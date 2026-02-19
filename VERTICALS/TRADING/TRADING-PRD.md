---
doc_id: "TRADING-PRD.md"
version: "1.0"
status: "active"
owner: "Frederisk"
last_updated: "2026-02-18"
rfc_refs: ["RFC-001", "RFC-010", "RFC-050", "RFC-060"]
---

# Trading PRD

## Objetivo
Definir vertical de trading em modo controlado, com foco em gestao de risco, auditoria e escalonamento progressivo.

## Escopo
Inclui:
- pipeline backtest -> dry-run -> live
- integracoes Binance Spot e Freqtrade
- governanca de risco e aprovacao HITL

Exclui:
- alavancagem e derivativos
- execucao live sem gating de enablement

## Regras Normativas
- [RFC-060] MUST tratar trading como alto risco estrutural.
- [RFC-010] MUST exigir gates de aprovacao para transicoes de modo.
- [RFC-050] MUST registrar logs e artifacts de cada operacao.
- [RFC-060] MUST bloquear live sem criterios de enablement atendidos.

## Pipeline Operacional
1. Backtest:
  - validar estrategia em historico.
  - provar aderencia as regras de risco.
2. Dry-run:
  - simular execucao com dados de mercado.
  - medir PnL, drawdown e estabilidade.
3. Live:
  - iniciar somente por decision aprovada e apos 7 dias de dry-run sem falha de auditoria.
  - passar obrigatoriamente no `pre_trade_validator` antes de cada ordem.
  - operar com protecoes hard-coded.

## Integracoes
- Exchange: Binance Spot.
- Engine: Freqtrade em sandbox isolado.
- Supervisao: Mission Control + Telegram HITL.

## Auditoria Obrigatoria
- ordem, tamanho, stop, resultado e motivo da entrada/saida.
- decision_id vinculada para mudancas de parametro critico.
- trilha de aprovacao humana para acao sensivel.
- registro de checks do `pre_trade_validator` por ordem.

## Links Relacionados
- [Trading Risk Rules](./TRADING-RISK-RULES.md)
- [Trading Enablement](./TRADING-ENABLEMENT-CRITERIA.md)
- [Decision Protocol](../../PM/DECISION-PROTOCOL.md)
