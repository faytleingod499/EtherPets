# Curl pose authored in Blender: the fox curled up with its head resting fully on top of its tail (nose short of
# the tail base), ears standing up and a little closer together, front and back legs folded into the centre.
# A = breathing out, B = breathing in. Quaternions (x, y, z, w), glTF-local. T = translations that differ from rest.
A = {
 'root': (-0.7071,0,0,0.7071), 'hips': (0,0,-0.9905,0.1375), 'chest': (-0.655,0.7554,0.0126,0.0145),
 'neck': (-0.4219,-0.0162,-0.466,0.7775), 'head': (0.2331,0.4549,-0.6102,0.6052),
 'ear_L': (-0.66,0.1233,-0.5053,0.5421), 'ear_R': (-0.8185,-0.002,-0.1449,0.5559),
 'foreleg_L': (0.2907,0.0968,-0.9519,0.0106), 'forepaw_L': (-0.6188,0.0979,0.7104,0.3207),
 'foreleg_R': (0.3036,0.2665,-0.7181,0.5667), 'forepaw_R': (0.5815,0.0432,-0.6805,0.4437),
 'hindleg_L': (-0.0865,-0.9883,0.1251,0.0109), 'hindshin_L': (0.9379,0,0,0.3468), 'hindpaw_L': (-0.6568,0,0,0.754),
 'hindleg_R': (0.4812,-0.6894,0.2859,0.4598), 'hindshin_R': (-0.1235,0,0.1482,0.9812), 'hindpaw_R': (0.352,-0.1941,-0.2677,0.8756),
 'tail_1': (-0.2098,-0.426,0.8316,0.2881), 'tail_2': (-0.0162,-0.0529,-0.4853,0.8726), 'tail_3': (-0.2022,0,-0.2973,0.9331),
}
B = dict(A)
B['chest'] = (0.654,-0.7554,-0.039,0.0083)
B['tail_3'] = (-0.1892,-0.0116,-0.332,0.924)
T = {  # every joint's offset from its parent, as posed in Blender, so the game matches the Blender pose exactly
 'root': (0.0,-0.0846,0.0), 'hips': (0.0,0.35,0.62), 'chest': (0.0,0.4,0.02), 'neck': (0.0025,0.457,0.0037),
 'head': (0.0386,0.2824,0.0626), 'ear_L': (0.1065,0.0589,-0.191), 'ear_R': (-0.0748,0.0517,-0.2474),
 'foreleg_L': (0.2118,0.3247,0.1623), 'forepaw_L': (0.0089,0.4545,-0.0102), 'foreleg_R': (-0.2082,0.3269,0.1625),
 'forepaw_R': (-0.0075,0.4451,0.0378), 'hindleg_L': (-0.22,-0.07,-0.08), 'hindshin_L': (0.0,0.2202,0.0),
 'hindpaw_L': (0.0,0.2202,0.0), 'hindleg_R': (0.22,-0.07,-0.08), 'hindshin_R': (0.0,0.2202,0.0), 'hindpaw_R': (0.0,0.2202,0.0),
 'tail_1': (0.0,-0.23,0.1), 'tail_2': (0.0,0.2126,0.0), 'tail_3': (0.0,0.2408,0.0),
}
