# EPIC-F5-02 ISSUE-F5-02-04 Credenciais live restritas + gate CI obrigatorio

- data/hora: 2026-02-26 18:46:20 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F5-02-04`
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/ROADMAP.md` (`B1-09`, `B1-12`)

## Red
- cenario A: aceitar credencial de trading live sem politica de "sem saque"/IP allowlist quando suportado.
- resultado esperado: `FAIL` no `make eval-trading`.
- cenario B: permitir mudanca de trading sem workflow CI executando `make eval-trading`.
- resultado esperado: `FAIL` no `make eval-trading`.

## Green
- acao:
  - endurecer `scripts/ci/eval_trading.sh` para validar regras de credencial live nos docs normativos;
  - validar `SEC/allowlists/ACTIONS.yaml` com `execution_gateway_only` para acoes de ordem e `trading_withdraw_funds` em `blocked`;
  - validar `.github/workflows/ci-trading.yml` com etapa explicita `make eval-trading`.
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
- `PRD/CHANGELOG.md`
- `artifacts/phase-f5/epic-f5-02-issue-04-credentials-ci-gate.md`
