"""Gera a arte do HUD holográfico da partida (T-289, BRF-125, decisão 64) e o mockup do HUD completo.
Uso: python gen_ui_hud.py   (de qualquer pasta). Desenho direto em px do viewport de 720 (1 px do PNG = 1 px de tela),
mesma escala das peças ui_holo_* e ui_speed_*. Reaproveita os helpers do gen_ui_holo.py (não altera as peças dele).
Saídas: assets/ui/ui_hud_*.png, _src/hud_sheet.png (folha de estados), docs/img/hud-holo-mockup.png (720x1280)
e docs/img/hud-holo-mockup-375x812.png."""
import subprocess
from gen_ui_holo import HERE, UI, ROOT, LINE, LINE_DIM, TEXT, TEXT2, MUTED, GOLD, DIS_FILL, DIS_LINE, ch, glow_under, render, optimize

FONT = (ROOT / "assets" / "fonts" / "Outfit-Variable.ttf").as_uri()
FFMPEG = "ffmpeg"
INK = "#03202E"
NAVY = "rgba(4,22,38,.9)"        # miolo das pílulas e botões (legível sobre a arena clara)
BASE = "#010C16"                 # base/sombra escura
TRAY = "#06182A"                 # bandeja (opaca: o Safari pinta a página com esta cor)
MAG, MAG_DARK = "#FF4F8B", "#2A0716"  # chefe: magenta-vermelho holográfico
DIS_TEXT = "#5F7A92"


def svg_px(w, h, inner):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{inner}</svg>'


def poly(x, y, w, h, c, fill, extra=""):
    return f'<polygon points="{ch(x, y, w, h, c)}" fill="{fill}"{extra}/>'


def framed(x, y, w, h, c, line, inner, t):
    return poly(x, y, w, h, c, line) + poly(x + t, y + t, w - 2 * t, h - 2 * t, max(c - t * .5, 1), inner)


# ---------- topo: pílulas ----------
def pill(bright):
    body = poly(8, 8, 96, 64, 14, "FILL")
    out = glow_under(body, LINE, 3, .5, "pw") if bright else ""
    out += framed(8, 8, 96, 64, 14, LINE if bright else LINE_DIM, NAVY, 2.5)
    if bright:  # colchetes curtos (fixos nas margens do 9-slice)
        out += f'<rect x="24" y="8" width="14" height="3" fill="{TEXT}"/><rect x="74" y="69" width="14" height="3" fill="{TEXT}"/>'
    return out


# ---------- pausa (mesma geometria do ui_speed_x1) ----------
def pause(pressed):
    dy = 4 if pressed else 0
    body = poly(14, 10 + dy, 68, 68, 16, "FILL")
    outer, inner = (TEXT2, "rgba(14,90,112,.96)") if pressed else (LINE, "rgba(6,34,58,.94)")
    bars = "".join(f'<rect x="{x}" y="{31 + dy}" width="9" height="26" rx="3" fill="{TEXT}"/>' for x in (36.5, 50.5))
    return (glow_under(body, LINE, 3.2, .30 if pressed else .45, f"gp{int(pressed)}")
            + poly(14, 16, 68, 68, 16, BASE) + framed(14, 10 + dy, 68, 68, 16, outer, inner, 4) + bars)


# ---------- barras ----------
def track(boss):
    body = poly(8, 8, 64, 40, 8, "FILL")
    if boss:
        return glow_under(body, MAG, 3, .65, "tb") + framed(8, 8, 64, 40, 8, MAG, "rgba(26,6,16,.92)", 2)
    return framed(8, 8, 64, 40, 8, LINE_DIM, "rgba(4,18,31,.92)", 2) + '<rect x="16" y="11" width="48" height="1" fill="rgba(63,232,245,.25)"/>'


def fill(stops, gid):
    """Enchimento 64x32: degradê vertical + filete claro no topo. Branco = tingir por modulate."""
    g = (f'<defs><linearGradient id="{gid}" x1="0" y1="0" x2="0" y2="1">'
         + "".join(f'<stop offset="{o}" stop-color="{c}"/>' for o, c in stops) + '</linearGradient></defs>')
    return (g + poly(0, 0, 64, 32, 6, f"url(#{gid})")
            + '<rect x="8" y="4" width="48" height="3" rx="1.5" fill="rgba(255,255,255,.75)"/>'
            + '<rect x="6" y="27" width="52" height="2" fill="rgba(0,0,0,.18)"/>')


