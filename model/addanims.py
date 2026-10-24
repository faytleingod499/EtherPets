# Adds the fox's own animations (made in Blender on the fox rig) to pet_fox.glb:
#   fox_leap  - the jump up onto its owner's head (13 frames at 24 fps)
#   fox_curl  - curled up asleep on the head (49 frames, looping breathing)
import struct, json, sys
import numpy as np
from glbio import Glb

I = (0, 0, 0, 1)
REST_T = {}
CURL_FRAMES = [1, 7, 13, 19, 25, 31, 37, 43, 49]
LEAP_FRAMES = [1, 5, 9, 13]
c1 = lambda q: [q]  # a pose that never changes

CURL = {
 'root': ([(-0.7071, 0, 0, 0.7071)], (0, -0.36, 0)),
 'hips': ([(0, 0, 0.9925, 0.1219)], None),
 'chest': ([(0.3906,-0.9203,-0.0204,0.0087),(0.3906,-0.9204,-0.0136,0.0116),(0.3905,-0.9204,-0.0108,0.0128),(0.3906,-0.9204,-0.0136,0.0116),(0.3906,-0.9203,-0.0204,0.0087),(0.3907,-0.9201,-0.0273,0.0058),(0.3907,-0.92,-0.0301,0.0046),(0.3907,-0.9201,-0.0273,0.0058),(0.3906,-0.9203,-0.0204,0.0087)], None),
 'neck': ([(-0.139, 0.1384, -0.4784, 0.856)], None),
 'head': ([(0.3445,0.1019,-0.6053,0.7104),(0.3453,0.1026,-0.6051,0.7099),(0.3426,0.1003,-0.6055,0.7113),(0.3379,0.0963,-0.6062,0.7135),(0.334,0.093,-0.6067,0.7153),(0.3332,0.0923,-0.6068,0.7157),(0.3359,0.0946,-0.6064,0.7145),(0.3406,0.0986,-0.6058,0.7122),(0.3445,0.1019,-0.6053,0.7104)], None),
 'ear_L': ([(-0.2685,-0.0467,0.0275,0.9618)], None),
 'ear_R': ([(-0.2685, 0.0467,-0.0275,0.9618)], None),
 'foreleg_L': ([(-0.1947,0,0,0.9809),(-0.1997,-0.0052,-0.0013,0.9798),(-0.2018,-0.0073,-0.0018,0.9794),(-0.1997,-0.0052,-0.0013,0.9798),(-0.1947,0,0,0.9809),(-0.1897,0.0052,0.0013,0.9818),(-0.1876,0.0073,0.0018,0.9822),(-0.1897,0.0052,0.0013,0.9818),(-0.1947,0,0,0.9809)], None),
 'foreleg_R': ([(-0.1947,0,0,0.9809),(-0.1997,-0.0052,-0.0013,0.9798),(-0.2018,-0.0073,-0.0018,0.9794),(-0.1997,-0.0052,-0.0013,0.9798),(-0.1947,0,0,0.9809),(-0.1897,0.0052,0.0013,0.9818),(-0.1876,0.0073,0.0018,0.9822),(-0.1897,0.0052,0.0013,0.9818),(-0.1947,0,0,0.9809)], None),
 'forepaw_L': ([(0.3051,0,0,0.9523)], None),
 'forepaw_R': ([(0.3051,0,0,0.9523)], None),
 'hindleg_L': ([(-0.0133,-0.9904,0.1076,0.0861)], None),
 'hindleg_R': ([(-0.0133, 0.9904,-0.1076,0.0861)], None),
 'hindpaw_L': ([(-0.0512,0,0,0.9987)], None),
 'hindpaw_R': ([(-0.0512,0,0,0.9987)], None),
 'tail_1': ([(-0.085,-0.085,0.702,0.702)], None),
 'tail_2': ([(0.0032,-0.3888,-0.4408,0.809)], None),
 'tail_3': ([(0.0442,-0.3508,-0.3562,0.8649),(0.0447,-0.3395,-0.3448,0.874),(0.0449,-0.3348,-0.34,0.8777),(0.0447,-0.3395,-0.3448,0.874),(0.0442,-0.3508,-0.3562,0.8649),(0.0438,-0.362,-0.3676,0.8555),(0.0436,-0.3666,-0.3723,0.8515),(0.0438,-0.362,-0.3676,0.8555),(0.0442,-0.3508,-0.3562,0.8649)], None),
}
LEAP = {
 'hips': [(0,0.1219,0.9925,0),(0,-0.1045,0.9945,0),(0,-0.0523,0.9986,0),(0,0.0698,0.9976,0)],
 'chest': [(0,0.9989,-0.0476,0),(0,0.9958,0.0919,0),(0,0.9984,0.0571,0),(0,0.9999,-0.0127,0)],
 'neck': [(-0.2565,0,0,0.9665),(-0.4205,0,0,0.9073),(-0.3724,0,0,0.9281),(-0.3398,0,0,0.9405)],
 'head': [(0.3527,0,0,0.9357),(0.1848,0,0,0.9828),(0.236,0,0,0.9718),(0.2445,0,0,0.9697)],
 'ear_L': [(-0.4314,-0.0533,0.0099,0.9005),(-0.3513,-0.0523,0.0145,0.9347),(-0.3917,-0.0528,0.0122,0.9185),(-0.4703,-0.0537,0.0076,0.8808)],
 'ear_R': [(-0.4314,0.0533,-0.0099,0.9005),(-0.3513,0.0523,-0.0145,0.9347),(-0.3917,0.0528,-0.0122,0.9185),(-0.4703,0.0537,-0.0076,0.8808)],
 'foreleg_L': [(0.5559,0,0,0.8313),(0.2381,0,0,0.9712),(0.4794,0,0,0.8776),(0.1525,0,0,0.9883)],
 'foreleg_R': [(0.5559,0,0,0.8313),(0.2381,0,0,0.9712),(0.4794,0,0,0.8776),(0.1525,0,0,0.9883)],
 'forepaw_L': [(-0.6051,0,0,0.7961),(-0.4577,0,0,0.8891),(-0.4185,0,0,0.9082),(-0.5334,0,0,0.8458)],
 'forepaw_R': [(-0.6051,0,0,0.7961),(-0.4577,0,0,0.8891),(-0.4185,0,0,0.9082),(-0.5334,0,0,0.8458)],
 'hindleg_L': [(0,0.9323,-0.3616,0),(0,0.3223,-0.9466,0),(0,0.4818,-0.8763,0),(0,0.8554,-0.518,0)],
 'hindleg_R': [(0,0.9323,-0.3616,0),(0,0.3223,-0.9466,0),(0,0.4818,-0.8763,0),(0,0.8554,-0.518,0)],
 'hindpaw_L': [(-0.3977,0,0,0.9175),(-0.3573,0,0,0.934),(-0.4374,0,0,0.8993),(-0.4762,0,0,0.8793)],
 'hindpaw_R': [(-0.3977,0,0,0.9175),(-0.3573,0,0,0.934),(-0.4374,0,0,0.8993),(-0.4762,0,0,0.8793)],
}

