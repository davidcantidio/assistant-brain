#!/usr/bin/env bash
set -euo pipefail

# Onboarding do assistant-brain (Linux) - Nanobot + ClawWork
# - Instala dependencias base (apt, quando disponivel)
# - Instala Nanobot por source editable
# - Instala ClawWork + wrapper clawmode
# - Configura ~/.nanobot e bridge de estado com o repo

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

NANOBOT_MIN_VERSION="${NANOBOT_MIN_VERSION:-0.1.4}"
NANOBOT_REPO_URL="${NANOBOT_REPO_URL:-https://github.com/HKUDS/nanobot.git}"
CLAWWORK_REPO_URL="${CLAWWORK_REPO_URL:-https://github.com/HKUDS/ClawWork.git}"
SRC_BASE="${SRC_BASE:-$HOME/.local/src}"
NANOBOT_SRC_DIR="${NANOBOT_SRC_DIR:-$SRC_BASE/nanobot}"
CLAWWORK_SRC_DIR="${CLAWWORK_SRC_DIR:-$SRC_BASE/ClawWork}"
BOOTSTRAP_VENV="${BOOTSTRAP_VENV:-$SRC_BASE/.venv-nanobot}"

RUNTIME_HOME="${RUNTIME_HOME:-$HOME/.nanobot}"
RUNTIME_WORKSPACE="${RUNTIME_WORKSPACE:-$RUNTIME_HOME/workspace}"
REPO_STATE_FILE="$REPO_ROOT/workspaces/main/.nanobot/workspace-state.json"
RUNTIME_STATE_FILE="$RUNTIME_WORKSPACE/workspace-state.json"

INTERACTIVE="${INTERACTIVE:-0}"
SET_TZ="${SET_TZ:-0}"

say(){ echo -e "\n==> $*"; }
warn(){ echo -e "\n[WARN] $*" >&2; }
die(){ echo -e "\n[ERRO] $*" >&2; exit 1; }
need_cmd(){ command -v "$1" >/dev/null 2>&1; }

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

ensure_local_bin_on_path() {
  local line='export PATH="$HOME/.local/bin:$PATH"'
  mkdir -p "$HOME/.local/bin"

  if [ -f "$HOME/.bashrc" ] && ! grep -Fq "$line" "$HOME/.bashrc"; then
    printf '\n%s\n' "$line" >> "$HOME/.bashrc"
  fi
  if [ -f "$HOME/.zshrc" ] && ! grep -Fq "$line" "$HOME/.zshrc"; then
    printf '\n%s\n' "$line" >> "$HOME/.zshrc"
  fi

  export PATH="$HOME/.local/bin:$PATH"
}

apt_install() {
  need_cmd sudo || die "sudo nao encontrado."
  need_cmd apt-get || die "apt-get nao encontrado (script assume Debian/Ubuntu)."
  sudo apt-get update -y
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@"
}

install_base_deps() {
  if need_cmd apt-get; then
    say "Instalando dependencias base (git, python3, venv, pip, build-essential)"
    apt_install ca-certificates curl git python3 python3-venv python3-pip build-essential
  else
    warn "apt-get nao encontrado. Instale manualmente: git, python3.11+, python3-venv, pip"
  fi
}

maybe_set_timezone() {
  if [ "$SET_TZ" != "1" ]; then
    return
  fi
  if need_cmd timedatectl; then
    say "Ajustando timezone para America/Sao_Paulo"
    sudo timedatectl set-timezone America/Sao_Paulo || warn "Falha ao setar timezone"
  else
    warn "timedatectl nao encontrado; pulando timezone."
  fi
}

ensure_python311() {
  need_cmd python3 || die "python3 nao encontrado"
  local pyver major minor
  pyver="$(python3 -c 'import sys; print(f"{sys.version_info[0]}.{sys.version_info[1]}.{sys.version_info[2]}")')"
  major="${pyver%%.*}"
  minor="$(printf '%s' "$pyver" | cut -d. -f2)"
  if [ "$major" -lt 3 ] || { [ "$major" -eq 3 ] && [ "$minor" -lt 11 ]; }; then
    die "Python 3.11+ obrigatorio. Versao atual: $pyver"
  fi
  say "Python detectado: $pyver"
}

