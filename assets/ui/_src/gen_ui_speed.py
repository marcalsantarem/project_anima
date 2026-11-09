"""Gera o botão de velocidade x1/x2 do HUD da partida (T-274, BRF-121) em PNG 2x, no estilo das peças ui_holo_*.
Uso: python gen_ui_speed.py   (de qualquer pasta). Desenho em unidades do mockup de 375 px; o PNG sai em 2x
(1 px do PNG ~ 1 px de tela no viewport de 720). Reaproveita os helpers do gen_ui_holo.py (não altera as peças dele).
Também gera _src/speed_check*.png e docs/img/botao-velocidade.png (prévia 375x812 sobre a arena)."""
import pathlib
from gen_ui_holo import HERE, UI, ROOT, LINE, TEXT, TEXT2, ch, glow_under, svg, render, optimize

INK = "#03202E"  # holo_ink
FONT = (ROOT / "assets" / "fonts" / "Outfit-Variable.ttf").as_uri()
W = H = 48           # canvas (unidades 1x) -> PNG 96x96
BX, BY, BW, BH, C = 7, 5, 34, 34, 8  # corpo chanfrado: 68x68 px no PNG (alvo de toque >= 64)


def chevrons(n, color, dy):
    """'>' (x1) ou '>>' (x2), traço arredondado, centrados no terço de cima do corpo."""
    cy, hh, hw = BY + 11.5 + dy, 5.5, 4.5
    xs = [24] if n == 1 else [20.5, 27.5]
    return "".join(f'<path d="M{x - hw / 2} {cy - hh} L{x + hw / 2} {cy} L{x - hw / 2} {cy + hh}" fill="none" '
                   f'stroke="{color}" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>' for x in xs)


def label(s, color, dy):
    return (f'<text x="24" y="{BY + 30 + dy}" text-anchor="middle" font-family="Outfit" font-weight="800" '
            f'font-size="12" letter-spacing=".5" fill="{color}">{s}</text>')


def speed(n, pressed):
    """n = 1 (normal: painel escuro, moldura ciano) ou 2 (ativo: ciano cheio + brilho forte, como o primário)."""
    dy = 2 if pressed else 0
    y = BY + dy
    body = f'<polygon points="{ch(BX, y, BW, BH, C)}" fill="FILL"/>'
    base = f'<polygon points="{ch(BX, BY + 3, BW, BH, C)}" fill="{"#010C16" if n == 1 else "#064A5C"}"/>'
    style = f'<style>@font-face{{font-family:Outfit;src:url({FONT});font-weight:100 900}}</style>'
    gid = f"g{n}{int(pressed)}"
    if n == 1:
        glow = glow_under(body, LINE, 1.6, .30 if pressed else .45, "f" + gid)
        outer, inner = (TEXT2, "rgba(14,90,112,.96)") if pressed else (LINE, "rgba(6,34,58,.94)")
        face = (body.replace("FILL", outer)
                + f'<polygon points="{ch(BX + 2, y + 2, BW - 4, BH - 4, C - 1)}" fill="{inner}"/>')
        content = chevrons(1, TEXT2, dy) + label("x1", TEXT, dy)
    else:
        stops = (('0', '#2FE6F2'), ('.6', '#0FA9C4'), ('1', '#0B7F97')) if pressed else \
                (('0', '#9FF8FF'), ('.45', '#2FE6F2'), ('1', '#0FA9C4'))
        glow = (glow_under(body, LINE, 2.2 if pressed else 3.4, .8 if pressed else 1, "f" + gid)
                + ("" if pressed else glow_under(body, "#FFFFFF", 1.2, .35, "w" + gid)))
        face = (f'<defs><linearGradient id="{gid}" x1="0" y1="0" x2="0" y2="1">'
                + "".join(f'<stop offset="{o}" stop-color="{c}"/>' for o, c in stops) + '</linearGradient>'
                f'<clipPath id="c{gid}"><polygon points="{ch(BX, y, BW, BH, C)}"/></clipPath></defs>'
                + body.replace("FILL", f"url(#{gid})")
                + f'<g clip-path="url(#c{gid})"><rect x="{BX + 9}" y="{y + 3}" width="{BW - 18}" height="1.5" fill="rgba(255,255,255,.8)"/></g>'
                + f'<polygon points="{ch(BX + 1, y + 1, BW - 2, BH - 2, C - 1)}" fill="none" stroke="#E6FFFF" stroke-opacity=".55" stroke-width="1"/>')
        content = chevrons(2, INK, dy) + label("x2", INK, dy)
    # a base fica sempre em BY+3: solto mostra 3 unidades (6 px), pressionado (corpo +2) mostra 1
    return style + glow + base + face + content


ASSETS = {
    "ui_speed_x1": speed(1, False),
    "ui_speed_x1_pressed": speed(1, True),
    "ui_speed_x2": speed(2, False),
    "ui_speed_x2_pressed": speed(2, True),
}


def checks():
    """Prévia 375x812: captura da partida (720x1474) reduzida a 375 de largura, ancorada embaixo; botão no HUD."""
    shot = (ROOT / "docs" / "img" / "partida.png").as_uri()
    sx = 375 / 720
    top = 812 - 1474 * sx
    head = ('<html><head><meta charset="utf-8"><style>*{margin:0;padding:0}html,body{width:375px;height:812px;overflow:hidden;'
            'position:relative;background:#F4ECDC}</style></head><body>'
            f'<img src="{shot}" style="position:absolute;left:0;top:{top}px;width:375px;height:{1474 * sx}px">')

    def btn(name, cx, cy):  # canvas 48x48 (1x 375), corpo centrado em (24, 22)
        return f'<img src="../ui_speed_{name}.png" style="position:absolute;left:{cx - 24}px;top:{cy - 22}px;width:48px;height:48px">'
    # posição sugerida: na fileira do topo, à direita da pausa (centro x ~ 84*sx..), alinhada à pausa
    pause_cy = top + 57 * sx
    pages = {
        "botao_velocidade": btn("x2", 82, pause_cy),
        "speed_check_x1": btn("x1", 82, pause_cy),
        "speed_check_tray": btn("x2", 356, top + 1392 * sx),
    }
    for n, b in pages.items():
        p = HERE / f"{n}.html"
        p.write_text(head + b + "</body></html>", encoding="utf-8")
        out = (ROOT / "docs" / "img" / "botao-velocidade.png") if n == "botao_velocidade" else HERE / f"{n}.png"
        render(p, out, 375, 812, 1)
    # folha das 4 peças em 2x e 1x sobre o chão creme e sobre o roxo do HUD
    cells = "".join(f'<div style="display:inline-block;padding:8px;background:{bg}">'
                    + "".join(f'<img src="../ui_speed_{s}.png" style="width:{w}px;height:{w}px;margin:4px">' for s in
                              ("x1", "x1_pressed", "x2", "x2_pressed"))
                    + '</div>' for bg in ("#F4ECDC", "#4B3A86") for w in (96, 48))
    p = HERE / "speed_sheet.html"
    p.write_text(f'<html><body style="margin:0;background:#222">{cells}</body></html>', encoding="utf-8")
    render(p, HERE / "speed_sheet.png", 900, 260, 1)


if __name__ == "__main__":
    for name, inner in ASSETS.items():
        sp = HERE / f"{name}.svg"
        sp.write_text(svg(W, H, inner), encoding="utf-8")
        png = UI / f"{name}.png"
        render(sp, png, W * 2, H * 2)
        optimize(png)
        print("ok", name, png.stat().st_size)
    checks()
