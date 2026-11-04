"""Gera os SVG dos sprites da partida (T-127) e os renderiza em PNG 2x no Chrome headless.
Uso: python gen_sprites.py   (de qualquer pasta). Desenho em escala 1x (720x1280); o PNG sai em 2x.
As formas vêm dos mockups A/B (assets/backgrounds/mockup_cartoon_*.svg), em coordenadas do mockup."""
import subprocess, pathlib

HERE = pathlib.Path(__file__).resolve().parent
SPR = HERE.parent
BG = SPR.parent / "backgrounds"
CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
SCALE = 2

EYE_LINE = "#3A2A55"
PUPIL = "#1E1838"


def body(cid, cx, cy, rx, ry, fill, shade, outline, sw=3.5):
    hx, hy = cx - 0.42 * rx, cy - 0.45 * ry
    return (f'<defs><clipPath id="{cid}"><ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}"/></clipPath></defs>'
            f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="{fill}"/>'
            f'<g clip-path="url(#{cid})"><ellipse cx="{cx + 0.35 * rx:.1f}" cy="{cy + 0.55 * ry:.1f}" '
            f'rx="{1.05 * rx:.1f}" ry="{0.75 * ry:.1f}" fill="{shade}" opacity="0.45"/></g>'
            f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="none" stroke="{outline}" stroke-width="{sw}"/>'
            f'<ellipse cx="{hx:.1f}" cy="{hy:.1f}" rx="{0.22 * rx:.1f}" ry="{0.14 * ry:.1f}" fill="#FFFFFF" '
            f'opacity="0.55" transform="rotate(-25 {hx:.1f} {hy:.1f})"/>')


def eye(cx, cy, rx, ry, pr, sw=1.75):
    # Pupila centrada (olhando para a câmera). Seguir o Anima exige uma camada de pupila própria (futuro).
    return (f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="#FFFFFF" stroke="{EYE_LINE}" stroke-width="{sw}"/>'
            f'<circle cx="{cx}" cy="{cy + 0.2 * ry:.1f}" r="{pr}" fill="{PUPIL}"/>'
            f'<circle cx="{cx - 0.33 * pr:.1f}" cy="{cy - 0.2 * ry:.1f}" r="{0.33 * pr:.1f}" fill="#FFFFFF"/>')


def brow(d, w=3):
    return f'<path d="{d}" stroke="{EYE_LINE}" stroke-width="{w}" stroke-linecap="round"/>'


# ---------- Anima ----------
ANIMA_BASE = (
    '<path d="M304 660 L304 686 Q360 712 416 686 L416 660 Z" fill="#9FA3AB" stroke="#66686E" stroke-width="3.5" stroke-linejoin="round"/>'
    '<path d="M304 674 Q360 698 416 674" fill="none" stroke="#2FE6D2" stroke-width="4" opacity="0.8"/>'
    '<ellipse cx="360" cy="660" rx="56" ry="20" fill="#E4E9F5" stroke="#66686E" stroke-width="3.5"/>'
    '<ellipse cx="360" cy="660" rx="34" ry="11" fill="#2FE6D2" opacity="0.35"/>'
    '<ellipse cx="360" cy="660" rx="20" ry="6" fill="#E8FFFC" opacity="0.8"/>'
    '<ellipse cx="334" cy="652" rx="9" ry="2.6" fill="#FFFFFF" opacity="0.6"/>')
ANIMA_CRYSTAL = (
    '<circle cx="360" cy="590" r="52" fill="#2FE6D2" opacity="0.18"/>'
    '<path d="M360 540 L390 586 L360 632 L330 586 Z" fill="#2FE6D2" stroke="#15675E" stroke-width="3.5" stroke-linejoin="round"/>'
    '<path d="M360 540 L390 586 L360 632 Z" fill="#1E9588" opacity="0.45"/>'
    '<path d="M360 540 L330 586 L352 586 Z" fill="#E8FFFC" opacity="0.85"/>'
    '<path d="M330 586 L390 586" stroke="#15675E" stroke-width="2.1" opacity="0.6"/>'
    '<path d="M360 540 L390 586 L360 632 L330 586 Z" fill="none" stroke="#15675E" stroke-width="3.5" stroke-linejoin="round"/>')
ANIMA_NODE = ('<circle cx="16" cy="16" r="8" fill="#E8FFFC" stroke="#177369" stroke-width="2.1"/>'
              '<circle cx="13.5" cy="13.5" r="2.2" fill="#FFFFFF"/>')

