# ADR 0001 — Metas de desempenho e exportação Web single-threaded

- **Status:** aceita (meta do iPhone aprovada pelo dono em 2026-11-06); campo de tamanho do build pendente (T-119)
- **Data:** 2026-11-06 · **Autor:** AG07 (Arquiteto Técnico) · **Tarefa:** T-007 (BRF-095)
- **Base:** T-005, T-006, T-118; medições em `docs/perf.md`; decisão #4 em `docs/decisoes.md`

## Contexto

O jogo é web-first e o alvo mais exigente é o **Safari no iPhone**. Godot 4.7.2, GDScript, renderer Compatibility (WebGL 2). A meta inicial (Bíblia/AG07) era 60 fps no PC e ≥ 50 fps no iPhone com ~150 inimigos e ~300 projéteis, download ≤ ~15 MB. Faltava confirmar com medição e fechar a decisão #4 (exportação single-threaded, ainda "Proposta").

## Decisão

1. **Exportação Web single-threaded** (Thread Support desligado), sem SharedArrayBuffer e sem headers COOP/COEP. **Recomendação ao AG00:** passar a decisão #4 de "Proposta" para **"Decidida"**. O build roda em hosting estático (Netlify hoje) e no Safari do iOS sem configuração especial, e as medições abaixo mostram que o gargalo é a renderização, não a CPU de um único thread.
2. **Metas de desempenho (revisadas):**

| Plataforma | Cenário | Meta | Medido | Situação |
|---|---|---|---|---|
| PC, Chrome | estresse 150 inimigos / 300 projéteis | 60 fps | 59,9 médio, mín 52,1 (SwiftShader, sem GPU: vale como piso) | confirmada |
| iPhone 11 Pro, Safari, iOS 18.7 | pior caso: 150 inimigos vivos, 60 s, `?debug=1&stress=150,300` | **média ≥ 45 fps** (aprovada pelo dono em 2026-11-06) | **46,9 médio**, mín 43,2, p95 25 ms, draw 592 (build `c7c6780`) | atendida |
| Aparelhos mais novos que o iPhone 11 Pro | mesmo cenário | acima da meta do 11 Pro (esperado, não medido) | — | a medir quando houver aparelho |

   A meta anterior de ≥ 50 fps no iPhone fica **substituída** por média ≥ 45 fps no iPhone 11 Pro no pior caso.
3. **Tamanho do build:** meta **≤ ~15 MB** de download (`.wasm` + `.pck` + shell).
   - Medido (T-119): total cru ~40,4 MB, gzip ~11,9 MB, **brotli ~8,9 MB** (dentro da meta de ~15 MB); `.wasm` 37,7 MB cru (6,6 MB brotli), `.pck` 2,0 MB, `.js` 273 KB. Risco: o primeiro frame < 5 s em 4G na primeira visita fica apertado por causa do `.wasm` (~7 a 10 s só de download); opção futura: template Web customizado sem módulos não usados

### Aviso para testes no iPhone

O **Modo de Pouca Energia do iOS limita o Safari a 30 fps**. Medição feita com ele ligado é inválida (ex.: a rodada de 29,3 fps em `docs/perf.md`). Desligue-o antes de medir e anote isso no registro.

## Consequências

- **Pool de inimigos e de projéteis** obrigatório (T-118): nada de instanciar/liberar por spawn; nada de alocação por frame.
- **Barra de vida só aparece com dano** nos inimigos comuns (economia de ~1 draw call por inimigo intacto; o draw caiu de ~691 para 592).
- **Limites de efeitos e projéteis** respeitados pelo conteúdo: `CPUParticles2D` curtas, nada de partícula por projétil, busca de alvo por intervalo (0,1 s), não por frame (ver `docs/gameplay.md`, Limites de desempenho).
- **Método de medição padrão:** modo de estresse no build do jogo `?debug=1&stress=N,M` (N inimigos, M projéteis), 60 s com o aparelho parado, e **envio do log** para registro em `docs/perf.md`. Toda mudança relevante de render/conteúdo deve ser remedida assim no iPhone 11 Pro.
- O PC com SwiftShader serve só como piso e regressão; quem decide a meta é o iPhone.

## Alternativas descartadas

- **Threads (SharedArrayBuffer):** exige headers COOP/COEP no hosting, complica hosting estático, iframes de portais e SDKs de ads de terceiros, e tem suporte instável no Safari do iOS. O ganho não se aplica: o gargalo medido é desenho, não lógica.
- **C#/.NET:** o Godot 4 com .NET não exporta para Web; acabaria com o web-first.

## Riscos

- **Crescimento de nós ao longo do minuto:** no iPhone o fps começa em ~56 e cai para ~45 enquanto os nós sobem de 2914 para 3399 e o draw sobe. Investigar o que acumula (efeitos, textos de dano, projéteis) antes de adicionar conteúdo.
- **Projéteis abaixo do alvo no estresse:** o estresse pedia 300 projéteis, mas só ~68 ficaram em voo. A meta foi validada com 150 inimigos e até ~68 projéteis; o cenário de 300 projéteis simultâneos não foi medido no iPhone.
- **Aparelhos mais antigos** que o iPhone 11 Pro podem ficar abaixo de 45 fps. Sem medição; considerar um modo de qualidade reduzida (menos efeitos) se aparecerem queixas.
- **Velocidade x2 no M2:** multiplica os passos de física e de lógica por segundo; a margem atual (46,9 contra 45) não absorve isso. Remedir antes de liberar o x2 e, se preciso, reduzir custo por passo (colisão por grade espacial, `monitorable` desligado onde não precisa).
- Margem pequena em geral (~2 fps): qualquer conteúdo novo no pior caso precisa de remedição.
