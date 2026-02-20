---
doc_id: "WORK-ORDER-SPEC.md"
version: "1.2"
status: "active"
owner: "PM"
last_updated: "2026-02-20"
rfc_refs: ["RFC-001", "RFC-010", "RFC-015", "RFC-020", "RFC-050"]
---

# Work Order Spec

## Objetivo
Definir contrato obrigatorio de demanda entre escritorios para roteamento, execucao e auditoria confiaveis.

## Escopo
Inclui:
- schema obrigatorio de Work Order
- classes de SLA e risco
- permissao de RAG e budget por demanda

Exclui:
- tarefa sem contrato minimo
- execucao inter-escritorios por solicitacao informal

## Regras Normativas
- [RFC-020] MUST validar schema antes de aceitar Work Order.
- [RFC-010] MUST classificar risco e gate na criacao.
- [RFC-015] MUST classificar sensibilidade de dados (`public|internal|sensitive`) na criacao.
- [RFC-020] MUST definir output esperado e DoD da entrega.
- [RFC-050] MUST registrar custo e artifacts vinculados ao Work Order.
- [RFC-020] MUST incluir `idempotency_key` e `schema_version` para reconciliacao segura.
- [RFC-020] MUST definir estrategia de replay (`attempt`) para eventos derivados.

## Schema Obrigatorio
```yaml
schema_version: "1.1"
work_order_id: "WO-YYYYMMDD-XXX"
idempotency_key: "UUID"
requester_office: "main|ops|writer|..."
target_office: "..."
objective: "texto claro"
sla_class: "instantaneo|normal|overnight"
risk_class: "baixo|medio|alto"
risk_tier: "R0|R1|R2|R3|null"
data_sensitivity: "public|internal|sensitive"
priority: "P0|P1|P2|P3"
created_at: "ISO-8601"
due_at: "ISO-8601"
allowed_inputs:
  - "doc://..."
expected_output:
  format: "json|yaml|md|patch|sql"
  acceptance_criteria:
    - "..."
rag_scope:
  allowed_offices: ["main"]
  allowed_collections: ["policy", "project-x"]
budget:
  currency: "BRL|USD"
  hard_cap: 100.0
estimated_cost: 45.0
owner: "PM"
status: "DRAFT|APPROVED|IN_PROGRESS|DONE|CANCELLED"
```

## SLA Classes
- instantaneo: resposta em segundos, baixa complexidade.
- normal: minutos, validacao completa.
- overnight: processamento extenso e lote.

## Regras de Risco
- baixo: execucao local com validacao deterministica.
- medio: revisao por amostragem/checkpoint.
- alto: decision obrigatoria e gate cloud/humano.

## Mapeamento de Risco (compatibilidade)
- taxonomia canonica de gates:
  - `R0`: doc-only sem impacto funcional/side effect.
  - `R1`: baixo risco funcional local.
  - `R2`: medio risco com side effect controlado/cross-modulo.
  - `R3`: alto risco critico/regulatorio/financeiro.
- mapeamento com `risk_class`:
  - `baixo -> R1` (ou `R0` quando doc-only).
  - `medio -> R2`.
  - `alto -> R3`.
- Work Order SHOULD incluir `risk_tier` quando houver side effect ou gate formal.

## Regras de Sensibilidade
- `public`: sem restricao adicional de provider alem da policy base.
- `internal`: provider allowlist moderada e redacao de logs obrigatoria.
- `sensitive`: provider allowlist restrita + politica ZDR + armazenamento minimizado de prompt.

## Criterios de Aceite (DoD)
- artefato no formato acordado.
- validacoes deterministicas aprovadas.
- citacoes e evidencias quando aplicavel.
- custo final <= hard cap.

## Conversao para Tasks no Mission Control
1. validar schema.
2. quebrar em microtarefas com IDs.
3. atribuir por papel e prioridade.
4. anexar artifacts e status.
5. consolidar entrega final no Work Order.

## Regra de Replay
- cada `task_event` derivado de um Work Order MUST carregar:
  - `idempotency_key` herdada do Work Order;
  - `attempt` incremental;
  - `replay_key` canonica.

## Links Relacionados
- [Decision Protocol](./DECISION-PROTOCOL.md)
- [Governance Risk](../CORE/GOVERNANCE-RISK.md)
- [ARC Core](../ARC/ARC-CORE.md)
