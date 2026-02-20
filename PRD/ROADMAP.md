---
doc_id: "ROADMAP.md"
version: "1.8"
status: "active"
owner: "PM"
last_updated: "2026-02-20"
rfc_refs: ["RFC-001", "RFC-010", "RFC-015", "RFC-020", "RFC-030", "RFC-035", "RFC-040", "RFC-050", "RFC-060"]
---

# Roadmap

## Objetivo
Definir fases, milestones e criterios objetivos de saida para evolucao do OpenClaw Agent OS com OpenRouter + Model Router + memoria vetorial hibrida sob controle de risco.

## Escopo
Inclui:
- planejamento em 3 fases (Mission Control, Trading, Expansao)
- entregas tecnicas minimas por fase
- Definition of Done com metrica verificavel
- backlog obrigatorio para sair de arquitetura de papel para MVP operacional

Exclui:
- tuning fino de prompt por caso
- implementacao de infraestrutura dentro deste documento
- benchmark detalhado por hardware

## Regras Normativas
- [RFC-040] MUST bloquear inicio de fase nova sem DoD da fase anterior.
- [RFC-010] MUST manter gate por risco em todas as fases.
- [RFC-050] MUST acompanhar custo, latencia, fallback e incidentes por fase.
- [RFC-035] MUST validar degradacao e reconciliacao antes de subir risco operacional.
- [RFC-060] MUST tratar Trading como fase gated por enablement formal.

## Plataforma de CI (decisao fechada)
- plataforma oficial: **GitHub Actions**.
- todo gate obrigatorio MUST ter workflow reproduzivel versionado no repositorio.

## Fase 0 - Mission Control Minimo
- Convex com colecoes minimas de control-plane.
- OpenClaw runtime configurado para workspace `workspaces/main`.
- Worker LLM local habilitado na Fase 0 para tarefas pesadas nao urgentes (host compativel, preferencia Mac >= 32 GB RAM).
- gateway LLM programatico padrao: OpenRouter (`https://openrouter.ai/api/v1`).
- Telegram bot com `/approve`, `/reject`, `/kill` e standup diario 11:30 (-03), mais adapter Slack para colaboracao operacional, `@mentions` e fallback HITL quando Telegram cair.
- Model Catalog Service + Model Router + Presets como componentes obrigatorios.
- Memory plane vetorial hibrido (Postgres + pgvector ou equivalente) para catalogo/runs/decisoes.
- Budget Governor baseado em saldo de creditos OpenRouter.
- policy de privacidade/retencao/provider allowlist/ZDR ativa por sensibilidade.
- Routing MVP limitado a 3 classes: Dispatcher, RAG Librarian (empresa), Dev Junior.

### Backlog de construcao de codigo (obrigatorio na Fase 0)
- `B0-01` implementar contratos `work_order`, `decision`, `task_event` com validacao de schema.
- `B0-02` implementar bot Telegram com autenticacao forte (`from.id` + `chat.id` + challenge).
- `B0-03` implementar lifecycle completo do challenge HITL.
- `B0-04` implementar enforcement idempotente e rollback para `SPRINT_OVERRIDE`.
- `B0-05` implementar contrato idempotente para auto-acoes de saude/observabilidade.
- `B0-06` implementar reconciliador de degraded mode (`idempotency_key` + `replay_key`).
- `B0-07` implementar OpenRouter client padrao (OpenAI-compatible) no runtime.
- `B0-08` implementar Model Catalog Service:
  - sync de Models API,
  - versionamento de preco/capabilities/limites/supported parameters.
- `B0-09` implementar Model Router:
  - provider routing (`include/exclude/order/require`),
  - `pin provider` para rotas criticas,
  - fallback chain por `task_type`,
  - modo `no-fallback` para rotas sensiveis,
  - modo tool-calling confiavel (exacto/preferido quando disponivel).
- `B0-10` implementar entidade `presets` para governanca central de roteamento.
- `B0-11` implementar memory plane vetorial hibrido unico para IA:
  - `model_catalog`, `llm_runs`, `router_decisions`, `eval_aggregates`, `credits_snapshots`.
- `B0-12` implementar ingestao de metadados de run (`requested/effective model/provider`, usage, fallback, erros, outcome).
- `B0-13` implementar Budget Governor por creditos OpenRouter:
  - coleta de `credits_snapshots`,
  - limites por run/task/dia,
  - circuit breaker de custo.
- `B0-14` implementar politica de privacidade e retencao:
  - classificacao `public/internal/sensitive`,
  - provider allowlist por task_type,
  - politica ZDR para `sensitive`,
  - prompt storage minimizado (hash + resumo sanitizado por padrao).
- `B0-15` implementar harness executavel de evals com comando unico (`make eval-gates` ou equivalente).
- `B0-16` implementar CI gates no GitHub Actions para claims centrais, allowlists, privacidade e roteamento.
- `B0-17` implementar adapter de eventos Slack:
  - normalizacao de `@mention` para `task_event` com `idempotency_key`,
  - deduplicacao por evento/coalescing key,
  - mapeamento de thread para `issue_id`/`microtask_id`,
  - sem bypass de gates `R2/R3`.
- `B0-18` implementar fallback HITL Slack + task automatica de recuperacao Telegram:
  - validar assinatura HMAC + anti-replay,
  - aplicar o mesmo challenge de segundo fator,
  - abrir incidente/task `RESTORE_TELEGRAM_CHANNEL` quando fallback for acionado.
- `B0-19` preencher e validar `OPERATORS.yaml` para fallback HITL:
  - `slack_user_ids` e `slack_channel_ids` nao vazios para operador habilitado,
  - pelo menos 1 `backup_operator` habilitado para capital real.

