---
doc_id: "ARC-HEARTBEAT.md"
version: "1.1"
status: "active"
owner: "Marvin"
last_updated: "2026-02-24"
rfc_refs: ["RFC-001", "RFC-030", "RFC-050"]
---

# ARC Heartbeat

## Objetivo
Definir politica de heartbeat e wake-up para equilibrar custo, responsividade e consistencia operacional.

## Escopo
Inclui:
- intervalo base e perfis por papel
- algoritmo de heartbeat em passos
- gatilhos event-driven de wake-up

Exclui:
- implementacao de cron provider especifico
- tuning de contexto por agente individual

## Regras Normativas
- [RFC-050] MUST registrar heartbeat com timestamp e estado do agente.
- [RFC-030] MUST acionar wake-up por evento sem aguardar janela periodica.
- [RFC-001] SHOULD manter politicas de periodicidade consistentes entre escritorios.
- [RFC-030] MUST usar baseline unico de 15 minutos para cadencia periodica.
- [RFC-050] MUST executar ciclo noturno de extracao de memoria diariamente.

## Intervalos Oficiais
- base global: 15 minutos.
- Dispatcher: event-driven + varredura periodica a cada 15 minutos.
- Workers: 15 minutos.
- Risk/Compliance: 15 minutos.
- Standup diario: 11:30 no fuso -03 (America/Sao_Paulo).
- Nightly extraction de memoria: 23:00 no fuso -03 (America/Sao_Paulo).

## Contrato Auditavel do Ciclo Noturno
- job_name: "nightly-extraction"
- scheduled_at: timestamp ISO-8601 da agenda da execucao.
- executed_at: timestamp ISO-8601 do inicio efetivo da execucao.
- daily_note_ref: arquivo diario atualizado em `workspaces/main/memory/YYYY-MM-DD.md`.
- status: `success|failed|delayed|skipped`.
- incident_ref: obrigatorio quando `status=failed` ou atraso maior que 24h.

## Algoritmo de Heartbeat
1. carregar contexto minimo (`working.md`, tasks abertas, mentions pendentes).
2. verificar prioridade/SLA e bloqueios.
3. executar acao ou registrar "Heartbeat OK" com motivo.
4. publicar resumo no `activity_feed`.
5. voltar para sleep ate proximo tick ou evento.

## Gatilhos de Wake-up
- mention direta em tarefa.
- nova task atribuida.
- decision pendente com timeout proximo.
- alerta de threshold (custo/latencia/falha).
- incidente com severidade alta.

## Regras de Custo
- tarefas sem evento SHOULD usar contexto reduzido.
- agentes ociosos MAY aumentar janela dentro do limite de papel.
- loop de wake-up sem progresso MUST abrir task de diagnostico.
- processos longos em tmux/loop MUST ser checados a cada heartbeat e relancados quando `stalled`.

## Contrato Operacional para Jobs Longos
- baseline de autonomia para sessao isolada (`tmux` ou equivalente):
  - `stalled_threshold_checks: 2`
  - `incident_on_stalled: true`
- health-check periodico MUST registrar `trace_id` em cada restart controlado.
- restart MUST preservar referencia da Issue e estado do DAG antes de retomar execucao.

## Links Relacionados
- [ARC Core](./ARC-CORE.md)
- [ARC Observability](./ARC-OBSERVABILITY.md)
- [Decision Protocol](../PM/DECISION-PROTOCOL.md)
