---
doc_id: "TRADING-RISK-RULES.md"
version: "1.7"
status: "active"
owner: "Frederisk"
last_updated: "2026-02-24"
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
- [RFC-060] MUST reprovar transicao de modo se `eval-trading` falhar.
- [RFC-060] MUST aplicar ramp-up progressivo de capital somente apos estagio `paper/sandbox` concluido.
- [RFC-060] MUST manter `asset_profile` por classe de ativo para qualquer execucao live fora de `crypto_spot`.
- [RFC-060] MUST exigir aprovacao humana explicita por ordem com side effect financeiro em todos os estagios.

## Regras Hard
- Risco por trade:
  - `risk_budget_quote = equity_quote * 0.01`.
  - `stop_distance_quote = abs(entry_price_quote - stop_price_quote)`.
  - `position_size_base = risk_budget_quote / stop_distance_quote`.
  - `effective_risk_quote = (position_size_base * stop_distance_quote) + fees + slippage`.
  - `effective_risk_quote` MUST ser `<= risk_budget_quote` apos arredondamento por lote/tick.
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

## Convencao de Unidade por Classe
- `crypto_spot`:
  - `equity_quote` e `risk_budget_quote` em moeda de cotacao (ex.: USDT).
  - `position_size_base` em ativo base (ex.: BTC).
- `equities_br` e `fii_br`:
  - `equity_quote` e `risk_budget_quote` em BRL.
  - `position_size_base` em quantidade de cotas/acoes inteiras.
- `fixed_income_br`:
  - `risk_budget_quote` em BRL.
  - `position_size_base` em unidades de titulo.
  - `max_loss_per_unit_brl` MUST ser definido no `asset_profile` para calcular `position_size_base`.

## Escopo por Classe de Ativo
- `crypto_spot`:
  - classe ativa na Fase 1 sob Binance Spot.
- `equities_br`, `fii_br`, `fixed_income_br`:
  - classes bloqueadas por default ate enablement formal por classe.
  - qualquer tentativa de envio de ordem live sem enablement MUST ser bloqueada e registrada como evento de risco.

## Estagios de Exposicao
- `S0 - Paper/Sandbox`:
  - exposicao financeira real MUST ser zero.
  - qualquer tentativa de ordem real MUST bloquear e abrir evento de risco.
- `S1 - Micro-live (L0)`:
  - exposicao real minima com capital de perda total aceitavel.
  - aprovacao humana explicita por ordem.
- `S2 - Escala gradual`:
  - promocao de limites somente por decision `R3` apos historico estavel.
  - aprovacao humana explicita por ordem permanece obrigatoria.

## Regras Adicionais para Classe Nova
- `asset_profile` obrigatorio por classe:
  - calendario e horario de mercado.
  - lote/tick/notional e regras de arredondamento.
  - modelo de custo (fees, emolumentos, impostos) e slippage.
- `capital_ramp_level`:
  - classe nova MUST iniciar em `L0` da classe, sem excecao.
- validacao operacional:
  - `pre_trade_validator` MUST aplicar regras especificas da classe.
  - `eval-trading-<asset_class>` MUST estar verde antes de qualquer ordem live.

## Disponibilidade de Engine de Sinal
- falha de engine primaria de sinal MUST operar em `fail_closed`:
  - bloquear novas entradas imediatamente;
  - manter somente fluxo de protecao/reducao de risco em posicoes abertas.
- `single_engine_mode` e permitido apenas quando houver falha de engine secundaria/auxiliar e a primaria permanecer saudavel.

## Capital Ramp apos Paper (obrigatorio)
- `L0` (padrao inicial):
  - `max_notional_per_order = 50 USD`.
  - `max_daily_notional = 300 USD`.
  - `max_orders_per_day = 6`.
  - permanencia minima recomendada: 30 dias corridos sem violacao hard/sem `SEV-1|SEV-2`.
- `L1`:
  - habilitacao somente por decision aprovada + checkpoint humano.
  - limites definidos explicitamente na decision.
- regressao obrigatoria:
  - qualquer incidente `SEV-1/SEV-2` ou violacao hard MUST retornar imediatamente para `L0` ou `TRADING_BLOCKED`.

## Definicao de `safe_notional` (degradacao)
- objetivo:
  - limitar exposicao residual durante `SYSTEM_DEGRADED` com regra deterministica e reproduzivel.
- formula canonica:
  - `safe_notional = min(open_exposure_notional, max_notional_per_order_nivel_atual, 0.25 * max_daily_notional_nivel_atual)`.
- fonte de parametros:
  - `max_notional_per_order_nivel_atual` e `max_daily_notional_nivel_atual` devem vir da policy ativa de `capital_ramp_level`.
  - para classe sem limites explicitos em policy ativa, usar limites de `asset_profile`.
- regra de falha:
  - se nao for possivel calcular `safe_notional` por ausencia de parametros, sistema MUST manter `TRADING_BLOCKED` e abrir incidente de risco.

## Pre-Trade Validator (obrigatorio)
- validar `min_notional` por simbolo.
- validar `lot_size` e arredondamento de quantidade.
- validar `tick_size` e arredondamento de preco/stop.
- validar margem de fees/slippage configurada.
- validar unidade da classe de ativo conforme `asset_profile`.
- validar calendario/estado de mercado da classe (`open`, `auction`, `halt`).
- se qualquer validacao falhar, MUST bloquear ordem e abrir evento de risco.

## Eventos que Forcam Bloqueio
- violacao de regra hard.
- falha de auditoria ou dados inconsistentes.
- incidente de seguranca.
- falha de engine primaria de sinal.
- `UNMANAGED_EXPOSURE` apos degradacao.

## Links Relacionados
- [Trading PRD](./TRADING-PRD.md)
- [Trading Enablement](./TRADING-ENABLEMENT-CRITERIA.md)
- [Decision Protocol](../../PM/DECISION-PROTOCOL.md)
