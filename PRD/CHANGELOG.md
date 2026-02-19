---
doc_id: "CHANGELOG.md"
version: "1.0"
status: "active"
owner: "PM"
last_updated: "2026-02-18"
rfc_refs: ["RFC-001", "RFC-010", "RFC-015", "RFC-020", "RFC-025", "RFC-030", "RFC-035", "RFC-040", "RFC-050", "RFC-060"]
---

# Changelog Normativo

## Objetivo
Manter historico auditavel de alteracoes normativas da documentacao, incluindo impacto e acao de migracao quando aplicavel.

## Escopo
Inclui:
- mudancas de regra MUST/SHOULD/MAY
- mudancas de RFC e de hierarquia documental
- impacto operacional e compliance

Exclui:
- log de tarefas de desenvolvimento cotidiano
- detalhe de commit tecnico sem impacto normativo

## Regras Normativas
- [RFC-001] MUST registrar data, resumo e RFCs afetadas em toda alteracao normativa.
- [RFC-050] MUST manter trilha de impacto e responsavel por mudanca.
- [RFC-015] SHOULD avaliar reflexo em seguranca para toda alteracao estrutural.

## Entradas

### 2026-02-19 - Ajustes de viabilidade MVP e controle operacional
- RFCs afetadas: RFC-015, RFC-030, RFC-040, RFC-050.
- Impacto:
  - fixa heartbeat baseline unico em 20 minutos;
  - define controle forte de aprovador Telegram (allowlist + challenge + idempotencia de comando);
  - formaliza fonte canonica de memoria/estado operacional em `workspaces/main/*`;
  - adiciona EVAL gates obrigatorios para claims centrais.
- Migracao:
  - desativar memoria operacional duplicada fora de `workspaces/main/memory`;
  - remover versionamento de `sessions/*.json*`;
  - atualizar scripts/env para `HEARTBEAT_MINUTES=20`.

### 2026-02-18 - Baseline v1.0 da stack documental
- RFCs afetadas: RFC-001, RFC-010, RFC-015, RFC-020, RFC-025, RFC-030, RFC-035, RFC-040, RFC-050, RFC-060.
- Impacto:
  - define arquitetura Local + Cloud com gates por risco;
  - formaliza RAG hibrido, degraded mode e Scrum com enforcement;
  - institui tabela de model routing com fallback e auditoria.
- Migracao:
  - remover arvores duplicadas de documentacao sob `PRD/`;
  - adotar somente arvore canonica na raiz do repositorio;
  - atualizar automacoes para novos caminhos relativos.

## Links Relacionados
- [PRD Master](./PRD-MASTER.md)
- [Document Hierarchy](../META/DOCUMENT-HIERARCHY.md)
- [RFC Index](../META/RFC-INDEX.md)
