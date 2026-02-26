# EPIC-F3-03 ISSUE-F3-03-01 Heartbeat Baseline Validation

- data/hora: 2026-02-26 12:15:20 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F3-03-01` (baseline oficial de 15 minutos)
- fonte de verdade: `PRD/PRD-MASTER.md`

## Red-A
- cenario: alterar `ARC/ARC-HEARTBEAT.md` de `base global: 15 minutos.` para `base global: 10 minutos.`.
- comando: `make eval-runtime`.
- resultado esperado: `FAIL`.
- evidencia:
  - `make: *** [eval-runtime] Error 1`

## Red-B
- cenario: alterar `workspaces/main/HEARTBEAT.md` de `Baseline oficial: 15 minutos.` para `Baseline oficial: 10 minutos.`.
- comando: `make eval-runtime`.
- resultado esperado: `FAIL`.
- evidencia:
  - `make: *** [eval-runtime] Error 1`

## Green
- acao: restaurar documentos canonicos de heartbeat.
- comando: `make eval-runtime`.
- resultado: `eval-runtime-contracts: PASS`.

## Refactor
- comando: `make eval-runtime` (segunda execucao).
- resultado: `eval-runtime-contracts: PASS`.

## Ajuste de contingencia aplicado
- problema identificado: o gate aceitava baseline no ARC por regex alternativa (`baseline unico` OU `base global`), permitindo falso positivo quando apenas `base global` era alterado.
- acao: endurecer `scripts/ci/eval_runtime_contracts.sh` para exigir as duas evidencias no ARC:
  - `baseline unico de 15 minutos`;
  - `base global: 15 minutos`.

## Alteracoes da issue
- `scripts/ci/eval_runtime_contracts.sh`
  - baseline do ARC passou de check alternativo para dois checks obrigatorios.
- `artifacts/phase-f3/epic-f3-03-issue-01-heartbeat-baseline.md`
  - evidencia auditavel do ciclo TDD.
