#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

search_re() {
  local pattern="$1"
  shift
  if command -v rg >/dev/null 2>&1; then
    rg -n -- "$pattern" "$@" >/dev/null
  else
    grep -nE -- "$pattern" "$@" >/dev/null
  fi
}

required_files=(
  "ARC/schemas/work_order.schema.json"
  "ARC/schemas/decision.schema.json"
  "ARC/schemas/task_event.schema.json"
  "PM/WORK-ORDER-SPEC.md"
  "PM/DECISION-PROTOCOL.md"
  "ARC/ARC-CORE.md"
  "PM/SPRINT-LIMITS.md"
  "ARC/ARC-OBSERVABILITY.md"
  "EVALS/SYSTEM-HEALTH-THRESHOLDS.md"
  "ARC/ARC-DEGRADED-MODE.md"
  "INCIDENTS/DEGRADED-MODE-PROCEDURE.md"
)

for f in "${required_files[@]}"; do
  [[ -f "$f" ]] || { echo "Arquivo obrigatorio ausente: $f"; exit 1; }
done

python3 -m json.tool ARC/schemas/work_order.schema.json >/dev/null
python3 -m json.tool ARC/schemas/decision.schema.json >/dev/null
python3 -m json.tool ARC/schemas/task_event.schema.json >/dev/null

search_re "## Contrato SPRINT_OVERRIDE" PM/SPRINT-LIMITS.md
search_re "override_key" PM/SPRINT-LIMITS.md
search_re "coalescing_key" PM/SPRINT-LIMITS.md
search_re "rollback_token" PM/SPRINT-LIMITS.md
search_re "rollback_snapshot_ref" PM/SPRINT-LIMITS.md
search_re 'reaplicacao com mesma `override_key` MUST ser no-op' PM/SPRINT-LIMITS.md
search_re 'antes de `APPLIED`, MUST existir `rollback_snapshot_ref` valido' PM/SPRINT-LIMITS.md

search_re "## Contrato de Auto-Acao \\(obrigatorio\\)" ARC/ARC-OBSERVABILITY.md
search_re "automation_action_id" ARC/ARC-OBSERVABILITY.md
search_re "automation_action_id" EVALS/SYSTEM-HEALTH-THRESHOLDS.md
search_re "coalescing_key" ARC/ARC-OBSERVABILITY.md
search_re "coalescing_key" EVALS/SYSTEM-HEALTH-THRESHOLDS.md
search_re "idempotency_key" ARC/ARC-OBSERVABILITY.md
search_re "idempotency_key" EVALS/SYSTEM-HEALTH-THRESHOLDS.md
search_re "rollback_plan_ref" ARC/ARC-OBSERVABILITY.md
search_re "rollback_plan_ref" EVALS/SYSTEM-HEALTH-THRESHOLDS.md
search_re "NO_OP_DUPLICATE" ARC/ARC-OBSERVABILITY.md
search_re "NO_OP_DUPLICATE" EVALS/SYSTEM-HEALTH-THRESHOLDS.md
search_re "notify-only" ARC/ARC-OBSERVABILITY.md
search_re "notify-only" EVALS/SYSTEM-HEALTH-THRESHOLDS.md

search_re "idempotency_key" ARC/ARC-DEGRADED-MODE.md
search_re "replay_key" ARC/ARC-DEGRADED-MODE.md
search_re "replay_key = work_order_id \\+ \":\" \\+ task_id \\+ \":\" \\+ event_type \\+ \":\" \\+ attempt" ARC/ARC-DEGRADED-MODE.md
search_re 'qualquer evento com `replay_key` repetida MUST ser ignorado e auditado' ARC/ARC-DEGRADED-MODE.md
search_re 'reconciliador deterministico \(`idempotency_key`, `replay_key`, hash-chain\)' INCIDENTS/DEGRADED-MODE-PROCEDURE.md
search_re "idempotency_key" PM/WORK-ORDER-SPEC.md
search_re "replay_key" PM/WORK-ORDER-SPEC.md
search_re "reconciliacao offline sem duplicidade" EVALS/SYSTEM-HEALTH-THRESHOLDS.md

python3 - <<'PY'
import datetime as dt
import json
import sys
from pathlib import Path

EXPECTING_INVALID = False


