"""Ícones dos Núcleos, molduras do nó, selo de nível e ligações da árvore (T-206, BRF-152; docs/meta.md "Núcleos", docs/arte.md §11.10).
Uso: python gen_ui_talents.py   (de qualquer pasta; Chrome e ffmpeg no PATH, helpers do gen_ui_holo.py).
Escala: 1 px do PNG ≈ 1 px de tela no viewport 720 (como o hangar, T-199); prévia em 375 px = PNG a 50%.
Saídas em assets/ui/: ui_icon_talent_<nome>[_off] (64), ui_talent_node[_selected|_owned|_max|_locked] (112),
ui_talent_level_chip (56x28), ui_talent_link_{v,h}_{off,on}; folha _src/talent_sheet.png e prévia docs/img/nucleos-pecas.png.
Ramo = cor + forma da placa: Ataque losango laranja, Defesa escudo azul, Economia quadrado arredondado orquídea.
Regras: contorno #021423, brilho pintado, sem texto na arte."""
import math
from gen_ui_holo import HERE, UI, ROOT, render, optimize, LINE, LINE_DIM, TEXT, TEXT2, GOLD, DIS_FILL, DIS_LINE
import gen_ui_icons as gi
import gen_ui_hangar as gh

INK = "#021423"
glow, grad = gi.glow, gi.grad


# ---------- placas dos ramos (viewBox 64) ----------
BRANCH = {  # ramo: (cor da linha, degradê escuro do miolo)
    "atk": ("#FF9F43", ("#5A2A0A", "#2A1004")),
    "def": ("#4F8DFF", ("#0E2E6E", "#06143A")),
    "eco": ("#E07BFF", ("#4A1A5E", "#1E0A2A")),
}
SHAPE = {
    "atk": '<polygon points="32,4 60,32 32,60 4,32" fill="F" T/>',
    "def": '<path d="M9 10 Q9 6 13 6 H51 Q55 6 55 10 V30 C55 44 45 53 32 59 C19 53 9 44 9 30 Z" fill="F" T/>',
    "eco": '<rect x="6" y="6" width="52" height="52" rx="16" fill="F" T/>',
}


def plate(b, uid):
    line, (c0, c1) = BRANCH[b]
    s = SHAPE[b]
    shp = lambda fill, extra="": s.replace('fill="F"', f'fill="{fill}"').replace(" T/", f" {extra}/")
    inner = f'transform="translate(32 32) scale(.82) translate(-32 -32)" stroke="{line}" stroke-width="2.6" stroke-linejoin="round"'
    return (glow(shp("FILL"), line, 2.2, .5, f"pg{uid}") + grad(f"pf{uid}", [(0, c0), (1, c1)])
            + shp(INK, 'transform="translate(0 2)"')
            + shp(f"url(#pf{uid})", f'stroke="{INK}" stroke-width="3.5" stroke-linejoin="round"')
            + shp("none", inner))


def stroke2(d, light, w=3, ink=6, cap="round"):
    """Traço com contorno: tinta grossa por baixo + cor por cima."""
    return (f'<path d="{d}" fill="none" stroke="{INK}" stroke-width="{ink}" stroke-linecap="{cap}" stroke-linejoin="round"/>'
            f'<path d="{d}" fill="none" stroke="{light}" stroke-width="{w}" stroke-linecap="{cap}" stroke-linejoin="round"/>')


def solid(d, fill, sw=2.6):
    return f'<path d="{d}" fill="{fill}" stroke="{INK}" stroke-width="{sw}" stroke-linejoin="round"/>'


def sparkle(cx, cy, r, fill="#5CF08A"):  # estrelinha de 4 pontas (a forma da Partícula), verde
    k = r * .18
    d = (f"M{cx} {cy - r} Q{cx + k} {cy - k} {cx + r} {cy} Q{cx + k} {cy + k} {cx} {cy + r} "
         f"Q{cx - k} {cy + k} {cx - r} {cy} Q{cx - k} {cy - k} {cx} {cy - r}Z")
    return solid(d, fill, 2)


