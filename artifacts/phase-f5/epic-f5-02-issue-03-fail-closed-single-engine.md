# EPIC-F5-02 ISSUE-F5-02-03 fail_closed primaria + single_engine_mode secundaria

- data/hora: 2026-02-26 18:44:38 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F5-02-03`
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/ROADMAP.md` (`B1-07`, `B2-R04`)

## Red
- cenario A: manter novas entradas habilitadas apos falha de engine primaria.
- resultado esperado: `FAIL` no `make eval-trading`.
- cenario B: permitir `single_engine_mode` sem condicao de engine primaria saudavel.
- resultado esperado: `FAIL` no `make eval-trading`.

## Green
- acao:
  - endurecer `scripts/ci/eval_trading.sh` para exigir, por arquivo normativo, regras explicitas de:
    - `fail_closed` associado a falha primaria;
    - `single_engine_mode` associado a falha secundaria;
    - condicao de primaria saudavel para `single_engine_mode`.
  - alinhar `VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md` com a condicao de primaria saudavel.
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
- `scripts/ci/eval_trading.sh`
- `VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md`
- `PRD/CHANGELOG.md`
- `artifacts/phase-f5/epic-f5-02-issue-03-fail-closed-single-engine.md`
