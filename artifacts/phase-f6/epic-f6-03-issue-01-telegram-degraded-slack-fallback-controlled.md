# EPIC-F6-03 ISSUE-F6-03-01 runbook de contingencia Telegram degradado com fallback Slack controlado

- data/hora: 2026-03-01 10:15:00 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F6-03-01`
- fonte de verdade: `PRD/PRD-MASTER.md`, `PM/DECISION-PROTOCOL.md`, `ARC/ARC-DEGRADED-MODE.md`, `INCIDENTS/DEGRADED-MODE-PROCEDURE.md`, `PRD/ROADMAP.md`

## Red
- cenario A: acionar fallback Slack sem degradacao comprovada de Telegram por > 2 heartbeats.
- resultado esperado: `FAIL` no `make ci-security`.
- cenario B: acionar fallback Slack sem controles equivalentes (`HMAC`, `anti-replay`, `challenge`).
- resultado esperado: `FAIL` no `make ci-security`.
- cenario C: acionar fallback sem incidente/task de restauracao do canal primario.
- resultado esperado: `FAIL` no `make ci-security`.

## Green
- acao:
  - reforcar `PM/DECISION-PROTOCOL.md` para explicitar:
    - fallback Slack somente apos degradacao Telegram por > 2 heartbeats;
    - exigencia de controles equivalentes (`HMAC` + `anti-replay` + `challenge`);
    - abertura obrigatoria de `RESTORE_TELEGRAM_CHANNEL` quando fallback for acionado.
  - reforcar `ARC/ARC-DEGRADED-MODE.md` e `INCIDENTS/DEGRADED-MODE-PROCEDURE.md` com o mesmo criterio de contingencia.
  - endurecer `scripts/ci/check_security.sh` para validar esses criterios nos tres documentos.
- comandos:
  1. `make ci-security`
  2. `make ci-quality`
- resultado:
  - `security-check: PASS`
  - `quality-check: PASS`

## Refactor
- consolidar linguagem equivalente de fallback em protocolo, arquitetura e procedimento de incidente.
- manter validacao executavel centralizada em `scripts/ci/check_security.sh`.

## Alteracoes da issue
- `PM/DECISION-PROTOCOL.md`
- `ARC/ARC-DEGRADED-MODE.md`
- `INCIDENTS/DEGRADED-MODE-PROCEDURE.md`
- `scripts/ci/check_security.sh`
- `PRD/CHANGELOG.md`
- `artifacts/phase-f6/epic-f6-03-issue-01-telegram-degraded-slack-fallback-controlled.md`
