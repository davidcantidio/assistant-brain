---
doc_id: "PHASE-F7-EPICS.md"
version: "1.0"
status: "active"
owner: "PM"
last_updated: "2026-02-24"
rfc_refs: ["RFC-001", "RFC-010", "RFC-040", "RFC-050", "RFC-060"]
---

# F7 Trading por Estagios - Epics

## Objetivo da Fase
Operar `S0 -> S1 -> S2` com risco controlado e bloqueio de bypass, mantendo governanca formal de trading em cada transicao de estagio.

## Gate de Saida da Fase
Comandos obrigatorios:

```bash
make eval-trading
```

- revisar `pre_live_checklist` sem item `fail`.

Criterio objetivo:
- `eval-trading: PASS`.
- checklist de pre-live valido e sem `fail`.

## Epics da Fase
| Epic ID | Nome | Objetivo | Status | Documento |
|---|---|---|---|---|
| `EPIC-F7-01` | S0 paper sandbox operacional | consolidar `S0` como etapa obrigatoria sem ordem real | planned | [EPIC-F7-01-S0-PAPER-SANDBOX-OPERACIONAL.md](./EPIC-F7-01-S0-PAPER-SANDBOX-OPERACIONAL.md) |
| `EPIC-F7-02` | S1 micro-live pre-live checklist | fechar prontidao de `S1` com checklist contratual e guardrails hard-risk | planned | [EPIC-F7-02-S1-MICRO-LIVE-PRE-LIVE-CHECKLIST.md](./EPIC-F7-02-S1-MICRO-LIVE-PRE-LIVE-CHECKLIST.md) |
| `EPIC-F7-03` | S2 escala e promocao | formalizar criterios de escala e decisao `promote|hold` de `F7 -> F8` | planned | [EPIC-F7-03-S2-ESCALA-E-PROMOCAO.md](./EPIC-F7-03-S2-ESCALA-E-PROMOCAO.md) |

## Escopo Desta Entrega
- fase `F7` inicializada na estrutura de planejamento.
- epicos `EPIC-F7-01..03` definidos para concluir a fase.