def arc(cx, cy, r, a0, a1):
    p = lambda a: (cx + r * math.cos(math.radians(a)), cy + r * math.sin(math.radians(a)))
    (x0, y0), (x1, y1) = p(a0), p(a1)
    return f"M{x0:.1f} {y0:.1f} A{r} {r} 0 0 1 {x1:.1f} {y1:.1f}"


ORANGE_G = [(0, "#FFF0D8"), (.45, "#FFB25E"), (1, "#E0701A")]
BLUE_G = [(0, "#EEF4FF"), (.5, "#9CC0FF"), (1, "#4F7FE8")]
ORCH_G = [(0, "#FBEAFF"), (.5, "#EBA8FF"), (1, "#B65AE0")]


# ---------- 12 glifos (centro 32,32; raio ~18) ----------
def g_sharp_core():
    d = "M32 9 L42 29 L36 52 L28 52 L22 29 Z"
    return (grad("a1", ORANGE_G, 1, 1) + solid(d, "url(#a1)", 3)
            + '<path d="M32 9 L42 29 L32 29Z" fill="#FFFFFF" opacity=".75"/><path d="M28 52 L22 29 L32 29 L32 52Z" fill="#C85A12" opacity=".55"/>'
            + stroke2("M45 12 V20 M41 16 H49", "#FFFFFF", 2, 4.5))


def g_quick_pulse():
    return ('<circle cx="18" cy="32" r="5.5" fill="#FFE0B8" stroke="#021423" stroke-width="2.6"/>'
            + stroke2(arc(18, 32, 11, -50, 50), "#FFB25E", 3.4, 7) + stroke2(arc(18, 32, 19, -45, 45), "#FFB25E", 3.4, 7)
            + stroke2("M41 24 L49 32 L41 40", "#FFFFFF", 3.2, 7))


def g_arcane_burst():
    rs = [20, 8, 13, 8] * 4
    pts = " ".join(f"{32 + r * math.cos(math.radians(i * 22.5 - 90)):.1f},{32 + r * math.sin(math.radians(i * 22.5 - 90)):.1f}"
                   for i, r in enumerate(rs))
    return (grad("a3", [(0, "#FFFFFF"), (.4, "#FFC07A"), (1, "#FF6A2A")], 1, 1)
            + f'<polygon points="{pts}" fill="url(#a3)" stroke="{INK}" stroke-width="2.8" stroke-linejoin="round"/>'
            + f'<path d="M32 25 L38 32 L32 39 L26 32Z" fill="#FFFFFF" stroke="{INK}" stroke-width="2"/>')


def g_piercing_ray():
    ring = lambda x, y: (f'<circle cx="{x}" cy="{y}" r="7.5" fill="none" stroke="{INK}" stroke-width="6.5"/>'
                         f'<circle cx="{x}" cy="{y}" r="7.5" fill="none" stroke="#FFC07A" stroke-width="3"/>')
    return (ring(24, 39) + ring(39, 24) + stroke2("M13 50 L47 16", "#FFFFFF", 3, 7)
            + solid("M51 12 L49.5 24 L46 19.5 L40 18 Z", "#FFFFFF", 2.4))


def g_hardened_shell():
    dome = "M16 44 C16 21 48 21 48 44 Z"
    return (grad("d1", BLUE_G, 1, 1) + solid(dome, "url(#d1)", 3)
            + f'<path d="M23 44 C23 31 41 31 41 44 M32 27 V44" fill="none" stroke="{INK}" stroke-width="2.2"/>'
            + solid("M13 43 H51 V49 Q51 52 48 52 H16 Q13 52 13 49 Z", "#BFD6FF", 2.8)
            + "".join(f'<circle cx="{x}" cy="47.5" r="1.6" fill="{INK}"/>' for x in (20, 32, 44))
            + '<path d="M21 36 C21 31 24 27 28 26" fill="none" stroke="#FFFFFF" stroke-width="2.2" stroke-linecap="round"/>')


def g_deflect():
    return (stroke2("M15 15 L30 37", "#BFD6FF", 3, 7) + stroke2("M33 37 L45 21", "#FFFFFF", 3.2, 7)
            + solid("M49 16 L47 28 L43 23.5 L38 23 Z", "#FFFFFF", 2.4)
            + stroke2("M18 44 L46 44", "#6FA2FF", 6, 10)
            + solid("M31.5 33 L33.5 37.5 L38 39.5 L33.5 41.5 L31.5 46 L29.5 41.5 L25 39.5 L29.5 37.5Z", "#FFF3C4", 1.8))


