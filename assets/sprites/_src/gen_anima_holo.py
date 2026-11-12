"""Anima holográfico da partida (T-291, BRF-126, decisão 64). Substitui o Anima cartoon (backup em anima_cartoon_backup/).
Mesmo canvas e âncoras do dado (data/anima/anima_default.tres): base 256x256 âncora (128,200); cristal 256x256 âncora
(128,128), centro 110 px 1x acima da base; nó 64x64 âncora (32,32). Desenho em 1x, PNG em 2x (Chrome headless).
Uso: python gen_anima_holo.py          -> PNGs em assets/sprites/
     python gen_anima_holo.py preview  -> + docs/img/anima-holo-arena.png (720x1280) e anima-holo-arena-375x812.png"""
import subprocess, pathlib, re, sys

HERE = pathlib.Path(__file__).resolve().parent
SPR = HERE.parent
ROOT = SPR.parent.parent
UI_SRC = ROOT / "assets" / "ui" / "_src"
CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
FFMPEG = "ffmpeg"
SCALE = 2

INK = "#03202E"      # holo_ink: contorno (legível no chão creme)
LINE = "#3FE8F5"     # holo_line: aro e luz
TEXT = "#E6FFFF"     # holo_text: brilho máximo
DEEP = "#0B6E86"     # ciano profundo (faceta escura)
NAVY = "#06223A"     # holo_panel: vidro do topo

# Pedestal: âncora (64,100) 1x. Degrau de baixo (topo y=78) e de cima (topo y=64); cristal flutua acima.
BASE = f'''
<defs>
 <linearGradient id="steel" x1="0" x2="1">
  <stop offset="0" stop-color="#5A6B7E"/><stop offset=".22" stop-color="#C9D6E2"/><stop offset=".45" stop-color="#F2F7FB"/>
  <stop offset=".7" stop-color="#93A4B6"/><stop offset="1" stop-color="#3E4D5E"/></linearGradient>
 <linearGradient id="steelTop" x1="0" y1="0" x2="0" y2="1">
  <stop offset="0" stop-color="#F4F9FC"/><stop offset="1" stop-color="#9FB0C2"/></linearGradient>
 <radialGradient id="glass" cx=".5" cy=".45" r=".6">
  <stop offset="0" stop-color="#1F8FA8"/><stop offset=".55" stop-color="{NAVY}"/><stop offset="1" stop-color="#021423"/></radialGradient>
 <radialGradient id="emit" cx=".5" cy=".5" r=".5">
  <stop offset="0" stop-color="{TEXT}"/><stop offset=".35" stop-color="{LINE}" stop-opacity=".9"/>
  <stop offset="1" stop-color="{LINE}" stop-opacity="0"/></radialGradient>
 <linearGradient id="beam" x1="0" y1="1" x2="0" y2="0">
  <stop offset="0" stop-color="{LINE}" stop-opacity=".45"/><stop offset="1" stop-color="{LINE}" stop-opacity="0"/></linearGradient>
 <radialGradient id="floorGlow" cx=".5" cy=".5" r=".5">
  <stop offset="0" stop-color="{LINE}" stop-opacity=".35"/><stop offset="1" stop-color="{LINE}" stop-opacity="0"/></radialGradient>
</defs>
<ellipse cx="64" cy="96" rx="64" ry="22" fill="url(#floorGlow)"/>
<!-- degrau de baixo -->
<path d="M6 80 L6 90 A58 13 0 0 0 122 90 L122 80 Z" fill="url(#steel)" stroke="{INK}" stroke-width="3" stroke-linejoin="round"/>
<path d="M8 86 A56 12 0 0 0 120 86" fill="none" stroke="{LINE}" stroke-width="2.5"/>
<ellipse cx="64" cy="80" rx="58" ry="17" fill="url(#steelTop)" stroke="{INK}" stroke-width="3"/>
<!-- luzes do degrau de baixo (cápsulas) -->
{''.join(f'<rect x="{x - 4}" y="{y - 2.5}" width="8" height="5" rx="2.5" fill="{TEXT}" stroke="{DEEP}" stroke-width="1.2"/>'
         for x, y in ((24, 93), (64, 99), (104, 93)))}
<!-- degrau de cima -->
<path d="M18 66 L18 76 A46 13 0 0 0 110 76 L110 66 Z" fill="url(#steel)" stroke="{INK}" stroke-width="3" stroke-linejoin="round"/>
<path d="M20 72 A44 12 0 0 0 108 72" fill="none" stroke="{LINE}" stroke-width="3"/>
<path d="M20 72 A44 12 0 0 0 108 72" fill="none" stroke="{TEXT}" stroke-width="1" opacity=".9"/>
<ellipse cx="64" cy="66" rx="46" ry="14" fill="url(#steelTop)" stroke="{INK}" stroke-width="3"/>
<!-- vidro do emissor com anéis holográficos -->
<ellipse cx="64" cy="66" rx="36" ry="10.5" fill="url(#glass)" stroke="#5A6B7E" stroke-width="1.5"/>
<ellipse cx="64" cy="66" rx="29" ry="8.2" fill="none" stroke="{LINE}" stroke-width="1.6" opacity=".9"/>
<ellipse cx="64" cy="66" rx="20" ry="5.6" fill="none" stroke="{LINE}" stroke-width="1.2" stroke-dasharray="5 3" opacity=".8"/>
<ellipse cx="64" cy="66" rx="16" ry="6" fill="url(#emit)"/>
<!-- feixe de luz até o cristal (fica atrás dele) -->
<path d="M50 66 L56 22 L72 22 L78 66 Z" fill="url(#beam)"/>
<!-- reflexo no aro -->
<path d="M30 59 A40 11 0 0 1 60 53" fill="none" stroke="#FFFFFF" stroke-width="2.2" stroke-linecap="round" opacity=".85"/>
'''

