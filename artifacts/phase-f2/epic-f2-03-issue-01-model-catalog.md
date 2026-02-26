# EPIC-F2-03 ISSUE-F2-03-01 Model Catalog Baseline Validation

- data/hora: 2026-02-26 10:09:50 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F2-03-01` (catalog sync + metadados minimos obrigatorios)
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/ROADMAP.md`, `ARC/ARC-MODEL-ROUTING.md`

## Red
- cenario: payload sem `provider` deve falhar.
- cenario: payload sem metadata de sync (`catalog_synced_at`) deve falhar.
- cenario: payload sem `model_id` deve falhar.
- validacao executavel: `scripts/ci/eval_models.sh` (fixtures invalidas inline em Python).
- resultado: cenarios invalidos bloqueados.

## Green
- acao: schema `models_catalog` atualizado com contrato minimo (`model_id/provider/capabilities/limits/pricing/status`) e metadata explicita de sync (`catalog_synced_at`, `sync_source`, `sync_interval_seconds`).
- acao: `ARC/ARC-MODEL-ROUTING.md` atualizado com regra explicita de contrato minimo + sync.
- comando: `make eval-models`
- resultado: `eval-models: PASS`.

## Refactor
- comando: `make phase-f2-gate`
- resultado:
  - `quality-check: PASS`
  - `security-check: PASS`
  - `eval-gates: PASS`
  - `phase-f2-gate: PASS`

## Rastreabilidade
- Roadmap: `B0-08`.
- Source refs:
  - `felixcraft.md` (Model Catalog / model aliases / metadata viva).
  - `felix-openclaw-pontos-relevantes.md` (baseline operacional com trilha auditavel).
