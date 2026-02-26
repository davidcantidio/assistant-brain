# EPIC-F5-02 ISSUE-F5-02-02 Idempotencia client_order_id + reconciliacao de falha parcial

- data/hora: 2026-02-26 18:41:42 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F5-02-02`
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/ROADMAP.md` (`B1-06`)

## Red
- cenario A: replay de `client_order_id` tratado como nova ordem.
- resultado esperado: `FAIL` no `make eval-trading`.
- cenario B: falha parcial sem regra explicita de reconciliacao para estado final consistente.
- resultado esperado: `FAIL` no `make eval-trading`.

## Green
- acao:
  - estender `ARC/schemas/execution_gateway.schema.json` para exigir `client_order_id` e metadados de replay/reconciliacao;
  - endurecer `scripts/ci/eval_trading.sh` para validar `client_order_id` obrigatorio e regras textuais de replay no-op + reconciliacao consistente;
  - explicitar essas regras em `VERTICALS/TRADING/TRADING-PRD.md` e `VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md`.
- comando: `make eval-trading`.
- resultado: `eval-trading: PASS`.

## Refactor
- comandos:
  1. `make eval-integrations`
  2. `make ci-quality`
- resultados:
  - `eval-integrations: PASS`
  - `quality-check: PASS`

## Alteracoes da issue
- `ARC/schemas/execution_gateway.schema.json`
- `scripts/ci/eval_trading.sh`
- `VERTICALS/TRADING/TRADING-PRD.md`
- `VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md`
- `PRD/CHANGELOG.md`
- `artifacts/phase-f5/epic-f5-02-issue-02-idempotency-reconciliation.md`
