"""Gera a arte dos menus holográficos (T-189, BRF-110) e a renderiza em PNG 2x no Chrome headless.
Uso: python gen_ui_holo.py [nomes...]   (de qualquer pasta). Desenho em 1x (mockup 375 px); o PNG sai em 2x.
Fonte dos valores: assets/mockups/_src/mockup_holo.html e docs/arte.md §11. Não toca nas peças do gen_ui.py.
Também gera _src/holo_check_*.png (folhas de validação montadas sobre os fundos; não vão para o jogo)."""
import pathlib, subprocess

HERE = pathlib.Path(__file__).resolve().parent
UI = HERE.parent
ROOT = UI.parents[1]
CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
FFMPEG = "ffmpeg"
SCALE = 2

# tokens holo_* (docs/arte.md §11.1)
LINE = "#3FE8F5"
LINE_DIM = "rgba(63,232,245,.38)"
PANEL = "rgba(6,34,58,.78)"
TEXT = "#E6FFFF"
TEXT2 = "#9FF6FF"
MUTED = "#7FA3B8"
VIOLET = "#8A6CFF"
GOLD = "#FFC93D"
DIS_FILL, DIS_LINE = "#0E2233", "#36506A"


def ch(x, y, w, h, c):
    """Polígono chanfrado (cantos cortados a 45°, c px)."""
    return (f"{x + c},{y} {x + w - c},{y} {x + w},{y + c} {x + w},{y + h - c} "
            f"{x + w - c},{y + h} {x + c},{y + h} {x},{y + h - c} {x},{y + c}")


def chamfered(x, y, w, h, c, outer, inner, inset, c_in=None, extra=""):
    """Moldura = polígono externo + polígono interno (como .panel/.fill do mockup)."""
    c_in = c - 1 if c_in is None else c_in
    return (f'<polygon points="{ch(x, y, w, h, c)}" fill="{outer}"{extra}/>'
            f'<polygon points="{ch(x + inset, y + inset, w - 2 * inset, h - 2 * inset, c_in)}" fill="{inner}"/>')


def glow_under(shape, color, std, alpha, fid):
    """Brilho pintado: cópia borrada da forma, colorida, por baixo (equivale ao drop-shadow 0 0 do CSS)."""
    return (f'<defs><filter id="{fid}" x="-50%" y="-50%" width="200%" height="200%">'
            f'<feGaussianBlur stdDeviation="{std}"/></filter></defs>'
            f'<g filter="url(#{fid})" opacity="{alpha}">{shape.replace("FILL", color)}</g>')


# ---------- painéis ----------
def brackets(w, h):  # colchetes 22x2 no canto superior esquerdo e inferior direito, a 12 px do canto
    return (f'<rect x="12" y="0" width="22" height="2" fill="{LINE}"/><rect x="0" y="12" width="2" height="22" fill="{LINE}"/>'
            f'<rect x="{w - 34}" y="{h - 2}" width="22" height="2" fill="{LINE}"/><rect x="{w - 2}" y="{h - 34}" width="2" height="22" fill="{LINE}"/>')


PANEL_SVG = chamfered(0, 0, 96, 96, 12, LINE_DIM, PANEL, 1.5, 11) + brackets(96, 96)
_g = ch(8, 8, 80, 80, 12)
PANEL_GOLD_SVG = (glow_under(f'<polygon points="{_g}" fill="FILL"/>', GOLD, 3.5, .6, "gg")
                  + chamfered(8, 8, 80, 80, 12, "rgba(255,201,61,.8)", "rgba(30,26,20,.88)", 1.5, 11))
PILL_SVG = chamfered(0, 0, 48, 32, 9, LINE_DIM, PANEL, 1.5, 8)


