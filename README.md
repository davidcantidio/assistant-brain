# assistant-brain (OpenClaw PRD Repo)

Repositorio de governanca e arquitetura do OpenClaw Agent OS.

## Status Atual
- fase atual: **PRD / arquitetura de papel** (sem control-plane implementado ainda).
- objetivo deste repo: fechar requisitos, contratos e gates antes da execucao.
- regra: MVP documental pode estar completo mesmo sem MVP operacional.

## Fonte Canonica
- fonte canonica normativa: `SEC/`, `PRD/` e `ARC/`
- hierarquia e precedencia: `META/DOCUMENT-HIERARCHY.md`
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
- OpenRouter e adaptador cloud opcional, permanece desabilitado por default e so pode ser habilitado por decision formal; quando cloud adicional estiver habilitado, OpenRouter e o preferido.
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
```

## Onboarding Local
```bash
bash scripts/onboard_linux.sh
bash scripts/verify_linux.sh
```

Notas:
- os scripts acima sao o contrato oficial de onboarding para Linux e macOS (detecao automatica no `onboard_linux.sh`).
- `scripts/verify_linux.sh` e gate bloqueante e retorna `exit code != 0` quando faltar requisito obrigatorio.
- template canonico de configuracao: `config/openclaw.env.example` (espelho em `.env_example`).
- o onboarding interativo suporta:
  - auto-geracao de `LITELLM_API_KEY` via LiteLLM `/key/generate`;
  - `OPENROUTER_API_KEY` opcional no mesmo fluxo;
  - preload de Telegram por JSON (`TELEGRAM_UPDATE_JSON` ou `TELEGRAM_UPDATE_JSON_FILE`).

### Onboarding interativo com LiteLLM auto-key
```bash
INTERACTIVE=1 bash scripts/onboard_linux.sh
```

No fluxo interativo:
- `LITELLM_PROXY_URL` e derivado de `LITELLM_BASE_URL` sem `/v1` (com override manual);
- `LITELLM_MODELS` default: `codex-main,claude-review`;
- se `OPENROUTER_API_KEY` estiver preenchida, o default inclui `openrouter/openai/gpt-4o-mini`;
- se auto-geracao falhar, o script cai em fallback manual para `LITELLM_API_KEY`.

### Preload de Telegram por payload JSON
Exemplo via arquivo:
```bash
TELEGRAM_UPDATE_JSON_FILE=/caminho/update.json INTERACTIVE=1 bash scripts/onboard_linux.sh
```

Exemplo via inline:
```bash
TELEGRAM_UPDATE_JSON='{\"message\":{\"from\":{\"id\":7165399698},\"chat\":{\"id\":7165399698,\"type\":\"private\"}}}' INTERACTIVE=1 bash scripts/onboard_linux.sh
```

### Slack app manifesto (Socket Mode)
Manifesto versionado:
- `config/slack-app-manifest.socket-mode.yaml`

Passos:
1. criar app em [api.slack.com/apps](https://api.slack.com/apps) via "From an app manifest";
2. colar o manifesto `config/slack-app-manifest.socket-mode.yaml`;
3. instalar app no workspace;
4. copiar `SLACK_BOT_TOKEN`, `SLACK_APP_TOKEN`, `SLACK_SIGNING_SECRET` para `.env`;
5. manter os placeholders de URL do manifesto apenas como bootstrap ate definir endpoint final.

Guia operacional detalhado:
- `DEV/DEV-OPENCLAW-SETUP.md`

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
- logs/sessoes brutos com payload sensivel
