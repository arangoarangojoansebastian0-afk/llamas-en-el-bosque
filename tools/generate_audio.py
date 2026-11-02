#!/usr/bin/env python3
"""Genera todo el audio de 'Llamas en el Bosque' por síntesis (numpy + scipy).
Salida: assets/audio/{sfx,music,ambience}/*.wav  (mono, 16 bits, 32 kHz).
Uso:  python3 tools/generate_audio.py
Los sonidos son sintéticos y sustituibles: basta con reemplazar el .wav conservando el nombre."""
import os, wave
import numpy as np
from scipy.signal import butter, lfilter

SR = 32000
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "audio")
rng = np.random.default_rng(1105)

# ---------------------------------------------------------------- utilidades
def tt(d): return np.arange(int(d * SR)) / SR
def mtof(m): return 440.0 * 2 ** ((m - 69) / 12.0)
def noise(d): return rng.standard_normal(int(d * SR))
def _b(kind, fc): return butter(2, np.array(fc) / (SR / 2), kind)
def lp(x, fc): b, a = _b("low", fc); return lfilter(b, a, x)
def hp(x, fc): b, a = _b("high", fc); return lfilter(b, a, x)
def bp(x, lo, hi): b, a = _b("band", [lo, hi]); return lfilter(b, a, x)
def clp(x, fc):  # filtro paso bajo circular (para bucles)
    n = len(x); return lp(np.tile(x, 3), fc)[n:2 * n]
def exp_env(n, decay): return np.exp(-(np.arange(n) / SR) / decay)
def adsr(n, a, r):
    e = np.ones(n); na = min(int(a * SR), n); nr = min(int(r * SR), n)
    if na: e[:na] = np.linspace(0, 1, na)
    if nr: e[n - nr:] *= np.linspace(1, 0, nr)
    return e
def sine(f, d): return np.sin(2 * np.pi * f * tt(d))
def tri(f, d): return 2 / np.pi * np.arcsin(np.sin(2 * np.pi * f * tt(d)))
def sweep(f0, f1, d):
    t = tt(d); k = (f1 - f0) / d; return np.sin(2 * np.pi * (f0 * t + 0.5 * k * t * t))
def chime(f, d=0.6, decay=0.2):
    t = tt(d)
    s = np.sin(2 * np.pi * f * t) + 0.35 * np.sin(4 * np.pi * f * t) + 0.15 * np.sin(6 * np.pi * f * t)
    return s * np.exp(-t / decay) * adsr(len(t), 0.003, 0.02)
def pluck(f, d, decay=0.4, bright=0.5):
    t = tt(d)
    s = np.sin(2 * np.pi * f * t) + bright * 0.5 * np.sin(4 * np.pi * f * t) + bright * 0.25 * np.sin(6 * np.pi * f * t)
    return s * np.exp(-t / decay) * adsr(len(t), 0.004, 0.03)
def pad(freqs, d, a, r):
    s = np.zeros(int(d * SR))
    for f in freqs:
        for det in (-0.004, 0.0, 0.004):
            s += np.sin(2 * np.pi * f * (1 + det) * tt(d)) + 0.25 * np.sin(4 * np.pi * f * (1 + det) * tt(d))
    return s / (len(freqs) * 3) * adsr(len(s), a, r)

def add(buf, sig, start, gain=1.0, wrap=False):
    s = int(start * SR); n = len(buf); sig = sig * gain
    if wrap:
        s %= n
        first = min(len(sig), n - s)
        buf[s:s + first] += sig[:first]
        if first < len(sig):
            rest = sig[first:]; buf[:len(rest)] += rest[:n]
    else:
        e = min(n, s + len(sig))
        if e > s: buf[s:e] += sig[:e - s]
    return buf
def echo(buf, delay, fb, taps, cutoff=3000):
    wet = clp(buf, cutoff); out = buf.copy()
    for k in range(1, taps + 1): out += np.roll(wet, int(k * delay * SR)) * fb ** k
    return out
def loopify(x, L, xf):
    n = int(L * SR); k = int(xf * SR); y = x[:n].copy(); tail = x[n:n + k]
    y[:k] = y[:k] * np.linspace(0, 1, k) + tail * np.linspace(1, 0, k); return y
def norm(x, peak=0.8): return x / (np.max(np.abs(x)) + 1e-9) * peak
def save(sub, name, x):
    os.makedirs(os.path.join(ROOT, sub), exist_ok=True)
    path = os.path.join(ROOT, sub, name + ".wav")
    data = (np.clip(x, -1, 1) * 32767).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(data.tobytes())
    print(f"{sub}/{name}.wav  {len(x)/SR:5.1f}s  pico {np.max(np.abs(x)):.2f}")
