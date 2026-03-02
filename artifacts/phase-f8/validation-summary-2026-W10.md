# F8 Validation Summary 2026-W10

- week_id: `2026-W10`
- weekly_report: `artifacts/phase-f8/weekly-governance/2026-W10.md`
- operational_readiness: `blocked`
- decision: `hold`
- release_review_status: `PASS`
- release_justification: release bloqueado por ci-quality=FAIL;release bloqueado por review_validity_status=FAIL;release bloqueado por operational_conformance_status=FAIL;phase_transition_blocked: F7 -> F8 permanece hold; ativacao prematura da F8 foi recuada ao contrato de promocao entre fases.
- phase_transition_status: `blocked`
- blocking_reason: phase_transition_blocked: F7 -> F8 permanece hold; ativacao prematura da F8 foi recuada ao contrato de promocao entre fases.
- review_validity_status: `FAIL`
- operational_conformance_status: `FAIL`
- failed_domains: `none`
- residual_risk_summary: falha de gate semanal em ci-quality;review_validity_status=FAIL;operational_conformance_status=FAIL;phase_transition_blocked: F7 -> F8 permanece hold; ativacao prematura da F8 foi recuada ao contrato de promocao entre fases.
- rollback_plan: manter a baseline vigente de F7/F8-02, sem promover F8, preservar hold e rerodar a semana apos remediacao.
- next_actions: corrigir ci-quality antes de rerodar a semana;publicar contract review da semana via F8-02;remediar dominios operacionais em FAIL: none;recuar a ativacao da F8 e preservar hold ate F7 -> F8=promote
- critical_drifts_open: `0`

## Gate Status

- eval_gates_status: `PASS`
- ci_quality_status: `FAIL`
- ci_security_status: `FAIL`

## Epic Status

- EPIC-F8-01: `done`
- EPIC-F8-02: `done`
- EPIC-F8-03: `done`
- EPIC-F8-04: `done`

## Evidence Refs

- `artifacts/phase-f8/contract-review/2026-W10.md`
- `artifacts/phase-f8/weekly-governance/2026-W10.md`
- `artifacts/phase-f8/epic-f8-03-issue-01-weekly-decision-criteria.md`
- `artifacts/phase-f8/epic-f8-03-issue-02-residual-risk-rollback.md`
- `artifacts/phase-f8/epic-f8-03-issue-03-executive-summary-audit.md`
- `artifacts/phase-f8/epic-f8-03-governanca-evolucao-release.md`
- `artifacts/phase-f8/epic-f8-04-issue-01-asset-profile-venue-adapters.md`
- `artifacts/phase-f8/epic-f8-04-issue-02-validator-evals-by-class.md`
- `artifacts/phase-f8/epic-f8-04-issue-03-shadow-r3-promote-hold.md`
- `artifacts/phase-f8/epic-f8-04-multiasset-enablement.md`
