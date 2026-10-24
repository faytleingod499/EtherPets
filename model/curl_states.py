# Curl pose authored in Blender, after the reference photo: the fox curled up with its bushy tail wrapped round the
# front and its tip turned in toward the body, its head resting on top of the tail with the snout lying on it,
# ears up in their normal place on the head, and all four legs folded into the middle of the curl.
# A = breathing out, B = breathing in. Quaternions (x, y, z, w), glTF-local; T = every joint's offset from its parent.
A = {
 'root': (-0.7071, -0.0, -0.0, 0.7071),
 'hips': (-0.0, -0.0, -0.9905, 0.1375),
 'chest': (-0.655, 0.7554, 0.0126, 0.0145),
 'neck': (-0.4931, 0.0541, -0.4158, 0.7623),
 'head': (0.453, 0.452, -0.3606, 0.6786),
 'ear_L': (-0.6498, -0.0541, -0.0042, 0.7582),
 'ear_R': (-0.6498, 0.0541, 0.0042, 0.7582),
 'foreleg_L': (-0.1464, 0.4425, 0.8421, 0.2713),
 'forepaw_L': (-0.6575, 0.1055, 0.7103, 0.2282),
 'foreleg_R': (0.3601, -0.1937, -0.413, 0.8138),
 'forepaw_R': (-0.4909, -0.2581, -0.6853, 0.4719),
 'hindleg_L': (-0.122, 0.5733, -0.5394, 0.6045),
 'hindshin_L': (-0.1607, -0.5484, 0.556, 0.6035),
 'hindpaw_L': (-0.0067, 0.0001, 1.0, 0.0001),
 'hindleg_R': (0.0355, -0.7798, 0.5078, 0.3645),
 'hindshin_R': (0.0698, -0.2198, -0.2324, 0.9449),
 'hindpaw_R': (-0.0, 0.2375, -0.0, 0.9714),
 'tail_1': (-0.2259, -0.5671, 0.727, 0.3145),
 'tail_2': (0.2017, -0.1324, -0.321, 0.9158),
 'tail_3': (-0.4193, 0.0566, -0.4322, 0.7963),
}
B = dict(A)
B['chest'] = (0.654, -0.7554, -0.039, 0.0083)
B['tail_3'] = (-0.4142, 0.0409, -0.4555, 0.7869)
T = {
 'root': (0.0, -0.0393, 0.0), 'hips': (0.0, 0.35, 0.62), 'chest': (0.0, 0.4, 0.02), 'neck': (0.0025, 0.457, 0.0037),
 'head': (0.0386, 0.2824, 0.0626), 'ear_L': (0.12, 0.0905, -0.1882), 'ear_R': (-0.12, 0.0905, -0.1882),
 'foreleg_L': (0.2118, 0.3247, 0.1623), 'forepaw_L': (0.0089, 0.4545, -0.0102),
 'foreleg_R': (-0.0998, 0.2828, 0.0782), 'forepaw_R': (-0.0075, 0.4451, 0.0378),
 'hindleg_L': (-0.22, -0.07, -0.08), 'hindshin_L': (0.0, 0.2202, 0.0), 'hindpaw_L': (0.0, 0.2202, 0.0),
 'hindleg_R': (0.12, -0.0037, 0.0), 'hindshin_R': (0.0, 0.2202, 0.0), 'hindpaw_R': (0.0, 0.2202, 0.0),
 'tail_1': (0.0, -0.23, 0.1), 'tail_2': (0.0, 0.2126, 0.0), 'tail_3': (0.0, 0.2408, 0.0),
}
