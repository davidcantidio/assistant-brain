# EPIC-F7-02 ISSUE-F7-02-01 contrato do pre_live_checklist com campos obrigatorios e items[]

- data/hora: 2026-03-01 00:00:00 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F7-02-01`
- fonte de verdade: `VERTICALS/TRADING/TRADING-PRD.md`, `PRD/PRD-MASTER.md`, `VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md`, `scripts/ci/eval_trading.sh`

## Red
- cenario A: checklist ausente ou sem campos obrigatorios (`checklist_id`, `decision_id`, `risk_tier`, `asset_class`, `capital_ramp_level`, `operator_id`, `approved_at`, `items[]`).
- resultado esperado: `FAIL` no `make eval-trading`.
- cenario B: checklist sem itens minimos obrigatorios (`eval_trading_green`, `execution_gateway_only`, `pre_trade_validator_active`, `credentials_live_no_withdraw`, `hitl_channel_ready`, `degraded_mode_runbook_ok`, `backup_operator_enabled`, `explicit_order_approval_active`).
- resultado esperado: `FAIL` no `make eval-trading`.

## Green
- acao:
  - formalizar contrato explicito de `pre_live_checklist` em `VERTICALS/TRADING/TRADING-PRD.md` e `PRD/PRD-MASTER.md`;
  - criar artifact versionado em `artifacts/trading/pre_live_checklist/CHECKLIST-F7-02-S1-20260301-01.json`;
  - endurecer `scripts/ci/eval_trading.sh` para validar estrutura obrigatoria e itens minimos.
- comandos:
  1. `make eval-trading`
  2. `make ci-quality`
- resultado:
  - `eval-trading: PASS`
  - `quality-check: PASS`

## Refactor
- manter contrato de checklist coerente entre PRD vertical, PRD master e criteria de enablement.
- manter validacao de contrato no harness unico `eval-trading`.

## Alteracoes da issue
- `VERTICALS/TRADING/TRADING-PRD.md`
- `PRD/PRD-MASTER.md`
- `scripts/ci/eval_trading.sh`
- `artifacts/trading/pre_live_checklist/CHECKLIST-F7-02-S1-20260301-01.json`
- `artifacts/phase-f7/epic-f7-02-issue-01-pre-live-checklist-contract.md`
- `PRD/CHANGELOG.md`
