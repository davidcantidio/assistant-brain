#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  bash scripts/runtime/export_runtime_state.sh --profile <active|dev> --out <file> [--redact-secrets <true|false>]
USAGE
}

PROFILE=""
OUT=""
REDACT_SECRETS="true"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      PROFILE="${2:-}"
      shift 2
      ;;
    --out)
      OUT="${2:-}"
      shift 2
      ;;
    --redact-secrets)
      REDACT_SECRETS="${2:-}"
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

if [[ -z "$PROFILE" || -z "$OUT" ]]; then
  echo "[ERRO] --profile e --out sao obrigatorios." >&2
  usage
  exit 2
fi

case "$PROFILE" in
  active)
    STATE_DIR="$HOME/.openclaw"
    ;;
  dev)
    STATE_DIR="$HOME/.openclaw-dev"
    ;;
  *)
    echo "[ERRO] --profile deve ser active|dev (recebido: $PROFILE)." >&2
    exit 2
    ;;
esac

CONFIG_PATH="$STATE_DIR/openclaw.json"
if [[ ! -f "$CONFIG_PATH" ]]; then
  echo "[ERRO] config nao encontrada: $CONFIG_PATH" >&2
  exit 2
fi

mkdir -p "$(dirname "$OUT")"
OPENCLAW_VERSION="unknown"
if command -v openclaw >/dev/null 2>&1; then
  OPENCLAW_VERSION="$(openclaw --version 2>/dev/null || echo unknown)"
fi

python3 - "$CONFIG_PATH" "$STATE_DIR" "$PROFILE" "$OPENCLAW_VERSION" "$REDACT_SECRETS" "$OUT" <<'PY'
import datetime as dt
import hashlib
import json
import os
import re
import sys
from typing import Any

config_path, state_dir, profile, openclaw_version, redact_raw, out_path = sys.argv[1:7]
redact_secrets = redact_raw.lower() == "true"


def load_json(path: str, default: Any) -> Any:
    if not os.path.exists(path):
        return default
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def shallow_recent_sessions(sessions_obj: Any) -> list[dict[str, Any]]:
    if not isinstance(sessions_obj, dict):
        return []
    rows = []
    for key, value in sessions_obj.items():
        if not isinstance(value, dict):
            continue
        rows.append(
            {
                "key": key,
                "updatedAt": value.get("updatedAt"),
                "sessionId": value.get("sessionId"),
                "model": value.get("model"),
            }
        )
    rows.sort(key=lambda row: row.get("updatedAt") or 0, reverse=True)
    return rows[:10]


def redact(obj: Any) -> Any:
    if not redact_secrets:
        return obj

    key_blocklist = (
        "token",
        "secret",
        "password",
        "apikey",
        "api_key",
        "signing",
        "bearer",
    )
    safe_token_like_keys = {
        "tokenSource",
        "botTokenSource",
        "appTokenSource",
        "contextTokens",
    }

    if isinstance(obj, dict):
        out = {}
        for key, value in obj.items():
            key_l = key.lower()
            if key in safe_token_like_keys:
                out[key] = redact(value)
                continue
            if any(block in key_l for block in key_blocklist):
                out[key] = "***REDACTED***"
                continue
            out[key] = redact(value)
        return out

    if isinstance(obj, list):
        return [redact(v) for v in obj]

    if isinstance(obj, str):
        if re.search(r"(xox[bap]-|sk-|tok_|Bearer\s+)", obj):
            return "***REDACTED***"
        if len(obj) > 40 and re.search(r"[A-Za-z0-9_-]{32,}", obj):
            return "***REDACTED***"
    return obj


config = load_json(config_path, {})
sessions_path = os.path.join(state_dir, "agents", "main", "sessions", "sessions.json")
sessions_raw = load_json(sessions_path, {})
cron_jobs = load_json(os.path.join(state_dir, "cron", "jobs.json"), {})

heartbeat = ((config.get("agents") or {}).get("defaults") or {}).get("heartbeat") or {}
models = ((config.get("agents") or {}).get("defaults") or {}).get("model") or {}

utc_now = dt.datetime.now(dt.timezone.utc)
snapshot_id = f"RTS-{utc_now.strftime('%Y%m%d-%H%M%S')}-{profile}"

payload = {
    "schema": "runtime_inventory.v1",
    "snapshot_id": snapshot_id,
    "profile": profile,
    "generated_at": utc_now.replace(microsecond=0).isoformat().replace("+00:00", "Z"),
    "openclaw_version": openclaw_version,
    "channels": redact(config.get("channels") or {}),
    "auth_profiles": redact(((config.get("auth") or {}).get("profiles") or {}),),
    "gateway": redact(config.get("gateway") or {}),
    "heartbeat": redact(heartbeat),
    "models": redact(models),
    "sessions": redact(
        {
            "path": sessions_path,
            "count": len(sessions_raw) if isinstance(sessions_raw, dict) else 0,
            "recent": shallow_recent_sessions(sessions_raw),
        }
    ),
    "cron": redact(cron_jobs),
    "plugins": redact(config.get("plugins") or {}),
    "runtime_config": redact(config),
}

hash_input = json.dumps(payload, sort_keys=True, separators=(",", ":"), ensure_ascii=True).encode("utf-8")
payload["hash"] = hashlib.sha256(hash_input).hexdigest()

with open(out_path, "w", encoding="utf-8") as f:
    json.dump(payload, f, indent=2, ensure_ascii=True)
    f.write("\n")

print(f"runtime_inventory.v1 written: {out_path}")
print(f"snapshot_id={snapshot_id}")
print(f"hash={payload['hash']}")
PY
