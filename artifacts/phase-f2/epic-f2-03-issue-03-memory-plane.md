# EPIC-F2-03 ISSUE-F2-03-03 Memory Plane and Run Metadata Validation

- data/hora: 2026-02-26 10:14:48 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F2-03-03` (entidades baseline de memoria + metadados minimos de run)
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/ROADMAP.md`, `ARC/ARC-CORE.md`

## Red
- cenario: payload `llm_run` sem `effective_model` deve falhar.
- cenario: payload `router_decision` sem `requested_model` deve falhar.
- cenario: payload `credits_snapshot` sem `burn_rate_day` deve falhar.
- validacao executavel: `scripts/ci/eval_runtime_contracts.sh` (fixtures invalidas inline em Python).
- resultado: entidades incompletas bloqueadas.

## Green
- acao: adicao de contratos executaveis:
  - `ARC/schemas/llm_run.schema.json`
  - `ARC/schemas/credits_snapshot.schema.json`
  - integracao com `ARC/schemas/router_decision.schema.json`
- acao: `ARC/ARC-CORE.md` atualizado para apontar schemas executaveis de `llm_runs/router_decisions/credits_snapshots`.
- comando: `make eval-runtime`
- resultado: `eval-runtime-contracts: PASS`.

## Refactor
- comando: `make phase-f2-gate`
- resultado:
  - `quality-check: PASS`
  - `security-check: PASS`
  - `eval-gates: PASS`
  - `phase-f2-gate: PASS`

## Rastreabilidade
- Roadmap: `B0-11`, `B0-12`.
- Source refs:
  - `felixcraft.md` (audit trail e observabilidade de runs).
  - `felix-openclaw-pontos-relevantes.md` (memoria em camadas e consolidacao operacional).
