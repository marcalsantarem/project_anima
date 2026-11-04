"""BRF-052: gera as 2 propostas de splash (720x1280, SVG + PNG) e o logotipo+núcleo transparente.
Uso: python gen_splash.py   (de qualquer pasta). Renderiza no Chrome headless (método dos mockups).
Saídas em assets/splash/: splash_a.*, splash_b.*, splash_logo_core.*, splash_bg_a.svg, splash_bg_b.svg
e prévias altas (720x1560) em _src/. A pasta tem .gdignore: nada disto entra no .pck."""
import subprocess, pathlib, re

HERE = pathlib.Path(__file__).resolve().parent
OUT = HERE.parent
CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
FONT = ('<style>@font-face{font-family:Outfit;src:url("%s");font-weight:100 900;}'
        '.t{font-family:Outfit,"Arial Rounded MT Bold",sans-serif;font-weight:800;}</style>')

INK = "#3A2A55"
PURPLE = "#7B5CE0"
PURPLE_D = "#4E3F8F"
RUNE = "#B9A5E8"
GOLD = "#FFC93D"
CREAM, CREAM_ALT = "#F6E9CF", "#EEDDBD"

# ---------- Núcleo-Anima (formas do mockup A; chão em (360,696), cristal em (360,586)) ----------
ANIMA_BASE = (
    '<path d="M304 660 L304 686 Q360 712 416 686 L416 660 Z" fill="#9FA3AB" stroke="#66686E" stroke-width="3.5" stroke-linejoin="round"/>'
    '<path d="M304 674 Q360 698 416 674" fill="none" stroke="#2FE6D2" stroke-width="4" opacity="0.8"/>'
    '<ellipse cx="360" cy="660" rx="56" ry="20" fill="#E4E9F5" stroke="#66686E" stroke-width="3.5"/>'
    '<ellipse cx="360" cy="660" rx="34" ry="11" fill="#2FE6D2" opacity="0.35"/>'
    '<ellipse cx="360" cy="660" rx="20" ry="6" fill="#E8FFFC" opacity="0.8"/>'
    '<ellipse cx="334" cy="652" rx="9" ry="2.6" fill="#FFFFFF" opacity="0.6"/>')
ANIMA_CRYSTAL = (
    '<path d="M360 540 L390 586 L360 632 L330 586 Z" fill="#2FE6D2" stroke="#15675E" stroke-width="3.5" stroke-linejoin="round"/>'
    '<path d="M360 540 L390 586 L360 632 Z" fill="#1E9588" opacity="0.45"/>'
    '<path d="M360 540 L330 586 L352 586 Z" fill="#E8FFFC" opacity="0.85"/>'
    '<path d="M330 586 L390 586" stroke="#15675E" stroke-width="2.1" opacity="0.6"/>'
    '<path d="M360 540 L390 586 L360 632 L330 586 Z" fill="none" stroke="#15675E" stroke-width="3.5" stroke-linejoin="round"/>')
GLOW_DEF = ('<radialGradient id="glow"><stop offset="0" stop-color="#2FE6D2" stop-opacity="0.45"/>'
            '<stop offset="0.5" stop-color="#2FE6D2" stop-opacity="0.16"/>'
            '<stop offset="1" stop-color="#2FE6D2" stop-opacity="0"/></radialGradient>')


def core(cx, gy, s, glow=True):
    """Núcleo com o ponto de chão em (cx, gy), escala s. Cristal flutuando + brilho + sombra.
    glow=False: sem brilho nem sombra (o shell os faz em CSS; deixa o PNG leve)."""
    fx = (f'<ellipse cx="360" cy="700" rx="70" ry="16" fill="#6B4E8C" opacity="0.22"/>'
          f'<circle cx="360" cy="590" r="96" fill="url(#glow)"/>') if glow else ""
    inner = (f'{fx}{ANIMA_BASE}'
             f'<g transform="translate(0 -6)">{ANIMA_CRYSTAL}</g>'
             # faíscas (alma) em volta do cristal
             f'<circle cx="318" cy="548" r="4" fill="#E8FFFC" stroke="#177369" stroke-width="1.5"/>'
             f'<circle cx="404" cy="560" r="3" fill="#E8FFFC" stroke="#177369" stroke-width="1.3"/>'
             f'<circle cx="398" cy="618" r="2.5" fill="#E8FFFC" opacity="0.9"/>')
    return f'<g transform="translate({cx} {gy}) scale({s}) translate(-360 -696)">{inner}</g>'