# ---------- botões ----------
def primary(pressed):
    y = 11 if pressed else 8
    stops = (('0', '#2FE6F2'), ('.6', '#0FA9C4'), ('1', '#0B7F97')) if pressed else (('0', '#7FF5FF'), ('.45', '#2FE6F2'), ('1', '#0FA9C4'))
    gid = "gp" if pressed else "gn"
    grad = (f'<defs><linearGradient id="{gid}" x1="0" y1="0" x2="0" y2="1">'
            + "".join(f'<stop offset="{o}" stop-color="{c}"/>' for o, c in stops) + '</linearGradient>'
            f'<clipPath id="cl{gid}"><polygon points="{ch(8, y, 80, 64, 16)}"/></clipPath></defs>')
    body = f'<polygon points="{ch(8, y, 80, 64, 16)}" fill="FILL"/>'
    glow = glow_under(body, LINE, 1.6 if pressed else 3.6, .55 if pressed else .75, "f" + gid)
    return (glow + grad + body.replace("FILL", f"url(#{gid})")
            + f'<g clip-path="url(#cl{gid})"><rect x="22" y="{y + 5}" width="52" height="2" fill="rgba(255,255,255,.75)"/>'
            f'<rect x="8" y="{y + 58}" width="80" height="6" fill="rgba(3,32,46,.35)"/></g>')


def secondary(state):
    y = 2 if state == "pressed" else 0
    outer, inner = {"normal": (LINE, "rgba(6,34,58,.9)"), "pressed": (TEXT2, "rgba(14,90,112,.95)"),
                    "disabled": (DIS_LINE, DIS_FILL)}[state]
    return chamfered(0, y, 64, 46, 10, outer, inner, 2, 9)


# ---------- barra de XP ----------
BAR_TRACK_SVG = f'<rect width="32" height="16" fill="{LINE_DIM}"/><rect x="1" y="1" width="30" height="14" fill="#071A2B"/>'
BAR_FILL_SVG = (f'<defs><linearGradient id="gf"><stop offset="0" stop-color="{VIOLET}"/><stop offset="1" stop-color="{LINE}"/></linearGradient></defs>'
                '<rect width="32" height="12" fill="url(#gf)"/>')
BAR_TIP_SVG = (glow_under('<rect x="2.5" y="4" width="3" height="12" fill="FILL"/>', LINE, 2, 1, "ft")
               + f'<rect x="2.5" y="4" width="3" height="12" fill="{TEXT}"/>')

# ---------- selo, anel e slot ----------
HEX = ('<defs><linearGradient id="gh" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3B2C9A"/><stop offset="1" stop-color="#150F4A"/></linearGradient></defs>'
       '<polygon points="26,1.5 50.5,15.5 50.5,42.5 26,56.5 1.5,42.5 1.5,15.5" fill="url(#gh)" stroke="#3FE8F5" stroke-width="2.5"/>'
       '<polygon points="26,7 45.5,18.5 45.5,39.5 26,51 6.5,39.5 6.5,18.5" fill="none" stroke="#8A6CFF" stroke-width="1.5" opacity=".9"/>')
BADGE_SVG = f'<svg x="0" y="1" width="64" height="70" viewBox="0 0 52 58" preserveAspectRatio="none">{HEX}</svg>'
RING_SVG = ('<g opacity=".85"><circle cx="48" cy="48" r="41" fill="none" stroke="#3FE8F5" stroke-width="1.5" stroke-dasharray="6 5"/>'
            '<circle cx="48" cy="48" r="35" fill="none" stroke="#8A6CFF" stroke-width="1"/></g>')
_s = ch(2, 2, 60, 60, 10)
SLOT_SVG = (glow_under(f'<polygon points="{_s}" fill="FILL"/>', LINE, 1.2, .8, "fs")
            + chamfered(2, 2, 60, 60, 10, LINE_DIM, "rgba(10,60,84,.95)", 1.5, 9))

# ---------- ícones (símbolos do mockup) ----------
XP_SVG = ('<defs><linearGradient id="gx" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#9B7CFF"/><stop offset="1" stop-color="#4A33C8"/></linearGradient></defs>'
          '<polygon points="16,2 28.5,9 28.5,23 16,30 3.5,23 3.5,9" fill="url(#gx)" stroke="#B9A5FF" stroke-width="1.6"/>'
          '<path d="M16 7 L21.5 16 L16 25 L10.5 16Z" fill="#3FE8F5"/><path d="M16 7 L16 25 L10.5 16Z" fill="#E6FFFF" opacity=".85"/>')