def g_wave_mend():
    heart = "M32 51 C14 39 11 28 17 21 C22 16 29 18 32 24 C35 18 42 16 47 21 C53 28 50 39 32 51 Z"
    return (grad("d3", [(0, "#FFD0D8"), (.5, "#FF7F98"), (1, "#E0405E")], 1, 1) + solid(heart, "url(#d3)", 3)
            + stroke2("M12 34 H22 L26 27 L30 41 L34 25 L37 34 H52", "#FFFFFF", 2.6, 6))


def g_bastion():
    body = "M22 30 H42 V53 H22 Z"
    cren = "M20 23 H25 V27 H29.5 V23 H34.5 V27 H39 V23 H44 V31 H20 Z"
    return (grad("d4", BLUE_G, 1, 1) + solid(body, "url(#d4)", 3) + solid(cren, "#BFD6FF", 2.8)
            + solid("M28 53 V45 Q32 40 36 45 V53 Z", "#0A1F4A", 2.2)
            + grad("d4c", [(0, "#E6FFFF"), (1, "#7FDCEB")], 1, 1) + solid("M32 6 L39 15 L32 23 L25 15 Z", "url(#d4c)", 2.6)
            + '<path d="M32 6 L39 15 L32 15Z" fill="#FFFFFF" opacity=".8"/>')


def g_particle_magnet():
    u = "M20 24 V33 A12 12 0 0 0 44 33 V24"
    return (f'<path d="{u}" fill="none" stroke="{INK}" stroke-width="14"/>'
            + grad("e1", ORCH_G, 1, 1) + f'<path d="{u}" fill="none" stroke="url(#e1)" stroke-width="9"/>'
            + solid("M14.5 22 H25.5 V29 H14.5 Z", "#E6F0FF", 2.6) + solid("M38.5 22 H49.5 V29 H38.5 Z", "#E6F0FF", 2.6)
            + sparkle(32, 24, 7) + sparkle(24, 11, 4.5) + sparkle(41, 12, 4.5))


def g_seed_charge():
    return (grad("e2", ORCH_G, 1, 1) + solid("M10 21 H46 Q49 21 49 24 V42 Q49 45 46 45 H10 Q7 45 7 42 V24 Q7 21 10 21Z", "url(#e2)", 3)
            + solid("M49 28 H54 V38 H49 Z", "#F6D2FF", 2.6)
            + f'<rect x="12" y="26" width="32" height="14" rx="2" fill="#1E0A2A" stroke="{INK}" stroke-width="2"/>'
            + "".join(f'<rect x="{x}" y="28.5" width="5" height="9" rx="1" fill="#5CF08A"/>' for x in (14.5, 20.5))
            + sparkle(34, 33, 7.5))


def g_cool_mind():
    flake = "".join(stroke2(f"M{45 - 8 * math.cos(math.radians(a)):.1f} {20 - 8 * math.sin(math.radians(a)):.1f} "
                            f"L{45 + 8 * math.cos(math.radians(a)):.1f} {20 + 8 * math.sin(math.radians(a)):.1f}", "#CFF6FF", 2.4, 5.5)
                    for a in (90, 30, 150))
    return (grad("e3", [(0, "#FFFFFF"), (1, "#E9C8FF")], 1, 1)
            + f'<circle cx="29" cy="35" r="16" fill="url(#e3)" stroke="{INK}" stroke-width="3"/>'
            + f'<circle cx="29" cy="35" r="12.5" fill="none" stroke="#B65AE0" stroke-width="1.6"/>'
            + f'<path d="M29 35 V25.5 M29 35 L36 39" fill="none" stroke="{INK}" stroke-width="3" stroke-linecap="round"/>'
            + f'<circle cx="29" cy="35" r="2.2" fill="{INK}"/>' + flake)