# Cristal: centro (64,64) 1x. Losango alongado, faixa média um pouco acima do centro (como no título).
T, L, R, B, M = (64, 16), (40, 58), (88, 58), (64, 112), (64, 64)
def P(*pts):
    return "M" + " L".join(f"{x} {y}" for x, y in pts) + " Z"

def ring(half):  # metade de trás (0) ou da frente (1) da trilha dos nós (elipse 29x12 1x)
    sweep = "0 0 0" if half == 0 else "0 0 1"
    return (f'<path d="M35 64 A29 12 {sweep} 93 64" fill="none" stroke="{LINE}" stroke-width="1.4" '
            f'stroke-dasharray="{"3 4" if half == 0 else "none"}" opacity="{.45 if half == 0 else .75}"/>')

CRYSTAL = f'''
<defs>
 <radialGradient id="halo" cx=".5" cy=".5" r=".5">
  <stop offset="0" stop-color="{LINE}" stop-opacity=".55"/><stop offset=".5" stop-color="{LINE}" stop-opacity=".2"/>
  <stop offset="1" stop-color="{LINE}" stop-opacity="0"/></radialGradient>
 <linearGradient id="fL" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="{TEXT}"/><stop offset="1" stop-color="#7FF3FA"/></linearGradient>
 <linearGradient id="fR" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#52E2F0"/><stop offset="1" stop-color="#1497B0"/></linearGradient>
 <linearGradient id="fBL" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5DE9F4"/><stop offset="1" stop-color="#18A9C2"/></linearGradient>
 <linearGradient id="fBR" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#1497B0"/><stop offset="1" stop-color="{DEEP}"/></linearGradient>
 <filter id="blur" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="3"/></filter>
</defs>
<circle cx="64" cy="64" r="60" fill="url(#halo)"/>
{ring(0)}
<!-- brilho por fora do contorno -->
<path d="{P(T, R, B, L)}" fill="{LINE}" filter="url(#blur)" opacity=".85"/>
<!-- facetas -->
<path d="{P(T, M, L)}" fill="url(#fL)"/>
<path d="{P(T, R, M)}" fill="url(#fR)"/>
<path d="{P(L, M, B)}" fill="url(#fBL)"/>
<path d="{P(M, R, B)}" fill="url(#fBR)"/>
<!-- arestas internas e núcleo de luz -->
<path d="M{T[0]} {T[1]} L64 112 M40 58 L64 64 L88 58" fill="none" stroke="{TEXT}" stroke-width="1.3" opacity=".75"/>
<ellipse cx="64" cy="62" rx="7" ry="11" fill="{TEXT}" opacity=".55" filter="url(#blur)"/>
<path d="M58 30 L50 52 L56 52 Z" fill="#FFFFFF" opacity=".9"/>
<path d="{P(T, R, B, L)}" fill="none" stroke="{INK}" stroke-width="2.6" stroke-linejoin="round"/>
<path d="{P(T, R, B, L)}" fill="none" stroke="{LINE}" stroke-width="1" stroke-linejoin="round" opacity=".6"/>
<!-- cintilação -->
<path d="M82 26 L84 32 L90 34 L84 36 L82 42 L80 36 L74 34 L80 32 Z" fill="#FFFFFF" opacity=".9"/>
{ring(1)}
'''

