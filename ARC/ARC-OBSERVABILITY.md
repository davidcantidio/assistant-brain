---
doc_id: "ARC-OBSERVABILITY.md"
version: "1.3"
status: "active"
owner: "Frederisk"
last_updated: "2026-02-20"
rfc_refs: ["RFC-001", "RFC-030", "RFC-050"]
---

# ARC Observability

## Objetivo
Definir metricas obrigatorias, thresholds e auto-acoes para manter saude operacional, previsibilidade de custo e explicabilidade do roteamento.

## Escopo
Inclui:
- metricas de tempo, custo, fallback, retrabalho e disponibilidade
- metricas de roteamento por modelo/provider
- monitoramento de creditos e burn-rate
- contrato de idempotencia para auto-acoes

Exclui:
- stack especifica de visualizacao
- tuning informal sem registro normativo

## Regras Normativas
- [RFC-050] MUST registrar metricas por tarefa, empresa, classe e decisao.
- [RFC-030] MUST monitorar p50/p95 por task_type/model/provider.
- [RFC-050] MUST abrir task automatica ao estourar threshold operacional.
- [RFC-050] MUST manter rastreabilidade de routing decision (`requested/effective`).
- [RFC-050] MUST aplicar auto-acao somente com contrato idempotente + rollback.

## Metricas Obrigatorias
- tempo por etapa (inbox -> assigned -> in_progress -> review -> done)
- custo por tarefa, empresa, sprint e decision
- custo por sucesso (`cost_per_success`) por task_type/model/provider
- taxa de fallback por task_type/model/provider
- taxa de rejeicao/retrabalho por origem (local/cloud/humano)
- `tool_success_rate` e `parse_rate` para rotas com tools/structured output
- saude do sistema: uptime, atraso de heartbeat, fila acumulada
- creditos: `balance`, `burn_rate_hour`, `burn_rate_day`
- trading:
  - ordens fora de `execution_gateway` (deve ser 0),
  - tempo em `UNMANAGED_EXPOSURE`,
  - reconciliacao de ordem/posicao sem duplicidade.

## Dashboards Minimos
- Operacao:
  - fila, SLA, retries, throughput.
- Router:
  - requested vs effective model/provider,
  - motivos de fallback,
  - no-fallback bloqueados.
- Financeiro:
  - custo total,
  - custo por sucesso,
  - consumo de creditos e burn-rate.
- Qualidade:
  - tool_success_rate,
  - parse_rate,
  - timeout_rate.
- Confiabilidade:
  - uptime,
  - degraded mode,
  - tempo de recuperacao.

## Contrato de Auto-Acao (obrigatorio)
```yaml
schema_version: "1.2"
automation_action_id: "AUTO-UUID"
coalescing_key: "<office>:<metric>:<root_cause>"
idempotency_key: "IDEMP-UUID"
trigger_metric: "latency_p95|daily_cost|burn_rate|parse_rate|tool_success_rate|..."
trigger_value: "numero"
threshold_value: "numero"
action_type: "open_task|open_decision|notify|reduce_load|activate_degraded"
target_ref: "task://...|decision://...|incident://..."
rollback_plan_ref: "artifact://..."
created_at: "ISO-8601"
cooldown_until: "ISO-8601"
status: "CREATED|APPLIED|NO_OP_DUPLICATE|ROLLED_BACK|FAILED"
```

## Regras de Idempotencia
- mesma `coalescing_key` dentro do `cooldown_window` MUST virar `NO_OP_DUPLICATE`.
- auto-acao sem `rollback_plan_ref` MUST ser convertida para `notify-only`.
- nunca abrir mais de 1 decision por `coalescing_key` durante cooldown.
- toda auto-acao MUST emitir `task_event` com hash encadeado.

## Explicabilidade de Roteamento
- toda execucao MUST responder:
  - por que escolheu esse modelo,
  - por que escolheu esse provider,
  - qual fallback foi aplicado (ou por que bloqueou no-fallback).
- evidencia minima:
  - registro em `router_decisions` + referencia cruzada em `llm_runs`.

## Integracao com PM/INCIDENTS
- threshold critico MUST abrir task com owner e prazo.
- violacao repetida MUST abrir decision de mudanca estrutural.
- incidente severo MUST entrar no log oficial.

## Links Relacionados
- [System Health Thresholds](../EVALS/SYSTEM-HEALTH-THRESHOLDS.md)
- [Financial Governance](../CORE/FINANCIAL-GOVERNANCE.md)
- [Incident Log Policy](../INCIDENTS/INCIDENT-LOG-POLICY.md)
