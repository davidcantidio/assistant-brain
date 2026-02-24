---
doc_id: "ROADMAP.md"
version: "2.2"
status: "active"
owner: "PM"
last_updated: "2026-02-24"
rfc_refs: ["RFC-001", "RFC-010", "RFC-015", "RFC-020", "RFC-030", "RFC-035", "RFC-040", "RFC-050", "RFC-060"]
---

# Roadmap

## Objetivo
Definir fases, milestones e criterios objetivos de saida para evolucao do OpenClaw Agent OS com OpenClaw gateway-first + Model Router + memoria vetorial hibrida sob controle de risco.

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
- gateway LLM programatico padrao: OpenClaw Gateway (`bind=loopback`); providers cloud entram por adaptador plugavel.
- OpenRouter e adaptador cloud opcional, permanece desabilitado por default e so pode ser habilitado por decision formal; quando cloud adicional estiver habilitado, OpenRouter e o preferido.
- Telegram bot com `/approve`, `/reject`, `/kill` e standup diario 11:30 (-03).
- Model Catalog + Model Router + Memory Plane + Budget + Privacidade entram em baseline minimo na Fase 0.
- refinos avancados desses blocos sao diferidos para Fase 1/2 sem perda de escopo.
- Routing MVP limitado a 3 classes: Dispatcher, RAG Librarian (empresa), Dev Junior.

### Backlog de construcao de codigo (obrigatorio na Fase 0 - baseline)
- `B0-01` implementar contratos `work_order`, `decision`, `task_event` com validacao de schema.
- `B0-02` implementar bot Telegram com autenticacao forte (`from.id` + `chat.id` + challenge).
- `B0-03` implementar lifecycle completo do challenge HITL.
- `B0-04` implementar enforcement idempotente e rollback para `SPRINT_OVERRIDE`.
- `B0-05` implementar contrato idempotente para auto-acoes de saude/observabilidade.
- `B0-06` implementar reconciliador de degraded mode (`idempotency_key` + `replay_key`).
- `B0-07` implementar contrato do OpenClaw Gateway:
  - `bind=loopback`,
  - endpoint `chatCompletions` opcional sob policy,
  - adaptador cloud plugavel (OpenRouter preferido somente quando cloud adicional estiver habilitado por decision formal).
- `B0-08` implementar Model Catalog baseline:
  - sync de Models API,
  - metadados minimos para roteamento (`model_id`, provider, capabilities, limits, pricing, status).
- `B0-09` implementar Model Router baseline:
  - filtro por policy/risk/sensitivity,
  - ranking baseline (`capabilities-first`),
  - trilha obrigatoria `requested/effective`.
- `B0-11` implementar Memory Plane baseline:
  - `llm_runs`, `router_decisions`, `credits_snapshots`.
- `B0-13` implementar Budget Governor baseline:
  - coleta de `credits_snapshots`,
  - limites por run/task/dia.
- `B0-14` implementar privacidade baseline:
  - classificacao `public/internal/sensitive`,
  - provider allowlist por sensibilidade,
  - prompt storage minimizado (hash + resumo sanitizado por padrao).
- `B0-15` implementar harness executavel de evals com comando unico (`make eval-gates` ou equivalente).
- `B0-16` implementar CI gates no GitHub Actions para claims centrais, allowlists, privacidade e roteamento.
- `B0-17` implementar contrato A2A baseline:
  - `tools.agentToAgent.enabled`,
  - `tools.agentToAgent.allow[]`,
  - trilha de delegacao com `trace_id`.
- `B0-18` implementar contrato de hooks/webhooks baseline:
  - `hooks.enabled`,
  - `hooks.mappings[]` com transform tipada,
  - `hooks.internal.entries[]` (`boot-md`, `command-logger`, `session-memory`).
- `B0-19` preencher e validar `OPERATORS.yaml` baseline:
  - IDs Telegram validados para aprovacao critica,
  - estrategia de `backup_operator` definida e rastreada.
- `B0-20` implementar `memory_contract` baseline:
  - `workspaces/main/MEMORY.md`,
  - `workspaces/main/memory/YYYY-MM-DD.md`,
  - cron `nightly-extraction` obrigatorio.
- `B0-21` implementar `approval_policy` baseline:
  - `financial_side_effect_requires_explicit_human_approval=true`,
  - `email_command_channel_trusted=false`.

