---
doc_id: "PHASE-F10-CONVERGENCIA-PRD-RUNTIME-SEM-REGRESSAO-EPICS.md"
version: "1.0"
status: "active"
owner: "PM"
last_updated: "2026-03-02"
rfc_refs: ["RFC-001", "RFC-010", "RFC-015", "RFC-030", "RFC-040", "RFC-050", "RFC-060"]
---

# F10 Convergencia PRD -> Runtime Sem Regressao - Epics

## Objetivo da Fase
Aplicar os contratos normativos do PRD no runtime real com rollout canario, preservando estado operacional completo e garantindo ausencia de regressao funcional do canal Telegram.

## Gate de Saida da Fase
Comandos obrigatorios:

```bash
bash scripts/ci/check_phase_f10_runtime_convergence.sh
make ci-quality
make ci-security
make eval-runtime
make eval-gates
```

Criterio objetivo:
- inventario `runtime_inventory.v1` gerado para baseline e pos-convergencia;
- `runtime_merge_plan.v1` aplicado primeiro em `--dev` e validado sem regressao fora da allowlist;
- promocao para runtime ativo com backup completo e rollback deterministico pronto;
- Telegram permanece configurado e com probe `ok=true` no pos-convergencia;
- drift critico de heartbeat corrigido para `15m` no runtime final.

## Epics da Fase
| Epic ID | Nome | Objetivo | Status | Documento |
|---|---|---|---|---|
| `EPIC-F10-01` | Auditoria e baseline runtime | inventariar runtime ativo, mapear gaps PRD/.env/runtime e materializar backlog executavel | done | [EPIC-F10-01-AUDITORIA-E-BASELINE-RUNTIME.md](./EPIC-F10-01-AUDITORIA-E-BASELINE-RUNTIME.md) |
| `EPIC-F10-02` | Convergencia PRD sem perda de estado | definir e executar merge policy com preservacao integral de estado | done | [EPIC-F10-02-CONVERGENCIA-PRD-SEM-PERDA-DE-ESTADO.md](./EPIC-F10-02-CONVERGENCIA-PRD-SEM-PERDA-DE-ESTADO.md) |
| `EPIC-F10-03` | Rollout canario e promocao | validar canario `--dev`, promover para runtime ativo e testar rollback deterministico | done | [EPIC-F10-03-ROLLOUT-CANARIO-E-PROMOCAO.md](./EPIC-F10-03-ROLLOUT-CANARIO-E-PROMOCAO.md) |

## Escopo desta entrega
- criar pacote PM completo da fase F10 no padrao EPIC/ISSUE rastreavel;
- criar toolkit de convergencia runtime em `scripts/runtime/`;
- publicar artifacts tecnicos em `artifacts/phase-f10/`;
- adicionar gate de qualidade da fase em `scripts/ci/check_phase_f10_runtime_convergence.sh`.

## Criterios de Fechamento da Fase
- `EPIC-F10-01..03` em estado `done` com evidencias rastreaveis;
- estado completo preservado (`auth`, `channels`, `agents`, `messages`, `commands`, `plugins`, `wizard`, sessoes/credenciais/cron);
- convergencia de runtime concluida sem regressao funcional de Telegram;
- changelog normativo atualizado com impacto e migracao da fase.

## Resultado da Rodada (2026-03-02)
- `runtime_inventory.v1` gerado para baseline e pos-convergencia (`active` e `dev`);
- `runtime_merge_plan.v1` gerado e aplicado com `operations=1` (`agents.defaults.heartbeat.every: 30m -> 15m`);
- canario `--dev` e promocao `active` validados com `overall_ok=true` em:
  - `artifacts/phase-f10/runtime-convergence-report-dev.json`;
  - `artifacts/phase-f10/runtime-convergence-report-active.json`;
- backup integral de state-dir registrado em `artifacts/phase-f10/runtime-backups/`;
- gates da fase executados com sucesso:
  - `make phase-f10-runtime-convergence`;
  - `make ci-quality`;
  - `make ci-security`;
  - `make eval-runtime`;
  - `make eval-gates`.

## Dependencias
- [Roadmap](../../../PRD/ROADMAP.md)
- [PRD Master](../../../PRD/PRD-MASTER.md)
- [ARC Core](../../../ARC/ARC-CORE.md)
- [Runtime Config Schema](../../../ARC/schemas/openclaw_runtime_config.schema.json)
- [Dev OpenClaw Setup](../../../DEV/DEV-OPENCLAW-SETUP.md)
