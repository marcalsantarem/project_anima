"""Gera os SVG dos ícones e da arte da UI (T-128) e os renderiza em PNG 2x no Chrome headless.
Uso: python gen_ui.py   (de qualquer pasta). Desenho em 1x; o PNG sai em 2x.
Formas e cores do mockup aprovado (assets/backgrounds/mockup_cartoon_a_upgrades.svg) e dos tokens do docs/ui.md.
Também gera _src/contact_sheet.png (folha de contato para conferência; não vai para o jogo)."""
import math, pathlib, subprocess

HERE = pathlib.Path(__file__).resolve().parent
UI = HERE.parent
CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
SCALE = 2
INK = "#3A2A55"      # ink / line
PURPLE = "#7B5CE0"   # corpo do botão de upgrade e da skill (mockup)
GRAY = "#8C86A0"     # apagado / bloqueado (mockup)
CYAN = "#2FE6D2"     # accent
MAXGOLD = "#F5B83D"  # lendário / MAX

# ---------- Glifos (centrados em 0,0; caixa ~40x40, como no mockup) ----------
G_SWORD = ('<path d="M-3.5 9 L-3.5 -13 L0 -19 L3.5 -13 L3.5 9 Z" fill="#FFFFFF" stroke="#3A2A55" stroke-width="2.5" stroke-linejoin="round"/>'
           '<rect x="-11" y="7" width="22" height="6" rx="3" fill="#FFC93D" stroke="#3A2A55" stroke-width="2.5"/>'
           '<rect x="-2.5" y="13" width="5" height="6" fill="#7A4A2A" stroke="#3A2A55" stroke-width="2"/>'
           '<circle cx="0" cy="20.5" r="3" fill="#FFC93D" stroke="#3A2A55" stroke-width="2"/>')
G_SPEED = ('<g transform="translate(2 0)">'
           '<path d="M-15 -11 L-3 0 L-15 11 M-1 -11 L11 0 L-1 11" fill="none" stroke="#3A2A55" stroke-width="10" stroke-linecap="round" stroke-linejoin="round"/>'
           '<path d="M-15 -11 L-3 0 L-15 11 M-1 -11 L11 0 L-1 11" fill="none" stroke="#FFFFFF" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/></g>')
G_SHIELD = ('<path d="M0 -17 L15 -8.5 L15 8.5 L0 17 L-15 8.5 L-15 -8.5 Z" fill="#FFFFFF" stroke="#3A2A55" stroke-width="3" stroke-linejoin="round"/>'
            '<path d="M0 -9 L8 -4.5 L8 4.5 L0 9 L-8 4.5 L-8 -4.5 Z" fill="#9CC4FF" stroke="#3A2A55" stroke-width="2.5" stroke-linejoin="round"/>')
G_HEART = ('<path d="M0 15 C-20 2 -16 -15 -6 -14 C-3 -14 -1 -12 0 -9 C1 -12 3 -14 6 -14 C16 -15 20 2 0 15 Z" fill="#FFFFFF" stroke="#3A2A55" stroke-width="3" stroke-linejoin="round"/>'
           '<path d="M0 -5 V7 M-6 1 H6" stroke="#FF5C8A" stroke-width="4" stroke-linecap="round"/>')
G_HOURGLASS = ('<path d="M-10 -15 H10 M-10 15 H10" stroke="#3A2A55" stroke-width="5" stroke-linecap="round"/>'
               '<path d="M-8 -14 H8 Q8 -5 1.5 0 Q8 5 8 14 H-8 Q-8 5 -1.5 0 Q-8 -5 -8 -14 Z" fill="#FFFFFF" stroke="#3A2A55" stroke-width="2.5" stroke-linejoin="round"/>'
               '<path d="M-4 -8 H4 L0 -2 Z M-6 12 Q0 5 6 12 Z" fill="#FFC93D"/>')
