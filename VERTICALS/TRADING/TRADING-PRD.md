---
doc_id: "TRADING-PRD.md"
version: "1.9"
status: "active"
owner: "Frederisk"
last_updated: "2026-02-24"
rfc_refs: ["RFC-001", "RFC-010", "RFC-050", "RFC-060"]
---

# Trading PRD

## Objetivo
Definir vertical de trading em modo controlado, com foco em gestao de risco, auditoria e escalonamento progressivo.

## Escopo
Inclui:
- rollout conservador em 3 estagios: `paper/sandbox -> micro-live -> escala gradual`
- fase 1: integracoes Binance Spot e Freqtrade (crypto spot)
- governanca de risco e aprovacao HITL
- validacao executavel de risco antes de transicoes de modo
- estrategia de expansao multiativos (acoes/FIIs/titulos) com gate por classe de ativo

Exclui:
- alavancagem e derivativos
- execucao live sem gating de enablement
- ativacao de nova classe de ativo sem `asset_profile` e enablement formal

## Regras Normativas
- [RFC-060] MUST tratar trading como alto risco estrutural.
- [RFC-010] MUST exigir gates de aprovacao para transicoes de modo.
- [RFC-050] MUST registrar logs e artifacts de cada operacao.
- [RFC-060] MUST bloquear live sem criterios de enablement atendidos.
- [RFC-060] MUST exigir aprovacao humana explicita por ordem com side effect financeiro.

## Pipeline Operacional
1. Backtest:
  - validar estrategia em historico.
  - provar aderencia as regras de risco.
2. Paper/Sandbox (obrigatorio):
  - operar somente em ambiente sem dinheiro real.
  - ordem real MUST permanecer bloqueada (`TRADING_BLOCKED`) neste estagio.
  - execucao em modo assistido: aprovacao humana obrigatoria por ordem de entrada.
  - janela minima recomendada: 4 semanas com estabilidade operacional.
3. Micro-live (capital minimo):
  - iniciar somente por decision aprovada com `risk_tier=R3`.
  - iniciar em `capital_ramp_level=L0` com limites reduzidos por ordem/dia.
  - usar apenas capital de perda total aceitavel.
  - manter aprovacao humana explicita por ordem em todo o estagio.
  - consumir sinal apenas via `signal_intent` normalizado e auditavel.
  - passar obrigatoriamente no `pre_trade_validator` antes de cada ordem.
  - operar com protecoes hard-coded.
  - executar `eval-trading` a cada alteracao de regra critica.
4. Escala gradual:
  - aumento de capital e limite so por decision explicita apos historico real estavel.
  - promocao de nivel MUST ser bloqueada se houver regressao de risco/confiabilidade.
  - execucao de ordem permanece sob aprovacao humana explicita por ordem.

## Integracoes
- Exchange/Venue (Fase 1): Binance Spot.
- Exchange/Venue (Fase 2+):
  - acoes e FIIs via broker adapter homologado.
  - titulos (renda fixa) via adapter homologado de broker/venue suportado.
- Engine: Freqtrade em sandbox isolado.
- Frameworks de decisao externos:
  - `TradingAgents` = engine primaria de sinal na Fase 1.
  - `AI-Trader` = engine secundaria de pesquisa/sinal em modo estritamente `signal_only`.
  - `AgenticTrading` = fonte secundaria de modulos especificos (risco/custo/portfolio) na Fase 2.
- Supervisao: Mission Control + HITL multi-canal (Telegram primario, Slack fallback controlado).

## Estrategia de Integracao de Frameworks Externos
- Backbone canonico de producao:
  - OpenClaw control-plane + risk engine + execution gateway + auditoria imutavel.
- Regra de acoplamento:
  - frameworks externos MUST operar como plugins de analise/sinal.
  - framework externo MUST NOT enviar ordem diretamente para exchange.
- Fase 1 (prioridade):
  - integrar `TradingAgents` como engine primaria de `signal_intent`.
  - integrar AI-Trader somente como produtor de intencao (`signal_intent`), sem permissao de enviar ordem.
  - pipeline oficial de integracao externa: `AI-Trader -> signal_intent -> normalizacao/deduplicacao -> pre_trade_validator -> HITL -> execution_gateway`.
  - caminho de execucao unico confirmado: somente `execution_gateway` pode enviar ordem live.
  - dominio de venue ativo em `SEC/allowlists/DOMAINS.yaml` e bloqueio comprovado para dominio fora da allowlist.
  - `signal_intent` passa por normalizacao, deduplicacao e `pre_trade_validator`.
  - qualquer payload que represente ordem direta originada do AI-Trader MUST ser rejeitado e auditado.
  - indisponibilidade da engine primaria MUST operar em `fail_closed` para novas entradas.