def fail(msg: str) -> None:
    if EXPECTING_INVALID:
        raise ValueError(msg)
    print(msg)
    sys.exit(1)


def parse_iso8601(value: str, field: str) -> None:
    if not isinstance(value, str):
        fail(f"{field} invalido: deve ser string ISO-8601.")
    try:
        dt.datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        fail(f"{field} invalido: timestamp ISO-8601 esperado.")


def parse_optional_iso8601(value, field: str) -> None:
    if value is None:
        return
    parse_iso8601(value, field)


def assert_string(payload: dict, field: str, ctx: str) -> None:
    value = payload.get(field)
    if not isinstance(value, str) or not value.strip():
        fail(f"{ctx} invalido: campo '{field}' deve ser string nao vazia.")


def assert_nullable_string(payload: dict, field: str, ctx: str) -> None:
    value = payload.get(field)
    if value is None:
        return
    if not isinstance(value, str) or not value.strip():
        fail(f"{ctx} invalido: campo '{field}' deve ser string nao vazia ou null.")


def assert_enum(payload: dict, field: str, allowed: set[str], ctx: str) -> None:
    value = payload.get(field)
    if value not in allowed:
        fail(f"{ctx} invalido: campo '{field}' fora do enum permitido.")


def assert_min_int(payload: dict, field: str, min_value: int, ctx: str) -> None:
    value = payload.get(field)
    if not isinstance(value, int) or value < min_value:
        fail(f"{ctx} invalido: campo '{field}' deve ser inteiro >= {min_value}.")


def check_required_and_additional(schema: dict, payload: dict, ctx: str) -> None:
    required = schema.get("required", [])
    properties = set(schema.get("properties", {}).keys())
    missing = sorted([k for k in required if k not in payload])
    if missing:
        fail(f"{ctx} invalido: campos obrigatorios ausentes: {missing}")
    if schema.get("additionalProperties") is False:
        extras = sorted([k for k in payload.keys() if k not in properties])
        if extras:
            fail(f"{ctx} invalido: campos extras nao permitidos: {extras}")


def validate_work_order(payload: dict, schema: dict, ctx: str) -> None:
    check_required_and_additional(schema, payload, ctx)
    assert_string(payload, "schema_version", ctx)
    assert_string(payload, "work_order_id", ctx)
    assert_string(payload, "idempotency_key", ctx)
    assert_string(payload, "objective", ctx)
    assert_enum(payload, "risk_class", {"baixo", "medio", "alto"}, ctx)
    assert_enum(payload, "risk_tier", {"R0", "R1", "R2", "R3"}, ctx)
    assert_enum(payload, "data_sensitivity", {"public", "internal", "sensitive"}, ctx)
    assert_enum(payload, "status", {"DRAFT", "APPROVED", "IN_PROGRESS", "DONE", "CANCELLED"}, ctx)
    parse_iso8601(payload.get("created_at"), f"{ctx}.created_at")


def validate_decision(payload: dict, schema: dict, ctx: str) -> None:
    check_required_and_additional(schema, payload, ctx)
    assert_string(payload, "schema_version", ctx)
    assert_string(payload, "decision_id", ctx)
    assert_string(payload, "decision_key", ctx)
    assert_string(payload, "title", ctx)
    assert_string(payload, "proposal", ctx)
    assert_enum(payload, "risk_class", {"baixo", "medio", "alto"}, ctx)
    assert_enum(payload, "risk_tier", {"R0", "R1", "R2", "R3"}, ctx)
    assert_enum(payload, "data_sensitivity", {"public", "internal", "sensitive"}, ctx)
    assert_enum(payload, "status", {"PENDING", "APPROVED", "REJECTED", "KILLED", "EXPIRED"}, ctx)
    assert_enum(
        payload,
        "challenge_status",
        {"NOT_REQUIRED", "PENDING", "VALIDATED", "EXPIRED", "INVALIDATED"},
        ctx,
    )
    assert_nullable_string(payload, "challenge_id", ctx)
    parse_iso8601(payload.get("created_at"), f"{ctx}.created_at")
    parse_iso8601(payload.get("timeout_at"), f"{ctx}.timeout_at")
    parse_optional_iso8601(payload.get("challenge_expires_at"), f"{ctx}.challenge_expires_at")

    challenge_status = payload.get("challenge_status")
    challenge_id = payload.get("challenge_id")
    challenge_expires_at = payload.get("challenge_expires_at")
    if challenge_status == "NOT_REQUIRED":
        if challenge_id is not None:
            fail(f"{ctx} invalido: challenge_id deve ser null quando challenge_status=NOT_REQUIRED.")
        if challenge_expires_at is not None:
            fail(
                f"{ctx} invalido: challenge_expires_at deve ser null quando challenge_status=NOT_REQUIRED."
            )
        return

    if challenge_id is None:
        fail(
            f"{ctx} invalido: challenge_id obrigatorio para challenge_status "
            "PENDING/VALIDATED/EXPIRED/INVALIDATED."
        )
    if challenge_expires_at is None:
        fail(
            f"{ctx} invalido: challenge_expires_at obrigatorio para challenge_status "
            "PENDING/VALIDATED/EXPIRED/INVALIDATED."
        )


