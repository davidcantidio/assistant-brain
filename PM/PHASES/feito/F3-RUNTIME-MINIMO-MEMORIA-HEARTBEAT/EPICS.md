---
doc_id: "PHASE-F3-EPICS.md"
version: "1.2"
status: "active"
owner: "PM"
last_updated: "2026-03-01"
rfc_refs: ["RFC-001", "RFC-030", "RFC-040", "RFC-050"]
---

# F3 Runtime Minimo, Memoria e Heartbeat - Epics

## Objetivo da Fase
Consolidar runtime minimo operacional com memoria diaria e heartbeat canonicos, prontos para uso humano com validacao objetiva.

## Gate de Saida da Fase
Comando obrigatorio:

```bash
make eval-runtime
```

Criterio objetivo:
- `eval-runtime-contracts: PASS`.
- contrato DoR de issue completo nas 9 issues F3 (`owner`, `estimate_hours`, `estimate_points`, `risk_class`, `risk_tier`, `dependencies`, `required_inputs`).
- artifacts das 9 issues com contrato de evidencia padrao (`scenario`, `command`, `expected_result`, `actual_assert_message`, `trace_id_or_ref`, `status`).

## Epics da Fase
| Epic ID | Nome | Objetivo | Status | Documento |
|---|---|---|---|---|
| `EPIC-F3-01` | Contrato de runtime minimo | validar arquivos obrigatorios, schema e contrato canonicos do runtime | done | [EPIC-F3-01-CONTRATO-RUNTIME-MINIMO.md](./EPIC-F3-01-CONTRATO-RUNTIME-MINIMO.md) |
| `EPIC-F3-02` | Memoria diaria com contrato minimo | validar estrutura e qualidade semantica minima das notas diarias de memoria | done | [EPIC-F3-02-MEMORIA-DIARIA-CONTRATO.md](./EPIC-F3-02-MEMORIA-DIARIA-CONTRATO.md) |
| `EPIC-F3-03` | Heartbeat, timezone e operacao | validar baseline de heartbeat, timezone canonico e coerencia de regras criticas | done | [EPIC-F3-03-HEARTBEAT-TIMEZONE-OPERACAO.md](./EPIC-F3-03-HEARTBEAT-TIMEZONE-OPERACAO.md) |

## Remediacao Pos-Audit (F3)
- foco: fechar gaps `R3`, `R4`, `R5`, `R7`, `R8`, `R9` reportados em `PM/audit/F3-EPICS-ISSUES-AUDIT.json`.
- hardening: enforcement simulado de canal confiavel + aprovacao financeira no gate.
- qualidade: evidencias Red/Green/Refactor com mensagem assertiva (sem dependencia de `make: Error 1`).

## Decisao de Fase (Pos-Audit)
- estado atual: `promote` condicionado ao re-run final do gate apos remediacoes.
- bloqueio automatico: qualquer falha em DoR/DoD de issue ou em contrato de evidencia deve forcar `hold`.

## Escopo Desta Entrega
- fase `F3` mantida com 3 epicos e 9 issues.
- contratos de governanca e evidencia da fase alinhados ao PRD-MASTER pos-auditoria.
