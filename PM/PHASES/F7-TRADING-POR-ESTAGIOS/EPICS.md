---
doc_id: "PHASE-F7-EPICS.md"
version: "1.2"
status: "active"
owner: "PM"
last_updated: "2026-03-01"
rfc_refs: ["RFC-001", "RFC-010", "RFC-040", "RFC-050", "RFC-060"]
---

# F7 Trading por Estagios - Epics

## Objetivo da Fase
Operar `S0 -> S1 -> S2` com risco controlado e bloqueio de bypass, mantendo governanca formal de trading em cada transicao de estagio.

## Gate de Saida da Fase
Comando obrigatorio:

```bash
make eval-trading
```

Criterio objetivo:
- `eval-trading: PASS`.
- `artifacts/phase-f7/validation-summary.md` publicado.
- decisao de fase `F7 -> F8` registrada como `promote|hold`.
- checklist `CHECKLIST-F7-02-S1-20260301-01` revisado com estado real preservado.
- enquanto o checklist contiver item `fail` ou nao existir decisao `R3` com limites explicitos para `S2`, a decisao da fase permanece `hold`.

## Contrato Obrigatorio das Issues F7
Cada `ISSUE-F7-*` deve conter obrigatoriamente os campos:
- `Owner`
- `Estimativa`
- `Dependencias`
- `Mapped requirements`
- `Prioridade`
- `Checklist QA/Repro`
- `Evidence refs`

## Epics da Fase
| Epic ID | Nome | Objetivo | Status | Documento |
|---|---|---|---|---|
| `EPIC-F7-01` | S0 paper sandbox operacional | consolidar `S0` como etapa obrigatoria sem ordem real | done | [EPIC-F7-01-S0-PAPER-SANDBOX-OPERACIONAL.md](../feito/F7-TRADING-POR-ESTAGIOS/EPIC-F7-01-S0-PAPER-SANDBOX-OPERACIONAL.md) |
| `EPIC-F7-02` | S1 micro-live pre-live checklist | fechar prontidao de `S1` com checklist contratual e guardrails hard-risk | done | [EPIC-F7-02-S1-MICRO-LIVE-PRE-LIVE-CHECKLIST.md](../feito/F7-TRADING-POR-ESTAGIOS/EPIC-F7-02-S1-MICRO-LIVE-PRE-LIVE-CHECKLIST.md) |
| `EPIC-F7-03` | S2 escala e promocao | formalizar criterios de escala e decisao `promote|hold` de `F7 -> F8` | done | [EPIC-F7-03-S2-ESCALA-E-PROMOCAO.md](../feito/F7-TRADING-POR-ESTAGIOS/EPIC-F7-03-S2-ESCALA-E-PROMOCAO.md) |

## Escopo Desta Entrega
- fase `F7` concluida no escopo documental/tdd desta rodada.
- epicos `EPIC-F7-01..03` em estado `done`.
- decisao de fase `F7 -> F8`: `hold`.
- `promote` permanece bloqueado enquanto `S1` tiver item critico `fail` ou enquanto nao existir decisao `R3` com limites explicitos para `S2`.

## Criterios de Fechamento da Fase
- `EPIC-F7-01..03` em `done`.
- `make eval-trading: PASS`.
- `artifacts/phase-f7/validation-summary.md` publicado.
- decisao `F7 -> F8` registrada como `promote|hold`.
- enquanto `CHECKLIST-F7-02-S1-20260301-01` tiver item `fail` ou nao existir decisao `R3` de escala, a decisao da fase permanece `hold`.
