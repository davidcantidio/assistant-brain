# EPIC-F9-02 ISSUE-F9-02-01 preload de Telegram por JSON

- data/hora: 2026-03-01
- escopo: `ISSUE-F9-02-01`
- fonte de verdade: `PRD/PRD-MASTER.md` (secao "Onboarding de Credenciais e Canais (F9)")

## Red
- cenario sem preload: operador preenche IDs de Telegram manualmente e pode cometer erro de digitacao.

## Green
- `scripts/onboard_linux.sh` aceita preload por:
  - `TELEGRAM_UPDATE_JSON_FILE` (arquivo);
  - `TELEGRAM_UPDATE_JSON` (payload inline).
- parser extrai `message.from.id`, `message.chat.id` e `message.chat.type`.
- defaults sao aplicados nos prompts:
  - `TELEGRAM_CHAT_ID`;
  - `TELEGRAM_USER_ID`.
- payload ausente/invalido nao quebra fluxo; onboarding mantem entrada manual.

## Evidencia tecnica
- comando: `bash -n scripts/onboard_linux.sh`
- resultado: `PASS`.

- comando:
  `rg -n "TELEGRAM_UPDATE_JSON|TELEGRAM_UPDATE_JSON_FILE|message.from.id|message.chat.id|message.chat.type|TELEGRAM_CHAT_ID|TELEGRAM_USER_ID" scripts/onboard_linux.sh`
- achados relevantes:
  - `247..255`: suporte a `TELEGRAM_UPDATE_JSON_FILE` e `TELEGRAM_UPDATE_JSON`;
  - `284`: validacao explicita de `message.from.id` e `message.chat.id`;
  - `293`: fallback com aviso para payload invalido sem interromper onboarding;
  - `454..459`: prompts com defaults para `TELEGRAM_CHAT_ID` e `TELEGRAM_USER_ID`.

## Criterios de aceite atendidos
- preload por JSON inline e por arquivo implementado no onboarding;
- parse de IDs/chat type coberto no parser;
- fallback manual preservado quando payload nao e utilizavel.
