# EPIC-F5-01 ISSUE-F5-01-02 Bloqueio de ordem direta externa + allowlist de venue

- data/hora: 2026-02-26 18:25:54 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F5-01-02`
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/ROADMAP.md` (`B1-03`, `B1-11`, `B1-22`)

## Red
- cenario A: remover regra de caminho unico via `execution_gateway` em qualquer doc normativo de trading.
- resultado esperado: `FAIL` por ausencia do padrao obrigatorio no arquivo afetado.
- cenario B: remover regra de allowlist de venue em qualquer doc normativo de trading.
- resultado esperado: `FAIL` por drift documental entre os docs de trading.
- cenario C: remover baseline Binance da `SEC/allowlists/DOMAINS.yaml`.
- resultado esperado: `FAIL` por ausencia dos campos obrigatorios da allowlist.

## Green
- acao:
  - endurecer `scripts/ci/eval_trading.sh` para exigir:
    - `execution_gateway only` por arquivo;
    - regra de allowlist de venue por arquivo;
    - baseline de `SEC/allowlists/DOMAINS.yaml` (`trading_phase1_binance`, `api.binance.com`, `deny`).
  - alinhar `VERTICALS/TRADING/TRADING-PRD.md` com as mesmas regras normativas ja presentes em `TRADING-ENABLEMENT-CRITERIA`.
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
  - adiciona `SEC/allowlists/DOMAINS.yaml` como arquivo obrigatorio do gate;
  - valida `execution_gateway only` e allowlist de venue em cada doc normativo de trading;
  - valida baseline de dominios permitidos para Binance fase 1.
- `VERTICALS/TRADING/TRADING-PRD.md`
  - explicita caminho unico de execucao live via `execution_gateway`;
  - explicita dependencia da allowlist de venue em `SEC/allowlists/DOMAINS.yaml`.
- `PRD/CHANGELOG.md`
  - registra execucao normativa da `ISSUE-F5-01-02`.
- `artifacts/phase-f5/epic-f5-01-issue-02-direct-order-block-venue-allowlist.md`
  - evidencia auditavel do ciclo da issue.
