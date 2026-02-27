---
doc_id: "PHASE-F6-EPICS.md"
version: "1.0"
status: "active"
owner: "PM"
last_updated: "2026-02-24"
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

## Epics da Fase
| Epic ID | Nome | Objetivo | Status | Documento |
|---|---|---|---|---|
| `EPIC-F6-01` | Identidade e canal confiavel | validar operadores autorizados e contrato de canal HITL confiavel | done | [EPIC-F6-01-IDENTIDADE-E-CANAL-CONFIAVEL.md](../feito/F6-OPERACAO-HUMANA-HITL/EPIC-F6-01-IDENTIDADE-E-CANAL-CONFIAVEL.md) |
| `EPIC-F6-02` | Challenge, idempotencia e auditoria | formalizar seguranca dos comandos criticos HITL com trilha auditavel | planned | [EPIC-F6-02-CHALLENGE-IDEMPOTENCIA-E-AUDITORIA.md](./EPIC-F6-02-CHALLENGE-IDEMPOTENCIA-E-AUDITORIA.md) |
| `EPIC-F6-03` | Fallback, contingencia e promocao | fechar fase com checklist humano e decisao formal `promote|hold` | planned | [EPIC-F6-03-FALLBACK-CONTINGENCIA-E-PROMOCAO.md](./EPIC-F6-03-FALLBACK-CONTINGENCIA-E-PROMOCAO.md) |

## Escopo Desta Entrega
- fase `F6` inicializada na estrutura de planejamento.
- epicos `EPIC-F6-01..03` definidos para concluir a fase.