clone_or_update() {
  local url="$1"
  local dest="$2"
  if [ -d "$dest/.git" ]; then
    say "Atualizando repo em $dest"
    git -C "$dest" pull --ff-only || warn "Falha no pull de $dest; mantendo estado atual"
  else
    say "Clonando $url em $dest"
    mkdir -p "$(dirname "$dest")"
    git clone "$url" "$dest"
  fi
}

setup_python_stack() {
  say "Criando/atualizando venv bootstrap em $BOOTSTRAP_VENV"
  python3 -m venv "$BOOTSTRAP_VENV"
  "$BOOTSTRAP_VENV/bin/pip" install -U pip wheel setuptools

  say "Instalando Nanobot em modo source editable"
  "$BOOTSTRAP_VENV/bin/pip" install -e "$NANOBOT_SRC_DIR"

  if [ -f "$CLAWWORK_SRC_DIR/requirements.txt" ]; then
    say "Instalando dependencias do ClawWork"
    "$BOOTSTRAP_VENV/bin/pip" install -r "$CLAWWORK_SRC_DIR/requirements.txt"
  else
    warn "requirements.txt do ClawWork nao encontrado em $CLAWWORK_SRC_DIR"
  fi

  if [ -f "$CLAWWORK_SRC_DIR/clawmode_integration/requirements.txt" ]; then
    say "Instalando dependencias do clawmode_integration"
    "$BOOTSTRAP_VENV/bin/pip" install -r "$CLAWWORK_SRC_DIR/clawmode_integration/requirements.txt"
  fi
}

NANOBOT_CMD=""

resolve_nanobot_cmd() {
  if need_cmd nanobot; then
    NANOBOT_CMD="$(command -v nanobot)"
    return
  fi
  if [ -x "$HOME/.local/bin/nanobot" ]; then
    NANOBOT_CMD="$HOME/.local/bin/nanobot"
    return
  fi
  if [ -x "$BOOTSTRAP_VENV/bin/nanobot" ]; then
    NANOBOT_CMD="$BOOTSTRAP_VENV/bin/nanobot"
    return
  fi
  NANOBOT_CMD=""
}

ensure_nanobot_cmd() {
  ensure_local_bin_on_path

  if [ -x "$BOOTSTRAP_VENV/bin/nanobot" ]; then
    ln -sf "$BOOTSTRAP_VENV/bin/nanobot" "$HOME/.local/bin/nanobot"
  fi

  resolve_nanobot_cmd
  [ -n "$NANOBOT_CMD" ] || die "nanobot nao encontrado apos instalacao"

  local raw current
  raw="$($NANOBOT_CMD --version 2>/dev/null || true)"
  current="$(extract_version "$raw")"
  [ -n "$current" ] || die "Nao foi possivel identificar versao do nanobot: '$raw'"

  if ! version_ge "$current" "$NANOBOT_MIN_VERSION"; then
    die "nanobot $current < minimo exigido ($NANOBOT_MIN_VERSION)"
  fi

  say "nanobot: $NANOBOT_CMD"
  say "nanobot version: $raw"
}

ensure_nanobot_config() {
  mkdir -p "$RUNTIME_HOME"

  if [ ! -f "$RUNTIME_HOME/config.json" ]; then
    say "Executando nanobot onboard para gerar ~/.nanobot/config.json"
    if ! "$NANOBOT_CMD" onboard; then
      warn "nanobot onboard falhou; criando template minimo de config.json"
    fi
  fi

  if [ ! -f "$RUNTIME_HOME/config.json" ]; then
    cat > "$RUNTIME_HOME/config.json" <<EOT
{
  "providers": {
    "openrouter": {
      "base_url": "https://openrouter.ai/api/v1",
      "api_key_env": "OPENROUTER_API_KEY",
      "management_key_env": "OPENROUTER_MANAGEMENT_KEY"
    }
  },
  "agents": {
    "defaults": {
      "model": "openai/gpt-4.1-mini"
    },
    "clawwork": {
      "enabled": true
    }
  },
  "pricing": {
    "currency": "USD"
  },
  "runtime": {
    "repo_canonical_state": "$REPO_STATE_FILE"
  }
}
EOT
  fi
}

ensure_clawmode_skill() {
  local src_skill="$CLAWWORK_SRC_DIR/clawmode_integration/skill/SKILL.md"
  local dst_skill_dir="$RUNTIME_WORKSPACE/skills/clawmode"
  local dst_skill="$dst_skill_dir/SKILL.md"

  [ -f "$src_skill" ] || die "Skill nao encontrada: $src_skill"
  mkdir -p "$dst_skill_dir"
  cp "$src_skill" "$dst_skill"
  say "Skill clawmode instalada em $dst_skill"
}

