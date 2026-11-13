"""Peças da barra de navegação do hangar, opção A (T-199, BRF-145; mockup _src/hangar_mockup.html, docs/arte.md §11.9).
Uso: python gen_ui_hangar.py   (de qualquer pasta). Desenho em 1x (mockup 375 px); o PNG sai em 2x (helpers do gen_ui_holo.py).
Saídas em assets/ui/: ui_nav_bar, ui_nav_tab_active, ui_nav_tab_pressed, ui_nav_lock_chip, ui_icon_nav_play, ui_icon_back,
ui_icon_nav_{modules,components,cores,settings}, ui_icon_{module,component,core}_locked;
folha _src/hangar_sheet.png e prévia docs/img/hangar-pecas.png (barra montada com as peças reais).
Regras: contorno #021423, miolo escuro, moldura ciano, brilho pintado, sem texto na arte."""
import re
from gen_ui_holo import HERE, UI, ROOT, render, optimize, svg, LINE, LINE_DIM, TEXT, TEXT2
import gen_ui_icons as gi

INK = "#021423"


def grad(gid, stops):
    return (f'<defs><linearGradient id="{gid}" x1="0" y1="0" x2="0" y2="1">'
            + "".join(f'<stop offset="{o}" stop-color="{c}"/>' for o, c in stops) + '</linearGradient></defs>')


def blur(gid, std):
    return f'<defs><filter id="{gid}" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="{std}"/></filter></defs>'


# ---------- fundo da barra (9-patch). Canvas 1x 64x60: brilho 0-4, linha em y 4, colchetes 22x2 nos cantos ----------
BAR = (grad("bb", [(0, "#0A2A44"), (.7, "#041A2C"), (1, "#041A2C")])
       + '<defs><linearGradient id="bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3FE8F5" stop-opacity="0"/>'
         '<stop offset="1" stop-color="#3FE8F5" stop-opacity=".22"/></linearGradient></defs>'
       + '<rect x="0" y="0" width="64" height="4" fill="url(#bg)"/>'
       + '<rect x="0" y="4" width="64" height="56" fill="url(#bb)" opacity=".97"/>'
       + f'<rect x="0" y="4" width="64" height="1.5" fill="{LINE_DIM}"/>'
       + f'<rect x="0" y="4" width="22" height="2" fill="{LINE}"/><rect x="42" y="4" width="22" height="2" fill="{LINE}"/>')


# ---------- placa da aba (célula 75x76 em (4,4); canvas 1x 83x84 = 4 px de brilho em volta) ----------
def plate_pts(x, y, w, h, c):  # chanfro só nos cantos de cima
    return f"{x + c},{y} {x + w - c},{y} {x + w},{y + c} {x + w},{y + h} {x},{y + h} {x},{y + c}"


def tab(pressed):
    x, y, w, h = 8, 8, 67, 68
    body = plate_pts(x, y, w, h, 10)
    if pressed:
        fill = grad("tp", [(0, "rgba(14,90,112,.85)"), (1, "rgba(14,90,112,.35)")])
        return (fill + f'<polygon points="{plate_pts(x - 1, y - 1, w + 2, h + 2, 10.5)}" fill="{INK}"/>'
                + f'<polygon points="{body}" fill="url(#tp)" stroke="{TEXT2}" stroke-width="1.5" stroke-opacity=".75" stroke-linejoin="round"/>')
    sx = 4 + 75 / 2 - 20
    return (blur("tg", 3) + f'<g filter="url(#tg)" opacity=".55"><polygon points="{body}" fill="{LINE}"/></g>'
            + f'<polygon points="{plate_pts(x - 1, y - 1, w + 2, h + 2, 10.5)}" fill="{INK}"/>'
            + grad("ta", [(0, "rgba(63,232,245,.32)"), (1, "rgba(63,232,245,.07)")])
            + f'<polygon points="{body}" fill="#041A2C"/>'
            + f'<polygon points="{body}" fill="url(#ta)" stroke="{LINE}" stroke-width="1.5" stroke-linejoin="round"/>'
            + f'<rect x="{x + 12}" y="{y + 3}" width="{w - 24}" height="1" fill="rgba(230,255,255,.35)"/>'
            + blur("ts", 2) + f'<g filter="url(#ts)"><rect x="{sx - 2}" y="3" width="44" height="6" fill="{LINE}"/></g>'
            + f'<rect x="{sx}" y="4" width="40" height="4" fill="{TEXT}"/>')


