# assistant-brain (OpenClaw PRD Repo)

Repositorio de governanca e arquitetura do OpenClaw Agent OS.

## Status Atual
- fase atual: **PRD / arquitetura de papel** (sem control-plane implementado ainda).
- objetivo deste repo: fechar requisitos, contratos e gates antes da execucao.
- regra: MVP documental pode estar completo mesmo sem MVP operacional.

## Fonte Canonica
- hierarquia e precedencia: `META/DOCUMENT-HIERARCHY.md`
- visao executiva do produto: `PRD/PRD-MASTER.md`
- fases e backlog de implementacao: `PRD/ROADMAP.md`
- historico normativo: `PRD/CHANGELOG.md`

## Estrutura
- `PRD/`: produto, fases e changelog
- `PM/`: decisoes, work order, sprint governance
- `ARC/`: arquitetura operacional e roteamento
- `SEC/`: seguranca, secrets, sandbox, allowlists
- `EVALS/`: gates de qualidade e saude
- `VERTICALS/`: PRDs por vertical (inclui Trading)
- `INCIDENTS/`: politicas e procedimentos de incidente
- `RAG/`: ingestao, isolamento e avaliacao de conhecimento
- `workspaces/main/`: workspace operacional canonico do MVP

## Regras Operacionais Essenciais
- baseline de heartbeat: **20 minutos** (`ARC/ARC-HEARTBEAT.md`).
- workspaces ativos no MVP: **somente** `workspaces/main`.
- gateway programatico de inferencia: **OpenRouter** (`https://openrouter.ai/api/v1`).
- automacoes com efeito colateral exigem contrato de idempotencia + rollback.
- aprovacao HITL critica exige allowlist de operador + challenge de segundo fator (Telegram primario, Slack fallback controlado).
- claims centrais sem eval gate executavel bloqueiam release de fase.

## CI e Seguranca
- plataforma de CI definida: **GitHub Actions**.
- allowlists canonicas:
  - `SEC/allowlists/DOMAINS.yaml`
  - `SEC/allowlists/TOOLS.yaml`
  - `SEC/allowlists/ACTIONS.yaml`
  - `SEC/allowlists/OPERATORS.yaml`
  - `SEC/allowlists/PROVIDERS.yaml`

## Onboarding Local
```bash
bash scripts/onboard_linux.sh
bash scripts/verify_linux.sh
```

## Contribuicao em Documentacao
- atualize `version` e `last_updated` no header do arquivo alterado.
- se houver impacto normativo, registre em `PRD/CHANGELOG.md`.
- em conflito entre docs, aplique `META/DOCUMENT-HIERARCHY.md`.

## Nao Versionar
- `.env`, secrets, chaves e tokens
- estado em `~/.openclaw*`
- logs/sessoes brutos com payload sensivel
