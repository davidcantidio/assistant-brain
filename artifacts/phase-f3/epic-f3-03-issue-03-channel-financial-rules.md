# EPIC-F3-03 ISSUE-F3-03-03 Critical Channel and Financial Rules Validation

- data/hora: 2026-02-26 12:16:37 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F3-03-03` (canal confiavel + aprovacao humana explicita para side effect financeiro)
- fonte de verdade: `PRD/PRD-MASTER.md`

## Red-A (canal confiavel)
- cenario: substituir temporariamente termos canonicos de canal confiavel em:
  - `PRD/PRD-MASTER.md`
  - `SEC/SEC-POLICY.md`
  - `PM/DECISION-PROTOCOL.md`
- alteracoes temporarias:
  - `canal nao confiavel para comando` -> `canal nao confiavel para operacao`;
  - `nunca canal confiavel de comando` -> `nunca canal confiavel operacional`.
- comando: `make eval-runtime`.
- resultado esperado: `FAIL`.
- evidencia:
  - `make: *** [eval-runtime] Error 1`

## Red-B (aprovacao explicita)
- cenario: substituir temporariamente `aprovacao humana explicita` por `aprovacao humana obrigatoria` em:
  - `PRD/PRD-MASTER.md`
  - `SEC/SEC-POLICY.md`
  - `VERTICALS/TRADING/TRADING-PRD.md`
  - `VERTICALS/TRADING/TRADING-RISK-RULES.md`
  - `VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md`
- comando: `make eval-runtime`.
- resultado esperado: `FAIL`.
- evidencia:
  - `make: *** [eval-runtime] Error 1`

## Green
- acao: restaurar todos os documentos normativos para os termos canonicos.
- comando: `make eval-runtime`.
- resultado: `eval-runtime-contracts: PASS`.

## Refactor
- comando: `make eval-runtime` (segunda execucao).
- resultado: `eval-runtime-contracts: PASS`.

## Alteracoes da issue
- `artifacts/phase-f3/epic-f3-03-issue-03-channel-financial-rules.md`
  - evidencia auditavel do ciclo TDD.
