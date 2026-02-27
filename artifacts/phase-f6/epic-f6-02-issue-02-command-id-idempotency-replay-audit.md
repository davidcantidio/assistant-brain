# EPIC-F6-02 ISSUE-F6-02-02 idempotencia por command_id e replay auditado

- data/hora: 2026-02-27 17:39:00 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F6-02-02`
- fonte de verdade: `PRD/PRD-MASTER.md`, `PM/DECISION-PROTOCOL.md`, `PRD/ROADMAP.md` (`B0-03`)

## Red
- cenario A: contrato `decision` sem campo de rastreio de ultimo comando (`last_command_id`).
- resultado esperado: `FAIL` em `make eval-idempotency` e `make ci-security`.
- cenario B: replay do mesmo `command_id` gerando nova transicao de estado.
- resultado esperado: `FAIL` em validacoes executaveis.

## Green
- acao:
  - endurecer `ARC/schemas/decision.schema.json` para exigir `last_command_id`;
  - reforcar `scripts/ci/eval_idempotency_reconciliation.sh` com simulacao de comando HITL idempotente (`APPLIED` -> `NO_OP_DUPLICATE_AUDITED`);
  - reforcar `scripts/ci/check_security.sh` para bloquear transicao duplicada e exigir trilha auditavel de replay.
- comandos:
  1. `make ci-security`
  2. `make eval-idempotency`
- resultado:
  - `security-check: PASS`
  - `eval-idempotency: PASS`

## Refactor
- comando: `make ci-quality`.
- resultado: `quality-check: PASS`.

## Alteracoes da issue
- `ARC/schemas/decision.schema.json`
- `scripts/ci/check_security.sh`
- `scripts/ci/eval_idempotency_reconciliation.sh`
- `PRD/CHANGELOG.md`
- `artifacts/phase-f6/epic-f6-02-issue-02-command-id-idempotency-replay-audit.md`
