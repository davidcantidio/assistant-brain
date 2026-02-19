---
doc_id: "RAG-INGESTION.md"
version: "1.0"
status: "active"
owner: "RAG Librarian"
last_updated: "2026-02-18"
rfc_refs: ["RFC-001", "RFC-025", "RFC-050"]
---

# RAG Ingestion

## Objetivo
Definir pipeline de ingestao com metadados obrigatorios, revisao e rastreabilidade para evitar contaminacao e perda de qualidade.

## Escopo
Inclui:
- metadados obrigatorios por documento/chunk
- fluxo de ingestao, revisao e promocao
- dedupe e chunking padronizados

Exclui:
- indexacao ad-hoc sem metadados
- promocao direta sem revisao

## Regras Normativas
- [RFC-025] MUST recusar ingestao sem metadados obrigatorios.
- [RFC-025] MUST executar dedupe e chunking consistente.
- [RFC-025] MUST iniciar todo novo documento em estado de quarentena.
- [RFC-050] MUST registrar reviewer e historico de mudancas.

## Metadados Obrigatorios
- `doc_id`
- `empresa_owner`
- `sensibilidade`
- `source_type`
- `timestamp`
- `reviewer`
- `allowed_offices[]`
- `confidence_level`

## Fluxo de Ingestao
1. receber documento bruto e classificar sensibilidade.
2. validar metadados obrigatorios.
3. executar dedupe e chunking.
4. indexar em `quarantine`.
5. revisar qualidade e permissoes.
6. promover para `active` quando aprovado.

## Dedupe e Chunking
- dedupe por hash + similaridade semantica.
- chunking com tamanho e sobreposicao padrao por tipo de doc.
- chunk MUST manter ponteiro para fonte original.

## Links Relacionados
- [RAG Quarantine](./RAG-QUARANTINE.md)
- [RAG Evals](./RAG-EVALS.md)
- [SEC Prompt Injection](../SEC/SEC-PROMPT-INJECTION.md)
