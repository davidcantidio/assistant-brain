---
doc_id: "SYSTEM-HEALTH-THRESHOLDS.md"
version: "1.0"
status: "active"
owner: "Frederisk"
last_updated: "2026-02-18"
rfc_refs: ["RFC-001", "RFC-030", "RFC-050"]
---

# System Health Thresholds

## Objetivo
Definir limites operacionais de custo, latencia, falha, fallback e incidentes, com acao automatica padronizada.

## Escopo
Inclui:
- thresholds de saude do sistema
- acoes automaticas em violacao
- criterios de escalation para decision

Exclui:
- tuning manual sem registro
- ignorar alerta recorrente

## Regras Normativas
- [RFC-050] MUST monitorar thresholds continuamente.
- [RFC-050] MUST abrir task automatica em violacao.
- [RFC-030] MUST ajustar model routing ao detectar degradacao.
- [RFC-001] MUST abrir decision se violacao persistir apos mitigacao.
- [RFC-050] MUST aplicar anti-storm controls antes de abrir task/decision em massa.
- [RFC-050] MUST bloquear release quando claim central nao tiver eval gate ativo.

## Thresholds
| Categoria | Threshold inicial | Acao |
|---|---|---|
| Custo diario | > 90% teto | fallback agressivo + decision de budget |
| Latencia p95 | > 2x SLA por 30 min | task de tuning + redução de carga |
| Falha de tarefa | > 10% em 1h | circuit breaker por classe |
| Fallback em cascata | > 3 por tarefa | escalar cloud/humano |
| Incidente critico | >= 1 | ativar degraded mode e checklist incidente |

## Calibragem por Fase
- Fase 0 (aquecimento, 2-4 semanas):
  - usar thresholds mais tolerantes para reduzir falso positivo.
  - ajustar semanalmente por baseline real (media + desvio).
- Fase 1+:
  - reduzir tolerancia gradualmente por classe critica.
  - bloquear regressao repetida com gate automatico.

## Anti-Storm Controls (obrigatorio)
- `debounce_window`: 10 minutos por sinal.
- `cooldown_window`: 30 minutos apos acao automatica.
- `coalescing_key`: agrupar alertas por classe+causa.
- `max_auto_tasks_per_hour`: 6 por escritorio.
- `max_auto_decisions_per_hour`: 3 por escritorio.
- `max_pending_decisions_global`: 10.
- quando exceder limite:
  - consolidar alertas em 1 task agregada;
  - suspender novas decisions nao criticas;
  - manter apenas incidentes criticos.

## Acoes Automaticas
- abrir task de mitigacao com owner.
- notificar Telegram com severidade.
- registrar evento no activity feed e incident log.
- abrir decision para ajuste estrutural quando persistente.
- nunca abrir mais de 1 decision para a mesma `coalescing_key` durante `cooldown_window`.

## EVAL Gates de Claims Centrais (obrigatorio)
| Claim central | Gate minimo | Threshold inicial | Acao em falha |
|---|---|---|---|
| identidade de aprovador HITL valida | taxa de comando autorizado | 100% | bloquear comandos + abrir `SECURITY_VIOLATION_REVIEW` |
| comando HITL idempotente | replay sem efeito colateral | 100% | bloquear execucao + abrir incident |
| Work Order schema/version/idempotency validos | WO invalido aceito | 0 casos | bloquear ingest + abrir task de contrato |
| reconciliacao offline sem duplicidade | eventos duplicados pos-replay | 0 casos | manter degraded + abrir decision |
| heartbeat baseline de 20 min atendido | atraso p95 vs agenda | <= 5 min | abrir tuning + reduzir carga |
| allowlists aplicadas corretamente | taxa de bloqueio de acao proibida | 100% | bloquear deploy + incident de seguranca |
| trilha auditavel integra (hash-chain) | quebra de cadeia | 0 casos | stop-ship + incidente de integridade |

## Regra de Release
- qualquer claim central sem gate definido/executado => release bloqueada.
- excecao apenas por decision explicita de risco, com prazo para correcao.

## Links Relacionados
- [ARC Observability](../ARC/ARC-OBSERVABILITY.md)
- [ARC Degraded Mode](../ARC/ARC-DEGRADED-MODE.md)
- [Incident Log Policy](../INCIDENTS/INCIDENT-LOG-POLICY.md)