def g_golden_core():
    oct_ = " ".join(f"{28 + 16 * math.cos(math.radians(a)):.1f},{28 + 16 * math.sin(math.radians(a)):.1f}" for a in range(-90, 270, 45))
    return (grad("e4", [(0, "#FFF3C4"), (.45, "#FFC93D"), (1, "#C98410")], 1, 1)
            + f'<polygon points="{oct_}" fill="url(#e4)" stroke="{INK}" stroke-width="3" stroke-linejoin="round"/>'
            + f'<polygon points="28,17 37,28 28,39 19,28" fill="#FFF6D2" stroke="#7A4A06" stroke-width="1.8" stroke-linejoin="round"/>'
            + '<path d="M28 28 L37 28 L28 39 L19 28Z" fill="#E8A21C"/>'
            + f'<circle cx="43" cy="44" r="10" fill="#5A3604" transform="translate(0 1.5)"/>'
            + f'<circle cx="43" cy="44" r="10" fill="#FFD95C" stroke="{INK}" stroke-width="2.8"/>'
            + '<path d="M43 37.5 L48 44 L43 50.5 L38 44Z" fill="#FFF0B8" stroke="#7A4A06" stroke-width="1.6" stroke-linejoin="round"/>')


TALENTS = [  # nome (id sem talent_), ramo, glifo, rótulo da prévia
    ("sharp_core", "atk", g_sharp_core, "Núcleo Afiado"), ("quick_pulse", "atk", g_quick_pulse, "Pulso Veloz"),
    ("arcane_burst", "atk", g_arcane_burst, "Surto Arcano"), ("piercing_ray", "atk", g_piercing_ray, "Raio Perfurante"),
    ("hardened_shell", "def", g_hardened_shell, "Casca Reforçada"), ("deflect", "def", g_deflect, "Desvio"),
    ("wave_mend", "def", g_wave_mend, "Reparo de Onda"), ("bastion", "def", g_bastion, "Bastião"),
    ("particle_magnet", "eco", g_particle_magnet, "Ímã de Partículas"), ("seed_charge", "eco", g_seed_charge, "Carga Inicial"),
    ("cool_mind", "eco", g_cool_mind, "Mente Fria"), ("golden_core", "eco", g_golden_core, "Núcleo Dourado"),
]


def icon(i):
    name, b, fn, _ = TALENTS[i]
    return lambda: plate(b, i) + fn()


# ---------- moldura do nó: canvas 112, corpo 96x96 em (8,8), chanfro 16 ----------
def oct_pts(x, y, w, c):
    return f"{x + c},{y} {x + w - c},{y} {x + w},{y + c} {x + w},{y + w - c} {x + w - c},{y + w} {x + c},{y + w} {x},{y + w - c} {x},{y + c}"


B = oct_pts(8, 8, 96, 16)
BI = oct_pts(13, 13, 86, 13)


def node(state):
    gl = lambda col, a: gh.blur("ng", 3) + f'<g filter="url(#ng)" opacity="{a}"><polygon points="{B}" fill="{col}"/></g>'
    base = f'<polygon points="{oct_pts(7, 9, 98, 16.5)}" fill="{INK}"/>'
    dark = gh.grad("nd", [(0, "#0A2A44"), (1, "#041A2C")]) + f'<polygon points="{B}" fill="url(#nd)"/>'
    if state == "normal":
        return (base + dark + f'<polygon points="{B}" fill="none" stroke="{LINE_DIM}" stroke-width="2.5"/>'
                + f'<rect x="30" y="12" width="52" height="1.5" fill="rgba(230,255,255,.18)"/>')
    if state == "locked":
        return (base + f'<polygon points="{B}" fill="{DIS_FILL}" stroke="{DIS_LINE}" stroke-width="2.5" stroke-dasharray="7 5"/>')
    if state == "selected":
        br = "".join(f'<path d="{d}" fill="none" stroke="{TEXT}" stroke-width="3" stroke-linecap="square"/>'
                     for d in ("M3 30 V19 L19 3 H30", "M82 109 H93 L109 93 V82"))
        return (gl(LINE, .75) + base + dark + gh.grad("ns", [(0, "rgba(63,232,245,.22)"), (1, "rgba(63,232,245,.04)")])
                + f'<polygon points="{B}" fill="url(#ns)" stroke="{LINE}" stroke-width="3"/>' + br)
    if state == "owned":
        return (gl(LINE, .55) + base + dark + gh.grad("no", [(0, "rgba(63,232,245,.38)"), (1, "rgba(63,232,245,.10)")])
                + f'<polygon points="{B}" fill="url(#no)" stroke="{LINE}" stroke-width="2.5"/>'
                + f'<polygon points="{BI}" fill="none" stroke="rgba(230,255,255,.35)" stroke-width="1.2"/>'
                + f'<rect x="30" y="12" width="52" height="2" fill="rgba(230,255,255,.5)"/>')
    # max: dourado, borda dupla e 4 losangos nos chanfros
    gems = "".join(f'<polygon points="{x},{y - 4} {x + 4},{y} {x},{y + 4} {x - 4},{y}" fill="#FFE08A" stroke="{INK}" stroke-width="1.5"/>'
                   for x, y in ((16, 16), (96, 16), (16, 96), (96, 96)))
    return (gl(GOLD, .7) + base + gh.grad("nm", [(0, "#3A2C10"), (1, "#1E1A14")]) + f'<polygon points="{B}" fill="url(#nm)"/>'
            + f'<polygon points="{B}" fill="none" stroke="{GOLD}" stroke-width="3"/>'
            + f'<polygon points="{BI}" fill="none" stroke="rgba(255,224,138,.6)" stroke-width="1.5"/>' + gems)


