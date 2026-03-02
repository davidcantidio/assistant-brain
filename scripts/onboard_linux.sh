#!/usr/bin/env bash
set -euo pipefail

# Onboarding do assistant-brain (Linux/macOS) - idempotente
# - Linux: instala deps base via apt-get
# - macOS: instala deps base via brew e valida Command Line Tools
# - Instala NVM (se faltar)
# - Instala Node via NVM (default: 22.22.0)
# - Instala OpenClaw via npm global (default: openclaw@2026.2.14)
# - Prepara .env / templates
#
# Uso:
#   bash scripts/onboard_linux.sh
# Interativo (perguntar chaves e preencher .env):
#   INTERACTIVE=1 bash scripts/onboard_linux.sh

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOST_OS="$(uname -s)"

NODE_VERSION="${NODE_VERSION:-22.22.0}"
OPENCLAW_NPM_PKG="${OPENCLAW_NPM_PKG:-openclaw}"
OPENCLAW_VERSION="${OPENCLAW_VERSION:-2026.2.14}"
NVM_INSTALL_VERSION="${NVM_INSTALL_VERSION:-v0.39.7}"
NVM_INSTALL_URL="https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_INSTALL_VERSION}/install.sh"
# Hash fixo do install.sh v0.39.7 (defesa basica contra supply-chain tampering).
NVM_INSTALL_SHA256="8e45fa547f428e9196a5613efad3bfa4d4608b74ca870f930090598f5af5f643"

INTERACTIVE="${INTERACTIVE:-0}"
SET_TZ="${SET_TZ:-0}"

say(){ echo -e "\n==> $*"; }
warn(){ echo -e "\n[WARN] $*" >&2; }
need_cmd(){ command -v "$1" >/dev/null 2>&1; }
die(){ echo -e "\n[ERRO] $*" >&2; exit 1; }

sha256_file() {
  local path="$1"
  if need_cmd shasum; then
    shasum -a 256 "$path" | awk '{print $1}'
    return
  fi
  if need_cmd sha256sum; then
    sha256sum "$path" | awk '{print $1}'
    return
  fi
  if need_cmd openssl; then
    openssl dgst -sha256 "$path" | awk '{print $NF}'
    return
  fi
  die "Nao foi possivel calcular SHA-256 (shasum/sha256sum/openssl ausentes)."
}

download_checked() {
  local url="$1"
  local expected_sha256="$2"
  local out_file="$3"

  curl -fsSL "$url" -o "$out_file"
  local actual_sha256
  actual_sha256="$(sha256_file "$out_file")"
  if [ "$actual_sha256" != "$expected_sha256" ]; then
    rm -f "$out_file"
    die "Checksum invalido para download de $url (esperado: $expected_sha256, obtido: $actual_sha256)."
  fi
}

detect_platform() {
  case "$HOST_OS" in
    Linux|Darwin)
      ;;
    *)
      die "SO nao suportado: $HOST_OS (suportados: Linux, Darwin)."
      ;;
  esac
}

apt_install() {
  need_cmd sudo || die "sudo nao encontrado."
  need_cmd apt-get || die "apt-get nao encontrado (Linux Debian/Ubuntu requerido)."
  sudo apt-get update -y
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@"
}

brew_install() {
  need_cmd brew || die "brew nao encontrado. Instale Homebrew e rode novamente."
  brew update >/dev/null
  brew install "$@"
}

validate_macos_clt() {
  if xcode-select -p >/dev/null 2>&1; then
    return
  fi
  die "Command Line Tools nao encontrado. Rode: xcode-select --install"
}

maybe_set_timezone() {
  if [ "$SET_TZ" != "1" ]; then
    warn "Timezone nao sera alterado (SET_TZ=1 para ajustar)."
    return
  fi

  case "$HOST_OS" in
    Linux)
      if need_cmd timedatectl; then
        say "Ajustando timezone para America/Sao_Paulo"
        sudo timedatectl set-timezone America/Sao_Paulo || warn "Falha ao setar timezone via timedatectl."
      else
        warn "timedatectl nao encontrado; pulando timezone."
      fi
      ;;
    Darwin)
      if need_cmd systemsetup; then
        say "Ajustando timezone para America/Sao_Paulo (sudo systemsetup)"
        sudo systemsetup -settimezone "America/Sao_Paulo" >/dev/null || warn "Falha ao setar timezone via systemsetup."
      else
        warn "systemsetup nao encontrado; pulando timezone."
      fi
      ;;
  esac
}

