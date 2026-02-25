# assistant-brain (OpenClaw PRD Repo)

Repositorio de governanca e arquitetura do OpenClaw Agent OS.

## Status Atual
- fase atual: **PRD / arquitetura de papel** (sem control-plane implementado ainda).
- objetivo deste repo: fechar requisitos, contratos e gates antes da execucao.
- regra: MVP documental pode estar completo mesmo sem MVP operacional.

## Fonte Canonica
- referencia arquitetural suprema: `felixcraft.md`
- hierarquia e precedencia: `META/DOCUMENT-HIERARCHY.md`
- visao executiva do produto: `PRD/PRD-MASTER.md`
- fases e backlog de implementacao: `PRD/ROADMAP.md`
- fases usaveis com teste humano por etapa: `PRD/PHASE-USABILITY-GUIDE.md`
- historico normativo: `PRD/CHANGELOG.md`

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
