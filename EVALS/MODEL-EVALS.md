---
doc_id: "MODEL-EVALS.md"
version: "1.0"
status: "active"
owner: "Frederisk"
last_updated: "2026-02-18"
rfc_refs: ["RFC-001", "RFC-030", "RFC-050"]
---

# Model Evals

## Objetivo
Definir como avaliar troca de modelo/quantizacao com rollout seguro, evitando regressao de qualidade ou custo.

## Escopo
Inclui:
- protocolo de benchmark funcional e operacional
- estrategia de rollout gradual
- thresholds de regressao e rollback

Exclui:
- troca de modelo em producao sem teste
- mudanca estrutural sem baseline

## Regras Normativas
- [RFC-030] MUST avaliar modelo por classe de tarefa e SLA alvo.
- [RFC-050] MUST comparar qualidade, custo, latencia e falha vs baseline.
- [RFC-030] MUST executar rollout gradual antes de adocao total.
- [RFC-050] MUST acionar rollback ao ultrapassar threshold de regressao.
- [RFC-050] MUST atualizar o gate de claim central correspondente apos qualquer troca de modelo.

## Protocolo de Avaliacao
1. definir baseline atual por classe.
2. executar suite offline controlada.
3. comparar metricas principais.
4. pilotar em trafego parcial (10% -> 25% -> 50% -> 100%).
5. consolidar decisao de adocao.

## Metricas Minimas
- qualidade (pass@criteria por classe).
- latencia p50/p95.
- custo por tarefa.
- taxa de fallback/retry.
- taxa de rejeicao humana/cloud.

## Regras de Rollback
- regressao de qualidade > 5 pontos.
- latencia p95 > 2x SLA.
- custo > 20% sem ganho proporcional.
- incidente critico associado ao novo modelo.

## Links Relacionados
- [ARC Model Routing](../ARC/ARC-MODEL-ROUTING.md)
- [System Health Thresholds](./SYSTEM-HEALTH-THRESHOLDS.md)
- [Decision Protocol](../PM/DECISION-PROTOCOL.md)