# ---------- selo "cadeado + NV" (9-patch). Canvas 1x 40x20: contorno 1 px, corpo 38x18, cadeado 13 px à esquerda ----------
def chip_pts(x, y, w, h, c):  # chanfro no canto sup. esq. e inf. dir.
    return f"{x + c},{y} {x + w},{y} {x + w},{y + h - c} {x + w - c},{y + h} {x},{y + h} {x},{y + c}"


LOCK_GRAY = "#B4CADB"
CHIP = (f'<polygon points="{chip_pts(0, 0, 40, 20, 4.5)}" fill="{INK}"/>'
        + f'<polygon points="{chip_pts(1, 1, 38, 18, 4)}" fill="#4A6A86"/>'
        + f'<polygon points="{chip_pts(2, 2, 36, 16, 3.5)}" fill="#0E2233"/>'
        + f'<svg x="3.5" y="3" width="13" height="13" viewBox="0 0 24 24">'
          f'<path d="M7.5 11V8a4.5 4.5 0 0 1 9 0v3" fill="none" stroke="{LOCK_GRAY}" stroke-width="2.6"/>'
          f'<rect x="5" y="11" width="14" height="10" rx="2" fill="#2A4258" stroke="{LOCK_GRAY}" stroke-width="2"/>'
          f'<circle cx="12" cy="16" r="1.8" fill="{LOCK_GRAY}"/></svg>')


# ---------- ícones (viewBox 1x; PNG 2x) ----------
PLAY_D = ("M16 3 L29 16 L16 29 L3 16Z", "M13 10.5 L22 16 L13 21.5Z")
PLAY = (blur("pg", 1.3) + f'<g filter="url(#pg)" opacity=".7"><path d="{PLAY_D[0]}" fill="none" stroke="{LINE}" stroke-width="3"/>'
        f'<path d="{PLAY_D[1]}" fill="{LINE}"/></g>'
        + f'<path d="{PLAY_D[0]}" fill="none" stroke="{INK}" stroke-width="4.6" stroke-linejoin="round"/>'
        + f'<path d="{PLAY_D[1]}" fill="{INK}" stroke="{INK}" stroke-width="3.6" stroke-linejoin="round"/>'
        + f'<path d="{PLAY_D[0]}" fill="rgba(6,48,74,.85)" stroke="{LINE}" stroke-width="2.2" stroke-linejoin="round"/>'
        + f'<path d="{PLAY_D[1]}" fill="{LINE}" stroke="{LINE}" stroke-width="1.5" stroke-linejoin="round"/>'
        + f'<path d="M13 10.5 L22 16 L13 16Z" fill="{TEXT}"/>')
BACK_D = "M11.5 3 L5.5 9 L11.5 15"
BACK = (f'<path d="{BACK_D}" fill="none" stroke="{INK}" stroke-width="4.8" stroke-linecap="round" stroke-linejoin="round"/>'
        + f'<path d="{BACK_D}" fill="none" stroke="{TEXT2}" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/>')
GEAR_D = ('M10.3 2h3.4l.5 2.6 1.6.7 2.2-1.5 2.4 2.4-1.5 2.2.7 1.6 2.6.5v3.4l-2.6.5-.7 1.6 1.5 2.2-2.4 2.4-2.2-1.5-1.6.7-.5 2.6'
          'h-3.4l-.5-2.6-1.6-.7-2.2 1.5-2.4-2.4 1.5-2.2-.7-1.6L2 13.7v-3.4l2.6-.5.7-1.6-1.5-2.2 2.4-2.4 2.2 1.5 1.6-.7z')
GEAR = (blur("sg", 1.2) + f'<g filter="url(#sg)" opacity=".6" transform="translate(2.2 2.2) scale(1.15)"><path d="{GEAR_D}" fill="{LINE}"/></g>'
        + f'<g transform="translate(2.2 2.2) scale(1.15)"><path d="{GEAR_D}" fill="{INK}" stroke="{INK}" stroke-width="2.4" stroke-linejoin="round"/>'
        + grad("sf", [(0, "#E6FFFF"), (1, "#7FDCEB")]) + f'<path d="{GEAR_D}" fill="url(#sf)"/>'
        + f'<circle cx="12" cy="12" r="3.8" fill="#06223A" stroke="{INK}" stroke-width="1.2"/>'
        + f'<circle cx="12" cy="12" r="2.6" fill="none" stroke="{TEXT2}" stroke-width="1"/></g>')


