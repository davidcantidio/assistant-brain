# F6 HITL Readiness Checklist

- checklist_id: HITL-F6-20260301-01
- operator_id: primary-01
- primary_channel: telegram
- fallback_channel: slack
- telegram_identity_validated: pass
- trusted_channel_evidence: `operator_id=primary-01` vinculado a `primary_channel=telegram` no mesmo ciclo de `make ci-security`
- slack_fallback_validated: fail
- challenge_flow_validated: pass
- command_idempotency_validated: pass
- ci_security_status: PASS
- security_check_cycle_ref: `2026-03-01T10:55:00-03:00`
- restore_telegram_channel_status: `not-opened` (fallback Slack nao foi acionado nesta rodada)
- decision_id: `not-issued`
- consolidation_owner: `pm`
- review_due_date: `2026-03-03`
- decision_protocol_ref: `PM/DECISION-PROTOCOL.md`
- result: hold
- justification: `SEC/allowlists/OPERATORS.yaml` mantem `live_ready: false` e operador habilitado (`primary-01`) com `slack_ready: false` + `slack_user_ids/slack_channel_ids` vazios, portanto fallback HITL nao esta validado para live.

## Evidencias de suporte
- `artifacts/phase-f6/epic-f6-01-identity-channel.md`
- `artifacts/phase-f6/epic-f6-02-challenge-audit.md`
- `artifacts/phase-f6/epic-f6-03-issue-01-telegram-degraded-slack-fallback-controlled.md`
- `artifacts/phase-f6/epic-f6-03-issue-02-trading-blocked-without-valid-hitl-fallback.md`
- `artifacts/phase-f6/epic-f6-03-issue-03-phase-evidence-promote-hold.md`
