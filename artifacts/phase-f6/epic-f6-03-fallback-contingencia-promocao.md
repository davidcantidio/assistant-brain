# EPIC-F6-03 fallback, contingencia e promocao consolidado

- data/hora: 2026-03-01 11:05:00 -0300
- host alvo: Darwin arm64
- escopo: `EPIC-F6-03`
- fonte de verdade: `PRD/PRD-MASTER.md`, `PM/DECISION-PROTOCOL.md`, `VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md`, `SEC/SEC-POLICY.md`

## Status por trilha do epico
- `ISSUE-F6-03-01` runbook de contingencia Telegram degradado com fallback Slack controlado: `PASS`
  - evidencia: `artifacts/phase-f6/epic-f6-03-issue-01-telegram-degraded-slack-fallback-controlled.md`
- `ISSUE-F6-03-02` pre-condicao de live sem fallback HITL validado permanece `TRADING_BLOCKED`: `PASS`
  - evidencia: `artifacts/phase-f6/epic-f6-03-issue-02-trading-blocked-without-valid-hitl-fallback.md`
- `ISSUE-F6-03-03` consolidacao de evidencia de fase e decisao final: `PASS`
  - evidencia: `artifacts/phase-f6/epic-f6-03-issue-03-phase-evidence-promote-hold.md`

## Status consolidado do epico
- fallback/contingencia: `PASS`
  - fallback Slack condicionado a degradacao de Telegram por > 2 heartbeats;
  - controles equivalentes (`HMAC` + `anti-replay` + `challenge`) reforcados.
- trading pre-live: `PASS`
  - sem fallback HITL validado, live permanece `TRADING_BLOCKED`;
  - desbloqueio por prontidao HITL somente por decisao formal.
- fechamento de fase: `PASS`
  - checklist HITL completo e artifact unico de validacao preenchidos;
  - decisao final de fase: `hold`.

## Gates finais do epico
- `make ci-security`: `PASS`
- `make eval-trading`: `PASS`
- `make ci-quality`: `PASS`
- `make eval-gates`: `PASS`
