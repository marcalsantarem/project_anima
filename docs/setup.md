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
