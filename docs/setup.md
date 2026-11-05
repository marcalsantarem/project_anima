# Ambiente de desenvolvimento (Windows)

## Obrigatório agora

- **Godot 4.7.2** padrão (não .NET) ✅ instalado em `C:\Program Files\Godot`.
- **Export templates 4.7.2 (Web)** ✅ instalados. Para reinstalar: *Editor → Gerenciar Modelos de Exportação → Baixar e Instalar* (pacote único com todas as plataformas). O editor desta máquina está em pt-BR.
- **Git**.

## Recomendado

- **VS Code** com a extensão **godot-tools**.
- **Framework de testes** (GUT ou gdUnit4, a definir), instalado pela AssetLib do Godot em `addons/`.

## Quando o backend for escolhido

- **Firebase:**
  - Node.js LTS.
  - Firebase CLI: `npm install -g firebase-tools`.
  - JDK 21 (para os emuladores).
  - Um projeto no Firebase. As Cloud Functions exigem o plano Blaze.
- **Nakama:**
  - Docker Desktop, para rodar o servidor localmente, ou uma conta na versão gerenciada.

## Para depois

- Ferramentas de arte, se houver produção própria: Aseprite, Krita ou Blender.

## Testes no iPhone

A inspeção remota do Safari exige um Mac. No Windows, os testes são feitos por **link de preview**, com logs exibidos dentro da própria página (overlay de debug).

## Deploy (Netlify via GitHub Actions)

- Produção (`main`): https://projectanimagame.netlify.app
- Desenvolvimento (`dev`): https://dev--projectanimagame.netlify.app
- O build roda no GitHub Actions, e o Netlify não está ligado ao Git. Os secrets de repositório são `NETLIFY_SITE_ID` e `NETLIFY_AUTH_TOKEN`.
- Export local completo (T-175): `godot --headless --path . --export-release "Web" build/web/index.html && bash web/copy_pwa.sh build/web` (copia `web/pwa/`: manifesto e ícones). Ícones novos do AG08 em `assets/app/`: `bash web/copy_pwa.sh --sync-icons`.
- Versão/build (T-165): o deploy injeta SHA, branch, data e execução com `bash web/inject_build.sh build/web`. Para simular localmente: `GITHUB_SHA=abc1234def... GITHUB_REF_NAME=dev GITHUB_RUN_NUMBER=42 bash web/inject_build.sh build/web`. Sem essas variáveis, o jogo mostra "dev local" (`docs/debug.md` §7).
- App na tela de início do iPhone: depois de mudar ícone ou manifesto, remova o atalho antigo e adicione de novo pelo Safari (Compartilhar › Adicionar à Tela de Início); detalhes em `docs/ui.md` §12.
