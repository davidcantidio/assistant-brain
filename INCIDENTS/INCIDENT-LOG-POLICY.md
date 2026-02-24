---
doc_id: "INCIDENT-LOG-POLICY.md"
version: "1.2"
status: "active"
owner: "Security"
last_updated: "2026-02-20"
rfc_refs: ["RFC-001", "RFC-015", "RFC-050"]
---

# Incident Log Policy

## Objetivo
Definir formato, campos obrigatorios, retencao e redaction do log de incidentes.

## Escopo
Inclui:
- schema de registro de incidente
- nivel de severidade e campos minimos
- politica de retencao e mascaramento

Exclui:
- log incompleto sem identificador
- armazenamento de segredo em texto puro

## Regras Normativas
- [RFC-050] MUST registrar todo incidente com ID unico e timeline.
- [RFC-015] MUST remover secrets e PII dos logs.
- [RFC-001] MUST classificar severidade no registro inicial.
- [RFC-050] MUST manter registro tamper-evident por hash encadeado.

## Formato do Log
```yaml
schema_version: "1.1"
incident_id: "INC-YYYYMMDD-XXX"
severity: "SEV-1|SEV-2|SEV-3"
status: "OPEN|MITIGATED|CLOSED"
summary: "..."
impact: "..."
root_cause: "..."
actions:
  - "..."
opened_at: "ISO-8601"
closed_at: "ISO-8601|null"
owner: "..."
prev_hash: "hex|null"
entry_hash: "hex"
```

## Integridade (Tamper-Evident)
- cada entrada MUST incluir `entry_hash` do payload canonico.
- cada entrada MUST referenciar `prev_hash` da entrada anterior.
- quebrar cadeia de hash MUST abrir incidente de integridade.

## Retencao e Redaction
- retencao minima: 12 meses.
- incidentes criticos: 24 meses.
- tokens/chaves/dados pessoais MUST ser mascarados.
- storage recomendado:
  - primario: `workspaces/main/.openclaw/audit/incidents.log` (append-only local).
  - secundario: bucket imutavel (S3 compativel) com Object Lock (compliance), versionamento e trilha diaria assinada.
  - politica eficiente: 90 dias em camada quente + 365 dias em camada fria com acesso sob trilha de auditoria.

## Links Relacionados
- [Incident Response](../SEC/SEC-INCIDENT-RESPONSE.md)
- [Degraded Procedure](./DEGRADED-MODE-PROCEDURE.md)
- [ARC Observability](../ARC/ARC-OBSERVABILITY.md)
