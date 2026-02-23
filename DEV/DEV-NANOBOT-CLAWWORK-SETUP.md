---
doc_id: "DEV-NANOBOT-CLAWWORK-SETUP.md"
version: "1.0"
status: "active"
owner: "Engineering"
last_updated: "2026-02-23"
rfc_refs: ["RFC-001", "RFC-010", "RFC-015", "RFC-050", "RFC-060"]
---

# Dev Nanobot + ClawWork Setup

## Objetivo
Definir instalacao minima e verificavel de `Nanobot + ClawWork` para Linux e macOS, com runtime local em `~/.nanobot` e estado canonico no repositorio.

## Escopo
Inclui:
- bootstrap por source editable de Nanobot
- instalacao do ClawWork com wrapper oficial `clawmode_integration`
- configuracao minima de runtime/config/skill/PYTHONPATH
- smoke tests tecnicos e bridge com estado canonico do repo

Exclui:
- deploy de producao
- customizacoes proprietarias da estrategia
- bypass de gates de risco/compliance

## Regras Normativas
- [RFC-015] MUST manter segredos fora de git e fora de logs.
- [RFC-050] MUST manter trilha de estado canonico no repo.
- [RFC-010] MUST preservar gates de risco para side effects.
- [RFC-060] MUST manter `execution_gateway` como unico caminho de ordem em Trading.

## 1) Pre-requisitos
- Python `3.11+`
- `git`
- `pip` e `venv`

Linux (Debian/Ubuntu):
```bash
sudo apt-get update
sudo apt-get install -y git python3 python3-venv python3-pip build-essential
python3 --version
```

macOS (Homebrew):
```bash
brew update
brew install git python@3.11
python3 --version
```

## 2) Instalar Nanobot (source editable)
```bash
mkdir -p ~/.local/src
git clone https://github.com/HKUDS/nanobot.git ~/.local/src/nanobot
python3 -m venv ~/.local/src/.venv-nanobot
~/.local/src/.venv-nanobot/bin/pip install -U pip wheel setuptools
~/.local/src/.venv-nanobot/bin/pip install -e ~/.local/src/nanobot
```

Adicionar binario ao PATH (bash/zsh):
```bash
mkdir -p ~/.local/bin
ln -sf ~/.local/src/.venv-nanobot/bin/nanobot ~/.local/bin/nanobot
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
```

Validar versao minima:
```bash
nanobot --version
```
Requisito: `>= 0.1.4`.

## 3) Instalar ClawWork
```bash
git clone https://github.com/HKUDS/ClawWork.git ~/.local/src/ClawWork
~/.local/src/.venv-nanobot/bin/pip install -r ~/.local/src/ClawWork/requirements.txt
```

Se existir requirements especifico da integracao:
```bash
if [ -f ~/.local/src/ClawWork/clawmode_integration/requirements.txt ]; then
  ~/.local/src/.venv-nanobot/bin/pip install -r ~/.local/src/ClawWork/clawmode_integration/requirements.txt
fi
```

## 4) Inicializar Nanobot
```bash
nanobot onboard
```

Validar criacao de config:
```bash
test -f ~/.nanobot/config.json && echo "OK: ~/.nanobot/config.json"
```

## 5) Configurar `~/.nanobot/config.json` (baseline)
Bloco minimo recomendado:
```json
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
  }
}
```

## 6) Instalar skill ClawMode
```bash
mkdir -p ~/.nanobot/workspace/skills/clawmode
cp ~/.local/src/ClawWork/clawmode_integration/skill/SKILL.md \
  ~/.nanobot/workspace/skills/clawmode/SKILL.md
```

## 7) Configurar `PYTHONPATH` para clawmode
```bash
echo 'export PYTHONPATH="$HOME/.local/src/ClawWork:${PYTHONPATH:-}"' >> ~/.bashrc
echo 'export PYTHONPATH="$HOME/.local/src/ClawWork:${PYTHONPATH:-}"' >> ~/.zshrc
```

Aplicar no shell atual:
```bash
export PYTHONPATH="$HOME/.local/src/ClawWork:${PYTHONPATH:-}"
```

## 8) Smoke tests
Sem side effect:
```bash
nanobot --help
python -m clawmode_integration.cli --help
```

Comandos operacionais minimos:
```bash
nanobot agent -m "hello"
python -m clawmode_integration.cli agent -m "/clawwork status"
python -m clawmode_integration.cli gateway
```

## 9) Canais (Telegram/Slack) minimo funcional
Variaveis minimas no `.env` local:
```bash
OPENROUTER_API_KEY=
OPENROUTER_MANAGEMENT_KEY=
TELEGRAM_BOT_TOKEN=
TELEGRAM_CHAT_ID=
SLACK_BOT_TOKEN=
SLACK_SIGNING_SECRET=
```

Regras:
- Telegram permanece primario para HITL critico.
- Slack pode atuar como colaboracao diaria e fallback controlado.
- fallback HITL por Slack exige assinatura valida + anti-replay + challenge + operador em allowlist.

## 10) Bridge com estado canonico do repo
Fonte canonica de estado no repo:
- `workspaces/main/.nanobot/workspace-state.json`

Criar bridge no runtime local:
```bash
mkdir -p ~/.nanobot/workspace
ln -sfn \
  /path/do/repo/workspaces/main/.nanobot/workspace-state.json \
  ~/.nanobot/workspace/workspace-state.json
```

Regra operacional:
- repo e fonte de verdade documental + estado canonico.
- `~/.nanobot` e runtime local sincronizado; divergencia abre incidente de reconciliacao.

## Links Relacionados
- [PRD Master](../PRD/PRD-MASTER.md)
- [Roadmap](../PRD/ROADMAP.md)
- [Security Policy](../SEC/SEC-POLICY.md)
- [Secrets](../SEC/SEC-SECRETS.md)
