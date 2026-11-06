"""BRF-084 (T-181): ícones do app (tela de início do iPhone, PWA, favicon) na identidade tecnológica.
Uso: python gen_icons.py   (de qualquer pasta). Precisa do Chrome (render) e do ffmpeg no PATH (paleta/compressão).
Cristal holográfico ciano sobre azul-marinho, redesenhado em vetor no estilo da arte-base
assets/splash/tech/tech_splash_clean.png (a fonte tem 768 px de largura; recortar dela não serve ao mestre 1024).
Saídas em assets/app/ (pasta com .gdignore: fica fora do .pck) e prévias em _src/."""
import pathlib, struct, subprocess, sys, tempfile

HERE = pathlib.Path(__file__).resolve().parent
OUT = HERE.parent
sys.path.insert(0, str(OUT.parent / "splash" / "_src"))
from gen_splash import CHROME  # noqa: E402

S = 1024
NAVY = "#021423"  # = theme_color/background_color do manifesto
DEFS = (
    '<radialGradient id="bg" cx="0.5" cy="0.46" r="0.72"><stop offset="0" stop-color="#0B3350"/>'
    '<stop offset="0.55" stop-color="#062039"/><stop offset="1" stop-color="' + NAVY + '"/></radialGradient>'
    '<radialGradient id="halo"><stop offset="0" stop-color="#3FE8FF" stop-opacity="0.42"/>'
    '<stop offset="0.5" stop-color="#3FE8FF" stop-opacity="0.12"/><stop offset="1" stop-color="#3FE8FF" stop-opacity="0"/></radialGradient>'
    '<radialGradient id="haze"><stop offset="0" stop-color="#8A4FE0" stop-opacity="0.55"/>'
    '<stop offset="1" stop-color="#8A4FE0" stop-opacity="0"/></radialGradient>'
    '<radialGradient id="core"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.35" stop-color="#C8FFFF" stop-opacity="0.85"/>'
    '<stop offset="1" stop-color="#5CF2FF" stop-opacity="0"/></radialGradient>'
    '<linearGradient id="fTL" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#B4FCFF"/><stop offset="1" stop-color="#32D6EE"/></linearGradient>'
    '<linearGradient id="fTR" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#4FE6F8"/><stop offset="1" stop-color="#1690C4"/></linearGradient>'
    '<linearGradient id="fBL" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#28C2E2"/><stop offset="1" stop-color="#6A6AE6"/></linearGradient>'
    '<linearGradient id="fBR" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#127FB4"/><stop offset="1" stop-color="#7A4FD6"/></linearGradient>'
    '<filter id="blur" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="34"/></filter>')


def P(*pts):
    return " ".join(f"{x:.1f},{y:.1f}" for x, y in pts)


def crystal(cx, cy, h, w, solid=False):
    """Octaedro alongado visto de leve por cima: faces translúcidas, arestas claras, núcleo de luz."""
    T, Bo = (cx, cy - 0.48 * h), (cx, cy + 0.50 * h)
    ey = cy - 0.02 * h
    L, R = (cx - w / 2, ey), (cx + w / 2, ey)
    F, Bk = (cx + 0.05 * w, ey + 0.06 * h), (cx - 0.05 * w, ey - 0.05 * h)
    op = 1.0 if solid else 0.78
    sw = w * (0.022 if solid else 0.011)
    o = [f'<polygon points="{P(T, R, Bo, L)}" fill="#3FE8FF" opacity="0.6" filter="url(#blur)"/>']
    if not solid:  # faces de trás vistas pela transparência
        o.append(f'<polygon points="{P(T, L, Bk, R)} " fill="#0E6E9A" opacity="0.35"/>')
    o += [f'<polygon points="{P(T, L, F)}" fill="url(#fTL)" opacity="{op}"/>',
          f'<polygon points="{P(T, F, R)}" fill="url(#fTR)" opacity="{op}"/>',
          f'<polygon points="{P(L, F, Bo)}" fill="url(#fBL)" opacity="{op}"/>',
          f'<polygon points="{P(F, R, Bo)}" fill="url(#fBR)" opacity="{op}"/>']
    if not solid:  # arestas de trás + cristal interno (efeito holográfico)
        o.append(f'<polyline points="{P(L, Bk, R)}" fill="none" stroke="#9FF6FF" stroke-width="{sw * .6:.1f}" opacity="0.45"/>'
                 f'<line x1="{T[0]}" y1="{T[1]}" x2="{Bk[0]}" y2="{Bk[1]}" stroke="#9FF6FF" stroke-width="{sw * .6:.1f}" opacity="0.35"/>')
        k = 0.42
        it = lambda p: (cx + (p[0] - cx) * k, ey + (p[1] - ey) * k)  # noqa: E731
        o.append(f'<polygon points="{P(it(T), it(R), it(Bo), it(L))}" fill="none" stroke="#E6FFFF" '
                 f'stroke-width="{sw * .7:.1f}" opacity="0.55" stroke-linejoin="round"/>'
                 f'<polyline points="{P(it(T), it(F), it(Bo))}" fill="none" stroke="#E6FFFF" stroke-width="{sw * .6:.1f}" opacity="0.45"/>'
                 f'<polyline points="{P(it(L), it(F), it(R))}" fill="none" stroke="#E6FFFF" stroke-width="{sw * .6:.1f}" opacity="0.45"/>')
    o.append(f'<polygon points="{P(T, R, Bo, L)}" fill="none" stroke="#D8FFFF" stroke-width="{sw:.1f}" stroke-linejoin="round"/>'
             f'<polyline points="{P(L, F, R)}" fill="none" stroke="#D8FFFF" stroke-width="{sw * .8:.1f}" stroke-linejoin="round"/>'
             f'<line x1="{T[0]}" y1="{T[1]}" x2="{F[0]}" y2="{F[1]}" stroke="#FFFFFF" stroke-width="{sw * .8:.1f}" opacity="0.9"/>'
             f'<line x1="{F[0]}" y1="{F[1]}" x2="{Bo[0]}" y2="{Bo[1]}" stroke="#D8FFFF" stroke-width="{sw * .6:.1f}" opacity="0.7"/>')
    c, r = (cx + 0.01 * w, ey - 0.01 * h), w * (0.30 if solid else 0.24)
    o.append(f'<circle cx="{c[0]:.1f}" cy="{c[1]:.1f}" r="{r:.1f}" fill="url(#core)"/>')
    if not solid:  # brilho em estrela de 4 pontas no núcleo
        a, b = w * 0.20, w * 0.025
        o.append(f'<path d="M{c[0]:.1f},{c[1] - a:.1f} L{c[0] + b:.1f},{c[1]:.1f} L{c[0]:.1f},{c[1] + a:.1f} '
                 f'L{c[0] - b:.1f},{c[1]:.1f}Z M{c[0] - a:.1f},{c[1]:.1f} L{c[0]:.1f},{c[1] - b:.1f} L{c[0] + a:.1f},{c[1]:.1f} '
                 f'L{c[0]:.1f},{c[1] + b:.1f}Z" fill="#FFFFFF" opacity="0.9"/>')
    return "".join(o)


