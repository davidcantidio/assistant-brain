# EPIC-F3-01 ISSUE-F3-01-01 Required Files Runtime Gate Validation

- data/hora: 2026-02-26 11:51:14 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F3-01-01` (required files: duplicidade + faltantes agregados)
- fonte de verdade: `PRD/PRD-MASTER.md`

## Red
- cenario: ausencia temporaria de `PRD/CHANGELOG.md`.
- comando: `make eval-runtime`.
- resultado esperado: `FAIL` com indicacao explicita do arquivo ausente.
- evidencia:
  - `Arquivo obrigatorio ausente: PRD/CHANGELOG.md`
  - `make: *** [eval-runtime] Error 1`

## Green
- acao: restaurar `PRD/CHANGELOG.md`.
- comando: `make eval-runtime`.
- resultado: `eval-runtime-contracts: PASS`.

## Refactor
- comando: `make eval-runtime` (segunda execucao).
- resultado: `eval-runtime-contracts: PASS`.

## Alteracoes da issue
- `scripts/ci/eval_runtime_contracts.sh`
  - bloqueia caminhos duplicados em `required_files`.
  - agrega todos os `required_files` ausentes e falha em lote.
