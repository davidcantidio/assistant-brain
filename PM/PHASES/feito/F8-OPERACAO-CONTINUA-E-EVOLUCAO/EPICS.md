---
doc_id: "PHASE-F8-EPICS.md"
version: "1.4"
status: "active"
owner: "PM"
last_updated: "2026-03-01"
rfc_refs: ["RFC-001", "RFC-015", "RFC-040", "RFC-050", "RFC-060"]
---

# F8 Operacao Continua e Evolucao - Epics

## Objetivo da Fase
Sustentar cadencia semanal de governanca com execucao de gates obrigatorios e revisao periodica de contratos para evitar drift.

## Gate de Saida da Fase
Comandos obrigatorios:

```bash
make eval-gates
make ci-quality
make ci-security
```

Criterio objetivo:
- trio de gates com `PASS` no mesmo ciclo semanal.
- revisao semanal registrada em artifact da fase.

## Epics da Fase
| Epic ID | Nome | Objetivo | Status | Documento |
|---|---|---|---|---|
| `EPIC-F8-01` | Cadencia semanal de gates | formalizar rotina semanal de execucao e evidencia dos gates obrigatorios | done | [EPIC-F8-01-CADENCIA-SEMANAL-DE-GATES.md](./EPIC-F8-01-CADENCIA-SEMANAL-DE-GATES.md) |
| `EPIC-F8-02` | Revisao periodica de contratos e drift | identificar e tratar drift normativo/contratual de forma recorrente | done | [EPIC-F8-02-REVISAO-PERIODICA-DE-CONTRATOS-E-DRIFT.md](./EPIC-F8-02-REVISAO-PERIODICA-DE-CONTRATOS-E-DRIFT.md) |
| `EPIC-F8-03` | Governanca de evolucao e release | consolidar decisao semanal `promote|hold` com trilha de release/auditoria | done | [EPIC-F8-03-GOVERNANCA-DE-EVOLUCAO-E-RELEASE.md](./EPIC-F8-03-GOVERNANCA-DE-EVOLUCAO-E-RELEASE.md) |
| `EPIC-F8-04` | Expansao multiativos por enablement | fechar backlog multiativos (`B2-*`) com gate por classe e decisao formal | done | [EPIC-F8-04-EXPANSAO-MULTIATIVOS-ENABLEMENT.md](./EPIC-F8-04-EXPANSAO-MULTIATIVOS-ENABLEMENT.md) |

## Escopo Desta Entrega
- `EPIC-F8-01..04` concluidos no escopo documental/tdd desta rodada.
- decisao semanal atual da `F8`: `hold`.
- `hold` permanece obrigatorio enquanto `critical_drifts_open > 0` no artifact canonico de `contract-review`.
- a ativacao prematura da `F8` foi recuada ao contrato de promocao entre fases.
- enquanto `artifacts/phase-f7/validation-summary.md` mantiver `F7 -> F8: hold`, o artifact semanal da `F8` MUST registrar `phase_transition_status=blocked`.
- o fechamento do `EPIC-F8-03` NAO promove a fase automaticamente; a rodada semanal permanece `hold` ate que `F7 -> F8` possa virar `promote`.
- o fechamento do `EPIC-F8-04` NAO habilita live multiativos automaticamente; `equities_br`, `fii_br` e `fixed_income_br` permanecem em `hold` ate `shadow_mode` validado e decision `R3`.
