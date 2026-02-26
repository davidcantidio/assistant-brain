---
doc_id: "PHASE-F4-EPICS.md"
version: "1.3"
status: "active"
owner: "PM"
last_updated: "2026-02-26"
rfc_refs: ["RFC-001", "RFC-015", "RFC-030", "RFC-040", "RFC-050", "RFC-060"]
---

# F4 Onboarding de Repositorios e Contexto Externo - Epics

## Objetivo da Fase
Consolidar onboarding de contexto externo com pacote de integracoes e contratos de schema validos, sem bypass de regras normativas.

## Gate de Saida da Fase
Comando obrigatorio:

```bash
make eval-integrations
```

Criterio objetivo:
- `eval-integrations: PASS`.

## Epics da Fase
| Epic ID | Nome | Objetivo | Status | Documento |
|---|---|---|---|---|
| `EPIC-F4-01` | Pacote INTEGRATIONS baseline | validar pacote documental obrigatorio de integracoes e regras mandatarias por integracao | done | [EPIC-F4-01-PACOTE-INTEGRATIONS-BASELINE.md](./EPIC-F4-01-PACOTE-INTEGRATIONS-BASELINE.md) |
| `EPIC-F4-02` | Contratos e schemas de integracao | validar contratos versionados e coerencia de campos minimos obrigatorios | done | [EPIC-F4-02-CONTRATOS-SCHEMAS-INTEGRACAO.md](./EPIC-F4-02-CONTRATOS-SCHEMAS-INTEGRACAO.md) |
| `EPIC-F4-03` | Coerencia normativa e gate | validar anti-drift documental, compatibilidade upstream e pacote de evidencia da fase | done | [EPIC-F4-03-COERENCIA-NORMATIVA-E-GATE.md](./EPIC-F4-03-COERENCIA-NORMATIVA-E-GATE.md) |

## Escopo Desta Entrega
- fase `F4` inicializada na estrutura de planejamento.
- epicos `EPIC-F4-01..03` definidos para concluir a fase.
