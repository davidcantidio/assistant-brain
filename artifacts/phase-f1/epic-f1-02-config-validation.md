# EPIC-F1-02 Config Validation

- data/hora: 2026-02-24 19:07:18 -0300
- host alvo: Darwin arm64
- escopo: EPIC-F1-02 (contrato de configuracao local)
- fonte de verdade: PRD (`PRD-MASTER`, `ROADMAP`, `PHASE-USABILITY-GUIDE`) + `DEV-OPENCLAW-SETUP`

## Preflight do Epico

1. `bash scripts/onboard_linux.sh` -> PASS
- OpenClaw instalado: `openclaw 2026.2.14`
- `.env` criado automaticamente a partir de `config/openclaw.env.example`

2. `bash scripts/verify_linux.sh` -> PASS (`exit 0`)

3. `make eval-models` -> PASS

## ISSUE-F1-02-01 - Variaveis obrigatorias

### Red
- acao: remover temporariamente `CONVEX_DEPLOY_KEY` do `.env`
- comando: `bash scripts/verify_linux.sh`
- resultado: FAIL (`exit 1`)
- evidencia: `[FAIL] .env sem chave obrigatoria: CONVEX_DEPLOY_KEY`

### Green
- acao: restaurar `.env` a partir de backup local
- comando: `bash scripts/verify_linux.sh`
- resultado: PASS (`exit 0`)

### Refactor
- comando: `bash scripts/verify_linux.sh`
- resultado: PASS (`exit 0`)

## ISSUE-F1-02-02 - Defaults operacionais

### Red
- acao: alterar defaults criticos no `.env`
  - `HEARTBEAT_MINUTES=10`
  - `OPENCLAW_GATEWAY_URL=http://127.0.0.1:9999/v1`
  - `OPENCLAW_SUPERVISOR_PRIMARY=codex-other`
- comando: `bash scripts/verify_linux.sh`
- resultado: FAIL (`exit 1`)
- evidencia:
  - `[FAIL] HEARTBEAT_MINUTES=10 (esperado: 15).`
  - `[FAIL] OPENCLAW_GATEWAY_URL=http://127.0.0.1:9999/v1 (esperado: http://127.0.0.1:18789/v1).`
  - `[FAIL] OPENCLAW_SUPERVISOR_PRIMARY=codex-other (esperado: codex-main).`

### Green
- acao: restaurar `.env` a partir de backup local
- comando: `bash scripts/verify_linux.sh`
- resultado: PASS (`exit 0`)

### Refactor
- comando: `make eval-models`
- resultado: PASS

## ISSUE-F1-02-03 - Cloud opcional desabilitado por default

### Red
- acao: mutacao minima em `README.md` para linguagem proibida de cloud default
- comando: `make eval-models`
- resultado: FAIL
- evidencia: `Padrao proibido encontrado: OpenRouter e o adaptador padrao recomendado`

### Green
- acao: restaurar `README.md` exatamente a partir de backup local
- comando: `make eval-models`
- resultado: PASS

### Refactor
- comando: `make eval-models`
- resultado: PASS

## Status final do epico

- `bash scripts/verify_linux.sh`: PASS (`exit 0`)
- `make eval-models`: PASS
- conclusao: EPIC-F1-02 apto no escopo documental/tdd desta rodada
