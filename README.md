# assistant-brain (OpenClaw PRD Repo)

Repositorio de governanca e arquitetura do OpenClaw Agent OS.

## Status Atual
- fase atual: **document-first com baseline operacional local ativo**.
- estado do control-plane: **parcial** (convergencia F10 de runtime local concluida; control-plane completo ainda pendente).
- objetivo deste repo: manter contratos normativos e gates executaveis sem ambiguidade entre papel e runtime.

## Fonte Canonica
- fonte canonica normativa: `SEC/`, `PRD/` e `ARC/`
- hierarquia e precedencia: `META/DOCUMENT-HIERARCHY.md`
- higiene estrutural do repositorio: `META/REPO-HYGIENE.md`
- visao executiva do produto: `PRD/PRD-MASTER.md`
- fases e backlog de implementacao: `PRD/ROADMAP.md`
- fases usaveis com teste humano por etapa: `PRD/PHASE-USABILITY-GUIDE.md`
- historico normativo: `PRD/CHANGELOG.md`
- referencia conceitual para traceability: `felixcraft.md` e `felix-openclaw-pontos-relevantes.md`

## Estrutura
- `PRD/`: produto, fases e changelog
- `PM/`: decisoes, work order, sprint governance e planejamento por fase (`PM/PHASES/`)
- `ARC/`: arquitetura operacional e roteamento
- `SEC/`: seguranca, secrets, sandbox, allowlists
- `INTEGRATIONS/`: contratos normativos para integracoes externas (AI-Trader, ClawWork, OpenClaw upstream)
- `EVALS/`: gates de qualidade e saude
- `VERTICALS/`: PRDs por vertical (inclui Trading)
- `INCIDENTS/`: politicas e procedimentos de incidente
- `RAG/`: ingestao, isolamento e avaliacao de conhecimento
- `workspaces/main/`: workspace operacional canonico do MVP

## Regras Operacionais Essenciais
- baseline de heartbeat: **15 minutos** (`ARC/ARC-HEARTBEAT.md`).
- workspaces ativos no MVP: **somente** `workspaces/main`.
- gateway programatico de inferencia: **OpenClaw Gateway** (`bind=loopback`).
- OpenRouter e o adaptador cloud padrao (cloud-first), habilitado por default no runtime cloud e hibrido.
- automacoes com efeito colateral exigem contrato de idempotencia + rollback.
- aprovacao HITL critica exige allowlist de operador + challenge de segundo fator (Telegram primario, Slack fallback controlado).
- email nunca e canal de comando confiavel.
- side effect financeiro exige aprovacao humana explicita por ordem.
- claims centrais sem eval gate executavel bloqueiam release de fase.

## CI e Seguranca
- plataforma de CI definida: **GitHub Actions**.
- allowlists canonicas:
  - `SEC/allowlists/DOMAINS.yaml`
  - `SEC/allowlists/TOOLS.yaml`
  - `SEC/allowlists/ACTIONS.yaml`
  - `SEC/allowlists/OPERATORS.yaml`
  - `SEC/allowlists/PROVIDERS.yaml`

## Harness de Evals (local)
```bash
make eval-models
make eval-integrations
make eval-idempotency
make eval-rag
make eval-trading
make eval-gates
make ci-quality
make ci-security
make policy-test
make e2e-test
make chaos-test
make phase1-critical-suite
```

## Policy Engine (migracao gradual)
- base modular em `platform/policy-engine/` para substituir checks monoliticos em Bash.
- contratos versionados por dominio:
  - `platform/policy-engine/contracts/runtime.v1.yaml`
  - `platform/policy-engine/contracts/security.v1.yaml`
- wrappers legados continuam ativos e agora sao thin wrappers para a CLI canonica:
  - `policy-engine run --domain runtime --format json --output artifacts/generated/ci/policy-engine-runtime.json`
  - `policy-engine run --domain security --format json --output artifacts/generated/ci/policy-engine-security.json`
  - `policy-engine validate --consistency --output artifacts/generated/ci/policy-engine-convergence.json`
- contratos de saida:
  - `ARC/schemas/policy_run_result.schema.json`
  - `ARC/schemas/rule_violation.schema.json`

## Onboarding Local
```bash
bash scripts/onboard_linux.sh
bash scripts/verify_linux.sh
```

Notas:
- os scripts acima sao o contrato oficial de onboarding para Linux e macOS (detecao automatica no `onboard_linux.sh`).
- `scripts/verify_linux.sh` e gate bloqueante e retorna `exit code != 0` quando faltar requisito obrigatorio, valor vazio ou placeholder em chave obrigatoria.
- template canonico de configuracao: `config/openclaw.env.example` (espelho em `.env_example`).
- o onboarding agora executa bootstrap automatico de config local quando `~/.openclaw/openclaw.json` estiver ausente.
- o onboarding interativo suporta:
  - auto-geracao de `LITELLM_API_KEY` via LiteLLM `/key/generate`;
  - `OPENROUTER_API_KEY` obrigatoria em `cloud|hybrid`;
  - preload de Telegram por JSON (`TELEGRAM_UPDATE_JSON` ou `TELEGRAM_UPDATE_JSON_FILE`).

