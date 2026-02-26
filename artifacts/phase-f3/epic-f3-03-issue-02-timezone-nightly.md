# EPIC-F3-03 ISSUE-F3-03-02 Timezone and Nightly Validation

- data/hora: 2026-02-26 12:15:50 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F3-03-02` (timezone `America/Sao_Paulo` + nightly extraction as 23:00)
- fonte de verdade: `PRD/PRD-MASTER.md`

## Red-A
- cenario: alterar `ARC/ARC-HEARTBEAT.md` de `Nightly extraction de memoria: 23:00` para `22:00`.
- comando: `make eval-runtime`.
- resultado esperado: `FAIL`.
- evidencia:
  - `make: *** [eval-runtime] Error 1`

## Red-B
- cenario: alterar `workspaces/main/HEARTBEAT.md` de `23:00 (America/Sao_Paulo)` para `22:00 (America/Sao_Paulo)`.
- comando: `make eval-runtime`.
- resultado esperado: `FAIL`.
- evidencia:
  - `make: *** [eval-runtime] Error 1`

## Green
- acao: restaurar horario noturno canonico em ARC e workspace heartbeat.
- comando: `make eval-runtime`.
- resultado: `eval-runtime-contracts: PASS`.

## Refactor
- comando: `make eval-runtime` (segunda execucao).
- resultado: `eval-runtime-contracts: PASS`.

## Alteracoes da issue
- `artifacts/phase-f3/epic-f3-03-issue-02-timezone-nightly.md`
  - evidencia auditavel do ciclo TDD.
