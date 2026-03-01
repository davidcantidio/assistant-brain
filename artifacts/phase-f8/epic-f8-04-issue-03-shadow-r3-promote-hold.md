# EPIC-F8-04 ISSUE-F8-04-03 shadow_mode e decision R3 por classe

- data/hora: 2026-03-01 10:56:06 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F8-04-03`
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/ROADMAP.md`, `VERTICALS/TRADING/TRADING-PRD.md`, `VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md`, `VERTICALS/TRADING/TRADING-RISK-RULES.md`, `PM/DECISION-PROTOCOL.md`

## Red
- cenario A: promover `equities_br`, `fii_br` ou `fixed_income_br` sem `shadow_mode`.
- resultado esperado: `hold` em `phase-f8-multiasset-enablement`.
- cenario B: promover classe sem decision `R3`.
- resultado esperado: `hold` em `phase-f8-multiasset-enablement`.
- cenario C: mover a fase `F8` para `feito` sem fallback de `EPICS.md` na governanca semanal.
- resultado esperado: `FAIL` em `make ci-quality`.

## Green
- acao:
  - criar `ARC/schemas/shadow_mode_review.schema.json`;
  - publicar artifacts canonicos em `artifacts/trading/shadow_mode/` com `status=pending_shadow`, `decision_id=not-issued`, `decision_status=NOT_REQUIRED_YET` e `promote_readiness=hold`;
  - publicar fixtures sinteticas positivas em `scripts/ci/fixtures/trading/multiasset/shadow/` com `status=completed`, `decision_status=APPROVED`, `risk_tier=R3` e `promote_readiness=pass`;
  - adicionar `scripts/ci/phase_f8_multiasset_enablement.py`, wrappers shell e target `make phase-f8-multiasset-enablement`;
  - mover `EPIC-F8-04` e `EPICS.md` da `F8` para `PM/PHASES/feito/F8-OPERACAO-CONTINUA-E-EVOLUCAO/`;
  - adicionar fallback para `EPICS.md` movido nos scripts semanais da `F8`;
  - rerodar a governanca semanal de `2026-W09`.
- comandos:
  1. `make phase-f8-multiasset-enablement`
  2. `make phase-f8-weekly-governance`
  3. `make ci-quality`
  4. `make ci-security`
- resultado:
  - `phase-f8-multiasset-enablement: PASS`
  - `phase-f8-weekly-governance: decision=hold`
  - `quality-check: PASS`
  - `security-check: PASS`

## Refactor
- `EPIC-F8-04` fecha documentalmente sem promover live: o estado real das classes novas continua bloqueado em `hold`.
- a `F8` passa a ser arquivada em `PM/PHASES/feito/`, sem quebrar `validation-summary` nem os checkers semanais.
- o summary semanal da `2026-W09` passa a refletir `EPIC-F8-04=done`, mas preserva `hold` por dependencia externa da fase anterior e por `critical_drifts_open=1`.

## Evidencia objetiva
- artifact consolidado:
  - `artifacts/phase-f8/epic-f8-04-multiasset-enablement.md`
- artifacts canonicos de shadow:
  - `artifacts/trading/shadow_mode/SHADOW-F8-04-EQUITIES-BR-20260301-01.json`
  - `artifacts/trading/shadow_mode/SHADOW-F8-04-FII-BR-20260301-01.json`
  - `artifacts/trading/shadow_mode/SHADOW-F8-04-FIXED-INCOME-BR-20260301-01.json`
- fixtures positivas:
  - `scripts/ci/fixtures/trading/multiasset/shadow/pass_equities_br.json`
  - `scripts/ci/fixtures/trading/multiasset/shadow/pass_fii_br.json`
  - `scripts/ci/fixtures/trading/multiasset/shadow/pass_fixed_income_br.json`
- fase arquivada:
  - `PM/PHASES/feito/F8-OPERACAO-CONTINUA-E-EVOLUCAO/EPIC-F8-04-EXPANSAO-MULTIATIVOS-ENABLEMENT.md`
  - `PM/PHASES/feito/F8-OPERACAO-CONTINUA-E-EVOLUCAO/EPICS.md`

## Alteracoes da issue
- `ARC/schemas/shadow_mode_review.schema.json`
- `artifacts/trading/shadow_mode/SHADOW-F8-04-EQUITIES-BR-20260301-01.json`
- `artifacts/trading/shadow_mode/SHADOW-F8-04-FII-BR-20260301-01.json`
- `artifacts/trading/shadow_mode/SHADOW-F8-04-FIXED-INCOME-BR-20260301-01.json`
- `scripts/ci/fixtures/trading/multiasset/shadow/pass_equities_br.json`
- `scripts/ci/fixtures/trading/multiasset/shadow/pass_fii_br.json`
- `scripts/ci/fixtures/trading/multiasset/shadow/pass_fixed_income_br.json`
- `scripts/ci/phase_f8_multiasset_enablement.py`
- `scripts/ci/run_phase_f8_multiasset_enablement.sh`
- `scripts/ci/check_phase_f8_multiasset_enablement.sh`
- `scripts/ci/phase_f8_release_governance.py`
- `scripts/ci/run_phase_f8_weekly_governance.sh`
- `scripts/ci/check_phase_f8_weekly_governance.sh`
- `scripts/ci/check_quality.sh`
- `Makefile`
- `PRD/PHASE-USABILITY-GUIDE.md`
- `PRD/CHANGELOG.md`
- `PM/PHASES/feito/F8-OPERACAO-CONTINUA-E-EVOLUCAO/EPIC-F8-04-EXPANSAO-MULTIATIVOS-ENABLEMENT.md`
- `PM/PHASES/feito/F8-OPERACAO-CONTINUA-E-EVOLUCAO/EPICS.md`
- `artifacts/phase-f8/epic-f8-04-issue-03-shadow-r3-promote-hold.md`