UPGRADES = {  # id: (cor do círculo, glifo); ordem da fileira (decisão 35)
    "atk_power": ("#FF6B3D", G_SWORD),
    "atk_speed": ("#FFB020", G_SPEED),
    "defense": ("#4A8CF5", G_SHIELD),
    "max_hp": ("#FF5C8A", G_HEART),
    "cooldown": ("#22B8A8", G_HOURGLASS),
}


def star16(r_out=30.0, r_in=14.0, n=8):
    pts = []
    for i in range(2 * n):
        r = r_out if i % 2 == 0 else r_in
        a = math.pi * i / n - math.pi / 2
        pts.append(f"{r * math.cos(a):.1f},{r * math.sin(a):.1f}")
    return " ".join(pts)


# Skill de área atual (skill_pulse). Para trocar (T-125/T-139): edite só G_SKILL_PULSE e rode o script.
G_SKILL_PULSE = (f'<circle r="27" fill="{CYAN}" opacity="0.3"/>'
                 f'<polygon points="{star16()}" fill="#FFFFFF" stroke="{INK}" stroke-width="3" stroke-linejoin="round"/>'
                 f'<circle r="11" fill="{CYAN}" stroke="{INK}" stroke-width="2.5"/><circle cx="-3.5" cy="-3.5" r="3" fill="#E8FFFC"/>')
# Skill do slot 1: meteoro de fogo (BRF-047, decisão 37). Desenhado com a cauda para cima e girado 40° (cauda para cima-direita).
_M_ROCK = "M-11 8 L-7 0 L1 -2 L9 2 L12 10 L8 18 L-1 21 L-9 17 Z"
G_SKILL_METEOR = ('<circle r="27" fill="#FF8A3D" opacity="0.3"/>'
                  '<g transform="rotate(40) translate(0 4.5)">'
                  f'<path d="M-14 10 Q-16 -8 -7 -20 Q-5 -12 -3 -14 Q-2 -24 0 -32 Q4 -22 4 -14 Q7 -18 9 -21 Q17 -6 14 10 Z" '
                  f'fill="#FF4A2A" stroke="{INK}" stroke-width="3" stroke-linejoin="round"/>'
                  '<path d="M-10 10 Q-11 -4 -4 -12 Q-2 -6 0 -8 Q0 -18 2 -24 Q5 -14 5 -7 Q8 -10 9 -12 Q13 0 10 10 Z" fill="#FFA02A"/>'
                  '<path d="M-6 10 Q-7 2 -2 -4 Q0 0 1 -2 Q1 -10 3 -14 Q6 -4 5 2 Q7 4 7 10 Z" fill="#FFE066"/>'
                  f'<defs><clipPath id="mr"><path d="{_M_ROCK}"/></clipPath></defs>'
                  f'<path d="{_M_ROCK}" fill="#8A4A36"/>'
                  '<g clip-path="url(#mr)"><ellipse cx="5" cy="18" rx="12" ry="8" fill="#4A2018" opacity="0.55"/></g>'
                  '<path d="M-5 6 L0 11 L-2 16 M0 11 L6 10" fill="none" stroke="#FFB020" stroke-width="2.2" '
                  'stroke-linecap="round" stroke-linejoin="round"/>'
                  f'<path d="{_M_ROCK}" fill="none" stroke="{INK}" stroke-width="3" stroke-linejoin="round"/></g>')
G_LOCK = ('<path d="M-10 -2 v-8 a10 10 0 0 1 20 0 v8" fill="none" stroke="#3A2A55" stroke-width="9"/>'
          '<path d="M-10 -2 v-8 a10 10 0 0 1 20 0 v8" fill="none" stroke="#E8EEF8" stroke-width="4"/>'
          '<rect x="-16" y="-4" width="32" height="24" rx="5" fill="#E8EEF8" stroke="#3A2A55" stroke-width="3"/>'
          '<circle cx="0" cy="6" r="3.5" fill="#3A2A55"/><rect x="-1.5" y="7" width="3" height="7" rx="1.5" fill="#3A2A55"/>')
