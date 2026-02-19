---
doc_id: "OFFICE-CREATION.md"
version: "1.0"
status: "active"
owner: "Marvin"
last_updated: "2026-02-18"
rfc_refs: ["RFC-001", "RFC-010", "RFC-020", "RFC-040"]
---

# Office Creation

## Objetivo
Definir como criar novos escritorios e verticais de negocio sem quebrar governanca, seguranca e rastreabilidade.

## Escopo
Inclui:
- requisitos de criacao de escritorio
- template minimo de proposta
- integracao com Work Order, RAG e Decision Protocol

Exclui:
- aprovacao automatica sem checkpoint
- mudancas em producao sem plano de rollout

## Regras Normativas
- [RFC-010] MUST tratar criacao de escritorio como risco medio/alto.
- [RFC-040] MUST abrir decision de criacao com evidencias e custo.
- [RFC-020] MUST formalizar demanda via Work Order de bootstrap.
- [RFC-001] SHOULD padronizar naming, ownership e KPI inicial.

## Requisitos de Criacao
- proposta com missao e escopo de negocio
- backlog inicial de 30 dias
- papeis minimos e modelo de capacidade
- budget inicial e teto de custo
- plano de seguranca e permissao de dados
- definicao do RAG inicial (fontes permitidas)

## Template de Proposta
- Nome do escritorio:
- Missao:
- Problema que resolve:
- Classe de risco inicial:
- Servicos compartilhados necessarios:
- KPI de 30/60/90 dias:
- Custo estimado:
- Dono responsavel:

## Fluxo de Aprovacao
1. PM registra Work Order de criacao.
2. RAG Librarian valida fontes e politicas aplicaveis.
3. Frederisk classifica risco e define gates.
4. Diretora IA revisa e aprova/reprova.
5. Humano confirma go-live quando risco alto.

## Integracao com RAG e Work Order
- Todo novo escritorio MUST definir escopo de dados permitido.
- Acesso cruzado entre empresas MUST nascer bloqueado por padrao.
- Promocao de acesso extra MUST passar por decision.

## Links Relacionados
- [Governance Risk](./GOVERNANCE-RISK.md)
- [Work Order Spec](../PM/WORK-ORDER-SPEC.md)
- [RAG Company](../RAG/RAG-COMPANY.md)
- [Decision Protocol](../PM/DECISION-PROTOCOL.md)