- Fase 2 (evolucao controlada):
  - integrar de `AgenticTrading` somente modulos com ganho comprovado:
    - `risk_agent_pool`
    - `transaction_cost_agent_pool`
    - `portfolio_construction_agent_pool` (opcional, apos estabilidade)
  - qualquer modulo novo MUST entrar em shadow mode antes de afetar decisao live.
  - falha de engine secundaria/auxiliar MAY ativar `single_engine_mode` com engine primaria saudavel.
- Governanca:
  - OpenClaw permanece fonte de verdade para `decision`, `order_intent`, `execution_report` e incidentes.
  - mudanca de peso entre engines ou ativacao de novo modulo MUST exigir decision registrada.

## Expansao Multiativos (pos-Fase 1)
- Classes de ativo planejadas:
  - `crypto_spot` (escopo inicial, Binance).
  - `equities_br` (acoes).
  - `fii_br` (fundos imobiliarios).
  - `fixed_income_br` (titulos/renda fixa).
- Regra de entrada por classe:
  - cada classe MUST ter `asset_profile` versionado com: calendario de mercado, regras de lote/tick/notional, custos/taxas/impostos e limites de liquidez/slippage.
  - cada classe MUST passar em suite de validacao dedicada (`eval-trading-<asset_class>`) com cobertura hard-risk.
  - cada classe MUST operar primeiro em `shadow_mode` com evidencia auditavel antes de impactar decisao live.
  - primeira ativacao live de classe nova MUST iniciar em `capital_ramp_level=L0` da classe e exigir decision `R3` + checkpoint humano.
- Regra de execucao:
  - toda ordem de qualquer classe MUST passar por `execution_gateway` unico e `pre_trade_validator` especifico da classe.
  - fonte de sinal pode variar, mas a fonte de verdade de execucao/auditoria permanece no OpenClaw.

## Contratos Operacionais (versionados)
- `execution_gateway` (v1 minimo):
  - entrada obrigatoria:
    - `order_intent_id`
    - `idempotency_key`
    - `asset_class`
    - `symbol`
    - `side`
    - `order_type`
    - `quantity`
    - `price` (quando aplicavel)
    - `stop_price` (obrigatorio para entrada live)
    - `risk_tier`
    - `decision_id`
  - saida obrigatoria:
    - `execution_id`
    - `venue_order_id`
    - `status`
    - `filled_quantity`
    - `avg_fill_price`
    - `reject_reason|null`
    - `position_snapshot_ref`
- `pre_trade_validator` (v1 minimo):
  - entrada obrigatoria:
    - `asset_profile_version`
    - `capital_ramp_level`
    - `symbol`
    - `symbol_constraints` (`min_notional`, `lot_size`, `tick_size`)
    - `order_intent`
    - `market_state`
  - saida obrigatoria:
    - `validator_status` (`PASS|BLOCK`)
    - `block_reasons[]`
    - `normalized_order`
    - `effective_risk_quote`
- regra:
  - alteracao de contrato MUST incrementar versao e passar em `eval-trading`.

## Auditoria Obrigatoria
- ordem, tamanho, stop, resultado e motivo da entrada/saida.
- decision_id vinculada para mudancas de parametro critico.
- trilha de aprovacao humana para acao sensivel.
- registro de checks do `pre_trade_validator` por ordem.

## Validacao Executavel (gate)
- comando: `make eval-trading`.
- release de regra critica para live sem resultado verde MUST ser bloqueada.
- ausencia do comando no repositorio MUST manter `TRADING_BLOCKED`.

## Gate de Prontidao para Capital Real
- entrada de capital real so e permitida quando todos os itens abaixo estiverem verdes:
  - estagio `paper/sandbox` concluido por janela minima definida com evidencias auditaveis.
  - `execution_gateway` + `pre_trade_validator` com contrato v1 versionado.
  - `make eval-trading` executavel e verde em CI por 7 dias.
  - credenciais de trading live sem permissao de saque e com IP allowlist quando suportado.
  - fallback HITL:
    - Telegram operacional.
    - Slack fallback apenas com `slack_user_ids` e `slack_channel_ids` preenchidos.
  - runbook de degradacao com posicao aberta validado em simulacao.

## Links Relacionados
- [Trading Risk Rules](./TRADING-RISK-RULES.md)
- [Trading Enablement](./TRADING-ENABLEMENT-CRITERIA.md)
- [Integration: AI-Trader](../../INTEGRATIONS/AI-TRADER.md)
- [Integration: ClawWork](../../INTEGRATIONS/CLAWWORK.md)
- [Decision Protocol](../../PM/DECISION-PROTOCOL.md)
