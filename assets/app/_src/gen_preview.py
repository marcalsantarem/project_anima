"""Folha de contato dos ícones (BRF-071): tamanhos reais, máscaras do maskable e simulação da grade
da tela de início do iPhone (cantos arredondados) em fundos escuro e claro. Rode depois de gen_icons.py."""
import pathlib, subprocess, sys
HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent.parent / "splash" / "_src"))
from gen_splash import CHROME  # noqa: E402

A = "../"
PH = ["#E8505B", "#3D7BF2", "#F2B33D", "#2FB36B", "#9AA0AA", "#1C1C1E", "#FFFFFF", "#F06FB0", "#46C2D9", "#FF8A3D", "#5856D6"]


def grid(bg, fg, label):
    cells = []
    for i in range(12):
        if i == 5:
            img = f'<img src="{A}apple-touch-icon-180.png" style="width:60px;height:60px;border-radius:13.4px">'
            name = "Anima"
        else:
            c = PH[i % len(PH)] if i < 5 else PH[(i - 1) % len(PH)]
            img = f'<div style="width:60px;height:60px;border-radius:13.4px;background:{c};box-shadow:inset 0 0 0 1px #0002"></div>'
            name = "App"
        cells.append(f'<div class="c">{img}<span style="color:{fg}">{name}</span></div>')
    return f'<div class="ph" style="background:{bg}"><b style="color:{fg}">{label}</b><div class="g">{"".join(cells)}</div></div>'


html = f"""<!doctype html><meta charset=utf-8><style>
body{{margin:0;background:#2a2a30;font:13px -apple-system,Segoe UI,sans-serif;color:#ddd;width:1400px}}
.row{{display:flex;gap:24px;align-items:flex-end;padding:16px 24px;flex-wrap:wrap}}
figure{{margin:0;text-align:center}} figcaption{{margin-top:6px}}
.ph{{width:300px;padding:16px;border-radius:24px}} .g{{display:grid;grid-template-columns:repeat(4,1fr);gap:18px 0;margin-top:10px}}
.c{{display:flex;flex-direction:column;align-items:center;gap:4px;font-size:11px}}
.m{{position:relative;width:192px;height:192px}} .m img{{width:192px;height:192px}}
</style>
<div class=row>
<figure><img src="{A}icon-512.png" width=256 style="border-radius:57px"><figcaption>icon-512 (cantos iOS)</figcaption></figure>
<figure><img src="{A}icon-512.png" width=256><figcaption>icon-512</figcaption></figure>
<figure><img src="{A}apple-touch-icon-180.png"><figcaption>180</figcaption></figure>
<figure><img src="{A}icon-192.png"><figcaption>192</figcaption></figure>
</div><div class=row>
<figure class=m><img src="{A}icon-maskable-512.png" style="border-radius:50%"><figcaption>maskable: círculo</figcaption></figure>
<figure class=m><img src="{A}icon-maskable-512.png" style="border-radius:30%"><figcaption>maskable: squircle</figcaption></figure>
<figure class=m><img src="{A}icon-maskable-512.png" style="clip-path:inset(10% round 50%)"><figcaption>zona segura 80%</figcaption></figure>
<figure><img src="{A}favicon-48.png"><figcaption>48</figcaption></figure>
<figure><img src="{A}favicon-32.png"><figcaption>32</figcaption></figure>
<figure><img src="favicon-16.png"><figcaption>16</figcaption></figure>
<figure><img src="{A}icon-512.png" width=48 height=48 style="border-radius:11px"><figcaption>512→48</figcaption></figure>
<figure style="background:#fff;padding:8px;border-radius:8px"><img src="{A}icon-512.png" width=48 height=48 style="border-radius:11px"><figcaption style="color:#333">48 claro</figcaption></figure>
</div><div class=row>
{grid("linear-gradient(#0d1b2a,#1b263b)", "#fff", "Fundo escuro")}
{grid("linear-gradient(#f4efe6,#dfe7f2)", "#222", "Fundo claro")}
{grid("linear-gradient(#5b2a86,#d04a6b)", "#fff", "Fundo colorido")}
</div>"""
p = HERE / "preview_contact.html"
p.write_text(html, encoding="utf-8")
subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--force-device-scale-factor=1",
                "--window-size=1400,1000", f"--screenshot={HERE / 'preview_contact.png'}", p.as_uri()], check=True, capture_output=True)
print("ok preview_contact.png")
