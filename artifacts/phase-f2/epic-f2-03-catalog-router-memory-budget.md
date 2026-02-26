# EPIC-F2-03 Catalog Router Memory Budget - Consolidated Validation

- data/hora: 2026-02-26 10:20:10 -0300
- host alvo: Darwin arm64
- escopo: fechamento consolidado do `EPIC-F2-03`
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/ROADMAP.md`

## Status Catalog/Router
- `ISSUE-F2-03-01` concluida com contrato minimo + sync explicito em `models_catalog`.
- `ISSUE-F2-03-02` concluida com contrato `router_decision` e trilha obrigatoria `requested/effective`.
- evidencias:
  - `artifacts/phase-f2/epic-f2-03-issue-01-model-catalog.md`
  - `artifacts/phase-f2/epic-f2-03-issue-02-model-router.md`

## Status Memory/Budget
- `ISSUE-F2-03-03` concluida com contratos executaveis de `llm_runs/router_decisions/credits_snapshots`.
- `ISSUE-F2-03-04` concluida com contrato `budget_governor_policy` (limites por run/task/day + snapshot contract).
- evidencias:
  - `artifacts/phase-f2/epic-f2-03-issue-03-memory-plane.md`
  - `artifacts/phase-f2/epic-f2-03-issue-04-budget-governor.md`

## Status A2A/Hooks
- `ISSUE-F2-03-05` concluida com contratos executaveis de eventos A2A e webhook com `trace_id`.
- validacoes bloqueiam delegacao fora de allowlist e webhook sem mapping/trace.
- evidencia:
  - `artifacts/phase-f2/epic-f2-03-issue-05-a2a-hooks-traceability.md`

## Validacao Final
1. `make eval-models` -> `PASS`
2. `make eval-runtime` -> `PASS`
3. `make eval-gates` -> `PASS`
4. `make phase-f2-gate` -> `PASS`

## Cobertura ROADMAP `B*`
- `B0-08`: model catalog baseline.
- `B0-09`: model router baseline com trilha requested/effective.
- `B0-11`: memory plane baseline (`llm_runs/router_decisions/credits_snapshots`).
- `B0-12`: ingestao de metadados minimos de run.
- `B0-13`: budget governor baseline com limites run/task/day.
- `B0-17`: contrato A2A baseline com allowlist + trace.
- `B0-18`: contrato hooks/webhooks baseline com mapping tipado + trace.
