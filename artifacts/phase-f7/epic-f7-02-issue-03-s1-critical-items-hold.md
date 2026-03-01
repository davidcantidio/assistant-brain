# EPIC-F7-02 ISSUE-F7-02-03 itens criticos de S1 com decisao hold

- data/hora: 2026-03-01 00:30:00 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F7-02-03`
- fonte de verdade: `VERTICALS/TRADING/TRADING-PRD.md`, `VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md`, `PM/DECISION-PROTOCOL.md`, `SEC/allowlists/OPERATORS.yaml`, `scripts/ci/eval_trading.sh`

## Red
- cenario A: checklist de `S1` com pelo menos um item minimo em `fail`.
- resultado esperado: `hold` para prontidao de `S1`.
- cenario B: tratar prontidao como `pass` sem evidenciar a matriz completa de 8 itens e as falhas criticas reais.
- resultado esperado: bloqueio da promocao operacional por inconsistencia de governanca.

## Green
- acao:
  - validar checklist atual preservando a matriz completa de 8 itens e o estado real dos 4 itens criticos em `fail`;
  - registrar decisao `hold` auditavel para `S1` sem forcar alteracao artificial de readiness;
  - consolidar artifact do epic com status dos guardrails, checklist completo e regra de bloqueio.
- comandos:
  1. `make eval-trading`
  2. `make ci-quality`
  3. `make ci-security`
- resultado:
  - `eval-trading: PASS`
  - `quality-check: PASS`
  - `security-check: PASS`

## Refactor
- manter fechamento do epic por avaliacao documental/tdd com decisao `hold` quando qualquer item obrigatorio permanecer em `fail`.
- manter rastreabilidade entre checklist, allowlist de operadores, aprovacao humana por ordem e protocolo de decisao.

## Evidencia objetiva
- matriz minima obrigatoria do checklist de `S1`:
  - `eval_trading_green=pass`
  - `execution_gateway_only=pass`
  - `pre_trade_validator_active=pass`
  - `credentials_live_no_withdraw=fail`
  - `hitl_channel_ready=fail`
  - `degraded_mode_runbook_ok=pass`
  - `backup_operator_enabled=fail`
  - `explicit_order_approval_active=fail`
- regra material:
  - qualquer item `fail` MUST manter `TRADING_BLOCKED`;
  - remocao de `TRADING_BLOCKED` so por decisao formal registrada;
  - aprovacao humana por ordem continua mandatória em `S1`.
- decisao da issue: `hold`.


## Alteracoes da issue
- `artifacts/phase-f7/epic-f7-02-issue-03-s1-critical-items-hold.md`
- `artifacts/phase-f7/epic-f7-02-s1-readiness.md`
- `PM/PHASES/F7-TRADING-POR-ESTAGIOS/EPICS.md`
- `PM/PHASES/feito/F7-TRADING-POR-ESTAGIOS/EPIC-F7-02-S1-MICRO-LIVE-PRE-LIVE-CHECKLIST.md`
- `PRD/CHANGELOG.md`
