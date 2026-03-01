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
- `review_validity_status=PASS` e `operational_conformance_status=PASS`.
- enquanto `phase_transition_status=blocked`, `failed_domains != none` ou `critical_drifts_open > 0`, `operational_readiness` MUST permanecer `blocked`.

## Contrato Obrigatorio das Issues F8
Cada `ISSUE-F8-*` deve conter obrigatoriamente os campos:
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
| `EPIC-F8-01` | Cadencia semanal de gates | formalizar rotina semanal de execucao e evidencia dos gates obrigatorios | done | [EPIC-F8-01-CADENCIA-SEMANAL-DE-GATES.md](./EPIC-F8-01-CADENCIA-SEMANAL-DE-GATES.md) |
| `EPIC-F8-02` | Revisao periodica de contratos e drift | identificar e tratar drift normativo/contratual de forma recorrente | done | [EPIC-F8-02-REVISAO-PERIODICA-DE-CONTRATOS-E-DRIFT.md](./EPIC-F8-02-REVISAO-PERIODICA-DE-CONTRATOS-E-DRIFT.md) |
| `EPIC-F8-03` | Governanca de evolucao e release | consolidar decisao semanal `promote|hold` com trilha de release/auditoria | done | [EPIC-F8-03-GOVERNANCA-DE-EVOLUCAO-E-RELEASE.md](./EPIC-F8-03-GOVERNANCA-DE-EVOLUCAO-E-RELEASE.md) |
| `EPIC-F8-04` | Expansao multiativos por enablement | fechar backlog multiativos (`B2-*`) com gate por classe e decisao formal | done | [EPIC-F8-04-EXPANSAO-MULTIATIVOS-ENABLEMENT.md](./EPIC-F8-04-EXPANSAO-MULTIATIVOS-ENABLEMENT.md) |

## Remediacao da Auditoria F8
| Issue | Prioridade | Owner | Prazo alvo | Status de remediacao | Resultado esperado |
|---|---|---|---|---|---|
| `ISSUE-F8-02-01` | `P0` | `tech-lead-trading` | `2026-03-04` | planned | separar validade estrutural de conformidade operacional do dominio |
| `ISSUE-F8-02-03` | `P0` | `product-owner + tech-lead-trading` | `2026-03-08` | planned | validar carry-over real em `2026-W10` |
| `ISSUE-F8-03-03` | `P1` | `pm + tech-lead-trading` | `2026-03-08` | planned | destacar `operational_readiness` e bloqueios no summary executivo |
| `ISSUE-F8-04-03` | `P0` | `product-owner + tech-lead-trading` | `2026-03-08` | planned | exigir `decision_ref` e `shadow_evidence_refs` antes de qualquer `pass` |
| `ISSUE-F8-01-01` | `P2` | `pm` | `2026-03-15` | planned | completar metadata operacional da issue |
| `ISSUE-F8-01-02` | `P1` | `tech-lead-trading` | `2026-03-08` | planned | completar ownership do fail-fast semanal |
| `ISSUE-F8-01-03` | `P2` | `pm` | `2026-03-15` | planned | completar metadata do relatorio semanal |
| `ISSUE-F8-02-02` | `P1` | `product-owner + tech-lead-trading` | `2026-03-08` | planned | completar metadados da remediacao de drift |
| `ISSUE-F8-03-01` | `P0` | `product-owner + tech-lead-trading` | `2026-03-08` | planned | formalizar owner do desbloqueio `F7 -> F8` |
| `ISSUE-F8-03-02` | `P1` | `pm` | `2026-03-08` | planned | completar ownership do pacote de continuidade |
| `ISSUE-F8-04-01` | `P1` | `tech-lead-trading` | `2026-03-08` | planned | completar ownership do contrato multiativo |
| `ISSUE-F8-04-02` | `P1` | `tech-lead-trading` | `2026-03-08` | planned | completar ownership do workflow de evals multiativos |

## Escopo Desta Entrega
- `EPIC-F8-01..04` concluidos no escopo documental/tdd desta rodada.
- decisao semanal atual da `F8`: `hold`.
- `operational_readiness` atual da `F8`: `blocked`.
- `review_validity_status=PASS`, `operational_conformance_status=FAIL`, `failed_domains=trading`.
- `hold` permanece obrigatorio enquanto `critical_drifts_open > 0` no artifact canonico de `contract-review`.
- a ativacao prematura da `F8` foi recuada ao contrato de promocao entre fases.
- enquanto `artifacts/phase-f7/validation-summary.md` mantiver `F7 -> F8: hold`, o artifact semanal da `F8` MUST registrar `phase_transition_status=blocked`.
- o fechamento do `EPIC-F8-03` NAO promove a fase automaticamente; a rodada semanal permanece `hold` ate que `F7 -> F8` possa virar `promote`.
- `EPIC-F8-01..04 = done` representam conclusao documental; nao equivalem a `ready to promote`.
- o fechamento do `EPIC-F8-04` NAO habilita live multiativos automaticamente; `equities_br`, `fii_br` e `fixed_income_br` permanecem em `hold` ate `shadow_mode` validado e decision `R3`.