WHITE_STOPS = (("0", "#FFFFFF"), (".5", "#E9EFF3"), ("1", "#A9B8C4"))
BOSS_STOPS = (("0", "#FF9EC0"), (".45", "#FF4F8B"), ("1", "#B3123F"))
FLASH = glow_under(f'<polygon points="{ch(9, 9, 62, 38, 7.5)}" fill="none" stroke="FILL" stroke-width="4"/>', "#FFFFFF", 3, 1, "fl") + \
    f'<polygon points="{ch(9, 9, 62, 38, 7.5)}" fill="none" stroke="#FFFFFF" stroke-width="3"/>'
TIP = glow_under('<rect x="6" y="8" width="4" height="32" rx="2" fill="FILL"/>', "#FFFFFF", 3, 1, "tp") + \
    '<rect x="6" y="8" width="4" height="32" rx="2" fill="#FFFFFF"/>'

ENERGY_ICON = (glow_under('<polygon points="28,6 48,32 28,58 8,32" fill="FILL"/>', LINE, 3, .7, "ei")
               + '<defs><linearGradient id="ge" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9FF8FF"/>'
               '<stop offset=".5" stop-color="#2FE6F2"/><stop offset="1" stop-color="#0FA9C4"/></linearGradient></defs>'
               f'<polygon points="28,6 48,32 28,58 8,32" fill="url(#ge)" stroke="{TEXT}" stroke-width="2.5" stroke-linejoin="round"/>'
               '<polygon points="28,12 28,52 13,32" fill="#FFFFFF" opacity=".45"/>'
               f'<polyline points="13,32 43,32" stroke="{INK}" stroke-opacity=".35" stroke-width="1.5"/>')
_hx = "28,14 45,24 45,42 28,52 11,42 11,24"
BOSS_ICON = (glow_under(f'<polygon points="{_hx}" fill="FILL"/><path d="M14 22 L9 6 L22 17Z M42 22 L47 6 L34 17Z" fill="FILL"/>', MAG, 3, .7, "bi")
             + f'<path d="M14 22 L9 6 L22 17Z M42 22 L47 6 L34 17Z" fill="#FFD0DF" stroke="{MAG}" stroke-width="1.5" stroke-linejoin="round"/>'
             + f'<polygon points="{_hx}" fill="{MAG_DARK}" stroke="{MAG}" stroke-width="2.5" stroke-linejoin="round"/>'
             + f'<path d="M17 29 L26 33 M39 29 L30 33" stroke="{MAG}" stroke-width="3" stroke-linecap="round"/>'
             + '<path d="M28 34 L33 40 L28 46 L23 40Z" fill="#FFFFFF"/>')

# ---------- bandeja ----------
TRAY_SVG = (glow_under('<rect x="0" y="12" width="64" height="3" fill="FILL"/>', LINE, 3.5, .9, "tr")
            + f'<rect x="0" y="12" width="64" height="68" fill="{TRAY}"/><rect x="0" y="12" width="64" height="3" fill="{LINE}"/>'
            '<rect x="0" y="19" width="64" height="1" fill="rgba(63,232,245,.14)"/>')
BAND_SVG = '<rect width="64" height="32" fill="rgba(12,46,72,.6)"/><rect y="30" width="64" height="2" fill="rgba(63,232,245,.38)"/>'

# ---------- slots de Módulo (canvas 176x184, centro (88,88), raio 72 = Ø144; base escura 6 px abaixo) ----------
C, R = 88, 72