# ---------- Inimigos ----------
RUNNER = (
    '<path d="M156 384 L146 358 L168 376 Z" fill="#FF8A3D" stroke="#723E1B" stroke-width="3.5" stroke-linejoin="round"/>'
    '<path d="M184 384 L194 358 L172 376 Z" fill="#FF8A3D" stroke="#723E1B" stroke-width="3.5" stroke-linejoin="round"/>'
    + body("b", 170, 400, 22, 20, "#FF8A3D", "#A55927", "#723E1B")
    + eye(162, 398, 6, 6.9, 3.3) + eye(178, 398, 6, 6.9, 3.3)
    + brow("M155.4 389.0 L167.4 392.9") + brow("M184.6 389.0 L172.6 392.9"))
TANK = (
    '<ellipse cx="308" cy="336" rx="12" ry="8" fill="#A22436" stroke="#681723" stroke-width="3.5"/>'
    '<ellipse cx="352" cy="336" rx="12" ry="8" fill="#A22436" stroke="#681723" stroke-width="3.5"/>'
    '<path d="M310 280 Q296 256 300 248 Q306 266 320 274 Z" fill="#F4E3C1" stroke="#6D6656" stroke-width="3.5" stroke-linejoin="round"/>'
    '<path d="M350 280 Q364 256 360 248 Q354 266 340 274 Z" fill="#F4E3C1" stroke="#6D6656" stroke-width="3.5" stroke-linejoin="round"/>'
    + body("b", 330, 304, 38, 32, "#E8344E", "#962132", "#681723")
    + '<path d="M306 310 Q330 322 354 310 L350 328 Q330 336 310 328 Z" fill="#7F1C2A" stroke="#681723" stroke-width="2.8" stroke-linejoin="round"/>'
    '<circle cx="318" cy="323" r="2.5" fill="#F18594"/><circle cx="330" cy="323" r="2.5" fill="#F18594"/>'
    '<circle cx="342" cy="323" r="2.5" fill="#F18594"/>'
    + eye(319, 290, 6, 6.9, 3.3) + eye(341, 290, 6, 6.9, 3.3)
    + brow("M312.4 281.0 L324.4 284.9") + brow("M347.6 281.0 L335.6 284.9"))
SHOOTER_BODY = "M520 240 Q526 240 548 274 Q550 296 520 298 Q490 296 492 274 Q514 240 520 240 Z"
SHOOTER = (
    '<path d="M494 276 L480 264 L488 288 Z" fill="#CC3090" stroke="#721B50" stroke-width="3.5" stroke-linejoin="round"/>'
    '<path d="M546 276 L560 264 L552 288 Z" fill="#CC3090" stroke="#721B50" stroke-width="3.5" stroke-linejoin="round"/>'
    f'<defs><clipPath id="b"><path d="{SHOOTER_BODY}"/></clipPath></defs>'
    f'<path d="{SHOOTER_BODY}" fill="#FF3DB4"/>'
    '<g clip-path="url(#b)"><rect x="524" y="236" width="40" height="70" fill="#A52775" opacity="0.45"/></g>'
    f'<path d="{SHOOTER_BODY}" fill="none" stroke="#721B50" stroke-width="3.5" stroke-linejoin="round"/>'
    '<ellipse cx="509" cy="262" rx="3" ry="5.5" fill="#FFFFFF" opacity="0.55" transform="rotate(35 509 262)"/>'
    '<circle cx="520" cy="226" r="16" fill="#FF2DAA" opacity="0.3"/>'
    '<circle cx="520" cy="226" r="10" fill="#FF2DAA" stroke="#72144C" stroke-width="2.45"/>'
    '<circle cx="517" cy="223" r="4" fill="#FFD6F0"/>'
    + eye(520, 274, 8, 9.2, 4.4) + brow("M511.2 262.0 L527.2 267.2"))
SWARM = (
    '<ellipse cx="518" cy="964" rx="9" ry="5" fill="#D2B5FF" stroke="#452972" stroke-width="2.1" transform="rotate(30 518 964)"/>'
    '<ellipse cx="542" cy="964" rx="9" ry="5" fill="#D2B5FF" stroke="#452972" stroke-width="2.1" transform="rotate(-30 542 964)"/>'
    + body("b", 530, 979, 12, 11, "#9B5CFF", "#643BA5", "#452972")
    + eye(530, 978, 4.5, 5.2, 2.5))
