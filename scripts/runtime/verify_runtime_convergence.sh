#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  bash scripts/runtime/verify_runtime_convergence.sh --profile <active|dev> --baseline <file> --post <file> --report <file>
USAGE
}

PROFILE=""
BASELINE=""
POST=""
REPORT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      PROFILE="${2:-}"
      shift 2
      ;;
    --baseline)
      BASELINE="${2:-}"
      shift 2
      ;;
    --post)
      POST="${2:-}"
      shift 2
      ;;
    --report)
      REPORT="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[ERRO] argumento invalido: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ -z "$PROFILE" || -z "$BASELINE" || -z "$POST" || -z "$REPORT" ]]; then
  echo "[ERRO] --profile, --baseline, --post e --report sao obrigatorios." >&2
  usage
  exit 2
fi

HEALTH_JSON="{}"
CAPS_JSON="{}"
if command -v openclaw >/dev/null 2>&1; then
  if [[ "$PROFILE" == "dev" ]]; then
    HEALTH_JSON="$(openclaw --dev health --json 2>/dev/null || echo '{}')"
    CAPS_JSON="$(openclaw --dev channels capabilities --json 2>/dev/null || echo '{}')"
  else
    HEALTH_JSON="$(openclaw health --json 2>/dev/null || echo '{}')"
    CAPS_JSON="$(openclaw channels capabilities --json 2>/dev/null || echo '{}')"
  fi
fi

mkdir -p "$(dirname "$REPORT")"

python3 - "$BASELINE" "$POST" "$REPORT" "$HEALTH_JSON" "$CAPS_JSON" <<'PY'
import json
import sys
from typing import Any

baseline_path, post_path, report_path, health_raw, caps_raw = sys.argv[1:6]
baseline = json.load(open(baseline_path, "r", encoding="utf-8"))
post = json.load(open(post_path, "r", encoding="utf-8"))
try:
    health = json.loads(health_raw)
except Exception:
    health = {}
try:
    caps = json.loads(caps_raw)
except Exception:
    caps = {}

allowed = {
    "gateway.bind",
    "gateway.port",
    "agents.defaults.heartbeat.every",
    "meta.lastTouchedAt",
    "meta.lastTouchedVersion",
}


def get(payload: dict[str, Any], path: str) -> Any:
    cur: Any = payload
    for key in path.split("."):
        if not isinstance(cur, dict) or key not in cur:
            return None
        cur = cur[key]
    return cur


def flatten_changes(a: Any, b: Any, prefix: str = "") -> set[str]:
    changed: set[str] = set()
    if type(a) is not type(b):
        changed.add(prefix or "<root>")
        return changed

    if isinstance(a, dict):
        keys = set(a.keys()) | set(b.keys())
        for key in keys:
            path = f"{prefix}.{key}" if prefix else key
            if key not in a or key not in b:
                changed.add(path)
                continue
            changed |= flatten_changes(a[key], b[key], path)
        return changed

    if isinstance(a, list):
        if a != b:
            changed.add(prefix or "<root>")
        return changed

    if a != b:
        changed.add(prefix or "<root>")
    return changed


def is_allowed(path: str) -> bool:
    for item in allowed:
        if path == item or path.startswith(item + "."):
            return True
    return False

base_cfg = baseline.get("runtime_config") or {}
post_cfg = post.get("runtime_config") or {}

changed_paths = sorted(flatten_changes(base_cfg, post_cfg))
unexpected = sorted([p for p in changed_paths if not is_allowed(p)])

checks = []

checks.append(
    {
        "id": "required_fields_present",
        "ok": all(
            k in baseline and k in post
            for k in [
                "snapshot_id",
                "profile",
                "openclaw_version",
                "channels",
                "auth_profiles",
                "gateway",
                "heartbeat",
                "models",
                "sessions",
                "cron",
                "plugins",
                "hash",
            ]
        ),
    }
)

checks.append(
    {
        "id": "no_loss_structural",
        "ok": len(unexpected) == 0,
        "unexpected_paths": unexpected,
        "changed_paths": changed_paths,
    }
)

checks.append(
    {
        "id": "gateway_bind_loopback",
        "ok": get(post_cfg, "gateway.bind") == "loopback",
        "value": get(post_cfg, "gateway.bind"),
    }
)

checks.append(
    {
        "id": "gateway_port_18789",
        "ok": get(post_cfg, "gateway.port") == 18789,
        "value": get(post_cfg, "gateway.port"),
    }
)

checks.append(
    {
        "id": "heartbeat_15m",
        "ok": get(post_cfg, "agents.defaults.heartbeat.every") == "15m",
        "value": get(post_cfg, "agents.defaults.heartbeat.every"),
    }
)

telegram_enabled = get(post_cfg, "channels.telegram.enabled") is True
telegram_probe_ok = (
    ((health.get("channels") or {}).get("telegram") or {}).get("probe") or {}
).get("ok") is True
if not telegram_probe_ok:
    for entry in caps.get("channels") or []:
        if entry.get("channel") == "telegram":
            telegram_probe_ok = (((entry.get("probe") or {}).get("ok")) is True)
            break
checks.append(
    {
        "id": "telegram_preserved",
        "ok": telegram_enabled and telegram_probe_ok,
        "telegram_enabled": telegram_enabled,
        "telegram_probe_ok": telegram_probe_ok,
    }
)

overall_ok = all(c.get("ok") is True for c in checks)
report = {
    "schema": "runtime_convergence_report.v1",
    "baseline": baseline_path,
    "post": post_path,
    "checks": checks,
    "overall_ok": overall_ok,
}

with open(report_path, "w", encoding="utf-8") as f:
    json.dump(report, f, indent=2, ensure_ascii=True)
    f.write("\n")

print(f"runtime_convergence_report.v1 written: {report_path}")
print(f"overall_ok={overall_ok}")
if not overall_ok:
    sys.exit(1)
PY
