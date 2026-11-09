"""Gera mus_entrada.ogg e sfx_tiro_basico.ogg (síntese própria, sem amostras de terceiros). BRF-123/T-194.
Uso: python gen_audio.py <pasta_de_saida>   (precisa de ffmpeg no PATH). Python puro, sem numpy."""
import math, random, struct, subprocess, sys, wave, os

SR = 44100
out = sys.argv[1] if len(sys.argv) > 1 else "."
random.seed(7)

def to_ogg(name, left, right, q):
    n = len(left)
    pk = max(max(map(abs, left)), max(map(abs, right)), 1e-9)
    g = 0.85 / pk
    path = os.path.join(out, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<hh", int(left[i]*g*32767), int(right[i]*g*32767)) for i in range(n)))
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", path, "-c:a", "libvorbis", "-q:a", str(q),
                    os.path.join(out, name + ".ogg")], check=True)
    os.remove(path)

def hz(m): return 440.0 * 2 ** ((m - 69) / 12)

# ---------- música: 16 compassos a 60 BPM = 64 s, loop circular ----------
BAR = 4 * SR
N = 16 * BAR
L = [0.0] * N; R = [0.0] * N
CH = [  # (baixo, acorde)
    (45, [57, 60, 64, 67]),   # Am7
    (41, [57, 60, 65, 69]),   # Fmaj7
    (48, [55, 60, 64, 67]),   # Cmaj7
    (43, [55, 59, 62, 67]),   # G
]

def add(buf, start, samples, amp=1.0):
    for i, s in enumerate(samples):
        buf[(start + i) % N] += s * amp

def pad_note(m, dur, detune):
    n = int(dur * SR); f = hz(m) * (1 + detune); a = int(1.6 * SR); r = int(2.2 * SR)
    res = []
    for i in range(n):
        env = min(1.0, i / a) * min(1.0, (n - i) / r)
        ph = 2 * math.pi * f * i / SR
        res.append(env * (math.sin(ph) + 0.35 * math.sin(2 * ph) + 0.12 * math.sin(3 * ph)))
    return res

def pluck(m, dur=1.4):
    n = int(dur * SR); f = hz(m); res = []
    for i in range(n):
        t = i / SR
        env = math.exp(-t * 3.2) * min(1.0, i / 120)
        ph = 2 * math.pi * f * t
        res.append(env * (math.sin(ph) + 0.4 * math.sin(2 * ph) * math.exp(-t * 6) + 0.15 * math.sin(4 * ph) * math.exp(-t * 10)))
    return res

def bass(m, dur):
    n = int(dur * SR); f = hz(m); res = []
    for i in range(n):
        env = min(1.0, i / 3000) * min(1.0, (n - i) / 9000)
        res.append(env * math.sin(2 * math.pi * f * i / SR))
    return res

for bar in range(16):
    b, chord = CH[bar % 4]
    s = bar * BAR
    for k, m in enumerate(chord):          # pad estéreo, levemente dessintonizado
        add(L, s, pad_note(m, 4.6, 0.0035), 0.075)
        add(R, s, pad_note(m, 4.6, -0.0035), 0.075)
    bs = bass(b, 3.8)
    add(L, s, bs, 0.20); add(R, s, bs, 0.20)
    cycle = bar // 4
    if cycle >= 1:                         # arpejo de colcheias a partir do 2º ciclo
        pat = [0, 2, 1, 3, 2, 1, 3, 2] if cycle != 2 else [3, 2, 1, 0, 1, 2, 3, 2]
        for j, idx in enumerate(pat):
            m = chord[idx] + (12 if cycle >= 2 else 0)
            p = pluck(m)
            pos = s + int(j * 0.5 * SR)
            pan = 0.35 + 0.3 * ((j % 4) / 3)
            add(L, pos, p, 0.07 * (1 - pan) * 2); add(R, pos, p, 0.07 * pan * 2)
    if cycle == 3 and bar % 2 == 0:        # sino agudo esparso
        p = pluck(chord[3] + 24, 2.5)
        add(L, s + 2 * SR, p, 0.05); add(R, s + 2 * SR + 900, p, 0.05)

def echo(buf, delay, fb, taps):           # eco circular (mantém o loop sem emenda)
    src = buf[:]
    out_ = buf[:]
    for t in range(1, taps + 1):
        d = (delay * t) % N
        g = fb ** t
        rot = src[-d:] + src[:-d]
        out_ = [a + g * b for a, b in zip(out_, rot)]
    return out_

L = echo(L, int(0.75 * SR), 0.45, 5)
R = echo(R, int(1.0 * SR), 0.45, 5)
to_ogg("mus_entrada", L, R, 3)

# ---------- SFX: tiro básico (~0,11 s), mono em 2 canais ----------
n = int(0.11 * SR); s = []
ph = 0.0
for i in range(n):
    t = i / SR
    f = 1500 - 5200 * t                    # varredura descendente curta e suave
    ph += 2 * math.pi * f / SR
    env = min(1.0, i / 90) * math.exp(-t * 32)
    s.append(env * (math.sin(ph) + 0.3 * math.sin(2 * ph)))
fade = 300
for i in range(fade): s[n - 1 - i] *= i / fade
to_ogg("sfx_tiro_basico", s, s, 2)
