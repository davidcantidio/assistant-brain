---
doc_id: "ARC-CORE.md"
version: "1.0"
status: "active"
owner: "Marvin"
last_updated: "2026-02-18"
rfc_refs: ["RFC-001", "RFC-020", "RFC-030", "RFC-035", "RFC-050"]
---

# ARC Core

## Objetivo
Definir a arquitetura operacional do Mission Control, incluindo componentes, schema minimo, ciclo de tarefa e mecanismos de escalacao.

## Escopo
Inclui:
- componentes nucleares (runtime, Convex, Telegram, sandbox)
- schema minimo de colecoes de controle
- lifecycle completo task -> artifact -> validacao -> review -> done

Exclui:
- implementacao de codigo especifica de provider
- detalhes de UI alem do necessario para operacao

## Regras Normativas
- [RFC-020] MUST receber demandas inter-escritorios somente via Work Order valido.
- [RFC-030] MUST aplicar model routing por classe de tarefa.
- [RFC-035] MUST suportar degraded mode com reconcilicao.
- [RFC-050] MUST registrar trilha de auditoria ponta a ponta.
- [RFC-020] MUST operar contratos versionados para `work_order`, `decision` e `task_event`.
- [RFC-050] MUST manter logs tamper-evident para eventos e incidentes criticos.

## Componentes do Sistema Nervoso
- OpenClaw runtime: execucao de agentes e rotinas.
- Convex: estado compartilhado, feed em tempo real e persistencia operacional.
- Telegram bot: HITL para approve/reject/kill e alertas.
- Execution sandbox: ambiente restrito para scripts e validacoes deterministicas.

## Schema Minimo (Convex)
- `agents`: id, name, role, status, last_seen_at, meta
- `tasks`: id, title, description, status, priority, assigned_to, created_at, updated_at
- `comments`: id, task_id, author, body, created_at
- `mentions`: id, task_id, target_agent, created_at, resolved_at
- `decisions`: id, title, proposal, status, requested_by, decided_by, created_at, decided_at
- `task_events`: event_id, task_id, event_type, actor, payload, created_at, trace_id, idempotency_key, event_hash, prev_event_hash
- `activity_feed`: id, type, actor, payload, created_at
- `artifacts`: id, task_id, type, content_or_uri, created_at

## Fonte Canonica de Estado Operacional (MVP)
- memoria operacional: `workspaces/main/memory/`.
- estado de workspace: `workspaces/main/.openclaw/workspace-state.json`.
- `memory/` na raiz e apenas ponteiro informativo (nao operacional).

## Contratos Criticos Versionados
- `work_order`:
  - campos obrigatorios: `schema_version`, `work_order_id`, `idempotency_key`, `risk_class`, `sla_class`, `budget`, `expected_output`.
- `decision`:
  - campos obrigatorios: `schema_version`, `decision_id`, `risk_class`, `status`, `created_at`, `timeout_at`.
- `task_event`:
  - campos obrigatorios: `schema_version`, `event_id`, `task_id`, `event_type`, `actor`, `created_at`, `trace_id`, `idempotency_key`, `event_hash`, `prev_event_hash`.
- qualquer payload sem `schema_version` MUST ser rejeitado na borda.
- qualquer `task_event` sem `idempotency_key` MUST ser rejeitado no ingest.
- `event_hash` MUST ser calculado sobre payload canonico para detectar adulteracao.

## Lifecycle Operacional
1. Entrada: Work Order criado e validado.
2. Dispatch: roteador classifica risco, SLA, budget e classe de tarefa.
3. Execucao: agente local produz artifact auditavel.
4. Validacao: checks deterministicas (schema/lint/test/policy).
5. Review: cloud/humano conforme risco.
6. Encerramento: `DONE`, log de custo, metrica e evidencia.

## Dispatcher / Roteador
- Entrada: objetivo, risco, SLA, budget, permissoes de RAG, criterios de aceite.
- Saida: plano de execucao (modelo, fallback ladder, validacoes, gate de aprovacao).
- MUST registrar decisao de roteamento com justificativa.

## Circuit Breaker e Escalation
- Disparos: erro repetido, latencia estourada, budget estourado, violacao de policy.
- Acao: pausar tarefa, abrir incident/task, escalar para cloud/humano.
- Retorno: so retoma apos criterio de recuperacao atendido.

## Links Relacionados
- [Model Routing](./ARC-MODEL-ROUTING.md)
- [Degraded Mode](./ARC-DEGRADED-MODE.md)
- [Observability](./ARC-OBSERVABILITY.md)
- [Work Order Spec](../PM/WORK-ORDER-SPEC.md)