G_PARTICLE = ('<path d="M0 -11 Q2 -2 11 0 Q2 2 0 11 Q-2 2 -11 0 Q-2 -2 0 -11 Z" fill="#FFC93D" stroke="#725A1B" stroke-width="2.2" stroke-linejoin="round"/>'
              '<circle cx="-2" cy="-2.5" r="1.8" fill="#FFF"/>')

# Partículas = estrela verde "chip" (decisão 40, BRF-061). G_PARTICLE (dourada) fica obsoleta: reservada à Moeda do M2.
P_GREEN = {"light": "#D2FFB0", "mid": "#7CF05A", "deep": "#3CC23A", "dark": "#1F8A3B", "out": "#124F24"}
P_OFF = {"light": "#E4E2EA", "mid": "#B8B4C6", "deep": "#9C97AE", "dark": "#7A7490", "out": "#4A4560"}


def g_particles(p):
    tri = lambda a, b, c: f'M{a} L{b} L{c} Z'
    faces = [(p["light"], ["0,-28", "-8,-8", "0,0"]), (p["mid"], ["0,-28", "8,-8", "0,0"]),
             (p["light"], ["-28,0", "-8,-8", "0,0"]), (p["mid"], ["-28,0", "-8,8", "0,0"]),
             (p["deep"], ["28,0", "8,-8", "0,0"]), (p["dark"], ["28,0", "8,8", "0,0"]),
             (p["deep"], ["0,28", "-8,8", "0,0"]), (p["dark"], ["0,28", "8,8", "0,0"])]
    star = "M0 -28 L8 -8 L28 0 L8 8 L0 28 L-8 8 L-28 0 L-8 -8 Z"
    return (f'<path d="{star}" fill="{p["out"]}" transform="translate(0 2.5)"/>'
            + "".join(f'<path d="{tri(*v)}" fill="{c}"/>' for c, v in faces)
            + f'<path d="{star}" fill="none" stroke="{p["out"]}" stroke-width="3.5" stroke-linejoin="round"/>'
            + f'<path d="M0 -7 L7 0 L0 7 L-7 0 Z" fill="{p["light"]}" stroke="{p["out"]}" stroke-width="2" stroke-linejoin="round"/>'
            + '<circle cx="-3" cy="-17" r="2.6" fill="#FFFFFF" opacity="0.9"/>')


def at(x, y, s, inner):
    return f'<g transform="translate({x} {y}) scale({s})">{inner}</g>'


def upgrade_icon(color, glyph):
    return (f'<circle cx="32" cy="33.5" r="28" fill="{INK}"/>'
            f'<circle cx="32" cy="31" r="28" fill="{color}" stroke="{INK}" stroke-width="3.5"/>'
            '<ellipse cx="22" cy="16" rx="10" ry="4.5" fill="#FFFFFF" opacity="0.3" transform="rotate(-25 22 16)"/>'
            + at(32, 31, 1.15, glyph))


PAUSE = (f'<rect x="3" y="8" width="58" height="52" rx="16" fill="{INK}"/>'
         f'<rect x="3" y="3" width="58" height="52" rx="16" fill="#FFFFFF" stroke="{INK}" stroke-width="4"/>'
         f'<rect x="21" y="16" width="8" height="26" rx="3" fill="{PURPLE}" stroke="{INK}" stroke-width="2.5"/>'
         f'<rect x="35" y="16" width="8" height="26" rx="3" fill="{PURPLE}" stroke="{INK}" stroke-width="2.5"/>')


