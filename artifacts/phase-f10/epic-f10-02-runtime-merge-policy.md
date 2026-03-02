# F10 / EPIC-F10-02 - Runtime Merge Policy

## Politica de preservacao obrigatoria
Paths preservados integralmente:
- `auth`
- `channels`
- `agents`
- `messages`
- `commands`
- `plugins`
- `wizard`

Estado adicional preservado no state-dir:
- `agents/*/sessions/*`
- `credentials/*`
- `cron/*`
- `devices/*`
- `identity/*`

## Politica de enforce PRD/.env
Paths aplicados pelo merge plan:
- `gateway.bind = loopback`
- `gateway.port = 18789`
- `agents.defaults.heartbeat.every = 15m`

## Resultado do merge plan real
Arquivo: `artifacts/phase-f10/runtime-merge-plan-active.json`
- `plan_id=RMP-20260302-005544`
- operacoes planejadas: `1`
- operacao aplicada:
  - `set agents.defaults.heartbeat.every: 30m -> 15m`

## Gaps estruturais detectados (sem mutacao nesta rodada)
- top-level ausentes no runtime atual: `tools`, `hooks`, `memory`
- canais exigidos pelo schema e ausentes no runtime atual: `slack`, `discord`, `signal`, `imessage`

## Regras de seguranca
- toda aplicacao `dry-run=false` cria backup completo do state-dir antes de mutar `openclaw.json`;
- qualquer diff fora da allowlist bloqueia promocao;
- rollback restaura snapshot integral do state-dir.

## Evidencias relacionadas
- `scripts/runtime/build_runtime_merge_plan.py`
- `scripts/runtime/apply_runtime_merge_plan.sh`
- `artifacts/phase-f10/runtime-backups/20260301-215647-active`
- `artifacts/phase-f10/runtime-convergence-report-active.json`
