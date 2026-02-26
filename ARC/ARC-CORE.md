---
doc_id: "ARC-CORE.md"
version: "2.1"
status: "active"
owner: "Marvin"
last_updated: "2026-02-26"
rfc_refs: ["RFC-001", "RFC-020", "RFC-030", "RFC-035", "RFC-050", "RFC-060"]
---

# ARC Core

## Objetivo
Definir a arquitetura operacional do Mission Control com OpenClaw gateway-first, Model Router central e memoria vetorial hibrida auditavel.

## Escopo
Inclui:
- componentes nucleares (runtime, Convex, OpenClaw Gateway, providers cloud plugaveis, Telegram/Slack/Discord/Signal/iMessage, sandbox, LLM local)
- plano de dados do control-plane
- plano de memoria vetorial para catalogo/runs/roteamento
- lifecycle task -> routing -> execucao -> validacao -> observabilidade

Exclui:
- detalhes de UI alem do necessario para operacao
- implementacao de provider especifico fora da camada de adapters do gateway OpenClaw

## Regras Normativas
- [RFC-020] MUST receber demandas inter-escritorios somente via Work Order valido.
- [RFC-030] MUST aplicar model routing por classe de tarefa e policy.
- [RFC-035] MUST suportar degraded mode com reconciliacao.
- [RFC-050] MUST registrar trilha de auditoria ponta a ponta.
- [RFC-020] MUST operar contratos versionados para `work_order`, `decision` e `task_event`.
- [RFC-050] MUST manter memoria vetorial hibrida com dados estruturados e embeddings no mesmo storage.

## Planos de Sistema
- `Control Plane` (tempo real):
  - Convex + runtime + adapters Telegram/Slack.
  - foco: estado operacional e workflow humano.
- `Memory Plane` (IA + analytics):
  - Postgres + pgvector (ou equivalente funcional).
  - foco: metadados de modelo, historico de execucao, decisoes de roteamento, agregados e creditos.
  - MUST suportar consultas estruturadas (filtros, joins, agregacoes) e busca semantica por embeddings no mesmo plano de dados.

## Componentes do Sistema Nervoso
- OpenClaw runtime: execucao de agentes e rotinas.
- OpenClaw Gateway: endpoint unico do runtime para chamadas LLM e eventos operacionais.
- Convex: estado compartilhado e feed operacional.
- LiteLLM supervisor adapter (padrao): aliases de supervisores pagos (`codex-main`, `claude-review`) e contabilizacao de uso.
- OpenRouter adapter (opcional/desabilitado por default): habilitacao somente por decision explicita; quando cloud adicional estiver habilitado, OpenRouter e o preferido.
- Worker LLM local: execucao de microtasks pesadas e nao urgentes em host compativel (preferencia: Mac >= 32 GB RAM).
- Model Catalog Service: sync e versionamento de metadados de modelos.
- Model Router: selecao de modelo/provider/fallback por task_type/risco/custo/confiabilidade.
- Strategy engine adapters: integracao controlada de engines externas (TradingAgents primario; AgenticTrading modular) para gerar `signal_intent`.
- Telegram bot: HITL para approve/reject/kill e alertas.
- Slack adapter: colaboracao operacional e fallback controlado para HITL quando Telegram cair.
- adapters de canal opcionais: Discord/Signal/iMessage (habilitacao por allowlist/policy).
- Execution sandbox: ambiente restrito para scripts e validacoes deterministicas.

## Contratos de Roteamento por Papel
- `routing_stack_contract`:
  - `gateway.primary=openclaw`
  - `gateway.supervisor_adapter=litellm`
  - `gateway.cloud_optional=disabled`
- `supervisor_contract`:
  - `primary=litellm/codex-main`
  - `secondary=litellm/claude-review`
  - aplicacao: aprovacao, critica, correcao, delegacao e revisao de risco.
- `local_worker_contract`:
  - `workers.local.code=ollama/qwen2.5-coder:32b`
  - `workers.local.reason=ollama/deepseek-r1:32b`
  - regra: local-first para tarefa bracal, com escalonamento por gates de capacidade.
- `fallback_contract`:
  - ordem default: `local_worker -> claude-review -> codex-main`
  - logging obrigatorio: `requested_model`, `effective_model`, `fallback_step`, `reason`.

## Contrato Minimo de Runtime (`openclaw_runtime_config`)
- concorrencia:
  - `agents.defaults.maxConcurrent`
  - `agents.defaults.subagents.maxConcurrent`
