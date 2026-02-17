#!/usr/bin/env bash
set -euo pipefail

# Onboarding do "assistant-brain" (Linux) — idempotente
# Objetivo: preparar um novo Linux pra rodar o brain do OpenClaw.
#
# Uso:
#   bash scripts/onboard_linux.sh
# Interativo (preenche .env): 
#   INTERACTIVE=1 bash scripts/onboard_linux.sh

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

INTERACTIVE="${INTERACTIVE:-0}"
SET_TZ="${SET_TZ:-0}"
INSTALL_NODE="${INSTALL_NODE:-0}"

say(){ echo -e "\n==> $*"; }
warn(){ echo -e "\n[WARN] $*" >&2; }
need_cmd(){ command -v "$1" >/dev/null 2>&1; }
die(){ echo -e "\n[ERRO] $*" >&2; exit 1; }

apt_install() {
  if ! need_cmd apt-get; then
    die "apt-get não encontrado. Este script assume Ubuntu/Debian."
  fi
  if ! need_cmd sudo; then
    die "sudo não encontrado. Instale sudo ou rode como root."
  fi
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
  fi
}

create_templates() {
  say "Garantindo pastas e templates"
  mkdir -p "$REPO_ROOT/scripts" "$REPO_ROOT/config"

  # Template .env (não versionar segredos)
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

# Model Router
OPENCLAW_MODEL_CHEAP=gpt-4.1-mini
OPENCLAW_MODEL_STRONG=gpt-4.1
EOT
  fi

  # Cria .env local se não existir
  if [ ! -f "$REPO_ROOT/.env" ]; then
    cp "$REPO_ROOT/config/openclaw.env.example" "$REPO_ROOT/.env"
    say "Criado $REPO_ROOT/.env (preencha depois)"
  else
    say ".env já existe (não sobrescrevendo)"
  fi

  # Garante arquivos essenciais do brain (só checa)
  for f in README.md agent/auth.json agent/auth-profiles.json memory/decisions.md; do
    if [ ! -e "$REPO_ROOT/$f" ]; then
      warn "Arquivo esperado não encontrado: $f"
    fi
  done
}

prompt_secret() {
  local label="$1"
  local var
  read -r -s -p "$label: " var
  echo
  echo "$var"
}
prompt_text() {
  local label="$1"
  local def="${2:-}"
  local var
  if [ -n "$def" ]; then
    read -r -p "$label [$def]: " var
    echo "${var:-$def}"
  else
    read -r -p "$label: " var
    echo "$var"
  fi
}
set_env_kv() {
  local file="$1"
  local key="$2"
  local val="$3"
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
  echo "(Nada será exibido ao digitar as chaves)"
  echo

  local tz
  tz="$(prompt_text "TZ" "America/Sao_Paulo")"
  set_env_kv "$env_file" "TZ" "$tz"

  local openai
  openai="$(prompt_secret "OPENAI_API_KEY")"
  if [ -n "$openai" ]; then set_env_kv "$env_file" "OPENAI_API_KEY" "$openai"; fi

  local tgbot
  tgbot="$(prompt_secret "TELEGRAM_BOT_TOKEN")"
  if [ -n "$tgbot" ]; then set_env_kv "$env_file" "TELEGRAM_BOT_TOKEN" "$tgbot"; fi

  local chat
  chat="$(prompt_text "TELEGRAM_CHAT_ID (ex: -100...)" "")"
  if [ -n "$chat" ]; then set_env_kv "$env_file" "TELEGRAM_CHAT_ID" "$chat"; fi

  local cxurl
  cxurl="$(prompt_text "CONVEX_DEPLOYMENT_URL" "")"
  if [ -n "$cxurl" ]; then set_env_kv "$env_file" "CONVEX_DEPLOYMENT_URL" "$cxurl"; fi

  local cxkey
  cxkey="$(prompt_secret "CONVEX_DEPLOY_KEY")"
  if [ -n "$cxkey" ]; then set_env_kv "$env_file" "CONVEX_DEPLOY_KEY" "$cxkey"; fi

  local hb
  hb="$(prompt_text "HEARTBEAT_MINUTES" "45")"
  set_env_kv "$env_file" "HEARTBEAT_MINUTES" "$hb"

  local st
  st="$(prompt_text "STANDUP_TIME (HH:MM)" "11:30")"
  set_env_kv "$env_file" "STANDUP_TIME" "$st"

  echo
  echo "OK: .env atualizado."
}

install_deps() {
  say "Instalando dependências base (git, curl, python3, venv)"
  apt_install ca-certificates curl git python3 python3-venv python3-pip

  if [ "$INSTALL_NODE" = "1" ]; then
    say "Instalando node/npm (opcional)"
    apt_install nodejs npm
  fi
}

setup_python_if_any() {
  # Seu repo hoje não mostra requirements/pyproject.
  # Mantemos auto-detect: se existir no futuro, instala.
  if [ -f "$REPO_ROOT/requirements.txt" ]; then
    say "Criando venv e instalando requirements.txt"
    python3 -m venv "$REPO_ROOT/.venv"
    "$REPO_ROOT/.venv/bin/pip" install -U pip wheel setuptools
    "$REPO_ROOT/.venv/bin/pip" install -r "$REPO_ROOT/requirements.txt"
  elif [ -f "$REPO_ROOT/pyproject.toml" ]; then
    say "Criando venv e instalando pyproject (editable)"
    python3 -m venv "$REPO_ROOT/.venv"
    "$REPO_ROOT/.venv/bin/pip" install -U pip wheel setuptools
    "$REPO_ROOT/.venv/bin/pip" install -e "$REPO_ROOT"
  else
    warn "Sem requirements.txt/pyproject.toml — pulando instalação Python deps."
  fi
}

main() {
  say "Repo: $REPO_ROOT"
  install_deps
  maybe_set_timezone
  create_templates

  if [ "$INTERACTIVE" = "1" ]; then
    configure_env_interactive
  else
    warn "Para preencher chaves via prompt: INTERACTIVE=1 bash scripts/onboard_linux.sh"
  fi

  setup_python_if_any

  say "Concluído ✅"
  echo "Próximos passos:"
  echo "1) Preencha .env (ou rode INTERACTIVE=1)"
  echo "2) Se você tiver um comando de start do OpenClaw, documente em README.md"
}

main "$@"
