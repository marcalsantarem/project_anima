"""Ícones da Moeda e do glossário do hangar no estilo holográfico (T-162, BRF-130).
Uso: python gen_ui_icons.py   (de qualquer pasta). SVG por código -> Chrome headless -> ffmpeg (helpers do gen_ui_holo.py).
Saídas: assets/ui/ui_icon_coin.png (128), ui_icon_coin_small.png (48, desenho simplificado para a pílula do menu),
ui_icon_module.png, ui_icon_component.png, ui_icon_core.png, ui_icon_module_fragment.png (128),
_src/icons_glossary_sheet.png (folha de conferência) e docs/img/icones-glossario.png (prévia, fundo HUD x arena).
Regras: contorno #021423, uma cor de identidade por conceito, sem texto, brilho pintado (sem blur em tempo real)."""
from gen_ui_holo import HERE, UI, ROOT, render, optimize

INK = "#021423"  # contorno (holo_bg)


def svg(px, inner, vb=64):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{px}" height="{px}" viewBox="0 0 {vb} {vb}">'
            f'{inner}</svg>')


def glow(shape, color, std=2.2, alpha=.55, fid="g"):
    """Brilho pintado: cópia borrada da silhueta por baixo (fica na textura)."""
    return (f'<defs><filter id="{fid}" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="{std}"/>'
            f'</filter></defs><g filter="url(#{fid})" opacity="{alpha}">{shape.replace("FILL", color)}</g>')


def grad(gid, stops, x2=0, y2=1):
    s = "".join(f'<stop offset="{o}" stop-color="{c}"/>' for o, c in stops)
    return f'<defs><linearGradient id="{gid}" x1="0" y1="0" x2="{x2}" y2="{y2}">{s}</linearGradient></defs>'


# ---------- Moeda: disco dourado com aro e losango em relevo (círculo = Moeda; estrela = Partícula; hexágono = XP) ----------
def coin():
    disc = '<circle cx="32" cy="32" r="25" fill="FILL"/>'
    return (glow(disc, "#FFC93D", 2.4, .55, "gc")
            + grad("cg", [(0, "#FFE9A3"), (.45, "#FFC93D"), (1, "#C98410")])
            + grad("cr", [(0, "#B87410"), (1, "#7A4A06")])
            + '<circle cx="32" cy="34" r="25" fill="#5A3604"/>'                      # espessura (3/4)
            + f'<circle cx="32" cy="32" r="25" fill="url(#cg)" stroke="{INK}" stroke-width="3.5"/>'
            + '<circle cx="32" cy="32" r="18.5" fill="url(#cr)" opacity=".55"/>'     # aro interno rebaixado
            + '<circle cx="32" cy="32" r="18.5" fill="none" stroke="#FFF3C4" stroke-width="1.6" opacity=".9"/>'
            + '<path d="M32 18 L44 32 L32 46 L20 32Z" fill="#FFD95C" stroke="#7A4A06" stroke-width="2" stroke-linejoin="round"/>'
            + '<path d="M32 18 L44 32 L32 32Z" fill="#FFF6D2"/><path d="M32 46 L20 32 L32 32Z" fill="#D89414"/>'
            + '<path d="M14.5 24 A19 19 0 0 1 26 12.6" fill="none" stroke="#FFFFFF" stroke-width="2.6" stroke-linecap="round" opacity=".85"/>'
            + '<circle cx="45" cy="19" r="1.8" fill="#FFFFFF"/>')


def coin_small():
    """Versão para 24-48 px: contorno mais grosso, sem aro fino nem faíscas."""
    disc = '<circle cx="24" cy="24" r="19" fill="FILL"/>'
    return (glow(disc, "#FFC93D", 1.6, .5, "gs")
            + grad("sg", [(0, "#FFE48A"), (1, "#E09A12")])
            + '<circle cx="24" cy="26" r="19" fill="#5A3604"/>'
            + f'<circle cx="24" cy="24" r="19" fill="url(#sg)" stroke="{INK}" stroke-width="3.5"/>'
            + '<path d="M24 12.5 L33.5 24 L24 35.5 L14.5 24Z" fill="#FFF0B8" stroke="#7A4A06" stroke-width="2.4" stroke-linejoin="round"/>'
            + '<path d="M24 24 L33.5 24 L24 35.5 L14.5 24Z" fill="#E8A21C"/>'
            + '<path d="M11 20 A14 14 0 0 1 19 11.5" fill="none" stroke="#FFFFFF" stroke-width="2.6" stroke-linecap="round" opacity=".9"/>')


def chip_frame(cx, cy, r, c, line, fill, gid):
    """Placa chanfrada (octógono) da família holográfica: moldura na cor de identidade + miolo escuro."""
    pts = lambda rr, cc: (f"{cx - rr + cc},{cy - rr} {cx + rr - cc},{cy - rr} {cx + rr},{cy - rr + cc} {cx + rr},{cy + rr - cc} "
                          f"{cx + rr - cc},{cy + rr} {cx - rr + cc},{cy + rr} {cx - rr},{cy + rr - cc} {cx - rr},{cy - rr + cc}")
    body = f'<polygon points="{pts(r, c)}" fill="FILL"/>'
    return (glow(body, line, 2.2, .5, gid)
            + f'<polygon points="{pts(r, c)}" fill="{INK}" transform="translate(0 2)"/>'
            + f'<polygon points="{pts(r, c)}" fill="{fill}" stroke="{INK}" stroke-width="3.5" stroke-linejoin="round"/>'
            + f'<polygon points="{pts(r - 3.2, c - 1.3)}" fill="none" stroke="{line}" stroke-width="2.2" stroke-linejoin="round"/>')


