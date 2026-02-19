---
doc_id: "TRADING-RISK-RULES.md"
version: "1.0"
status: "active"
owner: "Frederisk"
last_updated: "2026-02-18"
rfc_refs: ["RFC-001", "RFC-010", "RFC-060"]
---

# Trading Risk Rules

## Objetivo
Definir guardrails operacionais obrigatorios para proteger capital e limitar risco de execucao da vertical Trading.

## Escopo
Inclui:
- regras hard de risco por ordem e por dia
- bloqueios estruturais de exposicao
- kill switch e parametros controlados por decision

Exclui:
- estrategias sem stoploss
- alteracao de risco sem aprovacao

## Regras Normativas
- [RFC-060] MUST limitar risco por trade a 1% do equity.
- [RFC-060] MUST exigir stoploss obrigatorio em toda ordem.
- [RFC-060] MUST manter `max_open_trades=1`.
- [RFC-060] MUST bloquear alavancagem (spot-only).
- [RFC-010] MUST abrir decision para alterar parametro critico.
- [RFC-060] MUST validar constraints de exchange antes de enviar ordem.

## Regras Hard
- Risco por trade:
  - `position_size = equity * 0.01 / stop_distance`
  - aplicar desconto de fees/slippage no calculo de risco efetivo.
- Stoploss:
  - ordem sem stop inicial MUST ser rejeitada.
- Exposicao:
  - `max_open_trades=1`.
- Cooldown apos loss:
  - default 6h; parametrizavel via decision.
- Stop diario:
  - se PnL diario <= -3%, pausar ate proximo dia (-03).
- Drawdown guard:
  - congelar entre 8%-12% conforme decision vigente.
- Alavancagem:
  - proibida.
- Kill switch:
  - MUST parar imediatamente novas entradas.

## Pre-Trade Validator (obrigatorio)
- validar `min_notional` por simbolo.
- validar `lot_size` e arredondamento de quantidade.
- validar `tick_size` e arredondamento de preco/stop.
- validar margem de fees/slippage configurada.
- se qualquer validacao falhar, MUST bloquear ordem e abrir evento de risco.

## Eventos que Forcam Bloqueio
- violacao de regra hard.
- falha de auditoria ou dados inconsistentes.
- incidente de seguranca.

## Links Relacionados
- [Trading PRD](./TRADING-PRD.md)
- [Trading Enablement](./TRADING-ENABLEMENT-CRITERIA.md)
- [Decision Protocol](../../PM/DECISION-PROTOCOL.md)
