# EPIC-F5-03 ISSUE-F5-03-01 autonomia operacional para jobs longos

- data/hora: 2026-02-26 19:10:00 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F5-03-01`
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/ROADMAP.md` (`B1-R12`)

## Red
- cenario A: contrato sem `stalled_threshold_checks=2` ou sem `restart_policy`.
- resultado esperado: `FAIL` no `make eval-runtime`.
- cenario B: contrato sem `incident_on_stalled` ou sem preservacao de contexto de issue.
- resultado esperado: `FAIL` no `make eval-runtime`.

## Green
- acao:
  - criar `ARC/schemas/ops_autonomy_contract.schema.json` com contrato versionado de autonomia de jobs longos;
  - endurecer `scripts/ci/eval_runtime_contracts.sh` para validar required/campos minimos e cenarios valid/invalid;
  - explicitar contrato em `PRD/PRD-MASTER.md` e ancorar parametros operacionais em `ARC/ARC-HEARTBEAT.md`.
- comando: `make eval-runtime`.
- resultado: `eval-runtime-contracts: PASS`.

## Refactor
- comandos:
  1. `make eval-gates`
  2. `make ci-security`
- resultados:
  - `eval-gates: PASS`
  - `security-check: PASS`

## Alteracoes da issue
- `ARC/schemas/ops_autonomy_contract.schema.json` (novo)
- `scripts/ci/eval_runtime_contracts.sh`
- `PRD/PRD-MASTER.md`
- `ARC/ARC-HEARTBEAT.md`
- `PRD/CHANGELOG.md`
- `artifacts/phase-f5/epic-f5-03-issue-01-ops-autonomy-jobs-heartbeat.md`