# ---------- selo de nível (9-slice 12): 56x28, chanfro 6 ----------
def chip_pts(x, y, w, h, c):
    return f"{x + c},{y} {x + w - c},{y} {x + w},{y + c} {x + w},{y + h - c} {x + w - c},{y + h} {x + c},{y + h} {x},{y + h - c} {x},{y + c}"


CHIP = (f'<polygon points="{chip_pts(0, 0, 56, 28, 7)}" fill="{INK}"/>'
        + f'<polygon points="{chip_pts(2, 2, 52, 24, 6)}" fill="#3FA9C0"/>'
        + f'<polygon points="{chip_pts(4, 4, 48, 20, 5)}" fill="#06223A"/>')


# ---------- ligações: perfil uniforme no comprimento (tileável), largura 24 ----------
def link(on, vertical):
    if on:
        layers = [(24, "rgba(63,232,245,.10)"), (18, "rgba(63,232,245,.22)"), (10, INK), (7, LINE), (2.5, TEXT)]
        body = "".join(f'<rect x="{12 - w / 2}" y="0" width="{w}" height="16" fill="{c}"/>' for w, c in layers)
    else:  # tracejada (10 cheio + 6 vazio a cada 16) e sem brilho: lê "apagada" sem depender da cor
        body = (f'<rect x="7.5" y="0" width="9" height="10" rx="2" fill="{INK}"/>'
                f'<rect x="9.5" y="1.5" width="5" height="7" rx="1.5" fill="{DIS_LINE}"/>')
    if vertical:
        return f'<svg xmlns="http://www.w3.org/2000/svg" width="24" height="16" viewBox="0 0 24 16">{body}</svg>', 24, 16
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="16" height="24" viewBox="0 0 16 24">'
            f'<g transform="translate(16 0) rotate(90)">{body}</g></svg>'), 16, 24


def pieces():
    out = {}  # nome: (svg completo, w, h)
    for i, (n, *_ ) in enumerate(TALENTS):
        out[f"ui_icon_talent_{n}"] = (gi.svg(64, icon(i)()), 64, 64)
        out[f"ui_icon_talent_{n}_off"] = (gi.svg(64, gh.locked(icon(i))), 64, 64)
    for st in ("normal", "selected", "owned", "max", "locked"):
        nm = "ui_talent_node" + ("" if st == "normal" else f"_{st}")
        out[nm] = (f'<svg xmlns="http://www.w3.org/2000/svg" width="112" height="112" viewBox="0 0 112 112">{node(st)}</svg>', 112, 112)
    out["ui_talent_level_chip"] = (f'<svg xmlns="http://www.w3.org/2000/svg" width="56" height="28" viewBox="0 0 56 28">{CHIP}</svg>', 56, 28)
    for v in (True, False):
        for on in (False, True):
            out[f"ui_talent_link_{'v' if v else 'h'}_{'on' if on else 'off'}"] = link(on, v)
    return out


