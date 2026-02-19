---
doc_id: "BI-PRD.md"
version: "1.0"
status: "active"
owner: "PM"
last_updated: "2026-02-18"
rfc_refs: ["RFC-001", "RFC-010", "RFC-025", "RFC-050"]
---

# BI PRD

## Objetivo
Definir vertical BI como referencia de operacao de baixo risco com entrega de dados, dashboards e relatorios auditaveis.

## Escopo
Inclui:
- ETL, modelagem e dashboards
- relatorios recorrentes com rastreabilidade
- uso de RAG para contexto e politicas

Exclui:
- acao automatica no mundo real de alto impacto
- acesso a dados sem permissoes do Work Order

## Regras Normativas
- [RFC-010] MUST classificar tarefas BI como baixo/medio risco por padrao.
- [RFC-025] MUST citar fontes em analises criticas.
- [RFC-050] MUST gerar artifacts verificaveis (query, tabela, dashboard export).

## Entregaveis
- pipelines ETL versionados.
- datasets normalizados.
- dashboards com definicao de KPI.
- relatorios periodicos com evidencias.

## Uso de RAG e Determinismo
- RAG para definicao de metricas e politicas.
- script-first para ETL e checks de qualidade.
- validacao automatica de schema e consistencia.

## Links Relacionados
- [Dev Deterministic Pipeline](../../DEV/DEV-DETERMINISTIC-PIPELINE.md)
- [RAG Company](../../RAG/RAG-COMPANY.md)
- [Work Order Spec](../../PM/WORK-ORDER-SPEC.md)
