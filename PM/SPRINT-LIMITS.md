---
doc_id: "SPRINT-LIMITS.md"
version: "1.0"
status: "active"
owner: "PM"
last_updated: "2026-02-18"
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

Exclui:
- excecao informal sem justificativa/custo
- estimativa sem base de capacidade real

## Regras Normativas
- [RFC-040] MUST bloquear automaticamente sprint que exceder limite.
- [RFC-040] MUST exigir decision `SPRINT_OVERRIDE` para liberar excecao.
- [RFC-050] MUST registrar justificativa, custo e impacto da excecao.
- [RFC-001] MUST proibir datas/capacidade inventadas.

## Limites Base
- max itens por sprint: 12 (ajustavel por decision).
- max tamanho por task: 1 dia util ou 3 story points.
- max itens criticos paralelos: 2 por escritorio.

## Enforcement
- validacao em criacao e em update de sprint.
- ao exceder: status `BLOCKED_LIMIT`.
- notificar PM e abrir `SPRINT_OVERRIDE` automaticamente.

## Override via Decision
- decision_id padrao: `SPRINT_OVERRIDE`.
- campos obrigatorios:
  - motivo de negocio
  - custo adicional esperado
  - impacto em risco/SLA
  - plano de mitigacao

## Medicao de Tamanho
- preferencia: tempo estimado validado historicamente.
- opcional: story points calibrados.
- tarefa sem estimativa valida MUST ser rejeitada.

## Links Relacionados
- [Scrum Gov](./SCRUM-GOV.md)
- [Decision Protocol](./DECISION-PROTOCOL.md)
- [System Health Thresholds](../EVALS/SYSTEM-HEALTH-THRESHOLDS.md)