LOGO_DEF = ('<linearGradient id="gold" x1="0" y1="0" x2="0" y2="1">'
            '<stop offset="0" stop-color="#FFE48A"/><stop offset="0.55" stop-color="#FFC93D"/>'
            '<stop offset="1" stop-color="#FF9F2E"/></linearGradient>')


def logo(cx, y):
    """Logotipo em 2 linhas: 'PROJECT:' (fita roxa) e 'ANIMA' (dourado). y = linha de base de ANIMA."""
    big = (f'font-size="132" letter-spacing="4" text-anchor="middle" stroke-linejoin="round" '
           f'paint-order="stroke" class="t"')
    return (
        # fita roxa com "PROJECT:"
        f'<rect x="{cx - 128}" y="{y - 176}" width="256" height="58" rx="29" fill="{INK}"/>'
        f'<rect x="{cx - 128}" y="{y - 184}" width="256" height="58" rx="29" fill="{PURPLE}" stroke="{INK}" stroke-width="5"/>'
        f'<rect x="{cx - 112}" y="{y - 178}" width="224" height="16" rx="8" fill="#FFFFFF" opacity="0.2"/>'
        f'<text x="{cx}" y="{y - 142}" font-size="38" letter-spacing="6" text-anchor="middle" fill="#FFFFFF" '
        f'stroke="{INK}" stroke-width="6" stroke-linejoin="round" paint-order="stroke" class="t">PROJECT:</text>'
        # ANIMA: sombra, contorno e preenchimento dourado
        f'<text x="{cx}" y="{y + 9}" {big} fill="{INK}" stroke="{INK}" stroke-width="18">ANIMA</text>'
        f'<text x="{cx}" y="{y}" {big} fill="url(#gold)" stroke="{INK}" stroke-width="14">ANIMA</text>')


def progress(cx, y, frac=0.6, label="Carregando… 57%", w=440):
    """Barra pílula (track INK + fundo roxo-escuro, preenchimento dourado) e o texto abaixo."""
    x, h, fw = cx - w / 2, 40, (w - 12) * frac
    return (f'<rect x="{x}" y="{y + 7}" width="{w}" height="{h}" rx="{h / 2}" fill="{INK}"/>'
            f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{h / 2}" fill="#5B4A7A" stroke="{INK}" stroke-width="5"/>'
            f'<rect x="{x + 6}" y="{y + 6}" width="{fw}" height="{h - 12}" rx="{(h - 12) / 2}" fill="{GOLD}"/>'
            f'<rect x="{x + 14}" y="{y + 9}" width="{fw - 16}" height="7" rx="3.5" fill="#FFFFFF" opacity="0.45"/>'
            f'<text x="{cx}" y="{y + 92}" font-size="30" text-anchor="middle" fill="#FFFFFF" stroke="{INK}" '
            f'stroke-width="6" stroke-linejoin="round" paint-order="stroke" class="t">{label}</text>')


def rune_ring(cx, cy, k, c=RUNE, op=0.7):
    out = [f'<ellipse cx="{cx}" cy="{cy}" rx="{250 * k}" ry="{188 * k}" fill="none" stroke="{c}" stroke-width="{10 * k}" opacity="{op}"/>',
           f'<ellipse cx="{cx}" cy="{cy}" rx="{226 * k}" ry="{170 * k}" fill="none" stroke="{c}" stroke-width="{3 * k}" opacity="{op}"/>']
    for dx, dy in ((220, 69), (91, 165), (-91, 165), (-220, 69), (-220, -69), (-91, -165), (91, -165), (220, -69)):
        out.append(f'<path d="M{cx + dx * k:.1f} {cy + dy * k - 10 * k:.1f} l{8 * k:.1f} {10 * k:.1f} '
                   f'l{-8 * k:.1f} {10 * k:.1f} l{-8 * k:.1f} {-10 * k:.1f} Z" fill="{c}" opacity="{op}"/>')
    return "".join(out)


