---
doc_id: "ARC-CORE.md"
version: "1.5"
status: "active"
owner: "Marvin"
last_updated: "2026-02-20"
rfc_refs: ["RFC-001", "RFC-020", "RFC-030", "RFC-035", "RFC-050"]
---

# ARC Core

## Objetivo
Definir a arquitetura operacional do Mission Control com OpenRouter como gateway de inferencia, Model Router central e memoria vetorial hibrida auditavel.

## Escopo
Inclui:
- componentes nucleares (runtime, Convex, OpenRouter, Telegram, Slack, sandbox, LLM local)
- plano de dados do control-plane
- plano de memoria vetorial para catalogo/runs/roteamento
- lifecycle task -> routing -> execucao -> validacao -> observabilidade

Exclui:
- detalhes de UI alem do necessario para operacao
- implementacao de provider especifico fora da camada OpenRouter

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
- Convex: estado compartilhado e feed operacional.
- OpenRouter gateway: endpoint unico programatico para inferencia LLM.
- Worker LLM local: execucao de microtasks pesadas e nao urgentes em host compativel (preferencia: Mac >= 32 GB RAM).
- Model Catalog Service: sync e versionamento de metadados de modelos.
- Model Router: selecao de modelo/provider/fallback por task_type/risco/custo/confiabilidade.
- Strategy engine adapters: integracao controlada de engines externas (TradingAgents primario; AgenticTrading modular) para gerar `signal_intent`.
- Telegram bot: HITL para approve/reject/kill e alertas.
- Slack adapter: colaboracao operacional e fallback controlado para HITL quando Telegram cair.
- Execution sandbox: ambiente restrito para scripts e validacoes deterministicas.

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
  - `model_id`, `openrouter_model_id`, `provider_variants`, `pricing`, `limits`, `supported_parameters`, `capabilities`, `tags`, `status`, `version`, timestamps
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

### 3) `router_decisions`
- estruturado:
  - constraints de entrada
  - candidatos considerados
  - ranking e score
  - decisao final e justificativa curta
  - fallback chain acionada e motivo

### 4) `eval_aggregates`
- estruturado:
  - `task_type`, `model_id`, `provider`, janela temporal
  - `success_rate`, `tool_success_rate`, `parse_rate`, `retry_rate`, `timeout_rate`
  - `cost_per_success`, `latency_p95`

### 5) `credits_snapshots`
- estruturado:
  - `snapshot_at`, `total_credits`, `total_usage`, `balance`, `burn_rate_hour`, `burn_rate_day`

### 6) `router_presets`
- estruturado:
  - `preset_id`, `task_type`, `policy_version`, `provider_routing`, `generation_defaults`, `fallback_chain`, `no_fallback`, `pin_provider`, `exacto_mode`

## Fonte Canonica de Estado Operacional (MVP)
- memoria operacional de workspace:
  - `workspaces/main/memory/`
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
4. Execucao: chamada OpenRouter com log de requested/effective.
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
- OpenRouter indisponivel:
  - MUST aplicar fallback chain permitida por policy;
  - se `no-fallback`, MUST bloquear e abrir incident.
- Telegram indisponivel:
  - com fallback Slack validado, MUST ativar fallback para comandos HITL criticos (mesmo auth/challenge/gates).
  - sem fallback Slack validado, MUST registrar `human_action_required.md`, manter backlog de comandos criticos e operar trading em `TRADING_BLOCKED`.

## Links Relacionados
- [ARC Model Routing](./ARC-MODEL-ROUTING.md)
- [ARC Observability](./ARC-OBSERVABILITY.md)
- [ARC Degraded Mode](./ARC-DEGRADED-MODE.md)
- [Work Order Spec](../PM/WORK-ORDER-SPEC.md)
- [Financial Governance](../CORE/FINANCIAL-GOVERNANCE.md)
