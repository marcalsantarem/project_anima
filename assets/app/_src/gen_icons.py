"""BRF-071 (T-174): ícones do app (tela de início do iPhone, PWA, favicon).
Uso: python gen_icons.py   (de qualquer pasta). Precisa do Chrome (render) e do ffmpeg no PATH (paleta/compressão).
Reaproveita as formas do núcleo-Anima e do selo rúnico de assets/splash/_src/gen_splash.py.
Saídas em assets/app/ (pasta com .gdignore: fica fora do .pck) e prévias em _src/."""
import pathlib, struct, subprocess, sys, tempfile

HERE = pathlib.Path(__file__).resolve().parent
OUT = HERE.parent
sys.path.insert(0, str(OUT.parent / "splash" / "_src"))
from gen_splash import CHROME, GLOW_DEF, GOLD, core, rune_ring, sparkle  # noqa: E402

S = 1024
BG = ('<linearGradient id="bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8E72EC"/>'
      '<stop offset="0.5" stop-color="#7B5CE0"/><stop offset="1" stop-color="#5A4A9A"/></linearGradient>'
      '<radialGradient id="halo"><stop offset="0" stop-color="#2FE6D2" stop-opacity="0.55"/>'
      '<stop offset="0.45" stop-color="#2FE6D2" stop-opacity="0.18"/><stop offset="1" stop-color="#2FE6D2" stop-opacity="0"/></radialGradient>')


def icon(s=3.8, ring=True, sparks=True):
    """Arte 1024x1024. s = escala do núcleo; o símbolo fica centrado (alto ~178*s px)."""
    gy = 512 + 82 * s                      # ponto de chão do núcleo; centro visual em ~512
    cy = gy - 106 * s                      # centro do cristal
    out = [f'<rect width="{S}" height="{S}" fill="url(#bg)"/>']
    if ring:  # selo rúnico no chão, sob o pedestal (discreto)
        out.append(rune_ring(512, gy - 6 * s, 0.30 * s, "#DCD3FA", 0.30))
        out.append(rune_ring(512, gy - 6 * s, 0.19 * s, "#DCD3FA", 0.20))
    out.append(f'<circle cx="512" cy="{cy:.0f}" r="{120 * s:.0f}" fill="url(#halo)"/>')
    if sparks:
        out += [sparkle(512 + dx * s, cy + dy * s, r * s, GOLD, o) for dx, dy, r, o in
                ((-78, -40, 9, .9), (80, 12, 7, .8), (-66, 58, 5, .6))]
    out.append(core(512, gy, s))
    return "".join(out)


def svg(n, inner):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{n}" height="{n}" viewBox="0 0 {S} {S}">'
            f'<defs>{GLOW_DEF}{BG}</defs>{inner}</svg>')


def render(inner, n, png, svg_keep=None):
    """Renderiza o vetor direto no tamanho final (nítido) e grava PNG RGB sem alfa."""
    with tempfile.TemporaryDirectory() as td:
        sp = pathlib.Path(td) / "i.svg"
        sp.write_text(svg(n, inner), encoding="utf-8")
        if svg_keep:
            svg_keep.write_text(svg(S, inner), encoding="utf-8")
        w = max(n, 256)  # janela mínima do Chrome; recorta depois
        raw = pathlib.Path(td) / "raw.png"
        subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--force-device-scale-factor=1",
                        f"--window-size={w},{w}", f"--screenshot={raw}", sp.as_uri()], check=True, capture_output=True)
        vf = f"crop={n}:{n}:0:0"
        if n < S:  # paleta de 128 cores com dither leve: PNG pequeno sem banda visível
            vf += ",split[a][b];[a]palettegen=max_colors=128:stats_mode=full[p];[b][p]paletteuse=dither=bayer:bayer_scale=5"
            fmt = []
        else:
            fmt = ["-pix_fmt", "rgb24"]
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", str(raw), "-vf", vf, *fmt,
                        "-compression_level", "9", str(png)], check=True)


def write_ico(pngs, path):
    """ICO com entradas PNG (16/32/48)."""
    data = [p.read_bytes() for p in pngs]
    head = struct.pack("<HHH", 0, 1, len(data))
    off, ents = 6 + 16 * len(data), b""
    for p, d in zip(pngs, data):
        n = int(p.stem.rsplit("-", 1)[1]) if "-" in p.stem else 16
        ents += struct.pack("<BBBBHHII", n % 256, n % 256, 0, 0, 1, 32, len(d), off)
        off += len(d)
    path.write_bytes(head + ents + b"".join(data))


if __name__ == "__main__":
    master, mask, small = icon(), icon(s=3.2), icon(s=5.0, ring=False, sparks=False)
    jobs = [("app_icon_master", S, master), ("apple-touch-icon-180", 180, master), ("icon-192", 192, master),
            ("icon-512", 512, master), ("icon-maskable-512", 512, mask),
            ("favicon-48", 48, small), ("favicon-32", 32, small)]
    for name, n, inner in jobs:
        keep = HERE / f"{name}.svg" if name in ("app_icon_master",) else None
        render(inner, n, OUT / f"{name}.png", keep)
        print("ok", name, (OUT / f"{name}.png").stat().st_size, "B")
    (HERE / "icon_maskable_master.svg").write_text(svg(S, mask), encoding="utf-8")
    (HERE / "favicon_master.svg").write_text(svg(S, small), encoding="utf-8")
    render(small, 16, HERE / "favicon-16.png")
    write_ico([HERE / "favicon-16.png", OUT / "favicon-32.png", OUT / "favicon-48.png"], OUT / "favicon.ico")
    print("ok favicon.ico", (OUT / "favicon.ico").stat().st_size, "B")