def slot(state):
    s = f'<circle cx="{C}" cy="{C + 6}" r="{R}" fill="{BASE}"/>'
    if state == "ready":
        g = ('<defs><radialGradient id="sr" cx=".5" cy=".42" r=".6"><stop offset="0" stop-color="#14506F"/>'
             '<stop offset="1" stop-color="#051A2C"/></radialGradient></defs>')
        ticks = "".join(f'<rect x="{C - 2}" y="{C - R + 12}" width="4" height="8" rx="1" fill="{LINE}" transform="rotate({a} {C} {C})"/>' for a in (45, 135, 225, 315))
        return (glow_under(f'<circle cx="{C}" cy="{C}" r="{R}" fill="FILL"/>', LINE, 5, .7, "gr") + g + s
                + f'<circle cx="{C}" cy="{C}" r="{R}" fill="url(#sr)"/>'
                + f'<circle cx="{C}" cy="{C}" r="{R - 3}" fill="none" stroke="{LINE}" stroke-width="6"/>'
                + f'<circle cx="{C}" cy="{C}" r="{R - 12}" fill="none" stroke="{LINE_DIM}" stroke-width="1.5"/>' + ticks
                + f'<path d="M{C - 46} {C - 44} A64 64 0 0 1 {C + 46} {C - 44}" fill="none" stroke="#FFFFFF" stroke-opacity=".35" stroke-width="2" stroke-linecap="round"/>')
    if state == "cooldown":
        return (s + f'<circle cx="{C}" cy="{C}" r="{R}" fill="#041424"/>'
                + f'<circle cx="{C}" cy="{C}" r="{R - 3}" fill="none" stroke="{LINE_DIM}" stroke-width="6"/>'
                + f'<circle cx="{C}" cy="{C}" r="{R - 12}" fill="none" stroke="rgba(63,232,245,.18)" stroke-width="1.5"/>')
    if state == "locked":
        return (s + f'<circle cx="{C}" cy="{C}" r="{R}" fill="{DIS_FILL}"/>'
                + f'<circle cx="{C}" cy="{C}" r="{R - 3}" fill="none" stroke="{DIS_LINE}" stroke-width="5" stroke-dasharray="14 8"/>')
    # empty: liberado sem Módulo
    return (s + f'<circle cx="{C}" cy="{C}" r="{R}" fill="#051A2C"/>'
            + f'<circle cx="{C}" cy="{C}" r="{R - 3}" fill="none" stroke="{LINE_DIM}" stroke-width="4" stroke-dasharray="10 8"/>'
            + f'<circle cx="{C}" cy="{C}" r="{R - 12}" fill="none" stroke="rgba(63,232,245,.18)" stroke-width="1.5"/>')


RING = (glow_under(f'<circle cx="{C}" cy="{C}" r="{R - 3}" fill="none" stroke="FILL" stroke-width="6"/>', LINE, 2.5, .8, "rg")
        + f'<circle cx="{C}" cy="{C}" r="{R - 3}" fill="none" stroke="{LINE}" stroke-width="6"/>')
MASK = '<circle cx="72" cy="72" r="72" fill="rgba(2,20,35,.62)"/>'


def key_badge(on):
    line, inner = (LINE, "rgba(4,24,42,.96)") if on else (DIS_LINE, DIS_FILL)
    return framed(4, 4, 36, 36, 8, line, inner, 2)


# ---------- upgrades (canvas 144x96, corpo 128x80 em (8,8); faixa do custo = UpgradeButton.PILL) ----------
def upgrade(state):
    line, inner, strip, sline, glow = {
        "normal": (LINE, "rgba(6,34,58,.94)", "rgba(2,20,35,.92)", LINE_DIM, (LINE, .45)),
        "pressed": (TEXT2, "rgba(14,90,112,.96)", "rgba(2,20,35,.85)", TEXT2, (LINE, .3)),
        "disabled": (DIS_LINE, "rgba(14,34,51,.95)", "rgba(7,20,34,.95)", DIS_LINE, None),
        "max": (GOLD, "rgba(30,26,20,.94)", "rgba(255,201,61,.16)", GOLD, (GOLD, .5)),
    }[state]
    body = poly(8, 8, 128, 80, 14, "FILL")
    out = glow_under(body, glow[0], 3, glow[1], "gu" + state) if glow else ""
    out += framed(8, 8, 128, 80, 14, line, inner, 2.5)
    out += f'<circle cx="39" cy="36" r="24" fill="rgba(2,20,35,.85)" stroke="{sline}" stroke-width="1.5"/>'
    out += f'<polygon points="{ch(17, 60, 112, 25, 6)}" fill="{strip}" stroke="{sline}" stroke-width="1"/>'
    return out


