# EPIC-F6-02 ISSUE-F6-02-01 lifecycle de challenge com TTL e uso unico

- data/hora: 2026-02-27 17:32:00 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F6-02-01`
- fonte de verdade: `PRD/PRD-MASTER.md`, `PM/DECISION-PROTOCOL.md`, `PRD/ROADMAP.md` (`B0-03`)

## Red
- cenario A: contrato `decision` sem metadados obrigatorios de challenge (`challenge_id`, `challenge_status`, `challenge_expires_at`).
- resultado esperado: `FAIL` em `make eval-idempotency`.
- cenario B: challenge fora de TTL de 5 minutos ou com replay de uso unico.
- resultado esperado: `FAIL` em `make ci-security`.

## Green
- acao:
  - endurecer `ARC/schemas/decision.schema.json` para exigir campos de challenge no contrato;
  - estender `scripts/ci/eval_idempotency_reconciliation.sh` para validar lifecycle do challenge em payload de `decision`;
  - estender `scripts/ci/check_security.sh` com validacoes executaveis para TTL=5 minutos, maximo de 3 tentativas e invalidacao por sucesso/expiracao/rotacao/revogacao/replay.
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
- `artifacts/phase-f6/epic-f6-02-issue-01-challenge-lifecycle-ttl-single-use.md`
