# Makes the fox's own voice, modelled on a recording of a happy fox (clean calls: pitch about 400-700 Hz,
# buzzy harmonics up to 6 kHz, short 0.15-0.35 s chirps every 0.2-0.35 s, pitch wobbling and drifting down):
# fox_yip.wav, its answer to its owner's bark: a quick run of chirpy gekkers.
# fox_coo.wav, the happy sound when petted: a few softer, longer wobbling chirps.
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
        src += np.sin(h * phase + rng.random() * 0.3) / h ** 0.75
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


def chirp(f_start, f_peak, f_end, dur, wob=0.05, wob_hz=13.0, soft=1.0):
    n = int(dur * RATE)
    t = np.linspace(0, 1, n)
    f0 = np.interp(t, [0, 0.18, 1], [f_start, f_peak, f_end])
    f0 = f0 * (1 + wob * np.sin(2 * np.pi * wob_hz * t * dur + rng.random() * 6) * np.minimum(t * 4, 1))
    f0 = f0 * (1 + 0.01 * np.convolve(rng.standard_normal(n), np.ones(200) / 200, "same") * 12)
    env = np.minimum(t / 0.08, 1) * np.clip((1 - t) / 0.25, 0, 1) ** 0.8 * (1 - 0.3 * t)
    v = voice(f0, 1.0, [(1100, 350, 1.0), (2500, 600, 0.8), (4200, 900, 0.35)], 0.22 * soft)
    return v * env


def sequence(chirps, gaps, tail=0.08):
    parts = [np.zeros(int(0.02 * RATE))]
    for c, g in zip(chirps, gaps):
        parts.append(c / (np.abs(c).max() + 1e-9))
        parts.append(np.zeros(int(g * RATE)))
    parts.append(np.zeros(int(tail * RATE)))
    return np.concatenate(parts)


out_dir = sys.argv[1] if len(sys.argv) > 1 else "."

# the answer: six chirps, a little different each time, getting softer and further apart
specs = [(540, 700, 470, 0.24), (560, 720, 450, 0.22), (520, 680, 440, 0.2), (540, 640, 430, 0.2), (500, 600, 410, 0.19), (480, 560, 380, 0.22)]
gaps = [0.1, 0.09, 0.12, 0.11, 0.14, 0.0]
chirps = [chirp(a, p, e, d) * (1.0 - 0.09 * k) for k, (a, p, e, d) in enumerate(specs)]
y = finish(sequence(chirps, gaps), echo=0.4)
wavfile.write(os.path.join(out_dir, "fox_yip.wav"), RATE, (y * 32767).astype(np.int16))

# the petted sound: three softer, longer, wobblier chirps
specs = [(470, 580, 500, 0.4), (500, 620, 480, 0.36), (480, 560, 400, 0.5)]
gaps = [0.14, 0.14, 0.0]
chirps = [chirp(a, p, e, d, wob=0.07, wob_hz=9.0, soft=1.4) * (1.0 - 0.15 * k) for k, (a, p, e, d) in enumerate(specs)]
c = finish(sequence(chirps, gaps, 0.15), echo=0.3)
wavfile.write(os.path.join(out_dir, "fox_coo.wav"), RATE, (c * 32767).astype(np.int16))
print("ok", len(y) / RATE, len(c) / RATE)
