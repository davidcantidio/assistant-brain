# EPIC-F5-01 ISSUE-F5-01-01 TradingAgents + signal_intent + normalizacao/deduplicacao

- data/hora: 2026-02-26 18:24:05 -0300
- host alvo: Darwin arm64
- escopo: `ISSUE-F5-01-01`
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/ROADMAP.md` (`B1-01`, `B1-02`, `B1-22`)

## Red
- cenario A: regra de `TradingAgents` como engine primaria ausente em qualquer doc normativo de trading.
- resultado esperado: `FAIL` no gate por ausencia de padrao obrigatorio no arquivo afetado.
- cenario B: pipeline oficial de sinal externo ausente em qualquer um dos docs de trading.
- resultado esperado: `FAIL` no gate por drift entre `TRADING-PRD` e `TRADING-ENABLEMENT-CRITERIA`.

## Green
- acao: endurecer `scripts/ci/eval_trading.sh` para validar por arquivo:
  - `TradingAgents.*engine primaria de sinal`;
  - pipeline oficial `AI-Trader -> signal_intent -> normalizacao/deduplicacao -> pre_trade_validator -> HITL -> execution_gateway`;
  - regra anti-bypass `ordem direta originada do AI-Trader MUST ser rejeitado e auditado`.
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
  - adiciona helper `search_re_each_file`;
  - passa a exigir padroes obrigatorios em cada doc de trading para evitar falso positivo por busca agregada.
- `PRD/CHANGELOG.md`
  - registra execucao normativa da `ISSUE-F5-01-01`.
- `artifacts/phase-f5/epic-f5-01-issue-01-tradingagents-signal-intent.md`
  - evidencia auditavel do ciclo da issue.
