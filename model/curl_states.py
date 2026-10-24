# Curl pose authored in Blender (fox curled up, nose resting on the tail, head above the tail, legs tucked into the centre).
# A = breathing out, B = breathing in. Quaternions (x, y, z, w), glTF-local; the root also carries its translation.
A = {
 'root': (-0.7071,0,0,0.7071), 'hips': (0,0,-0.9905,0.1375), 'chest': (-0.655,0.7554,0.0126,0.0145),
 'neck': (-0.2924,-0.1735,-0.5408,0.7693), 'head': (-0.1414,0.2073,-0.5777,0.7767),
 'ear_L': (-0.9216,-0.2509,-0.2955,0.0181), 'ear_R': (0.8748,-0.2265,-0.4097,0.1246),
 'foreleg_L': (0.29,0.0639,-0.9546,0.022), 'forepaw_L': (-0.6134,0.0642,0.7174,0.3239),
 'foreleg_R': (0.2833,0.2417,-0.7262,0.578), 'forepaw_R': (0.6064,0.0348,-0.6575,0.4458),
 'hindleg_L': (-0.0865,-0.9883,0.1251,0.0109), 'hindshin_L': (0.9379,0,0,0.3468), 'hindpaw_L': (-0.6568,0,0,0.754),
 'hindleg_R': (0.4812,-0.6894,0.2859,0.4598), 'hindshin_R': (-0.1235,0,0.1482,0.9812), 'hindpaw_R': (0.352,-0.1941,-0.2677,0.8756),
 'tail_1': (-0.133,-0.2605,0.8883,0.3541), 'tail_2': (-0.1019,0.0029,-0.7464,0.6576), 'tail_3': (0,0,0,1),
}
B = dict(A)
B['chest'] = (0.654,-0.7554,-0.039,0.0083)
B['tail_3'] = (0.0294,0,-0.0272,0.9992)
ROOT_T = (0.0, -0.0632, 0.0)
