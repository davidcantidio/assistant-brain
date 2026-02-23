# assistant-brain (Nanobot PRD Repo)

Repositorio de governanca e arquitetura do Nanobot Agent OS.

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
- gateway programatico de inferencia em cloud/provider externo: **OpenRouter** (`https://openrouter.ai/api/v1`).
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

## Harness de Evals (local)
```bash
make eval-models
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

## Quickstart Minimo (Nanobot + ClawWork)
```bash
# 1) Runtime Nanobot (source editable)
git clone https://github.com/HKUDS/nanobot.git ~/.local/src/nanobot
python3 -m venv ~/.local/src/.venv-nanobot
~/.local/src/.venv-nanobot/bin/pip install -U pip wheel setuptools
~/.local/src/.venv-nanobot/bin/pip install -e ~/.local/src/nanobot

# 2) ClawWork + clawmode wrapper
git clone https://github.com/HKUDS/ClawWork.git ~/.local/src/ClawWork
~/.local/src/.venv-nanobot/bin/pip install -r ~/.local/src/ClawWork/requirements.txt

# 3) Bootstrap Nanobot
~/.local/src/.venv-nanobot/bin/nanobot onboard
```

Comandos oficiais de integracao:
```bash
nanobot --version
python -m clawmode_integration.cli agent
python -m clawmode_integration.cli gateway
```

Guia completo Linux + macOS:
- `DEV/DEV-NANOBOT-CLAWWORK-SETUP.md`

## Contribuicao em Documentacao
- atualize `version` e `last_updated` no header do arquivo alterado.
- se houver impacto normativo, registre em `PRD/CHANGELOG.md`.
- em conflito entre docs, aplique `META/DOCUMENT-HIERARCHY.md`.

## Nao Versionar
- `.env`, secrets, chaves e tokens
- estado em `~/.nanobot*`
- logs/sessoes brutos com payload sensivel
