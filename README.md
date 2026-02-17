# Runbook (VPS)
Aqui está o conteúdo fornecido por você, já limpo e pronto para ser salvo diretamente como arquivo `.md` (sem qualquer artefato extra do chat, sem quebras indesejadas e com formatação consistente).

```markdown
# assistant-brain (OpenClaw Workspace Repo)

Este repositório é o **“cérebro”** do meu OpenClaw: workspaces (prompts/identidade/bootstrap), memória e organização em múltiplos contextos (`main`, `ops`, `writer`).

## Árvore (resumo)

- `workspaces/`
  - `main/` — workspace principal
  - `ops/` — operações/infra
  - `writer/` — escrita/redação
- `memory/` — memória global do brain (decisions, lessons, projects etc.)
- `agent/` — arquivos locais de auth/config do workspace (não commitar segredos)
- `sessions/` — logs e sessões (json/jsonl)
- `backup_brain.sh` / `scripts_backup.sh` — scripts de backup/utilitários

> Importante: **estado/config/credenciais do OpenClaw** normalmente ficam em `~/.openclaw/` (ou `~/.openclaw-<profile>`), e **não devem** ser versionados aqui.

---

## Requisitos

- Linux (Ubuntu/Debian recomendado)
- `sudo` disponível
- Node via **NVM**
- OpenClaw CLI via npm

Baseline da VPS atual:
- Node: `v22.22.0` (NVM)
- OpenClaw: `2026.2.14`

---

## Onboarding rápido (Linux)

### 1) Clone

```bash
git clone https://github.com/davidcantidio/assistant-brain.git
cd assistant-brain
```

### 2) Instale tudo (NVM + Node + OpenClaw + templates)

Sem interatividade:

```bash
bash scripts/onboard_linux.sh
```

Com interatividade (preenche .env via prompts sem exibir chaves):

```bash
INTERACTIVE=1 bash scripts/onboard_linux.sh
```

Opcional: ajustar timezone no host:

```bash
SET_TZ=1 bash scripts/onboard_linux.sh
```

### 3) Verifique

```bash
bash scripts/verify_linux.sh
```

## Workspaces

Este repo contém 3 workspaces principais:

- `workspaces/main`
- `workspaces/ops`
- `workspaces/writer`

Cada workspace inclui arquivos como:

- `AGENTS.md`
- `BOOTSTRAP.md`
- `HEARTBEAT.md`
- `IDENTITY.md`
- `SOUL.md`
- `TOOLS.md`
- `USER.md`

além de pasta `memory/` no `main` (e/ou memórias específicas por workspace).

## Conectar este repo ao OpenClaw (workspace)

O OpenClaw trabalha com a ideia de workspace ativo (onde ele lê `BOOTSTRAP.md`, `SOUL.md`, `TOOLS.md`, etc.).

A forma mais estável é apontar o OpenClaw para um workspace deste repo via configuração.

### Opção A (recomendada): setar workspace default no config

Edite/crie `~/.openclaw/openclaw.json` e aponte `agents.defaults.workspace`:

Exemplo usando `main`:

```json
{
  "agents": {
    "defaults": {
      "workspace": "/home/<seu-user>/assistant-brain/workspaces/main"
    }
  }
}
```

Depois rode:

```bash
openclaw setup
openclaw doctor
```

### Opção B: perfis para isolar estado/config

Para isolar estado/config por perfil:

```bash
openclaw --profile main status
openclaw --profile main gateway --port 18789
```

Isso separa `OPENCLAW_STATE_DIR` e o config sob `~/.openclaw-<profile>`.

## Operação (comandos úteis)

### Ajuda

```bash
openclaw --help
openclaw gateway --help
openclaw doctor --help
```

### Health / Doctor

```bash
openclaw health
openclaw doctor
```

### Subir Gateway (foreground)

```bash
openclaw gateway --port 18789
```

### Dashboard (Control UI)

```bash
openclaw dashboard
```

## Migração para outra máquina (checklist)

1. Rodar o onboarding neste repo:

```bash
bash scripts/onboard_linux.sh
```

2. Copiar estado/config do OpenClaw (se necessário):

- default: `~/.openclaw/`
- com profile: `~/.openclaw-<profile>/`

3. Validar:

```bash
openclaw doctor
bash scripts/verify_linux.sh
```

## Segurança

Nunca commitar:

- `.env` com chaves reais
- `~/.openclaw/` (state/config/tokens)
- tokens/chaves em `agent/auth.json` ou `agent/auth-profiles.json`

Recomendação: garantir no `.gitignore`:

```
.env
**/*.key
**/*.pem
**/secrets*
```

## Notas

- Trading/Freqtrade (Fase 1) entra depois que o Mission Control (Fase 0) estiver estável.
- Aprovações humanas serão via Telegram (HITL).
```

Pronto para copiar e colar diretamente em um arquivo `README.md` ou similar.

Se quiser ajustes (ex: adicionar seções novas, mudar versão do Node/OpenClaw, incluir exemplos de SOUL.md, ou gerar um `.gitignore` complementar), é só falar.


## SSH
- ssh openclaw (via config no Windows)
## Saúde
- openclaw status
- openclaw doctor
## Dashboard
- usar túnel SSH (NUNCA expor porta)
## Backup
- cron diário faz push do repo
