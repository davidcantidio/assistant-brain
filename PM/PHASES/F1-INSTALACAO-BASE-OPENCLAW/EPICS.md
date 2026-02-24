---
doc_id: "PHASE-F1-EPICS.md"
version: "1.1"
status: "active"
owner: "PM"
last_updated: "2026-02-24"
rfc_refs: ["RFC-001", "RFC-010", "RFC-040", "RFC-050"]
---

# F1 Instalacao Base OpenClaw - Epics

## Objetivo da Fase
Entregar ambiente local operacional do OpenClaw com onboarding e verify executaveis sem erro.

## Gate de Saida da Fase
Comandos obrigatorios:

```bash
bash scripts/onboard_linux.sh
bash scripts/verify_linux.sh
```

Criterio objetivo:
- `verify_linux.sh` finaliza sem erro.

## Epics da Fase
| Epic ID | Nome | Objetivo | Status | Documento |
|---|---|---|---|---|
| `EPIC-F1-01` | Baseline de instalacao e verify | garantir setup minimo, validacao e evidencias operacionais da fase | planned | [EPIC-F1-01-INSTALACAO-VERIFY.md](./EPIC-F1-01-INSTALACAO-VERIFY.md) |
| `EPIC-F1-02` | Contrato de configuracao local | validar coerencia de `.env`, variaveis obrigatorias e defaults operacionais sem vazamento de segredo | planned | [EPIC-F1-02-CONTRATO-CONFIG-LOCAL.md](./EPIC-F1-02-CONTRATO-CONFIG-LOCAL.md) |
| `EPIC-F1-03` | Workspace state e memoria operacional minima | garantir estado canonico e baseline de memoria/heartbeat prontos para uso humano real | planned | [EPIC-F1-03-WORKSPACE-STATE-MEMORY.md](./EPIC-F1-03-WORKSPACE-STATE-MEMORY.md) |
| `EPIC-F1-04` | HITL bootstrap e evidencias de fase | fechar F1 com seguranca operacional humana minima e pacote de evidencias para promover F2 | planned | [EPIC-F1-04-HITL-BOOTSTRAP-EVIDENCIAS.md](./EPIC-F1-04-HITL-BOOTSTRAP-EVIDENCIAS.md) |

## Escopo Desta Entrega
- fase `F1` inicializada na estrutura de planejamento.
- epicos `EPIC-F1-01..04` definidos para concluir a fase.
