#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$REPO_ROOT/.env"
HOST_OS="$(uname -s)"

FAILURES=0
WARNINGS=0

pass() { echo "[PASS] $*"; }
warn() { WARNINGS=$((WARNINGS + 1)); echo "[WARN] $*"; }
fail() { FAILURES=$((FAILURES + 1)); echo "[FAIL] $*"; }

key_present() {
  local key="$1"
  grep -Eq "^[[:space:]]*${key}=" "$ENV_FILE"
}

value_for_key() {
  local key="$1"
  awk -F= -v key="$key" '
    $0 ~ "^[[:space:]]*" key "=" {
      sub("^[[:space:]]*" key "=", "", $0)
      print $0
      exit
    }
  ' "$ENV_FILE"
}

check_exact_default() {
  local key="$1" expected="$2" value
  value="$(value_for_key "$key")"
  if [ "$value" = "$expected" ]; then
    pass "$key=$expected"
  elif [ -n "$value" ]; then
    fail "$key=$value (esperado: $expected)."
  else
    fail "$key sem valor."
  fi
}

check_openclaw_new_shell() {
  local shell_cmd shell_name
  case "$HOST_OS" in
    Darwin)
      shell_cmd="zsh -lic"
      shell_name="zsh -lic"
      ;;
    *)
      shell_cmd="bash -lic"
      shell_name="bash -lic"
      ;;
  esac

  if eval "$shell_cmd 'command -v openclaw >/dev/null 2>&1 && openclaw --version >/dev/null 2>&1'"; then
    pass "openclaw disponivel em nova sessao ($shell_name)."
  else
    fail "openclaw nao ficou disponivel em nova sessao ($shell_name)."
  fi
}

try_load_nvm_openclaw() {
  if command -v openclaw >/dev/null 2>&1; then
    return
  fi
  if [ -s "$HOME/.nvm/nvm.sh" ]; then
    # shellcheck disable=SC1090
    . "$HOME/.nvm/nvm.sh"
  fi
}

echo "== Verify assistant-brain + OpenClaw (gate) =="
try_load_nvm_openclaw

echo
echo "[1] Runtime OpenClaw"
if command -v openclaw >/dev/null 2>&1; then
  pass "openclaw no PATH: $(command -v openclaw)"
  if openclaw --version >/dev/null 2>&1; then
    pass "openclaw --version: $(openclaw --version)"
  else
    fail "openclaw encontrado, mas 'openclaw --version' falhou."
  fi
  check_openclaw_new_shell
else
  fail "FALTA: openclaw (rode scripts/onboard_linux.sh)."
fi

echo
echo "[2] Dependencias de host"
if command -v git >/dev/null 2>&1; then
  pass "git: $(git --version)"
else
  fail "FALTA: git"
fi

if command -v python3 >/dev/null 2>&1; then
  pass "python3: $(python3 --version)"
else
  fail "FALTA: python3"
fi

echo
echo "[3] Contrato .env (hibrido)"
if [ ! -f "$ENV_FILE" ]; then
  fail "FALTA: .env na raiz do repo."
else
  required_keys=(
    TZ
    LITELLM_API_KEY
    LITELLM_MASTER_KEY
    LITELLM_BASE_URL
    CODEX_OAUTH_ACCESS_TOKEN
    ANTHROPIC_API_KEY
    OPENCLAW_SUPERVISOR_PRIMARY
    OPENCLAW_SUPERVISOR_SECONDARY
    OPENCLAW_WORKER_CODE_MODEL
    OPENCLAW_WORKER_REASON_MODEL
    TELEGRAM_BOT_TOKEN
    SLACK_BOT_TOKEN
    SLACK_SIGNING_SECRET
    CONVEX_DEPLOYMENT_URL
    CONVEX_DEPLOY_KEY
    HEARTBEAT_MINUTES
    STANDUP_TIME
    OPENCLAW_GATEWAY_URL
  )

  for key in "${required_keys[@]}"; do
    if key_present "$key"; then
      pass ".env contem chave obrigatoria: $key"
    else
      fail ".env sem chave obrigatoria: $key"
    fi
  done

  if key_present "TELEGRAM_CHAT_ID"; then
    pass "Telegram ID canonico presente: TELEGRAM_CHAT_ID"
  elif key_present "TELEGRAM_USER_ID" || key_present "TELEGRAM_GROUP_ID"; then
    pass "Telegram ID via alias (USER_ID/GROUP_ID)."
  else
    fail "FALTA Telegram ID: informe TELEGRAM_CHAT_ID (canonico) ou alias USER/GROUP."
  fi

  optional_template_keys=(
    OPENAI_API_KEY
    SLACK_APP_TOKEN
    EMAIL_ADDRESS
    GITHUB_TOKEN
    SENTRY_DSN
    STRIPE_SECRET_KEY
    CLOUDFLARE_TUNNEL_ID
    OPENCLAW_GATEWAY_PORT
    OPENCLAW_GATEWAY_BIND
    OPENCLAW_WORKSPACE
    NODE_ENV
    LOG_LEVEL
    QMD_HOST
    QMD_PORT
    QMD_DATABASE
    QMD_USER
    QMD_PASSWORD
  )
  present_optional=0
  for key in "${optional_template_keys[@]}"; do
    if key_present "$key"; then
      present_optional=$((present_optional + 1))
    fi
  done
  if [ "$present_optional" -gt 0 ]; then
    pass "Template completo referenciado: $present_optional chave(s) opcionais detectadas."
  else
    warn "Nenhuma chave opcional do template completo detectada (.env valido, mas minimo)."
  fi
fi

echo
echo "[4] Estrutura minima do brain"
required_paths=(
  "$REPO_ROOT/PRD"
  "$REPO_ROOT/ARC"
  "$REPO_ROOT/SEC"
  "$REPO_ROOT/workspaces/main"
)
for path in "${required_paths[@]}"; do
  if [ -e "$path" ]; then
    pass "estrutura presente: $path"
  else
    fail "estrutura ausente: $path"
  fi
done

echo
echo "[5] Heartbeat baseline (15 min)"
if [ -f "$ENV_FILE" ]; then
  check_exact_default "HEARTBEAT_MINUTES" "15"
  check_exact_default "STANDUP_TIME" "11:30"
  check_exact_default "OPENCLAW_GATEWAY_URL" "http://127.0.0.1:18789/v1"
  check_exact_default "LITELLM_BASE_URL" "http://127.0.0.1:4000/v1"
  check_exact_default "OPENCLAW_SUPERVISOR_PRIMARY" "codex-main"
  check_exact_default "OPENCLAW_SUPERVISOR_SECONDARY" "claude-review"
else
  fail ".env ausente; defaults normativos nao podem ser validados."
fi

echo
if [ "$FAILURES" -gt 0 ]; then
  echo "verify: FAIL ($FAILURES erro(s), $WARNINGS aviso(s))."
  exit 1
fi

echo "verify: PASS (0 erro(s), $WARNINGS aviso(s))."