install_base_deps() {
  case "$HOST_OS" in
    Linux)
      say "Instalando dependencias base Linux (curl, git, python3, build-essential)"
      apt_install ca-certificates curl git python3 python3-venv python3-pip build-essential
      ;;
    Darwin)
      say "Validando Command Line Tools no macOS"
      validate_macos_clt
      say "Instalando dependencias base macOS (curl, git, python)"
      brew_install curl git python
      ;;
  esac
}

# ---------- NVM / Node ----------
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

append_nvm_hook() {
  local profile="$1"
  [ -f "$profile" ] || touch "$profile"
  if grep -q "NVM (OpenClaw onboarding)" "$profile" 2>/dev/null; then
    return
  fi
  cat >> "$profile" <<'EOT'

# NVM (OpenClaw onboarding)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
EOT
}

ensure_nvm_profiles() {
  append_nvm_hook "$HOME/.bashrc"
  append_nvm_hook "$HOME/.zshrc"
}

ensure_nvm() {
  if [ -s "$NVM_DIR/nvm.sh" ]; then
    # shellcheck disable=SC1090
    source "$NVM_DIR/nvm.sh"
    say "NVM ja existe."
    ensure_nvm_profiles
    return
  fi

  say "Instalando NVM em $NVM_DIR (download com verificacao SHA-256)"
  local tmp_install_script
  tmp_install_script="$(mktemp)"
  download_checked "$NVM_INSTALL_URL" "$NVM_INSTALL_SHA256" "$tmp_install_script"
  bash "$tmp_install_script"
  rm -f "$tmp_install_script"

  # shellcheck disable=SC1090
  source "$NVM_DIR/nvm.sh"
  ensure_nvm_profiles
}

ensure_node() {
  say "Garantindo Node v$NODE_VERSION via NVM"
  nvm install "$NODE_VERSION" >/dev/null
  nvm use "$NODE_VERSION" >/dev/null
  nvm alias default "$NODE_VERSION" >/dev/null
  say "Node: $(node -v) | npm: $(npm -v)"
}

# ---------- OpenClaw via npm ----------
ensure_openclaw() {
  say "Garantindo OpenClaw CLI ($OPENCLAW_NPM_PKG@$OPENCLAW_VERSION)"
  if need_cmd openclaw; then
    local cur
    cur="$(openclaw --version 2>/dev/null || true)"
    if [ "$cur" = "$OPENCLAW_VERSION" ]; then
      say "openclaw ja esta na versao desejada: $cur"
      return
    fi
    warn "openclaw encontrado ($cur), ajustando para $OPENCLAW_VERSION"
  fi

  npm i -g "${OPENCLAW_NPM_PKG}@${OPENCLAW_VERSION}"

  need_cmd openclaw || die "Instalei ${OPENCLAW_NPM_PKG}@${OPENCLAW_VERSION}, mas 'openclaw' nao apareceu no PATH."
  say "openclaw: $(command -v openclaw)"
  say "openclaw version: $(openclaw --version)"
}

# ---------- Templates / .env ----------
create_templates() {
  say "Criando templates e .env (sem sobrescrever valores existentes)"
  mkdir -p "$REPO_ROOT/config"

  if [ ! -f "$REPO_ROOT/config/openclaw.env.example" ]; then
    if [ -f "$REPO_ROOT/.env_example" ]; then
      cp "$REPO_ROOT/.env_example" "$REPO_ROOT/config/openclaw.env.example"
      warn "config/openclaw.env.example ausente; copiado de .env_example."
    else
      die "Template de env ausente. Esperado: config/openclaw.env.example"
    fi
  fi

  if [ ! -f "$REPO_ROOT/.env" ]; then
    cp "$REPO_ROOT/config/openclaw.env.example" "$REPO_ROOT/.env"
    say "Criado $REPO_ROOT/.env (preencha depois)"
  else
    say ".env ja existe (nao sobrescrevendo)"
  fi
}

