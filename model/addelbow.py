# Gives the fox's front legs an elbow: each foreleg bone (shoulder to wrist) is split into
#   foreleg_X  (shoulder to elbow)  and  forearm_X  (elbow to wrist), with forepaw_X now hanging off forearm_X.
# The skin weights of the lower half of each front leg move to the new bone (blended around the elbow),
# and every animation gets a resting track for the new bones, so nothing else about the fox moves.
import sys, numpy as np
from glbio import Glb

HALF = 0.22          # the foreleg bones are 0.44 long; the elbow goes half way down

def trs(n):
    t = np.array(n.get('translation', [0, 0, 0]), float)
    x, y, z, w = n.get('rotation', [0, 0, 0, 1])
    R = np.array([[1-2*(y*y+z*z), 2*(x*y-z*w), 2*(x*z+y*w)],
                  [2*(x*y+z*w), 1-2*(x*x+z*z), 2*(y*z-x*w)],
                  [2*(x*z-y*w), 2*(y*z+x*w), 1-2*(x*x+y*y)]])
    s = np.array(n.get('scale', [1, 1, 1]), float)
    M = np.eye(4); M[:3, :3] = R * s; M[:3, 3] = t
    return M

def new_acc(g, data, typ, ctype=5126):
    data = np.ascontiguousarray(data)
    pad = (-len(g.bin)) % 4; g.bin += b'\0' * pad
    off = len(g.bin); g.bin += data.tobytes()
    g.j['bufferViews'].append({'buffer': 0, 'byteOffset': off, 'byteLength': data.nbytes})
    a = {'bufferView': len(g.j['bufferViews']) - 1, 'componentType': ctype, 'count': len(data), 'type': typ}
    if typ == 'SCALAR': a['min'] = [float(data.min())]; a['max'] = [float(data.max())]
    g.j['accessors'].append(a)
    return len(g.j['accessors']) - 1

def add_elbows(g):
    j = g.j
    nodes = j['nodes']
    idx = {n.get('name'): i for i, n in enumerate(nodes)}
    if 'forearm_L' in idx:
        return
    skin = j['skins'][0]
    joints = list(skin['joints'])
    ibm = g.acc(skin['inverseBindMatrices']).reshape(-1, 4, 4).transpose(0, 2, 1)   # column-major -> row-major
    new_ibm = list(ibm)
    remap = {}
    for s in 'LR':
        leg, paw = idx['foreleg_' + s], idx['forepaw_' + s]
        nodes.append({'name': 'forearm_' + s, 'translation': [0.0, HALF, 0.0], 'children': [paw]})
        arm = len(nodes) - 1
        nodes[leg]['children'] = [arm]
        nodes[paw]['translation'] = [0.0, HALF, 0.0]
        leg_glob = np.linalg.inv(ibm[joints.index(leg)])
        arm_glob = leg_glob @ np.array([[1, 0, 0, 0], [0, 1, 0, HALF], [0, 0, 1, 0], [0, 0, 0, 1]], float)
        joints.append(arm); new_ibm.append(np.linalg.inv(arm_glob))
        remap[joints.index(leg)] = (len(joints) - 1, ibm[joints.index(leg)])
    skin['joints'] = joints
    skin['inverseBindMatrices'] = new_acc(g, np.array(new_ibm).transpose(0, 2, 1).astype(np.float32).reshape(-1, 16), 'MAT4')
    # move the lower half of each front leg's skin to its forearm
    moved = 0
    for pr in j['meshes'][0]['primitives']:
        at = pr['attributes']
        P = g.acc(at['POSITION']); J = g.acc(at['JOINTS_0']).astype(np.int64); W = g.acc(at['WEIGHTS_0']).astype(np.float64)
        for v in range(len(P)):
            for k in range(4):
                jl = J[v, k]
                if jl in remap and W[v, k] > 0:
                    arm_j, leg_ibm = remap[jl]
                    t = (leg_ibm @ np.append(P[v], 1.0))[1] / (2 * HALF)
                    s = np.clip((t - 0.42) / 0.16, 0, 1); s = s * s * (3 - 2 * s)
                    if s <= 0: continue
                    w = W[v, k]
                    free = [q for q in range(4) if W[v, q] == 0]
                    if s >= 1 or not free:
                        if s >= 0.5 or not free: J[v, k] = arm_j
                    else:
                        W[v, k] = w * (1 - s); J[v, free[0]] = arm_j; W[v, free[0]] = w * s
                    moved += 1
        jt = j['accessors'][at['JOINTS_0']]['componentType']
        g.set_acc(at['JOINTS_0'], J.astype({5121: np.uint8, 5123: np.uint16}[jt]))
        wt = j['accessors'][at['WEIGHTS_0']]['componentType']
        g.set_acc(at['WEIGHTS_0'], W.astype(np.float32) if wt == 5126 else W)
    # animations: paws now sit half as far down (from the elbow), and the new bones get a resting track
    idx = {n.get('name'): i for i, n in enumerate(nodes)}
    for a in j.get('animations', []):
        for c in a['channels']:
            nm = nodes[c['target']['node']].get('name')
            if nm in ('forepaw_L', 'forepaw_R') and c['target']['path'] == 'translation':
                smp = a['samplers'][c['sampler']]
                n = j['accessors'][smp['output']]['count']
                smp['output'] = new_acc(g, np.tile(np.array([0, HALF, 0], np.float32), (n, 1)), 'VEC3')
        ensure_rest_tracks(g, a, ('forearm_L', 'forearm_R'))
    j['buffers'][0]['byteLength'] = len(g.bin)
    return moved

def ensure_rest_tracks(g, a, names):
    j = g.j; nodes = j['nodes']
    idx = {n.get('name'): i for i, n in enumerate(nodes)}
    have = {(c['target']['node'], c['target']['path']) for c in a['channels']}
    end = max(j['accessors'][s['input']]['max'][0] for s in a['samplers']) if a['samplers'] else 0.0
    for nm in names:
        i = idx[nm]; n = nodes[i]
        for path, val in (('rotation', n.get('rotation', [0, 0, 0, 1])), ('translation', n.get('translation', [0, 0, 0]))):
            if (i, path) in have: continue
            t = new_acc(g, np.array([0.0, max(end, 1e-3)], np.float32), 'SCALAR')
            v = new_acc(g, np.array([val, val], np.float32), 'VEC4' if path == 'rotation' else 'VEC3')
            a['samplers'].append({'input': t, 'output': v, 'interpolation': 'LINEAR'})
            a['channels'].append({'sampler': len(a['samplers']) - 1, 'target': {'node': i, 'path': path}})
    j['buffers'][0]['byteLength'] = len(g.bin)

if __name__ == '__main__':
    g = Glb(sys.argv[1]); print('moved weights:', add_elbows(g)); g.save(sys.argv[2])
