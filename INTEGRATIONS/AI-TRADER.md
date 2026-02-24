---
doc_id: "INTEGRATIONS-AI-TRADER.md"
version: "1.0"
status: "active"
owner: "Trading"
last_updated: "2026-02-24"
rfc_refs: ["RFC-010", "RFC-015", "RFC-050", "RFC-060"]
---

# Integration - AI-Trader

## Objetivo
Integrar AI-Trader como fonte de pesquisa e geracao de sinais sem violar hard gates financeiros do OpenClaw/Trading.

## Modo Permitido
- MUST operar somente como gerador de `signal_intent`.
- saida valida da integracao: intencao de sinal normalizada e auditavel.
- pipeline oficial: `AI-Trader -> signal_intent -> normalizacao/deduplicacao -> pre_trade_validator -> HITL -> execution_gateway`.

## Fora de Escopo e Bloqueios
- MUST NOT enviar `order_intent` diretamente para venue/exchange.
- qualquer payload que represente ordem direta originada do AI-Trader MUST ser bloqueado e auditado.
- qualquer tentativa de bypass de `pre_trade_validator`, HITL ou `execution_gateway` MUST manter estado `TRADING_BLOCKED` ate revisao humana.

## Threat Model (resumo)
- risco de autonomia nao supervisionada (`zero human input`) levando a side effect financeiro sem aprovacao.
- risco de bypass via toolchain externo (ex.: MCP) sem trilha de policy.
- risco de replay/duplicacao de sinais sem deduplicacao.

## Contratos/Schemas
- input canonico aceito: [signal_intent](../ARC/schemas/signal_intent.schema.json).
- qualquer transicao para ordem real MUST ocorrer so via [order_intent](../ARC/schemas/order_intent.schema.json) depois de `pre_trade_validator` e aprovacao HITL.
- output de execucao MUST seguir [execution_report](../ARC/schemas/execution_report.schema.json).

## Checklist de Testes/Gates
- `make eval-integrations`.
- `make eval-trading`.
- teste negativo obrigatorio: payload de ordem direta originado do AI-Trader deve ser rejeitado e registrado como violacao.
- teste de fail-closed: indisponibilidade da engine primaria nao pode liberar novas entradas live.

## Rollback / Fail-Closed
- em anomalia de integracao, bloquear novas ordens (`TRADING_BLOCKED`) e manter somente coleta de sinal em ambiente `S0`/replay.
- rollback operacional consiste em remover AI-Trader do roteamento de sinal e manter `TradingAgents` como unica fonte ativa aprovada por decision.