prompt_secret() { local label="$1"; local var; read -r -s -p "$label: " var; echo; echo "$var"; }
prompt_text() { local label="$1"; local def="${2:-}"; local var; if [ -n "$def" ]; then read -r -p "$label [$def]: " var; echo "${var:-$def}"; else read -r -p "$label: " var; echo "$var"; fi; }

set_env_kv() {
  local file="$1" key="$2" val="$3" tmp
  [ -f "$file" ] || touch "$file"

  tmp="$(mktemp)"
  awk -v key="$key" -v val="$val" '
    BEGIN { done=0 }
    $0 ~ "^" key "=" {
      print key "=" val
      done=1
      next
    }
    { print }
    END {
      if (!done) {
        print key "=" val
      }
    }
  ' "$file" > "$tmp"
  mv "$tmp" "$file"
}

get_env_kv() {
  local file="$1" key="$2"
  [ -f "$file" ] || return 0
  awk -F= -v key="$key" '
    $0 ~ "^[[:space:]]*" key "=" {
      sub("^[[:space:]]*" key "=", "", $0)
      print $0
      exit
    }
  ' "$file"
}

normalize_env_value() {
  printf "%s" "${1:-}" | tr -d '\r' | xargs
}

is_placeholder_value() {
  local key="$1"
  local val
  val="$(normalize_env_value "${2:-}")"
  case "${key}:${val}" in
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
  local val
  val="$(normalize_env_value "${2:-}")"
  [ -n "$val" ] || return 1
  if is_placeholder_value "$key" "$val"; then
    return 1
  fi
  return 0
}

prompt_required_secret() {
  local file="$1" key="$2" label="$3"
  local existing raw value prompt
  existing="$(normalize_env_value "$(get_env_kv "$file" "$key")")"

  while true; do
    if is_effective_env_value "$key" "$existing"; then
      prompt="$label (Enter para manter valor atual)"
    else
      prompt="$label (obrigatorio)"
    fi

    raw="$(prompt_secret "$prompt")"
    value="$(normalize_env_value "$raw")"

    if [ -z "$value" ]; then
      if is_effective_env_value "$key" "$existing"; then
        set_env_kv "$file" "$key" "$existing"
        return 0
      fi
      warn "$key obrigatoria e nao pode ficar vazia."
      continue
    fi

    if is_effective_env_value "$key" "$value"; then
      set_env_kv "$file" "$key" "$value"
      return 0
    fi

    warn "$key com placeholder invalido; informe valor real."
  done
}

prompt_required_text() {
  local file="$1" key="$2" label="$3" default="${4:-}"
  local existing effective_default value
  existing="$(normalize_env_value "$(get_env_kv "$file" "$key")")"

  while true; do
    if is_effective_env_value "$key" "$existing"; then
      effective_default="$existing"
    else
      effective_default="$default"
    fi

    if [ -n "$effective_default" ]; then
      value="$(prompt_text "$label" "$effective_default")"
    else
      value="$(prompt_text "$label")"
    fi
    value="$(normalize_env_value "$value")"

    if is_effective_env_value "$key" "$value"; then
      set_env_kv "$file" "$key" "$value"
      return 0
    fi

    warn "$key obrigatoria e nao pode ficar vazia/placeholder."
  done
}

derive_litellm_proxy_url() {
  local base_url="$1"
  local trimmed="${base_url%/}"
  if [[ "$trimmed" == */v1 ]]; then
    printf "%s\n" "${trimmed%/v1}"
    return
  fi
  printf "%s\n" "$trimmed"
}

