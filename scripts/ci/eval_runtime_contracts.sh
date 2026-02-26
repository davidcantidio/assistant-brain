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
  "META/DOCUMENT-HIERARCHY.md"
  "PRD/PRD-MASTER.md"
  "ARC/ARC-CORE.md"
  "ARC/schemas/openclaw_runtime_config.schema.json"
  "ARC/schemas/ops_autonomy_contract.schema.json"
  "ARC/schemas/llm_run.schema.json"
  "ARC/schemas/router_decision.schema.json"
  "ARC/schemas/credits_snapshot.schema.json"
  "ARC/schemas/budget_governor_policy.schema.json"
  "ARC/schemas/a2a_delegation_event.schema.json"
  "ARC/schemas/webhook_ingest_event.schema.json"
  "CORE/FINANCIAL-GOVERNANCE.md"
  "EVALS/SYSTEM-HEALTH-THRESHOLDS.md"
  "SEC/SEC-POLICY.md"
  "PM/DECISION-PROTOCOL.md"
  "ARC/ARC-HEARTBEAT.md"
  "workspaces/main/HEARTBEAT.md"
  "workspaces/main/MEMORY.md"
  "workspaces/main/.openclaw/workspace-state.json"
  "PRD/CHANGELOG.md"
)

duplicate_required_files="$(printf '%s\n' "${required_files[@]}" | sort | uniq -d || true)"
if [[ -n "$duplicate_required_files" ]]; then
  echo "Lista de required_files contem caminhos duplicados:"
  while IFS= read -r duplicated; do
    [[ -z "$duplicated" ]] && continue
    echo " - $duplicated"
  done <<<"$duplicate_required_files"
  exit 1
fi

missing_required_files=()
for f in "${required_files[@]}"; do
  if [[ ! -f "$f" ]]; then
    missing_required_files+=("$f")
  fi
