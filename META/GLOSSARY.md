---
doc_id: "GLOSSARY.md"
version: "1.0"
status: "active"
owner: "RAG Librarian"
last_updated: "2026-02-18"
rfc_refs: ["RFC-001", "RFC-020", "RFC-025", "RFC-035"]
---

# Glossary

## Objetivo
Padronizar termos operacionais do sistema para reduzir ambiguidade entre escritorio, engenharia, seguranca e operacao.

## Escopo
Inclui:
- definicoes oficiais dos termos centrais da arquitetura
- termos de governanca, RAG, execucao e seguranca
- referencias cruzadas para normas aplicaveis

Exclui:
- exemplos extensos de implementacao
- jargoes nao usados no projeto

## Regras Normativas
- [RFC-001] MUST usar estas definicoes em PRDs, decisions e runbooks.
- [RFC-025] SHOULD anexar termos de RAG em artefatos de ingestao/eval.
- [RFC-035] MUST usar a mesma semantica de degraded mode em ARC e INCIDENTS.

## Definicoes
- Escritorio: unidade operacional de uma empresa no edificio virtual, com missao, backlog e equipe proprios.
- Condominio: servicos compartilhados entre escritorios (financeiro, compliance, design, dev e outros).
- Work Order: contrato formal de demanda inter-escritorios com objetivo, risco, SLA, budget e permissoes.
- Decision: objeto de aprovacao humana/cloud para mudancas de alto impacto ou override.
- Artifact: saida auditavel produzida por tarefa (json, yaml, diff, sql, relatorio).
- Claim: afirmacao verificavel dentro de uma resposta; deve apontar para fonte.
- Chunk: segmento indexado de documento no RAG, com metadados e rastreabilidade.
- Sandbox: ambiente restrito de execucao com limites de tempo, memoria e permissoes.
- Degraded mode: modo de operacao segura durante falhas de infraestrutura ou dependencia critica.
- Fonte canonica operacional: local unico de memoria/estado valido para execucao no MVP (`workspaces/main/*`).

## Links Relacionados
- [RFC Index](./RFC-INDEX.md)
- [Work Order Spec](../PM/WORK-ORDER-SPEC.md)
- [RAG Ingestion](../RAG/RAG-INGESTION.md)
- [ARC Degraded Mode](../ARC/ARC-DEGRADED-MODE.md)
