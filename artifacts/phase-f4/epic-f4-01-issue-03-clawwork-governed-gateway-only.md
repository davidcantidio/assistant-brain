# EPIC-F4-01 ISSUE-F4-01-03 ClawWork Governed Gateway-Only Validation

- data/hora: 2026-02-26 15:13:43 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F4-01-03` (regra mandataria ClawWork `lab_isolated` + `governed` gateway-only)
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/ROADMAP.md` (`B1-23`)

## Red
- cenario A: ambiguar regra de default `lab_isolated`.
- cenario B: ambiguar regra `governed` via gateway-only.
- cenario C: remover bloqueio explicito de chamada direta externa no modo `governed`.
- comando em todos os cenarios: `make eval-integrations`.
- resultado observado em todos os cenarios: `FAIL` (`make: *** [eval-integrations] Error 1`).

## Green
- acao: restaurar integralmente as regras mandatarias no `INTEGRATIONS/CLAWWORK.md`.
- comando: `make eval-integrations`.
- resultado: `eval-integrations: PASS`.

## Refactor
- comando: `make eval-integrations` (segunda execucao para estabilidade).
- resultado: `eval-integrations: PASS`.

## Alteracoes da issue
- `artifacts/phase-f4/epic-f4-01-issue-03-clawwork-governed-gateway-only.md`
  - evidencia auditavel do ciclo TDD da issue.
