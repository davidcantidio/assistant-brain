---
doc_id: "RAG-GENERAL.md"
version: "1.0"
status: "active"
owner: "RAG Librarian"
last_updated: "2026-02-18"
rfc_refs: ["RFC-001", "RFC-025", "RFC-050"]
---

# RAG General

## Objetivo
Definir escopo, ownership e controle de qualidade do RAG geral do condominio.

## Escopo
Inclui:
- politicas, playbooks, padroes, templates, glossario e catalogo de servicos
- versionamento e ownership pelo RAG Librarian
- controle de drift de politica

Exclui:
- conteudo operacional sensivel de empresa especifica
- dados privados sem classificacao

## Regras Normativas
- [RFC-025] MUST limitar o RAG geral a metaconhecimento compartilhavel.
- [RFC-025] MUST versionar documentos com `doc_id` e data de revisao.
- [RFC-025] MUST bloquear resposta com politica desatualizada (policy drift).
- [RFC-050] SHOULD registrar consultas criticas para auditoria.

## Conteudo Permitido
- normas de seguranca e governanca
- templates oficiais (Work Order, Decision, Incident)
- glossario e mapa documental
- catalogo de servicos do condominio

## Ownership e Versionamento
- dono: RAG Librarian.
- ciclo de revisao: semanal para politicas criticas.
- mudanca normativa MUST atualizar changelog e RFC index.

## Politica de Policy Drift
- resposta critica MUST citar versao do documento fonte.
- se versao estiver vencida, resposta MUST ser bloqueada com alerta.
- docs obsoletos MUST sair do indice ativo.

## Links Relacionados
- [RAG Company](./RAG-COMPANY.md)
- [RAG Ingestion](./RAG-INGESTION.md)
- [Glossary](../META/GLOSSARY.md)
- [Document Hierarchy](../META/DOCUMENT-HIERARCHY.md)
