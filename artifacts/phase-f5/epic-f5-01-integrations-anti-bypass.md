# EPIC-F5-01 Integracoes governadas e anti-bypass - Consolidated Evidence

- data/hora: 2026-02-26 18:31:49 -0300
- host alvo: Darwin arm64
- escopo: fechamento consolidado do `EPIC-F5-01`
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/ROADMAP.md`

## Status por issue
- `ISSUE-F5-01-01` concluida:
  - gate de trading endurecido para exigir `TradingAgents` como engine primaria e pipeline/anti-bypass por arquivo.
  - evidencia: `artifacts/phase-f5/epic-f5-01-issue-01-tradingagents-signal-intent.md`.
- `ISSUE-F5-01-02` concluida:
  - bloqueio de ordem direta externa e allowlist de venue validados no gate de trading.
  - evidencia: `artifacts/phase-f5/epic-f5-01-issue-02-direct-order-block-venue-allowlist.md`.
- `ISSUE-F5-01-03` concluida:
  - contratos de integracao com metadata de versionamento obrigatoria e runtime dual preservado.
  - evidencia: `artifacts/phase-f5/epic-f5-01-issue-03-versioned-contracts-runtime-dual.md`.
- `ISSUE-F5-01-04` concluida:
  - matriz explicita de modos permitidos e checks anti-ambiguidade no pacote `INTEGRATIONS`.
  - evidencia: `artifacts/phase-f5/epic-f5-01-issue-04-allowed-modes-no-ambiguity.md`.

## Cobertura ROADMAP
- `B1-01`, `B1-02`, `B1-03`, `B1-11`, `B1-20`, `B1-21`, `B1-22`, `B1-23`, `B1-24`.

## Validacao final
1. `make eval-integrations` -> `eval-integrations: PASS`
2. `make eval-trading` -> `eval-trading: PASS`
3. `make ci-quality` -> `quality-check: PASS`

## Decisao do epico
- decisao: `done`.
- justificativa:
  - as 4 issues do epico foram executadas com evidencia auditavel.
  - gates de saida da fase (`eval-integrations` e `eval-trading`) estao verdes no mesmo ciclo.