def sparkle(x, y, r, c=GOLD, op=1.0):
    return (f'<path d="M{x} {y - r} Q{x + r * .18} {y - r * .18} {x + r} {y} Q{x + r * .18} {y + r * .18} {x} {y + r} '
            f'Q{x - r * .18} {y + r * .18} {x - r} {y} Q{x - r * .18} {y - r * .18} {x} {y - r} Z" fill="{c}" opacity="{op}"/>')


PILLAR = ('<path d="M58 260 L58 296 Q80 308 102 296 L102 260 Z" fill="#B7A8EA" stroke="#4E3F8F" stroke-width="3.5"/>'
          '<ellipse cx="80" cy="260" rx="22" ry="8" fill="#DCD3FA" stroke="#4E3F8F" stroke-width="3.5"/>'
          '<path d="M80 214 L92 244 L80 258 L68 244 Z" fill="#FFB84D" stroke="#8A4F12" stroke-width="3" stroke-linejoin="round"/>'
          '<path d="M80 214 L68 244 L77 244 Z" fill="#FFF3D1"/>')


def pillar(x, y, s=1.0):
    return (f'<g transform="translate({x} {y}) scale({s}) translate(-80 -302)">'
            f'<ellipse cx="80" cy="302" rx="30" ry="8" fill="#6B4E8C" opacity="0.22"/>{PILLAR}</g>')


# ---------- Fundos (esticáveis: H de 1280 a 1560; o conteúdo fica centrado) ----------
def bg_a(H):
    """Chão quadriculado creme (pattern) + selo rúnico centrado + sombra roxa no topo e na base."""
    cy = H / 2 - 4
    return (f'<defs><pattern id="ck" width="120" height="120" patternUnits="userSpaceOnUse" y="{(H / 2) % 120}">'
            f'<rect width="120" height="120" fill="{CREAM}"/><rect width="60" height="60" fill="{CREAM_ALT}"/>'
            f'<rect x="60" y="60" width="60" height="60" fill="{CREAM_ALT}"/></pattern>'
            f'<linearGradient id="sh" x1="0" y1="0" x2="0" y2="1">'
            f'<stop offset="0" stop-color="{INK}" stop-opacity="0.32"/><stop offset="0.22" stop-color="{INK}" stop-opacity="0"/>'
            f'<stop offset="0.8" stop-color="{INK}" stop-opacity="0"/><stop offset="1" stop-color="{INK}" stop-opacity="0.28"/>'
            f'</linearGradient></defs>'
            f'<rect width="720" height="{H}" fill="url(#ck)"/>'
            f'{rune_ring(360, cy, 1.1)}'
            f'<rect width="720" height="{H}" fill="url(#sh)"/>')


def bg_b(H):
    """Roxo da UI em degradê vertical + selo rúnico grande e suave atrás do núcleo + faíscas douradas."""
    cy = H / 2 - 170
    sp = "".join(sparkle(x, y + (H - 1280) / 2, r, GOLD, o) for x, y, r, o in (
        (96, 210, 10, .8), (628, 300, 8, .7), (80, 760, 7, .6), (650, 860, 11, .8), (180, 1180, 6, .5), (560, 1150, 8, .6)))
    return (f'<defs><linearGradient id="pg" x1="0" y1="0" x2="0" y2="1">'
            f'<stop offset="0" stop-color="#8E72EC"/><stop offset="0.55" stop-color="{PURPLE}"/>'
            f'<stop offset="1" stop-color="{PURPLE_D}"/></linearGradient></defs>'
            f'<rect width="720" height="{H}" fill="url(#pg)"/>'
            f'{rune_ring(360, cy, 1.25, "#DCD3FA", 0.35)}{rune_ring(360, cy, 0.8, "#DCD3FA", 0.22)}{sp}')


