#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "== Verify assistant-brain =="

echo
echo "[1] OS"
uname -a || true

echo
echo "[2] Git/Python"
git --version || true
python3 --version || true

echo
echo "[3] .env"
if [ -f "$REPO_ROOT/.env" ]; then
  echo "OK: .env existe"
  echo "(mostrando apenas nomes das variáveis principais)"
  egrep '^(TZ|OPENAI_API_KEY|TELEGRAM_BOT_TOKEN|TELEGRAM_CHAT_ID|CONVEX_DEPLOYMENT_URL|CONVEX_DEPLOY_KEY)=' "$REPO_ROOT/.env" | cut -d= -f1
else
  echo "FALTA: .env — rode scripts/onboard_linux.sh"
fi

echo
echo "[4] Pastas importantes"
ls -la "$REPO_ROOT/agent" "$REPO_ROOT/memory" "$REPO_ROOT/workspaces" 2>/dev/null || true

echo
echo "[5] venv (se existir)"
if [ -x "$REPO_ROOT/.venv/bin/python" ]; then
  echo "OK: venv existe (.venv)"
  "$REPO_ROOT/.venv/bin/python" -V
else
  echo "venv não existe (ok se ainda não há requirements/pyproject)"
fi

echo
echo "OK."