- delegacao A2A:
  - `tools.agentToAgent.enabled`
  - `tools.agentToAgent.allow[]`
- canais:
  - `channels.telegram`, `channels.slack`, `channels.discord`, `channels.signal`, `channels.imessage`
- hooks:
  - `hooks.enabled`
  - `hooks.mappings[]` (webhooks externos)
  - `hooks.internal.entries[]` (`boot-md`, `command-logger`, `session-memory`)
- memoria:
  - `memory.backend=qmd`
  - `memory.qmd.paths[]`
  - `memory.qmd.update.interval`
- gateway:
  - `gateway.bind=loopback`
  - `gateway.control_plane.ws` (canonico)
  - `gateway.http.endpoints.chatCompletions.enabled` (opcional sob policy)

## Delegacao A2A (Agent-to-Agent)
- delegacao entre agentes MUST obedecer allowlist `tools.agentToAgent.allow[]`.
- agente solicitante MUST registrar `trace_id`, `delegation_id`, `requester_agent`, `target_agent`.
- resposta A2A MUST registrar estado final (`succeeded|failed|blocked`) e evidence refs.
- delegacao fora de allowlist MUST falhar com bloqueio + evento de seguranca.
- contrato executavel: `ARC/schemas/a2a_delegation_event.schema.json`.

## Hooks e Webhooks
- webhook externo MUST entrar por mapping explicito em `hooks.mappings[]`.
- mapping MUST transformar payload externo em evento interno tipado antes de entrar no Orchestrator.
- hooks internos MUST carregar contexto (`boot-md`), trilha de comando (`command-logger`) e memoria de sessao (`session-memory`).
- hooks sem assinatura/validacao de origem exigida por policy MUST ser bloqueados.
- contrato executavel: `ARC/schemas/webhook_ingest_event.schema.json`.

## Hardening do Gateway
- processo local MUST operar com `bind=loopback`.
- exposicao externa do gateway somente via tunel/autenticacao na borda (sem bind publico direto).
- control plane WS (`gateway.control_plane.ws`) MUST ser o endpoint canonico de orquestracao do runtime.
- endpoint `chatCompletions` MAY ser habilitado, mas com as mesmas politicas de allowlist, risco e auditoria do runtime.

## Regra de Backbone Unico (trading live)
- OpenClaw runtime MUST ser o unico backbone de producao para:
  - gate de risco,
  - aprovacao HITL,
  - emissao de ordem,
  - reconciliacao,
  - auditoria e incidentes.
- engines externas de trading MUST operar apenas como provedores de analise/sinal.
- caminho de ordem direta de framework externo para exchange MUST ser bloqueado por policy.
- falha da engine primaria de sinal em trading live MUST operar em `fail_closed` para novas entradas.

## Schema Minimo (Control Plane - Convex)
- `agents`: id, name, role, status, last_seen_at, meta
- `tasks`: id, title, description, status, priority, assigned_to, created_at, updated_at
- `comments`: id, task_id, author, body, created_at
- `mentions`: id, task_id, target_agent, created_at, resolved_at
- `decisions`: id, title, proposal, status, requested_by, decided_by, created_at, decided_at
- `task_events`: event_id, task_id, event_type, actor, payload, created_at, trace_id, idempotency_key, event_hash, prev_event_hash
- `activity_feed`: id, type, actor, payload, created_at
- `artifacts`: id, task_id, type, content_or_uri, created_at

## Schema Logico Minimo (Memory Plane Vetorial)

### 1) `model_catalog`
- estruturado:
  - `model_id`, `provider_model_ref`, `provider_variants`, `pricing`, `limits`, `supported_parameters`, `capabilities`, `tags`, `status`, `version`, timestamps
- embedding:
  - `model_card_embedding` (descricao/capabilities/model card)

### 2) `llm_runs`
- estruturado:
  - identidade: `run_id`, `trace_id`, `task_id`, `agent_id`, `session_id`
  - request: parametros, tool schemas, response_format, `prompt_hash`, `prompt_summary`
  - routing: `requested_model`, `effective_model`, `effective_provider`, `preset_id`, `fallback_step`, `retry_count`
  - response: `finish_reason`, tool calls, parse/validation status
  - usage: tokens/custos/latencia/cache
  - erro: codigo, tipo, resumo
  - outcome: success/fail + score/flags
- embeddings:
  - `task_spec_embedding`
  - `outcome_embedding`
