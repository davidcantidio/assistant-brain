---
doc_id: "DEV-PRINCIPLES.md"
version: "1.0"
status: "active"
owner: "Marvin"
last_updated: "2026-02-18"
rfc_refs: ["RFC-001", "RFC-015", "RFC-040", "RFC-050"]
---

# Dev Principles

## Objetivo
Definir principios de engenharia para entrega previsivel, auditavel e segura no Agent OS.

## Escopo
Inclui:
- principios de design e execucao
- exigencias de evidencia para mudanca
- relacionamento com pipeline e CI

Exclui:
- excecoes ad-hoc sem registro
- alteracao em producao sem validacao

## Regras Normativas
- [RFC-001] MUST priorizar determinismo sobre prompt sempre que possivel.
- [RFC-050] MUST anexar evidencias (patch, testes, logs) em toda entrega tecnica.
- [RFC-015] MUST respeitar seguranca e sandbox em toda execucao.
- [RFC-040] SHOULD usar decision para excecao de processo/risco.

## Principios
- script-first: transformar tarefas repetiveis em ferramentas.
- patch-first: alterar o minimo necessario com diffs claros.
- test-first para risco medio/alto: validar antes de merge.
- observabilidade by default: medir custo, latencia e erro.
- rollback-ready: toda mudanca relevante com plano de reversao.

## Links Relacionados
- [Deterministic Pipeline](./DEV-DETERMINISTIC-PIPELINE.md)
- [CI Rules](./DEV-CI-RULES.md)
- [Security Policy](../SEC/SEC-POLICY.md)
