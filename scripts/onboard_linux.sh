#!/usr/bin/env bash
set -euo pipefail

# Onboarding do assistant-brain (Linux) — idempotente
# - Instala deps base (apt)
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

# Defaults baseados na sua VPS
NODE_VERSION="${NODE_VERSION:-22.22.0}"
OPENCLAW_NPM_PKG="${OPENCLAW_NPM_PKG:-openclaw}"
OPENCLAW_VERSION="${OPENCLAW_VERSION:-2026.2.14}"

INTERACTIVE="${INTERACTIVE:-0}"
SET_TZ="${SET_TZ:-0}"  # SET_TZ=1 para ajustar timezone via timedatectl (sudo)

say(){ echo -e "\n==> $*"; }
warn(){ echo -e "\n[WARN] $*" >&2; }
need_cmd(){ command -v "$1" >/dev/null 2>&1; }
die(){ echo -e "\n[ERRO] $*" >&2; exit 1; }

apt_install() {
  need_cmd sudo || die "sudo não encontrado."
  need_cmd apt-get || die "apt-get não encontrado (script assume Debian/Ubuntu)."
  sudo apt-get update -y
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@"
}

maybe_set_timezone() {
  if [ "$SET_TZ" != "1" ]; then
    warn "Timezone não será alterado (SET_TZ=1 para ajustar)."
    return
  fi
  if need_cmd timedatectl; then
    say "Ajustando timezone para America/Sao_Paulo"
    sudo timedatectl set-timezone America/Sao_Paulo || warn "Falha ao setar timezone"
  else
    warn "timedatectl não encontrado; pulando timezone."
  fi
}

install_base_deps() {
  say "Instalando dependências base (curl, git, python3, build-essential)"
  apt_install ca-certificates curl git python3 python3-venv python3-pip build-essential
}

# ---------- NVM / Node ----------
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

ensure_nvm() {
  if [ -s "$NVM_DIR/nvm.sh" ]; then
    # shellcheck disable=SC1090
    source "$NVM_DIR/nvm.sh"
    say "NVM já existe."
    return
  fi

  say "Instalando NVM em $NVM_DIR"
  # Instala NVM (usa script oficial)
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

  # shellcheck disable=SC1090
  source "$NVM_DIR/nvm.sh"

  # garante que nvm carregue no shell futuro (idempotente)
  if ! grep -q 'NVM_DIR' "$HOME/.bashrc" 2>/dev/null; then
    cat >> "$HOME/.bashrc" <<'EOT'

# NVM (OpenClaw onboarding)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
EOT
  fi
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
  # se openclaw existe e versão bate, não mexe
  if need_cmd openclaw; then
    local cur
    cur="$(openclaw --version 2>/dev/null || true)"
    if [ "$cur" = "$OPENCLAW_VERSION" ]; then
      say "openclaw já está na versão desejada: $cur"
      return
    fi
    warn "openclaw encontrado ($cur), mas vou ajustar para $OPENCLAW_VERSION"
  fi

  npm i -g "${OPENCLAW_NPM_PKG}@${OPENCLAW_VERSION}"

  need_cmd openclaw || die "Instalei ${OPENCLAW_NPM_PKG}@${OPENCLAW_VERSION}, mas 'openclaw' não apareceu no PATH."
  say "openclaw: $(command -v openclaw)"
  say "openclaw version: $(openclaw --version)"
}

# ---------- Templates / .env ----------
create_templates() {
  say "Criando templates e .env (sem sobrescrever valores existentes)"
  mkdir -p "$REPO_ROOT/config"

  if [ ! -f "$REPO_ROOT/config/openclaw.env.example" ]; then
    cat > "$REPO_ROOT/config/openclaw.env.example" <<'EOT'
# OpenClaw Env (exemplo) — NÃO COMMITAR valores reais
TZ=America/Sao_Paulo

# OpenAI
OPENAI_API_KEY=

# Telegram
TELEGRAM_BOT_TOKEN=
TELEGRAM_CHAT_ID=

# Convex
CONVEX_DEPLOYMENT_URL=
CONVEX_DEPLOY_KEY=

# Runtime
HEARTBEAT_MINUTES=45
STANDUP_TIME=11:30

# Model Router (OpenAI)
OPENCLAW_MODEL_CHEAP=gpt-4.1-mini
OPENCLAW_MODEL_STRONG=gpt-4.1
EOT
  fi

  if [ ! -f "$REPO_ROOT/.env" ]; then
    cp "$REPO_ROOT/config/openclaw.env.example" "$REPO_ROOT/.env"
    say "Criado $REPO_ROOT/.env (preencha depois)"
  else
    say ".env já existe (não sobrescrevendo)"
  fi
}

