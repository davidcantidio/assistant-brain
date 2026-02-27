# EPIC-F6-02 ISSUE-F6-02-03 bloqueio por autenticacao/canal invalido com incidente

- data/hora: 2026-02-27 17:46:00 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F6-02-03`
- fonte de verdade: `PRD/PRD-MASTER.md`, `PM/DECISION-PROTOCOL.md`, `SEC/SEC-POLICY.md`, `PRD/ROADMAP.md` (`B0-03`)

## Red
- cenario A: payload `decision` sem trilha minima de autenticacao/canal (`auth_method`, `approver_*`).
- resultado esperado: `FAIL` em `make eval-idempotency` e `make ci-security`.
- cenario B: comando HITL com autenticacao/canal invalido sem bloqueio/incidente.
- resultado esperado: `FAIL` em validacoes executaveis.

## Green
- acao:
  - endurecer `ARC/schemas/decision.schema.json` com campos obrigatorios de auditoria de autenticacao/canal;
  - reforcar `scripts/ci/eval_idempotency_reconciliation.sh` com cenarios invalidos de coerencia canal/auth e bloqueio por autenticacao/canal invalido;
  - reforcar `scripts/ci/check_security.sh` para exigir bloqueio com incidente `SECURITY_VIOLATION_REVIEW` e hash de payload.
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
- `artifacts/phase-f6/epic-f6-02-issue-03-auth-channel-block-security-incident.md`