### DoD Fase 0
- 7 dias de operacao estavel.
- uptime operacional >= 99.0% no piloto.
- reboot sem corrupcao de estado.
- decisions aprovam/rejeitam corretamente.
- wake-up por mention funcional.
- standup diario entregue de forma consistente.
- taxa de falha de tarefa < 10% por hora.
- delay de heartbeat p95 <= 5 minutos vs agenda.
- MTTR <= 30 minutos para incidente operacional.
- backlog envelhecido (>24h) <= 10 tarefas abertas.
- custo cloud dentro do baseline aprovado.
- 100% dos claims centrais com eval gate definido e executado.
- roteamento explicavel por run (`requested/effective` + motivo).
- nenhum fluxo `sensitive` sem allowlist/ZDR configurado.
- workflow GitHub Actions de gates obrigatorios verde por 7 dias.

## Fase 1 - Trading (alto risco)
- Pipeline: backtest -> paper/sandbox -> micro-live -> escala gradual.
- Integracao Binance Spot + Freqtrade em sandbox isolado.
- Escopo de ativos da fase: `crypto_spot` apenas.
- Guardrails obrigatorios de risco e kill switch.
- Aprovar entrada e mudancas em live somente via decision + checkpoint humano.
- Suite de validacao de trading executavel obrigatoria antes de live.
- Operar com `capital_ramp_level=L0` por default e evoluir nivel somente por decision.
- estrategia de framework:
  - `TradingAgents` como engine primaria de sinal.
  - `AgenticTrading` ainda nao substitui backbone na Fase 1.

### Backlog Fase 1 (trading conservador)
- `B1-01` integrar adapter de `TradingAgents` com contrato `signal_intent` canonico.
- `B1-02` implementar `signal_normalizer` + deduplicacao + trace de origem do engine.
- `B1-03` bloquear tecnicamente caminho de ordem direta de framework externo para exchange.
- `B1-04` habilitar `single_engine_mode` (degradacao segura) para falha de engine secundaria/auxiliar.
- `B1-05` reforcar `pre_trade_validator` com `capital_ramp_level` por simbolo.
- `B1-06` validar idempotencia de ordem (`client_order_id`) e reconciliacao em falha parcial.
- `B1-07` implementar `fail_closed` para falha de engine primaria de sinal.
- `B1-08` implementar runbook/automacao de degradacao com posicao aberta (`TRADING_BLOCKED`, `position_snapshot`, reconciliacao).
- `B1-09` formalizar credenciais de trading live com politica sem saque + IP allowlist.
- `B1-10` versionar contratos `execution_gateway` e `pre_trade_validator` com validacao automatica.
- `B1-11` habilitar allowlist de dominios de venue (Binance fase 1) e teste de bloqueio para dominio nao permitido.
- `B1-12` tornar `make eval-trading` gate obrigatorio em CI para mudancas de trading.
- `B1-13` formalizar estagio `S0 - paper/sandbox` com evidencias obrigatorias e bloqueio de ordem real.
- `B1-14` habilitar modo assistido humano por ordem de entrada na janela inicial de `S1`.
- `B1-15` definir criterios objetivos de promocao `S1 -> S2` (30 dias, sem `SEV-1/SEV-2`, sem violacao hard).

### DoD Fase 1
- gating de enablement totalmente verde.
- zero falhas de auditoria em execucao critica.
- incidentes criticos abaixo de threshold.
- latencia e custo dentro do SLA aprovado.
- suite hard-risk de trading com aprovacao 100% nos cenarios bloqueantes.
- gate de capital real verde por 7 dias consecutivos.
- estagio `S0` concluido e auditado antes da primeira ordem real.

## Fase 2 - Expansao
- Novas verticais e escritorios com padrao unico de governanca.
- Dashboard opcional alem do Telegram.
- Migracao para microservices apenas com sinais objetivos persistentes.
- evolucao trading por modulos seletivos de `AgenticTrading` (risco/custo/portfolio) apenas com ganho comprovado e decision.
- expansao trading para multiativos (`equities_br`, `fii_br`, `fixed_income_br`) com enablement por classe.

### Backlog Fase 2 (trading multiativos)
- `B2-01` definir schema canonico de `asset_profile` por classe de ativo.
- `B2-02` implementar adapters de venue por classe no `execution_gateway` (sem bypass de risco/auditoria).
- `B2-03` estender `pre_trade_validator` para calendario de mercado, lote/tick/notional e custos por classe.
- `B2-04` criar suites `eval-trading-<asset_class>` com cenarios hard-risk bloqueantes.
- `B2-05` implantar `shadow_mode` por classe com criterio de promote para live.

### DoD Fase 2
- novas verticais operando sem violacao de politica.
- isolamento de dados entre empresas validado.
- thresholds de saude e custo mantidos por 30 dias.

## Marcos
- M0: estrutura documental normativa completa.
- M1: Mission Control MVP em producao controlada.
- M2: trading habilitado por criterios formais.
- M3: primeira vertical de baixo risco alem da principal.
- M4: escalonamento com governanca sem regressao.

## Links Relacionados
- [PRD Master](./PRD-MASTER.md)
- [Changelog](./CHANGELOG.md)
- [ARC Model Routing](../ARC/ARC-MODEL-ROUTING.md)
- [System Health Thresholds](../EVALS/SYSTEM-HEALTH-THRESHOLDS.md)
- [Decision Protocol](../PM/DECISION-PROTOCOL.md)
- [Dev CI Rules](../DEV/DEV-CI-RULES.md)