ensure_pythonpath() {
  local line="export PYTHONPATH=\"$CLAWWORK_SRC_DIR:\${PYTHONPATH:-}\""
  if [ -f "$HOME/.bashrc" ] && ! grep -Fq "$CLAWWORK_SRC_DIR" "$HOME/.bashrc"; then
    printf '\n%s\n' "$line" >> "$HOME/.bashrc"
  fi
  if [ -f "$HOME/.zshrc" ] && ! grep -Fq "$CLAWWORK_SRC_DIR" "$HOME/.zshrc"; then
    printf '\n%s\n' "$line" >> "$HOME/.zshrc"
  fi
  export PYTHONPATH="$CLAWWORK_SRC_DIR:${PYTHONPATH:-}"
}

ensure_workspace_bridge() {
  mkdir -p "$(dirname "$REPO_STATE_FILE")"
  mkdir -p "$RUNTIME_WORKSPACE"

  if [ ! -f "$REPO_STATE_FILE" ]; then
    cat > "$REPO_STATE_FILE" <<'EOT'
{
  "version": 1,
  "bootstrapSeededAt": ""
}
EOT
  fi

  if [ -e "$RUNTIME_STATE_FILE" ] && [ ! -L "$RUNTIME_STATE_FILE" ]; then
    local backup
    backup="$RUNTIME_STATE_FILE.bak.$(date +%Y%m%d%H%M%S)"
    mv "$RUNTIME_STATE_FILE" "$backup"
    warn "Arquivo de estado local movido para backup: $backup"
  fi

  ln -sfn "$REPO_STATE_FILE" "$RUNTIME_STATE_FILE"
  say "Bridge de estado ativo: $RUNTIME_STATE_FILE -> $REPO_STATE_FILE"
}

create_templates() {
  mkdir -p "$REPO_ROOT/config"

  local template="$REPO_ROOT/config/nanobot_clawwork.env.example"
  if [ ! -f "$template" ]; then
    cat > "$template" <<'EOT'
# Nanobot + ClawWork Env (exemplo) - NAO COMMITAR valores reais
TZ=America/Sao_Paulo

# OpenRouter
OPENROUTER_API_KEY=
OPENROUTER_MANAGEMENT_KEY=

# Telegram
TELEGRAM_BOT_TOKEN=
TELEGRAM_CHAT_ID=

# Slack
SLACK_BOT_TOKEN=
SLACK_SIGNING_SECRET=
SLACK_ALERT_CHANNEL_ID=

# Convex
CONVEX_DEPLOYMENT_URL=
CONVEX_DEPLOY_KEY=

# Runtime
HEARTBEAT_MINUTES=20
STANDUP_TIME=11:30
NANOBOT_RUNTIME_HOME=~/.nanobot
NANOBOT_WORKSPACE_PATH=~/.nanobot/workspace
NANOBOT_DEFAULT_MODEL=openai/gpt-4.1-mini

# ClawWork / Wrapper
CLAWWORK_REPO_PATH=~/.local/src/ClawWork
CLAWMODE_PYTHONPATH=~/.local/src/ClawWork
EOT
  fi

  if [ ! -f "$REPO_ROOT/.env" ]; then
    cp "$template" "$REPO_ROOT/.env"
    say "Criado $REPO_ROOT/.env"
  fi

}

main() {
  say "Repo: $REPO_ROOT"
  install_base_deps
  maybe_set_timezone
  ensure_python311

  clone_or_update "$NANOBOT_REPO_URL" "$NANOBOT_SRC_DIR"
  clone_or_update "$CLAWWORK_REPO_URL" "$CLAWWORK_SRC_DIR"

  setup_python_stack
  ensure_nanobot_cmd
  ensure_nanobot_config
  ensure_clawmode_skill
  ensure_pythonpath
  ensure_workspace_bridge
  create_templates

  if [ "$INTERACTIVE" = "1" ]; then
    warn "Modo INTERACTIVE ainda nao preenche segredos automaticamente. Edite .env manualmente."
  fi

  say "Concluido"
  echo "Proximos passos:"
  echo "1) source ~/.bashrc (ou ~/.zshrc)"
  echo "2) preencha .env e ~/.nanobot/config.json"
  echo "3) rode: bash scripts/verify_linux.sh"
}

main "$@"