def add(g, name, frames, rot, trans, fps=24.0):
    j = g.j
    names = {n.get('name'): i for i, n in enumerate(j['nodes'])}
    def new_acc(data, typ):
        data = np.asarray(data, np.float32)
        pad = (-len(g.bin)) % 4
        g.bin += b'\0' * pad
        off = len(g.bin); g.bin += data.tobytes()
        j['bufferViews'].append({'buffer': 0, 'byteOffset': off, 'byteLength': data.nbytes})
        a = {'bufferView': len(j['bufferViews']) - 1, 'componentType': 5126, 'count': len(data), 'type': typ}
        if typ == 'SCALAR': a['min'] = [float(data.min())]; a['max'] = [float(data.max())]
        j['accessors'].append(a); return len(j['accessors']) - 1
    anim = {'name': name, 'channels': [], 'samplers': []}
    times_all = [(f - 1) / fps for f in frames]
    for bone, keys in rot.items():
        t = times_all if len(keys) > 1 else [0.0, times_all[-1]]
        k = keys if len(keys) > 1 else [keys[0], keys[0]]
        q = np.asarray(k, np.float32); q /= np.linalg.norm(q, axis=1, keepdims=True)
        # keep neighbouring quaternions on the same side so they blend the short way
        for i in range(1, len(q)):
            if np.dot(q[i - 1], q[i]) < 0: q[i] = -q[i]
        anim['samplers'].append({'input': new_acc(t, 'SCALAR'), 'output': new_acc(q, 'VEC4'), 'interpolation': 'LINEAR'})
        anim['channels'].append({'sampler': len(anim['samplers']) - 1, 'target': {'node': names[bone], 'path': 'rotation'}})
    for bone, v in (trans or {}).items():
        anim['samplers'].append({'input': new_acc([0.0, times_all[-1]], 'SCALAR'), 'output': new_acc([v, v], 'VEC3'), 'interpolation': 'LINEAR'})
        anim['channels'].append({'sampler': len(anim['samplers']) - 1, 'target': {'node': names[bone], 'path': 'translation'}})
    j['animations'] = [a for a in j.get('animations', []) if a['name'] != name] + [anim]
    j['buffers'][0]['byteLength'] = len(g.bin)

if __name__ == '__main__':
    g = Glb(sys.argv[1])
    add(g, 'fox_curl', CURL_FRAMES, {b: v[0] for b, v in CURL.items()}, {'root': CURL['root'][1]})
    add(g, 'fox_leap', LEAP_FRAMES, LEAP, None)
    g.save(sys.argv[2])
    print('animations:', [a['name'] for a in g.j['animations']])