### Perfis de runtime (`OPENCLAW_RUNTIME_MODE`)
- `local-only`: foco local-first; `LITELLM_API_KEY`, `LITELLM_MASTER_KEY` e `OPENROUTER_API_KEY` deixam de ser obrigatorios no `verify`.
- `hybrid`: cloud-first com fallback local 7B; `LITELLM_*` + `OPENROUTER_API_KEY` obrigatorios.
- `cloud` (default): cloud-first estrito; `LITELLM_*` + `OPENROUTER_API_KEY` obrigatorios.
- em `local-only`, onboarding define `LITELLM_AUTO_GENERATE_KEY=false` e sugere supervisors locais:
  - `OPENCLAW_SUPERVISOR_PRIMARY=local-main`
  - `OPENCLAW_SUPERVISOR_SECONDARY=local-review`

## Inicializacao do OpenClaw (foreground)
Setup local one-time (quando necessario):
```bash
openclaw setup --mode local --non-interactive
```

Comando canonico de inicializacao:
```bash
openclaw gateway run --bind loopback --port 18789 --force
```

Pre-start recomendado (instancia unica para Telegram polling):
```bash
bash scripts/check_telegram_conflict.sh
```
O precheck agora tambem valida lockfiles de sessao (`*.jsonl.lock`) e falha quando encontrar lock stale (PID morto).

Sequencia operacional recomendada:
1. validar conflito local com `bash scripts/check_telegram_conflict.sh`;
2. se houver duplicidade, encerrar instancias extras (`pkill -f openclaw-gateway`);
3. iniciar gateway unico com `openclaw gateway run --bind loopback --port 18789 --force`;
4. observar logs iniciais por ~30-60s e confirmar ausencia de `getUpdates conflict`/`409`.

Observacao: o bot Telegram em modo polling nao suporta multiplos consumidores simultaneos para o mesmo `TELEGRAM_BOT_TOKEN`.

Troubleshooting rapido:
- erro `Missing config`: execute `openclaw setup --mode local --non-interactive`;
- se `openclaw setup` exigir risk acknowledgement, use: `openclaw onboard --mode local --non-interactive --accept-risk --auth-choice skip --skip-channels --skip-skills --skip-daemon --skip-health --skip-ui`;
- erro `invalid_auth`: revise os tokens reais no `.env` (nao use placeholders do template).
- erro `getUpdates 409 Conflict`:
  - sintoma: repeticao de `terminated by other getUpdates request`;
  - causa provavel: outro poller usando o mesmo token (sessao local duplicada ou host remoto);
  - acao local: `bash scripts/check_telegram_conflict.sh`, encerrar duplicados e subir apenas uma instancia;
  - acao remota: verificar servidor/container/daemon que esteja com o mesmo `TELEGRAM_BOT_TOKEN` e desligar a instancia concorrente;
  - verificacao final: logs estaveis sem novas linhas `getUpdates conflict` por pelo menos 2 ciclos de retry.

### Telegram com dois checks e sem resposta
Sintoma comum:
- mensagem no Telegram fica com dois checks, mas o bot nao responde.

Causas frequentes neste runtime local:
- lock de sessao (`session file locked`) por uso simultaneo de Dashboard/Webchat e Telegram na mesma sessao logica;
- latencia/timeout do modelo local 30B sem fallback leve.

Runbook recomendado (perfil `default`):
1. garantir processo unico e lockfiles saudaveis:
   - `bash scripts/check_telegram_conflict.sh`
2. isolar sessoes por canal:
   - `openclaw config set session.dmScope per-channel-peer`
3. reduzir contencao do agente:
   - `openclaw config set agents.defaults.maxConcurrent 1 --json`
4. ajustar timeout e janela de contexto:
   - `openclaw config set agents.defaults.timeoutSeconds 900 --json`
   - `openclaw config set agents.defaults.contextTokens 32768 --json`
5. manter 30B como primario e fallback leve local:
   - `openclaw config set agents.defaults.model.primary ollama/qwen3:30b-a3b-instruct-2507-q8_0`
   - `openclaw config set agents.defaults.model.fallbacks '["ollama/qwen2.5:7b-instruct-q8_0"]' --json`
6. garantir fallback instalado:
   - `ollama pull qwen2.5:7b-instruct-q8_0`
7. reiniciar gateway e validar:
   - `openclaw gateway run --bind loopback --port 18789 --force`
   - `openclaw channels status`

Validacao de sucesso:
- Telegram `enabled, configured, running`;
- ausencia de erros `No API key found for provider "openrouter"` e `session file locked`;
- resposta funcional no Telegram apos envio de mensagem de teste.

### Onboarding interativo com LiteLLM auto-key (`hybrid|cloud`)
```bash
INTERACTIVE=1 bash scripts/onboard_linux.sh
```