# ---------- Módulo (poder ativo): placa ciano com raio de energia ----------
def module():
    bolt = "M36 12 L20 35 L30 35 L26 52 L44 27 L34 27 Z"
    return (chip_frame(32, 32, 25, 9, "#3FE8F5", "#06304A", "gm")
            + f'<path d="{bolt}" fill="#3FE8F5" stroke="{INK}" stroke-width="3" stroke-linejoin="round"/>'
            + '<path d="M36 12 L20 35 L27 35 Z" fill="#E6FFFF"/>'
            + '<circle cx="18" cy="18" r="1.8" fill="#E6FFFF"/>')


# ---------- Componente (equipamento): peça encaixável laranja (placa com pinos e soquete) ----------
def component():
    pins = "".join(f'<rect x="{x}" y="6" width="5" height="9" rx="1.5" fill="#FFB25E" stroke="{INK}" stroke-width="2.4"/>'
                   f'<rect x="{x}" y="49" width="5" height="9" rx="1.5" fill="#C9661A" stroke="{INK}" stroke-width="2.4"/>'
                   for x in (19.5, 29.5, 39.5))
    pins += "".join(f'<rect x="6" y="{y}" width="9" height="5" rx="1.5" fill="#FFB25E" stroke="{INK}" stroke-width="2.4"/>'
                    f'<rect x="49" y="{y}" width="9" height="5" rx="1.5" fill="#C9661A" stroke="{INK}" stroke-width="2.4"/>'
                    for y in (24.5, 34.5))
    return (glow('<rect x="10" y="10" width="44" height="44" rx="7" fill="FILL"/>', "#FF9F43", 2.4, .5, "gq")
            + pins + grad("qg", [(0, "#FFC07A"), (.5, "#FF9F43"), (1, "#D9671C")])
            + f'<rect x="12" y="14" width="40" height="40" rx="7" fill="{INK}"/>'
            + f'<rect x="12" y="12" width="40" height="40" rx="7" fill="url(#qg)" stroke="{INK}" stroke-width="3.5"/>'
            + f'<rect x="21" y="21" width="22" height="22" rx="4" fill="#3A1A06" stroke="{INK}" stroke-width="2.4"/>'
            + '<rect x="25" y="25" width="14" height="14" rx="2.5" fill="#FFD9A8"/>'
            + '<path d="M25 25 H39 L25 39Z" fill="#FFFFFF" opacity=".75"/>'
            + '<path d="M16 19 A6 6 0 0 1 20 15.5" fill="none" stroke="#FFFFFF" stroke-width="2.4" stroke-linecap="round" opacity=".85"/>')


# ---------- Núcleo (talento): esfera azul com três ramos ligados (árvore de talentos) ----------
def core():
    nodes = [(32, 13), (13.5, 46), (50.5, 46)]
    links = "".join(f'<line x1="32" y1="34" x2="{x}" y2="{y}" stroke="{INK}" stroke-width="7" stroke-linecap="round"/>'
                    f'<line x1="32" y1="34" x2="{x}" y2="{y}" stroke="#8FB8FF" stroke-width="3" stroke-linecap="round"/>'
                    for x, y in nodes)
    small = "".join(f'<circle cx="{x}" cy="{y}" r="6.5" fill="#4F8DFF" stroke="{INK}" stroke-width="3"/>'
                    f'<circle cx="{x - 1.6}" cy="{y - 1.8}" r="1.8" fill="#E6F0FF"/>' for x, y in nodes)
    return (glow('<circle cx="32" cy="34" r="14" fill="FILL"/><circle cx="32" cy="13" r="7" fill="FILL"/>'
                 '<circle cx="13.5" cy="46" r="7" fill="FILL"/><circle cx="50.5" cy="46" r="7" fill="FILL"/>', "#4F8DFF", 2.4, .55, "gn")
            + links + small + grad("ng", [(0, "#BFD6FF"), (.45, "#4F8DFF"), (1, "#2348C8")], 1, 1)
            + f'<circle cx="32" cy="35.5" r="13.5" fill="{INK}"/>'
            + f'<circle cx="32" cy="34" r="13.5" fill="url(#ng)" stroke="{INK}" stroke-width="3.5"/>'
            + '<circle cx="32" cy="34" r="5.5" fill="#E6F0FF"/>'
            + '<path d="M23.5 30 A9.5 9.5 0 0 1 28 25" fill="none" stroke="#FFFFFF" stroke-width="2.4" stroke-linecap="round" opacity=".9"/>')


