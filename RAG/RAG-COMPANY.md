---
doc_id: "RAG-COMPANY.md"
version: "1.0"
status: "active"
owner: "RAG Librarian"
last_updated: "2026-02-18"
rfc_refs: ["RFC-001", "RFC-020", "RFC-025"]
---

# RAG Company

## Objetivo
Definir isolamento, permissoes e classificacao de sensibilidade do RAG por empresa.

## Escopo
Inclui:
- escopo de conhecimento operacional por empresa
- regras de acesso e compartilhamento controlado
- vinculo de permissao ao Work Order

Exclui:
- acesso cruzado implicito entre empresas
- uso de documento sem classificacao de sensibilidade

## Regras Normativas
- [RFC-025] MUST manter isolamento logico por empresa.
- [RFC-020] MUST exigir permissao explicita no Work Order para acesso a RAG de outra empresa.
- [RFC-025] MUST exigir citacao por claim para resposta critica.
- [RFC-001] SHOULD aplicar classificacao de sensibilidade padrao.

## Classes de Sensibilidade
- Publico interno: compartilhavel no condominio.
- Restrito empresa: acesso apenas ao escritorio dono.
- Confidencial: acesso limitado por role e decision.
- Critico regulatorio: acesso minimo, com logging reforcado.

## Permissoes por Work Order
- `allowed_offices[]` MUST listar escritorios autorizados.
- `rag_scope` MUST definir colecoes e filtros permitidos.
- ausencia de permissao MUST resultar em bloqueio.

## Firewall de Dados
- bloqueio default entre empresas.
- compartilhamento temporario so com expiracao definida.
- auditoria de leitura em dados sensiveis.

## Links Relacionados
- [Work Order Spec](../PM/WORK-ORDER-SPEC.md)
- [RAG Ingestion](./RAG-INGESTION.md)
- [RAG Quarantine](./RAG-QUARANTINE.md)