normalize_runtime_mode() {
  local raw
  raw="$(printf "%s" "${1:-}" | tr '[:upper:]' '[:lower:]' | xargs)"
  case "$raw" in
    local-only|hybrid|cloud) printf "%s\n" "$raw" ;;
    *) printf "%s\n" "cloud" ;;
  esac
}

ensure_openclaw_config() {
  local config_path="$HOME/.openclaw/openclaw.json"
  if [ -f "$config_path" ]; then
    say "Config OpenClaw detectada: $config_path"
    return
  fi

  say "Config OpenClaw ausente; executando bootstrap local (openclaw setup --mode local --non-interactive)"
  if openclaw setup --mode local --non-interactive; then
    say "Config OpenClaw criada em: $config_path"
    return
  fi

  warn "openclaw setup falhou; tentando fallback via openclaw onboard --accept-risk."
  if openclaw onboard --mode local --non-interactive --accept-risk --auth-choice skip --skip-channels --skip-skills --skip-daemon --skip-health --skip-ui; then
    if [ -f "$config_path" ]; then
      say "Config OpenClaw criada via fallback em: $config_path"
      return
    fi
  fi

  die "Falha ao gerar config local do OpenClaw. Rode manualmente: openclaw setup --mode local --non-interactive (ou fallback: openclaw onboard --mode local --non-interactive --accept-risk --auth-choice skip --skip-channels --skip-skills --skip-daemon --skip-health --skip-ui)"
}

telegram_defaults_from_payload() {
  local payload=""

  TELEGRAM_DEFAULT_USER_ID=""
  TELEGRAM_DEFAULT_CHAT_ID=""
  TELEGRAM_DEFAULT_CHAT_TYPE=""
  TELEGRAM_DEFAULT_USERNAME=""

  if [ -n "${TELEGRAM_UPDATE_JSON_FILE:-}" ]; then
    if [ -f "${TELEGRAM_UPDATE_JSON_FILE}" ]; then
      payload="$(cat "${TELEGRAM_UPDATE_JSON_FILE}")"
    else
      warn "TELEGRAM_UPDATE_JSON_FILE nao encontrado: ${TELEGRAM_UPDATE_JSON_FILE}"
      return
    fi
  elif [ -n "${TELEGRAM_UPDATE_JSON:-}" ]; then
    payload="${TELEGRAM_UPDATE_JSON}"
  else
    return
  fi

  local parsed=""
  if ! parsed="$(
    TELEGRAM_UPDATE_PAYLOAD="$payload" python3 - <<'PY'
import json
import os
import sys

raw = os.environ.get("TELEGRAM_UPDATE_PAYLOAD", "")
try:
    data = json.loads(raw)
except Exception as exc:
    print(f"invalid json: {exc}", file=sys.stderr)
    sys.exit(1)

msg = data.get("message") or data.get("edited_message") or {}
chat = msg.get("chat") or {}
sender = msg.get("from") or {}

user_id = sender.get("id")
chat_id = chat.get("id")
chat_type = chat.get("type") or ""
username = sender.get("username") or chat.get("username") or ""

if user_id is None and chat_id is None:
    print("telegram payload sem message.from.id e message.chat.id", file=sys.stderr)
    sys.exit(1)

def as_str(value):
    return "" if value is None else str(value)

print("|".join([as_str(user_id), as_str(chat_id), chat_type, username]))
PY
  )"; then
    warn "Nao foi possivel parsear TELEGRAM_UPDATE_JSON/FILE."
    return
  fi

  IFS='|' read -r TELEGRAM_DEFAULT_USER_ID TELEGRAM_DEFAULT_CHAT_ID TELEGRAM_DEFAULT_CHAT_TYPE TELEGRAM_DEFAULT_USERNAME <<< "$parsed"
  say "Telegram preload detectado: user_id=${TELEGRAM_DEFAULT_USER_ID:-n/a}, chat_id=${TELEGRAM_DEFAULT_CHAT_ID:-n/a}, chat_type=${TELEGRAM_DEFAULT_CHAT_TYPE:-n/a}, username=${TELEGRAM_DEFAULT_USERNAME:-n/a}"
}

