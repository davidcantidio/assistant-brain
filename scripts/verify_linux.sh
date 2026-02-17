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
  egrep '^(TZ|OPENAI_API_KEY|TELEGRAM_BOT_TOKEN|TELEGRAM_CHAT_ID|CONVEX_DEPLOYMENT_URL|CONVEX_DEPLOY_KEY)=' "$REPO_ROOT/.env" | cut -d= -f1
else
  echo "FALTA: .env"
fi

echo
echo "[4] Estrutura do brain"
ls -la "$REPO_ROOT/agent" "$REPO_ROOT/memory" "$REPO_ROOT/workspaces" 2>/dev/null || true

echo
echo "OK."
