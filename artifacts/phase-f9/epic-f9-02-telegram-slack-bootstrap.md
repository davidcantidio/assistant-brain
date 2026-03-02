# EPIC-F9-02 Bootstrap Telegram e Slack Socket Mode

- data/hora: 2026-03-01
- escopo: `EPIC-F9-02`
- fonte de verdade: `PRD/PRD-MASTER.md` (F9 onboarding), `PRD/ROADMAP.md` (`B0-23`, `B0-24`)

## Payload de exemplo de Telegram parseado
Exemplo usado no onboarding:
```bash
TELEGRAM_UPDATE_JSON='{"message":{"from":{"id":7165399698},"chat":{"id":7165399698,"type":"private"}}}' INTERACTIVE=1 bash scripts/onboard_linux.sh
```

Campos de preload cobertos:
- `message.from.id` -> default de `TELEGRAM_USER_ID`;
- `message.chat.id` -> default de `TELEGRAM_CHAT_ID`;
- `message.chat.type` -> derivacao de contexto de chat (private/group) para defaults auxiliares.

Comportamento de fallback:
- payload ausente/invalido nao interrompe onboarding e mantem entrada manual dos IDs.

## Checklist de importacao do manifesto Slack
1. abrir [api.slack.com/apps](https://api.slack.com/apps).
2. selecionar "Create New App" -> "From an app manifest".
3. colar `config/slack-app-manifest.socket-mode.yaml`.
4. confirmar no manifesto:
   - `socket_mode_enabled=true`;
   - comandos `/oc-approve`, `/oc-reject`, `/oc-kill`;
   - placeholders `https://example.invalid/slack/commands`, `.../events`, `.../interactivity`.
5. instalar o app no workspace e preencher `.env`:
   - `SLACK_BOT_TOKEN`;
   - `SLACK_APP_TOKEN`;
   - `SLACK_SIGNING_SECRET`.

## Evidencias de testes/gates
- `bash -n scripts/onboard_linux.sh`: `PASS`.
- validacao de preload Telegram por grep de contrato no script: `PASS`.
- validacao do manifesto Slack por grep dos campos obrigatorios: `PASS`.
- `make ci-quality`: `PASS`.
- `make ci-security`: `PASS`.
- `make eval-models`: `PASS`.

## Evidencia por issue
- `ISSUE-F9-02-01`: `artifacts/phase-f9/epic-f9-02-issue-01-telegram-json-preload.md`
- `ISSUE-F9-02-02`: `artifacts/phase-f9/epic-f9-02-issue-02-slack-socket-manifest.md`
- `ISSUE-F9-02-03`: `artifacts/phase-f9/epic-f9-02-issue-03-doc-sync-onboarding-canais.md`