No fluxo interativo:
- `LITELLM_PROXY_URL` e derivado de `LITELLM_BASE_URL` sem `/v1` (com override manual);
- `LITELLM_MODELS` default: `openrouter-main,openrouter-review,local-fallback-7b`;
- `OPENROUTER_API_KEY` e obrigatoria em `cloud|hybrid`;
- se auto-geracao falhar, o script cai em fallback manual obrigatorio para `LITELLM_API_KEY` (nao permite lacuna).
- `scripts/verify_linux.sh` bloqueia `cloud|hybrid` quando `OPENROUTER_API_KEY` estiver vazia/ausente.

### Matriz de modelo por tarefa (selecao explicita)
- `chat/triage/day-to-day`: `openrouter-main`
- `review/risk/checkpoint`: `openrouter-review`
- `contingencia cloud down`: `local-fallback-7b` (`ollama/qwen2.5:7b-instruct-q8_0`)
- override:
  - a selecao pode ser sobrescrita por tarefa no prompt/comando operacional;
  - toda troca de modelo por tarefa deve registrar `requested_model`, `effective_model`, `fallback_step` e `reason`.

### Preload de Telegram por payload JSON
Exemplo via arquivo:
```bash
TELEGRAM_UPDATE_JSON_FILE=/caminho/update.json INTERACTIVE=1 bash scripts/onboard_linux.sh
```

Exemplo via inline:
```bash
TELEGRAM_UPDATE_JSON='{\"message\":{\"from\":{\"id\":7165399698},\"chat\":{\"id\":7165399698,\"type\":\"private\"}}}' INTERACTIVE=1 bash scripts/onboard_linux.sh
```

Contrato operacional do preload:
- parser usa `message.from.id`, `message.chat.id` e `message.chat.type` como fonte de defaults;
- prompts recebem prefill de `TELEGRAM_CHAT_ID` e `TELEGRAM_USER_ID`;
- payload ausente/invalido nao interrompe onboarding e mantem entrada manual.

### Slack app manifesto (Socket Mode)
Manifesto versionado:
- `config/slack-app-manifest.socket-mode.yaml`

Passos:
1. criar app em [api.slack.com/apps](https://api.slack.com/apps) via "From an app manifest";
2. colar o manifesto `config/slack-app-manifest.socket-mode.yaml`;
3. instalar app no workspace;
4. copiar `SLACK_BOT_TOKEN`, `SLACK_APP_TOKEN`, `SLACK_SIGNING_SECRET` para `.env`;
5. manter os placeholders de URL do manifesto apenas como bootstrap ate definir endpoint final.

Contrato do manifesto:
- `socket_mode_enabled=true`;
- comandos provisionados: `/oc-approve`, `/oc-reject`, `/oc-kill`;
- placeholders explicitos de URL (`.../commands`, `.../events`, `.../interactivity`) preservados para compatibilidade de schema.

Guia operacional detalhado:
- `DEV/DEV-OPENCLAW-SETUP.md`
- fechamento documental do epico: `PM/PHASES/F9-ONBOARDING-CREDENCIAIS-E-CANAIS-AUTOMATIZADOS/EPIC-F9-02-BOOTSTRAP-TELEGRAM-E-SLACK-SOCKET-MANIFEST.md`
- artifacts da rodada F9-02:
  - `artifacts/phase-f9/epic-f9-02-issue-01-telegram-json-preload.md`
  - `artifacts/phase-f9/epic-f9-02-issue-02-slack-socket-manifest.md`
  - `artifacts/phase-f9/epic-f9-02-issue-03-doc-sync-onboarding-canais.md`
  - `artifacts/phase-f9/epic-f9-02-telegram-slack-bootstrap.md`

## Docling PDF -> MD
Tooling Python opcional e isolado para conversao de PDF em Markdown.

```bash
make docling-install
make pdf-to-md PDF=felixcraft.pdf MD=felixcraft.md
```

Notas operacionais:
- `.venv-docling` e um ambiente local isolado de tooling; nao faz parte do runtime principal do OpenClaw.
- runtime principal continua Node/OpenClaw (onboarding via `scripts/onboard_linux.sh`).
- policy de CI/local: se `felixcraft.pdf` mudar, `felixcraft.md` deve ser commitado junto.
- validacao local da policy:
```bash
make check-pdf-md-sync
```

## Contribuicao em Documentacao
- atualize `version` e `last_updated` no header do arquivo alterado.
- se houver impacto normativo, registre em `PRD/CHANGELOG.md`.
- em conflito entre docs, aplique `META/DOCUMENT-HIERARCHY.md`.

## Nao Versionar
- `.env`, secrets, chaves e tokens
- estado em `~/.openclaw*`
- outputs gerados em `artifacts/generated/`
- snapshots temporarios de runtime (`runtime-inventory`, `runtime-merge-plan`, `runtime-convergence-report`)
- logs/sessoes brutos com payload sensivel