def sfx(name, x, peak=0.8):
    x = norm(x, peak); n = int(0.004 * SR); x[:n] *= np.linspace(0, 1, n); x[-n:] *= np.linspace(1, 0, n)
    save("sfx", name, x)
def seq(total, parts):
    b = np.zeros(int(total * SR))
    for sig, start, gain in parts: add(b, sig, start, gain)
    return b

# ---------------------------------------------------------------- efectos
def make_sfx():
    n = int(0.06 * SR)
    sfx("click", sine(1500, 0.06) * exp_env(n, 0.012) + 0.4 * sine(750, 0.06) * exp_env(n, 0.02), 0.6)
    for i, fc in enumerate((900, 1400), start=1):
        n = int(0.14 * SR)
        s = lp(noise(0.14), fc) * exp_env(n, 0.03) + 0.5 * sine(80, 0.14) * exp_env(n, 0.025)
        sfx(f"step{i}", s, 0.5)
    sfx("pickup", seq(0.6, [(chime(mtof(76)), 0, 1), (chime(mtof(83)), 0.09, 0.9)]), 0.7)
    s = np.zeros(int(0.8 * SR))
    for _ in range(12):
        f0 = rng.uniform(250, 600); d = 0.07
        b = sweep(f0, f0 * rng.uniform(1.5, 2.2), d) * np.sin(np.linspace(0, np.pi, int(d * SR)))
        add(s, b, rng.uniform(0, 0.65), rng.uniform(0.3, 0.7))
    g = lp(noise(0.8), 700) * (0.5 + 0.5 * np.sin(2 * np.pi * 13 * tt(0.8))) * adsr(int(0.8 * SR), 0.05, 0.25)
    sfx("refill", s + 0.5 * g, 0.7)
    n = int(0.5 * SR)
    sfx("splash", bp(noise(0.5), 600, 3500) * exp_env(n, 0.12) + 0.6 * sine(90, 0.5) * exp_env(n, 0.04), 0.75)
    n = int(1.0 * SR)
    sfx("fire_out", hp(noise(1.0), 1800) * exp_env(n, 0.35) + 0.7 * sine(70, 1.0) * exp_env(n, 0.09), 0.75)
    n = int(0.5 * SR)
    sfx("plant", seq(0.7, [(sine(110, 0.5) * exp_env(n, 0.08), 0, 1.0), (chime(mtof(67)), 0.05, 0.6), (chime(mtof(74)), 0.15, 0.6)]), 0.7)
    n = int(0.3 * SR)
    sfx("hurt", sweep(160, 50, 0.3) * exp_env(n, 0.1) + 0.6 * lp(noise(0.3), 600) * exp_env(n, 0.05), 0.8)
    for i, f in enumerate((520, 620, 740), start=1):
        n = int(0.05 * SR)
        sfx(f"blip{i}", tri(f, 0.05) * adsr(n, 0.002, 0.02), 0.45)
    sfx("quest_start", seq(1.0, [(chime(mtof(m), 0.7, 0.28), 0.12 * i, 1) for i, m in enumerate((72, 76, 79))]), 0.7)
    sfx("objective", seq(0.7, [(chime(mtof(79), 0.5, 0.2), 0, 1), (chime(mtof(84), 0.5, 0.25), 0.1, 1)]), 0.65)
    parts = [(chime(mtof(m), 1.0, 0.4), 0.1 * i, 1) for i, m in enumerate((72, 76, 79, 84, 88))]
    parts.append((hp(noise(0.6), 6000) * exp_env(int(0.6 * SR), 0.15), 0.3, 0.12))
    sfx("quest_complete", seq(1.6, parts), 0.75)
    parts = []
    for i, m in enumerate((72, 76, 79, 84)): parts.append((chime(mtof(m), 1.4, 0.6), 0.25 * i, 1))
    for start, ch in ((0.0, (60, 64, 67)), (1.2, (62, 67, 71)), (2.2, (60, 64, 67, 72))):
        parts.append((pad([mtof(m) for m in ch], 2.4, 0.05, 1.2), start, 0.5))
    sfx("victory", seq(4.8, parts), 0.8)
    parts = [(tri(mtof(m), 1.0) * exp_env(int(1.0 * SR), 0.5), 0.38 * i, 1) for i, m in enumerate((57, 53, 50, 45))]
    parts.append((sine(55, 2.5) * adsr(int(2.5 * SR), 0.3, 1.2), 0.2, 0.5))
    sfx("defeat", seq(3.0, parts), 0.75)
    n = int(0.35 * SR)
    s = sweep(500, 1800, 0.35) * np.sin(np.linspace(0, np.pi, n)) ** 2
    s = seq(1.2, [(s, 0, 1), (chime(1800, 0.8, 0.3), 0.3, 0.4)])
    sfx("observe", echo(s, 0.18, 0.4, 3), 0.6)
    def chirp(f0, f1): return sweep(f0, f1, 0.07) * np.sin(np.linspace(0, np.pi, int(0.07 * SR)))
    sfx("chirp", seq(0.4, [(chirp(2000, 3000), 0, 1), (chirp(2400, 3400), 0.1, 0.9)]), 0.55)
    sfx("rescue", seq(1.1, [(chirp(1800, 2800), 0.1 * i, 0.8) for i in range(3)] +
        [(chime(mtof(76), 0.8, 0.3), 0.35, 0.9), (chime(mtof(83), 0.8, 0.3), 0.45, 0.8), (chime(mtof(88), 0.8, 0.3), 0.55, 0.7)]), 0.7)

