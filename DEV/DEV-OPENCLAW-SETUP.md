---
doc_id: "DEV-OPENCLAW-SETUP.md"
version: "1.4"
status: "active"
owner: "Engineering"
last_updated: "2026-02-24"
rfc_refs: ["RFC-001", "RFC-010", "RFC-015", "RFC-050", "RFC-060"]
---

# Dev OpenClaw Setup

## Objetivo
Definir instalacao minima e verificavel de `OpenClaw` para Linux/macOS, com gateway runtime local (`loopback`) e estado canonico no repositorio.

## Escopo
Inclui:
- instalacao de runtime OpenClaw via npm global
- preparacao de `.env` padrao
- verificacao de versao e comandos basicos
- ponte de estado para `workspaces/main/.openclaw/workspace-state.json`

Exclui:
- deploy de producao
- bypass de gates de risco/compliance

## Pre-requisitos
- Linux (Debian/Ubuntu recomendado) **ou** macOS (Darwin + Homebrew)
- `git`, `curl`, `python3`
- Linux: `build-essential`
- macOS: Xcode Command Line Tools (`xcode-select --install`)
- `nvm` + Node `22.22.0`

## Instalacao
1. Executar onboarding:
```bash
bash scripts/onboard_linux.sh
```
> O script detecta automaticamente Linux/macOS e aplica o fluxo da plataforma.

2. Validar setup:
```bash
bash scripts/verify_linux.sh
```
> `verify_linux.sh` e gate bloqueante: retorna `exit code != 0` com requisito faltante.

## Contrato de Configuracao
- arquivo local:
  - `.env` (na raiz do repo)
  - template canonico: `config/openclaw.env.example` (espelho em `.env_example`)
- variaveis obrigatorias:
  - `LITELLM_API_KEY`
  - `LITELLM_MASTER_KEY` (somente para budget governor/administracao)
  - `CODEX_OAUTH_ACCESS_TOKEN` (alias `codex-main`)
  - `ANTHROPIC_API_KEY` (alias `claude-review`)
  - `TELEGRAM_BOT_TOKEN`
  - `TELEGRAM_CHAT_ID` (canonico; aliases aceitos: `TELEGRAM_USER_ID`, `TELEGRAM_GROUP_ID`)
  - `SLACK_BOT_TOKEN`
  - `SLACK_SIGNING_SECRET`
  - `CONVEX_DEPLOYMENT_URL`
  - `CONVEX_DEPLOY_KEY`
- variaveis de runtime:
  - `HEARTBEAT_MINUTES=15`
  - `STANDUP_TIME=11:30`
  - `OPENCLAW_GATEWAY_URL` (default: `http://127.0.0.1:18789/v1`)
  - `LITELLM_BASE_URL` (default: `http://127.0.0.1:4000/v1`)
  - `OPENCLAW_SUPERVISOR_PRIMARY=codex-main`
  - `OPENCLAW_SUPERVISOR_SECONDARY=claude-review`
  - `OPENCLAW_WORKER_CODE_MODEL=ollama/qwen2.5-coder:32b`
  - `OPENCLAW_WORKER_REASON_MODEL=ollama/deepseek-r1:32b`
  - `OPENROUTER_API_KEY` (opcional; fallback cloud desabilitado por default)

## Estado Canonico
- arquivo de estado do workspace:
  - `workspaces/main/.openclaw/workspace-state.json`
- regra:
  - esse arquivo e a referencia canonica no repo para estado operacional minimo.

## Smoke Checks
```bash
openclaw --version
make ci-quality
make ci-security
make eval-gates
```

## Opcional: Tooling Docling (isolado)
O pipeline PDF -> MD usa um ambiente Python dedicado e nao acopla o runtime principal do OpenClaw.

### Instalacao do tooling local
```bash
make docling-install
```

### Conversao PDF -> Markdown
```bash
make pdf-to-md PDF=felixcraft.pdf MD=felixcraft.md
```

### Policy local/CI de sincronia
Regra: se `felixcraft.pdf` mudar, `felixcraft.md` tambem deve mudar no mesmo commit/PR.

Verificacao local:
```bash
make check-pdf-md-sync
```

## Links Relacionados
- [PRD Master](../PRD/PRD-MASTER.md)
- [Roadmap](../PRD/ROADMAP.md)
- [Security Policy](../SEC/SEC-POLICY.md)