# Chefe: silhueta do mockup B, redesenhada no estilo A (contorno colorido, sombra suave a 45%).
B_OUT = "#561C6E"
BOSS = (
    f'<ellipse cx="276" cy="344" rx="22" ry="30" fill="#A336D0" stroke="{B_OUT}" stroke-width="4" transform="rotate(20 276 344)"/>'
    f'<ellipse cx="444" cy="344" rx="22" ry="30" fill="#A336D0" stroke="{B_OUT}" stroke-width="4" transform="rotate(-20 444 344)"/>'
    + body("b", 360, 334, 76, 66, "#C040F5", "#7C299F", B_OUT, sw=4)
    + "".join(f'<path d="M{x} 274 L{x + 14} {t} L{x + 28} 274 Z" fill="#FFC93D" stroke="#725A1B" '
              f'stroke-width="3.5" stroke-linejoin="round"/>'
              for x, t in [(302, 245), (324, 240), (346, 234), (368, 240), (390, 245)])
    + '<path d="M300 270 Q360 284 420 270 L420 279 Q360 293 300 279 Z" fill="#FFC93D" stroke="#725A1B" stroke-width="3.5" stroke-linejoin="round"/>'
    '<path d="M360 282 l10 12 l-10 12 l-10 -12 Z" fill="#FF2DAA" stroke="#72144C" stroke-width="2.5" stroke-linejoin="round"/>'
    '<path d="M357 287 l-4 7 l4 0 Z" fill="#FFD6F0"/>'
    + eye(360, 330, 26, 22, 13, sw=3.5)
    + brow("M326 304 L354 312", 6) + brow("M394 304 L366 312", 6)
    + f'<path d="M336 366 Q360 378 384 366 L376 372 L368 366 L360 373 L352 366 L344 372 Z" fill="{B_OUT}" '
      f'stroke="{B_OUT}" stroke-width="2" stroke-linejoin="round"/>')
BOSS_RING = (
    '<ellipse cx="128" cy="64" rx="112" ry="34" fill="none" stroke="#725A1B" stroke-width="9" stroke-dasharray="18 12" opacity="0.9"/>'
    '<ellipse cx="128" cy="64" rx="112" ry="34" fill="none" stroke="#FFC93D" stroke-width="5" stroke-dasharray="18 12"/>')

# ---------- Projéteis, coleta e sombra ----------
PROJ_PLAYER = ('<rect x="3" y="2" width="26" height="12" rx="6" fill="#2FE6D2" stroke="#177369" stroke-width="2"/>'
               '<rect x="11" y="5.5" width="15" height="5" rx="2.5" fill="#E8FFFC"/>')
PROJ_ENEMY = ('<circle cx="16" cy="16" r="15" fill="#FF2DAA" opacity="0.25"/>'
              '<path d="M3 16 L16 7 L29 16 L16 25 Z" fill="#FF2DAA" stroke="#72144C" stroke-width="2.5" stroke-linejoin="round"/>'
              '<path d="M11 16 L16 12.5 L21 16 L16 19.5 Z" fill="#FFD6F0"/>')
PICKUP = ('<path d="M260 589 Q262 598 271 600 Q262 602 260 611 Q258 602 249 600 Q258 598 260 589 Z" fill="#FFC93D" '
          'stroke="#725A1B" stroke-width="2.5" stroke-linejoin="round"/><circle cx="258" cy="598" r="2" fill="#FFF"/>')
SHADOW = '<ellipse cx="32" cy="16" rx="30" ry="10" fill="#6B4E8C" opacity="0.22"/>'


def place(content, ax, ay, gx, gy, s=1.0):
    """Leva o ponto de chão (gx, gy) do mockup para a âncora (ax, ay) do canvas 1x."""
    return f'<g transform="translate({ax} {ay}) scale({s}) translate({-gx} {-gy})">{content}</g>'


# nome: (largura 1x, altura 1x, conteúdo)
SPRITES = {
    "anima_default_base": (128, 128, place(ANIMA_BASE, 64, 100, 360, 696)),
    "anima_default_crystal": (128, 128, place(ANIMA_CRYSTAL, 64, 64, 360, 586)),
    "anima_default_node": (32, 32, ANIMA_NODE),
    "enemy_runner": (64, 64, place(RUNNER, 32, 60, 170, 420, 0.9)),
    "enemy_tank": (128, 128, place(TANK, 64, 112, 330, 336)),
    "enemy_shooter": (128, 128, place(SHOOTER, 64, 112, 520, 300)),
    "enemy_swarm": (64, 64, place(SWARM, 32, 52, 530, 990)),
    "boss_warden": (256, 256, place(BOSS, 128, 236, 360, 400)),
    "boss_warden_ring": (256, 128, BOSS_RING),
    "projectile_player": (32, 16, PROJ_PLAYER),
    "projectile_enemy": (32, 32, PROJ_ENEMY),
    "pickup_particle": (32, 32, place(PICKUP, 16, 28, 260, 614)),
    "shadow_ground": (64, 32, SHADOW),
}