GEAR_SVG = ('<path d="M10.3 2h3.4l.5 2.6 1.6.7 2.2-1.5 2.4 2.4-1.5 2.2.7 1.6 2.6.5v3.4l-2.6.5-.7 1.6 1.5 2.2-2.4 2.4-2.2-1.5-1.6.7-.5 2.6h-3.4l-.5-2.6-1.6-.7-2.2 1.5-2.4-2.4 1.5-2.2-.7-1.6L2 13.7v-3.4l2.6-.5.7-1.6-1.5-2.2 2.4-2.4 2.2 1.5 1.6-.7z" fill="#9FF6FF"/>'
            '<circle cx="12" cy="12" r="3.6" fill="#06223A" stroke="#9FF6FF" stroke-width="1"/>')
LOCK_SVG = ('<svg width="32" height="32" viewBox="0 0 24 24"><path d="M7.5 11V8a4.5 4.5 0 0 1 9 0v3" fill="none" stroke="#7FA3B8" stroke-width="2.2"/>'
            '<rect x="5" y="11" width="14" height="10" rx="2" fill="#2A4258" stroke="#7FA3B8" stroke-width="1.6"/><circle cx="12" cy="16" r="1.6" fill="#7FA3B8"/></svg>')
UNLOCK_SVG = ('<svg width="32" height="32" viewBox="0 0 24 24"><path d="M7.5 11V7a4.5 4.5 0 0 1 9 0" fill="none" stroke="#3FE8F5" stroke-width="2.2"/>'
              '<rect x="5" y="11" width="14" height="10" rx="2" fill="#0B4A5E" stroke="#3FE8F5" stroke-width="1.6"/><circle cx="12" cy="16" r="1.6" fill="#E6FFFF"/></svg>')

# ---------- varredura e brilho ----------
SCAN_SVG = ('<defs><linearGradient id="gs"><stop offset="0" stop-color="#3FE8F5" stop-opacity="0"/>'
            '<stop offset=".25" stop-color="#3FE8F5" stop-opacity=".55"/><stop offset=".75" stop-color="#3FE8F5" stop-opacity=".55"/>'
            '<stop offset="1" stop-color="#3FE8F5" stop-opacity="0"/></linearGradient></defs><rect y=".5" width="128" height="1" fill="url(#gs)"/>')
GLOW_SVG = ('<defs><radialGradient id="gr"><stop offset="0" stop-color="#fff" stop-opacity=".9"/><stop offset=".3" stop-color="#fff" stop-opacity=".5"/>'
            '<stop offset=".6" stop-color="#fff" stop-opacity=".16"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></radialGradient></defs>'
            '<circle cx="32" cy="32" r="32" fill="url(#gr)"/>')

ASSETS = {  # nome: (largura 1x, altura 1x, svg interno)
    "ui_holo_panel": (96, 96, PANEL_SVG),
    "ui_holo_panel_gold": (96, 96, PANEL_GOLD_SVG),
    "ui_holo_pill": (48, 32, PILL_SVG),
    "ui_holo_btn_primary_normal": (96, 80, primary(False)),
    "ui_holo_btn_primary_pressed": (96, 80, primary(True)),
    "ui_holo_btn_secondary_normal": (64, 48, secondary("normal")),
    "ui_holo_btn_secondary_pressed": (64, 48, secondary("pressed")),
    "ui_holo_btn_secondary_disabled": (64, 48, secondary("disabled")),
    "ui_holo_bar_track": (32, 16, BAR_TRACK_SVG),
    "ui_holo_bar_fill": (32, 12, BAR_FILL_SVG),
    "ui_holo_bar_tip": (8, 20, BAR_TIP_SVG),
    "ui_holo_level_badge": (64, 72, BADGE_SVG),
    "ui_holo_level_ring": (96, 96, RING_SVG),
    "ui_holo_slot_ready": (64, 64, SLOT_SVG),
    "ui_icon_xp": (32, 32, XP_SVG),
    "ui_icon_settings": (24, 24, GEAR_SVG),
    "ui_icon_lock_holo": (32, 32, LOCK_SVG),
    "ui_icon_unlock_holo": (32, 32, UNLOCK_SVG),
    "ui_holo_scanline": (128, 2, SCAN_SVG),
    "ui_holo_glow": (64, 64, GLOW_SVG),
}


