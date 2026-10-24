# Curl pose authored in Blender, after the reference photo: the fox curled up with its bushy tail wrapped round the
# front, its head resting on top of the tail with the snout lying on it (nose short of the tail base), ears up,
# front and back legs folded into the centre.
# A = breathing out, B = breathing in. Quaternions (x, y, z, w), glTF-local.
A = {
 'root': (-0.7071,0,0,0.7071), 'hips': (0,0,-0.9905,0.1375), 'chest': (-0.655,0.7554,0.0126,0.0145),
 'neck': (-0.4931,0.0541,-0.4158,0.7623), 'head': (0.453,0.452,-0.3606,0.6786),
 'ear_L': (-0.6696,0.1065,-0.5218,0.5177), 'ear_R': (-0.8349,-0.01,-0.1534,0.5284),
 'foreleg_L': (0.2907,0.0968,-0.9519,0.0106), 'forepaw_L': (-0.6188,0.0979,0.7104,0.3207),
 'foreleg_R': (0.3036,0.2665,-0.7181,0.5667), 'forepaw_R': (0.5815,0.0432,-0.6805,0.4437),
 'hindleg_L': (-0.0865,-0.9883,0.1251,0.0109), 'hindshin_L': (0.9379,0,0,0.3468), 'hindpaw_L': (-0.6568,0,0,0.754),
 'hindleg_R': (0.4812,-0.6894,0.2859,0.4598), 'hindshin_R': (-0.1235,0,0.1482,0.9812), 'hindpaw_R': (0.352,-0.1941,-0.2677,0.8756),
 'tail_1': (-0.2259,-0.5671,0.727,0.3145), 'tail_2': (0.2017,-0.1324,-0.321,0.9158), 'tail_3': (-0.1198,-0.0271,-0.3026,0.9452),
}
B = dict(A)
B['chest'] = (0.654,-0.7554,-0.039,0.0083)
B['tail_3'] = (-0.1089,-0.0336,-0.3285,0.9376)
T = {  # every joint's offset from its parent, as posed in Blender, so the game matches the Blender pose exactly
 'root': (0.0,-0.0454,0.0), 'hips': (0.0,0.35,0.62), 'chest': (0.0,0.4,0.02), 'neck': (0.0025,0.457,0.0037),
 'head': (0.0386,0.2824,0.0626), 'ear_L': (0.1065,0.0589,-0.191), 'ear_R': (-0.0748,0.0517,-0.2474),
 'foreleg_L': (0.2118,0.3247,0.1623), 'forepaw_L': (0.0089,0.4545,-0.0102), 'foreleg_R': (-0.2082,0.3269,0.1625),
 'forepaw_R': (-0.0075,0.4451,0.0378), 'hindleg_L': (-0.22,-0.07,-0.08), 'hindshin_L': (0.0,0.2202,0.0),
 'hindpaw_L': (0.0,0.2202,0.0), 'hindleg_R': (0.22,-0.07,-0.08), 'hindshin_R': (0.0,0.2202,0.0), 'hindpaw_R': (0.0,0.2202,0.0),
 'tail_1': (0.0,-0.23,0.1), 'tail_2': (0.0,0.2126,0.0), 'tail_3': (0.0,0.2408,0.0),
}
