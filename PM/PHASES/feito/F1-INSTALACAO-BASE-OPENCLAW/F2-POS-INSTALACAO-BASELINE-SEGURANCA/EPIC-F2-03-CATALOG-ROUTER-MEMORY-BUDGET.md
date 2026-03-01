---
doc_id: "EPIC-F2-03-CATALOG-ROUTER-MEMORY-BUDGET.md"
version: "1.1"
status: "active"
owner: "PM"
last_updated: "2026-02-26"
rfc_refs: ["RFC-001", "RFC-015", "RFC-030", "RFC-050"]
---

# EPIC-F2-03 Catalog router memory budget baseline

## Objetivo
Fechar baseline de Model Catalog, Model Router, Memory Plane e Budget Governor com contratos auditaveis e controles de privacidade.

## Resultado de Negocio Mensuravel
- decisoes de roteamento ficam explicaveis em 100% das execucoes (`requested/effective`).
- custo e privacidade deixam de operar sem contrato minimo verificavel.

## Cobertura ROADMAP
- `B0-08`, `B0-09`, `B0-10`, `B0-11`, `B0-12`, `B0-13`, `B0-17`, `B0-18`.

## Source refs (felix)
- `felixcraft.md`: Model aliases, cost optimization, webhooks/hooks, memory QMD backend.
- `felix-openclaw-pontos-relevantes.md`: memoria em camadas, cron de consolidacao, heartbeat proativo.

## Definition of Done (Scrum)
- todas as issues do epico em estado `Done`.
- `make eval-models`, `make eval-runtime` e `make eval-gates` com `PASS`.
- artifact unico com trilha de roteamento, memoria e custo.

## Issues (Scrum + TDD + Criterios de Aceitacao)

### ISSUE-F2-03-01 - Validar Model Catalog baseline com sync e metadados minimos
**User story**
Como operador, quero catalogo de modelos atualizado para evitar roteamento com metadado incompleto.

**Owner sugerido**
- Tech Lead

**Estimativa**
- 1 dia

**Dependencias**
- `ARC/schemas/models_catalog.schema.json`
- `scripts/ci/eval_models.sh`

**Plano TDD**
1. `Red`: executar sem metadados obrigatorios (`model_id/provider/capabilities/limits/pricing/status`).
2. `Green`: exigir contrato minimo e sync periodico.
3. `Refactor`: padronizar trilha de versao de catalogo.

**Criterios de aceitacao**
- Given metadado obrigatorio ausente, When gate de modelos roda, Then o resultado deve ser `FAIL`.
- Given catalogo completo e sincronizado, When gate roda, Then o resultado deve ser `PASS`.

**Checklist QA**
- remover `catalog_synced_at` do fixture.
- remover `provider` do fixture.
- validar artifact com `catalog_version`.

### ISSUE-F2-03-02 - Validar Model Router baseline com trilha requested effective
**User story**
Como operador, quero roteamento explicavel por policy/risco/sensibilidade para auditar cada decisao.

**Owner sugerido**
- QA

**Estimativa**
- 2 dias

**Dependencias**
- `ARC/schemas/router_decision.schema.json`
- `ARC/ARC-MODEL-ROUTING.md`
- `scripts/ci/eval_models.sh`

**Plano TDD**
1. `Red`: aceitar execucao sem registrar `requested/effective`.
2. `Green`: exigir filtro por policy + ranking baseline + trilha obrigatoria com `fallback_step` e `reason`.
3. `Refactor`: alinhar com contratos de fallback auditavel.

**Criterios de aceitacao**
- Given execucao sem trilha de roteamento, When gate de compliance roda, Then o resultado deve ser `FAIL`.
- Given execucao sem `reason`, When gate de compliance roda, Then o resultado deve ser `FAIL`.
- Given `fallback_reason` presente e divergente de `reason`, When gate roda, Then o resultado deve ser `FAIL`.
- Given trilha completa por run, When gate roda, Then o resultado deve ser `PASS`.

**Checklist QA**
- remover `reason` do fixture.
- testar `fallback_reason` divergente.
- validar rastreio `requested_model/effective_model/fallback_step/reason`.

### ISSUE-F2-03-03 - Validar Memory Plane baseline e ingestao de metadados de run
**User story**
Como operador, quero memoria operacional estruturada para analise de runs, roteamento e custo.

**Owner sugerido**
- PO

**Estimativa**
- 2 dias

**Dependencias**
- `ARC/schemas/nightly_memory_cycle.schema.json`
- `ARC/ARC-HEARTBEAT.md`
- `workspaces/main/MEMORY.md`

**Plano TDD**
1. `Red`: operar sem entidades `llm_runs/router_decisions/credits_snapshots`.
2. `Green`: exigir entidades baseline, ingestao minima de metadados e ciclo `nightly-extraction` auditavel.
3. `Refactor`: alinhar qualidade da trilha com contratos de auditoria.

**Criterios de aceitacao**
- Given entidades obrigatorias ausentes, When validacao roda, Then o resultado deve ser `FAIL`.
- Given ciclo `nightly-extraction` com atraso >24h sem `incident_ref`, When validacao roda, Then o resultado deve ser `FAIL`.
- Given entidades presentes e `nightly-extraction` auditado com `scheduled_at`, `executed_at`, `status`, `daily_note_ref` e `incident_ref`, When validacao roda, Then o resultado deve ser `PASS`.