ASSETS = {  # nome: (largura, altura, svg) em px do PNG = px de tela no viewport 720
    "ui_hud_pill_wave": (112, 80, pill(True)),
    "ui_hud_pill": (112, 80, pill(False)),
    "ui_hud_btn_pause": (96, 96, pause(False)),
    "ui_hud_btn_pause_pressed": (96, 96, pause(True)),
    "ui_hud_bar_track": (80, 56, track(False)),
    "ui_hud_bar_track_boss": (80, 56, track(True)),
    "ui_hud_bar_fill": (64, 32, fill(WHITE_STOPS, "fw")),
    "ui_hud_bar_fill_boss": (64, 32, fill(BOSS_STOPS, "fb")),
    "ui_hud_bar_flash": (80, 56, FLASH),
    "ui_hud_bar_tip": (16, 48, TIP),
    "ui_hud_icon_energy": (56, 64, ENERGY_ICON),
    "ui_hud_icon_boss": (56, 56, BOSS_ICON),
    "ui_hud_tray": (64, 80, TRAY_SVG),
    "ui_hud_tray_band": (64, 32, BAND_SVG),
    "ui_hud_skill_ready": (176, 184, slot("ready")),
    "ui_hud_skill_cooldown": (176, 184, slot("cooldown")),
    "ui_hud_skill_locked": (176, 184, slot("locked")),
    "ui_hud_skill_empty": (176, 184, slot("empty")),
    "ui_hud_skill_cooldown_ring": (176, 184, RING),
    "ui_hud_skill_cooldown_mask": (144, 144, MASK),
    "ui_hud_key_badge": (44, 44, key_badge(True)),
    "ui_hud_key_badge_off": (44, 44, key_badge(False)),
    "ui_hud_upgrade_normal": (144, 96, upgrade("normal")),
    "ui_hud_upgrade_pressed": (144, 96, upgrade("pressed")),
    "ui_hud_upgrade_disabled": (144, 96, upgrade("disabled")),
    "ui_hud_upgrade_max": (144, 96, upgrade("max")),
}

# ---------- mockup (HTML montado com as peças; 1 px CSS = 1 px do viewport 720) ----------
CORE_HIGH, CORE_MID, CORE_LOW = "#6CF0A4", "#FFC93D", "#FF5A6E"  # UiTokens.core_hp_color (inalterado)


def tinted_fill(color):
    """Simula modulate = color sobre ui_hud_bar_fill (branco): gera _src/hud_tmp_fill_<hex>.png."""
    r, g, b = (int(color[i:i + 2], 16) for i in (1, 3, 5))

    def mul(hexc):
        rr, gg, bb = (int(hexc[i:i + 2], 16) for i in (1, 3, 5))
        return f"#{rr * r // 255:02X}{gg * g // 255:02X}{bb * b // 255:02X}"
    name = f"hud_tmp_fill_{color[1:]}"
    sp = HERE / f"{name}.svg"
    sp.write_text(svg_px(64, 32, fill(tuple((o, mul(c)) for o, c in WHITE_STOPS), "t" + color[1:])), encoding="utf-8")
    render(sp, HERE / f"{name}.png", 64, 32)
    return name


def nine(src, x, y, w, h, l, r, t, b, expand=0, extra=""):
    """9-slice: margens em px do PNG (= px CSS aqui); expand = expand_margin do StyleBoxTexture."""
    return (f'<div style="position:absolute;left:{x - expand}px;top:{y - expand}px;width:{w + 2 * expand}px;height:{h + 2 * expand}px;'
            f'box-sizing:border-box;border-style:solid;border-width:{t}px {r}px {b}px {l}px;'
            f'border-image:url({src}) {t} {r} {b} {l} fill stretch;{extra}"></div>')


def img(src, x, y, w, h, extra=""):
    return f'<img src="{src}" style="position:absolute;left:{x}px;top:{y}px;width:{w}px;height:{h}px;{extra}">'


def txt(x, y, w, h, s, style):
    return (f'<div style="position:absolute;left:{x}px;top:{y}px;width:{w}px;height:{h}px;display:flex;align-items:center;'
            f'{style}">{s}</div>')


UI_ = "../"
SPR = "../../sprites/"
BG = "../../backgrounds/"
OUTL = "-webkit-text-stroke:5px #021423;paint-order:stroke fill"
GLOW = "text-shadow:0 0 10px rgba(63,232,245,.8)"


def hud_text(s, size, color=TEXT, extra=""):
    return f"font-weight:800;font-size:{size}px;color:{color};{OUTL};{extra}"