def validate_task_event(payload: dict, schema: dict, ctx: str) -> None:
    check_required_and_additional(schema, payload, ctx)
    assert_string(payload, "schema_version", ctx)
    assert_string(payload, "event_id", ctx)
    assert_string(payload, "work_order_id", ctx)
    assert_string(payload, "task_id", ctx)
    assert_string(payload, "event_type", ctx)
    assert_string(payload, "trace_id", ctx)
    assert_string(payload, "idempotency_key", ctx)
    assert_min_int(payload, "attempt", 1, ctx)
    assert_string(payload, "replay_key", ctx)
    parse_iso8601(payload.get("created_at"), f"{ctx}.created_at")


def expect_invalid(check_fn, payload: dict, schema: dict, label: str) -> None:
    global EXPECTING_INVALID
    try:
        EXPECTING_INVALID = True
        check_fn(payload, schema, label)
    except (SystemExit, ValueError):
        return
    finally:
        EXPECTING_INVALID = False
    fail(f"{label} deveria falhar, mas passou.")


def expected_required_in_schema(schema: dict, expected_fields: set[str], label: str) -> None:
    required = set(schema.get("required", []))
    missing = sorted(expected_fields - required)
    if missing:
        fail(f"{label} sem campos obrigatorios minimos esperados: {missing}")
    if schema.get("additionalProperties") is not False:
        fail(f"{label} deve definir additionalProperties=false")


def validate_sprint_override_payload(payload: dict, ctx: str) -> None:
    required_fields = {
        "override_key",
        "coalescing_key",
        "sprint_id",
        "limit_type",
        "requested_delta",
        "status",
        "source_alert_id",
        "rollback_token",
        "rollback_snapshot_ref",
    }
    missing = sorted([k for k in required_fields if k not in payload])
    if missing:
        fail(f"{ctx} invalido: campos obrigatorios ausentes: {missing}")

    assert_string(payload, "override_key", ctx)
    assert_string(payload, "coalescing_key", ctx)
    assert_string(payload, "sprint_id", ctx)
    assert_string(payload, "limit_type", ctx)
    assert_string(payload, "requested_delta", ctx)
    assert_string(payload, "status", ctx)
    assert_string(payload, "source_alert_id", ctx)
    assert_string(payload, "rollback_token", ctx)
    assert_string(payload, "rollback_snapshot_ref", ctx)

    assert_enum(
        payload,
        "status",
        {"REQUESTED", "APPROVED", "APPLIED", "ROLLED_BACK", "REJECTED", "EXPIRED"},
        ctx,
    )


def apply_sprint_override(state: dict, payload: dict, ctx: str) -> str:
    validate_sprint_override_payload(payload, ctx)
    key = payload["override_key"]

    if key in state["applied_by_key"]:
        return "NO_OP_DUPLICATE"

    if payload["status"] == "APPLIED" and not payload.get("rollback_snapshot_ref"):
        fail(f"{ctx} invalido: rollback_snapshot_ref obrigatorio para status APPLIED.")

    state["applied_by_key"].add(key)
    return "APPLIED"