def locked(fn):
    """Versão bloqueada do ícone do glossário: sem brilho, cinza (luminância × 0,75) e 45% de opacidade na própria arte."""
    s = re.sub(r'<g filter="url\(#[^"]+\)" opacity="[^"]+">.*?</g>', "", fn())
    s = re.sub(r'id="([^"]+)"', r'id="L\1"', s).replace('url(#', 'url(#L')
    m = ('<defs><filter id="lk" color-interpolation-filters="sRGB"><feColorMatrix type="matrix" values="'
         '.16 .54 .05 0 0  .16 .54 .05 0 0  .16 .54 .05 0 0  0 0 0 .45 0"/></filter></defs>')
    return m + f'<g filter="url(#lk)">{s}</g>'


PIECES = {  # nome: (largura 1x, altura 1x, svg interno, viewBox) — PNG = 2x
    "ui_nav_bar": (64, 60, BAR, None),
    "ui_nav_tab_active": (83, 84, tab(False), None),
    "ui_nav_tab_pressed": (83, 84, tab(True), None),
    "ui_nav_lock_chip": (40, 20, CHIP, None),
    "ui_icon_nav_play": (32, 32, PLAY, 32),
    "ui_icon_back": (18, 18, BACK, 18),
    "ui_icon_nav_settings": (32, 32, GEAR, 32),
    "ui_icon_nav_modules": (32, 32, gi.module(), 64),
    "ui_icon_nav_components": (32, 32, gi.component(), 64),
    "ui_icon_nav_cores": (32, 32, gi.core(), 64),
    "ui_icon_module_locked": (32, 32, locked(gi.module), 64),
    "ui_icon_component_locked": (32, 32, locked(gi.component), 64),
    "ui_icon_core_locked": (32, 32, locked(gi.core), 64),
}


def build():
    for name, (w, h, inner, vb) in PIECES.items():
        sp = HERE / f"{name}.svg"
        if vb is None:
            sp.write_text(svg(w, h, inner), encoding="utf-8")
        else:
            sp.write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{w * 2}" height="{h * 2}" viewBox="0 0 {vb} {vb}">{inner}</svg>',
                          encoding="utf-8")
        png = UI / f"{name}.png"
        render(sp, png, w * 2, h * 2)
        optimize(png)


# ---------- folha de conferência: barra montada (conta nível 2) + peças soltas ----------
def u(n):
    return (UI / f"{n}.png").as_uri()


def bar_html(y, active, lvl, pressed=None):
    tabs = [("modules", "Módulos", 2, "module"), ("components", "Componentes", 4, "component"), ("play", "Jogar", 1, None),
            ("cores", "Núcleos", 3, "core"), ("settings", "Ajustes", 1, None)]
    s = (f'<div class="a" style="left:0;top:{y - 4}px;width:375px;height:114px;border-style:solid;'
         f'border-width:8px 24px 4px 24px;border-image:url({u("ui_nav_bar")}) 16 48 8 48 fill stretch"></div>')
    for i, (tid, name, nv, base) in enumerate(tabs):
        x = i * 75; cx = x + 37.5; on = tid == active; lock = lvl < nv
        if on or tid == pressed:
            s += f'<img class="a" src="{u("ui_nav_tab_active" if on else "ui_nav_tab_pressed")}" style="left:{x - 4}px;top:{y - 4}px;width:83px;height:84px">'
        isz = 32 if on else 28; iy = y + (9 if on else 12); ix = cx - isz / 2 - (12 if lock else 0)
        src = u(f"ui_icon_{base}_locked") if lock else u(f"ui_icon_nav_{tid}")
        s += f'<img class="a" src="{src}" style="left:{ix}px;top:{iy}px;width:{isz}px;height:{isz}px">'
        if lock:
            s += (f'<div class="a chip" style="left:{cx - 12}px;top:{iy + 14}px">NV {nv}</div>')
        col = "#6F8BA3" if lock else ("#E6FFFF" if on else "#9FC4D6")
        sh = ";text-shadow:0 0 6px rgba(63,232,245,.8)" if on else ""
        s += f'<div class="a lbl" style="left:{x}px;top:{y + 52}px;color:{col}{sh}">{name}</div>'
    return s