# ---------------------------------------------------------------- ambiente
def make_ambience():
    L, xf = 24.0, 1.5; total = L + xf; n = int(total * SR); t = tt(total)
    lfo1 = 0.5 + 0.5 * np.sin(2 * np.pi * 0.07 * t + 1.0)
    lfo2 = 0.5 + 0.5 * np.sin(2 * np.pi * 0.13 * t + 2.5)
    wind = bp(noise(total), 120, 700) * (0.35 + 0.65 * lfo1 * (0.6 + 0.4 * lfo2))
    rustle = bp(noise(total), 2500, 6500) * (0.03 + 0.10 * lfo2 ** 2)
    x = wind * 1.0 + rustle
    for _ in range(7):
        t0 = rng.uniform(xf + 0.5, L - 2.0); base = rng.uniform(2600, 4200)
        for k in range(int(rng.integers(3, 6))):
            d = 0.07; up = rng.random() < 0.5
            f0, f1 = (base, base * 1.3) if up else (base * 1.3, base)
            c = sweep(f0, f1, d) * np.sin(np.linspace(0, np.pi, int(d * SR)))
            add(x, c, t0 + k * 0.11, rng.uniform(0.05, 0.09) * np.max(np.abs(wind)))
    save("ambience", "forest", norm(loopify(x, L, xf), 0.6))
    L, xf = 6.0, 0.5; total = L + xf; n = int(total * SR)
    x = np.zeros(n)
    for _ in range(int(total * 90)):
        ln = int(rng.uniform(0.004, 0.03) * SR); amp = rng.random() ** 3
        pop = hp(rng.standard_normal(ln), 800) * np.exp(-np.arange(ln) / (0.006 * SR))
        add(x, pop, rng.uniform(0, total - 0.04), amp * 2.0)
    x += lp(noise(total), 250) * 0.5 * (0.7 + 0.3 * np.sin(2 * np.pi * 0.5 * tt(total)))
    x += bp(noise(total), 1500, 5000) * 0.08
    save("ambience", "fire", norm(loopify(x, L, xf), 0.7))

