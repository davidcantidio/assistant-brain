#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  bash scripts/runtime/apply_runtime_merge_plan.sh --profile <active|dev> --plan <file> --dry-run <true|false>
USAGE
}

PROFILE=""
PLAN_FILE=""
DRY_RUN="true"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      PROFILE="${2:-}"
      shift 2
      ;;
    --plan)
      PLAN_FILE="${2:-}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN="${2:-}"
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

if [[ -z "$PROFILE" || -z "$PLAN_FILE" ]]; then
  echo "[ERRO] --profile e --plan sao obrigatorios." >&2
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
    echo "[ERRO] --profile deve ser active|dev." >&2
    exit 2
    ;;
esac

CONFIG_PATH="$STATE_DIR/openclaw.json"
if [[ ! -f "$CONFIG_PATH" ]]; then
  echo "[ERRO] config nao encontrada: $CONFIG_PATH" >&2
  exit 2
fi
if [[ ! -f "$PLAN_FILE" ]]; then
  echo "[ERRO] plano nao encontrado: $PLAN_FILE" >&2
  exit 2
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BACKUP_ROOT="$ROOT/artifacts/phase-f10/runtime-backups"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$BACKUP_ROOT/${TIMESTAMP}-${PROFILE}"

python3 - "$PLAN_FILE" "$CONFIG_PATH" "$DRY_RUN" <<'PY'
import json
import sys

plan_file, config_path, dry_run_raw = sys.argv[1:4]
dry_run = dry_run_raw.lower() == "true"
plan = json.load(open(plan_file, "r", encoding="utf-8"))
ops = plan.get("operations") or []
config = json.load(open(config_path, "r", encoding="utf-8"))

print(f"plan={plan.get('plan_id','unknown')} dry_run={dry_run}")
if not ops:
    print("operations=0 (nada para aplicar)")
    raise SystemExit(0)

for op in ops:
    print(f"- {op.get('op')} {op.get('path')} => {op.get('value')} (current={op.get('current')})")

if dry_run:
    raise SystemExit(0)
PY

if [[ "$(printf '%s' "$DRY_RUN" | tr '[:upper:]' '[:lower:]')" == "true" ]]; then
  echo "[OK] dry-run concluido sem mutacao."
  exit 0
fi

mkdir -p "$BACKUP_ROOT"
cp -a "$STATE_DIR" "$BACKUP_DIR"
echo "[OK] backup criado: $BACKUP_DIR"

python3 - "$PLAN_FILE" "$CONFIG_PATH" <<'PY'
import json
import os
import tempfile
import sys
from typing import Any

plan_file, config_path = sys.argv[1:3]

with open(plan_file, "r", encoding="utf-8") as f:
    plan = json.load(f)
with open(config_path, "r", encoding="utf-8") as f:
    config = json.load(f)


def set_path(payload: dict[str, Any], path: str, value: Any) -> None:
    cur = payload
    parts = path.split(".")
    for key in parts[:-1]:
        nxt = cur.get(key)
        if not isinstance(nxt, dict):
            nxt = {}
            cur[key] = nxt
        cur = nxt
    cur[parts[-1]] = value

for op in plan.get("operations") or []:
    if op.get("op") != "set":
        continue
    set_path(config, op["path"], op.get("value"))

fd, tmp = tempfile.mkstemp(prefix="openclaw-merge-", suffix=".json", dir=os.path.dirname(config_path))
os.close(fd)
with open(tmp, "w", encoding="utf-8") as f:
    json.dump(config, f, indent=2, ensure_ascii=True)
    f.write("\n")
os.replace(tmp, config_path)
print(f"[OK] merge aplicado em {config_path}")
PY
