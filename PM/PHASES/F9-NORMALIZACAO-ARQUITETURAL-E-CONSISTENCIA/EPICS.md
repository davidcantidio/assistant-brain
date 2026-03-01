---
doc_id: "PHASE-F9-EPICS.md"
version: "1.0"
status: "active"
owner: "PM"
last_updated: "2026-03-01"
rfc_refs: ["RFC-001", "RFC-010", "RFC-015", "RFC-040", "RFC-050", "RFC-060"]
---

# F9 Normalizacao Arquitetural e Consistencia - Epics

## Objetivo da Fase
Converter a auditoria arquitetural de 2026-03-01 em backlog executavel de governanca, removendo ambiguidade de autoridade, cadeia estrutural concorrente e lacunas de rastreabilidade documental no pacote PM.

## Gate de Saida da Fase
Comandos obrigatorios:

```bash
make ci-quality
bash scripts/ci/check_pm_audit_paths.sh
```

Criterio objetivo:
- `ci-quality` em `PASS` no mesmo ciclo da fase.
- `F9` publicada com `EPICS.md + 3 epics` e 9 issues com metadata obrigatoria completa.
- `PM/audit/F9-NORMALIZACAO-ARQUITETURAL-EPICS-ISSUES-AUDIT.json` valido e parseavel.
- `PM/TRACEABILITY/ARCHITECTURE-AUDIT-COVERAGE.md` mapeando conflitos e failure modes para o backlog `F9`.
- zero referencia legada de `F7` fora de `feito` em `PM/audit/*`.

## Contrato Canonico de Paths PM
- fase ativa: `PM/PHASES/F*-.../`
- fase concluida: `PM/PHASES/feito/F*-.../`

## Contrato Obrigatorio das Issues F9
Cada `ISSUE-F9-*` deve conter obrigatoriamente os campos:
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
| `EPIC-F9-01` | Higiene PM e autoridade normativa | canonizar paths, fechar links quebrados e explicitar autoridade normativa unica | planned | [EPIC-F9-01-HIGIENE-PM-E-AUTORIDADE-NORMATIVA.md](./EPIC-F9-01-HIGIENE-PM-E-AUTORIDADE-NORMATIVA.md) |
| `EPIC-F9-02` | Cadeia de planejamento e governanca de codigo | alinhar cadeia canonica e reclassificar pipeline multi-modelo para proposta harmonizavel | planned | [EPIC-F9-02-CADEIA-PLANEJAMENTO-E-GOVERNANCA-CODIGO.md](./EPIC-F9-02-CADEIA-PLANEJAMENTO-E-GOVERNANCA-CODIGO.md) |
| `EPIC-F9-03` | Microtask e superficies externas | formalizar trilha minima de microtask e governanca para superficies externas e overrides Felix | planned | [EPIC-F9-03-MICROTASK-E-SUPERFICIES-EXTERNAS.md](./EPIC-F9-03-MICROTASK-E-SUPERFICIES-EXTERNAS.md) |

## Escopo Desta Entrega
- fase `F9` criada como fase dedicada de governanca documental.
- organizacao da base PM tratada como prioridade inicial (`EPIC-F9-01`).
- pacote completo desta conversao inclui:
  - fase + epics em `PM/PHASES/F9-*`;
  - auditoria de fase em `PM/audit/F9-*`;
  - rastreabilidade cruzada em `PM/TRACEABILITY/ARCHITECTURE-AUDIT-COVERAGE.md`;
  - entrada normativa no `PRD/CHANGELOG.md`.

## Criterios de Fechamento da Fase
- `EPIC-F9-01..03` em estado `done`.
- cada uma das 9 issues com metadata obrigatoria completa e evidencias rastreaveis.
- conflitos criticos da auditoria com plano de remediacao associado.
- historico antigo preservado em `PRD/CHANGELOG.md`, sem reescrita retroativa de entradas anteriores.

## Referencia de Origem
- [Auditoria de Consistencia Arquitetural (2026-03-01)](../../../artifacts/architecture/2026-03-01-architectural-consistency-audit.md)
