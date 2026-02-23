---
doc_id: "TRADING-ENABLEMENT-CRITERIA.md"
version: "1.7"
status: "active"
owner: "Frederisk"
last_updated: "2026-02-20"
rfc_refs: ["RFC-001", "RFC-050", "RFC-060"]
---

# Trading Enablement Criteria

## Objetivo
Definir gate formal para habilitar e manter trading, garantindo que alto risco so opere sob condicoes controladas.

## Escopo
Inclui:
- criterios obrigatorios de enablement
- condicoes de bloqueio automatico
- checkpoint humano e decision para desbloqueio
- suite de validacao executavel obrigatoria

Exclui:
- ativacao por conveniencia
- bypass de criterio minimo

## Regras Normativas
- [RFC-060] MUST considerar trading como alto risco estrutural.
- [RFC-060] MUST habilitar trading somente com todos os criterios verdes.
- [RFC-050] MUST bloquear automaticamente ao violar criterio em producao.
- [RFC-060] MUST exigir decision + checkpoint humano para reabilitar.
- [RFC-060] MUST executar suite de validacao de trading antes de cada alteracao critica em live.
- [RFC-060] MUST operar entrada em live com `capital_ramp_level=L0` por default.
- [RFC-060] MUST concluir estagio `paper/sandbox` antes da primeira ordem com dinheiro real.

## Criterios de Habilitacao (todos obrigatorios)
- 7 dias sem incidentes criticos.
- retrabalho abaixo do threshold definido.
- zero falhas de auditoria em tarefas criticas.
- latencia dentro do SLA para operacoes de trading.
- suite de validacao de trading com 100% em cenarios hard-risk.
- `pre_trade_validator` com 100% de bloqueio correto para casos invalidos nos testes de regressao.
- `capital_ramp_level=L0` ativo e confirmado em configuracao de runtime.
- kill switch validado nas ultimas 24h com evidencia auditavel.
- `TradingAgents` conectado como engine primaria de sinal, com output normalizado para `signal_intent`.
- caminho de execucao unico confirmado: somente `execution_gateway` pode enviar ordem live.
- nenhum framework externo com permissao direta de credencial/endpoint de ordem.
- classe de ativo ativa com `asset_profile` versionado e aprovado.
- dominio de venue ativo em `SEC/allowlists/DOMAINS.yaml` e bloqueio comprovado para dominio fora da allowlist.
- operador backup habilitado em `SEC/allowlists/OPERATORS.yaml`.
- `make eval-trading` executavel no repositorio e validado em CI.

## Estagios de Enablement (obrigatorio)
- `S0 - Paper/Sandbox`:
  - sem ordem real.
  - aprovacao humana por ordem de entrada.
  - janela minima: 4 semanas.
  - sem incidente `SEV-1/SEV-2` na janela.
- `S1 - Micro-live`:
  - iniciar em `capital_ramp_level=L0`.
  - capital de risco minimo (perda total aceitavel).
  - aprovacao humana por ordem de entrada durante janela inicial.
  - janela minima recomendada antes de escala: 30 dias corridos.
- `S2 - Escala gradual`:
  - promocao de limite/capital somente por decision `R3`.
  - exige historico estavel do `S1` sem regressao critica.

## Suite de Validacao de Trading (obrigatoria)
- comando padrao:
  - `make eval-trading`.
- cobertura minima:
  - pre-trade validator (`min_notional`, `lot_size`, `tick_size`, fees/slippage);
  - stoploss obrigatorio;
  - calculo de position size com risco <= 1%;
  - kill switch;
  - stop diario e drawdown guard;
  - idempotencia de envio de ordem/replay de evento.
- artifacts obrigatorios:
  - `artifacts/evals/trading/summary.json`
  - `artifacts/evals/trading/failures.jsonl`

Regra de bloqueio:
- se `make eval-trading` nao existir ou nao for executavel, Trading live MUST permanecer `TRADING_BLOCKED`.

