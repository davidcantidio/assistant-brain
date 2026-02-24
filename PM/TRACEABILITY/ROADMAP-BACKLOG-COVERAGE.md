---
doc_id: "ROADMAP-BACKLOG-COVERAGE.md"
version: "1.0"
status: "active"
owner: "PM"
last_updated: "2026-02-24"
rfc_refs: ["RFC-001", "RFC-040", "RFC-050", "RFC-060"]
---

# Cobertura Backlog ROADMAP -> Epics/Issues

## Objetivo
Mapear cada item `B*` do `PRD/ROADMAP.md` para ao menos uma issue executavel, com rastreabilidade para fontes Felix quando aplicavel.

## Regras
- status permitido: `covered_existing`, `covered_new`, `covered_refinement_origin`.
- `covered_refinement_origin` deve apontar para issue de refinamento (`R*`) ou decisao equivalente.
- item sem linha nesta matriz bloqueia promocao de fase.

## Matriz
| Backlog ID | Status | Epic/Issue mapeada | Fonte Felix principal | Observacao |
|---|---|---|---|---|
| `B0-01` | covered_new | `EPIC-F2-02` / `ISSUE-F2-02-01` | felixcraft: structured operations | contratos `work_order/decision/task_event` |
| `B0-02` | covered_existing | `EPIC-F6-01` / `ISSUE-F6-01-01` | pontos: canal autenticado | Telegram + operador validado |
| `B0-03` | covered_existing | `EPIC-F6-02` / `ISSUE-F6-02-01` | felixcraft: approval flow | lifecycle de challenge |
| `B0-04` | covered_new | `EPIC-F2-02` / `ISSUE-F2-02-02` | felixcraft: safety rails | override idempotente + rollback |
| `B0-05` | covered_new | `EPIC-F2-02` / `ISSUE-F2-02-03` | felixcraft: bounded autonomy | auto-acoes idempotentes |
| `B0-06` | covered_new | `EPIC-F2-02` / `ISSUE-F2-02-04` | pontos: contingencia | reconciliacao com replay |
| `B0-07` | covered_existing | `EPIC-F3-01` / `ISSUE-F3-01-02` | felixcraft: gateway config | runtime gateway contract |
| `B0-08` | covered_new | `EPIC-F2-03` / `ISSUE-F2-03-01` | felixcraft: model aliases/catalog | baseline de catalogo |
| `B0-09` | covered_new | `EPIC-F2-03` / `ISSUE-F2-03-02` | felixcraft: routing | baseline de router |
| `B0-10` | covered_refinement_origin | `EPIC-F5-03` / `ISSUE-F5-03-03` | felixcraft: production config | origem de `presets` |
| `B0-11` | covered_new | `EPIC-F2-03` / `ISSUE-F2-03-03` | pontos: memoria em camadas | entidades baseline de memoria |
| `B0-12` | covered_refinement_origin | `EPIC-F2-03` / `ISSUE-F2-03-03` | felixcraft: audit trail | ingestao de metadados de run |
| `B0-13` | covered_new | `EPIC-F2-03` / `ISSUE-F2-03-04` | felixcraft: cost optimization | budget governor baseline |
| `B0-14` | covered_new | `EPIC-F2-01` / `ISSUE-F2-01-02` | felixcraft: safety rules | classificacao + allowlist + retention |
| `B0-15` | covered_new | `EPIC-F2-01` / `ISSUE-F2-01-01` | felixcraft: operational discipline | harness unico de evals |
| `B0-16` | covered_new | `EPIC-F2-01` / `ISSUE-F2-01-01` | felixcraft: reliability via checks | gates em GitHub Actions |
| `B0-17` | covered_new | `EPIC-F2-03` / `ISSUE-F2-03-05` | felixcraft: multi-agent architecture | A2A allowlist + trace |
| `B0-18` | covered_new | `EPIC-F2-03` / `ISSUE-F2-03-05` | felixcraft: webhooks transforms | hooks/webhooks baseline |
| `B0-19` | covered_existing | `EPIC-F6-01` / `ISSUE-F6-01-01` | pontos: controle por Telegram | `OPERATORS.yaml` |
| `B0-20` | covered_existing | `EPIC-F3-02` / `ISSUE-F3-02-01` | pontos: daily notes | `memory_contract` |
| `B0-21` | covered_existing | `EPIC-F6-01` / `ISSUE-F6-01-02` | felixcraft: email hard rules | `approval_policy` |
| `B1-01` | covered_new | `EPIC-F5-01` / `ISSUE-F5-01-01` | pontos: engine de sinal | adapter TradingAgents |
| `B1-02` | covered_new | `EPIC-F5-01` / `ISSUE-F5-01-01` | pontos: deduplicacao | signal normalizer |
| `B1-03` | covered_new | `EPIC-F5-01` / `ISSUE-F5-01-02` | felixcraft: safety rails | bloqueio de ordem direta externa |
| `B1-04` | covered_refinement_origin | `EPIC-F5-02` / `ISSUE-F5-02-03` | pontos: degradacao segura | origem de `single_engine_mode` |
| `B1-05` | covered_new | `EPIC-F5-02` / `ISSUE-F5-02-01` | pontos: controle de risco | validator por simbolo |
| `B1-06` | covered_new | `EPIC-F5-02` / `ISSUE-F5-02-02` | pontos: reconciliacao | idempotencia por ordem |
| `B1-07` | covered_new | `EPIC-F5-02` / `ISSUE-F5-02-03` | pontos: contingencia | fail_closed primaria |
| `B1-08` | covered_new | `EPIC-F5-02` / `ISSUE-F5-02-05` | pontos: degradacao com posicao aberta | runbook + `TRADING_BLOCKED` |
| `B1-09` | covered_new | `EPIC-F5-02` / `ISSUE-F5-02-04` | pontos: mitigacao de risco por acesso | credenciais no-withdraw + IP allowlist |
| `B1-10` | covered_new | `EPIC-F5-02` / `ISSUE-F5-02-01` | felixcraft: contract-first | contratos versionados de execucao |
| `B1-11` | covered_new | `EPIC-F5-01` / `ISSUE-F5-01-02` | felixcraft: allowlist discipline | dominios de venue |
| `B1-12` | covered_new | `EPIC-F5-02` / `ISSUE-F5-02-04` | felixcraft: CI before done | eval-trading obrigatorio em CI |
| `B1-13` | covered_existing | `EPIC-F7-01` / `ISSUE-F7-01-01` | pontos: rollout conservador | S0 obrigatorio sem ordem real |
| `B1-14` | covered_existing | `EPIC-F7-01` / `ISSUE-F7-01-02` | pontos: aprovacao humana | modo assistido no S1 inicial |
| `B1-15` | covered_refinement_origin | `EPIC-F7-03` / `ISSUE-F7-03-01` | pontos: criterio de promocao | origem de criterios S1->S2 |
| `B1-20` | covered_existing | `EPIC-F4-01` / `ISSUE-F4-01-01` | pontos: integracoes explicitas | pacote `INTEGRATIONS/` |
| `B1-21` | covered_existing | `EPIC-F4-02` / `ISSUE-F4-02-01` | felixcraft: contracts | schemas versionados |
| `B1-22` | covered_existing | `EPIC-F4-01` / `ISSUE-F4-01-02` | pontos: signal-only | AI-Trader sem ordem direta |
| `B1-23` | covered_existing | `EPIC-F4-01` / `ISSUE-F4-01-03` | pontos: modos permitidos | ClawWork `lab_isolated/governed` |
| `B1-24` | covered_existing | `EPIC-F4-02` / `ISSUE-F4-02-03` | felixcraft: ws + chat endpoint | compatibilidade runtime |
| `B1-R08` | covered_new | `EPIC-F5-03` / `ISSUE-F5-03-03` | felixcraft: production config | catalogo versionado expandido |
| `B1-R09` | covered_new | `EPIC-F5-03` / `ISSUE-F5-03-03` | felixcraft: routing controls | provider routing/pin/no-fallback |
| `B1-R10` | covered_new | `EPIC-F5-03` / `ISSUE-F5-03-03` | felixcraft: config governance | presets versionados |
| `B1-R11` | covered_new | `EPIC-F2-03` / `ISSUE-F2-03-03` | pontos: memoria em camadas | memory plane vetorial expandido |
| `B1-R12` | covered_new | `EPIC-F2-03` / `ISSUE-F2-03-03` | felixcraft: observability | metadados completos de run |
| `B1-R13` | covered_new | `EPIC-F5-03` / `ISSUE-F5-03-03` | felixcraft: cost optimization | burn-rate e circuit breaker |
| `B1-R14` | covered_new | `EPIC-F5-03` / `ISSUE-F5-03-03` | felixcraft: safety boundaries | retention/ZDR por sensibilidade |
| `B1-R16` | covered_new | `EPIC-F5-03` / `ISSUE-F5-03-04` | felixcraft: multi-agent delegation | A2A cross-workspace |
| `B1-R17` | covered_new | `EPIC-F5-03` / `ISSUE-F5-03-04` | pontos: threads e rastreio | adapter Slack task_event |
| `B1-R18` | covered_new | `EPIC-F5-03` / `ISSUE-F5-03-05` | pontos: contingencia de canal | fallback HITL + restore telegram |
| `B1-R19` | covered_new | `EPIC-F5-03` / `ISSUE-F5-03-05` | pontos: fallback pronto antes de live | IDs Slack + backup operator |
| `B2-01` | covered_new | `EPIC-F8-04` / `ISSUE-F8-04-01` | pontos: expansao gradual | schema `asset_profile` por classe |
| `B2-02` | covered_new | `EPIC-F8-04` / `ISSUE-F8-04-01` | pontos: execucao governada | adapters de venue por classe |
| `B2-03` | covered_new | `EPIC-F8-04` / `ISSUE-F8-04-02` | pontos: hard-risk por classe | validator multiativos |
| `B2-04` | covered_new | `EPIC-F8-04` / `ISSUE-F8-04-02` | pontos: testes bloqueantes | suites `eval-trading-<asset_class>` |
| `B2-05` | covered_new | `EPIC-F8-04` / `ISSUE-F8-04-03` | pontos: promote gradual | shadow mode por classe |
| `B2-R04` | covered_new | `EPIC-F5-02` / `ISSUE-F5-02-03` | pontos: degradacao segura | single_engine_mode secundario |
| `B2-R15` | covered_existing | `EPIC-F7-03` / `ISSUE-F7-03-01` | pontos: criterios objetivos de promocao | 30 dias sem violacao hard |

## Criterio de aceite desta matriz
- 100% dos IDs `B*` presentes em `PRD/ROADMAP.md` mapeados.
- nenhuma linha com status `gap`.
- toda issue nova mapeada deve existir fisicamente em `PM/PHASES/*`.
