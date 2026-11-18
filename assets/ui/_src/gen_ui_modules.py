"""Ícones dos Módulos novos (T-214, BRF-164): congelamento, escudo, choque. Mesmo estilo/tamanho do meteoro (64 1x, PNG 128).
Uso: python gen_ui_modules.py. Importa helpers do gen_ui.py. Saídas: ui_icon_skill_freeze/shield/shock.png,
_src/modulos_icones_sheet.png e docs/img/modulos-icones.png (folha de contato 375 px, 64 px, fundo do HUD).
Sem variante bloqueada: pulse/meteor também não têm (a moldura ui_skill_frame_locked cobre o estado)."""
import pathlib
from gen_ui import HERE, UI, SCALE, INK, svg, render, at
ROOT = UI.parents[1]
try:
    from gen_ui_holo import optimize
except Exception:
    optimize = lambda p: None

# Freeze: aglomerado de cristais de gelo (3 estilhaços angulosos), ciano-gelo
def _shard(pts, light, mid):
    return (f'<polygon points="{pts}" fill="{mid}" stroke="{INK}" stroke-width="3" stroke-linejoin="round"/>')
G_FREEZE = ('<circle r="27" fill="#7FE8FF" opacity="0.3"/>'
    + '<g transform="rotate(-38)">' + _shard("-6,-6 0,-26 6,-6 6,12 0,18 -6,12", "", "#BDF4FF") + '</g>'
    + '<g transform="rotate(38)">' + _shard("-6,-6 0,-26 6,-6 6,12 0,18 -6,12", "", "#8FDDF5") + '</g>'
    + _shard("-8,-8 0,-30 8,-8 8,16 0,24 -8,16", "", "#DDFBFF")
    + '<polygon points="0,-30 8,-8 0,-8" fill="#FFFFFF"/><polygon points="0,24 8,16 8,-8 0,-8" fill="#6FCBEA" opacity="0.55"/>'
    + '<path d="M0 -26 L0 20" stroke="#4AA8CF" stroke-width="1.6" opacity="0.7"/>'
    + '<circle cx="-3.5" cy="-12" r="2.2" fill="#FFFFFF"/>')

# Shield: domo (meia cúpula) com favos hexagonais, azul-energia
_dome = "M-24 14 A24 24 0 0 1 24 14 Z"
_hex = lambda x, y, r=6.2: ('<polygon points="' + " ".join(f"{x + r * c:.1f},{y + r * s:.1f}" for c, s in
         [(0.866, 0.5), (0, 1), (-0.866, 0.5), (-0.866, -0.5), (0, -1), (0.866, -0.5)]) + '"/>')
G_SHIELD_M = ('<circle r="27" fill="#4A8CF5" opacity="0.3"/>'
    + f'<defs><clipPath id="dm"><path d="{_dome}"/></clipPath></defs>'
    + f'<path d="{_dome}" fill="#3E7BEA"/>'
    + '<g clip-path="url(#dm)"><ellipse cx="0" cy="-2" rx="20" ry="18" fill="#7FB4FF"/><ellipse cx="8" cy="12" rx="26" ry="14" fill="#2A56C4" opacity="0.6"/>'
    + '<g fill="none" stroke="#E6F0FF" stroke-width="2" stroke-linejoin="round" opacity="0.95">'
    + _hex(0, -4) + _hex(-10.7, -10) + _hex(10.7, -10) + _hex(-10.7, 2.5) + _hex(10.7, 2.5) + _hex(0, 8.5) + '</g></g>'
    + f'<path d="{_dome}" fill="none" stroke="{INK}" stroke-width="3" stroke-linejoin="round"/>'
    + f'<rect x="-27" y="12" width="54" height="7" rx="3.5" fill="#CFE3FF" stroke="{INK}" stroke-width="3"/>'
    + '<path d="M-16 -8 A19 19 0 0 1 -6 -17" fill="none" stroke="#FFFFFF" stroke-width="3" stroke-linecap="round"/>')

# Shock: raio em zigue-zague saltando entre dois nós, amarelo-elétrico com nós violeta
_bolt = "M-4 -26 L-14 2 L-3 2 L-9 26 L14 -6 L3 -6 L10 -26 Z"
G_SHOCK = ('<circle r="27" fill="#B070FF" opacity="0.32"/>'
    + '<path d="M-22 -14 L-9 -4 L-16 4 M22 14 L9 4 L16 -4" fill="none" stroke="#B070FF" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>'
    + f'<circle cx="-23" cy="-15" r="5.5" fill="#8A4DE8" stroke="{INK}" stroke-width="2.5"/><circle cx="23" cy="15" r="5.5" fill="#8A4DE8" stroke="{INK}" stroke-width="2.5"/>'
    + f'<path d="{_bolt}" fill="#FFE84A" stroke="{INK}" stroke-width="3" stroke-linejoin="round"/>'
    + '<path d="M-3 -21 L-10 1 L-1 1 L-6 17 L7 -2" fill="none" stroke="#FFFBC8" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/>')

ICONS = {"ui_icon_skill_freeze": G_FREEZE, "ui_icon_skill_shield": G_SHIELD_M, "ui_icon_skill_shock": G_SHOCK}
REF = ["ui_icon_skill_meteor", "ui_icon_skill_pulse"]

def build():
    for n, g in ICONS.items():
        sp = HERE / f"{n}.svg"
        sp.write_text(svg(64, 64, at(32, 32, 1.0, g)), encoding="utf-8")
        render(sp, UI / f"{n}.png", 64 * SCALE, 64 * SCALE)
        optimize(UI / f"{n}.png")

def sheet():
    names = list(ICONS) + REF
    def row(bg, s):
        return ('<div style="display:flex;justify-content:space-around;padding:10px 4px;background:' + bg + '">'
                + "".join(f'<img src="{(UI / (n + ".png")).as_uri()}" style="width:{s}px;height:{s}px">' for n in names) + '</div>')
    html = ('<html><body style="margin:0;width:375px;background:#021423">' + row("#021423", 64) + row("#06182A", 64)
            + row("#021423", 40) + row("repeating-conic-gradient(#F6E9CF 0 25%,#EEDDBD 0 50%) 0 0/48px 48px", 64) + '</body></html>')
    hp = HERE / "modulos_icones_sheet.html"
    hp.write_text(html, encoding="utf-8")
    for p in (HERE / "modulos_icones_sheet.png", ROOT / "docs" / "img" / "modulos-icones.png"):
        render(hp, p, 375, 330)

if __name__ == "__main__":
    build(); sheet()
    for n in ICONS: print(n, (UI / f"{n}.png").stat().st_size)