**Checklist QA**
- testar fixture noturno com `incident_ref=null` e atraso >24h.
- validar timezone `America/Sao_Paulo`.
- anexar `daily_note_ref` no artifact.

### ISSUE-F2-03-04 - Validar Budget Governor baseline e limites por run task dia
**User story**
Como operador, quero limites claros de custo para evitar burn-rate sem controle.

**Owner sugerido**
- Tech Lead

**Estimativa**
- 2 dias

**Dependencias**
- `ARC/schemas/budget_governor_policy.schema.json`
- `CORE/FINANCIAL-GOVERNANCE.md`
- `scripts/ci/eval_runtime_contracts.sh`

**Plano TDD**
1. `Red`: executar sem limite por run/task/dia.
2. `Green`: aplicar limites, telemetria `litellm_aggregated`, snapshot do provider efetivo e circuit breaker obrigatorios.
3. `Refactor`: padronizar evidencia de bloqueio por limite violado.

**Criterios de aceitacao**
- Given limite ausente, When validacao de budget roda, Then o resultado deve ser `FAIL`.
- Given `telemetry_source` ausente ou diferente de `litellm_aggregated`, When validacao de budget roda, Then o resultado deve ser `FAIL`.
- Given `provider_snapshot_source` ausente ou `burn_rate_policy` incompleto, When validacao de budget roda, Then o resultado deve ser `FAIL`.
- Given limites ativos, snapshot consistente e circuit breaker configurado, When validacao roda, Then o resultado deve ser `PASS`.

**Checklist QA**
- remover `telemetry_source` do fixture.
- remover `burn_rate_policy` do fixture.
- validar `circuit_breaker_action` no artifact.

### ISSUE-F2-03-05 - Validar A2A e hooks webhooks baseline com trace_id
**User story**
Como operador, quero delegacao e eventos externos com rastreabilidade para evitar acao opaca.

**Owner sugerido**
- Tech Lead

**Estimativa**
- 2 dias

**Dependencias**
- `ARC/schemas/openclaw_runtime_config.schema.json`
- `ARC/schemas/webhook_ingest_event.schema.json`
- `scripts/ci/eval_runtime_contracts.sh`

**Plano TDD**
1. `Red`: delegar sem allowlist ou processar webhook sem mapping.
2. `Green`: exigir `agentToAgent.allow[]`, `hooks.mappings[]`, `trace_id`, `source_hook_id`, assinatura valida e `duplicate_disposition`.
3. `Refactor`: alinhar contrato com runtime schema.

**Criterios de aceitacao**
- Given A2A fora de allowlist ou webhook sem mapping, When validacao roda, Then o resultado deve ser `FAIL`.
- Given webhook com assinatura invalida e `status!=blocked`, When validacao roda, Then o resultado deve ser `FAIL`.
- Given webhook sem `source_hook_id` ou sem `duplicate_disposition`, When validacao roda, Then o resultado deve ser `FAIL`.
- Given A2A/hooks conforme contrato, When validacao roda, Then o resultado deve ser `PASS`.

**Checklist QA**
- remover `mapping_id` do fixture de webhook.
- testar `signature_status=invalid` com `status=accepted`.
- validar `source_hook_id`, `signature_key_id` e `duplicate_disposition` no artifact.

## Artifact Minimo do Epico
- registrar em `artifacts/phase-f2/epic-f2-03-catalog-router-memory-budget.md`:
  - status de catalog/router;
  - status de memory/budget;
  - status de A2A/hooks;
  - referencias `B*` cobertas.

## Resultado desta Rodada
- `make eval-models`: `PASS` (`eval-models: PASS`).
- `make eval-runtime`: `PASS` (`eval-runtime-contracts: PASS`).
- `make eval-gates`: `PASS` (`eval-gates: PASS`).
- `make phase-f2-gate`: `PASS` (`phase-f2-gate: PASS`).
- artifacts por issue publicados:
  - `artifacts/phase-f2/epic-f2-03-issue-01-model-catalog.md`;
  - `artifacts/phase-f2/epic-f2-03-issue-02-model-router.md`;
  - `artifacts/phase-f2/epic-f2-03-issue-03-memory-plane.md`;
  - `artifacts/phase-f2/epic-f2-03-issue-04-budget-governor.md`;
  - `artifacts/phase-f2/epic-f2-03-issue-05-a2a-hooks-traceability.md`.
- artifact consolidado do epico publicado:
  - `artifacts/phase-f2/epic-f2-03-catalog-router-memory-budget.md`.
- status do epico nesta rodada: `done`.

## Dependencias
- [ARC Model Routing](../../../../../ARC/ARC-MODEL-ROUTING.md)
- [ARC Core](../../../../../ARC/ARC-CORE.md)
- [Runtime Config Schema](../../../../../ARC/schemas/openclaw_runtime_config.schema.json)
- [Roadmap](../../../../../PRD/ROADMAP.md)
- [Felixcraft Architecture](../../../../../felixcraft.md)
- [Felix OpenClaw Pontos Relevantes](../../../../../felix-openclaw-pontos-relevantes.md)
