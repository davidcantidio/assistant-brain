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
  "SEC/allowlists/DOMAINS.yaml"
  "SEC/allowlists/TOOLS.yaml"
  "SEC/allowlists/ACTIONS.yaml"
  "SEC/allowlists/OPERATORS.yaml"
  "SEC/allowlists/PROVIDERS.yaml"
)
for f in "${required_files[@]}"; do
  [[ -f "$f" ]] || { echo "Arquivo obrigatorio ausente: $f"; exit 1; }
done

# basic leak signatures in tracked files
if git grep -nE \
  -e 'sk-[A-Za-z0-9]{20,}' \
  -e 'xox[baprs]-[A-Za-z0-9-]{10,}' \
  -e 'AKIA[0-9A-Z]{16}' \
  -- . > /tmp/security_hits.txt; then
  echo "Possivel segredo detectado em arquivos versionados:"
  cat /tmp/security_hits.txt
  exit 1
else
  status=$?
  if [ "$status" -ne 1 ]; then
    echo "Falha ao executar scan de segredos (git grep exit=$status)"
    exit "$status"
  fi
fi

search_re "telegram_user_id" SEC/allowlists/OPERATORS.yaml
search_re "trading_live_requires_backup_operator" SEC/allowlists/OPERATORS.yaml

python3 - <<'PY'
import re
import sys
from pathlib import Path

path = Path("SEC/allowlists/OPERATORS.yaml")
text = path.read_text(encoding="utf-8")
lines = text.splitlines()


def fail(msg: str) -> None:
    print(msg)
    sys.exit(1)


def require_bool_key(key: str, expected: bool | None = None) -> None:
    m = re.search(rf"^\s*{re.escape(key)}\s*:\s*(true|false)\s*$", text, re.MULTILINE)
    if not m:
        fail(f"OPERATORS.yaml sem chave booleana obrigatoria: {key}")
    if expected is not None:
        value = m.group(1) == "true"
        if value != expected:
            fail(f"OPERATORS.yaml com valor invalido em {key} (esperado: {str(expected).lower()}).")


require_bool_key("trading_live_requires_backup_operator", expected=True)
require_bool_key("slack_fallback_requires_non_empty_user_and_channel_ids", expected=True)
require_bool_key("live_ready", expected=False)

operators = []
current = None
section = None

for raw in lines:
    stripped = raw.strip()
    if not stripped or stripped.startswith("#"):
        continue

    if stripped.startswith("- operator_id:"):
        if current:
            operators.append(current)
        current = {
            "operator_id": stripped.split(":", 1)[1].strip().strip('"'),
            "enabled": None,
            "telegram_user_id": None,
            "telegram_chat_ids": [],
            "permissions": [],
            "slack_ready": None,
        }
        section = None
        continue

    if current is None:
        continue

    if stripped.startswith("permissions:"):
        section = "permissions"
        continue
    if stripped.startswith("telegram_chat_ids:"):
        section = "telegram_chat_ids"
        continue

    if stripped.startswith("- "):
        item = stripped[2:].strip().strip('"')
        if section == "permissions":
            current["permissions"].append(item)
        elif section == "telegram_chat_ids":
            current["telegram_chat_ids"].append(item)
        continue

    section = None
    if ":" not in stripped:
        continue
    key, value = stripped.split(":", 1)
    key = key.strip()
    value = value.strip().strip('"')

    if key == "enabled":
        if value not in ("true", "false"):
            fail(f"OPERATORS.yaml invalido: enabled nao booleano para operador {current['operator_id']}.")
        current["enabled"] = value == "true"
    elif key == "telegram_user_id":
        current["telegram_user_id"] = value
    elif key == "slack_ready":
        if value not in ("true", "false"):
            fail(f"OPERATORS.yaml invalido: slack_ready nao booleano para operador {current['operator_id']}.")
        current["slack_ready"] = value == "true"

if current:
    operators.append(current)

if not operators:
    fail("OPERATORS.yaml sem bloco de operators.")

enabled_ops = [op for op in operators if op.get("enabled") is True]
if not enabled_ops:
    fail("OPERATORS.yaml sem operador habilitado (enabled: true).")

required_permissions = {"approve", "reject", "kill"}
for op in enabled_ops:
    op_id = op.get("operator_id") or "<sem_operator_id>"
    user_id = op.get("telegram_user_id")
    if not user_id:
        fail(f"Operador habilitado sem telegram_user_id: {op_id}")
    if not re.fullmatch(r"\d+", user_id):
        fail(f"telegram_user_id invalido para operador {op_id}: {user_id}")
    if not op.get("telegram_chat_ids"):
        fail(f"Operador habilitado sem telegram_chat_ids: {op_id}")
    if op.get("slack_ready") is None:
        fail(f"Operador habilitado sem campo slack_ready: {op_id}")
    permissions = set(op.get("permissions", []))
    missing = sorted(required_permissions - permissions)
    if missing:
        fail(f"Operador habilitado sem permissoes HITL obrigatorias ({', '.join(missing)}): {op_id}")
PY

echo "security-check: PASS"