def svg(w, h, inner):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w * SCALE}" height="{h * SCALE}" '
            f'viewBox="0 0 {w} {h}">{inner}</svg>')


def render(src, png, w, h, dpr=1):
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--allow-file-access-from-files",
                    "--default-background-color=00000000", f"--force-device-scale-factor={dpr}", f"--window-size={w},{h}",
                    "--virtual-time-budget=1500", f"--screenshot={png}", src.as_uri()], check=True, capture_output=True)


def optimize(png):
    """Regrava o PNG (RGBA, compressão máxima) com o ffmpeg; mantém o alfa suave (sem paleta indexada)."""
    tmp = png.with_suffix(".tmp.png")
    r = subprocess.run([FFMPEG, "-y", "-loglevel", "error", "-i", str(png), "-pix_fmt", "rgba", "-pred", "mixed",
                        "-compression_level", "9", str(tmp)], capture_output=True)
    if r.returncode == 0 and tmp.stat().st_size < png.stat().st_size:
        tmp.replace(png)
    elif tmp.exists():
        tmp.unlink()


# ---------- folhas de validação (375x812, peças montadas como 9-patch via border-image) ----------
def nine(name, x, y, w, h, l, r, t, b, extra=""):
    """Peça 9-patch posicionada em px 1x; margens em px do PNG 2x (border-image usa px da imagem)."""
    return (f'<div style="position:absolute;left:{x}px;top:{y}px;width:{w}px;height:{h}px;box-sizing:border-box;'
            f'border-style:solid;border-width:{t / 2}px {r / 2}px {b / 2}px {l / 2}px;'
            f'border-image:url(../{name}.png) {t} {r} {b} {l} fill stretch;{extra}"></div>')


def img(name, x, y, w, h, extra=""):
    return f'<img src="../{name}.png" style="position:absolute;left:{x}px;top:{y}px;width:{w}px;height:{h}px;{extra}">'


def tint(name, x, y, w, h, color, alpha):
    """Equivale a um Sprite/TextureRect com modulate = color e material aditivo."""
    return (f'<div style="position:absolute;left:{x}px;top:{y}px;width:{w}px;height:{h}px;background:{color};opacity:{alpha};'
            f'mix-blend-mode:plus-lighter;-webkit-mask:url(../{name}.png) 0 0/100% 100%;mask:url(../{name}.png) 0 0/100% 100%"></div>')


def txt(x, y, s, extra):
    return f'<div style="position:absolute;left:{x}px;top:{y}px;{extra}">{s}</div>'


GLOW_TXT = "text-shadow:0 0 8px rgba(63,232,245,.8),0 0 2px rgba(63,232,245,.9)"
COIN_TMP = ('<svg style="position:absolute;left:{x}px;top:{y}px" width="{s}" height="{s}" viewBox="0 0 32 32"><circle cx="16" cy="17" r="13.5" fill="#9A5F0C"/>'
            '<circle cx="16" cy="15.5" r="13.5" fill="#FFC93D" stroke="#9A5F0C" stroke-width="1.5"/><path d="M16 8.5 L21 15.5 L16 22.5 L11 15.5Z" fill="#FFF6D6"/></svg>')


