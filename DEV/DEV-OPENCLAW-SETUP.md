---
doc_id: "DEV-OPENCLAW-SETUP.md"
version: "1.0"
status: "active"
owner: "Engineering"
last_updated: "2026-02-24"
rfc_refs: ["RFC-001", "RFC-010", "RFC-015", "RFC-050", "RFC-060"]
---

# Dev OpenClaw Setup

## Objetivo
Definir instalacao minima e verificavel de `OpenClaw` para Linux, com configuracao via `.env` local e estado canonico no repositorio.

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
- Linux (Debian/Ubuntu recomendado)
- `git`, `curl`, `python3`, `build-essential`
- `nvm` + Node `22.22.0`

## Instalacao
1. Executar onboarding:
```bash
bash scripts/onboard_linux.sh
```
2. Validar setup:
```bash
bash scripts/verify_linux.sh
```

## Contrato de Configuracao
- arquivo local:
  - `.env` (na raiz do repo)
- variaveis obrigatorias:
  - `OPENROUTER_API_KEY`
  - `OPENROUTER_MANAGEMENT_KEY` (somente para budget governor)
  - `TELEGRAM_BOT_TOKEN`
  - `TELEGRAM_CHAT_ID`
  - `SLACK_BOT_TOKEN`
  - `SLACK_SIGNING_SECRET`
  - `CONVEX_DEPLOYMENT_URL`
  - `CONVEX_DEPLOY_KEY`
- variaveis de runtime:
  - `HEARTBEAT_MINUTES=20`
  - `STANDUP_TIME=11:30`
  - `OPENCLAW_MODEL_CHEAP`
  - `OPENCLAW_MODEL_STRONG`

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

## Links Relacionados
- [PRD Master](../PRD/PRD-MASTER.md)
- [Roadmap](../PRD/ROADMAP.md)
- [Security Policy](../SEC/SEC-POLICY.md)
