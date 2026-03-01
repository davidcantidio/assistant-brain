# EPIC-F9-02 ISSUE-F9-02-02 manifesto Slack Socket Mode

- data/hora: 2026-03-01
- escopo: `ISSUE-F9-02-02`
- fonte de verdade: `PRD/PRD-MASTER.md` (secao "Onboarding de Credenciais e Canais (F9)")

## Red
- sem manifesto versionado, setup do app Slack depende de configuracao manual repetitiva e sujeita a drift.

## Green
- `config/slack-app-manifest.socket-mode.yaml` versionado no repositorio.
- Socket Mode habilitado com comandos HITL:
  - `/oc-approve`
  - `/oc-reject`
  - `/oc-kill`
- placeholders explicitos de URL mantidos para schema do Slack.
- scopes/eventos minimos declarados para funcionamento dos comandos e eventos de colaboracao.

## Evidencia tecnica
- comando:
  `rg -n "socket_mode_enabled: true|/oc-approve|/oc-reject|/oc-kill|request_url: https://example.invalid/slack/(events|interactivity)|url: https://example.invalid/slack/commands" config/slack-app-manifest.socket-mode.yaml`
- resultado relevante:
  - comandos `/oc-approve`, `/oc-reject`, `/oc-kill` presentes;
  - `socket_mode_enabled: true`;
  - placeholders `https://example.invalid/slack/commands`, `.../events`, `.../interactivity`.

- comando:
  `rg -n "scopes:|app_mentions:read|channels:history|chat:write|commands|groups:history|im:history|mpim:history|bot_events:|app_mention|message.im" config/slack-app-manifest.socket-mode.yaml`
- resultado relevante:
  - scopes bot minimos declarados;
  - eventos `app_mention` e `message.im` declarados.

## Criterios de aceite atendidos
- manifesto importavel e reproduzivel para "Create app from manifest";
- comandos HITL provisionados no manifesto versionado;
- placeholders obrigatorios do schema explicitados para uso em Socket Mode.
