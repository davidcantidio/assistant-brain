---
doc_id: "RFC-INDEX.md"
version: "1.0"
status: "active"
owner: "PM"
last_updated: "2026-02-18"
rfc_refs: ["RFC-001", "RFC-010", "RFC-015", "RFC-020", "RFC-025", "RFC-030", "RFC-035", "RFC-040", "RFC-050", "RFC-060"]
---

# RFC Index

## Objetivo
Centralizar os RFCs internos, com status e referencia para os documentos onde cada norma e implementada.

## Escopo
Inclui:
- catalogo oficial de RFC IDs ativos
- resumo curto por RFC
- links de implementacao documental

Exclui:
- texto completo de cada norma
- historico detalhado de alteracoes de versao

## Regras Normativas
- [RFC-001] MUST manter formato de ID `RFC-XXX`.
- [RFC-001] MUST referenciar RFC em toda regra MUST/SHOULD relevante.
- [RFC-050] MUST manter este indice sincronizado com a documentacao operacional.

## Catalogo RFC

### RFC-001 - Linguagem normativa e convencoes
- Status: active
- Resumo: define semantica MUST/SHOULD/MAY, formato de IDs e padrao de documentos.
- Implementacao:
  - [PRD Master](../PRD/PRD-MASTER.md)
  - [Document Hierarchy](./DOCUMENT-HIERARCHY.md)

### RFC-010 - Governanca por risco e gates
- Status: active
- Resumo: padroniza classificacao de risco e fluxo de aprovacao proporcional.
- Implementacao:
  - [Governance Risk](../CORE/GOVERNANCE-RISK.md)
  - [Decision Protocol](../PM/DECISION-PROTOCOL.md)

### RFC-015 - Politica de seguranca operacional
- Status: active
- Resumo: define menor privilegio, sandbox, secrets, redaction e resposta a incidente.
- Implementacao:
  - [Security Policy](../SEC/SEC-POLICY.md)
  - [Secrets](../SEC/SEC-SECRETS.md)
  - [Sandboxing](../SEC/SEC-SANDBOXING.md)
  - [Prompt Injection](../SEC/SEC-PROMPT-INJECTION.md)
  - [Incident Response](../SEC/SEC-INCIDENT-RESPONSE.md)
  - [Operators Allowlist](../SEC/allowlists/OPERATORS.yaml)

### RFC-020 - Work Order schema
- Status: active
- Resumo: define contrato minimo para demandas inter-escritorios.
- Implementacao:
  - [Work Order Spec](../PM/WORK-ORDER-SPEC.md)
  - [ARC Core](../ARC/ARC-CORE.md)

### RFC-025 - RAG hibrido e firewall por empresa
- Status: active
- Resumo: define ingestao, avaliacao, isolamento, citacao e quarentena de conhecimento.
- Implementacao:
  - [RAG General](../RAG/RAG-GENERAL.md)
  - [RAG Company](../RAG/RAG-COMPANY.md)
  - [RAG Ingestion](../RAG/RAG-INGESTION.md)
  - [RAG Evals](../RAG/RAG-EVALS.md)
  - [RAG Quarantine](../RAG/RAG-QUARANTINE.md)

### RFC-030 - Model routing e fallback
- Status: active
- Resumo: define roteamento por classe de tarefa, SLA e fallback ladder.
- Implementacao:
  - [ARC Model Routing](../ARC/ARC-MODEL-ROUTING.md)
  - [System Health Thresholds](../EVALS/SYSTEM-HEALTH-THRESHOLDS.md)

### RFC-035 - Degraded mode e reconciliacao
- Status: active
- Resumo: define degradacao graciosa, logs offline e retorno seguro.
- Implementacao:
  - [ARC Degraded Mode](../ARC/ARC-DEGRADED-MODE.md)
  - [Degraded Procedure](../INCIDENTS/DEGRADED-MODE-PROCEDURE.md)

### RFC-040 - Scrum enforcement e decisions
- Status: active
- Resumo: limita backlog/sprint/task e define override com justificativa.
- Implementacao:
  - [Scrum Gov](../PM/SCRUM-GOV.md)
  - [Sprint Limits](../PM/SPRINT-LIMITS.md)
  - [Decision Protocol](../PM/DECISION-PROTOCOL.md)

### RFC-050 - Observabilidade e auditoria
- Status: active
- Resumo: define metricas obrigatorias, thresholds e trilha de auditoria.
- Implementacao:
  - [ARC Observability](../ARC/ARC-OBSERVABILITY.md)
  - [Incident Log Policy](../INCIDENTS/INCIDENT-LOG-POLICY.md)
  - [System Health Thresholds](../EVALS/SYSTEM-HEALTH-THRESHOLDS.md)

### RFC-060 - Vertical de alto risco (Trading)
- Status: active
- Resumo: define gating de habilitacao, bloqueios e checkpoints humanos para trading.
- Implementacao:
  - [Trading PRD](../VERTICALS/TRADING/TRADING-PRD.md)
  - [Trading Risk Rules](../VERTICALS/TRADING/TRADING-RISK-RULES.md)
  - [Trading Enablement](../VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md)

## Links Relacionados
- [Document Hierarchy](./DOCUMENT-HIERARCHY.md)
- [Glossary](./GLOSSARY.md)
- [Changelog](../PRD/CHANGELOG.md)
