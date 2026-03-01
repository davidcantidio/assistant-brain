# EPIC-F7-02 ISSUE-F7-02-02 guardrails de entrada em S1 (L0 + gateway-only + pre-trade-validator)

- data/hora: 2026-03-01 00:00:00 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F7-02-02`
- fonte de verdade: `VERTICALS/TRADING/TRADING-PRD.md`, `VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md`, `SEC/allowlists/ACTIONS.yaml`, `ARC/schemas/pre_trade_validator.schema.json`, `scripts/ci/eval_trading.sh`

## Red
- cenario A: `capital_ramp_level` diferente de `L0` no checklist de entrada em `S1`.
- resultado esperado: `FAIL` no `make eval-trading`.
- cenario B: `execution_gateway_only` ou `pre_trade_validator_active` com status diferente de `pass`.
- resultado esperado: `FAIL` no `make eval-trading`.

## Green
- acao:
  - fixar checklist `S1` com `capital_ramp_level=L0`;
  - ajustar `execution_gateway_only=pass` e `pre_trade_validator_active=pass` no checklist;
  - endurecer `scripts/ci/eval_trading.sh` para validar guardrails explicitos de entrada em `S1`.
- comandos:
  1. `make eval-trading`
  2. `make ci-quality`
- resultado:
  - `eval-trading: PASS`
  - `quality-check: PASS`

## Refactor
- manter guardrails de `S1` centralizados no artifact de checklist e validados por harness unico.
- manter coerencia com `SEC/allowlists/ACTIONS.yaml` e contrato versionado do `pre_trade_validator`.

## Alteracoes da issue
- `artifacts/trading/pre_live_checklist/CHECKLIST-F7-02-S1-20260301-01.json`
- `scripts/ci/eval_trading.sh`
- `artifacts/phase-f7/epic-f7-02-issue-02-s1-guardrails-l0-gateway-validator.md`
- `PRD/CHANGELOG.md`
