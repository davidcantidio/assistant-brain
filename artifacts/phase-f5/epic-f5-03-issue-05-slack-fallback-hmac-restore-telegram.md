# EPIC-F5-03 ISSUE-F5-03-05 fallback HITL Slack seguro + restauracao Telegram

- data/hora: 2026-02-26 20:20:00 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F5-03-05`
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/ROADMAP.md` (`B1-R18`, `B1-R19`)

## Red
- cenario A: fallback Slack sem assinatura HMAC/anti-replay/challenge.
- resultado esperado: `FAIL` em `make ci-security` e `make eval-runtime`.
- cenario B: fallback Slack acionado sem incidente/task `RESTORE_TELEGRAM_CHANNEL`.
- resultado esperado: `FAIL` em `make ci-security` e `make eval-runtime`.

## Green
- acao:
  - formalizar `RESTORE_TELEGRAM_CHANNEL` em `PM/DECISION-PROTOCOL.md`, `ARC/ARC-DEGRADED-MODE.md` e `INCIDENTS/DEGRADED-MODE-PROCEDURE.md`;
  - adicionar `restore_telegram_channel` em `SEC/allowlists/ACTIONS.yaml` com policy `decision_and_hitl_required`;
  - endurecer `scripts/ci/check_security.sh` e `scripts/ci/eval_runtime_contracts.sh` para exigir controles de fallback e restauracao.
- comandos:
  1. `make ci-security`
  2. `make eval-runtime`
- resultados:
  - `security-check: PASS`
  - `eval-runtime-contracts: PASS`

## Refactor
- comando: `make eval-gates`.
- resultado: `eval-gates: PASS`.

## Alteracoes da issue
- `scripts/ci/check_security.sh`
- `scripts/ci/eval_runtime_contracts.sh`
- `SEC/allowlists/ACTIONS.yaml`
- `PM/DECISION-PROTOCOL.md`
- `ARC/ARC-DEGRADED-MODE.md`
- `INCIDENTS/DEGRADED-MODE-PROCEDURE.md`
- `PRD/CHANGELOG.md`
- `artifacts/phase-f5/epic-f5-03-issue-05-slack-fallback-hmac-restore-telegram.md`
