#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NANOBOT_MIN_VERSION="${NANOBOT_MIN_VERSION:-0.1.4}"
RUNTIME_HOME="${RUNTIME_HOME:-$HOME/.nanobot}"
RUNTIME_WORKSPACE="${RUNTIME_WORKSPACE:-$RUNTIME_HOME/workspace}"
REPO_STATE_FILE="$REPO_ROOT/workspaces/main/.nanobot/workspace-state.json"
RUNTIME_STATE_FILE="$RUNTIME_WORKSPACE/workspace-state.json"

NANOBOT_CMD="$(command -v nanobot || true)"

extract_version() {
  printf '%s' "$1" | grep -Eo '[0-9]+(\.[0-9]+)+' | head -n1
}

version_ge() {
  local current="$1"
  local minimum="$2"
  local ordered
  ordered="$(printf '%s\n%s\n' "$minimum" "$current" | sort -V | head -n1)"
  [ "$ordered" = "$minimum" ]
}

echo "== Verify assistant-brain + Nanobot + ClawWork =="

echo
echo "[1] Python"
python3 --version || true

echo
echo "[2] Nanobot"
if [ -n "$NANOBOT_CMD" ]; then
  raw="$($NANOBOT_CMD --version 2>/dev/null || true)"
  cur="$(extract_version "$raw")"
  echo "nanobot: $NANOBOT_CMD"
  echo "nanobot version: $raw"
  if [ -n "$cur" ] && version_ge "$cur" "$NANOBOT_MIN_VERSION"; then
    echo "OK: nanobot >= $NANOBOT_MIN_VERSION"
  else
    echo "FALHA: nanobot abaixo do minimo ($NANOBOT_MIN_VERSION)"
  fi
else
  echo "FALTA: nanobot (rode scripts/onboard_linux.sh)"
fi

echo
echo "[3] Config runtime"
if [ -f "$RUNTIME_HOME/config.json" ]; then
  echo "OK: $RUNTIME_HOME/config.json"
  python3 -m json.tool "$RUNTIME_HOME/config.json" >/dev/null 2>&1 && echo "OK: JSON valido" || echo "FALHA: JSON invalido"
else
  echo "FALTA: $RUNTIME_HOME/config.json"
fi

echo
echo "[4] Skill clawmode"
if [ -f "$RUNTIME_WORKSPACE/skills/clawmode/SKILL.md" ]; then
  echo "OK: $RUNTIME_WORKSPACE/skills/clawmode/SKILL.md"
else
  echo "FALTA: $RUNTIME_WORKSPACE/skills/clawmode/SKILL.md"
fi

echo
echo "[5] Bridge de estado"
if [ -f "$REPO_STATE_FILE" ]; then
  echo "OK: repo state $REPO_STATE_FILE"
else
  echo "FALTA: repo state $REPO_STATE_FILE"
fi

if [ -L "$RUNTIME_STATE_FILE" ]; then
  echo "OK: runtime state link $(readlink "$RUNTIME_STATE_FILE")"
elif [ -f "$RUNTIME_STATE_FILE" ]; then
  echo "WARN: runtime state existe, mas nao e symlink para canonico"
else
  echo "FALTA: runtime state $RUNTIME_STATE_FILE"
fi

echo
echo "[6] .env (nomes apenas)"
if [ -f "$REPO_ROOT/.env" ]; then
  egrep '^(TZ|OPENROUTER_API_KEY|OPENROUTER_MANAGEMENT_KEY|TELEGRAM_BOT_TOKEN|TELEGRAM_CHAT_ID|SLACK_BOT_TOKEN|SLACK_SIGNING_SECRET|SLACK_ALERT_CHANNEL_ID|CONVEX_DEPLOYMENT_URL|CONVEX_DEPLOY_KEY|NANOBOT_RUNTIME_HOME|NANOBOT_WORKSPACE_PATH|NANOBOT_DEFAULT_MODEL|CLAWWORK_REPO_PATH|CLAWMODE_PYTHONPATH)=' "$REPO_ROOT/.env" | cut -d= -f1
else
  echo "FALTA: $REPO_ROOT/.env"
fi

echo
echo "[7] Smoke CLI (sem side effects)"
if [ -n "$NANOBOT_CMD" ]; then
  "$NANOBOT_CMD" --help >/dev/null 2>&1 && echo "OK: nanobot --help" || echo "WARN: nanobot --help falhou"
fi

if python3 - <<'PY' >/dev/null 2>&1
import importlib.util
import sys
sys.exit(0 if importlib.util.find_spec("clawmode_integration.cli") else 1)
PY
then
  echo "OK: modulo clawmode_integration.cli importavel"
  python3 -m clawmode_integration.cli --help >/dev/null 2>&1 && echo "OK: clawmode_integration.cli --help" || echo "WARN: clawmode_integration.cli --help falhou"
else
  echo "WARN: modulo clawmode_integration.cli nao importavel (ajuste PYTHONPATH para repo ClawWork)"
fi

echo
echo "Comandos de smoke recomendados (manual):"
echo "- nanobot agent -m \"hello\""
echo "- python -m clawmode_integration.cli agent -m \"/clawwork status\""
echo "- python -m clawmode_integration.cli gateway"

echo
echo "OK."
