# Makes the fox's own voice: fox_yip.wav (its answer to its owner's bark: three sharp, hoarse
# "wow" yips that jump up and fall away, like a red fox's bark) and fox_coo.wav (the happy sound when petted:
# a soft, high, wavering coo that scoops up and eases down with a little breath).
# Run:  python3 make_fox.py out_dir
import sys, os
import numpy as np
from scipy.signal import butter, lfilter, fftconvolve
from scipy.io import wavfile

RATE = 22050
rng = np.random.default_rng(23)


def voice(f0, amp, formants, breath, rough=0.0):
    n = len(f0)
    phase = 2 * np.pi * np.cumsum(f0) / RATE
    # a buzzy source: many harmonics with a gentle tilt
    src = np.zeros(n)
    for h in range(1, 28):
        src += np.sin(h * phase + rng.random() * 0.3) / h ** 1.1
    if rough:                                            # hoarse: loudness jitters at the voice rate
        src *= 1 + rough * rng.standard_normal(n).cumsum() * 0.0 + rough * np.sin(phase * 0.5) * 0.5
    out = np.zeros(n)
    for fc, bw, g in formants:                           # the mouth's resonances
        lo, hi = max(fc - bw, 60) / (RATE / 2), min(fc + bw, 10000) / (RATE / 2)
        b, a = butter(2, [lo, hi], "band")
        out += g * lfilter(b, a, src)
    noise = lfilter(*butter(2, [1500 / (RATE / 2), 6000 / (RATE / 2)], "band"), rng.standard_normal(n))
    out = out + breath * noise * (np.abs(out).max() + 1e-6) * 0.5
    return out * amp


def finish(x, echo=0.0):
    x = x / (np.abs(x).max() + 1e-9)
    if echo:
        ir = np.exp(-np.arange(int(0.12 * RATE)) / (0.03 * RATE)) * rng.standard_normal(int(0.12 * RATE))
        x = x + echo * fftconvolve(x, ir)[:len(x)] * 0.05
    x = lfilter(*butter(1, 120 / (RATE / 2), "high"), x)
    x = x / (np.abs(x).max() + 1e-9) * 0.85
    fade = int(0.01 * RATE)
    x[:fade] *= np.linspace(0, 1, fade)
    x[-fade:] *= np.linspace(1, 0, fade)
    return x


def yip(start_hz, peak_hz, end_hz, dur):
    n = int(dur * RATE)
    t = np.linspace(0, 1, n)
    f0 = np.interp(t, [0, 0.25, 1], [start_hz, peak_hz, end_hz])
    f0 *= 1 + 0.02 * np.sin(2 * np.pi * 38 * t * dur)    # a hoarse flutter
    env = np.minimum(t / 0.06, 1) * np.exp(-2.8 * t)
    # "wow": the mouth opens (ah) then closes (oo)
    v = voice(f0, 1.0, [(900, 250, 1.0), (1700, 350, 0.7), (3200, 600, 0.35)], 0.35)
    return v * env


# --- the yip: three barks, each a little different, with short gaps
gaps = [0.0, 0.17, 0.15]
dur = 0.2
parts = [np.zeros(int(0.02 * RATE))]
for k, (a, p, e) in enumerate([(650, 1250, 800), (700, 1350, 850), (680, 1150, 700)]):
    parts.append(yip(a, p, e, dur))
    parts.append(np.zeros(int(gaps[k + 1 if k + 1 < 3 else 2] * RATE) if k < 2 else int(0.05 * RATE)))
y = finish(np.concatenate(parts), echo=0.6)
wavfile.write(os.path.join(sys.argv[1] if len(sys.argv) > 1 else ".", "fox_yip.wav"), RATE, (y * 32767).astype(np.int16))

# --- the coo: soft, high and wavering
LEN = 1.1
n = int(LEN * RATE)
t = np.linspace(0, 1, n)
f0 = np.interp(t, [0, 0.2, 0.55, 1], [820, 1180, 1050, 760])
f0 *= 1 + 0.025 * np.sin(2 * np.pi * 6.5 * t * LEN) + 0.004 * rng.standard_normal(n).cumsum() / np.sqrt(n) * 10
env = np.minimum(t / 0.12, 1) * np.clip((1 - t) / 0.35, 0, 1) ** 1.2 * (0.85 + 0.15 * np.sin(2 * np.pi * 6.5 * t * LEN))
c = voice(f0, 1.0, [(700, 200, 1.0), (2200, 400, 0.4)], 0.18) * env
c = finish(c, echo=0.3)
wavfile.write(os.path.join(sys.argv[1] if len(sys.argv) > 1 else ".", "fox_coo.wav"), RATE, (c * 32767).astype(np.int16))
print("ok")
