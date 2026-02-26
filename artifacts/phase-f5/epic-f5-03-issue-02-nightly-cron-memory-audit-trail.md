# EPIC-F5-03 ISSUE-F5-03-02 cron proativo e memoria noturna auditavel

- data/hora: 2026-02-26 19:28:00 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F5-03-02`
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/ROADMAP.md` (`B1-R11`, `B1-R12`)

## Red
- cenario A: remover contrato de ciclo noturno ou metadata minima (`job_name`, `scheduled_at`, `executed_at`, `daily_note_ref`).
- resultado esperado: `FAIL` no `make eval-runtime`.
- cenario B: falha/atraso >24h sem `incident_ref`.
- resultado esperado: `FAIL` no `make eval-runtime`.

## Green
- acao:
  - criar `ARC/schemas/nightly_memory_cycle.schema.json` com contrato versionado e campos minimos;
  - endurecer `scripts/ci/eval_runtime_contracts.sh` para validar required/campos minimos e regra de incidente para falha/atraso >24h;
  - alinhar contrato em `PRD/PRD-MASTER.md`, `ARC/ARC-HEARTBEAT.md` e `workspaces/main/MEMORY.md`.
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
- `ARC/schemas/nightly_memory_cycle.schema.json` (novo)
- `scripts/ci/eval_runtime_contracts.sh`
- `PRD/PRD-MASTER.md`
- `ARC/ARC-HEARTBEAT.md`
- `workspaces/main/MEMORY.md`
- `PRD/CHANGELOG.md`
- `artifacts/phase-f5/epic-f5-03-issue-02-nightly-cron-memory-audit-trail.md`
