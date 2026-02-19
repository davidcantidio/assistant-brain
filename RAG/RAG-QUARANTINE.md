---
doc_id: "RAG-QUARANTINE.md"
version: "1.0"
status: "active"
owner: "RAG Librarian"
last_updated: "2026-02-18"
rfc_refs: ["RFC-001", "RFC-025", "RFC-035"]
---

# RAG Quarantine

## Objetivo
Controlar entrada de novos documentos em estado de quarentena para prevenir contaminacao do conhecimento ativo.

## Escopo
Inclui:
- estado inicial de novos documentos
- regras de uso enquanto em quarentena
- fluxo de promocao para ativo

Exclui:
- uso critico de documento nao revisado
- bypass manual sem trilha de aprovacao

## Regras Normativas
- [RFC-025] MUST colocar todo documento novo em `quarantine`.
- [RFC-025] MUST limitar uso de documento em quarentena a tarefas de baixo risco.
- [RFC-025] MUST exigir revisao antes de promover para `active`.
- [RFC-035] SHOULD manter fallback seguro se revisao estiver indisponivel.

## Politica de Quarentena
- estado inicial: `quarantine`.
- permitido: consultas exploratorias de baixo risco com flag de incerteza.
- proibido: uso em decisao critica, compliance e acao real.

## Fluxo de Promocao
1. ingestao com metadados obrigatorios.
2. validacao automatica (formato, dedupe, permissao).
3. revisao humana ou cloud com checklist.
4. aprovacao e mudanca de estado para `active`.
5. registro de promocao em auditoria.

## Criterios de Rejeicao
- metadado incompleto.
- fonte nao confiavel.
- conflito com politica atual.
- falha em teste de leakage/injection.

## Links Relacionados
- [RAG Ingestion](./RAG-INGESTION.md)
- [RAG Evals](./RAG-EVALS.md)
- [Governance Risk](../CORE/GOVERNANCE-RISK.md)
