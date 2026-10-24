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

import math
from curl_states import A as CA, B as CB, T as CURL_T
def _slerp(a, b, t):
    a = np.array(a, float); b = np.array(b, float)
    if a @ b < 0: b = -b
    d = min(1.0, a @ b)
    if d > 0.9995: q = a + (b - a) * t
    else:
        th = math.acos(d); q = (math.sin((1 - t) * th) * a + math.sin(t * th) * b) / math.sin(th)
    return tuple(q / np.linalg.norm(q))
_W = [0.5 - 0.5 * math.cos(2 * math.pi * (f - 1) / 48) for f in CURL_FRAMES]   # one slow breath
CURL = {bone: ([_slerp(CA[bone], CB[bone], w) for w in _W] if CA[bone] != CB[bone] else [CA[bone]], None) for bone in CA}
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
    add(g, 'fox_curl', CURL_FRAMES, {b: v[0] for b, v in CURL.items()}, CURL_T)
    add(g, 'fox_leap', LEAP_FRAMES, LEAP, None)
    g.save(sys.argv[2])
    print('animations:', [a['name'] for a in g.j['animations']])
