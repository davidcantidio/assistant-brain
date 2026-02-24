---
doc_id: "PHASE-F3-EPICS.md"
version: "1.0"
status: "active"
owner: "PM"
last_updated: "2026-02-24"
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

## Epics da Fase
| Epic ID | Nome | Objetivo | Status | Documento |
|---|---|---|---|---|
| `EPIC-F3-01` | Contrato de runtime minimo | validar arquivos obrigatorios, schema e contrato canonicos do runtime | planned | [EPIC-F3-01-CONTRATO-RUNTIME-MINIMO.md](./EPIC-F3-01-CONTRATO-RUNTIME-MINIMO.md) |
| `EPIC-F3-02` | Memoria diaria com contrato minimo | validar estrutura e qualidade semantica minima das notas diarias de memoria | planned | [EPIC-F3-02-MEMORIA-DIARIA-CONTRATO.md](./EPIC-F3-02-MEMORIA-DIARIA-CONTRATO.md) |
| `EPIC-F3-03` | Heartbeat, timezone e operacao | validar baseline de heartbeat, timezone canonico e coerencia de regras criticas | planned | [EPIC-F3-03-HEARTBEAT-TIMEZONE-OPERACAO.md](./EPIC-F3-03-HEARTBEAT-TIMEZONE-OPERACAO.md) |

## Escopo Desta Entrega
- fase `F3` inicializada na estrutura de planejamento.
- epicos `EPIC-F3-01..03` definidos para concluir a fase.