### DoD Fase 0
- 7 dias de operacao estavel.
- uptime operacional >= 99.0% no piloto.
- reboot sem corrupcao de estado.
- decisions aprovam/rejeitam corretamente.
- wake-up por evento funcional nos canais habilitados da fase.
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
- Toda ordem com side effect financeiro exige aprovacao humana explicita por ordem + decision/checkpoint humano.
- Suite de validacao de trading executavel obrigatoria antes de live.
- Operar com `capital_ramp_level=L0` por default e evoluir nivel somente por decision.
- estrategia de framework:
  - `TradingAgents` como engine primaria de sinal.
  - `AgenticTrading` ainda nao substitui backbone na Fase 1.

### Backlog Fase 1 (trading conservador)
- `B1-01` integrar adapter de `TradingAgents` com contrato `signal_intent` canonico.
- `B1-02` implementar `signal_normalizer` + deduplicacao + trace de origem do engine.
- `B1-03` bloquear tecnicamente caminho de ordem direta de framework externo para exchange.
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
- `B1-20` criar pacote normativo `INTEGRATIONS/` para AI-Trader, ClawWork e OpenClaw upstream com template obrigatorio (objetivo, modo permitido, contratos, riscos, testes e rollback).
- `B1-21` adicionar contratos versionados em `ARC/schemas/` (`signal_intent`, `order_intent`, `execution_report`, `economic_run`) e gate `make eval-integrations`.
- `B1-22` formalizar AI-Trader em modo `signal_only`, com bloqueio explicito de qualquer caminho de ordem direta para venue.
- `B1-23` formalizar ClawWork com modos `lab_isolated` (default) e `governed` (gateway-only + policy), incluindo politica de dados para E2B.
- `B1-24` formalizar matriz de compatibilidade do runtime com OpenClaw upstream (`gateway.control_plane.ws` canonico + `chatCompletions` opcional sob policy).

### Refinos diferidos da Fase 0 (sem perda de informacao)
- `B1-R08` (origem `B0-08`) expandir Model Catalog:
  - versionamento de preco/capabilities/limites/supported parameters.
- `B1-R09` (origem `B0-09`) expandir Model Router:
  - provider routing (`include/exclude/order/require`),
  - `pin provider` para rotas criticas,
  - fallback chain por `task_type`,
  - modo `no-fallback` para rotas sensiveis,
  - modo tool-calling confiavel (exacto/preferido quando disponivel).
- `B1-R10` (origem `B0-10`) implementar entidade `presets` para governanca central de roteamento.
- `B1-R11` (origem `B0-11`) expandir memory plane vetorial hibrido:
  - `model_catalog`, `eval_aggregates` e embeddings operacionais.
- `B1-R12` (origem `B0-12`) implementar ingestao completa de metadados de run (`requested/effective model/provider`, usage, fallback, erros, outcome).
- `B1-R13` (origem `B0-13`) expandir Budget Governor:
  - circuit breaker de custo e politicas de burn-rate.
- `B1-R14` (origem `B0-14`) expandir privacidade/retencao:
  - ZDR por task_type `sensitive` e politicas de retention detalhadas.
- `B1-R16` (origem `B0-17`) expandir A2A:
  - delegacao cross-workspace com allowlist por papel,
  - limites por concorrencia e custo,
  - fallback para fila serial em conflito.
- `B1-R17` (origem `B0-18`) implementar adapter de eventos Slack:
  - normalizacao de `@mention` para `task_event` com `idempotency_key`,
  - deduplicacao por evento/coalescing key,
  - mapeamento de thread para `issue_id`/`microtask_id`,
  - sem bypass de gates `R2/R3`.
- `B1-R18` (origem `B0-18`) implementar fallback HITL Slack + task automatica de recuperacao Telegram:
  - validar assinatura HMAC + anti-replay,
  - aplicar o mesmo challenge de segundo fator,
  - abrir incidente/task `RESTORE_TELEGRAM_CHANNEL` quando fallback for acionado.
- `B1-R19` (origem `B0-19`) concluir prontidao de fallback HITL Slack:
  - `slack_user_ids` e `slack_channel_ids` nao vazios para operador habilitado,
  - `backup_operator` habilitado para capital real.

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

### Refinos diferidos da Fase 1 (sem perda de informacao)
- `B2-R04` (origem `B1-04`) habilitar `single_engine_mode` (degradacao segura) para falha de engine secundaria/auxiliar.
- `B2-R15` (origem `B1-15`) definir criterios objetivos de promocao `S1 -> S2` (30 dias, sem `SEV-1/SEV-2`, sem violacao hard).

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
- [Integrations](../INTEGRATIONS/README.md)
- [System Health Thresholds](../EVALS/SYSTEM-HEALTH-THRESHOLDS.md)
- [Decision Protocol](../PM/DECISION-PROTOCOL.md)
- [Dev CI Rules](../DEV/DEV-CI-RULES.md)
