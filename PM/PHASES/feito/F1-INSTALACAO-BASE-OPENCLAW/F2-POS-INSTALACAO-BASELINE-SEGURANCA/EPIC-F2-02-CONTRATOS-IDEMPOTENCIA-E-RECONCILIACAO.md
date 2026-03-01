---
doc_id: "EPIC-F2-02-CONTRATOS-IDEMPOTENCIA-E-RECONCILIACAO.md"
version: "1.1"
status: "active"
owner: "PM"
last_updated: "2026-02-25"
rfc_refs: ["RFC-001", "RFC-015", "RFC-040", "RFC-050"]
---

# EPIC-F2-02 Contratos idempotencia e reconciliacao

## Objetivo
Cobrir contratos minimos de trabalho/evento/decisao e garantir idempotencia + rollback + reconciliacao no degraded mode sem perda de trilha.

## Resultado de Negocio Mensuravel
- overrides e auto-acoes deixam de ter side effect duplicado ou rollback indefinido.
- degraded mode opera com trilha de reconciliacao auditavel (`idempotency_key` + `replay_key`).

## Cobertura ROADMAP
- `B0-01`, `B0-04`, `B0-05`, `B0-06`.

## Source refs (felix)
- `felixcraft.md`: Tool Safety Principle; Prompt Injection Defense; Webhook Hooks and Transforms.
- `felix-openclaw-pontos-relevantes.md`: seguranca por canal; heartbeat e reexecucao de jobs; evitar perda por sessao volatil.

## Definition of Done (Scrum)
- todas as issues do epico em estado `Done`.
- `make eval-gates` com `PASS` para claims de idempotencia/reconciliacao.
- artifact com fluxos `Red/Green` e evidencias de no-op duplicate + rollback.

## Issues (Scrum + TDD + Criterios de Aceitacao)

### ISSUE-F2-02-01 - Validar contratos work_order decision task_event com schema versionado
**User story**
Como operador, quero contratos tipados de trabalho e decisao para manter interoperabilidade e auditoria.

**Owner sugerido**
- Tech Lead

**Estimativa**
- 1 dia

**Dependencias**
- `ARC/schemas/work_order.schema.json`
- `ARC/schemas/decision.schema.json`
- `ARC/schemas/task_event.schema.json`

**Plano TDD**
1. `Red`: introduzir payload invalido sem schema compativel.
2. `Green`: validar contratos versionados para `work_order`, `decision`, `task_event`.
3. `Refactor`: consolidar exemplos canonicos e links de schema.

**Criterios de aceitacao**
- Given payload fora de contrato, When validacao de schema ocorre, Then o gate falha.
- Given payload conforme contratos versionados, When validacao ocorre, Then o gate retorna `PASS`.

**Checklist QA**
- validar payload invalido para `work_order`.
- validar payload invalido para `decision`.
- anexar links dos schemas canonicos no artifact.

### ISSUE-F2-02-02 - Validar SPRINT_OVERRIDE com idempotencia e rollback executavel
**User story**
Como operador, quero override de sprint sem duplicidade e com rollback garantido para evitar regressao operacional.

**Owner sugerido**
- Tech Lead

**Estimativa**
- 1 dia

**Dependencias**
- `PM/SPRINT-LIMITS.md`
- `scripts/ci/eval_idempotency_reconciliation.sh`

**Plano TDD**
1. `Red`: reaplicar override com mesma chave gerando novo efeito colateral.
2. `Green`: aplicar no-op duplicate por `override_key` e exigir rollback previo documentado.
3. `Refactor`: alinhar com `SPRINT-LIMITS` e evidencias de execucao.

**Criterios de aceitacao**
- Given reaplicacao com mesma `override_key`, When override e executado, Then resultado deve ser no-op.
- Given override sem rollback definido, When tentativa ocorre, Then operacao deve ser bloqueada.

**Checklist QA**
- reexecutar mesma `override_key`.
- remover `rollback_snapshot_ref` do fixture e validar bloqueio.
- anexar `rollback_snapshot_ref` no artifact.

### ISSUE-F2-02-03 - Validar contrato idempotente para auto-acoes de saude observabilidade
**User story**
Como operador, quero auto-acoes com idempotencia para evitar acao duplicada em ciclos de saude.

