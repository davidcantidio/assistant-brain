# EPIC-F8-04 ISSUE-F8-04-02 validator profiles e evals por classe

- data/hora: 2026-03-01 10:47:14 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F8-04-02`
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/ROADMAP.md`, `VERTICALS/TRADING/TRADING-PRD.md`, `VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md`, `VERTICALS/TRADING/TRADING-RISK-RULES.md`, `PM/DECISION-PROTOCOL.md`

## Red
- cenario A: classe sem `calendar_rules`.
- resultado esperado: `FAIL` em `eval-trading-<asset_class>`.
- cenario B: classe sem `lot_size`, `tick_size` ou `min_notional`.
- resultado esperado: `FAIL` em `eval-trading-<asset_class>`.
- cenario C: classe com `cost_rules` incompleto.
- resultado esperado: `FAIL` em `eval-trading-<asset_class>`.
- cenario D: `fixed_income_br` sem validacao explicita de `max_loss_per_unit_brl`.
- resultado esperado: `FAIL` em `eval-trading-fixed_income_br`.
- cenario E: `market_state` em estado bloqueante (`closed`, `auction`, `halt`).
- resultado esperado: `FAIL` em `eval-trading-<asset_class>`.

## Green
- acao:
  - criar `ARC/schemas/asset_class_validator.schema.json`;
  - publicar `VERTICALS/TRADING/validator_profiles/` para `equities_br`, `fii_br` e `fixed_income_br`;
  - publicar fixtures positivas e negativas em `scripts/ci/fixtures/trading/multiasset/`;
  - adicionar `scripts/ci/eval_trading_asset_class.sh`;
  - adicionar `eval-trading-equities_br`, `eval-trading-fii_br`, `eval-trading-fixed_income_br` e `eval-trading-multiasset` no `Makefile`;
  - atualizar `ci-trading.yml`, `DEV/DEV-CI-RULES.md` e os docs normativos de Trading para apontar `validator_profiles` e as suites por classe.
- comandos:
  1. `make eval-trading-equities_br`
  2. `make eval-trading-fii_br`
  3. `make eval-trading-fixed_income_br`
  4. `make eval-trading-multiasset`
  5. `make ci-quality`
- resultado:
  - `eval-trading-equities_br: PASS`
  - `eval-trading-fii_br: PASS`
  - `eval-trading-fixed_income_br: PASS`
  - `eval-trading-multiasset: PASS`
  - `quality-check: PASS`

## Refactor
- o baseline `make eval-trading` da Fase 1 permanece intacto e continua dedicado ao escopo `crypto_spot`.
- a expansao multiativos passa a ser um bloco aditivo de CI, agregado por `make eval-trading-multiasset`.
- `fixed_income_br` fica com regra explicita de validator para `max_loss_per_unit_brl`, sem contaminar o contrato v1 de `pre_trade_validator`.

## Evidencia objetiva
- novo contrato:
  - `ARC/schemas/asset_class_validator.schema.json`
- validator profiles canonicos:
  - `VERTICALS/TRADING/validator_profiles/equities_br.json`
  - `VERTICALS/TRADING/validator_profiles/fii_br.json`
  - `VERTICALS/TRADING/validator_profiles/fixed_income_br.json`
- fixtures publicadas:
  - `scripts/ci/fixtures/trading/multiasset/equities_br/`
  - `scripts/ci/fixtures/trading/multiasset/fii_br/`
  - `scripts/ci/fixtures/trading/multiasset/fixed_income_br/`
- runner novo:
  - `scripts/ci/eval_trading_asset_class.sh`
- workflow oficial atualizado:
  - `.github/workflows/ci-trading.yml` executa `make eval-trading` e `make eval-trading-multiasset`

## Alteracoes da issue
- `ARC/schemas/asset_class_validator.schema.json`
- `VERTICALS/TRADING/validator_profiles/equities_br.json`
- `VERTICALS/TRADING/validator_profiles/fii_br.json`
- `VERTICALS/TRADING/validator_profiles/fixed_income_br.json`
- `scripts/ci/fixtures/trading/multiasset/equities_br/pass.json`
- `scripts/ci/fixtures/trading/multiasset/equities_br/fail_missing_calendar.json`
- `scripts/ci/fixtures/trading/multiasset/equities_br/fail_missing_lot_size.json`
- `scripts/ci/fixtures/trading/multiasset/equities_br/fail_missing_cost.json`
- `scripts/ci/fixtures/trading/multiasset/equities_br/fail_market_closed.json`
- `scripts/ci/fixtures/trading/multiasset/fii_br/pass.json`
- `scripts/ci/fixtures/trading/multiasset/fii_br/fail_missing_min_notional.json`
- `scripts/ci/fixtures/trading/multiasset/fii_br/fail_missing_tick_size.json`
- `scripts/ci/fixtures/trading/multiasset/fii_br/fail_missing_cost.json`
- `scripts/ci/fixtures/trading/multiasset/fii_br/fail_market_auction.json`
- `scripts/ci/fixtures/trading/multiasset/fixed_income_br/pass.json`
- `scripts/ci/fixtures/trading/multiasset/fixed_income_br/fail_missing_calendar.json`
- `scripts/ci/fixtures/trading/multiasset/fixed_income_br/fail_missing_cost.json`
- `scripts/ci/fixtures/trading/multiasset/fixed_income_br/fail_missing_max_loss.json`
- `scripts/ci/fixtures/trading/multiasset/fixed_income_br/fail_market_halt.json`
- `scripts/ci/eval_trading_asset_class.sh`
- `Makefile`
- `.github/workflows/ci-trading.yml`
- `DEV/DEV-CI-RULES.md`
- `VERTICALS/TRADING/TRADING-PRD.md`
- `VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md`
- `VERTICALS/TRADING/TRADING-RISK-RULES.md`
- `PRD/CHANGELOG.md`
- `artifacts/phase-f8/epic-f8-04-issue-02-validator-evals-by-class.md`
