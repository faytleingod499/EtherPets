# Curl pose authored in Blender, after the reference photo: the fox lying flat on the ground, curled round with its
# bushy tail wrapped round the front (tip turned in toward the body), its head resting on top of the tail with the
# snout lying on it, ears up, and all four legs folded flat on the ground in the middle of the curl (the front legs
# bend at the new elbow joints).
# A = breathing out, B = breathing in. Quaternions (x, y, z, w), glTF-local; T = every joint's offset from its parent;
# S = scale. The neck is stretched a little (head joint further out) so the head can lie lower with the snout raised.
A = {
 'root': (-0.7071, -0.0, -0.0, 0.7071),
 'hips': (-0.0, -0.0, -0.9905, 0.1375),
 'chest': (0.6498, -0.7526, -0.0915, 0.054),
 'neck': (-0.3145, -0.0586, -0.5066, 0.8007),
 'head': (0.0864, 0.3781, -0.4912, 0.7799),
 'ear_L': (-0.6498, -0.0541, -0.0042, 0.7582),
 'ear_R': (-0.6498, 0.0541, 0.0042, 0.7582),
 'foreleg_L': (0.0427, -0.2807, -0.9568, 0.0622),
 'forearm_L': (-0.594, 0.0, -0.0448, 0.8032),
 'forepaw_L': (-0.6005, 0.2838, 0.7091, 0.2368),
 'foreleg_R': (0.4484, -0.0132, -0.7167, 0.5339),
 'forearm_R': (-0.1695, -0.0, -0.1175, 0.9785),
 'forepaw_R': (-0.3408, -0.0688, -0.0198, 0.9374),
 'hindleg_L': (-0.1582, 0.7011, -0.259, 0.6452),
 'hindshin_L': (0.6585, 0.2086, -0.6839, 0.2349),
 'hindpaw_L': (-0.0067, -0.0135, 0.9999, 0.0012),
 'hindleg_R': (0.235, -0.7199, 0.438, 0.4844),
 'hindshin_R': (-0.1509, -0.7086, 0.0817, 0.6844),
 'hindpaw_R': (-0.3735, -0.3996, -0.3859, 0.7429),
 'tail_1': (-0.1597, -0.3278, 0.8057, 0.4668),
 'tail_2': (0.1165, -0.15, -0.3094, 0.9318),
 'tail_3': (-0.5011, -0.1898, -0.4043, 0.7412),
}
B = dict(A)
B['chest'] = (0.6467, -0.7499, -0.1167, 0.076)
B['tail_3'] = (-0.492, -0.2064, -0.4253, 0.7311)
T = {
 'root': (0.0, -0.4078, 0.0), 'hips': (0.0, 0.35, 0.62), 'chest': (0.0, 0.4, 0.02), 'neck': (-0.0017, 0.4803, -0.1058),
 'head': (0.0, 0.3673, 0.0), 'ear_L': (0.12, 0.0905, -0.1882), 'ear_R': (-0.12, 0.0905, -0.1882),
 'foreleg_L': (0.2076, 0.348, 0.0528), 'forearm_L': (0.0, 0.22, 0.0), 'forepaw_L': (0.0089, 0.2345, -0.0102),
 'foreleg_R': (-0.104, 0.3061, -0.0313), 'forearm_R': (0.0, 0.22, 0.0), 'forepaw_R': (-0.0075, 0.2251, 0.0378),
 'hindleg_L': (-0.22, -0.07, 0.032), 'hindshin_L': (0.0, 0.2202, 0.0), 'hindpaw_L': (0.0, 0.2202, 0.0),
 'hindleg_R': (0.12, -0.0037, 0.112), 'hindshin_R': (0.0, 0.2202, 0.0), 'hindpaw_R': (0.0, 0.2202, 0.0),
 'tail_1': (0.0, -0.23, 0.212), 'tail_2': (0.0, 0.2126, 0.0), 'tail_3': (0.0, 0.2408, 0.0),
}
S = {'tail_1': (0.8, 0.8, 0.8)}   # the bushy tail a little slimmer while curled, so the head can rest on top of it
