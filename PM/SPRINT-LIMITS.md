---
doc_id: "SPRINT-LIMITS.md"
version: "1.1"
status: "active"
owner: "PM"
last_updated: "2026-02-19"
rfc_refs: ["RFC-001", "RFC-040", "RFC-050"]
---

# Sprint Limits

## Objetivo
Definir enforcement automatico de limites de sprint e tarefa para manter previsibilidade e evitar sobrecarga artificial.

## Escopo
Inclui:
- limites de quantidade e tamanho
- bloqueio automatico de violacao
- fluxo de override por decision `SPRINT_OVERRIDE`
- contrato obrigatorio de idempotencia e rollback

Exclui:
- excecao informal sem justificativa/custo
- estimativa sem base de capacidade real

## Regras Normativas
- [RFC-040] MUST bloquear automaticamente sprint que exceder limite.
- [RFC-040] MUST exigir decision `SPRINT_OVERRIDE` para liberar excecao.
- [RFC-050] MUST registrar justificativa, custo e impacto da excecao.
- [RFC-001] MUST proibir datas/capacidade inventadas.
- [RFC-040] MUST tratar tentativa duplicada de override como no-op idempotente.
- [RFC-040] MUST registrar rollback executavel antes de aplicar override.

## Limites Base
- max itens por sprint: 12 (ajustavel por decision).
- max tamanho por task: 1 dia util ou 3 story points.
- max itens criticos paralelos: 2 por escritorio.

## Enforcement
- validacao em criacao e em update de sprint.
- ao exceder: status `BLOCKED_LIMIT`.
- abrir evento `SPRINT_LIMIT_ALERT` com `coalescing_key` deterministica:
  - `coalescing_key = sprint_id + ":" + limit_type + ":" + sprint_window`.
- se o mesmo alerta reaparecer durante `cooldown_window`, MUST virar no-op (sem nova decision).
- decisao `SPRINT_OVERRIDE` so pode ser criada quando nao houver pendencia ativa para a mesma `coalescing_key`.

## Contrato SPRINT_OVERRIDE (idempotencia + rollback)
```yaml
schema_version: "1.1"
override_key: "SPR-OVR-<sprint_id>-<limit_type>-<window>"
coalescing_key: "<sprint_id>:<limit_type>:<window>"
sprint_id: "SPR-YYYYMMDD-XXX"
limit_type: "max_items|max_task_size|max_parallel_critical"
requested_delta: "descricao objetiva"
status: "REQUESTED|APPROVED|APPLIED|ROLLED_BACK|REJECTED|EXPIRED"
source_alert_id: "ALERT-..."
rollback_token: "RBK-UUID"
rollback_snapshot_ref: "artifact://..."
applied_by: "agent|human|null"
applied_at: "ISO-8601|null"
expires_at: "ISO-8601"
```

## Regras de Aplicacao
- `override_key` MUST ser unico por janela de sprint.
- reaplicacao com mesma `override_key` MUST ser no-op.
- antes de `APPLIED`, MUST existir `rollback_snapshot_ref` valido.
- expiracao sem aplicacao MUST fechar como `EXPIRED` e reabrir planejamento.

## Regras de Rollback
- rollback MUST restaurar snapshot da sprint pre-override.
- rollback MUST registrar `task_event` com `idempotency_key` propria.
- rollback parcial ou falho MUST abrir incidente de governanca.

## Medicao de Tamanho
- preferencia: tempo estimado validado historicamente.
- opcional: story points calibrados.
- tarefa sem estimativa valida MUST ser rejeitada.

## Links Relacionados
- [Scrum Gov](./SCRUM-GOV.md)
- [Decision Protocol](./DECISION-PROTOCOL.md)
- [System Health Thresholds](../EVALS/SYSTEM-HEALTH-THRESHOLDS.md)