def sheet_html():
    font = (ROOT / "assets" / "fonts" / "Outfit-Variable.ttf").as_uri()
    css = ('*{margin:0;padding:0;box-sizing:border-box}body{width:375px;height:520px;background:#021423;font-family:Outfit;color:#E6FFFF;position:relative;overflow:hidden}'
           '.a{position:absolute}.lbl{width:75px;text-align:center;font-size:11.5px;font-weight:700;letter-spacing:.3px}'
           f'.chip{{height:20px;padding:0 6px 0 19px;font-size:11px;font-weight:800;line-height:19px;color:#9FB8CC;border-style:solid;border-width:10px 6px 10px 19px;'
           f'border-image:url({u("ui_nav_lock_chip")}) 20 12 20 38 fill stretch;padding:0;display:flex;align-items:center;margin-top:-1px}}'
           '.t{font-size:10px;font-weight:600;color:#7FA3B8;letter-spacing:.5px}')
    bg = f'<div class="a" style="left:-12px;top:0;width:399px;height:300px;background:url({(UI / "title_bg_tech.webp").as_uri()}) 0 -330px/100% auto;opacity:.6"></div>'
    s = bg + '<div class="a t" style="left:12px;top:8px">Jogar ativo (nível 2) · Componentes e Núcleos bloqueados</div>' + bar_html(28, "play", 2)
    s += '<div class="a t" style="left:12px;top:150px">Módulos ativo · Ajustes pressionado (nível 8)</div>' + bar_html(170, "modules", 8, "settings")
    y = 296
    s += f'<div class="a t" style="left:12px;top:{y}px">Peças a 1x (tamanho de tela) e ícones a 2x</div>'
    s += (f'<div class="a" style="left:12px;top:{y + 22}px;width:104px;height:56px;border-style:solid;border-width:10px;'
          f'border-image:url({u("ui_holo_pill")}) 20 fill stretch"></div>'
          f'<img class="a" src="{u("ui_icon_back")}" style="left:28px;top:{y + 41}px;width:18px;height:18px">'
          f'<div class="a" style="left:50px;top:{y + 38}px;font-size:17px;font-weight:800;letter-spacing:1px">Voltar</div>')
    for i, n in enumerate(["ui_nav_tab_active", "ui_nav_tab_pressed"]):
        s += f'<img class="a" src="{u(n)}" style="left:{130 + i * 92}px;top:{y + 14}px;width:83px;height:84px;outline:1px dashed rgba(255,201,61,.35)">'
    s += f'<div class="a chip" style="left:318px;top:{y + 40}px">NV 12</div>'
    icons = ["ui_icon_nav_play", "ui_icon_nav_modules", "ui_icon_nav_components", "ui_icon_nav_cores", "ui_icon_nav_settings",
             "ui_icon_module_locked", "ui_icon_component_locked", "ui_icon_core_locked"]
    for i, n in enumerate(icons):
        s += f'<img class="a" src="{u(n)}" style="left:{8 + i * 46}px;top:{y + 112}px;width:40px;height:40px">'
        s += f'<img class="a" src="{u(n)}" style="left:{14 + i * 46}px;top:{y + 160}px;width:28px;height:28px">'
    s += f'<div class="a" style="left:0;top:{y + 196}px;width:375px;height:28px;background:repeating-conic-gradient(#F6E9CF 0 25%,#EEDDBD 0 50%) 0 0/24px 24px"></div>'
    for i, n in enumerate(icons):
        s += f'<img class="a" src="{u(n)}" style="left:{14 + i * 46}px;top:{y + 196}px;width:28px;height:28px">'
    return f'<html><head><meta charset="utf-8"><style>@font-face{{font-family:Outfit;src:url({font});font-weight:100 900}}{css}</style></head><body>{s}</body></html>'


def sheets():
    hp = HERE / "hangar_sheet.html"
    hp.write_text(sheet_html(), encoding="utf-8")
    for path in (HERE / "hangar_sheet.png", ROOT / "docs" / "img" / "hangar-pecas.png"):
        render(hp, path, 375, 520, 2)
        optimize(path)


if __name__ == "__main__":
    build()
    sheets()
    tot = 0
    for n, (w, h, *_ ) in PIECES.items():
        b = (UI / f"{n}.png").stat().st_size; tot += b
        print(n, f"{w * 2}x{h * 2}", b, "B")
    print("total", tot, "B")
