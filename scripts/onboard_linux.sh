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

INTERACTIVE="${INTERACTIVE:-0}"
SET_TZ="${SET_TZ:-0}"

say(){ echo -e "\n==> $*"; }
warn(){ echo -e "\n[WARN] $*" >&2; }
need_cmd(){ command -v "$1" >/dev/null 2>&1; }
die(){ echo -e "\n[ERRO] $*" >&2; exit 1; }

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

  say "Instalando NVM em $NVM_DIR"
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

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

configure_env_interactive() {
  local env_file="$REPO_ROOT/.env"
  echo
  echo "== Configuracao interativa (.env) =="
  echo "Nada sera exibido ao digitar chaves."
  echo

  local tz
  tz="$(prompt_text "TZ" "America/Sao_Paulo")"
  set_env_kv "$env_file" "TZ" "$tz"

  local litellm_key
  litellm_key="$(prompt_secret "LITELLM_API_KEY")"
  [ -n "$litellm_key" ] && set_env_kv "$env_file" "LITELLM_API_KEY" "$litellm_key"

  local litellm_master
  litellm_master="$(prompt_secret "LITELLM_MASTER_KEY (somente servico budget/admin)")"
  [ -n "$litellm_master" ] && set_env_kv "$env_file" "LITELLM_MASTER_KEY" "$litellm_master"

  local litellm_url
  litellm_url="$(prompt_text "LITELLM_BASE_URL" "http://127.0.0.1:4000/v1")"
  set_env_kv "$env_file" "LITELLM_BASE_URL" "$litellm_url"

  local codex_oauth
  codex_oauth="$(prompt_secret "CODEX_OAUTH_ACCESS_TOKEN (alias codex-main)")"
  [ -n "$codex_oauth" ] && set_env_kv "$env_file" "CODEX_OAUTH_ACCESS_TOKEN" "$codex_oauth"

  local anthropic_key
  anthropic_key="$(prompt_secret "ANTHROPIC_API_KEY (alias claude-review)")"
  [ -n "$anthropic_key" ] && set_env_kv "$env_file" "ANTHROPIC_API_KEY" "$anthropic_key"

  local openai_key
  openai_key="$(prompt_secret "OPENAI_API_KEY (opcional)")"
  [ -n "$openai_key" ] && set_env_kv "$env_file" "OPENAI_API_KEY" "$openai_key"

  local tgbot
  tgbot="$(prompt_secret "TELEGRAM_BOT_TOKEN")"
  [ -n "$tgbot" ] && set_env_kv "$env_file" "TELEGRAM_BOT_TOKEN" "$tgbot"

  local chat
  chat="$(prompt_text "TELEGRAM_CHAT_ID (canonico, opcional se USER/GROUP definido)" "")"
  [ -n "$chat" ] && set_env_kv "$env_file" "TELEGRAM_CHAT_ID" "$chat"

  local tg_user
  tg_user="$(prompt_text "TELEGRAM_USER_ID (alias opcional)" "")"
  [ -n "$tg_user" ] && set_env_kv "$env_file" "TELEGRAM_USER_ID" "$tg_user"

  local tg_group
  tg_group="$(prompt_text "TELEGRAM_GROUP_ID (alias opcional)" "")"
  [ -n "$tg_group" ] && set_env_kv "$env_file" "TELEGRAM_GROUP_ID" "$tg_group"

  local slackbot
  slackbot="$(prompt_secret "SLACK_BOT_TOKEN")"
  [ -n "$slackbot" ] && set_env_kv "$env_file" "SLACK_BOT_TOKEN" "$slackbot"

  local slacksign
  slacksign="$(prompt_secret "SLACK_SIGNING_SECRET")"
  [ -n "$slacksign" ] && set_env_kv "$env_file" "SLACK_SIGNING_SECRET" "$slacksign"

  local slackapp
  slackapp="$(prompt_secret "SLACK_APP_TOKEN (opcional)")"
  [ -n "$slackapp" ] && set_env_kv "$env_file" "SLACK_APP_TOKEN" "$slackapp"

  local slackchan
  slackchan="$(prompt_text "SLACK_ALERT_CHANNEL_ID (opcional, ex: C0123456789)" "")"
  [ -n "$slackchan" ] && set_env_kv "$env_file" "SLACK_ALERT_CHANNEL_ID" "$slackchan"

  local cxurl
  cxurl="$(prompt_text "CONVEX_DEPLOYMENT_URL (https://...convex.cloud)" "")"
  [ -n "$cxurl" ] && set_env_kv "$env_file" "CONVEX_DEPLOYMENT_URL" "$cxurl"

  local cxkey
  cxkey="$(prompt_secret "CONVEX_DEPLOY_KEY")"
  [ -n "$cxkey" ] && set_env_kv "$env_file" "CONVEX_DEPLOY_KEY" "$cxkey"

  local hb
  hb="$(prompt_text "HEARTBEAT_MINUTES" "15")"
  set_env_kv "$env_file" "HEARTBEAT_MINUTES" "$hb"

  local st
  st="$(prompt_text "STANDUP_TIME (HH:MM)" "11:30")"
  set_env_kv "$env_file" "STANDUP_TIME" "$st"

  local gw
  gw="$(prompt_text "OPENCLAW_GATEWAY_URL" "http://127.0.0.1:18789/v1")"
  set_env_kv "$env_file" "OPENCLAW_GATEWAY_URL" "$gw"

  local sup_primary
  sup_primary="$(prompt_text "OPENCLAW_SUPERVISOR_PRIMARY" "codex-main")"
  set_env_kv "$env_file" "OPENCLAW_SUPERVISOR_PRIMARY" "$sup_primary"

  local sup_secondary
  sup_secondary="$(prompt_text "OPENCLAW_SUPERVISOR_SECONDARY" "claude-review")"
  set_env_kv "$env_file" "OPENCLAW_SUPERVISOR_SECONDARY" "$sup_secondary"

  local worker_code
  worker_code="$(prompt_text "OPENCLAW_WORKER_CODE_MODEL" "ollama/qwen2.5-coder:32b")"
  set_env_kv "$env_file" "OPENCLAW_WORKER_CODE_MODEL" "$worker_code"

  local worker_reason
  worker_reason="$(prompt_text "OPENCLAW_WORKER_REASON_MODEL" "ollama/deepseek-r1:32b")"
  set_env_kv "$env_file" "OPENCLAW_WORKER_REASON_MODEL" "$worker_reason"

  if [ -z "$chat" ] && [ -z "$tg_user" ] && [ -z "$tg_group" ]; then
    warn "Nenhum ID Telegram informado. Defina TELEGRAM_CHAT_ID ou um alias USER/GROUP."
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

main() {
  detect_platform
  say "Repo: $REPO_ROOT"
  say "Plataforma detectada: $HOST_OS"

  install_base_deps
  maybe_set_timezone

  ensure_nvm
  ensure_node
  ensure_openclaw
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
  echo "3) Documente no README o comando de inicializacao do OpenClaw."
}

main "$@"
