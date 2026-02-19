---
doc_id: "ARC-OBSERVABILITY.md"
version: "1.0"
status: "active"
owner: "Frederisk"
last_updated: "2026-02-18"
rfc_refs: ["RFC-001", "RFC-030", "RFC-050"]
---

# ARC Observability

## Objetivo
Definir metricas obrigatorias, thresholds e acoes automaticas para manter saude operacional e previsibilidade de custo/qualidade.

## Escopo
Inclui:
- metricas de tempo, custo, fallback, retrabalho e disponibilidade
- dashboards minimos e alertas
- automacoes para abrir task/decision

Exclui:
- stack especifica de visualizacao
- tuning de threshold por time sem registro normativo

## Regras Normativas
- [RFC-050] MUST registrar metricas por tarefa, empresa, classe e decisao.
- [RFC-030] MUST monitorar p50/p95 por classe de task.
- [RFC-050] MUST abrir task automatica ao estourar threshold operacional.
- [RFC-001] SHOULD revisar thresholds em ciclo semanal com changelog.

## Metricas Obrigatorias
- tempo por etapa (inbox -> assigned -> in_progress -> review -> done)
- custo por tarefa, empresa, sprint e decision
- taxa de fallback por classe de tarefa
- taxa de rejeicao/retrabalho por origem (local/cloud/humano)
- saude do sistema: uptime, atraso de heartbeat, fila acumulada

## Thresholds e Acoes
| Metrica | Threshold | Acao automatica |
|---|---|---|
| Latencia p95 | > 2x SLA da classe por 30 min | abrir task de tuning + reduzir carga |
| Custo diario | > 90% do teto diario | abrir decision de budget + fallback agressivo |
| Falha de validacao | > 15% por sprint | bloquear merge automatico e abrir task raiz |
| Fallback em cascata | > 3 por tarefa | escalar para cloud/humano |
| Heartbeat atrasado | > 2 ciclos | abrir incident e notificar Telegram |

## Dashboards Minimos
- Operacao: fila, SLA, retries, throughput.
- Financeiro: custo por empresa e projeção mensal.
- Qualidade: retrabalho, rejeicao, erro por classe.
- Confiabilidade: uptime, degraded mode, tempo de recuperacao.

## Integracao com PM/INCIDENTS
- threshold critico MUST abrir task com owner e prazo.
- violacao repetida MUST abrir decision de mudanca estrutural.
- incidente severo MUST entrar no log oficial.

## Links Relacionados
- [System Health Thresholds](../EVALS/SYSTEM-HEALTH-THRESHOLDS.md)
- [Incident Log Policy](../INCIDENTS/INCIDENT-LOG-POLICY.md)
- [Financial Governance](../CORE/FINANCIAL-GOVERNANCE.md)