def menu(level, fill_w, xp, coins):
    return ('<div class="bg" style="background-image:url(../title_bg_tech.webp)"></div>'
            + nine("ui_holo_pill", 315, 53, 44, 44, 20, 20, 20, 20) + img("ui_icon_settings", 325, 63, 24, 24)
            + txt(0, 440, "PROJECT:", f"right:0;text-align:center;font-weight:700;font-size:22px;letter-spacing:4px;{GLOW_TXT}")
            + txt(0, 462, "ANIMA", f"right:0;text-align:center;font-weight:800;font-size:58px;letter-spacing:6px;line-height:1;{GLOW_TXT}")
            + img("ui_holo_level_badge", 44, 547, 52, 58.5)
            + txt(44, 558, str(level), "width:52px;text-align:center;font-weight:800;font-size:26px")
            + txt(106, 553, f"NÍVEL {level}", f"font-weight:700;font-size:13px;letter-spacing:2px;color:{TEXT2}")
            + nine("ui_holo_bar_track", 106, 572, 124, 12, 8, 8, 8, 8)
            + nine("ui_holo_bar_fill", 108, 574, fill_w, 8, 6, 6, 6, 6)
            + img("ui_holo_bar_tip", 108 + fill_w - 4, 568, 8, 20)
            + txt(106, 588, xp, f"font-size:11px;font-weight:600;letter-spacing:1px;color:{MUTED}")
            + tint("ui_holo_glow", 226, 547, 120, 60, LINE, .45)
            + nine("ui_holo_pill", 240, 558, 92, 38, 20, 20, 20, 20) + COIN_TMP.format(x=247, y=564, s=26)
            + txt(276, 566, coins, "width:50px;text-align:right;font-weight:800;font-size:18px")
            + nine("ui_holo_btn_primary_normal", 39, 628, 297, 94, 48, 48, 56, 56)
            + txt(47, 636, "JOGAR", "width:281px;height:78px;display:flex;align-items:center;justify-content:center;"
                  "font-weight:800;font-size:30px;letter-spacing:2px;color:#03202E"))


def result():
    return ('<div class="bg" style="background-image:url(../../backgrounds/result_tech_bg.webp)"></div><div class="dim"></div>'
            + txt(0, 56, "VITÓRIA", f"right:0;text-align:center;font-weight:900;font-size:48px;letter-spacing:5px;color:{GOLD};"
                  "text-shadow:0 0 10px rgba(255,201,61,.75),0 2px 0 #6A4300")
            + txt(0, 116, "ONDA 10/10 · 4:32", f"right:0;text-align:center;font-weight:600;font-size:13px;letter-spacing:3px;color:{TEXT2}")
            + nine("ui_holo_panel", 24, 152, 327, 124, 72, 72, 72, 72)
            + txt(0, 163, "RECOMPENSAS", f"right:0;text-align:center;font-weight:700;font-size:12px;letter-spacing:3px;color:{TEXT2}")
            + nine("ui_holo_scanline", 26, 187.5, 323, 1, 64, 64, 0, 0)
            + img("ui_icon_xp", 52, 200, 44, 44)
            + txt(104, 196, "+180", f"font-weight:800;font-size:32px;{GLOW_TXT}")
            + txt(106, 236, "XP", "font-size:11px;font-weight:700;letter-spacing:2px;color:#B9A5FF")
            + '<div style="position:absolute;left:187px;top:198px;width:1px;height:52px;background:rgba(63,232,245,.38)"></div>'
            + COIN_TMP.format(x=208, y=200, s=44)
            + txt(260, 196, "+95", "font-weight:800;font-size:32px;color:#FFE08A;text-shadow:0 0 8px rgba(255,201,61,.6)")
            + txt(262, 236, "MOEDA", f"font-size:11px;font-weight:700;letter-spacing:2px;color:{GOLD}")
            + nine("ui_holo_panel", 24, 292, 327, 116, 72, 72, 72, 72)
            + img("ui_holo_level_ring", 30, 302, 96, 96)
            + img("ui_holo_level_badge", 46, 315, 64, 72)
            + txt(46, 330, "3", "width:64px;text-align:center;font-weight:900;font-size:32px")
            + txt(136, 310, "NÍVEL 3!", f"font-weight:800;font-size:26px;letter-spacing:2px;{GLOW_TXT}")
            + txt(138, 342, "NÍVEL 2 → 3", f"font-size:11px;font-weight:600;letter-spacing:1px;color:{MUTED}")
            + nine("ui_holo_bar_track", 136, 362, 196, 14, 8, 8, 8, 8)
            + nine("ui_holo_bar_fill", 138, 364, 34, 10, 6, 6, 6, 6)
            + img("ui_holo_bar_tip", 138 + 34 - 4, 359, 8, 20, "transform:scaleY(1.1)")
            + "".join(f'<div style="position:absolute;left:{136 + t}px;top:364px;width:1px;height:10px;background:rgba(2,20,35,.7)"></div>' for t in (49, 98, 147))
            + txt(136, 382, "40 / 650 XP", f"font-size:11px;font-weight:600;letter-spacing:1px;color:{MUTED}")
            + nine("ui_holo_panel_gold", 16, 420, 343, 108, 72, 72, 72, 72)
            + img("ui_holo_slot_ready", 40, 442, 64, 64)
            + img("ui_icon_unlock_holo", 56, 458, 32, 32)
            + txt(118, 450, "SLOT 1 LIBERADO", f"font-weight:800;font-size:22px;letter-spacing:1px;color:{GOLD};"
                  "text-shadow:0 0 10px rgba(255,201,61,.75),0 2px 0 #6A4300")
            + txt(118, 480, "O 1º Módulo entra na próxima partida", f"width:220px;font-size:12px;font-weight:600;color:{TEXT};line-height:1.3")
            + nine("ui_holo_btn_primary_normal", 39, 632, 297, 88, 48, 48, 56, 56)
            + txt(47, 640, "CONTINUAR", "width:281px;height:72px;display:flex;align-items:center;justify-content:center;"
                  "font-weight:800;font-size:26px;letter-spacing:2px;color:#03202E")
            + nine("ui_holo_btn_secondary_normal", 77, 728, 221, 54, 24, 24, 24, 24)
            + txt(77, 728, "JOGAR DE NOVO", f"width:221px;height:52px;display:flex;align-items:center;justify-content:center;"
                  f"font-weight:800;font-size:17px;letter-spacing:2px;color:{TEXT}"))


