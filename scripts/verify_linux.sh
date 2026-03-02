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

normalize_env_value() {
  printf "%s" "${1:-}" | tr -d '\r' | xargs
}

is_placeholder_value() {
  local key="$1"
  local value
  value="$(normalize_env_value "${2:-}")"
  case "${key}:${value}" in
    "ANTHROPIC_API_KEY:sk-ant-..."|\
    "TELEGRAM_BOT_TOKEN:123456789:ABCDEfghijklmnopqrstuvwxyz_1234567890"|\
    "SLACK_BOT_TOKEN:xoxb-..."|\
    "SLACK_SIGNING_SECRET:..."|\
    "TELEGRAM_USER_ID:123456789"|\
    "TELEGRAM_GROUP_ID:-1001234567890"|\
    "LITELLM_API_KEY:...")
      return 0
      ;;
  esac
  return 1
}

is_effective_env_value() {
  local key="$1"
  local value
  value="$(normalize_env_value "${2:-}")"
  [ -n "$value" ] || return 1
  if is_placeholder_value "$key" "$value"; then
    return 1
  fi
  return 0
}

runtime_mode_value() {
  local raw
  raw="$(normalize_env_value "$(value_for_key "OPENCLAW_RUNTIME_MODE")")"
  raw="$(printf "%s" "$raw" | tr '[:upper:]' '[:lower:]')"
  if [ -z "$raw" ]; then
    printf "%s\n" "cloud"
    return
  fi
  printf "%s\n" "$raw"
}

check_required_env_value() {
  local key="$1"
  local mode_label="${2:-global}"
  local value norm

  if ! key_present "$key"; then
    fail ".env sem chave obrigatoria ($mode_label): $key"
    return
  fi

  value="$(value_for_key "$key")"
  norm="$(normalize_env_value "$value")"

  if [ -z "$norm" ]; then
    fail "$key vazio (obrigatorio em $mode_label)."
    return
  fi

  if is_placeholder_value "$key" "$norm"; then
    fail "$key com placeholder invalido (obrigatorio em $mode_label); informe valor real."
    return
  fi

  pass ".env chave obrigatoria valida ($mode_label): $key"
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
echo "[3] Contrato .env (runtime mode)"
if [ ! -f "$ENV_FILE" ]; then
  fail "FALTA: .env na raiz do repo."
else
  mode="$(runtime_mode_value)"
  if ! [[ "$mode" =~ ^(local-only|hybrid|cloud)$ ]]; then
    fail "OPENCLAW_RUNTIME_MODE invalido: '$mode' (use: local-only|hybrid|cloud)."
    mode="cloud"
  fi
  pass "OPENCLAW_RUNTIME_MODE=$mode"

  required_keys_common=(
    TZ
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

  for key in "${required_keys_common[@]}"; do
    check_required_env_value "$key" "$mode"
  done

  if [ "$mode" = "local-only" ]; then
    if key_present "OPENCLAW_SUPERVISOR_PRIMARY"; then
      sup_primary_value="$(normalize_env_value "$(value_for_key "OPENCLAW_SUPERVISOR_PRIMARY")")"
      if [ "$sup_primary_value" = "local-main" ]; then
        pass "OPENCLAW_SUPERVISOR_PRIMARY=local-main (perfil local-only)."
      else
        fail "OPENCLAW_SUPERVISOR_PRIMARY='$sup_primary_value' (esperado local-main em local-only)."
      fi
    fi
    if key_present "OPENCLAW_SUPERVISOR_SECONDARY"; then
      sup_secondary_value="$(normalize_env_value "$(value_for_key "OPENCLAW_SUPERVISOR_SECONDARY")")"
      if [ "$sup_secondary_value" = "local-review" ]; then
        pass "OPENCLAW_SUPERVISOR_SECONDARY=local-review (perfil local-only)."
      else
        fail "OPENCLAW_SUPERVISOR_SECONDARY='$sup_secondary_value' (esperado local-review em local-only)."
      fi
    fi
  else
    required_keys_hybrid_cloud=(
      LITELLM_API_KEY
      LITELLM_MASTER_KEY
      LITELLM_BASE_URL
      OPENROUTER_API_KEY
    )
    for key in "${required_keys_hybrid_cloud[@]}"; do
      check_required_env_value "$key" "$mode"
    done
  fi

  telegram_chat_id_value="$(normalize_env_value "$(value_for_key "TELEGRAM_CHAT_ID")")"
  telegram_user_id_value="$(normalize_env_value "$(value_for_key "TELEGRAM_USER_ID")")"
  telegram_group_id_value="$(normalize_env_value "$(value_for_key "TELEGRAM_GROUP_ID")")"
  if is_effective_env_value "TELEGRAM_CHAT_ID" "$telegram_chat_id_value"; then
    pass "Telegram ID canonico valido: TELEGRAM_CHAT_ID"
  elif is_effective_env_value "TELEGRAM_USER_ID" "$telegram_user_id_value" \
    || is_effective_env_value "TELEGRAM_GROUP_ID" "$telegram_group_id_value"; then
    pass "Telegram ID valido via alias (TELEGRAM_USER_ID/TELEGRAM_GROUP_ID)."
  else
    fail "Telegram ID invalido: informe TELEGRAM_CHAT_ID ou alias TELEGRAM_USER_ID/TELEGRAM_GROUP_ID com valor real."
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

  if [ "$mode" = "local-only" ]; then
    if key_present "OPENROUTER_API_KEY"; then
      openrouter_api_key_value="$(value_for_key "OPENROUTER_API_KEY" | tr -d '\r' | xargs)"
      if [ -n "$openrouter_api_key_value" ]; then
        pass "OPENROUTER_API_KEY informada (opcional em local-only)."
      else
        pass "OPENROUTER_API_KEY vazia (opcional em local-only)."
      fi
    else
      pass "OPENROUTER_API_KEY ausente (opcional em local-only)."
    fi
  else
    pass "OPENROUTER_API_KEY obrigatoria validada para $mode."
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
  mode="$(runtime_mode_value)"
  if [ "$mode" = "local-only" ]; then
    check_exact_default "OPENCLAW_SUPERVISOR_PRIMARY" "local-main"
    check_exact_default "OPENCLAW_SUPERVISOR_SECONDARY" "local-review"
  else
    check_exact_default "LITELLM_BASE_URL" "http://127.0.0.1:4000/v1"
    check_exact_default "OPENCLAW_SUPERVISOR_PRIMARY" "openrouter-main"
    check_exact_default "OPENCLAW_SUPERVISOR_SECONDARY" "openrouter-review"
  fi
else
  fail ".env ausente; defaults normativos nao podem ser validados."
fi

echo
if [ "$FAILURES" -gt 0 ]; then
  echo "verify: FAIL ($FAILURES erro(s), $WARNINGS aviso(s))."
  exit 1
fi

echo "verify: PASS (0 erro(s), $WARNINGS aviso(s))."