**Owner sugerido**
- Tech Lead

**Estimativa**
- 2 dias

**Dependencias**
- `ARC/schemas/automation_action_event.schema.json`
- `ARC/ARC-OBSERVABILITY.md`
- `EVALS/SYSTEM-HEALTH-THRESHOLDS.md`

**Plano TDD**
1. `Red`: executar auto-acao repetida sem deduplicacao.
2. `Green`: exigir `automation_action_id`, `has_side_effect` e rollback obrigatorio para auto-acao com side effect.
3. `Refactor`: consolidar recomendacao de retry/rollback e auditoria.

**Criterios de aceitacao**
- Given auto-acao repetida com mesma chave, When processamento ocorre, Then deve ser no-op.
- Given auto-acao sem contrato idempotente, When gate roda, Then resultado deve ser `FAIL`.
- Given auto-acao com `has_side_effect=true` e sem `rollback_plan_ref`, When gate roda, Then resultado deve ser `FAIL_STOP_SHIP`.
- Given auto-acao sem side effect e sem rollback, When gate roda, Then resultado deve ser `NOTIFY_ONLY`.

**Checklist QA**
- replay com mesma `idempotency_key`.
- teste negativo de `has_side_effect=true` sem `rollback_plan_ref`.
- teste de `NOTIFY_ONLY` apenas para acao sem side effect.

### ISSUE-F2-02-04 - Validar reconciliador de degraded mode com replay_key e trilha de incidente
**User story**
Como operador, quero reconciliacao controlada no degradado para evitar perda de estado em recuperacao.

**Owner sugerido**
- Tech Lead

**Estimativa**
- 2 dias

**Dependencias**
- `ARC/schemas/degraded_reconciliation_status.schema.json`
- `ARC/ARC-DEGRADED-MODE.md`
- `scripts/ci/check_phase_f2_gate.sh`

**Plano TDD**
1. `Red`: reconciliar evento sem `idempotency_key`/`replay_key`.
2. `Green`: exigir chaves de reconciliacao, incidente e `promotion_blocked` ate a reconciliacao final.
3. `Refactor`: alinhar com runbook de degraded mode.

**Criterios de aceitacao**
- Given evento sem chaves obrigatorias, When reconciliacao ocorre, Then o fluxo deve ser bloqueado.
- Given evento com chaves validas, When reconciliacao ocorre, Then o estado final e auditavel e deterministico.
- Given reconciliacao ainda pendente, When `phase-f2-gate` roda, Then a promocao deve permanecer bloqueada.
- Given reconciliacao concluida, When `degraded_reconciliation_status` e publicado, Then `promotion_blocked=false`.

**Checklist QA**
- remover `replay_key` do fixture e validar bloqueio.
- testar `status=pending` com `promotion_blocked=true`.
- validar artifact `artifacts/phase-f2/degraded-reconciliation-status.json`.

## Artifact Minimo do Epico
- registrar em `artifacts/phase-f2/epic-f2-02-idempotency-reconciliation.md`:
  - cobertura de contratos `work_order/decision/task_event`;
  - evidencias de no-op duplicate e rollback;
  - evidencias de reconciliacao em degraded mode;
  - `degraded_reconciliation_status` com `promotion_blocked`;
  - referencias `B*` cobertas.

## Resultado desta Rodada
- `make eval-idempotency`: `PASS` (`eval-idempotency: PASS`).
- `make eval-gates`: `PASS` (`eval-gates: PASS`).
- `make phase-f2-gate`: `PASS` (`phase-f2-gate: PASS`).
- artifact final publicado: `artifacts/phase-f2/epic-f2-02-idempotency-reconciliation.md`.
- status do epico nesta rodada: `done`.

## Dependencias
- [Sprint Limits](../../../../../PM/SPRINT-LIMITS.md)
- [ARC Observability](../../../../../ARC/ARC-OBSERVABILITY.md)
- [ARC Degraded Mode](../../../../../ARC/ARC-DEGRADED-MODE.md)
- [Roadmap](../../../../../PRD/ROADMAP.md)
- [Felixcraft Architecture](../../../../../felixcraft.md)
