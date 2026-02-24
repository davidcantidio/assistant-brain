---
doc_id: "INTEGRATIONS-OPENCLAW-UPSTREAM.md"
version: "1.0"
status: "active"
owner: "Architecture"
last_updated: "2026-02-24"
rfc_refs: ["RFC-001", "RFC-030", "RFC-050"]
---

# Integration - OpenClaw Upstream

## Objetivo
Manter compatibilidade documentada entre contratos locais e comportamento esperado do OpenClaw upstream, minimizando risco de schema mismatch.

## Matriz de Compatibilidade
| Interface | Status no repo | Regra normativa |
|---|---|---|
| control plane WS (canonico) | obrigatorio | `gateway.control_plane.ws` MUST existir e ser a interface canonica de orquestracao |
| chatCompletions HTTP (opcional) | opcional | `gateway.http.endpoints.chatCompletions.enabled` MAY operar sob policy e sem bypass |
| bind local | obrigatorio | `gateway.bind=loopback` MUST permanecer default |

## Contrato Atual no Repositorio
- schema local: [openclaw_runtime_config.schema.json](../ARC/schemas/openclaw_runtime_config.schema.json).
- interface canonica de runtime: `gateway.control_plane.ws`.
- interoperabilidade HTTP opcional: `gateway.http.endpoints.chatCompletions`.

## Procedimento de Revisao Periodica
- periodicidade minima: mensal ou em qualquer release upstream relevante.
- cada revisao MUST:
  - verificar breaking changes de campos no runtime config upstream;
  - atualizar matriz de compatibilidade e schema local quando necessario;
  - registrar entrada normativa em `PRD/CHANGELOG.md`.

## Checklist de Testes/Gates
- `make eval-integrations`.
- validacao JSON do schema local.
- validacao textual de presenca da matriz e dos campos canonicos (`gateway.control_plane.ws`, `chatCompletions`).

## Rollback / Fail-Closed
- quando houver incompatibilidade nao resolvida com upstream:
  - bloquear promote de mudanca de runtime;
  - manter configuracao anterior aprovada;
  - abrir decision de compatibilidade antes de nova tentativa.
