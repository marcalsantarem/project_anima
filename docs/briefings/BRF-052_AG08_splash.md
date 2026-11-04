# BRF-052 — AG08 — Arte da splash de carregamento (proposta para aprovação)
**Contexto:** a tela que aparece no navegador enquanto o jogo baixa é do nosso `web/shell.html` (hoje fundo preto com "PROJECT: ANIMA" e barra ciano; o iPhone mostra "Carregando… 57%"). O dono quer trocá-la por uma splash com a nossa arte, no estilo da demo (2D cartoon casual, claro, "Jardim Arcano"; `docs/arte.md`, mockup `assets/backgrounds/mockup_cartoon_a_upgrades.png`). **Nesta etapa só a arte, para o dono aprovar**: não edite o `shell.html` (o AG02 montará depois).
**Fazer:** **2 propostas** de splash em retrato 720×1280 (mesmo tema, composições diferentes), em SVG de origem + PNG renderizado (Chrome headless; método dos mockups) em `assets/splash/` (`splash_a.*`, `splash_b.*`):
- fundo no estilo da demo (chão quadriculado creme e/ou roxo da UI, com o selo rúnico em volta), sem HUD;
- o **núcleo-Anima** (base + cristal flutuando, brilho suave) como protagonista;
- o **nome do jogo** "Project: Anima" como logotipo legível (fonte arredondada pesada Outfit 800 com contorno escuro, como o texto da UI);
- uma **barra de progresso** no estilo dos botões e barras do jogo (pílula com contorno; mostre a barra a ~60%) e o texto "Carregando… 57%" como referência de posição;
- uma versão do **logotipo + núcleo sem fundo** (PNG transparente) para reaproveitar no "toque para começar".
Considere tela alta (a splash será centralizada: o fundo deve poder esticar para cima e para baixo, 1280 a 1560 px) e leveza (alvo: tudo que aparece antes do jogo carregar ≤ 60 KB; se usar PNG, indique o peso; prefira SVG/CSS para o fundo e apenas o núcleo+logotipo como imagem). Sem ciano em nada que não seja o jogador. Nada copiado de outros jogos. Registre em `assets/LICENSES.md` com edição pontual.
**Arquivos permitidos:** `assets/splash/` (novo), `assets/LICENSES.md`, `docs/arte.md` (nota curta). Não edite `web/`, `src/` nem `project.godot`.
**Validação:** confira os PNG visualmente e informe os pesos.
**Entrega:** no máximo 8 linhas, com os caminhos dos PNG das duas propostas.
