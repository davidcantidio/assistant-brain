---
doc_id: "DEV-OPENCLAW-SETUP.md"
version: "1.11"
status: "active"
owner: "Engineering"
last_updated: "2026-03-02"
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

Fluxo interativo (recomendado para primeira instalacao):
```bash
INTERACTIVE=1 bash scripts/onboard_linux.sh
```

Com preload de Telegram por arquivo:
```bash
TELEGRAM_UPDATE_JSON_FILE=/caminho/update.json INTERACTIVE=1 bash scripts/onboard_linux.sh
```

Com preload de Telegram inline:
```bash
TELEGRAM_UPDATE_JSON='{"message":{"from":{"id":7165399698},"chat":{"id":7165399698,"type":"private"}}}' INTERACTIVE=1 bash scripts/onboard_linux.sh
```

2. Bootstrap local de config OpenClaw (one-time, quando necessario):
```bash
openclaw setup --mode local --non-interactive
```
> O onboarding tenta executar esse bootstrap automaticamente quando `~/.openclaw/openclaw.json` nao existe.

3. Validar setup:
```bash
bash scripts/verify_linux.sh
```
> `verify_linux.sh` e gate bloqueante: retorna `exit code != 0` com requisito faltante, valor vazio ou placeholder em chave obrigatoria.

4. Inicializar gateway (foreground):
```bash
openclaw gateway run --bind loopback --port 18789 --force
```

Troubleshooting rapido:
- erro `Missing config`: rode `openclaw setup --mode local --non-interactive`;
- se `openclaw setup` exigir risk acknowledgement, use: `openclaw onboard --mode local --non-interactive --accept-risk --auth-choice skip --skip-channels --skip-skills --skip-daemon --skip-health --skip-ui`;
- erro `invalid_auth`: revise os tokens reais no `.env` (nao use placeholders do template).

## Contrato de Configuracao
- arquivo local:
  - `.env` (na raiz do repo)
  - template canonico: `config/openclaw.env.example` (espelho em `.env_example`)
- seletor de modo:
  - `OPENCLAW_RUNTIME_MODE=local-only|hybrid|cloud`
  - default: `cloud` (cloud-first)
- variaveis obrigatorias:
  - `TELEGRAM_BOT_TOKEN`
  - `TELEGRAM_CHAT_ID` (canonico; aliases aceitos: `TELEGRAM_USER_ID`, `TELEGRAM_GROUP_ID`)
  - `SLACK_BOT_TOKEN`
  - `SLACK_SIGNING_SECRET`
  - `CONVEX_DEPLOYMENT_URL`
  - `CONVEX_DEPLOY_KEY`
- obrigatorias adicionais em `hybrid|cloud`:
  - `LITELLM_API_KEY`
  - `LITELLM_MASTER_KEY` (somente para budget governor/administracao)
  - `OPENROUTER_API_KEY`
- variaveis de onboarding (novas):
  - `LITELLM_AUTO_GENERATE_KEY=true|false`
  - `LITELLM_PROXY_URL` (default derivado de `LITELLM_BASE_URL` sem `/v1`)
  - `LITELLM_MODELS` (escopo da virtual key)
  - `TELEGRAM_UPDATE_JSON` (payload inline)
  - `TELEGRAM_UPDATE_JSON_FILE` (payload em arquivo)
- variaveis de runtime:
  - `HEARTBEAT_MINUTES=15`
  - `STANDUP_TIME=11:30`
  - `OPENCLAW_GATEWAY_URL` (default: `http://127.0.0.1:18789/v1`)
  - `LITELLM_BASE_URL` (default: `http://127.0.0.1:4000/v1`)
  - `OPENCLAW_SUPERVISOR_PRIMARY=openrouter-main`
  - `OPENCLAW_SUPERVISOR_SECONDARY=openrouter-review`
  - `OPENCLAW_WORKER_CODE_MODEL=ollama/qwen2.5:7b-instruct-q8_0`
  - `OPENCLAW_WORKER_REASON_MODEL=ollama/qwen2.5:7b-instruct-q8_0`
  - `OPENROUTER_API_KEY` (obrigatorio em `cloud|hybrid`)

## LiteLLM Auto-Key no Onboarding
- em `local-only`, `LITELLM_AUTO_GENERATE_KEY` fica `false` por default e LiteLLM passa a nao ser requisito obrigatorio.
- quando `LITELLM_AUTO_GENERATE_KEY=true`, onboarding tenta gerar `LITELLM_API_KEY` via `/key/generate`.
- pre-requisitos para auto-geracao:
  - `LITELLM_MASTER_KEY` valido;
  - `LITELLM_BASE_URL` configurado;
  - `LITELLM_MODELS` definido (default: `openrouter-main,openrouter-review,local-fallback-7b`).
- fallback:
  - se `/key/generate` falhar, onboarding exige `LITELLM_API_KEY` manual para concluir o fluxo interativo.
  - `scripts/verify_linux.sh` valida `LITELLM_API_KEY` com valor nao vazio.

## OpenRouter Obrigatorio (cloud-first)
- `OPENROUTER_API_KEY` e obrigatoria em `cloud|hybrid`.
- onboarding exige `OPENROUTER_API_KEY` explicitamente nesses modos.
- `scripts/verify_linux.sh` bloqueia setup em `cloud|hybrid` quando `OPENROUTER_API_KEY` estiver vazia ou ausente.

## Matriz de modelo por tarefa (selecao explicita)
- `chat/triage/day-to-day`: `openrouter-main`
- `review/risk/checkpoint`: `openrouter-review`
- `contingencia cloud down`: `local-fallback-7b` (`ollama/qwen2.5:7b-instruct-q8_0`)
- regra de override:
  - cada task pode sobrescrever o modelo explicitamente;
  - o runtime deve manter trilha `requested_model`, `effective_model`, `fallback_step` e `reason`.

## Slack Manifest (Socket Mode)
- manifesto versionado: `config/slack-app-manifest.socket-mode.yaml`.
- comandos provisionados no manifesto:
  - `/oc-approve`
  - `/oc-reject`
  - `/oc-kill`
- contrato de schema no bootstrap:
  - `socket_mode_enabled=true`;
  - placeholders de URL explicitos em `.../commands`, `.../events` e `.../interactivity`.
- apos criar/instalar o app no Slack:
  - preencher `SLACK_BOT_TOKEN`, `SLACK_APP_TOKEN`, `SLACK_SIGNING_SECRET` em `.env`.

## Evidencias F9-02
- epic: `PM/PHASES/F9-ONBOARDING-CREDENCIAIS-E-CANAIS-AUTOMATIZADOS/EPIC-F9-02-BOOTSTRAP-TELEGRAM-E-SLACK-SOCKET-MANIFEST.md`
- issue artifacts:
  - `artifacts/phase-f9/epic-f9-02-issue-01-telegram-json-preload.md`
  - `artifacts/phase-f9/epic-f9-02-issue-02-slack-socket-manifest.md`
  - `artifacts/phase-f9/epic-f9-02-issue-03-doc-sync-onboarding-canais.md`
- artifact minimo do epico:
  - `artifacts/phase-f9/epic-f9-02-telegram-slack-bootstrap.md`

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
- [Repo Hygiene](../META/REPO-HYGIENE.md)
