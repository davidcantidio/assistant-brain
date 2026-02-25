# EPIC-F2-02 Idempotency and Reconciliation Validation

- data/hora: 2026-02-25 19:15:49 -0300
- host alvo: Darwin arm64
- escopo: EPIC-F2-02 (contratos idempotentes e reconciliacao)
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/ROADMAP.md`, `PM/SPRINT-LIMITS.md`, `ARC/ARC-OBSERVABILITY.md`, `ARC/ARC-DEGRADED-MODE.md`

## ISSUE-F2-02-01 - Contratos versionados (work_order, decision, task_event)

### Red
- acao: remover temporariamente `idempotency_key` do sample valido de `work_order` no gate.
- comando: `make eval-idempotency`
- resultado: FAIL (`exit 2`)
- evidencia: `make: *** [eval-idempotency] Error 1`

### Green
- acao: restaurar sample canonico e rerodar gate.
- comando: `make eval-idempotency`
- resultado: PASS (`eval-idempotency: PASS`)

### Refactor
- comando: `make eval-gates`
- resultado: PASS

## ISSUE-F2-02-02 - SPRINT_OVERRIDE idempotente + rollback

### Red
- acao: remover temporariamente `rollback_snapshot_ref` de `PM/SPRINT-LIMITS.md`.
- comando: `make eval-idempotency`
- resultado: FAIL (`exit 2`)
- evidencia: `make: *** [eval-idempotency] Error 1`

### Green
- acao: restaurar contrato canonico de sprint override e rerodar gate.
- comando: `make eval-idempotency`
- resultado: PASS (`eval-idempotency: PASS`)

### Refactor
- comando: `make eval-gates`
- resultado: PASS

## ISSUE-F2-02-03 - Auto-acoes de observabilidade idempotentes

### Red
- acao: remover temporariamente `automation_action_id` em `ARC/ARC-OBSERVABILITY.md`.
- comando: `make eval-idempotency`
- resultado: FAIL (`exit 2`)
- evidencia: `make: *** [eval-idempotency] Error 1`

### Green
- acao: restaurar contrato canonico de auto-acao e rerodar gate.
- comando: `make eval-idempotency`
- resultado: PASS (`eval-idempotency: PASS`)

### Refactor
- comando: `make eval-gates`
- resultado: PASS

## ISSUE-F2-02-04 - Reconciliacao no degraded mode com replay_key

### Red
- acao: remover temporariamente `replay_key` em `ARC/ARC-DEGRADED-MODE.md`.
- comando: `make eval-idempotency`
- resultado: FAIL (`exit 2`)
- evidencia: `make: *** [eval-idempotency] Error 1`

### Green
- acao: restaurar contrato canonico de reconciliacao e rerodar gate.
- comando: `make eval-idempotency`
- resultado: PASS (`eval-idempotency: PASS`)

### Refactor
- comando: `make eval-gates`
- resultado: PASS

## Validacao final do epico

1. `make ci-quality` -> PASS (`quality-check: PASS`)
2. `make ci-security` -> PASS (`security-check: PASS`)
3. `make eval-idempotency` -> PASS (`eval-idempotency: PASS`)
4. `make eval-gates` -> PASS (`eval-gates: PASS`)
5. `make phase-f2-gate` -> PASS (`phase-f2-gate: PASS`)

## Rastreabilidade

- Roadmap: `B0-01`, `B0-04`, `B0-05`, `B0-06`.
- Source refs:
  - `felixcraft.md` (Tool Safety Principle, Webhook Hooks and Transforms).
  - `felix-openclaw-pontos-relevantes.md` (reexecucao de jobs e perda por sessao volatil).