# ---------- Fragmento de Módulo: cacos de cristal orquídea com a faísca do Módulo ----------
def module_fragment():
    big = "M30 8 L44 20 L38 44 L22 38 L18 18 Z"
    s1 = "M44 30 L56 36 L50 52 L40 48 Z"
    s2 = "M12 42 L22 46 L20 56 L8 54 Z"
    sil = "".join(f'<path d="{d}" fill="FILL"/>' for d in (big, s1, s2))
    shard = lambda d: f'<path d="{d}" fill="url(#fg)" stroke="{INK}" stroke-width="3.2" stroke-linejoin="round"/>'
    return (glow(sil, "#E07BFF", 2.4, .55, "gf")
            + grad("fg", [(0, "#F6D2FF"), (.45, "#E07BFF"), (1, "#A945E0")], 1, 1)
            + "".join(f'<path d="{d}" fill="{INK}" transform="translate(0 2)"/>' for d in (big, s1, s2))
            + shard(big) + shard(s1) + shard(s2)
            + '<path d="M30 8 L44 20 L31 24 Z" fill="#FFFFFF" opacity=".7"/>'
            + '<path d="M44 30 L56 36 L47 38Z" fill="#FFFFFF" opacity=".6"/>'
            + f'<path d="M33 17 L25 29 L30.5 29 L28 38 L37 25.5 L31.5 25.5 Z" fill="#3FE8F5" stroke="{INK}" stroke-width="2" stroke-linejoin="round"/>')


ICONS = {  # nome: (desenho, px, viewBox)
    "ui_icon_coin": (coin, 128, 64),
    "ui_icon_coin_small": (coin_small, 48, 48),
    "ui_icon_module": (module, 128, 64),
    "ui_icon_component": (component, 128, 64),
    "ui_icon_core": (core, 128, 64),
    "ui_icon_module_fragment": (module_fragment, 128, 64),
}
LABELS = {"ui_icon_coin": "Moeda", "ui_icon_module": "Módulo", "ui_icon_component": "Componente",
          "ui_icon_core": "Núcleo", "ui_icon_module_fragment": "Fragmento de Módulo"}


def build():
    for name, (fn, px, vb) in ICONS.items():
        sp = HERE / f"{name}.svg"
        sp.write_text(svg(px, fn(), vb), encoding="utf-8")
        png = UI / f"{name}.png"
        render(sp, png, px, px)
        optimize(png)


def sheet_html(w):
    font = (ROOT / "assets" / "fonts" / "Outfit-Variable.ttf").as_uri()
    def img(n, s):
        return f'<img src="{(UI / (n + ".png")).as_uri()}" style="width:{s}px;height:{s}px">'
    def row(bg, fg):
        cells = ""
        for n, lab in LABELS.items():
            small = "ui_icon_coin_small" if n == "ui_icon_coin" else n
            cells += (f'<div class="c">{img(n, 64)}<div class="s">{img(n, 44)}{img(small, 28)}</div>'
                      f'<div class="l" style="color:{fg}">{lab}</div></div>')
        return f'<div class="r" style="background:{bg}">{cells}</div>'
    ref = ('<div class="r ref" style="background:#021423"><span>referência:</span>'
           f'<img src="{(UI / "ui_icon_particles.png").as_uri()}" style="width:44px"><span>Partículas</span>'
           f'<img src="{(UI / "ui_icon_xp.png").as_uri()}" style="width:44px"><span>XP</span>'
           f'{img("ui_icon_coin_small", 28)}<span>Moeda 28</span>'
           f'<img src="{(UI / "ui_icon_particles.png").as_uri()}" style="width:28px"><span>Partículas 28</span></div>')
    return (f'<html><head><meta charset="utf-8"><style>@font-face{{font-family:Outfit;src:url({font});font-weight:100 900}}'
            f'*{{margin:0;padding:0}}body{{width:{w}px;font-family:Outfit;font-weight:700}}'
            '.r{display:flex;justify-content:space-around;padding:18px 8px}.c{display:flex;flex-direction:column;align-items:center;gap:8px;width:140px}'
            '.s{display:flex;align-items:center;gap:10px}.l{font-size:14px}'
            '.ref{justify-content:center;gap:10px;align-items:center;color:#7FA3B8;font-size:13px;padding:12px}'
            '.arena{background:repeating-conic-gradient(#F6E9CF 0 25%,#EEDDBD 0 50%) 0 0/48px 48px}</style></head><body>'
            + row("#021423", "#E6FFFF") + row("#06182A", "#9FF6FF")
            + row("repeating-conic-gradient(#F6E9CF 0 25%,#EEDDBD 0 50%) 0 0/48px 48px", "#3A2A5A")
            + ref + '</body></html>')


def sheets():
    for path, w in ((HERE / "icons_glossary_sheet.png", 760), (ROOT / "docs" / "img" / "icones-glossario.png", 760)):
        hp = HERE / "icons_glossary_sheet.html"
        hp.write_text(sheet_html(w), encoding="utf-8")
        render(hp, path, w, 668)
        optimize(path)


if __name__ == "__main__":
    build()
    sheets()
    for n in ICONS:
        p = UI / f"{n}.png"
        print(n, p.stat().st_size, "B")
