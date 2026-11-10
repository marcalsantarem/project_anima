"""Gera o interruptor holográfico liga/desliga (T-296, BRF-138) em PNG 228x88, no estilo das peças ui_holo_*.
Uso: python gen_ui_toggle.py   (de qualquer pasta). Desenho em unidades 1x (114x44); o PNG sai em 2x (228x88),
1 px do PNG = 1 px de tela no viewport de 720. O corpo repete o ui_holo_btn_secondary_* esticado a 228x88
(chanfro 20 px, moldura 4 px, 4 px livres embaixo; o pressionado desce 4 px), então troca sem mexer no layout.
Também gera _src/toggle_sheet.png e docs/img/interruptor-holo.png (prévia 375x812 sobre a pausa)."""
from gen_ui_holo import HERE, UI, ROOT, LINE, TEXT, TEXT2, MUTED, DIS_FILL, DIS_LINE, ch, glow_under, svg, render, optimize

OUT = "#021423"  # contorno
FONT = (ROOT / "assets" / "fonts" / "Outfit-Variable.ttf").as_uri()
W, H = 114, 44                    # canvas 1x -> PNG 228x88
BW, BH, C = 114, 42, 10           # corpo (igual ao secundário esticado)
TX, TW, TH, TC = 82, 24, 14, 5    # trilho: x 164..212 px, 48x28 px, centrado no corpo
KS = 11                           # botão deslizante 22x22 px


def toggle(state, pressed=False):
    """state: 'off' (apagado, ciano escuro), 'on' (aceso, ciano forte + brilho) ou 'disabled'."""
    dy = 2 if pressed else 0
    gid = f"{state}{int(pressed)}"
    frame, inner = {
        "off": ("#1C7F8E" if not pressed else "#2AA3B3", "rgba(5,26,44,.92)" if not pressed else "rgba(9,52,70,.95)"),
        "on": (LINE if not pressed else TEXT2, "rgba(10,62,86,.95)" if not pressed else "rgba(14,90,112,.96)"),
        "disabled": (DIS_LINE, DIS_FILL),
    }[state]
    body = (f'<polygon points="{ch(0, dy, BW, BH, C)}" fill="{OUT}"/>'
            f'<polygon points="{ch(1, dy + 1, BW - 2, BH - 2, C - .5)}" fill="{frame}"/>'
            f'<polygon points="{ch(2.5, dy + 2.5, BW - 5, BH - 5, C - 1.2)}" fill="{inner}"/>')
    glow = ""
    if state == "on":  # brilho interno (o canvas não tem folga para brilho externo, igual ao secundário)
        glow = (f'<defs><clipPath id="c{gid}"><polygon points="{ch(2.5, dy + 2.5, BW - 5, BH - 5, C - 1.2)}"/></clipPath>'
                f'<filter id="b{gid}" x="-20%" y="-50%" width="140%" height="200%"><feGaussianBlur stdDeviation="2.4"/></filter></defs>'
                f'<g clip-path="url(#c{gid})"><polygon points="{ch(2.5, dy + 2.5, BW - 5, BH - 5, C - 1.2)}" fill="none" '
                f'stroke="{LINE}" stroke-width="3" opacity="{.55 if pressed else .8}" filter="url(#b{gid})"/></g>')
    ty = dy + (BH - TH) / 2
    track = f'<polygon points="{ch(TX, ty, TW, TH, TC)}" fill="FILL"/>'
    if state == "on":
        t_out = (glow_under(track, LINE, 1.6 if pressed else 2.4, .7 if pressed else .95, "t" + gid)
                 + f'<defs><linearGradient id="g{gid}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9FF8FF"/>'
                 f'<stop offset=".5" stop-color="#2FE6F2"/><stop offset="1" stop-color="#0FA9C4"/></linearGradient></defs>'
                 + track.replace("FILL", OUT)
                 + f'<polygon points="{ch(TX + 1, ty + 1, TW - 2, TH - 2, TC - .4)}" fill="url(#g{gid})"/>')
        # marca "I" (ligado) na metade livre, à esquerda do botão
        mark = f'<rect x="{TX + 5.25}" y="{ty + 4}" width="1.5" height="6" rx=".75" fill="#03202E"/>'
        kx, k_fill, k_line = TX + TW - 1.5 - KS, TEXT, OUT
    else:
        dis = state == "disabled"
        t_out = (track.replace("FILL", OUT)
                 + f'<polygon points="{ch(TX + 1, ty + 1, TW - 2, TH - 2, TC - .4)}" fill="{DIS_LINE if dis else "#1C7F8E"}"/>'
                 + f'<polygon points="{ch(TX + 2, ty + 2, TW - 4, TH - 4, TC - .8)}" fill="{"#0A1A28" if dis else "#03131F"}"/>')
        # marca "O" (desligado) na metade livre, à direita do botão
        mark = (f'<circle cx="{TX + TW - 6.5}" cy="{ty + TH / 2}" r="2.6" fill="none" '
                f'stroke="{DIS_LINE if dis else "#2AA3B3"}" stroke-width="1.3"/>')
        kx, k_fill, k_line = TX + 1.5, ("#2A4258" if dis else MUTED), OUT
    ky = ty + (TH - KS) / 2
    knob = (f'<polygon points="{ch(kx, ky, KS, KS, 3.5)}" fill="{k_line}"/>'
            f'<polygon points="{ch(kx + 1, ky + 1, KS - 2, KS - 2, 3)}" fill="{k_fill}"/>')
    if state == "on":
        knob = glow_under(f'<polygon points="{ch(kx, ky, KS, KS, 3.5)}" fill="FILL"/>', "#FFFFFF", 1.2, .5, "k" + gid) + knob
        knob += f'<rect x="{kx + 3}" y="{ky + 2}" width="{KS - 6}" height="1" fill="#FFFFFF" opacity=".9"/>'
    elif state == "off":
        knob += f'<rect x="{kx + 3}" y="{ky + 2}" width="{KS - 6}" height="1" fill="#C9DCE8" opacity=".6"/>'
    return body + glow + t_out + mark + knob