def disc_b(cx, gy):
    """Plataforma de chão creme (recorte elíptico do xadrez) sob o núcleo, na proposta B."""
    return (f'<defs><clipPath id="dc"><ellipse cx="{cx}" cy="{gy}" rx="200" ry="74"/></clipPath>'
            f'<pattern id="ckb" width="80" height="80" patternUnits="userSpaceOnUse" x="{cx - 40}" y="{gy - 40}">'
            f'<rect width="80" height="80" fill="{CREAM}"/><rect width="40" height="40" fill="{CREAM_ALT}"/>'
            f'<rect x="40" y="40" width="40" height="40" fill="{CREAM_ALT}"/></pattern></defs>'
            f'<ellipse cx="{cx}" cy="{gy + 16}" rx="204" ry="76" fill="{INK}"/>'
            f'<ellipse cx="{cx}" cy="{gy}" rx="200" ry="74" fill="url(#ckb)" stroke="{INK}" stroke-width="5"/>'
            f'<ellipse cx="{cx}" cy="{gy}" rx="150" ry="52" fill="none" stroke="{RUNE}" stroke-width="5" clip-path="url(#dc)"/>')


def svg(w, h, inner, font_rel, scale=1):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w * scale}" height="{h * scale}" viewBox="0 0 {w} {h}">'
            f'{FONT % font_rel}<defs>{GLOW_DEF}{LOGO_DEF}</defs>{inner}</svg>')


def splash_a(H=1280):
    o = (H - 1280) / 2
    return (bg_a(H) + pillar(120, 820 + o, 1.2) + pillar(600, 820 + o, 1.2)
            + logo(360, 330 + o) + core(360, 830 + o, 2.4) + progress(360, 1060 + o))


def splash_b(H=1280):
    o = (H - 1280) / 2
    return (bg_b(H) + disc_b(360, 630 + o) + core(360, 600 + o, 2.5)
            + logo(360, 920 + o) + progress(360, 1060 + o))


LOGO_W, LOGO_H = 560, 760  # logotipo + núcleo sem fundo (1x)


def logo_core():
    return core(280, 460, 2.2, glow=False) + logo(280, 700)


def render(svg_path, png_path, w, h, transparent=False):
    args = [CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", f"--window-size={w},{h}",
            f"--screenshot={png_path}", svg_path.as_uri()]
    if transparent:
        args.insert(3, "--default-background-color=00000000")
    subprocess.run(args, check=True, capture_output=True)


def minify(s):
    return re.sub(r">\s+<", "><", s)


if __name__ == "__main__":
    f_out, f_src = "../fonts/Outfit-Variable.ttf", "../../fonts/Outfit-Variable.ttf"
    jobs = [
        (OUT / "splash_a", 720, 1280, splash_a(), f_out, False),
        (OUT / "splash_b", 720, 1280, splash_b(), f_out, False),
        (OUT / "splash_logo_core", LOGO_W, LOGO_H, logo_core(), f_out, True),
        (HERE / "preview_a_720x1560", 720, 1560, splash_a(1560), f_src, False),
        (HERE / "preview_b_720x1560", 720, 1560, splash_b(1560), f_src, False),
    ]
    for base, w, h, inner, fr, tr in jobs:
        sp = base.with_suffix(".svg")
        sp.write_text(svg(w, h, inner, fr), encoding="utf-8")
        render(sp, base.with_suffix(".png"), w, h, tr)
        print("ok", base.name)
    # Fundos sozinhos (sem texto/núcleo) para o shell: SVG mínimo, esticável via viewBox 720x1560 + slice.
    for name, fn in (("splash_bg_a", bg_a), ("splash_bg_b", bg_b)):
        (OUT / f"{name}.svg").write_text(minify(
            f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 720 1560" preserveAspectRatio="xMidYMid slice">'
            f'{fn(1560)}</svg>'), encoding="utf-8")
        print("ok", name)
    # Versão leve para a web: WebP com alfa (q85), ~22 KB. Precisa do ffmpeg no PATH.
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", str(OUT / "splash_logo_core.png"), "-pix_fmt", "yuva420p",
                    "-c:v", "libwebp", "-q:v", "85", "-compression_level", "6", str(OUT / "splash_logo_core.webp")], check=True)
    print("ok splash_logo_core.webp")