# ---------------------------------------------------------------- música
def make_music():
    # Calma: Am F C G Am F G Am, 4 s por acorde, 32 s.
    L = 32.0; buf = np.zeros(int(L * SR))
    chords = [([57, 60, 64], 45), ([53, 57, 60], 41), ([55, 60, 64], 48), ([55, 59, 62], 43),
              ([57, 60, 64], 45), ([53, 57, 60], 41), ([55, 59, 62], 43), ([57, 60, 64], 45)]
    penta = [69, 72, 74, 76, 79, 81]
    for i, (notes, bass) in enumerate(chords):
        add(buf, pad([mtof(m) for m in notes], 6.5, 1.5, 2.5), 4 * i, 0.55, wrap=True)
        add(buf, sine(mtof(bass), 3.8) * adsr(int(3.8 * SR), 0.2, 0.8), 4 * i, 0.35, wrap=True)
        for beat in sorted(rng.choice([0.5, 1.0, 1.5, 2.0, 2.5, 3.0], size=int(rng.integers(2, 4)), replace=False)):
            add(buf, pluck(mtof(int(rng.choice(penta))), 3.0, 0.9, 0.3), 4 * i + beat, 0.16, wrap=True)
    save("music", "calm", norm(echo(buf, 0.5, 0.4, 5), 0.8))
    # Tensa: bordón disonante + latido, 24 s (frecuencias con ciclos enteros: bucle limpio).
    L = 24.0; t = tt(L); buf = np.zeros(len(t))
    for f, g in ((55.0, 0.5), (82.5, 0.3), (110.0, 0.2), (58.25, 0.25)):
        buf += np.sin(2 * np.pi * f * t) * g * (0.7 + 0.3 * np.sin(2 * np.pi * 3 / L * t))
    for f, g in ((220.0, 0.07), (233.0, 0.07)):
        buf += np.sin(2 * np.pi * f * t) * g * (0.5 + 0.5 * np.sin(2 * np.pi * 2 / L * t))
    for k in range(16):
        add(buf, sine(52, 0.5) * exp_env(int(0.5 * SR), 0.12), 1.5 * k, 0.55, wrap=True)
        add(buf, sine(52, 0.4) * exp_env(int(0.4 * SR), 0.1), 1.5 * k + 0.28, 0.3, wrap=True)
    for _ in range(6):
        f = rng.choice([880.0, 932.0, 1318.0]); s = (np.sin(2 * np.pi * f * tt(2.5)) + 0.5 * np.sin(2 * np.pi * f * 2.76 * tt(2.5)))
        add(buf, s * exp_env(len(s), 0.9), rng.uniform(0, 22), 0.05, wrap=True)
    save("music", "tense", norm(echo(buf, 0.45, 0.35, 4), 0.8))
    # Incendio: 120 bpm, 16 s, ritmo y bajo insistente en Re menor.
    L = 16.0; buf = np.zeros(int(L * SR))
    for k in range(32):
        add(buf, sweep(120, 50, 0.25) * exp_env(int(0.25 * SR), 0.1), 0.5 * k, 0.8, wrap=True)
    for k in range(16):
        add(buf, hp(noise(0.2), 1500) * exp_env(int(0.2 * SR), 0.05), 1.0 * k + 0.5, 0.35, wrap=True)
    for k in range(64):
        add(buf, hp(noise(0.08), 6000) * exp_env(int(0.08 * SR), 0.02), 0.25 * k, 0.12, wrap=True)
    line = [38, 38, 41, 38, 45, 38, 41, 36]
    for k in range(64):
        add(buf, pluck(mtof(line[k % 8]), 0.3, 0.16, 0.8) * 0.8 + 0.3 * pluck(mtof(line[k % 8] + 12), 0.3, 0.1, 0.5), 0.25 * k, 0.4, wrap=True)
    for bar in range(8):
        ch = [50, 53, 57] if bar < 4 else [46, 50, 53]
        add(buf, pad([mtof(m) for m in ch], 2.6, 0.05, 0.8), 2.0 * bar, 0.45, wrap=True)
        add(buf, pad([mtof(ch[0] + 6)], 2.6, 0.1, 0.8), 2.0 * bar, 0.2 if bar % 2 else 0.1, wrap=True)
    save("music", "fire", norm(echo(buf, 0.375, 0.25, 3), 0.8))
    # Rescate: cálida y esperanzada, 80 bpm, 24 s. C G Am F C G F C.
    L = 24.0; buf = np.zeros(int(L * SR))
    prog = [([60, 64, 67], 48), ([55, 59, 62], 43), ([57, 60, 64], 45), ([53, 57, 60], 41),
            ([60, 64, 67], 48), ([55, 59, 62], 43), ([53, 57, 60], 41), ([60, 64, 67], 48)]
    for i, (notes, bass) in enumerate(prog):
        add(buf, pad([mtof(m) for m in notes], 4.5, 0.6, 1.2), 3 * i, 0.4, wrap=True)
        add(buf, sine(mtof(bass), 2.8) * adsr(int(2.8 * SR), 0.05, 0.5), 3 * i, 0.4, wrap=True)
        arp = [notes[0] + 12, notes[1] + 12, notes[2] + 12, notes[1] + 24, notes[2] + 12, notes[1] + 12, notes[0] + 12, notes[1] + 12]
        for k, m in enumerate(arp):
            add(buf, pluck(mtof(m), 0.7, 0.35, 0.4), 3 * i + 0.375 * k, 0.17, wrap=True)
    save("music", "rescue", norm(echo(buf, 0.375, 0.3, 4), 0.8))

if __name__ == "__main__":
    make_sfx(); make_ambience(); make_music()
    print("Listo.")
