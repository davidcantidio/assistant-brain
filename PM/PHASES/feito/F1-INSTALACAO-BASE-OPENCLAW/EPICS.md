---
doc_id: "PHASE-F1-EPICS.md"
version: "1.6"
status: "active"
owner: "PM"
last_updated: "2026-03-01"
rfc_refs: ["RFC-001", "RFC-010", "RFC-040", "RFC-050"]
---

# F1 Instalacao Base OpenClaw - Epics

## Objetivo da Fase
Entregar ambiente local operacional do OpenClaw com onboarding e verify executaveis sem erro em Linux e macOS.

## Gate de Saida da Fase
Comandos obrigatorios:

```bash
bash scripts/onboard_linux.sh
bash scripts/verify_linux.sh
```

Criterio objetivo:
- `verify_linux.sh` finaliza com `exit code 0` (falha obrigatoria com `exit code != 0` quando faltar requisito).

## Escopo normativo da F1 (audit alignment)
- in_scope_f1:
  - `R1`,`R2`,`R3`,`R4`,`R5`,`R7`,`R8`,`R9`,`R10`,`R11`,`R12`,`R13`,`R14`,`R15`
- remap_phase:
  - `R6 -> F2` (`EPIC-F2-03/ISSUE-F2-03-05`)
  - `R16 -> F2` (`EPIC-F2-02/ISSUE-F2-02-03`)
  - `R17 -> F5` (`EPIC-F5-03/ISSUE-F5-03-03`)
  - `R18..R22 -> F7` (`EPIC-F7-01..03`)
- criterio de auditoria:
  - requisito fora de escopo da `F1` nao e tratado como lacuna funcional desta fase quando houver mapeamento formal para fase alvo com issue existente.

## Epics da Fase
| Epic ID | Nome | Objetivo | Status | Documento |
|---|---|---|---|---|
| `EPIC-F1-01` | Baseline de instalacao e verify | garantir setup minimo, validacao e evidencias operacionais da fase | done | [EPIC-F1-01-INSTALACAO-VERIFY.md](./EPIC-F1-01-INSTALACAO-VERIFY.md) |
| `EPIC-F1-02` | Contrato de configuracao local | validar coerencia de `.env`, variaveis obrigatorias e defaults operacionais sem vazamento de segredo | done | [EPIC-F1-02-CONTRATO-CONFIG-LOCAL.md](./EPIC-F1-02-CONTRATO-CONFIG-LOCAL.md) |
| `EPIC-F1-03` | Workspace state e memoria operacional minima | garantir estado canonico e baseline de memoria/heartbeat prontos para uso humano real | done | [EPIC-F1-03-WORKSPACE-STATE-MEMORY.md](./EPIC-F1-03-WORKSPACE-STATE-MEMORY.md) |
| `EPIC-F1-04` | HITL bootstrap e evidencias de fase | fechar F1 com seguranca operacional humana minima e pacote de evidencias para promover F2 | done | [EPIC-F1-04-HITL-BOOTSTRAP-EVIDENCIAS.md](./EPIC-F1-04-HITL-BOOTSTRAP-EVIDENCIAS.md) |

## Escopo Desta Entrega
- fase `F1` inicializada na estrutura de planejamento.
- epicos `EPIC-F1-01..04` definidos para concluir a fase.