## Enablement por Classe de Ativo
- `crypto_spot`:
  - classe inicial habilitada no piloto (Binance Spot).
- `equities_br`, `fii_br`, `fixed_income_br`:
  - bloqueadas por default ate completar:
    - `asset_profile` completo e versionado;
    - `eval-trading-<asset_class>` verde com 100% de cenarios hard-risk bloqueantes;
    - `shadow_mode` com evidencia auditavel de estabilidade;
    - decision `R3` + checkpoint humano para primeira ativacao live;
    - inicio obrigatorio em `capital_ramp_level=L0` da classe.

## Bloqueio Automatico
- qualquer violacao de criterio MUST:
  - bloquear trading imediatamente;
  - abrir decision de reavaliacao;
  - notificar humano responsavel.

## Checkpoint Humano
- habilitacao inicial live.
- troca de estrategia principal.
- aumento de risco ou mudanca de limite.

## Evidencias para Reabilitacao
- causa raiz tratada.
- testes de regressao e replay de eventos de ordem aprovados.
- auditoria de logs sem anomalia.
- aprovacao em decision registrada.
- evidencia de degradacao segura:
  - `single_engine_mode` para falha de engine secundaria/auxiliar;
  - `fail_closed` para falha de engine primaria.
- para classe nova: evidencia de `shadow_mode` + suite da classe verde antes de reabilitar live.

## Gate de Prontidao para Capital Real
Todos obrigatorios antes da primeira ordem com dinheiro real:
- `S0 - Paper/Sandbox` concluido com janela minima e evidencias.
- `execution_gateway` e `pre_trade_validator` com contrato versionado e validado.
- `make eval-trading` verde em CI por 7 dias consecutivos.
- fallback HITL:
  - Telegram operacional;
  - Slack fallback somente se `slack_user_ids` e `slack_channel_ids` estiverem preenchidos para operador habilitado.
- credencial de trading live com:
  - permissao sem saque;
  - IP allowlist ativa quando suportado.
- runbook de degradacao com posicao aberta aprovado e testado em simulacao.

## `pre_live_checklist` (contrato obrigatorio)
- objetivo:
  - impedir `live-run` sem evidencias minimas de risco, seguranca e operacao.
- campos obrigatorios:
  - `checklist_id`
  - `decision_id`
  - `risk_tier`
  - `asset_class`
  - `capital_ramp_level`
  - `operator_id`
  - `approved_at`
  - `items[]` com `item_id`, `status(pass|fail)`, `evidence_ref`
- itens minimos:
  - `eval_trading_green` (`make eval-trading` verde em CI)
  - `execution_gateway_only` (sem bypass para venue)
  - `pre_trade_validator_active` (contrato versionado e carregado)
  - `credentials_live_no_withdraw` (sem saque + IP allowlist quando suportado)
  - `hitl_channel_ready` (Telegram pronto; Slack fallback somente se IDs validados)
  - `degraded_mode_runbook_ok` (simulacao validada)
  - `backup_operator_enabled` (habilitado para `approve/reject/kill`)
- regra de bloqueio:
  - qualquer item `fail` MUST manter `TRADING_BLOCKED`.
- artifact minimo:
  - `artifacts/trading/pre_live_checklist/<checklist_id>.json`

## Gate de Promocao (Micro-live -> Escala)
Todos obrigatorios:
- minimo de 30 dias corridos em `S1` com capital minimo.
- zero incidentes `SEV-1/SEV-2` no periodo.
- sem violacao hard de risco no periodo.
- reconciliacao de ordens/posicoes sem duplicidade no periodo.
- decisao `R3` de promocao com limites explicitos de novo nivel.

## Links Relacionados
- [Trading PRD](./TRADING-PRD.md)
- [Trading Risk Rules](./TRADING-RISK-RULES.md)
- [Decision Protocol](../../PM/DECISION-PROTOCOL.md)
- [System Health Thresholds](../../EVALS/SYSTEM-HEALTH-THRESHOLDS.md)