def validate_automation_action_payload(payload: dict, ctx: str) -> None:
    required_fields = {
        "automation_action_id",
        "coalescing_key",
        "idempotency_key",
        "action_type",
        "status",
    }
    missing = sorted([k for k in required_fields if k not in payload])
    if missing:
        fail(f"{ctx} invalido: campos obrigatorios ausentes: {missing}")

    assert_string(payload, "automation_action_id", ctx)
    assert_string(payload, "coalescing_key", ctx)
    assert_string(payload, "idempotency_key", ctx)
    assert_string(payload, "action_type", ctx)
    assert_string(payload, "status", ctx)

    if "rollback_plan_ref" in payload and payload["rollback_plan_ref"] is not None:
        value = payload["rollback_plan_ref"]
        if not isinstance(value, str):
            fail(f"{ctx} invalido: campo 'rollback_plan_ref' deve ser string quando presente.")

    assert_enum(
        payload,
        "status",
        {"CREATED", "APPLIED", "NO_OP_DUPLICATE", "ROLLED_BACK", "FAILED"},
        ctx,
    )


def apply_automation_action(state: dict, payload: dict, ctx: str) -> str:
    validate_automation_action_payload(payload, ctx)
    coalescing_key = payload["coalescing_key"]
    idempotency_key = payload["idempotency_key"]

    if coalescing_key in state["coalescing_in_cooldown"]:
        return "NO_OP_DUPLICATE"
    if idempotency_key in state["idempotency_seen"]:
        return "NO_OP_DUPLICATE"

    state["coalescing_in_cooldown"].add(coalescing_key)
    state["idempotency_seen"].add(idempotency_key)

    rollback_ref = payload.get("rollback_plan_ref")
    if rollback_ref is None or (isinstance(rollback_ref, str) and not rollback_ref.strip()):
        return "NOTIFY_ONLY"

    return "APPLIED"


def validate_reconciliation_event(payload: dict, ctx: str) -> None:
    required_fields = {
        "work_order_id",
        "task_id",
        "event_type",
        "attempt",
        "idempotency_key",
        "replay_key",
    }
    missing = sorted([k for k in required_fields if k not in payload])
    if missing:
        fail(f"{ctx} invalido: campos obrigatorios ausentes: {missing}")

    assert_string(payload, "work_order_id", ctx)
    assert_string(payload, "task_id", ctx)
    assert_string(payload, "event_type", ctx)
    assert_min_int(payload, "attempt", 1, ctx)
    assert_string(payload, "idempotency_key", ctx)
    assert_string(payload, "replay_key", ctx)

    expected_replay_key = (
        f"{payload['work_order_id']}:{payload['task_id']}:{payload['event_type']}:{payload['attempt']}"
    )
    if payload["replay_key"] != expected_replay_key:
        fail(f"{ctx} invalido: replay_key fora da formula canonica.")


def apply_reconciliation_event(state: dict, payload: dict, ctx: str) -> str:
    validate_reconciliation_event(payload, ctx)
    replay_key = payload["replay_key"]

    if replay_key in state["replay_seen"]:
        return "IGNORED_DUPLICATE_AUDITED"

    state["replay_seen"].add(replay_key)
    return "APPLIED"


work_order_schema = json.loads(Path("ARC/schemas/work_order.schema.json").read_text(encoding="utf-8"))
decision_schema = json.loads(Path("ARC/schemas/decision.schema.json").read_text(encoding="utf-8"))
task_event_schema = json.loads(Path("ARC/schemas/task_event.schema.json").read_text(encoding="utf-8"))

expected_required_in_schema(
    work_order_schema,
    {
        "schema_version",
        "work_order_id",
        "idempotency_key",
        "objective",
        "risk_class",
        "risk_tier",
        "data_sensitivity",
        "status",
        "created_at",
    },
    "work_order.schema.json",
)
expected_required_in_schema(
    decision_schema,
    {
        "schema_version",
        "decision_id",
        "decision_key",
        "title",
        "proposal",
        "risk_class",
        "risk_tier",
        "data_sensitivity",
        "status",
        "created_at",
        "timeout_at",
        "challenge_id",
        "challenge_status",
        "challenge_expires_at",
    },
    "decision.schema.json",
)
expected_required_in_schema(
    task_event_schema,
    {
        "schema_version",
        "event_id",
        "work_order_id",
        "task_id",
        "event_type",
        "trace_id",
        "idempotency_key",
        "attempt",
        "replay_key",
        "created_at",
    },
    "task_event.schema.json",
)