# ---------- Botão de upgrade 128x80 (canvas 132x90: corpo em (2,2), sombra +6) ----------
def upgrade_btn(fill, stroke, inner_ring):
    s = (f'<rect x="2" y="8" width="128" height="80" rx="18" fill="{INK}"/>'
         f'<rect x="2" y="2" width="128" height="80" rx="18" fill="{fill}" stroke="{stroke}" stroke-width="4"/>')
    if inner_ring:
        s += f'<rect x="7" y="7" width="118" height="70" rx="15" fill="none" stroke="{inner_ring}" stroke-width="3"/>'
    return s + '<rect x="10" y="8" width="112" height="20" rx="10" fill="#FFFFFF" opacity="0.18"/>'


def pill_cost(fill, stroke=None):  # pílula do custo/MAX: 110x23 (canvas 112x25)
    st = f' stroke="{stroke}" stroke-width="2"' if stroke else ""
    return f'<rect x="1" y="1" width="110" height="23" rx="11.5" fill="{fill}"{st}/>'


# ---------- Moldura circular de skill (canvas 160x168: centro (80,80), r=72, sombra +6) ----------
def skill_frame(state):
    s = f'<circle cx="80" cy="86" r="72" fill="{INK}"/>'
    if state == "ready":
        s += f'<circle cx="80" cy="80" r="80" fill="{CYAN}" opacity="0.35"/>'
    body = GRAY if state == "locked" else PURPLE
    s += f'<circle cx="80" cy="80" r="72" fill="{body}" stroke="{INK}" stroke-width="4"/>'
    if state == "ready":
        s += f'<circle cx="80" cy="80" r="64" fill="none" stroke="{CYAN}" stroke-width="6"/>'
    elif state == "cooldown":
        s += '<circle cx="80" cy="80" r="64" fill="none" stroke="#5A4A9A" stroke-width="6"/>'
    op = 0.15 if state == "locked" else 0.2
    return s + f'<ellipse cx="80" cy="48" rx="43" ry="20" fill="#FFF" opacity="{op}"/>'


COOLDOWN_MASK = '<circle cx="70" cy="70" r="70" fill="#1A0F2E" opacity="0.55"/>'  # véu radial (TextureProgressBar)

# ---------- Barra (9-patch horizontal) ----------
BAR_TRACK = (f'<rect x="2" y="6" width="60" height="28" rx="14" fill="{INK}"/>'
             f'<rect x="2" y="2" width="60" height="28" rx="14" fill="#5B4A7A" stroke="{INK}" stroke-width="4"/>')
BAR_FILL = '<rect x="0" y="0" width="48" height="24" rx="12" fill="#FFFFFF"/>'  # tingir com self_modulate
BAR_SHINE = '<rect x="0" y="0" width="48" height="8" rx="4" fill="#FFFFFF" opacity="0.35"/>'

# ---------- Painel com moldura (9-patch, canvas 96x96) ----------
PANEL = (f'<rect x="2" y="8" width="92" height="86" rx="24" fill="{INK}"/>'
         f'<rect x="2" y="2" width="92" height="86" rx="24" fill="{PURPLE}" stroke="{INK}" stroke-width="4"/>'
         f'<rect x="12" y="12" width="72" height="66" rx="16" fill="#8E7CD8" stroke="{INK}" stroke-width="3"/>'
         '<rect x="10" y="5" width="76" height="4" rx="2" fill="#FFFFFF" opacity="0.3"/>')


# ---------- Botão grande (9-patch, canvas 96x72; corpo 92x56) ----------
def big_btn(pressed):
    dy = 4 if pressed else 0
    fill = "#22C4B2" if pressed else CYAN
    op = 0.18 if pressed else 0.35
    return (f'<rect x="2" y="10" width="92" height="56" rx="24" fill="{INK}"/>'
            f'<rect x="2" y="{2 + dy}" width="92" height="56" rx="24" fill="{fill}" stroke="{INK}" stroke-width="4"/>'
            f'<rect x="12" y="{7 + dy}" width="72" height="16" rx="8" fill="#FFFFFF" opacity="{op}"/>')


