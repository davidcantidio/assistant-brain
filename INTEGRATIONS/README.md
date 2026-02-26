---
doc_id: "INTEGRATIONS-README.md"
version: "1.0"
status: "active"
owner: "Architecture"
last_updated: "2026-02-24"
rfc_refs: ["RFC-001", "RFC-015", "RFC-030", "RFC-050", "RFC-060"]
---

# Integrations Package

## Objetivo
Definir contrato normativo unico para integracoes externas, reduzindo improviso de implementacao e eliminando bypass de risco/auditoria.

## Escopo
Inclui:
- regras obrigatorias para AI-Trader, ClawWork e OpenClaw upstream.
- modos permitidos e fora de escopo por integracao.
- contratos versionados (schemas JSON) e gates de CI.
- modelo minimo de threat model e rollback por integracao.

Exclui:
- implementacao de codigo operacional de adapters neste repositorio.
- alteracao de politicas de repositorios externos.

## Template Obrigatorio por Integracao
Cada documento em `INTEGRATIONS/` MUST conter:
- objetivo da integracao.
- modo permitido.
- fora de escopo e bloqueios explicitos.
- threat model resumido.
- contratos/schemas associados.
- checklist minimo de testes/gates.
- estrategia de rollback/fail-closed.

## Matriz de Modos Permitidos
| Integracao | Modo permitido | Regra anti-bypass |
|---|---|---|
| AI-Trader | `signal_only` | gera apenas `signal_intent`; envio direto de `order_intent` para venue e bloqueado |
| ClawWork | `lab_isolated` (default) e `governed` (gateway-only) | em `governed`, chamada direta a provider externo e bloqueada |
| OpenClaw upstream | runtime canonico via `gateway.control_plane.ws` com `chatCompletions` opcional sob policy | interface opcional HTTP nao pode criar bypass de policy/gates |

## Artefatos Canonicos
- [AI-Trader](./AI-TRADER.md)
- [ClawWork](./CLAWWORK.md)
- [OpenClaw Upstream](./OPENCLAW-UPSTREAM.md)
- [signal_intent schema](../ARC/schemas/signal_intent.schema.json)
- [order_intent schema](../ARC/schemas/order_intent.schema.json)
- [execution_report schema](../ARC/schemas/execution_report.schema.json)
- [economic_run schema](../ARC/schemas/economic_run.schema.json)

## Gate de Compliance
- comando obrigatorio: `make eval-integrations`.
- `eval-integrations` MUST falhar em:
  - documento ausente no pacote;
  - schema invalido;
  - linguagem ambigua sobre OpenRouter/default cloud;
  - ausencia de bloqueio explicito para bypass de ordem externa.