# Nó orbital: centro (16,16) 1x. Orbe de energia com contorno escuro (lê no chão creme) e aura.
NODE = f'''
<defs>
 <radialGradient id="aura" cx=".5" cy=".5" r=".5">
  <stop offset="0" stop-color="{LINE}" stop-opacity=".7"/><stop offset="1" stop-color="{LINE}" stop-opacity="0"/></radialGradient>
 <radialGradient id="core" cx=".38" cy=".35" r=".7">
  <stop offset="0" stop-color="#FFFFFF"/><stop offset=".45" stop-color="{TEXT}"/><stop offset="1" stop-color="{LINE}"/></radialGradient>
</defs>
<circle cx="16" cy="16" r="15" fill="url(#aura)"/>
<circle cx="16" cy="16" r="6.5" fill="url(#core)" stroke="{INK}" stroke-width="1.8"/>
<circle cx="16" cy="16" r="9.5" fill="none" stroke="{LINE}" stroke-width="1" opacity=".7"/>
<circle cx="14" cy="13.8" r="1.6" fill="#FFFFFF"/>
'''

SPRITES = {
    "anima_default_base": (128, 128, BASE),
    "anima_default_crystal": (128, 128, CRYSTAL),
    "anima_default_node": (32, 32, NODE),
}


def svg(w, h, inner):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w * SCALE}" height="{h * SCALE}" '
            f'viewBox="0 0 {w} {h}">{inner}</svg>')


def render(src, png, w, h):
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--allow-file-access-from-files",
                    "--default-background-color=00000000", f"--window-size={w},{h}",
                    "--virtual-time-budget=1500", f"--screenshot={png}", src.as_uri()], check=True, capture_output=True)


def optimize(png):
    tmp = png.with_suffix(".tmp.png")
    r = subprocess.run([FFMPEG, "-y", "-loglevel", "error", "-i", str(png), "-pix_fmt", "rgba", "-pred", "mixed",
                        "-compression_level", "9", str(tmp)], capture_output=True)
    if r.returncode == 0 and tmp.stat().st_size < png.stat().st_size:
        tmp.replace(png)
    elif tmp.exists():
        tmp.unlink()


def preview():
    """Anima holo sobre a arena + HUD da T-289 (reaproveita os mockups do AG08 em assets/ui/_src) e acrescenta os nós."""
    def nodes(cx, cy):  # centro do cristal em px de tela; 3 nós na elipse 29x12, em ângulos de uma fase qualquer
        import math
        out = ""
        for i in range(3):
            a = 0.6 + i * 2 * math.pi / 3
            x, y = cx + 29 * math.cos(a), cy + 12 * math.sin(a)
            out += f'<img src="../../sprites/anima_default_node.png" style="position:absolute;left:{x - 16:.1f}px;top:{y - 16:.1f}px;width:32px;height:32px;">'
        return out
    for src, out, h, small in (("hud_mockup_720.html", "anima-holo-arena.png", 1280, False),
                               ("hud_mockup_375.html", "anima-holo-arena-375x812.png", 1559, True)):
        html = (UI_SRC / src).read_text(encoding="utf-8")
        # O mockup da T-289 põe o cristal 146 px acima do chão; no jogo são 110 (crystal_height). Corrige aqui.
        base_top = int(re.search(r'anima_default_base\.png" style="position:absolute;left:\d+px;top:(\d+)px', html).group(1))
        m = re.search(r'anima_default_crystal\.png" style="position:absolute;left:(\d+)px;top:(\d+)px', html)
        tag = m.group(0).replace(f"top:{m.group(2)}px", f"top:{base_top + 100 - 110 - 64}px")
        html = html.replace(m.group(0), tag)
        cx, cy = int(m.group(1)) + 64, base_top + 100 - 110
        end = html.index(">", html.index(tag)) + 1
        html = html[:end] + nodes(cx, cy) + html[end:]
        html = html.replace("<head>", f'<head><base href="{UI_SRC.as_uri()}/">', 1)  # caminhos relativos do mockup
        p = HERE / f"_anima_holo_{src}"
        p.write_text(html, encoding="utf-8")
        dst = ROOT / "docs" / "img" / out
        if small:
            big = HERE / "_anima_holo_big.png"
            render(p, big, 720, h)
            subprocess.run([FFMPEG, "-y", "-loglevel", "error", "-i", str(big), "-vf", "scale=375:812:flags=lanczos",
                            str(dst)], check=True)
            big.unlink()
        else:
            render(p, dst, 720, h)
        p.unlink()
        print("ok", out)


if __name__ == "__main__":
    for name, (w, h, inner) in SPRITES.items():
        sp = HERE / f"{name}.svg"
        sp.write_text(svg(w, h, inner), encoding="utf-8")
        png = SPR / f"{name}.png"
        render(sp, png, w * SCALE, h * SCALE)
        optimize(png)
        print("ok", name)
    if "preview" in sys.argv[1:]:
        preview()