def svg(w, h, inner):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w * SCALE}" height="{h * SCALE}" '
            f'viewBox="0 0 {w} {h}">{inner}</svg>')


# --- Fundo em tela cheia (BRF-040): peças separadas para o jogo montar ---
SQ = 60  # lado do quadrado (1x); 720 / 60 = 12 colunas exatas
TILE_N = 4  # repetição de 4×4 quadrados = 240×240 (1x)


def floor_tile():
    """Chão quadriculado creme sem emendas: número par de quadrados, sem nada cruzando a borda."""
    t = SQ * TILE_N
    out = [f'<rect width="{t}" height="{t}" fill="#F6E9CF"/>']
    out += [f'<rect x="{c * SQ}" y="{r * SQ}" width="{SQ}" height="{SQ}" fill="#EEDDBD"/>'
            for r in range(TILE_N) for c in range(TILE_N) if (r + c) % 2]
    for x, y in ((38, 44), (172, 104), (96, 200)):  # pedrinhas longe da borda
        out.append(f'<ellipse cx="{x}" cy="{y}" rx="10" ry="5" fill="#E0CCA6"/>')
    return t, t, "".join(out)


RING_W, RING_H = 480, 360  # 1x; centro (240, 180) = posição do Anima


def floor_ring():
    """Selo rúnico do mockup A (escala 0,87), centrado no canvas."""
    k, cx, cy, c = 0.87, RING_W / 2, RING_H / 2, "#B9A5E8"
    out = [f'<ellipse cx="{cx}" cy="{cy}" rx="{250 * k}" ry="{188 * k}" fill="none" stroke="{c}" '
           f'stroke-width="{10 * k}" opacity="0.7"/>',
           f'<ellipse cx="{cx}" cy="{cy}" rx="{226 * k}" ry="{170 * k}" fill="none" stroke="{c}" '
           f'stroke-width="{3 * k}" opacity="0.7"/>']
    for dx, dy in ((220, 69), (91, 165), (-91, 165), (-220, 69), (-220, -69), (-91, -165), (91, -165), (220, -69)):
        out.append(f'<path d="M{cx + dx * k} {cy + dy * k - 10 * k} l{8 * k} {10 * k} l{-8 * k} {10 * k} '
                   f'l{-8 * k} {-10 * k} Z" fill="{c}"/>')
    return RING_W, RING_H, "".join(out)


PILLAR = ('<path d="M58 260 L58 296 Q80 308 102 296 L102 260 Z" fill="#B7A8EA" stroke="#4E3F8F" stroke-width="3.5"/>'
          '<ellipse cx="80" cy="260" rx="22" ry="8" fill="#DCD3FA" stroke="#4E3F8F" stroke-width="3.5"/>'
          '<path d="M80 214 L92 244 L80 258 L68 244 Z" fill="#FFB84D" stroke="#8A4F12" stroke-width="3" '
          'stroke-linejoin="round"/><path d="M80 214 L68 244 L77 244 Z" fill="#FFF3D1"/>')


def floor_top_shade():
    """Escurecimento opcional atrás do HUD: roxo-escuro a 30% no topo, some até a base."""
    return 720, 220, ('<defs><linearGradient id="g" x1="0" y1="0" x2="0" y2="1">'
                      '<stop offset="0" stop-color="#3A2A55" stop-opacity="0.30"/>'
                      '<stop offset="0.6" stop-color="#3A2A55" stop-opacity="0.10"/>'
                      '<stop offset="1" stop-color="#3A2A55" stop-opacity="0"/></linearGradient></defs>'
                      '<rect width="720" height="220" fill="url(#g)"/>')


FLOOR_PARTS = {
    "floor_tile": floor_tile(),
    "floor_ring": floor_ring(),
    "floor_pillar": (64, 104, place(PILLAR, 32, 96, 80, 302)),  # âncora no chão, sem sombra
    "floor_top_shade": floor_top_shade(),
}


def render(svg_path, png_path, w, h):
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars",
                    "--default-background-color=00000000", f"--window-size={w},{h}",
                    f"--screenshot={png_path}", svg_path.as_uri()], check=True, capture_output=True)


if __name__ == "__main__":
    jobs = [(n, w, h, svg(w, h, c), SPR) for n, (w, h, c) in SPRITES.items()]
    jobs += [(n, w, h, svg(w, h, c), BG) for n, (w, h, c) in FLOOR_PARTS.items()]
    for name, w, h, text, outdir in jobs:
        sp = HERE / f"{name}.svg"
        sp.write_text(text, encoding="utf-8")
        render(sp, outdir / f"{name}.png", w * SCALE, h * SCALE)
        print("ok", name)
