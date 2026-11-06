# ADR 0002 — Save local atrás da interface `Backend`

**Estado:** aceita (T-185, BRF-107). **Contexto:** o provedor online ainda é [A definir]; o protótipo precisa de progresso persistente.

## Decisão
- O jogo só conhece o autoload `Backend` (`src/backend/backend.gd`), que delega a um `BackendProvider`. A 1ª implementação é `LocalBackend`; Firebase/Nakama entram trocando `Backend.provider`, sem mudar quem chama.
- API: `has_save()`, `load_profile()`, `save_profile(p)`, `reset_profile()`; sinais `profile_loaded`, `profile_saved`, `profile_reset`, `backend_error(code, msg)`, `recovered_from_backup`. Hoje síncrona; o contrato de sinais permite provedores assíncronos depois.
- Modelo: `PlayerProfile` (`src/meta/player_profile.gd`): `level`, `xp`, `coins`, `settings` (`sound_on`, `music_volume`, `sfx_volume`) e `extra` (chaves desconhecidas são preservadas; é onde entram Módulos, Componentes e Núcleos, sempre opcionais com padrão).

## Formato
`user://save.json` = `{"version": 1, "profile": {...}}`. `MAX_LEVEL` = 100 é provisório (teto real: T-186).

## Migração
`_migrate` leva o arquivo até `SCHEMA_VERSION`, em cadeia (`if ver == N: ...; ver = N+1`). v0 (sem `version`, perfil solto na raiz) -> v1. Versão futura (maior que a do jogo) é tratada como inválida, para um jogo antigo não sobrescrever dados novos sem aviso (cai no `.bak`/perfil novo).

## Escrita e recuperação
1. Grava `save.json.tmp` (com `flush`). 2. Se o `save.json` atual é válido, copia para `save.json.bak`. 3. Renomeia `.tmp` -> `save.json`. Falha antes do rename deixa o save anterior intacto.
Na leitura, JSON inválido, tipos errados ou valores fora de faixa (nível < 1 ou > máximo, negativos, volume fora de 0..1) contam como corrompido: tenta o `.bak`; sem `.bak`, devolve perfil novo (nunca trava), emitindo `backend_error(&"corrupt_save")`. `save_profile` sanitiza (clamp) antes de gravar.

## Web
`user://` vira IndexedDB e o Godot sincroniza ao fechar o arquivo. Checar no iPhone/Safari: (a) salvar, recarregar a aba e fechar/reabrir o Safari; (b) **modo privado**: o IndexedDB pode falhar ou ser apagado ao fechar; esperado `write_failed` sem travar; (c) **PWA instalado**: o armazenamento é separado do Safari (não compartilha o save) e o iOS pode limpar dados de sites sem uso por ~7 dias; (d) fechar a aba logo após salvar (salvar em marcos, não só ao sair).

## Limites
O save do cliente web é **manipulável** e **não autoritativo**. Moeda, XP e fusão com autoridade no servidor são do marco de backend; este save é só cache/progresso local do protótipo.