valid_work_order = {
    "schema_version": "1.0",
    "work_order_id": "WO-20260225-001",
    "idempotency_key": "IDEMP-WO-001",
    "objective": "validar contrato de work order",
    "risk_class": "medio",
    "risk_tier": "R2",
    "data_sensitivity": "internal",
    "status": "APPROVED",
    "created_at": "2026-02-25T18:00:00Z",
}

valid_decision = {
    "schema_version": "1.0",
    "decision_id": "DEC-20260225-001",
    "decision_key": "f2-02:gate:idempotency",
    "title": "Validar contrato idempotente",
    "proposal": "Aplicar baseline de contratos",
    "risk_class": "medio",
    "risk_tier": "R2",
    "data_sensitivity": "internal",
    "status": "PENDING",
    "created_at": "2026-02-25T18:00:00Z",
    "timeout_at": "2026-02-25T19:00:00Z",
    "challenge_id": "CHL-20260225-001",
    "challenge_status": "PENDING",
    "challenge_expires_at": "2026-02-25T18:05:00Z",
}

valid_task_event = {
    "schema_version": "1.0",
    "event_id": "EVT-20260225-001",
    "work_order_id": "WO-20260225-001",
    "task_id": "TASK-F2-02-01",
    "event_type": "VALIDATION_STARTED",
    "trace_id": "TRACE-ABC-001",
    "idempotency_key": "IDEMP-WO-001",
    "attempt": 1,
    "replay_key": "WO-20260225-001:TASK-F2-02-01:VALIDATION_STARTED:1",
    "created_at": "2026-02-25T18:00:00Z",
}

invalid_work_order = dict(valid_work_order)
invalid_work_order.pop("idempotency_key", None)

invalid_decision = dict(valid_decision)
invalid_decision["risk_tier"] = "R4"

invalid_decision_missing_challenge_expiry = dict(valid_decision)
invalid_decision_missing_challenge_expiry["challenge_expires_at"] = None

invalid_decision_not_required_with_challenge = dict(valid_decision)
invalid_decision_not_required_with_challenge["challenge_status"] = "NOT_REQUIRED"
invalid_decision_not_required_with_challenge["challenge_id"] = "CHL-20260225-001"

invalid_task_event = dict(valid_task_event)
invalid_task_event["attempt"] = 0

valid_sprint_override = {
    "override_key": "SPR-OVR-SPR-20260225-001-max_items-W01",
    "coalescing_key": "SPR-20260225-001:max_items:W01",
    "sprint_id": "SPR-20260225-001",
    "limit_type": "max_items",
    "requested_delta": "aumentar limite de 12 para 14",
    "status": "APPLIED",
    "source_alert_id": "ALERT-SPR-001",
    "rollback_token": "RBK-20260225-001",
    "rollback_snapshot_ref": "artifact://sprint/SPR-20260225-001/pre-override",
}

invalid_sprint_override_missing_rollback = dict(valid_sprint_override)
invalid_sprint_override_missing_rollback.pop("rollback_snapshot_ref", None)

valid_automation_action = {
    "automation_action_id": "AUTO-20260225-001",
    "coalescing_key": "main:latency_p95:timeout",
    "idempotency_key": "IDEMP-AUTO-001",
    "action_type": "open_task",
    "status": "CREATED",
    "rollback_plan_ref": "artifact://automation/AUTO-20260225-001/rollback",
}

invalid_automation_action_missing_id = dict(valid_automation_action)
invalid_automation_action_missing_id.pop("automation_action_id", None)

automation_without_rollback = dict(valid_automation_action)
automation_without_rollback["automation_action_id"] = "AUTO-20260225-002"
automation_without_rollback["idempotency_key"] = "IDEMP-AUTO-002"
automation_without_rollback["rollback_plan_ref"] = ""

valid_reconciliation_event = {
    "work_order_id": "WO-20260225-001",
    "task_id": "TASK-F2-02-04",
    "event_type": "REPLAY_APPLY",
    "attempt": 1,
    "idempotency_key": "IDEMP-WO-001",
    "replay_key": "WO-20260225-001:TASK-F2-02-04:REPLAY_APPLY:1",
}

invalid_reconciliation_missing_idempotency = dict(valid_reconciliation_event)
invalid_reconciliation_missing_idempotency.pop("idempotency_key", None)