generate_litellm_key_and_write_env() {
  local env_file="$1"
  local litellm_base_url="$2"
  local litellm_master="$3"
  local litellm_models="$4"
  local litellm_proxy_url="$5"

  if [ -z "$litellm_base_url" ] || [ -z "$litellm_master" ] || [ -z "$litellm_models" ]; then
    warn "Auto-geracao de LITELLM_API_KEY pulada: faltam LITELLM_BASE_URL, LITELLM_MASTER_KEY ou LITELLM_MODELS."
    return 1
  fi

  local proxy_url="$litellm_proxy_url"
  if [ -z "$proxy_url" ]; then
    proxy_url="$(derive_litellm_proxy_url "$litellm_base_url")"
  fi
  if [ -z "$proxy_url" ]; then
    warn "Nao foi possivel derivar LITELLM_PROXY_URL."
    return 1
  fi

  local output=""
  if ! output="$(
    LITELLM_PROXY_URL="$proxy_url" \
    LITELLM_MASTER_KEY="$litellm_master" \
    LITELLM_MODELS="$litellm_models" \
    LITELLM_OUTPUT_MODE="key-only" \
    python3 "$REPO_ROOT/generate_litellm_virtual_key.py" 2>&1
  )"; then
    warn "Falha ao gerar LITELLM_API_KEY automaticamente via /key/generate."
    echo "$output" >&2
    return 1
  fi

  local generated_key
  generated_key="$(printf "%s\n" "$output" | tail -n 1 | tr -d '\r' | xargs)"
  if [ -z "$generated_key" ]; then
    warn "Resposta do gerador LiteLLM sem chave consumivel."
    echo "$output" >&2
    return 1
  fi

  set_env_kv "$env_file" "LITELLM_PROXY_URL" "$proxy_url"
  set_env_kv "$env_file" "LITELLM_MODELS" "$litellm_models"
  set_env_kv "$env_file" "LITELLM_API_KEY" "$generated_key"
  say "LITELLM_API_KEY gerada automaticamente via LiteLLM /key/generate."
  return 0
}

