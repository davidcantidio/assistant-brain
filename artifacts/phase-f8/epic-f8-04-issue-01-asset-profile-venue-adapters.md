# EPIC-F8-04 ISSUE-F8-04-01 asset_profile e venue adapters por classe

- data/hora: 2026-03-01 10:40:33 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F8-04-01`
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/ROADMAP.md`, `VERTICALS/TRADING/TRADING-PRD.md`, `VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md`, `VERTICALS/TRADING/TRADING-RISK-RULES.md`, `PM/DECISION-PROTOCOL.md`

## Red
- cenario A: habilitar `equities_br`, `fii_br` ou `fixed_income_br` sem `asset_profile`.
- resultado esperado: `FAIL` em `make phase-f8-multiasset-contracts`.
- cenario B: manter classe sem `venue_adapter` dedicado ou com `execution_path` diferente de `execution_gateway_only`.
- resultado esperado: `FAIL` em `make phase-f8-multiasset-contracts`.
- cenario C: publicar `fixed_income_br` sem `risk_units.max_loss_per_unit_brl`.
- resultado esperado: `FAIL` em `make phase-f8-multiasset-contracts`.

## Green
- acao:
  - mover `PM/PHASES/F7-TRADING-POR-ESTAGIOS/EPICS.md` para `PM/PHASES/feito/F7-TRADING-POR-ESTAGIOS/EPICS.md`;
  - criar `ARC/schemas/asset_profile.schema.json` e `ARC/schemas/venue_adapter.schema.json`;
  - publicar manifests em `VERTICALS/TRADING/asset_profiles/` e `VERTICALS/TRADING/venue_adapters/` para `equities_br`, `fii_br` e `fixed_income_br`;
  - adicionar `scripts/ci/check_phase_f8_multiasset_contracts.sh` e target `make phase-f8-multiasset-contracts`;
  - integrar o novo checker ao `make ci-quality`;
  - atualizar docs de Trading para apontar os manifests como fonte canonica por classe.
- comandos:
  1. `make phase-f8-multiasset-contracts`
  2. `make ci-quality`
- resultado:
  - `phase-f8-multiasset-contracts: PASS`
  - `quality-check: PASS`

## Refactor
- `equities_br`, `fii_br` e `fixed_income_br` passam a compartilhar o mesmo contrato estrutural de `asset_profile` e `venue_adapter`, sem alterar o baseline `v1` de `execution_gateway` e `pre_trade_validator`.
- os tres adapters ficam explicitamente em `status=blocked` e presos ao grupo `trading_phase2_brokers` enquanto nao houver broker homologado em `SEC/allowlists/DOMAINS.yaml`.
- a fase `F7` passa a ser referenciada pelo `EPICS.md` movido para `PM/PHASES/feito/`, preservando os links de fase ativos.

## Evidencia objetiva
- novos contratos versionados:
  - `ARC/schemas/asset_profile.schema.json`
  - `ARC/schemas/venue_adapter.schema.json`
- manifests publicados:
  - `VERTICALS/TRADING/asset_profiles/equities_br.json`
  - `VERTICALS/TRADING/asset_profiles/fii_br.json`
  - `VERTICALS/TRADING/asset_profiles/fixed_income_br.json`
  - `VERTICALS/TRADING/venue_adapters/equities_br.json`
  - `VERTICALS/TRADING/venue_adapters/fii_br.json`
  - `VERTICALS/TRADING/venue_adapters/fixed_income_br.json`
- gate dedicado:
  - `scripts/ci/check_phase_f8_multiasset_contracts.sh`
- resultado validado:
  - `fixed_income_br` exige `risk_units.max_loss_per_unit_brl`;
  - todo `venue_adapter` exige `execution_path=execution_gateway_only`;
  - todo `venue_adapter` exige `allowlist_group=trading_phase2_brokers`;
  - a documentacao normativa de Trading referencia explicitamente `VERTICALS/TRADING/asset_profiles/` e `VERTICALS/TRADING/venue_adapters/`.

## Alteracoes da issue
- `PM/PHASES/feito/F7-TRADING-POR-ESTAGIOS/EPICS.md`
- `PRD/PHASE-USABILITY-GUIDE.md`
- `ARC/schemas/asset_profile.schema.json`
- `ARC/schemas/venue_adapter.schema.json`
- `VERTICALS/TRADING/asset_profiles/equities_br.json`
- `VERTICALS/TRADING/asset_profiles/fii_br.json`
- `VERTICALS/TRADING/asset_profiles/fixed_income_br.json`
- `VERTICALS/TRADING/venue_adapters/equities_br.json`
- `VERTICALS/TRADING/venue_adapters/fii_br.json`
- `VERTICALS/TRADING/venue_adapters/fixed_income_br.json`
- `scripts/ci/check_phase_f8_multiasset_contracts.sh`
- `scripts/ci/check_quality.sh`
- `Makefile`
- `VERTICALS/TRADING/TRADING-PRD.md`
- `VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md`
- `VERTICALS/TRADING/TRADING-RISK-RULES.md`
- `PRD/CHANGELOG.md`
- `artifacts/phase-f8/epic-f8-04-issue-01-asset-profile-venue-adapters.md`
