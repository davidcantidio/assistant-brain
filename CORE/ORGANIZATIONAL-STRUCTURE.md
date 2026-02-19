---
doc_id: "ORGANIZATIONAL-STRUCTURE.md"
version: "1.0"
status: "active"
owner: "Marvin"
last_updated: "2026-02-18"
rfc_refs: ["RFC-001", "RFC-010", "RFC-020"]
---

# Organizational Structure

## Objetivo
Definir papeis fixos, papeis variaveis e relacao entre escritorios e servicos compartilhados do condominio.

## Escopo
Inclui:
- cargos minimos por escritorio
- regras de compartilhamento de funcao
- matriz escritorio x servicos de condominio

Exclui:
- contratacao de pessoas reais
- workflows detalhados de sprint

## Regras Normativas
- [RFC-010] MUST manter Diretora IA, PM, RAG Librarian e controles de risco/financeiro/compliance.
- [RFC-020] MUST explicitar ownership no Work Order para cada demanda inter-escritorios.
- [RFC-001] SHOULD manter nomenclatura de papeis consistente em todos os docs.
- [RFC-010] MUST manter papeis centrais dedicados por escritorio em operacao normal.

## Cargos Fixos Minimos
- Diretora IA (cloud): supervisao, risco alto, desempate e aprovacao critica.
- PM: planejamento, capacidade, limites e fluxo de entrega.
- RAG Librarian: curadoria, citacao e drift de conhecimento.
- Controladoria/Financeiro: budget e relatorio de custo.
- Auditoria/Compliance: politica, seguranca e conformidade.

## Cargos Variaveis
- design office
- dev backend/frontend/data
- marketing/growth
- BI e analytics
- juridico e operacoes especializadas

## Politica de Compartilhamento (modo seguro)
- papeis centrais NAO sao compartilhados:
  - PM dedicado por escritorio.
  - RAG Librarian dedicado por escritorio.
  - Compliance/Auditoria dedicado por escritorio.
  - Controladoria dedicada por escritorio.
- dados e artefatos podem ser compartilhados sob contrato explicito:
  - Work Order com `allowed_offices[]`.
  - classificacao de sensibilidade aplicada.
  - trilha de auditoria por acesso.

## Matriz Escritorio x Servicos
| Escritorio | PM | RAG | Financeiro | Compliance | Dados Compartilhados |
|---|---|---|---|---|---|
| Main | Dedicado | Dedicado | Dedicado | Dedicado | Sim, por Work Order |
| Ops | Parked (Fase 2) | Parked (Fase 2) | Parked (Fase 2) | Parked (Fase 2) | Nao ativo no MVP |
| Writer | Parked (Fase 2) | Parked (Fase 2) | Parked (Fase 2) | Parked (Fase 2) | Nao ativo no MVP |

## Regras para abrir cargos variaveis
- MUST abrir justificativa de capacidade/impacto.
- MUST informar risco, custo mensal e KPIs.
- MUST registrar aprovacao em decision quando envolver alto risco.

## Links Relacionados
- [Office Creation](./OFFICE-CREATION.md)
- [Financial Governance](./FINANCIAL-GOVERNANCE.md)
- [Work Order Spec](../PM/WORK-ORDER-SPEC.md)
