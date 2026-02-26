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
  "ARC/schemas/llm_run.schema.json"
  "ARC/schemas/router_decision.schema.json"
  "ARC/schemas/credits_snapshot.schema.json"
  "SEC/SEC-POLICY.md"
  "PM/DECISION-PROTOCOL.md"
  "ARC/ARC-HEARTBEAT.md"
  "workspaces/main/HEARTBEAT.md"
  "workspaces/main/MEMORY.md"
  "workspaces/main/.openclaw/workspace-state.json"
  "PRD/CHANGELOG.md"
)
for f in "${required_files[@]}"; do
  [[ -f "$f" ]] || { echo "Arquivo obrigatorio ausente: $f"; exit 1; }
done

python3 -m json.tool ARC/schemas/openclaw_runtime_config.schema.json >/dev/null
python3 -m json.tool ARC/schemas/llm_run.schema.json >/dev/null
python3 -m json.tool ARC/schemas/router_decision.schema.json >/dev/null
python3 -m json.tool ARC/schemas/credits_snapshot.schema.json >/dev/null

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

# Memory lifecycle contract
search_re 'Contrato `memory_contract`' PRD/PRD-MASTER.md
search_re "nightly-extraction" PRD/PRD-MASTER.md ARC/ARC-HEARTBEAT.md
search_re 'name: "nightly-extraction"' PRD/PRD-MASTER.md
search_re 'schedule: "0 23 \* \* \*"' PRD/PRD-MASTER.md
search_re 'timezone: "America/Sao_Paulo"' PRD/PRD-MASTER.md
search_re "required: true" PRD/PRD-MASTER.md
search_re "workspaces/main/MEMORY\.md" PRD/PRD-MASTER.md META/DOCUMENT-HIERARCHY.md
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
search_re "baseline unico de 15 minutos|base global: 15 minutos" ARC/ARC-HEARTBEAT.md
search_re "Baseline oficial: 15 minutos" workspaces/main/HEARTBEAT.md
search_re "America/Sao_Paulo" ARC/ARC-HEARTBEAT.md PRD/PRD-MASTER.md workspaces/main/HEARTBEAT.md
search_re "Nightly extraction de memoria: 23:00" ARC/ARC-HEARTBEAT.md
search_re "23:00 \\(America/Sao_Paulo\\).*nightly extraction" workspaces/main/HEARTBEAT.md
search_re "override deliberado de timezone.*America/Sao_Paulo" PRD/CHANGELOG.md

echo "eval-runtime-contracts: PASS"
