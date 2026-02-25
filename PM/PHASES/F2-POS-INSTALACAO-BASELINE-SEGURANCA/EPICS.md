---
doc_id: "PHASE-F2-EPICS.md"
version: "1.1"
status: "active"
owner: "PM"
last_updated: "2026-02-25"
rfc_refs: ["RFC-001", "RFC-015", "RFC-040", "RFC-050", "RFC-060"]
---

# F2 Pos-instalacao + Baseline de Seguranca - Epics

## Objetivo da Fase
Consolidar baseline de seguranca, contratos idempotentes e gates obrigatorios antes de ampliar superficie operacional, mantendo rastreabilidade explicita com `felixcraft.md` e `felix-openclaw-pontos-relevantes.md`.

## Gate de Saida da Fase
Comandos obrigatorios:

```bash
make ci-quality
make ci-security
make eval-gates
```

Criterio objetivo:
- todos os gates acima em `PASS` no mesmo ciclo.
- matriz de rastreabilidade `ROADMAP -> Epic/Issue -> Source` sem lacunas para itens `B0-*` bloqueantes.

## Epics da Fase
| Epic ID | Nome | Objetivo | Status | Documento |
|---|---|---|---|---|
| `EPIC-F2-01` | Baseline de seguranca e gates | fechar baseline de policy/allowlists/approval queue com CI obrigatorio | done | [EPIC-F2-01-BASELINE-SEGURANCA-E-GATES.md](./EPIC-F2-01-BASELINE-SEGURANCA-E-GATES.md) |
| `EPIC-F2-02` | Contratos idempotentes e reconciliacao | cobrir `work_order/decision/task_event`, override idempotente e degraded mode | planned | [EPIC-F2-02-CONTRATOS-IDEMPOTENCIA-E-RECONCILIACAO.md](./EPIC-F2-02-CONTRATOS-IDEMPOTENCIA-E-RECONCILIACAO.md) |
| `EPIC-F2-03` | Catalog, router, memory e budget baseline | formalizar baseline tecnico de roteamento, memoria e custo com contratos executaveis | planned | [EPIC-F2-03-CATALOG-ROUTER-MEMORY-BUDGET.md](./EPIC-F2-03-CATALOG-ROUTER-MEMORY-BUDGET.md) |

## Escopo Desta Entrega
- fase `F2` adicionada para remover lacuna entre `F1` e `F3` do overlay de fases usaveis.
- epicos `EPIC-F2-01..03` cobrem os gaps centrais remanescentes de `B0-*`.
- cada issue desta fase deve referenciar:
  - ao menos um item de `PRD/ROADMAP.md` (`B*`);
  - ao menos uma fonte `felixcraft.md` ou `felix-openclaw-pontos-relevantes.md`.