def build(ps):
    for name, (s, w, h) in ps.items():
        sp = HERE / f"{name}.svg"
        sp.write_text(s, encoding="utf-8")
        png = UI / f"{name}.png"
        render(sp, png, w, h)
        optimize(png)


# ---------- prévia 375x812 (PNG a 50%): árvore no nível 3, 2 nós comprados ----------
u = gh.u
COLX = [75, 187.5, 300]
ROWY = [172, 272, 372, 472]
COL = {"atk": "#FF9F43", "def": "#4F8DFF", "eco": "#E07BFF"}
MAXL = {"piercing_ray": 1, "bastion": 1, "golden_core": 3}
LEVEL = {"sharp_core": 2, "hardened_shell": 1}            # comprados
SELECTED = "quick_pulse"
PREREQ = {"quick_pulse": [("sharp_core", 1)], "arcane_burst": [("quick_pulse", 3)], "piercing_ray": [("arcane_burst", 3), ("deflect", 1)],
          "deflect": [("hardened_shell", 1)], "wave_mend": [("deflect", 3)], "bastion": [("wave_mend", 3), ("seed_charge", 1)],
          "seed_charge": [("particle_magnet", 1)], "cool_mind": [("seed_charge", 3)], "golden_core": [("cool_mind", 3), ("quick_pulse", 1)]}


