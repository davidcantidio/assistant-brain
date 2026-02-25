#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

required_files=(
  "ARC/schemas/work_order.schema.json"
  "ARC/schemas/decision.schema.json"
  "ARC/schemas/task_event.schema.json"
  "PM/WORK-ORDER-SPEC.md"
  "PM/DECISION-PROTOCOL.md"
  "ARC/ARC-CORE.md"
)

for f in "${required_files[@]}"; do
  [[ -f "$f" ]] || { echo "Arquivo obrigatorio ausente: $f"; exit 1; }
done

python3 -m json.tool ARC/schemas/work_order.schema.json >/dev/null
python3 -m json.tool ARC/schemas/decision.schema.json >/dev/null
python3 -m json.tool ARC/schemas/task_event.schema.json >/dev/null

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


def assert_string(payload: dict, field: str, ctx: str) -> None:
    value = payload.get(field)
    if not isinstance(value, str) or not value.strip():
        fail(f"{ctx} invalido: campo '{field}' deve ser string nao vazia.")


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
    parse_iso8601(payload.get("created_at"), f"{ctx}.created_at")
    parse_iso8601(payload.get("timeout_at"), f"{ctx}.timeout_at")


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

invalid_task_event = dict(valid_task_event)
invalid_task_event["attempt"] = 0

validate_work_order(valid_work_order, work_order_schema, "work_order.valid")
validate_decision(valid_decision, decision_schema, "decision.valid")
validate_task_event(valid_task_event, task_event_schema, "task_event.valid")

expect_invalid(validate_work_order, invalid_work_order, work_order_schema, "work_order.invalid")
expect_invalid(validate_decision, invalid_decision, decision_schema, "decision.invalid")
expect_invalid(validate_task_event, invalid_task_event, task_event_schema, "task_event.invalid")
PY

echo "eval-idempotency: PASS"