def checks():
    font = (ROOT / "assets" / "fonts" / "Outfit-Variable.ttf").as_uri()
    head = (f'<html><head><meta charset="utf-8"><style>@font-face{{font-family:Outfit;src:url({font});font-weight:100 900}}'
            '*{margin:0;padding:0}html,body{width:375px;height:812px;overflow:hidden;position:relative;background:#021423;font-family:Outfit;color:#E6FFFF}'
            '.bg{position:absolute;left:50%;top:0;width:399px;height:714px;transform:translateX(-50%);background-size:100% 100%}'
            '.bg::after{content:"";position:absolute;left:0;right:0;bottom:0;height:160px;background:linear-gradient(rgba(2,20,35,0),#021423)}'
            '.dim{position:absolute;inset:0;background:rgba(2,20,35,.30)}</style></head><body>')
    screens = {"menu": menu(4, 74, "320 / 500 XP", "1.250"), "menu_lvl1": menu(1, 6, "0 / 100 XP", "0"), "result": result()}
    outs = []
    for n, body in screens.items():
        p = HERE / f"holo_check_{n}.html"
        p.write_text(head + body + "</body></html>", encoding="utf-8")
        for dpr in (2, 1):
            out = HERE / f"holo_check_{n}{'' if dpr == 2 else '_1x'}.png"
            render(p, out, 375, 812, dpr)
            outs.append(out)
    # comparação lado a lado: mockup aprovado x montagem com as peças (2x reduzido) + 1x
    cells = "".join(f'<div class="c"><img src="../../mockups/mockup_holo_{n}.png"><img src="holo_check_{n}.png"><img src="holo_check_{n}_1x.png"><br>'
                    f'<span>{n}: mockup | peças (2x) | peças (1x)</span></div>' for n in screens)
    p = HERE / "holo_compare.html"
    p.write_text('<html><body style="margin:0;background:#000;font:14px sans-serif;color:#9FF6FF">'
                 '<style>.c{padding:6px}img{width:375px;height:812px;margin-right:6px}</style>' + cells + "</body></html>", encoding="utf-8")
    render(p, HERE / "holo_compare.png", 1160, 2520, 1)


if __name__ == "__main__":
    import sys
    only = set(sys.argv[1:])  # opcional: gera só os nomes passados (as folhas de validação sempre são refeitas)
    for name, (w, h, inner) in ASSETS.items():
        if only and name not in only:
            continue
        sp = HERE / f"{name}.svg"
        sp.write_text(svg(w, h, inner), encoding="utf-8")
        png = UI / f"{name}.png"
        render(sp, png, w * SCALE, h * SCALE)
        optimize(png)
        print("ok", name, png.stat().st_size)
    checks()