configure_env_interactive() {
  local env_file="$REPO_ROOT/.env"
  echo
  echo "== Configuracao interativa (.env) =="
  echo "Nada sera exibido ao digitar chaves."
  echo

  telegram_defaults_from_payload
  local runtime_mode_raw runtime_mode
  runtime_mode_raw="$(prompt_text "OPENCLAW_RUNTIME_MODE (local-only|hybrid|cloud)" "cloud")"
  runtime_mode="$(normalize_runtime_mode "$runtime_mode_raw")"
  set_env_kv "$env_file" "OPENCLAW_RUNTIME_MODE" "$runtime_mode"
  say "Runtime mode selecionado: $runtime_mode"

  prompt_required_text "$env_file" "TZ" "TZ" "America/Sao_Paulo"
  local litellm_master="" litellm_url="" litellm_proxy=""
  if [ "$runtime_mode" = "local-only" ]; then
    set_env_kv "$env_file" "LITELLM_AUTO_GENERATE_KEY" "false"
    set_env_kv "$env_file" "OPENCLAW_SUPERVISOR_PRIMARY" "local-main"
    set_env_kv "$env_file" "OPENCLAW_SUPERVISOR_SECONDARY" "local-review"
    say "Modo local-only: LiteLLM/OpenRouter nao obrigatorios; supervisors locais aplicados."
  else
    prompt_required_secret "$env_file" "LITELLM_MASTER_KEY" "LITELLM_MASTER_KEY (somente servico budget/admin)"
    prompt_required_text "$env_file" "LITELLM_BASE_URL" "LITELLM_BASE_URL" "http://127.0.0.1:4000/v1"
    litellm_master="$(normalize_env_value "$(get_env_kv "$env_file" "LITELLM_MASTER_KEY")")"
    litellm_url="$(normalize_env_value "$(get_env_kv "$env_file" "LITELLM_BASE_URL")")"
    local litellm_proxy_default
    litellm_proxy_default="$(derive_litellm_proxy_url "$litellm_url")"
    litellm_proxy="$(prompt_text "LITELLM_PROXY_URL (sem /v1)" "$litellm_proxy_default")"
    [ -n "$litellm_proxy" ] && set_env_kv "$env_file" "LITELLM_PROXY_URL" "$litellm_proxy"
  fi

  local openai_key
  openai_key="$(prompt_secret "OPENAI_API_KEY (opcional)")"
  [ -n "$openai_key" ] && set_env_kv "$env_file" "OPENAI_API_KEY" "$openai_key"

  local openrouter_key
  if [ "$runtime_mode" = "local-only" ]; then
    openrouter_key="$(prompt_secret "OPENROUTER_API_KEY (opcional, cloud adapter)")"
    [ -n "$openrouter_key" ] && set_env_kv "$env_file" "OPENROUTER_API_KEY" "$openrouter_key"
  else
    prompt_required_secret "$env_file" "OPENROUTER_API_KEY" "OPENROUTER_API_KEY (obrigatorio em cloud|hybrid)"
    openrouter_key="$(normalize_env_value "$(get_env_kv "$env_file" "OPENROUTER_API_KEY")")"
  fi

  local should_auto_generate="true"
  if [ "$runtime_mode" = "local-only" ]; then
    should_auto_generate="false"
    set_env_kv "$env_file" "LITELLM_AUTO_GENERATE_KEY" "false"
  else
    local litellm_auto_generate
    litellm_auto_generate="$(prompt_text "LITELLM_AUTO_GENERATE_KEY via /key/generate? (Y/n)" "Y")"
    local litellm_auto_generate_norm
    litellm_auto_generate_norm="$(printf "%s" "$litellm_auto_generate" | tr '[:upper:]' '[:lower:]')"
    case "$litellm_auto_generate_norm" in
      n|no|0|false) should_auto_generate="false" ;;
    esac
    set_env_kv "$env_file" "LITELLM_AUTO_GENERATE_KEY" "$should_auto_generate"
  fi

  local litellm_models_default="openrouter-main,openrouter-review,local-fallback-7b"
  if [ "$runtime_mode" = "local-only" ]; then
    litellm_models_default="local-main,local-review"
  fi
  local litellm_models
  litellm_models="$(prompt_text "LITELLM_MODELS (escopo da virtual key)" "$litellm_models_default")"
  [ -n "$litellm_models" ] && set_env_kv "$env_file" "LITELLM_MODELS" "$litellm_models"

  local litellm_key_generated=0
  if [ "$runtime_mode" != "local-only" ]; then
    if [ "$should_auto_generate" = "true" ]; then
      if generate_litellm_key_and_write_env "$env_file" "$litellm_url" "$litellm_master" "$litellm_models" "$litellm_proxy"; then
        litellm_key_generated=1
      fi
    fi

    if [ "$litellm_key_generated" -ne 1 ]; then
      local existing_litellm_key
      existing_litellm_key="$(normalize_env_value "$(get_env_kv "$env_file" "LITELLM_API_KEY")")"
      local litellm_key
      while true; do
        if is_effective_env_value "LITELLM_API_KEY" "$existing_litellm_key"; then
          litellm_key="$(prompt_secret "LITELLM_API_KEY (fallback manual, obrigatoria; Enter para manter valor atual)")"
        else
          litellm_key="$(prompt_secret "LITELLM_API_KEY (fallback manual, obrigatoria)")"
        fi
        litellm_key="$(normalize_env_value "$litellm_key")"
        if is_effective_env_value "LITELLM_API_KEY" "$litellm_key"; then
          set_env_kv "$env_file" "LITELLM_API_KEY" "$litellm_key"
          break
        fi
        if [ -z "$litellm_key" ] && is_effective_env_value "LITELLM_API_KEY" "$existing_litellm_key"; then
          warn "Entrada vazia; mantendo LITELLM_API_KEY ja existente no .env."
          set_env_kv "$env_file" "LITELLM_API_KEY" "$existing_litellm_key"
          break
        fi
        warn "LITELLM_API_KEY e obrigatoria quando a auto-geracao falha."
      done

      local effective_litellm_key
      effective_litellm_key="$(normalize_env_value "$(get_env_kv "$env_file" "LITELLM_API_KEY")")"
      if ! is_effective_env_value "LITELLM_API_KEY" "$effective_litellm_key"; then
        die "Nao foi possivel concluir onboarding: LITELLM_API_KEY obrigatoria apos falha da auto-geracao."
      fi
    fi
  fi

  prompt_required_secret "$env_file" "TELEGRAM_BOT_TOKEN" "TELEGRAM_BOT_TOKEN"

  local tg_chat_default="${TELEGRAM_DEFAULT_CHAT_ID:-}"
  local tg_user_default="${TELEGRAM_DEFAULT_USER_ID:-}"
  local tg_group_default=""
  if [ -n "${TELEGRAM_DEFAULT_CHAT_ID:-}" ] && [ "${TELEGRAM_DEFAULT_CHAT_TYPE:-}" != "private" ]; then
    tg_group_default="${TELEGRAM_DEFAULT_CHAT_ID}"
  fi

  local chat
  chat="$(prompt_text "TELEGRAM_CHAT_ID (canonico, opcional se USER/GROUP definido)" "$tg_chat_default")"
  [ -n "$chat" ] && set_env_kv "$env_file" "TELEGRAM_CHAT_ID" "$chat"

  local tg_user
  tg_user="$(prompt_text "TELEGRAM_USER_ID (alias opcional)" "$tg_user_default")"
  [ -n "$tg_user" ] && set_env_kv "$env_file" "TELEGRAM_USER_ID" "$tg_user"

  local tg_group
  tg_group="$(prompt_text "TELEGRAM_GROUP_ID (alias opcional)" "$tg_group_default")"
  [ -n "$tg_group" ] && set_env_kv "$env_file" "TELEGRAM_GROUP_ID" "$tg_group"

  prompt_required_secret "$env_file" "SLACK_BOT_TOKEN" "SLACK_BOT_TOKEN"
  prompt_required_secret "$env_file" "SLACK_SIGNING_SECRET" "SLACK_SIGNING_SECRET"

  local slackapp
  slackapp="$(prompt_secret "SLACK_APP_TOKEN (opcional)")"
  [ -n "$slackapp" ] && set_env_kv "$env_file" "SLACK_APP_TOKEN" "$slackapp"

  local slackchan
  slackchan="$(prompt_text "SLACK_ALERT_CHANNEL_ID (opcional, ex: C0123456789)" "")"
  [ -n "$slackchan" ] && set_env_kv "$env_file" "SLACK_ALERT_CHANNEL_ID" "$slackchan"

  prompt_required_text "$env_file" "CONVEX_DEPLOYMENT_URL" "CONVEX_DEPLOYMENT_URL (https://...convex.cloud)"
  prompt_required_secret "$env_file" "CONVEX_DEPLOY_KEY" "CONVEX_DEPLOY_KEY"

  local hb
  hb="$(prompt_text "HEARTBEAT_MINUTES" "15")"
  set_env_kv "$env_file" "HEARTBEAT_MINUTES" "$hb"

  local st
  st="$(prompt_text "STANDUP_TIME (HH:MM)" "11:30")"
  set_env_kv "$env_file" "STANDUP_TIME" "$st"

  local gw
  gw="$(prompt_text "OPENCLAW_GATEWAY_URL" "http://127.0.0.1:18789/v1")"
  set_env_kv "$env_file" "OPENCLAW_GATEWAY_URL" "$gw"

  local sup_primary sup_secondary
  if [ "$runtime_mode" = "local-only" ]; then
    sup_primary="$(prompt_text "OPENCLAW_SUPERVISOR_PRIMARY" "local-main")"
    sup_secondary="$(prompt_text "OPENCLAW_SUPERVISOR_SECONDARY" "local-review")"
  else
    sup_primary="$(prompt_text "OPENCLAW_SUPERVISOR_PRIMARY" "openrouter-main")"
    sup_secondary="$(prompt_text "OPENCLAW_SUPERVISOR_SECONDARY" "openrouter-review")"
  fi
  set_env_kv "$env_file" "OPENCLAW_SUPERVISOR_PRIMARY" "$sup_primary"
  set_env_kv "$env_file" "OPENCLAW_SUPERVISOR_SECONDARY" "$sup_secondary"

  local worker_code
  worker_code="$(prompt_text "OPENCLAW_WORKER_CODE_MODEL" "ollama/qwen2.5:7b-instruct-q8_0")"
  set_env_kv "$env_file" "OPENCLAW_WORKER_CODE_MODEL" "$worker_code"

  local worker_reason
  worker_reason="$(prompt_text "OPENCLAW_WORKER_REASON_MODEL" "ollama/qwen2.5:7b-instruct-q8_0")"
  set_env_kv "$env_file" "OPENCLAW_WORKER_REASON_MODEL" "$worker_reason"

  local effective_chat effective_user effective_group
  effective_chat="$(normalize_env_value "$(get_env_kv "$env_file" "TELEGRAM_CHAT_ID")")"
  effective_user="$(normalize_env_value "$(get_env_kv "$env_file" "TELEGRAM_USER_ID")")"
  effective_group="$(normalize_env_value "$(get_env_kv "$env_file" "TELEGRAM_GROUP_ID")")"

  if ! is_effective_env_value "TELEGRAM_CHAT_ID" "$effective_chat" \
    && ! is_effective_env_value "TELEGRAM_USER_ID" "$effective_user" \
    && ! is_effective_env_value "TELEGRAM_GROUP_ID" "$effective_group"; then
    die "Nao foi possivel concluir onboarding: informe TELEGRAM_CHAT_ID (canonico) ou alias TELEGRAM_USER_ID/TELEGRAM_GROUP_ID com valor real."
  fi

  echo
  echo "OK: .env atualizado."
}