ASSETS = {
    "ui_holo_toggle_off": toggle("off"),
    "ui_holo_toggle_off_pressed": toggle("off", True),
    "ui_holo_toggle_on": toggle("on"),
    "ui_holo_toggle_on_pressed": toggle("on", True),
    "ui_holo_toggle_disabled": toggle("disabled"),
}

S = 375 / 720  # escala da prévia
STYLE = (f'<style>@font-face{{font-family:Outfit;src:url({FONT});font-weight:100 900}}*{{margin:0;padding:0}}'
         '.t{position:absolute;font-family:Outfit;font-weight:700;line-height:1.1;display:flex;align-items:center;'
         '-webkit-text-stroke:0}</style>')


def piece(name, x, y, label, color, s=S):
    """Peça 228x88 em (x, y) css; texto na área livre (16..152 px x 0..84 px), 20 px, 2 linhas."""
    w, h = 228 * s, 88 * s
    dy = 4 * s if name.endswith("pressed") else 0
    shadow = "text-shadow:0 0 2px #021423,0 0 2px #021423,0 0 1px #021423"
    return (f'<img src="{(UI / (name + ".png")).as_uri()}" style="position:absolute;left:{x}px;top:{y}px;width:{w}px;height:{h}px">'
            f'<div class="t" style="left:{x + 16 * s}px;top:{y + dy}px;width:{136 * s}px;height:{84 * s}px;'
            f'font-size:{20 * s}px;color:{color};{shadow}">{label}</div>')


def checks():
    bg = (ROOT / "docs" / "img" / "pausa-holo-375x812.png").as_uri()
    lab = "Efeitos<br>reduzidos"
    h = ('<html><head><meta charset="utf-8">' + STYLE + '</head><body style="width:375px;height:812px;position:relative;overflow:hidden">'
         f'<img src="{bg}" style="position:absolute;left:0;top:0;width:375px;height:812px">'
         # cobre a fileira antiga e monta a nova (Efeitos reduzidos ligado, Debug desligado)
         '<div style="position:absolute;left:62px;top:494px;width:252px;height:54px;background:#0A2A40"></div>'
         + piece("ui_holo_toggle_on", 67, 499, lab, TEXT) + piece("ui_holo_toggle_off", 190, 499, "Debug", TEXT2)
         # cartela dos 5 estados
         + '<div style="position:absolute;left:14px;top:566px;width:347px;height:238px;background:rgba(2,20,35,.94);'
           'border:1.5px solid rgba(63,232,245,.5)"></div>'
         + '<div class="t" style="left:24px;top:570px;font-size:11px;color:#9FF6FF">T-296 · interruptor holográfico (228x88)</div>')
    cells = [("ui_holo_toggle_off", "desligado", TEXT2), ("ui_holo_toggle_off_pressed", "desligado · press.", TEXT2),
             ("ui_holo_toggle_on", "ligado", TEXT), ("ui_holo_toggle_on_pressed", "ligado · press.", TEXT),
             ("ui_holo_toggle_disabled", "desabilitado", "#5E7A92")]
    for i, (n, cap, col) in enumerate(cells):
        x, y = (30 + (i % 2) * 168, 592 + (i // 2) * 70)
        h += piece(n, x, y, lab, col, .64)
        h += f'<div class="t" style="left:{x}px;top:{y + 57}px;font-size:9px;color:#7FA3B8">{cap}</div>'
    p = HERE / "interruptor_holo.html"
    p.write_text(h + "</body></html>", encoding="utf-8")
    render(p, ROOT / "docs" / "img" / "interruptor-holo.png", 375, 812, 1)
    # folha 1x (tamanho real) sobre o painel da pausa e sobre o creme
    sheet = ('<html><head><meta charset="utf-8">' + STYLE + '</head><body style="margin:0;width:500px;height:520px;position:relative;background:#222">')
    for j, bgc in enumerate(("#0A2A40", "#F4ECDC")):
        sheet += f'<div style="position:absolute;left:{j * 250}px;top:0;width:250px;height:520px;background:{bgc}"></div>'
        for i, (n, _, col) in enumerate(cells):
            sheet += piece(n, j * 250 + 11, 8 + i * 102, "Efeitos<br>reduzidos", col, 1)
    p = HERE / "toggle_sheet.html"
    p.write_text(sheet + "</body></html>", encoding="utf-8")
    render(p, HERE / "toggle_sheet.png", 500, 520, 1)


if __name__ == "__main__":
    for name, inner in ASSETS.items():
        sp = HERE / f"{name}.svg"
        sp.write_text(svg(W, H, inner), encoding="utf-8")
        png = UI / f"{name}.png"
        render(sp, png, W * 2, H * 2)
        optimize(png)
        print("ok", name, png.stat().st_size)
    checks()