- contrato executavel: `ARC/schemas/llm_run.schema.json`

### 3) `router_decisions`
- estruturado:
  - constraints de entrada
  - candidatos considerados
  - ranking e score
  - decisao final e justificativa curta
  - fallback chain acionada e motivo
- contrato executavel: `ARC/schemas/router_decision.schema.json`

### 4) `eval_aggregates`
- estruturado:
  - `task_type`, `model_id`, `provider`, janela temporal
  - `success_rate`, `tool_success_rate`, `parse_rate`, `retry_rate`, `timeout_rate`
  - `cost_per_success`, `latency_p95`

### 5) `credits_snapshots`
- estruturado:
  - `snapshot_at`, `billing_source`, `period_limit`, `period_usage`, `balance`, `burn_rate_hour`, `burn_rate_day`
- contrato executavel: `ARC/schemas/credits_snapshot.schema.json`

### 6) `router_presets`
- estruturado:
  - `preset_id`, `task_type`, `policy_version`, `provider_routing`, `generation_defaults`, `fallback_chain`, `no_fallback`, `pin_provider`, `exacto_mode`

## Fonte Canonica de Estado Operacional (MVP)
- memoria operacional de workspace:
  - `workspaces/main/MEMORY.md`
  - `workspaces/main/memory/YYYY-MM-DD.md`
- estado de workspace:
  - `workspaces/main/.openclaw/workspace-state.json`
- memoria vetorial (catalogo/runs):
  - banco operacional dedicado (nao versionado em git)

## Trilha Auditavel Persistente (nao versionada)
- buffer local append-only (MVP):
  - `workspaces/main/.openclaw/audit/task_events.jsonl`
  - `workspaces/main/.openclaw/audit/decisions.jsonl`
  - `workspaces/main/.openclaw/audit/critical_actions.jsonl`
- espelhamento:
  - object storage imutavel (S3 compativel) por particao diaria.
  - modo recomendado: Object Lock (compliance) + versionamento + retention de 90 dias quente e 365 dias frio.

## Lifecycle Operacional
1. Entrada: Work Order valido.
2. Dispatch: Router avalia risco, sensibilidade, SLA, budget, capabilities.
3. Selecao: escolhe preset/model/provider e fallback chain.
4. Execucao: chamada via OpenClaw Gateway com log de requested/effective.
5. Validacao: checks deterministicas + parse/structured output.
6. Review: cloud/humano conforme risco.
7. Encerramento: `DONE` + metrica + evidencia + auditoria.

## Dispatcher / Router (contrato minimo)
- entrada:
  - `task_type`, `risk_class`, `risk_tier`, `sensitivity`, `sla_class`, `budget`, `structured_output_required`, `tools_required`
- saida:
  - `preset_id`, `requested_model`, `provider_routing`, `fallback_chain`, `decision_explain`
- MUST registrar:
  - requested vs effective model/provider,
  - motivo de fallback/retry,
  - custo previsto e custo real.

## Circuit Breaker e Escalation
- disparos:
  - erro repetido, latencia estourada, budget estourado, violacao de policy, queda de parse/tool success.
- acao:
  - degradar para preset economico,
  - bloquear tarefas nao criticas,
  - abrir task/decision/incident.

## Mitigacao de SPOF
- Convex indisponivel:
  - MUST entrar em degraded mode com fila offline local.
- adapter cloud indisponivel:
  - MUST aplicar fallback chain permitida por policy (cloud alternativo ou local, conforme risco/policy);
  - se `no-fallback`, MUST bloquear e abrir incident.
- Telegram indisponivel:
  - com fallback Slack validado, MUST ativar fallback para comandos HITL criticos (mesmo auth/challenge/gates).
  - sem fallback Slack validado, MUST registrar `human_action_required.md`, manter backlog de comandos criticos e operar trading em `TRADING_BLOCKED`.

## Links Relacionados
- [ARC Model Routing](./ARC-MODEL-ROUTING.md)
- [OpenClaw Runtime Config Schema](./schemas/openclaw_runtime_config.schema.json)
- [Integrations](../INTEGRATIONS/README.md)
- [ARC Observability](./ARC-OBSERVABILITY.md)
- [ARC Degraded Mode](./ARC-DEGRADED-MODE.md)
- [Work Order Spec](../PM/WORK-ORDER-SPEC.md)
- [Financial Governance](../CORE/FINANCIAL-GOVERNANCE.md)
