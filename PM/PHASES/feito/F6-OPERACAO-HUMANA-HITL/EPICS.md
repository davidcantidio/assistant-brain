---
doc_id: "PHASE-F6-EPICS.md"
version: "1.2"
status: "active"
owner: "PM"
last_updated: "2026-03-01"
rfc_refs: ["RFC-001", "RFC-015", "RFC-040", "RFC-050", "RFC-060"]
---

# F6 Operacao Humana HITL - Epics

## Objetivo da Fase
Validar operador/canal confiavel e fluxo humano critico em conformidade com policy, com Telegram como canal primario e Slack apenas como fallback validado.

## Gate de Saida da Fase
Comando obrigatorio:

```bash
make ci-security
```

Criterio objetivo:
- `security-check: PASS`.
- checklist HITL preenchido e validado.
- remediacao da auditoria F6 concluida com `R1`, `R3` e `R6` sem cobertura parcial e `R9` coberto.
- enquanto qualquer criterio acima estiver pendente, a decisao de fase permanece `hold`.

## Contrato Obrigatorio das Issues F6
Cada `ISSUE-F6-*` deve conter obrigatoriamente os campos:
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
| `EPIC-F6-01` | Identidade e canal confiavel | validar operadores autorizados e contrato de canal HITL confiavel | done | [EPIC-F6-01-IDENTIDADE-E-CANAL-CONFIAVEL.md](./EPIC-F6-01-IDENTIDADE-E-CANAL-CONFIAVEL.md) |
| `EPIC-F6-02` | Challenge, idempotencia e auditoria | formalizar seguranca dos comandos criticos HITL com trilha auditavel | done | [EPIC-F6-02-CHALLENGE-IDEMPOTENCIA-E-AUDITORIA.md](./EPIC-F6-02-CHALLENGE-IDEMPOTENCIA-E-AUDITORIA.md) |
| `EPIC-F6-03` | Fallback, contingencia e promocao | fechar fase com checklist humano e decisao formal `promote|hold` | done | [EPIC-F6-03-FALLBACK-CONTINGENCIA-E-PROMOCAO.md](./EPIC-F6-03-FALLBACK-CONTINGENCIA-E-PROMOCAO.md) |

## Escopo Desta Entrega
- fase `F6` concluida no escopo documental/tdd desta rodada.
- epicos `EPIC-F6-01..03` em estado `done`.
- decisao de fase `F6 -> F7`: `hold`.
- remediacao documental da auditoria F6 em andamento ate rerun confirmar cobertura integral.

## Remediacao da Auditoria F6
| Issue | Prioridade | Owner | Prazo alvo | Status de remediacao | Resultado esperado |
|---|---|---|---|---|---|
| `ISSUE-F6-02-01` | `P0` | `security-lead` | `2026-03-02` | planned | fechar `TTL=5 minutos` + invalidacao completa |
| `ISSUE-F6-03-01` | `P1` | `product-owner + tech-lead-trading` | `2026-03-04` | planned | incluir `>2 heartbeats` + `RESTORE_TELEGRAM_CHANNEL` |
| `ISSUE-F6-03-02` | `P1` | `product-owner + tech-lead-trading` | `2026-03-04` | planned | exigir `decision_id` para remover `TRADING_BLOCKED` |
| `ISSUE-F6-01-01` | `P1` | `security-lead` | `2026-03-04` | planned | amarrar operador+canal ao mesmo ciclo de `security-check: PASS` |
| `ISSUE-F6-01-02` | `P1` | `security-lead` | `2026-03-04` | planned | fechar contrato de canal confiavel no gate F6 |
| `ISSUE-F6-01-03` | `P1` | `product-owner` | `2026-03-04` | planned | reforcar rastreabilidade de fallback Slack |
| `ISSUE-F6-02-02` | `P1` | `tech-lead-trading` | `2026-03-04` | planned | anexar evidencia de `replay_event_hash` |
| `ISSUE-F6-02-03` | `P1` | `security-lead` | `2026-03-04` | planned | anexar `blocked_payload_hash` e incidente rastreavel |
| `ISSUE-F6-03-03` | `P2` | `pm` | `2026-03-03` | planned | consolidar owner + data alvo + decisao final |

## Criterios de Fechamento da Remediacao
- 9/9 issues F6 com metadata obrigatoria preenchida.
- presenca literal de `TTL=5 minutos` em `ISSUE-F6-02-01`.
- presenca literal de `>2 heartbeats` e `RESTORE_TELEGRAM_CHANNEL` em `ISSUE-F6-03-01`.
- presenca literal de `decision_id` em `ISSUE-F6-03-02`.
- rerun da auditoria F6 sem cobertura parcial em `R1`, `R3`, `R6` e com `R9` coberto.