def orbit(cx, cy, rx, ry, half):
    """Anel HUD em elipse; half='back' (metade de cima, atrás do cristal) ou 'front' (metade de baixo)."""
    sweep = 1 if half == "back" else 0
    d = f"M{cx - rx:.1f},{cy:.1f} A{rx:.1f},{ry:.1f} 0 0 {sweep} {cx + rx:.1f},{cy:.1f}"
    d2 = f"M{cx - rx * .82:.1f},{cy:.1f} A{rx * .82:.1f},{ry * .82:.1f} 0 0 {sweep} {cx + rx * .82:.1f},{cy:.1f}"
    return (f'<path d="{d}" fill="none" stroke="#5CEBFF" stroke-width="5" opacity="0.30"/>'
            f'<path d="{d2}" fill="none" stroke="#5CEBFF" stroke-width="3" stroke-dasharray="40 18 6 18" opacity="0.38"/>')


def icon(k=1.0, deco=True, solid=False):
    """Arte 1024x1024. k = escala do símbolo (cristal com ~700*k px de altura, centrado)."""
    cy, h, w = 512, 700 * k, 380 * k
    ey = cy - 0.02 * h
    out = [f'<rect width="{S}" height="{S}" fill="url(#bg)"/>',
           f'<ellipse cx="512" cy="{cy + 0.30 * h:.0f}" rx="{330 * k:.0f}" ry="{230 * k:.0f}" fill="url(#haze)"/>',
           f'<circle cx="512" cy="{ey:.0f}" r="{420 * k:.0f}" fill="url(#halo)"/>']
    if deco:
        out += [f'<circle cx="{x}" cy="{y}" r="{r}" fill="{c}" opacity="{o}"/>' for x, y, r, c, o in
                ((150, 210, 5, "#9FF6FF", .7), (880, 260, 4, "#FFFFFF", .6), (210, 760, 4, "#5CEBFF", .6),
                 (850, 800, 5, "#B89BFF", .6), (300, 120, 3, "#FFFFFF", .5), (760, 900, 3, "#9FF6FF", .5))]
        out.append(orbit(512, ey, 430 * k, 120 * k, "back"))
    out.append(crystal(512, cy, h, w, solid))
    if deco:
        out.append(orbit(512, ey, 430 * k, 120 * k, "front"))
    return "".join(out)


def svg(n, inner):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{n}" height="{n}" viewBox="0 0 {S} {S}">'
            f'<defs>{DEFS}</defs>{inner}</svg>')


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
                        "--default-background-color=021423ff",
                        f"--window-size={w},{w}", f"--screenshot={raw}", sp.as_uri()], check=True, capture_output=True)
        vf = f"crop={n}:{n}:0:0"
        if n < S:  # paleta de 128 cores com dither leve: PNG pequeno sem banda visível
            vf += ",format=rgb24,split[a][b];[a]palettegen=max_colors=128:stats_mode=full:reserve_transparent=0[p];[b][p]paletteuse=dither=bayer:bayer_scale=5"
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
    # mestre; maskable com cristal e anéis dentro do círculo de 80% (raio 410); favicon sem enfeites, faces opacas
    master, mask, small = icon(), icon(k=0.84), icon(k=1.28, deco=False, solid=True)
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