# nome: (largura 1x, altura 1x, conteúdo)
ASSETS = {f"ui_icon_upgrade_{k}": (64, 64, upgrade_icon(c, g)) for k, (c, g) in UPGRADES.items()}
ASSETS.update({
    "ui_icon_skill_pulse": (64, 64, at(32, 32, 1.0, G_SKILL_PULSE)),
    "ui_icon_skill_meteor": (64, 64, at(32, 32, 1.0, G_SKILL_METEOR)),
    "ui_icon_lock": (64, 64, at(32, 35, 1.25, G_LOCK)),
    "ui_icon_particle": (32, 32, at(16, 16, 1.3, G_PARTICLE)),  # obsoleto (dourado = Moeda do M2)
    "ui_icon_particles": (64, 64, at(32, 31, 1.0, g_particles(P_GREEN))),
    "ui_icon_particles_off": (64, 64, at(32, 31, 1.0, g_particles(P_OFF))),
    "ui_icon_pause": (64, 64, PAUSE),
    "ui_upgrade_btn_normal": (132, 90, upgrade_btn(PURPLE, INK, CYAN)),
    "ui_upgrade_btn_disabled": (132, 90, upgrade_btn(GRAY, INK, None)),
    "ui_upgrade_btn_max": (132, 90, upgrade_btn(PURPLE, MAXGOLD, INK)),
    "ui_upgrade_cost_pill": (112, 25, pill_cost(INK)),
    "ui_upgrade_cost_pill_max": (112, 25, pill_cost(MAXGOLD, INK)),
    "ui_skill_frame_ready": (160, 168, skill_frame("ready")),
    "ui_skill_frame_cooldown": (160, 168, skill_frame("cooldown")),
    "ui_skill_frame_locked": (160, 168, skill_frame("locked")),
    "ui_skill_cooldown_mask": (140, 140, COOLDOWN_MASK),
    "ui_bar_track": (64, 36, BAR_TRACK),
    "ui_bar_fill": (48, 24, BAR_FILL),
    "ui_bar_shine": (48, 8, BAR_SHINE),
    "ui_panel": (96, 96, PANEL),
    "ui_button_big_normal": (96, 72, big_btn(False)),
    "ui_button_big_pressed": (96, 72, big_btn(True)),
})


def svg(w, h, inner):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w * SCALE}" height="{h * SCALE}" '
            f'viewBox="0 0 {w} {h}">{inner}</svg>')


def render(src, png, w, h):
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars",
                    "--default-background-color=00000000", f"--window-size={w},{h}",
                    f"--screenshot={png}", src.as_uri()], check=True, capture_output=True)


def contact_sheet():
    cells = []
    for n, (w, h, _) in ASSETS.items():
        small = f'<img src="../{n}.png" style="width:44px"> ' if w <= 64 else ""
        cells.append(f'<div class="c"><img src="../{n}.png" style="width:{w}px"> {small}<br><span>{n}</span></div>')
    html = ('<html><body style="margin:8px;background:#7C6BC9;font:11px sans-serif;color:#fff">'
            '<style>.c{display:inline-block;vertical-align:top;margin:5px;padding:6px;'
            'background:repeating-conic-gradient(#6a5ab8 0 25%,#7C6BC9 0 50%) 0 0/16px 16px}</style>'
            + "".join(cells) + "</body></html>")
    p = HERE / "contact_sheet.html"
    p.write_text(html, encoding="utf-8")
    render(p, HERE / "contact_sheet.png", 1000, 700)


if __name__ == "__main__":
    import sys
    only = set(sys.argv[1:])  # opcional: gera só os nomes passados (a folha de contato sempre é refeita)
    for name, (w, h, inner) in ASSETS.items():
        if only and name not in only:
            continue
        sp = HERE / f"{name}.svg"
        sp.write_text(svg(w, h, inner), encoding="utf-8")
        render(sp, UI / f"{name}.png", w * SCALE, h * SCALE)
        print("ok", name)
    contact_sheet()
