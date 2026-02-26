# EPIC-F5-02 ISSUE-F5-02-01 pre_trade_validator por simbolo + contratos versionados

- data/hora: 2026-02-26 18:39:00 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F5-02-01`
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/ROADMAP.md` (`B1-05`, `B1-10`)

## Red
- cenario A: contrato de `execution_gateway` ou `pre_trade_validator` ausente/sem versionamento (`schema_version` ou `contract_version`).
- resultado esperado: `FAIL` no `make eval-trading`.
- cenario B: contrato de pre-trade sem atributos explicitos de validacao por simbolo.
- resultado esperado: `FAIL` no `make eval-trading`.

## Green
- acao:
  - criar `ARC/schemas/execution_gateway.schema.json` e `ARC/schemas/pre_trade_validator.schema.json` com versionamento e campos minimos obrigatorios;
  - endurecer `scripts/ci/eval_trading.sh` para validar presenca, JSON valido, versionamento e campos minimos dos dois contratos;
  - explicitar `symbol` e `symbol_constraints` no contrato v1 de `pre_trade_validator` em `VERTICALS/TRADING/TRADING-PRD.md`.
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
- `ARC/schemas/execution_gateway.schema.json` (novo)
- `ARC/schemas/pre_trade_validator.schema.json` (novo)
- `scripts/ci/eval_trading.sh`
- `VERTICALS/TRADING/TRADING-PRD.md`
- `PRD/CHANGELOG.md`
- `artifacts/phase-f5/epic-f5-02-issue-01-validator-contracts.md`
