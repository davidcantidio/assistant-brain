# EPIC-F8-02 Contract Review Drift Summary

- data/hora: 2026-03-01 08:58:01 -0300
- status do epic: `done`
- semana autoritativa: `2026-W09`

## Comandos executados nesta rodada

1. `make phase-f8-contract-review` -> `phase-f8-contract-review: PASS`
2. `make phase-f8-weekly-governance` -> `phase-f8-weekly-governance: decision=hold`
3. `make ci-quality` -> `quality-check: PASS`

## Estado consolidado do epic

| Issue | Status | Evidencia |
|---|---|---|
| `ISSUE-F8-02-01` | done | `artifacts/phase-f8/epic-f8-02-issue-01-contract-review-conformity.md` |
| `ISSUE-F8-02-02` | done | `artifacts/phase-f8/epic-f8-02-issue-02-drift-remediation-backlog.md` |
| `ISSUE-F8-02-03` | done | `artifacts/phase-f8/epic-f8-02-issue-03-prior-week-critical-drift-closure.md` |

## Artifact canonico

- revisao contratual: `artifacts/phase-f8/contract-review/2026-W09.md`
- governanca semanal: `artifacts/phase-f8/weekly-governance/2026-W09.md`

## Decisao operacional atual

- `review_validity_status`: `PASS`
- `operational_conformance_status`: `FAIL`
- `failed_domains`: `trading`
- `critical_drifts_open`: `1`
- `decision`: `hold`
- justificativa:
  - `DRIFT-F8-2026-W09-01` permanece `critical/open`;
  - o primeiro ciclo ainda nao possui semana anterior para carry-over, entao `previous_week_id=none` foi aceito;
  - a promocao semanal continua bloqueada ate fechamento ou aceitacao formal do drift critico.

## Carry-over real requerido

- `ISSUE-F8-02-03` depende de rodada operacional real `2026-W10`.
- em `2026-W10`, `previous_week_id` deve ser `2026-W09` e `carried_over_drifts` deve classificar `DRIFT-F8-2026-W09-01` como `closed`, `risk_accepted` (com `risk_exception_ref`) ou `open`.
- nenhum artifact sintetico `2026-W10` deve ser publicado antes da semana real.