# ---------- Python deps (se aparecerem no repo) ----------
setup_python_if_any() {
  if [ -f "$REPO_ROOT/requirements.txt" ]; then
    say "requirements.txt encontrado - criando .venv e instalando deps"
    python3 -m venv "$REPO_ROOT/.venv"
    "$REPO_ROOT/.venv/bin/pip" install -U pip wheel setuptools
    "$REPO_ROOT/.venv/bin/pip" install -r "$REPO_ROOT/requirements.txt"
  elif [ -f "$REPO_ROOT/pyproject.toml" ]; then
    say "pyproject.toml encontrado - criando .venv e instalando projeto"
    python3 -m venv "$REPO_ROOT/.venv"
    "$REPO_ROOT/.venv/bin/pip" install -U pip wheel setuptools
    "$REPO_ROOT/.venv/bin/pip" install -e "$REPO_ROOT"
  else
    warn "Sem requirements.txt/pyproject.toml - pulando deps Python."
  fi
}

ensure_interactive_tty() {
  if [ "$INTERACTIVE" = "1" ] && [ ! -t 0 ]; then
    die "INTERACTIVE=1 requer terminal interativo (TTY). Execute em um terminal sem redirecionar stdin."
  fi
}

main() {
  detect_platform
  ensure_interactive_tty
  say "Repo: $REPO_ROOT"
  say "Plataforma detectada: $HOST_OS"

  install_base_deps
  maybe_set_timezone

  ensure_nvm
  ensure_node
  ensure_openclaw
  ensure_openclaw_config
  create_templates

  if [ "$INTERACTIVE" = "1" ]; then
    configure_env_interactive
  else
    warn "Para preencher chaves via prompt: INTERACTIVE=1 bash scripts/onboard_linux.sh"
  fi

  setup_python_if_any

  say "Concluido."
  echo "Proximos passos:"
  echo "1) (se nao usou INTERACTIVE=1) edite .env"
  echo "2) Rode: bash scripts/verify_linux.sh"
  echo "3) Inicie o gateway: openclaw gateway run --bind loopback --port 18789 --force"
}

main "$@"