invalid_reconciliation_missing_replay = dict(valid_reconciliation_event)
invalid_reconciliation_missing_replay.pop("replay_key", None)

validate_work_order(valid_work_order, work_order_schema, "work_order.valid")
validate_decision(valid_decision, decision_schema, "decision.valid")
validate_task_event(valid_task_event, task_event_schema, "task_event.valid")

expect_invalid(validate_work_order, invalid_work_order, work_order_schema, "work_order.invalid")
expect_invalid(validate_decision, invalid_decision, decision_schema, "decision.invalid")
expect_invalid(
    validate_decision,
    invalid_decision_missing_challenge_expiry,
    decision_schema,
    "decision.invalid_missing_challenge_expiry",
)
expect_invalid(
    validate_decision,
    invalid_decision_not_required_with_challenge,
    decision_schema,
    "decision.invalid_not_required_with_challenge",
)
expect_invalid(validate_task_event, invalid_task_event, task_event_schema, "task_event.invalid")

sprint_state = {"applied_by_key": set()}
first_apply = apply_sprint_override(sprint_state, valid_sprint_override, "sprint_override.first_apply")
if first_apply != "APPLIED":
    fail("sprint_override.first_apply deveria retornar APPLIED.")

duplicate_apply = apply_sprint_override(sprint_state, valid_sprint_override, "sprint_override.duplicate_apply")
if duplicate_apply != "NO_OP_DUPLICATE":
    fail("sprint_override.duplicate_apply deveria retornar NO_OP_DUPLICATE.")

expect_invalid(
    lambda payload, _schema, ctx: apply_sprint_override({"applied_by_key": set()}, payload, ctx),
    invalid_sprint_override_missing_rollback,
    {},
    "sprint_override.invalid_missing_rollback",
)

automation_state = {"coalescing_in_cooldown": set(), "idempotency_seen": set()}
first_auto_apply = apply_automation_action(automation_state, valid_automation_action, "automation_action.first_apply")
if first_auto_apply != "APPLIED":
    fail("automation_action.first_apply deveria retornar APPLIED.")

duplicate_auto_apply = apply_automation_action(
    automation_state, valid_automation_action, "automation_action.duplicate_apply"
)
if duplicate_auto_apply != "NO_OP_DUPLICATE":
    fail("automation_action.duplicate_apply deveria retornar NO_OP_DUPLICATE.")

notify_only_apply = apply_automation_action(
    {"coalescing_in_cooldown": set(), "idempotency_seen": set()},
    automation_without_rollback,
    "automation_action.notify_only",
)
if notify_only_apply != "NOTIFY_ONLY":
    fail("automation_action.notify_only deveria retornar NOTIFY_ONLY.")

expect_invalid(
    lambda payload, _schema, ctx: apply_automation_action(
        {"coalescing_in_cooldown": set(), "idempotency_seen": set()}, payload, ctx
    ),
    invalid_automation_action_missing_id,
    {},
    "automation_action.invalid_missing_id",
)

reconciliation_state = {"replay_seen": set()}
first_reconciliation = apply_reconciliation_event(
    reconciliation_state,
    valid_reconciliation_event,
    "reconciliation.first_apply",
)
if first_reconciliation != "APPLIED":
    fail("reconciliation.first_apply deveria retornar APPLIED.")

duplicate_reconciliation = apply_reconciliation_event(
    reconciliation_state,
    valid_reconciliation_event,
    "reconciliation.duplicate_apply",
)
if duplicate_reconciliation != "IGNORED_DUPLICATE_AUDITED":
    fail("reconciliation.duplicate_apply deveria retornar IGNORED_DUPLICATE_AUDITED.")

expect_invalid(
    lambda payload, _schema, ctx: apply_reconciliation_event({"replay_seen": set()}, payload, ctx),
    invalid_reconciliation_missing_idempotency,
    {},
    "reconciliation.invalid_missing_idempotency",
)

expect_invalid(
    lambda payload, _schema, ctx: apply_reconciliation_event({"replay_seen": set()}, payload, ctx),
    invalid_reconciliation_missing_replay,
    {},
    "reconciliation.invalid_missing_replay",
)
PY

echo "eval-idempotency: PASS"
