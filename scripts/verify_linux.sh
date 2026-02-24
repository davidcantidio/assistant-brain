#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "== Verify assistant-brain + OpenClaw =="

echo
echo "[1] Node/NVM/OpenClaw"
if command -v openclaw >/dev/null 2>&1; then
  echo "openclaw: $(command -v openclaw)"
  openclaw --version || true
else
  echo "FALTA: openclaw (rode scripts/onboard_linux.sh)"
fi

echo
echo "[2] Git/Python"
git --version || true
python3 --version || true

echo
echo "[3] .env (mostrando apenas nomes)"
if [ -f "$REPO_ROOT/.env" ]; then
  egrep '^(TZ|LITELLM_API_KEY|LITELLM_MASTER_KEY|LITELLM_BASE_URL|CODEX_OAUTH_ACCESS_TOKEN|ANTHROPIC_API_KEY|OPENCLAW_SUPERVISOR_PRIMARY|OPENCLAW_SUPERVISOR_SECONDARY|OPENCLAW_WORKER_CODE_MODEL|OPENCLAW_WORKER_REASON_MODEL|TELEGRAM_BOT_TOKEN|TELEGRAM_CHAT_ID|SLACK_BOT_TOKEN|SLACK_SIGNING_SECRET|SLACK_ALERT_CHANNEL_ID|CONVEX_DEPLOYMENT_URL|CONVEX_DEPLOY_KEY|OPENCLAW_GATEWAY_URL|OPENROUTER_API_KEY)=' "$REPO_ROOT/.env" | cut -d= -f1
else
  echo "FALTA: .env"
fi

echo
echo "[4] Estrutura do brain"
ls -la "$REPO_ROOT/PRD" "$REPO_ROOT/ARC" "$REPO_ROOT/SEC" "$REPO_ROOT/workspaces/main" 2>/dev/null || true

echo
echo "[5] Heartbeat baseline (15 min)"
if [ -f "$REPO_ROOT/.env" ]; then
  hb="$(grep -E '^HEARTBEAT_MINUTES=' "$REPO_ROOT/.env" | tail -n1 | cut -d= -f2- || true)"
  if [ -n "$hb" ]; then
    echo "HEARTBEAT_MINUTES=$hb"
  else
    echo "HEARTBEAT_MINUTES ausente no .env"
  fi
else
  echo ".env ausente"
fi

echo
echo "OK."