def pos(n):
    i = [t[0] for t in TALENTS].index(n)
    return COLX[i // 4], ROWY[i % 4]


def available(n):
    return all(LEVEL.get(p, 0) >= k for p, k in PREREQ.get(n, []))


def seg(x0, y0, x1, y1, on, ext=6):
    L = math.hypot(x1 - x0, y1 - y0) + 2 * ext
    a = math.degrees(math.atan2(y1 - y0, x1 - x0))
    h = u(f"ui_talent_link_h_{'on' if on else 'off'}")
    return (f'<div class="a" style="left:{x0}px;top:{y0 - 6}px;width:{L:.1f}px;height:12px;transform-origin:0 6px;'
            f'transform:rotate({a:.2f}deg) translateX(-{ext}px);background:url({h}) 0 0/8px 12px repeat-x"></div>')


def tree_html(sheet=False):
    font = (ROOT / "assets" / "fonts" / "Outfit-Variable.ttf").as_uri()
    css = ('*{margin:0;padding:0;box-sizing:border-box}body{width:375px;height:812px;background:#021423;font-family:Outfit;color:#E6FFFF;position:relative;overflow:hidden}'
           '.a{position:absolute}.lbl{width:75px;text-align:center;font-size:11.5px;font-weight:700;letter-spacing:.3px}'
           f'.chip{{height:20px;font-size:11px;font-weight:800;color:#9FB8CC;border-style:solid;border-width:10px 6px 10px 19px;'
           f'border-image:url({u("ui_nav_lock_chip")}) 20 12 20 38 fill stretch;display:flex;align-items:center;margin-top:-1px}}'
           f'.lv{{width:34px;height:14px;margin-left:-17px;border-style:solid;border-width:6px;border-image:url({u("ui_talent_level_chip")}) 12 fill stretch;'
           'font-size:10px;font-weight:800;line-height:2px;text-align:center;letter-spacing:.3px}'
           '.br{width:112px;margin-left:-56px;text-align:center;font-size:11px;font-weight:800;letter-spacing:2px}')
    s = (f'<div class="a" style="left:-12px;top:0;width:399px;height:812px;background:url({(UI / "title_bg_tech.webp").as_uri()}) 0 -300px/100% auto;opacity:.35"></div>'
         f'<div class="a" style="left:12px;top:36px;width:104px;height:56px;border-style:solid;border-width:10px;border-image:url({u("ui_holo_pill")}) 20 fill stretch"></div>'
         f'<img class="a" src="{u("ui_icon_back")}" style="left:28px;top:55px;width:18px;height:18px">'
         '<div class="a" style="left:50px;top:52px;font-size:17px;font-weight:800;letter-spacing:1px">Voltar</div>'
         '<div class="a" style="left:0;width:375px;top:50px;text-align:center;font-size:20px;font-weight:800;letter-spacing:1px">Núcleos</div>'
         f'<div class="a" style="left:279px;top:44px;width:84px;height:40px;border-style:solid;border-width:10px;border-image:url({u("ui_holo_pill")}) 20 fill stretch"></div>'
         f'<img class="a" src="{u("ui_icon_coin_small")}" style="left:288px;top:52px;width:24px;height:24px">'
         '<div class="a" style="left:316px;top:53px;font-size:16px;font-weight:800;color:#FFE08A">170</div>')
    for x, (t, c) in zip(COLX, (("ATAQUE", "atk"), ("DEFESA", "def"), ("ECONOMIA", "eco"))):
        s += f'<div class="a br" style="left:{x}px;top:116px;color:{COL[c]}">{t}</div>'
    # ligações (por baixo dos nós)
    for n, ps in PREREQ.items():
        x1, y1 = pos(n)
        for p, k in ps:
            x0, y0 = pos(p)
            on = LEVEL.get(p, 0) >= k  # acesa = este pré-requisito já cumprido
            if (p, n) == ("quick_pulse", "golden_core"):  # rota por fora: esquerda, baixo, direita, sobe
                for a, b in (((x0, y0), (19, y0)), ((19, y0), (19, 518)), ((19, 518), (x1, 518)), ((x1, 518), (x1, y1))):
                    s += seg(*a, *b, on)
            else:
                s += seg(x0, y0, x1, y1, on, 0)
    for n, b, _, _ in TALENTS:
        x, y = pos(n)
        lv, mx = LEVEL.get(n, 0), MAXL.get(n, 5)
        av = available(n)
        st = "max" if lv >= mx else "owned" if lv else "selected" if n == SELECTED else "normal" if av else "locked"
        fr = "ui_talent_node" + ("" if st == "normal" else f"_{st}")
        s += f'<img class="a" src="{u(fr)}" style="left:{x - 28}px;top:{y - 28}px;width:56px;height:56px">'
        s += f'<img class="a" src="{u("ui_icon_talent_" + n + ("" if av else "_off"))}" style="left:{x - 16}px;top:{y - 18}px;width:32px;height:32px">'
        s += f'<div class="a lv" style="left:{x}px;top:{y + 17}px;color:{"#E6FFFF" if av else "#5F7A92"}">{lv}/{mx}</div>'
    # painel do nó selecionado
    s += (f'<div class="a" style="left:12px;top:540px;width:351px;height:150px;border-style:solid;border-width:36px;'
          f'border-image:url({u("ui_holo_panel")}) 72 fill stretch"></div>'
          f'<img class="a" src="{u("ui_talent_node_selected")}" style="left:26px;top:558px;width:56px;height:56px">'
          f'<img class="a" src="{u("ui_icon_talent_quick_pulse")}" style="left:38px;top:568px;width:32px;height:32px">'
          '<div class="a" style="left:92px;top:560px;font-size:17px;font-weight:800">Pulso Veloz</div>'
          '<div class="a" style="left:92px;top:582px;font-size:11px;font-weight:700;letter-spacing:1px;color:#FF9F43">ATAQUE · NV 0/5</div>'
          '<div class="a" style="left:92px;top:600px;font-size:12px;font-weight:600;color:#9FF6FF">+3% de cadência de tiro por nível</div>'
          f'<div class="a" style="left:96px;top:624px;width:184px;height:60px;border-style:solid;border-width:28px 24px;'
          f'border-image:url({u("ui_holo_btn_primary_normal")}) 56 48 fill stretch"></div>'
          '<div class="a" style="left:96px;top:640px;width:184px;text-align:center;font-size:19px;font-weight:800;letter-spacing:1.5px;color:#03202E">'
          'COMPRAR · 120</div>')
    s += gh.bar_html(702, "cores", 3)
    return f'<html><head><meta charset="utf-8"><style>@font-face{{font-family:Outfit;src:url({font});font-weight:100 900}}{css}</style></head><body>{s}</body></html>'


def sheet_html():
    font = (ROOT / "assets" / "fonts" / "Outfit-Variable.ttf").as_uri()
    s = '<div class="t" style="top:6px">Molduras: normal · selecionado · comprado · máximo · bloqueado (1:1 a 50%)</div>'
    for i, (st, ic) in enumerate((("", "quick_pulse"), ("_selected", "deflect"), ("_owned", "sharp_core"), ("_max", "golden_core"), ("_locked", "bastion"))):
        x = 14 + i * 72
        s += f'<img class="a" src="{u("ui_talent_node" + st)}" style="left:{x}px;top:24px;width:56px;height:56px">'
        s += f'<img class="a" src="{u("ui_icon_talent_" + ic + ("_off" if st == "_locked" else ""))}" style="left:{x + 12}px;top:34px;width:32px;height:32px">'
    s += '<div class="t" style="top:92px">12 ícones (a 50% e a 100%) e versões _off</div>'
    for i, (n, *_ ) in enumerate(TALENTS):
        x = 6 + i * 30.5
        s += f'<img class="a" src="{u("ui_icon_talent_" + n)}" style="left:{x}px;top:110px;width:28px;height:28px">'
        s += f'<img class="a" src="{u("ui_icon_talent_" + n + "_off")}" style="left:{x}px;top:142px;width:28px;height:28px">'
    for i, (n, *_ ) in enumerate(TALENTS):
        s += f'<img class="a" src="{u("ui_icon_talent_" + n)}" style="left:{6 + (i % 6) * 62}px;top:{178 + (i // 6) * 62}px;width:56px;height:56px">'
    s += '<div class="t" style="top:306px">Ligações: v off/on (repeat-y) · h off/on (repeat-x) · diagonal</div>'
    for i, n in enumerate(("v_off", "v_on")):
        s += f'<div class="a" style="left:{20 + i * 30}px;top:324px;width:12px;height:60px;background:url({u("ui_talent_link_" + n)}) 0 0/12px 8px repeat-y"></div>'
    for i, n in enumerate(("h_off", "h_on")):
        s += f'<div class="a" style="left:90px;top:{336 + i * 24}px;width:110px;height:12px;background:url({u("ui_talent_link_" + n)}) 0 0/8px 12px repeat-x"></div>'
    s += seg(230, 330, 280, 380, False, 0) + seg(290, 330, 340, 380, True, 0)
    s += f'<div class="a lv" style="left:60px;top:396px;width:44px;margin-left:0;color:#E6FFFF">3/5</div>'
    s += f'<div class="a" style="left:0;top:418px;width:375px;height:30px;background:repeating-conic-gradient(#F6E9CF 0 25%,#EEDDBD 0 50%) 0 0/24px 24px"></div>'
    for i, (n, *_ ) in enumerate(TALENTS):
        s += f'<img class="a" src="{u("ui_icon_talent_" + n)}" style="left:{6 + i * 30.5}px;top:419px;width:28px;height:28px">'
    css = ('*{margin:0;padding:0;box-sizing:border-box}body{width:375px;height:452px;background:#021423;font-family:Outfit;color:#E6FFFF;position:relative;overflow:hidden}'
           '.a{position:absolute}.t{position:absolute;left:10px;font-size:10px;font-weight:600;color:#7FA3B8;letter-spacing:.4px}'
           f'.lv{{height:14px;border-style:solid;border-width:6px;border-image:url({u("ui_talent_level_chip")}) 12 fill stretch;'
           'font-size:10px;font-weight:800;line-height:2px;text-align:center}')
    return f'<html><head><meta charset="utf-8"><style>@font-face{{font-family:Outfit;src:url({font});font-weight:100 900}}{css}</style></head><body>{s}</body></html>'


def sheets():
    tp = HERE / "talent_tree.html"
    tp.write_text(tree_html(), encoding="utf-8")
    out = ROOT / "docs" / "img" / "nucleos-pecas.png"
    render(tp, out, 375, 812, 2); optimize(out)
    sp = HERE / "talent_sheet.html"
    sp.write_text(sheet_html(), encoding="utf-8")
    out = HERE / "talent_sheet.png"
    render(sp, out, 375, 452, 2); optimize(out)


if __name__ == "__main__":
    ps = pieces()
    build(ps)
    sheets()
    tot = 0
    for n, (_, w, h) in ps.items():
        b = (UI / f"{n}.png").stat().st_size; tot += b
        print(n, f"{w}x{h}", b, "B")
    print("total", len(ps), "PNG", tot, "B")