prompt_secret() { local label="$1"; local var; read -r -s -p "$label: " var; echo; echo "$var"; }
prompt_text() { local label="$1"; local def="${2:-}"; local var; if [ -n "$def" ]; then read -r -p "$label [$def]: " var; echo "${var:-$def}"; else read -r -p "$label: " var; echo "$var"; fi; }

set_env_kv() {
  local file="$1" key="$2" val="$3"
  local esc
  esc="$(printf '%s' "$val" | sed -e 's/[\/&]/\\&/g')"
  if grep -qE "^${key}=" "$file"; then
    sed -i "s/^${key}=.*/${key}=${esc}/" "$file"
  else
    echo "${key}=${val}" >> "$file"
  fi
}

configure_env_interactive() {
  local env_file="$REPO_ROOT/.env"
  echo
  echo "== Configuração interativa (.env) =="
  echo "Nada será exibido ao digitar chaves."
  echo

  local tz
  tz="$(prompt_text "TZ" "America/Sao_Paulo")"
  set_env_kv "$env_file" "TZ" "$tz"

  local openai
  openai="$(prompt_secret "OPENAI_API_KEY")"
  [ -n "$openai" ] && set_env_kv "$env_file" "OPENAI_API_KEY" "$openai"

  local tgbot
  tgbot="$(prompt_secret "TELEGRAM_BOT_TOKEN")"
  [ -n "$tgbot" ] && set_env_kv "$env_file" "TELEGRAM_BOT_TOKEN" "$tgbot"

  local chat
  chat="$(prompt_text "TELEGRAM_CHAT_ID (ex: -100...)" "")"
  [ -n "$chat" ] && set_env_kv "$env_file" "TELEGRAM_CHAT_ID" "$chat"

  local cxurl
  cxurl="$(prompt_text "CONVEX_DEPLOYMENT_URL (https://...convex.cloud)" "")"
  [ -n "$cxurl" ] && set_env_kv "$env_file" "CONVEX_DEPLOYMENT_URL" "$cxurl"

  local cxkey
  cxkey="$(prompt_secret "CONVEX_DEPLOY_KEY")"
  [ -n "$cxkey" ] && set_env_kv "$env_file" "CONVEX_DEPLOY_KEY" "$cxkey"

  local hb
  hb="$(prompt_text "HEARTBEAT_MINUTES" "45")"
  set_env_kv "$env_file" "HEARTBEAT_MINUTES" "$hb"

  local st
  st="$(prompt_text "STANDUP_TIME (HH:MM)" "11:30")"
  set_env_kv "$env_file" "STANDUP_TIME" "$st"

  echo
  echo "OK: .env atualizado."
}

# ---------- Python deps (se aparecerem no repo) ----------
setup_python_if_any() {
  if [ -f "$REPO_ROOT/requirements.txt" ]; then
    say "requirements.txt encontrado — criando .venv e instalando deps"
    python3 -m venv "$REPO_ROOT/.venv"
    "$REPO_ROOT/.venv/bin/pip" install -U pip wheel setuptools
    "$REPO_ROOT/.venv/bin/pip" install -r "$REPO_ROOT/requirements.txt"
  elif [ -f "$REPO_ROOT/pyproject.toml" ]; then
    say "pyproject.toml encontrado — criando .venv e instalando projeto"
    python3 -m venv "$REPO_ROOT/.venv"
    "$REPO_ROOT/.venv/bin/pip" install -U pip wheel setuptools
    "$REPO_ROOT/.venv/bin/pip" install -e "$REPO_ROOT"
  else
    warn "Sem requirements.txt/pyproject.toml — pulando deps Python."
  fi
}

main() {
  say "Repo: $REPO_ROOT"
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

  say "Concluído ✅"
  echo "Próximos passos:"
  echo "1) (se não usou INTERACTIVE=1) edite .env"
  echo "2) Rode: bash scripts/verify_linux.sh"
  echo "3) Documente no README qual comando você usa para iniciar o OpenClaw com este brain."
}

main "$@"