done
if (( ${#missing_required_files[@]} > 0 )); then
  for f in "${missing_required_files[@]}"; do
    echo "Arquivo obrigatorio ausente: $f"
  done
  exit 1
fi

python3 -m json.tool ARC/schemas/openclaw_runtime_config.schema.json >/dev/null
python3 -m json.tool ARC/schemas/ops_autonomy_contract.schema.json >/dev/null
python3 -m json.tool ARC/schemas/llm_run.schema.json >/dev/null
python3 -m json.tool ARC/schemas/router_decision.schema.json >/dev/null
python3 -m json.tool ARC/schemas/credits_snapshot.schema.json >/dev/null
python3 -m json.tool ARC/schemas/budget_governor_policy.schema.json >/dev/null
python3 -m json.tool ARC/schemas/a2a_delegation_event.schema.json >/dev/null
python3 -m json.tool ARC/schemas/webhook_ingest_event.schema.json >/dev/null

python3 - <<'PY'
import json
import sys
from copy import deepcopy
from pathlib import Path


def fail(msg: str) -> None:
    print(msg)
    sys.exit(1)


def get_path(payload: dict, path: list[str], label: str):
    current = payload
    for key in path:
        if not isinstance(current, dict) or key not in current:
            raise ValueError(f"{label} sem caminho obrigatorio: {'/'.join(path)}")
        current = current[key]
    return current


def ensure_required(payload: dict, path: list[str], expected: set[str], label: str) -> None:
    value = get_path(payload, path, label)
    if not isinstance(value, list):
        raise ValueError(f"{label} com {'/'.join(path)} invalido (esperado lista).")
    missing = sorted(expected - set(value))
    if missing:
        raise ValueError(f"{label} sem required obrigatorio em {'/'.join(path)}: {missing}")


def validate_openclaw_runtime_schema(schema: dict, label: str) -> None:
    ensure_required(schema, ["required"], {"agents", "tools", "channels", "hooks", "memory", "gateway"}, label)

    ensure_required(
        schema,
        ["properties", "tools", "properties", "agentToAgent", "required"],
        {"enabled", "allow"},
        label,
    )

    ensure_required(
        schema,
        ["properties", "hooks", "required"],
        {"enabled", "mappings", "internal"},
        label,
    )

    ensure_required(
        schema,
        ["properties", "hooks", "properties", "internal", "properties", "entries", "required"],
        {"boot-md", "command-logger", "session-memory"},
        label,
    )

    bind_const = get_path(schema, ["properties", "gateway", "properties", "bind", "const"], label)
    if bind_const != "loopback":
        raise ValueError(f"{label} com gateway.bind.const invalido (esperado 'loopback').")

    ensure_required(
        schema,
        ["properties", "gateway", "properties", "control_plane", "properties", "ws", "required"],
        {"enabled", "url"},
        label,
    )

    ensure_required(
        schema,
        [
            "properties",
            "gateway",
            "properties",
            "http",
            "properties",
            "endpoints",
            "properties",
            "chatCompletions",
            "required",
        ],
        {"enabled"},
        label,
    )


def expect_invalid(schema: dict, label: str) -> None:
    try:
        validate_openclaw_runtime_schema(schema, label)
    except ValueError:
        return
    fail(f"{label} deveria falhar, mas passou.")


runtime_schema = json.loads(Path("ARC/schemas/openclaw_runtime_config.schema.json").read_text(encoding="utf-8"))

try:
    validate_openclaw_runtime_schema(runtime_schema, "openclaw_runtime_config.schema.json")
except ValueError as exc:
    fail(str(exc))

invalid_missing_top_required = deepcopy(runtime_schema)
invalid_missing_top_required["required"].remove("hooks")
expect_invalid(invalid_missing_top_required, "invalid_missing_top_required")

invalid_missing_a2a_required = deepcopy(runtime_schema)
invalid_missing_a2a_required["properties"]["tools"]["properties"]["agentToAgent"]["required"].remove("allow")
expect_invalid(invalid_missing_a2a_required, "invalid_missing_a2a_required")

invalid_missing_hooks_required = deepcopy(runtime_schema)
invalid_missing_hooks_required["properties"]["hooks"]["required"].remove("internal")
expect_invalid(invalid_missing_hooks_required, "invalid_missing_hooks_required")

invalid_missing_hook_internal_entry = deepcopy(runtime_schema)
invalid_missing_hook_internal_entry["properties"]["hooks"]["properties"]["internal"]["properties"]["entries"]["required"].remove("session-memory")
expect_invalid(invalid_missing_hook_internal_entry, "invalid_missing_hook_internal_entry")

invalid_gateway_bind = deepcopy(runtime_schema)
invalid_gateway_bind["properties"]["gateway"]["properties"]["bind"]["const"] = "public"
expect_invalid(invalid_gateway_bind, "invalid_gateway_bind")

invalid_ws_required = deepcopy(runtime_schema)
invalid_ws_required["properties"]["gateway"]["properties"]["control_plane"]["properties"]["ws"]["required"].remove("url")
expect_invalid(invalid_ws_required, "invalid_ws_required")

invalid_chat_required = deepcopy(runtime_schema)
invalid_chat_required["properties"]["gateway"]["properties"]["http"]["properties"]["endpoints"]["properties"]["chatCompletions"]["required"].remove("enabled")
expect_invalid(invalid_chat_required, "invalid_chat_required")
PY

python3 - <<'PY'
import json
import sys
from copy import deepcopy
from pathlib import Path


def fail(msg: str) -> None:
    print(msg)
    sys.exit(1)


def validate_contract(payload: dict, required_fields: set[str], label: str) -> None:
    missing = sorted([f for f in required_fields if f not in payload])
    if missing:
        raise ValueError(f"{label} sem campos obrigatorios: {missing}")

    if payload.get("schema_version") != "1.0":
        raise ValueError(f"{label} com schema_version invalido.")
    if payload.get("contract_version") != "v1":
        raise ValueError(f"{label} com contract_version invalido.")
    if payload.get("isolation_mode") not in {"tmux", "equivalent_isolated_session"}:
        raise ValueError(f"{label} com isolation_mode invalido.")

    interval = payload.get("healthcheck_interval_minutes")
    if not isinstance(interval, int) or interval < 1:
        raise ValueError(f"{label} com healthcheck_interval_minutes invalido.")

    if payload.get("stalled_threshold_checks") != 2:
        raise ValueError(f"{label} com stalled_threshold_checks invalido (esperado 2).")

    restart = payload.get("restart_policy")
    if not isinstance(restart, dict):
        raise ValueError(f"{label} com restart_policy invalido.")
    restart_required = {"mode", "max_restarts", "restart_backoff_seconds", "requires_trace_id_log"}
    missing_restart = sorted([f for f in restart_required if f not in restart])
    if missing_restart:
        raise ValueError(f"{label} sem restart_policy minimo: {missing_restart}")
    if restart.get("mode") != "controlled_restart":
        raise ValueError(f"{label} com restart_policy.mode invalido.")
    if not isinstance(restart.get("max_restarts"), int) or restart["max_restarts"] < 1:
        raise ValueError(f"{label} com restart_policy.max_restarts invalido.")
    if not isinstance(restart.get("restart_backoff_seconds"), int) or restart["restart_backoff_seconds"] < 1:
        raise ValueError(f"{label} com restart_policy.restart_backoff_seconds invalido.")
    if restart.get("requires_trace_id_log") is not True:
        raise ValueError(f"{label} com restart_policy.requires_trace_id_log invalido.")

    if payload.get("incident_on_stalled") is not True:
        raise ValueError(f"{label} com incident_on_stalled invalido.")
    if payload.get("preserve_issue_context") is not True:
        raise ValueError(f"{label} com preserve_issue_context invalido.")

    fields = payload.get("required_runtime_fields")
    if not isinstance(fields, list) or len(fields) < 3:
        raise ValueError(f"{label} com required_runtime_fields invalido.")
    required_field_set = {"issue_id", "dag_state_ref", "trace_id"}
    if not required_field_set.issubset(set(fields)):
        raise ValueError(f"{label} sem required_runtime_fields minimos: {sorted(required_field_set - set(fields))}")


def expect_invalid(payload: dict, required_fields: set[str], label: str) -> None:
    try:
        validate_contract(payload, required_fields, label)
    except ValueError:
        return
    fail(f"{label} deveria falhar, mas passou.")


schema = json.loads(Path("ARC/schemas/ops_autonomy_contract.schema.json").read_text(encoding="utf-8"))
required = set(schema.get("required", []))
required_contract = {
    "schema_version",
    "contract_version",
    "isolation_mode",
    "healthcheck_interval_minutes",
    "stalled_threshold_checks",
    "restart_policy",
    "incident_on_stalled",
    "preserve_issue_context",
    "required_runtime_fields",
}
missing_required = sorted(required_contract - required)
if missing_required:
    fail(f"ops_autonomy_contract.schema.json sem required obrigatorio: {missing_required}")

props = schema.get("properties", {})
if props.get("stalled_threshold_checks", {}).get("const") != 2:
    fail("ops_autonomy_contract.schema.json invalido: stalled_threshold_checks deve ter const=2.")

valid_contract = {
    "schema_version": "1.0",
    "contract_version": "v1",
    "isolation_mode": "tmux",
    "healthcheck_interval_minutes": 15,
    "stalled_threshold_checks": 2,
    "restart_policy": {
        "mode": "controlled_restart",
        "max_restarts": 3,
        "restart_backoff_seconds": 30,
        "requires_trace_id_log": True,
    },
    "incident_on_stalled": True,
    "preserve_issue_context": True,
    "required_runtime_fields": ["issue_id", "dag_state_ref", "trace_id"],
}

try:
    validate_contract(valid_contract, required, "valid_ops_autonomy_contract")
except ValueError as exc:
    fail(str(exc))

invalid_contract = deepcopy(valid_contract)
invalid_contract["stalled_threshold_checks"] = 3
expect_invalid(invalid_contract, required, "invalid_ops_autonomy_contract_stalled_threshold")

invalid_contract_missing_restart = deepcopy(valid_contract)
invalid_contract_missing_restart.pop("restart_policy")
expect_invalid(invalid_contract_missing_restart, required, "invalid_ops_autonomy_contract_missing_restart_policy")
PY

python3 - <<'PY'
import datetime as dt
import json
import sys
from copy import deepcopy
from pathlib import Path


def fail(msg: str) -> None:
    print(msg)
    sys.exit(1)


def parse_iso8601(value: str, field: str) -> None:
    if not isinstance(value, str):
        raise ValueError(f"{field} deve ser string ISO-8601.")
    try:
        dt.datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as exc:
        raise ValueError(f"{field} invalido: {exc}") from exc


def validate_llm_run(payload: dict, required_fields: set[str], label: str) -> None:
    missing = sorted([f for f in required_fields if f not in payload])
    if missing:
        raise ValueError(f"{label} sem campos obrigatorios: {missing}")

    for field in ("run_id", "trace_id", "task_id", "requested_model", "effective_model", "effective_provider"):
        value = payload.get(field)
        if not isinstance(value, str) or len(value.strip()) < 2:
            raise ValueError(f"{label} com {field} invalido.")

    if not isinstance(payload.get("fallback_step"), int) or payload["fallback_step"] < 0:
        raise ValueError(f"{label} com fallback_step invalido.")
    if not isinstance(payload.get("retry_count"), int) or payload["retry_count"] < 0:
        raise ValueError(f"{label} com retry_count invalido.")

    usage = payload.get("usage")
    if not isinstance(usage, dict):
        raise ValueError(f"{label} com usage invalido.")
    usage_fields = ("prompt_tokens", "completion_tokens", "total_tokens", "total_cost_usd", "latency_ms")
    for field in usage_fields:
        value = usage.get(field)
        if not isinstance(value, (int, float)) or value < 0:
            raise ValueError(f"{label} com usage.{field} invalido.")

    outcome = payload.get("outcome")
    if not isinstance(outcome, dict):
        raise ValueError(f"{label} com outcome invalido.")
    if outcome.get("status") not in {"success", "failed", "blocked"}:
        raise ValueError(f"{label} com outcome.status invalido.")
    score = outcome.get("score")
    if not isinstance(score, (int, float)) or score < 0 or score > 1:
        raise ValueError(f"{label} com outcome.score invalido.")

    parse_iso8601(payload.get("started_at"), f"{label}.started_at")
    parse_iso8601(payload.get("completed_at"), f"{label}.completed_at")


def validate_router_decision(payload: dict, required_fields: set[str], label: str) -> None:
    missing = sorted([f for f in required_fields if f not in payload])
    if missing:
        raise ValueError(f"{label} sem campos obrigatorios: {missing}")

    for field in ("requested_model", "effective_model", "effective_provider", "decision_explain"):
        value = payload.get(field)
        if not isinstance(value, str) or not value.strip():
            raise ValueError(f"{label} com {field} invalido.")

    parse_iso8601(payload.get("created_at"), f"{label}.created_at")


def validate_credits_snapshot(payload: dict, required_fields: set[str], label: str) -> None:
    missing = sorted([f for f in required_fields if f not in payload])
    if missing:
        raise ValueError(f"{label} sem campos obrigatorios: {missing}")

    if payload.get("period_scope") not in {"run", "task", "day", "month"}:
        raise ValueError(f"{label} com period_scope invalido.")

    for field in ("period_limit", "period_usage", "balance", "burn_rate_hour", "burn_rate_day"):
        value = payload.get(field)
        if not isinstance(value, (int, float)) or value < 0:
            raise ValueError(f"{label} com {field} invalido.")

    parse_iso8601(payload.get("snapshot_at"), f"{label}.snapshot_at")
    parse_iso8601(payload.get("collected_at"), f"{label}.collected_at")


def expect_invalid(fn, payload: dict, required_fields: set[str], label: str) -> None:
    try:
        fn(payload, required_fields, label)
    except ValueError:
        return
    fail(f"{label} deveria falhar, mas passou.")


llm_schema = json.loads(Path("ARC/schemas/llm_run.schema.json").read_text(encoding="utf-8"))
router_schema = json.loads(Path("ARC/schemas/router_decision.schema.json").read_text(encoding="utf-8"))
credits_schema = json.loads(Path("ARC/schemas/credits_snapshot.schema.json").read_text(encoding="utf-8"))

llm_required = set(llm_schema.get("required", []))
router_required = set(router_schema.get("required", []))
credits_required = set(credits_schema.get("required", []))

missing_llm = sorted({"run_id", "requested_model", "effective_model", "effective_provider", "usage", "outcome"} - llm_required)
if missing_llm:
    fail(f"llm_run.schema.json sem required obrigatorio: {missing_llm}")

missing_router = sorted({"requested_model", "effective_model", "effective_provider", "decision_explain"} - router_required)
if missing_router:
    fail(f"router_decision.schema.json sem required obrigatorio: {missing_router}")

missing_credits = sorted({"period_scope", "period_limit", "period_usage", "balance", "burn_rate_hour", "burn_rate_day"} - credits_required)
if missing_credits:
    fail(f"credits_snapshot.schema.json sem required obrigatorio: {missing_credits}")

valid_llm_run = {
    "schema_version": "1.0",
    "run_id": "RUN-001",
    "trace_id": "TRACE-001",
    "task_id": "TASK-001",
    "agent_id": "router-agent",
    "session_id": "SESSION-001",
    "requested_model": "local/code-worker",
    "effective_model": "local/code-worker",
    "effective_provider": "ollama",
    "preset_id": "preset.dev_patch_v1",
    "fallback_step": 0,
    "retry_count": 0,
    "prompt_hash": "sha256:abc12345",
    "prompt_summary": "gerar patch minimo para bugfix.",
    "finish_reason": "stop",
    "parse_status": "ok",
    "usage": {
        "prompt_tokens": 120,
        "completion_tokens": 80,
        "total_tokens": 200,
        "total_cost_usd": 0.02,
        "latency_ms": 640
    },
    "outcome": {
        "status": "success",
        "score": 0.93
    },
    "started_at": "2026-02-26T10:20:00Z",
    "completed_at": "2026-02-26T10:20:02Z"
}

valid_router_decision = {
    "schema_version": "1.0",
    "decision_id": "ROUTER-001",
    "trace_id": "TRACE-001",
    "task_type": "dev_patch",
    "risk_class": "medio",
    "risk_tier": "R2",
    "data_sensitivity": "internal",
    "policy_filters": {
        "risk": "R2",
        "sensitivity": "internal",
        "allowlist": ["ollama", "litellm"]
    },
    "ranking_strategy": "capabilities-first",
    "requested_model": "local/code-worker",
    "effective_model": "local/code-worker",
    "effective_provider": "ollama",
    "provider_routing_applied": {
        "include": ["ollama"],
        "exclude": [],
        "order": ["ollama", "litellm"],
        "require": []
    },
    "fallback_step": 0,
    "fallback_reason": "primary_available",
    "decision_explain": "modelo local atende policy e custo.",
    "created_at": "2026-02-26T10:20:00Z"
}

valid_credits_snapshot = {
    "schema_version": "1.0",
    "snapshot_id": "SNAP-001",
    "snapshot_at": "2026-02-26T10:20:00Z",
    "billing_source": "openrouter",
    "currency": "USD",
    "period_scope": "day",
    "period_limit": 220.0,
    "period_usage": 48.7,
    "balance": 970.2,
    "burn_rate_hour": 3.2,
    "burn_rate_day": 58.0,
    "collected_at": "2026-02-26T10:20:05Z"
}

for validator, payload, required, label in (
    (validate_llm_run, valid_llm_run, llm_required, "valid_llm_run"),
    (validate_router_decision, valid_router_decision, router_required, "valid_router_decision"),
    (validate_credits_snapshot, valid_credits_snapshot, credits_required, "valid_credits_snapshot"),
):
    try:
        validator(payload, required, label)
    except ValueError as exc:
        fail(str(exc))

invalid_llm_run = deepcopy(valid_llm_run)
invalid_llm_run.pop("effective_model")
expect_invalid(validate_llm_run, invalid_llm_run, llm_required, "invalid_llm_run")

invalid_router_decision = deepcopy(valid_router_decision)
invalid_router_decision.pop("requested_model")
expect_invalid(validate_router_decision, invalid_router_decision, router_required, "invalid_router_decision")

invalid_credits_snapshot = deepcopy(valid_credits_snapshot)
invalid_credits_snapshot.pop("burn_rate_day")
expect_invalid(validate_credits_snapshot, invalid_credits_snapshot, credits_required, "invalid_credits_snapshot")
PY

python3 - <<'PY'
import datetime as dt
import json
import sys
from copy import deepcopy
from pathlib import Path


def fail(msg: str) -> None:
    print(msg)
    sys.exit(1)


def parse_iso8601(value: str, field: str) -> None:
    if not isinstance(value, str):
        raise ValueError(f"{field} deve ser string ISO-8601.")
    try:
        dt.datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as exc:
        raise ValueError(f"{field} invalido: {exc}") from exc


def validate_budget_policy(payload: dict, required_fields: set[str], label: str) -> None:
    missing = sorted([f for f in required_fields if f not in payload])
    if missing:
        raise ValueError(f"{label} sem campos obrigatorios: {missing}")

    limits = payload.get("limits")
    if not isinstance(limits, dict):
        raise ValueError(f"{label} sem limits valido.")
    for field in ("run_usd", "task_usd", "day_usd"):
        value = limits.get(field)
        if not isinstance(value, (int, float)) or value < 0:
            raise ValueError(f"{label} com limits.{field} invalido.")

    snapshot_contract = payload.get("snapshot_contract")
    if not isinstance(snapshot_contract, dict):
        raise ValueError(f"{label} sem snapshot_contract valido.")
    if snapshot_contract.get("entity") != "credits_snapshots":
        raise ValueError(f"{label} com snapshot_contract.entity invalido.")
    if snapshot_contract.get("schema_ref") != "ARC/schemas/credits_snapshot.schema.json":
        raise ValueError(f"{label} com snapshot_contract.schema_ref invalido.")
    freshness = snapshot_contract.get("freshness_minutes_max")
    if not isinstance(freshness, int) or freshness < 1:
        raise ValueError(f"{label} com snapshot_contract.freshness_minutes_max invalido.")
    required_fields_snapshot = snapshot_contract.get("required_fields")
    if not isinstance(required_fields_snapshot, list) or len(required_fields_snapshot) == 0:
        raise ValueError(f"{label} com snapshot_contract.required_fields invalido.")

    enforcement = payload.get("enforcement")
    if not isinstance(enforcement, dict):
        raise ValueError(f"{label} sem enforcement valido.")
    for field in ("block_without_limits", "block_with_stale_snapshot"):
        value = enforcement.get(field)
        if not isinstance(value, bool):
            raise ValueError(f"{label} com enforcement.{field} invalido.")
    actions = enforcement.get("violation_actions")
    if not isinstance(actions, list) or len(actions) == 0:
        raise ValueError(f"{label} com enforcement.violation_actions invalido.")

    parse_iso8601(payload.get("updated_at"), f"{label}.updated_at")


def expect_invalid(payload: dict, required_fields: set[str], label: str) -> None:
    try:
        validate_budget_policy(payload, required_fields, label)
    except ValueError:
        return
    fail(f"{label} deveria falhar, mas passou.")


schema = json.loads(Path("ARC/schemas/budget_governor_policy.schema.json").read_text(encoding="utf-8"))
required = set(schema.get("required", []))

missing_required = sorted({"limits", "snapshot_contract", "enforcement"} - required)
if missing_required:
    fail(f"budget_governor_policy.schema.json sem required obrigatorio: {missing_required}")

valid_policy = {
    "schema_version": "1.0",
    "policy_id": "budget-f2-baseline",
    "scope": "global",
    "currency": "USD",
    "limits": {
        "run_usd": 2.5,
        "task_usd": 8.0,
        "day_usd": 220.0
    },
    "snapshot_contract": {
        "entity": "credits_snapshots",
        "schema_ref": "ARC/schemas/credits_snapshot.schema.json",
        "freshness_minutes_max": 10,
        "required_fields": [
            "snapshot_at",
            "period_limit",
            "period_usage",
            "balance",
            "burn_rate_hour",
            "burn_rate_day"
        ]
    },
    "enforcement": {
        "block_without_limits": True,
        "block_with_stale_snapshot": True,
        "violation_actions": [
            "block_non_critical",
            "fallback_economic_preset",
            "open_budget_decision"
        ]
    },
    "updated_at": "2026-02-26T10:30:00Z",
    "updated_by": "budget-governor"
}

try:
    validate_budget_policy(valid_policy, required, "valid_policy")
except ValueError as exc:
    fail(str(exc))

invalid_missing_limits = deepcopy(valid_policy)
invalid_missing_limits.pop("limits")
expect_invalid(invalid_missing_limits, required, "invalid_missing_limits")

invalid_missing_day_limit = deepcopy(valid_policy)
invalid_missing_day_limit["limits"].pop("day_usd")
expect_invalid(invalid_missing_day_limit, required, "invalid_missing_day_limit")

invalid_missing_snapshot = deepcopy(valid_policy)
invalid_missing_snapshot["snapshot_contract"].pop("required_fields")
expect_invalid(invalid_missing_snapshot, required, "invalid_missing_snapshot")
PY

python3 - <<'PY'
import datetime as dt
import json
import sys
from copy import deepcopy
from pathlib import Path


def fail(msg: str) -> None:
    print(msg)
    sys.exit(1)


def parse_iso8601(value: str, field: str) -> None:
    if not isinstance(value, str):
        raise ValueError(f"{field} deve ser string ISO-8601.")
    try:
        dt.datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as exc:
        raise ValueError(f"{field} invalido: {exc}") from exc


def validate_a2a(payload: dict, required_fields: set[str], label: str) -> None:
    missing = sorted([f for f in required_fields if f not in payload])
    if missing:
        raise ValueError(f"{label} sem campos obrigatorios: {missing}")

    for field in ("trace_id", "requester_agent", "target_agent", "allowlist_entry"):
        value = payload.get(field)
        if not isinstance(value, str) or len(value.strip()) < 2:
            raise ValueError(f"{label} com {field} invalido.")

    if payload.get("allowed") is not True:
        raise ValueError(f"{label} invalido: delegacao fora de allowlist.")
    if payload.get("status") not in {"queued", "succeeded", "failed", "blocked"}:
        raise ValueError(f"{label} com status invalido.")

    parse_iso8601(payload.get("created_at"), f"{label}.created_at")


def validate_webhook(payload: dict, required_fields: set[str], label: str) -> None:
    missing = sorted([f for f in required_fields if f not in payload])
    if missing:
        raise ValueError(f"{label} sem campos obrigatorios: {missing}")

    for field in ("trace_id", "source_hook_id", "mapping_id", "idempotency_key"):
        value = payload.get(field)
        if not isinstance(value, str) or len(value.strip()) < 2:
            raise ValueError(f"{label} com {field} invalido.")

    if payload.get("status") not in {"accepted", "rejected", "blocked"}:
        raise ValueError(f"{label} com status invalido.")

    parse_iso8601(payload.get("received_at"), f"{label}.received_at")


def expect_invalid(fn, payload: dict, required_fields: set[str], label: str) -> None:
    try:
        fn(payload, required_fields, label)
    except ValueError:
        return
    fail(f"{label} deveria falhar, mas passou.")


a2a_schema = json.loads(Path("ARC/schemas/a2a_delegation_event.schema.json").read_text(encoding="utf-8"))
webhook_schema = json.loads(Path("ARC/schemas/webhook_ingest_event.schema.json").read_text(encoding="utf-8"))

a2a_required = set(a2a_schema.get("required", []))
webhook_required = set(webhook_schema.get("required", []))

missing_a2a = sorted({"trace_id", "allowlist_entry", "allowed"} - a2a_required)
if missing_a2a:
    fail(f"a2a_delegation_event.schema.json sem required obrigatorio: {missing_a2a}")

missing_webhook = sorted({"trace_id", "mapping_id", "idempotency_key"} - webhook_required)
if missing_webhook:
    fail(f"webhook_ingest_event.schema.json sem required obrigatorio: {missing_webhook}")

valid_a2a = {
    "schema_version": "1.0",
    "delegation_id": "A2A-001",
    "trace_id": "TRACE-A2A-001",
    "requester_agent": "orchestrator",
    "target_agent": "dev-worker",
    "allowlist_entry": "orchestrator->dev-worker",
    "allowed": True,
    "status": "queued",
    "created_at": "2026-02-26T10:40:00Z"
}

valid_webhook = {
    "schema_version": "1.0",
    "hook_event_id": "HOOK-001",
    "trace_id": "TRACE-HOOK-001",
    "source_hook_id": "slack-mention",
    "mapping_id": "hooks.mappings.mention",
    "idempotency_key": "HOOK-IDEMP-001",
    "event_type": "task_event",
    "status": "accepted",
    "received_at": "2026-02-26T10:40:05Z"
}

for validator, payload, required, label in (
    (validate_a2a, valid_a2a, a2a_required, "valid_a2a"),
    (validate_webhook, valid_webhook, webhook_required, "valid_webhook"),
):
    try:
        validator(payload, required, label)
    except ValueError as exc:
        fail(str(exc))

invalid_a2a = deepcopy(valid_a2a)
invalid_a2a["allowed"] = False
expect_invalid(validate_a2a, invalid_a2a, a2a_required, "invalid_a2a_outside_allowlist")

invalid_webhook = deepcopy(valid_webhook)
invalid_webhook.pop("mapping_id")
expect_invalid(validate_webhook, invalid_webhook, webhook_required, "invalid_webhook_missing_mapping")

invalid_webhook_trace = deepcopy(valid_webhook)
invalid_webhook_trace.pop("trace_id")
expect_invalid(validate_webhook, invalid_webhook_trace, webhook_required, "invalid_webhook_missing_trace_id")
PY

workspace_state_candidates=()
while IFS= read -r candidate_path; do
  workspace_state_candidates+=("$candidate_path")
done < <(find workspaces -type f -path "*/.openclaw/workspace-state.json" 2>/dev/null | sort)

if (( ${#workspace_state_candidates[@]} != 1 )); then
  echo "workspace-state invalido: esperado exatamente 1 caminho canonico em workspaces/*/.openclaw/workspace-state.json; encontrados ${#workspace_state_candidates[@]}."
  if (( ${#workspace_state_candidates[@]} > 0 )); then
    for candidate_path in "${workspace_state_candidates[@]}"; do
      echo "workspace-state encontrado: $candidate_path"
    done
  fi
  exit 1
fi

if [[ "${workspace_state_candidates[0]}" != "workspaces/main/.openclaw/workspace-state.json" ]]; then
  echo "workspace-state invalido: caminho canonico esperado 'workspaces/main/.openclaw/workspace-state.json', encontrado '${workspace_state_candidates[0]}'."
  exit 1
fi

python3 - <<'PY'
import datetime as dt
import json
import pathlib
import re
import sys

path = pathlib.Path("workspaces/main/.openclaw/workspace-state.json")
try:
    data = json.loads(path.read_text(encoding="utf-8"))
except Exception as exc:
    print(f"workspace-state invalido: {path}: {exc}")
    sys.exit(1)

version = data.get("version")
if not isinstance(version, int) or version < 1:
    print("workspace-state invalido: campo 'version' deve ser inteiro >= 1.")
    sys.exit(1)

seeded = data.get("bootstrapSeededAt")
if not isinstance(seeded, str):
    print("workspace-state invalido: campo 'bootstrapSeededAt' ausente ou nao-string.")
    sys.exit(1)

if not re.match(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z$", seeded):
    print("workspace-state invalido: 'bootstrapSeededAt' deve estar em ISO-8601 UTC (terminando com 'Z').")
    sys.exit(1)

try:
    dt.datetime.fromisoformat(seeded.replace("Z", "+00:00"))
except ValueError:
    print("workspace-state invalido: 'bootstrapSeededAt' nao representa timestamp valido.")
    sys.exit(1)
PY

# Canonical precedence
search_re "felixcraft\.md" META/DOCUMENT-HIERARCHY.md

# Runtime contract and A2A/hooks
search_re 'Contrato Canonico `openclaw_runtime_config`' PRD/PRD-MASTER.md
search_re "tools\.agentToAgent\.enabled" PRD/PRD-MASTER.md ARC/ARC-CORE.md
search_re "tools\.agentToAgent\.allow\[\]" PRD/PRD-MASTER.md ARC/ARC-CORE.md
search_re "hooks\.enabled" PRD/PRD-MASTER.md ARC/ARC-CORE.md
search_re "hooks\.mappings\[\]" PRD/PRD-MASTER.md ARC/ARC-CORE.md
search_re "hooks\.internal\.entries\[\]" PRD/PRD-MASTER.md ARC/ARC-CORE.md
search_re "trace_id" PRD/PRD-MASTER.md ARC/ARC-CORE.md
search_re "gateway\.bind = loopback" PRD/PRD-MASTER.md ARC/ARC-CORE.md
search_re "gateway\.control_plane\.ws" PRD/PRD-MASTER.md ARC/ARC-CORE.md
search_re "chatCompletions" PRD/PRD-MASTER.md ARC/ARC-CORE.md

# Memory plane baseline entities
search_re '### 2\) `llm_runs`' ARC/ARC-CORE.md
search_re '### 3\) `router_decisions`' ARC/ARC-CORE.md
search_re '### 5\) `credits_snapshots`' ARC/ARC-CORE.md
search_re "requested_model" ARC/ARC-CORE.md PRD/PRD-MASTER.md
search_re "effective_model" ARC/ARC-CORE.md PRD/PRD-MASTER.md
search_re "effective_provider" ARC/ARC-CORE.md PRD/PRD-MASTER.md

# Budget governor baseline (run/task/day + credits snapshots)
search_re "limites por run/tarefa/dia" CORE/FINANCIAL-GOVERNANCE.md
search_re "sem limite por run/tarefa/dia MUST bloquear" CORE/FINANCIAL-GOVERNANCE.md
search_re "credits_snapshots" CORE/FINANCIAL-GOVERNANCE.md EVALS/SYSTEM-HEALTH-THRESHOLDS.md
search_re "snapshot de custo desatualizado > 10 min" EVALS/SYSTEM-HEALTH-THRESHOLDS.md
search_re "run/task/day" EVALS/SYSTEM-HEALTH-THRESHOLDS.md

# Memory lifecycle contract
search_re 'Contrato `memory_contract`' PRD/PRD-MASTER.md
search_re "nightly-extraction" PRD/PRD-MASTER.md ARC/ARC-HEARTBEAT.md
search_re 'name: "nightly-extraction"' PRD/PRD-MASTER.md
search_re 'schedule: "0 23 \* \* \*"' PRD/PRD-MASTER.md
search_re 'timezone: "America/Sao_Paulo"' PRD/PRD-MASTER.md
search_re "required: true" PRD/PRD-MASTER.md
search_re "workspaces/main/MEMORY\.md" PRD/PRD-MASTER.md META/DOCUMENT-HIERARCHY.md

# Ops autonomy contract
search_re 'Contrato `ops_autonomy_contract`' PRD/PRD-MASTER.md
search_re "isolation_mode" PRD/PRD-MASTER.md
search_re "stalled_threshold_checks: 2" PRD/PRD-MASTER.md ARC/ARC-HEARTBEAT.md
search_re "restart_policy" PRD/PRD-MASTER.md
search_re "incident_on_stalled: true" PRD/PRD-MASTER.md ARC/ARC-HEARTBEAT.md
search_re "preserve_issue_context: true" PRD/PRD-MASTER.md
search_re "trace_id" PRD/PRD-MASTER.md ARC/ARC-HEARTBEAT.md

if ! ls workspaces/main/memory/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md >/dev/null 2>&1; then
  echo "Nenhuma nota diaria encontrada em workspaces/main/memory/YYYY-MM-DD.md"
  exit 1
fi
python3 - <<'PY'
import glob
import re
import sys

daily_files = sorted(glob.glob("workspaces/main/memory/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md"))
required_sections = ("Key Events", "Decisions Made", "Facts Extracted")
errors = []

for path in daily_files:
    text = open(path, "r", encoding="utf-8", errors="ignore").read().splitlines()
    if not text or not re.match(r"^#\s+\d{4}-\d{2}-\d{2}\s*$", text[0].strip()):
        errors.append(f"{path}: cabecalho diario invalido (esperado '# YYYY-MM-DD').")
        continue

    bullets = {section: 0 for section in required_sections}
    current = None
    for line in text:
        m = re.match(r"^##\s+(Key Events|Decisions Made|Facts Extracted)\s*$", line.strip())
        if m:
            current = m.group(1)
            continue
        if current and re.match(r"^\s*-\s+\S+", line):
            bullets[current] += 1

    for section in required_sections:
        if bullets.get(section, 0) == 0:
            errors.append(f"{path}: secao '{section}' sem bullet obrigatorio.")

if errors:
    for err in errors:
        print(err)
    sys.exit(1)
PY

# Channel trust + financial hard gate
search_re "email.*nunca.*canal confiavel de comando|canal nao confiavel para comando" PRD/PRD-MASTER.md SEC/SEC-POLICY.md PM/DECISION-PROTOCOL.md
search_re "aprovacao humana explicita" PRD/PRD-MASTER.md SEC/SEC-POLICY.md VERTICALS/TRADING/TRADING-PRD.md VERTICALS/TRADING/TRADING-RISK-RULES.md VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md

# Heartbeat baseline alignment
search_re "baseline unico de 15 minutos" ARC/ARC-HEARTBEAT.md
search_re "base global: 15 minutos" ARC/ARC-HEARTBEAT.md
search_re "Baseline oficial: 15 minutos" workspaces/main/HEARTBEAT.md
search_re "America/Sao_Paulo" ARC/ARC-HEARTBEAT.md PRD/PRD-MASTER.md workspaces/main/HEARTBEAT.md
search_re "Nightly extraction de memoria: 23:00" ARC/ARC-HEARTBEAT.md
search_re "23:00 \\(America/Sao_Paulo\\).*nightly extraction" workspaces/main/HEARTBEAT.md
search_re "override deliberado de timezone.*America/Sao_Paulo" PRD/CHANGELOG.md

echo "eval-runtime-contracts: PASS"