def arena(H, top, tray, boss):
    cy = (top + tray) // 2 + 30
    out = (f'<div style="position:absolute;inset:0;background:#F4ECDC url({BG}floor_tile.png) 0 0/240px 240px repeat"></div>'
           + img(BG + "floor_top_shade.png", 0, 0, 720, 220)
           + img(BG + "floor_ring.png", 120, cy - 180, 480, 360))
    for px, py in ((80, top + 120), (640, top + 120), (80, tray - 70), (640, tray - 70)):
        out += img(BG + "floor_pillar.png", px - 32, py - 96, 64, 104)
    out += img(SPR + "anima_default_base.png", 296, cy - 64, 128, 128)
    out += img(SPR + "anima_default_crystal.png", 296, cy - 174, 128, 128)
    mobs = [("enemy_runner", 64, 220, top + 200), ("enemy_runner", 64, 610, cy + 110), ("enemy_tank", 128, 470, tray - 230),
            ("enemy_swarm", 64, 600, cy - 60), ("enemy_swarm", 64, 640, cy - 20), ("enemy_shooter", 128, 150, cy + 40)]
    if boss:
        mobs.append(("boss_ogre", 256, 400, top + 270))
    for n, s, x, y in mobs:
        out += img(SPR + n + ".png", x - s // 2, y - s + s // 16, s, s)
    out += img(SPR + "projectile_player.png", 380, cy - 230, 32, 16, "transform:rotate(-70deg)")
    out += img(SPR + "projectile_enemy.png", 200, cy + 30, 32, 32)
    return out


def top_hud(wave, particles, energy, emax, boss=None, flash=False):
    frac = energy / emax
    col = CORE_HIGH if frac > .5 else CORE_MID if frac > .25 else CORE_LOW
    fill_name = tinted_fill(col)
    h_top = 216 if boss else 164
    out = f'<div style="position:absolute;left:0;top:0;width:720px;height:{h_top + 24}px;background:linear-gradient(rgba(2,20,35,.6),rgba(2,20,35,0))"></div>'
    out += img(UI_ + "ui_hud_btn_pause.png", 12, 16, 96, 96)
    out += img(UI_ + "ui_speed_x2.png", 108, 16, 96, 96)
    out += nine(UI_ + "ui_hud_pill_wave.png", 250, 28, 220, 64, 40, 40, 28, 28, 8)
    out += txt(250, 28, 220, 64, f"ONDA {wave}", hud_text("", 32, extra="justify-content:center;letter-spacing:2px;" + GLOW))
    out += nine(UI_ + "ui_hud_pill.png", 520, 28, 184, 64, 40, 40, 28, 28, 8)
    out += img(UI_ + "ui_icon_particles.png", 536, 44, 32, 32)
    out += txt(572, 28, 116, 64, particles, hud_text("", 32, extra="justify-content:flex-end"))
    # Energia (linha 2: y 120..164, barra 40)
    out += img(UI_ + "ui_hud_icon_energy.png", 10, 110, 56, 64)
    out += nine(UI_ + "ui_hud_bar_track.png", 64, 122, 640, 40, 20, 20, 20, 20, 8)
    fw = round((640 - 8) * frac)
    out += nine(fill_name + ".png", 68, 126, fw, 32, 10, 10, 10, 10)
    out += img(UI_ + "ui_hud_bar_tip.png", 68 + fw - 8, 118, 16, 48)
    if flash:
        out += (f'<div style="position:absolute;left:56px;top:114px;width:656px;height:56px;background:{CORE_LOW};opacity:.95;'
                f'-webkit-mask-box-image:url({UI_}ui_hud_bar_flash.png) 20 fill / 20px stretch"></div>')
    out += txt(64, 122, 640, 40, f"ENERGIA {energy} / {emax}".replace("1100", "1.100"), hud_text("", 24, extra="justify-content:center;letter-spacing:1px;-webkit-text-stroke:4px #021423"))
    if boss:
        hp, hmax = boss
        out += img(UI_ + "ui_hud_icon_boss.png", 12, 170, 48, 48)
        out += nine(UI_ + "ui_hud_bar_track_boss.png", 64, 182, 640, 32, 20, 20, 16, 16, 8)
        bw = round((640 - 8) * hp / hmax)
        out += nine(UI_ + "ui_hud_bar_fill_boss.png", 68, 186, bw, 24, 10, 10, 10, 10)
        out += img(UI_ + "ui_hud_bar_tip.png", 68 + bw - 8, 174, 16, 48, "transform:scaleY(.8)")
        out += txt(80, 182, 300, 32, "Boss", hud_text("", 22, extra="letter-spacing:1px;-webkit-text-stroke:4px #2A0716"))
        out += txt(380, 182, 310, 32, f"{hp:,} / {hmax:,}".replace(",", "."), hud_text("", 22, extra="justify-content:flex-end;-webkit-text-stroke:4px #2A0716"))
    return out


UPGRADES = ["atk_power", "atk_speed", "defense", "max_hp", "cooldown"]


def tray_hud(H, upgrades, slots):
    y0 = H - 266
    out = nine(UI_ + "ui_hud_tray.png", 0, y0, 720, 266, 8, 8, 24, 8, 0, "top:%dpx;height:278px" % (y0 - 12))
    out += nine(UI_ + "ui_hud_tray_band.png", 0, y0 + 4, 720, 96, 4, 4, 4, 6)
    for i, (uid, lv, cost, st) in enumerate(zip(UPGRADES, *zip(*upgrades))):
        x, y = 16 + i * 140, y0 + 10
        art = {"ok": "normal", "poor": "disabled", "max": "max", "pressed": "pressed"}[st]
        sc = "transform:scale(.94);transform-origin:72px 48px;" if st == "pressed" else ""
        out += f'<div style="position:absolute;left:{x - 8}px;top:{y - 8}px;width:144px;height:96px;{sc}">'
        out += img(UI_ + f"ui_hud_upgrade_{art}.png", 0, 0, 144, 96)
        out += img(UI_ + f"ui_icon_upgrade_{uid}.png", 19, 16, 40, 40, "opacity:.55" if st == "poor" else "")
        out += txt(62, 14, 70, 44, f"Nv {lv}", hud_text("", 26, DIS_TEXT if st == "poor" else TEXT, "justify-content:center;-webkit-text-stroke:4px #021423"))
        if st == "max":
            out += txt(17, 60, 112, 25, "MAX", hud_text("", 20, GOLD, "justify-content:center;letter-spacing:2px;-webkit-text-stroke:4px #3A2A00"))
        else:
            out += img(UI_ + "ui_icon_particles.png", 21, 62, 20, 20, "opacity:.55" if st == "poor" else "")
            out += txt(43, 60, 78, 25, str(cost), hud_text("", 20, "#FF9AA6" if st == "poor" else "#FFE08A", "justify-content:flex-end;-webkit-text-stroke:4px #021423"))
        out += "</div>"
    cy = y0 + 180
    for i, (state, extra) in enumerate(slots):
        cx = (150, 360, 570)[i]
        x, y = cx - 88, cy - 88
        art = {"ready": "ready", "cooldown": "cooldown", "locked": "locked", "empty": "empty"}[state]
        out += img(UI_ + f"ui_hud_skill_{art}.png", x, y, 176, 184)
        if state == "ready":
            out += img(UI_ + extra, cx - 44, cy - 44, 88, 88)
        elif state == "cooldown":
            icon, secs, frac = extra
            out += img(UI_ + icon, cx - 44, cy - 44, 88, 88)
            deg = 360 * frac  # fração restante
            out += (f'<div style="position:absolute;left:{cx - 72}px;top:{cy - 72}px;width:144px;height:144px;'
                    f'-webkit-mask:conic-gradient(#000 0 {deg}deg,transparent {deg}deg);background:url({UI_}ui_hud_skill_cooldown_mask.png) 0 0/144px 144px"></div>')
            el = 360 - deg
            out += (f'<div style="position:absolute;left:{x}px;top:{y}px;width:176px;height:184px;'
                    f'-webkit-mask:conic-gradient(from {deg}deg at 88px 88px,#000 0 {el}deg,transparent {el}deg);'
                    f'background:url({UI_}ui_hud_skill_cooldown_ring.png) 0 0/176px 184px"></div>')
            out += txt(cx - 72, cy - 72, 144, 144, secs, hud_text("", 56, TEXT, "justify-content:center;" + GLOW))
        elif state == "locked":
            out += img(UI_ + "ui_icon_lock_holo.png", cx - 32, cy - 52, 64, 64)
            out += txt(cx - 72, cy + 6, 144, 40, extra, hud_text("", 30, MUTED, "justify-content:center;letter-spacing:1px"))
        badge = "ui_hud_key_badge_off" if state == "locked" else "ui_hud_key_badge"
        out += img(UI_ + badge + ".png", cx + 30, cy - 82, 44, 44)
        out += txt(cx + 30, cy - 82, 44, 44, str(i + 1), hud_text("", 24, DIS_TEXT if state == "locked" else TEXT, "justify-content:center;-webkit-text-stroke:0"))
    return out


def page(W, H, body):
    return (f'<html><head><meta charset="utf-8"><style>@font-face{{font-family:Outfit;src:url({FONT});font-weight:100 900}}'
            f'*{{margin:0;padding:0}}html,body{{width:{W}px;height:{H}px;overflow:hidden;position:relative;font-family:Outfit;'
            'font-variant-numeric:tabular-nums}</style></head><body>' + body + "</body></html>")


def mockups():
    # 720x1280: chefe com barra; slot 1 pronto, 2 em recarga, 3 bloqueado; Atk power sem saldo, Cooldown no máximo
    H = 1280
    body = (arena(H, 216, H - 266, True)
            + top_hud("10/10", "7", 142, 170, boss=(992, 1100))
            + tray_hud(H, [(2, 8, "poor"), (1, 6, "ok"), (0, 4, "ok"), (1, 6, "ok"), (5, 0, "max")],
                       [("ready", "ui_icon_skill_meteor.png"), ("cooldown", ("ui_icon_skill_pulse.png", "4", .62)), ("locked", "NV 8")]))
    p = HERE / "hud_mockup_720.html"
    p.write_text(page(720, H, body), encoding="utf-8")
    render(p, ROOT / "docs" / "img" / "hud-holo-mockup.png", 720, H)
    # 375x812 (720x1559 reduzido): sem chefe, Energia baixa com flash de dano, slot 2 vazio (liberado), upgrade pressionado
    H2 = 1559
    body = (arena(H2, 164, H2 - 266, False)
            + top_hud("4/10", "382", 38, 170, flash=True)
            + tray_hud(H2, [(2, 8, "ok"), (1, 6, "pressed"), (0, 4, "ok"), (1, 6, "ok"), (0, 400, "poor")],
                       [("ready", "ui_icon_skill_meteor.png"), ("empty", None), ("locked", "NV 8")]))
    p = HERE / "hud_mockup_375.html"
    p.write_text(page(720, H2, body), encoding="utf-8")
    big = HERE / "hud_mockup_375_2x.png"
    render(p, big, 720, H2)
    subprocess.run([FFMPEG, "-y", "-loglevel", "error", "-i", str(big), "-vf", "scale=375:812:flags=lanczos",
                    str(ROOT / "docs" / "img" / "hud-holo-mockup-375x812.png")], check=True)
    big.unlink()


def sheet():
    """Folha de estados: todas as peças a 1:1, sobre o navy e sobre o chão creme."""
    cells = "".join(f'<div class="c"><img src="../{n}.png"><span>{n[7:]}<br>{w}x{h}</span></div>' for n, (w, h, _) in ASSETS.items())
    p = HERE / "hud_sheet.html"
    p.write_text(f'<html><head><meta charset="utf-8"><style>body{{margin:0;font:12px sans-serif;color:#9FF6FF}}'
                 '.r{display:flex;flex-wrap:wrap;align-items:flex-end;padding:8px}.c{margin:6px;text-align:center}.c img{display:block;margin:auto}'
                 '</style></head><body><div class="r" style="background:#021423">' + cells + '</div>'
                 f'<div class="r" style="background:#F4ECDC url(../../backgrounds/floor_tile.png) 0 0/240px;color:#03202E">{cells}</div></body></html>',
                 encoding="utf-8")
    render(p, HERE / "hud_sheet.png", 1280, 1000)


if __name__ == "__main__":
    total = 0
    for name, (w, h, inner) in ASSETS.items():
        sp = HERE / f"{name}.svg"
        sp.write_text(svg_px(w, h, inner), encoding="utf-8")
        png = UI / f"{name}.png"
        render(sp, png, w, h)
        optimize(png)
        total += png.stat().st_size
        print("ok", name, png.stat().st_size)
    print("total", total)
    mockups()
    sheet()
    for t in HERE.glob("hud_tmp_fill_*"):
        t.unlink()
