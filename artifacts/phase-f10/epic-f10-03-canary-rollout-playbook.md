# F10 / EPIC-F10-03 - Canary Rollout Playbook

## Execucao canario (`--dev`) - concluido
1. backup do state dev pre-canario:
   - `artifacts/phase-f10/runtime-backups/20260301-215557-dev-precanary`
2. copia controlada do state ativo para `~/.openclaw-dev`
3. baseline dev:
   - `artifacts/phase-f10/runtime-inventory-dev-baseline.json`
4. dry-run + apply no dev via merge plan
5. pos dev:
   - `artifacts/phase-f10/runtime-inventory-dev-post.json`
6. validacao:
   - `artifacts/phase-f10/runtime-convergence-report-dev.json`
   - `overall_ok=true`

## Execucao promocao (`active`) - concluido
1. baseline ativo:
   - `artifacts/phase-f10/runtime-inventory-active-baseline.json`
2. dry-run + apply no ativo via merge plan
3. backup ativo criado:
   - `artifacts/phase-f10/runtime-backups/20260301-215647-active`
4. pos ativo:
   - `artifacts/phase-f10/runtime-inventory-active-post.json`
5. validacao:
   - `artifacts/phase-f10/runtime-convergence-report-active.json`
   - `overall_ok=true`

## Resultado operacional final
- `openclaw config get agents.defaults.heartbeat.every` => `15m`
- `openclaw status --json` => heartbeat `15m`
- `openclaw health --json` => `ok=true`, `channels.telegram.probe.ok=true`
- diff permitido observado: apenas `agents.defaults.heartbeat.every`

## Rollback deterministico
Backups integrais prontos para restore imediato:
- `artifacts/phase-f10/runtime-backups/20260301-215557-dev-precanary`
- `artifacts/phase-f10/runtime-backups/20260301-215633-dev`
- `artifacts/phase-f10/runtime-backups/20260301-215647-active`
- `artifacts/phase-f10/runtime-backups/20260301-220006-dev`
- `artifacts/phase-f10/runtime-backups/20260301-220040-dev`

Teste executado de rollback no `--dev`:
- restore do backup `20260301-215633-dev` retornou heartbeat para `30m`;
- reapply do merge plan retornou heartbeat para `15m`;
- report final do canario apos reteste: `artifacts/phase-f10/runtime-convergence-report-dev.json` com `overall_ok=true`.
