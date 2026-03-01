---
doc_id: "ARCHITECTURE-AUDIT-COVERAGE.md"
version: "1.0"
status: "active"
owner: "PM"
last_updated: "2026-03-01"
rfc_refs: ["RFC-001", "RFC-010", "RFC-015", "RFC-040", "RFC-050", "RFC-060"]
---

# Cobertura da Auditoria Arquitetural -> Backlog F9

## Objetivo
Mapear conflitos e failure modes da auditoria arquitetural de 2026-03-01 para epics/issues executaveis da fase `F9`.

## Fonte Canonica
- `artifacts/architecture/2026-03-01-architectural-consistency-audit.md`

## Regras
- todo conflito critico/alto MUST ter issue vinculada em `F9`.
- todo override de arquitetura vindo de fonte externa MUST ter trilha em issue + changelog + traceability.
- item sem mapeamento bloqueia fechamento da fase `F9`.

## Matriz de Conflitos
| Conflito da auditoria | Severidade | Issue F9 vinculada | Status | Observacao |
|---|---|---|---|---|
| Hierarquia documental com autoridade paralela Felix vs PRD | critica | `ISSUE-F9-01-02` | planned | consolidar precedencia normativa unica |
| Cadeia estrutural concorrente (`sprint/task` vs `issue/microtask`) | alta | `ISSUE-F9-02-01` | planned | sprint fica como capacidade, nao como trilha concorrente |
| Microtask declarada sem trilha materializada | alta | `ISSUE-F9-03-01` | planned | definir path `runs/<issue_id>/<microtask_id>/` e evidencia minima |
| Pipeline `M30 -> M14-Code -> Codex 5` normativo sem harmonizacao transversal | alta | `ISSUE-F9-02-02` | planned | rebaixar para proposta ate convergencia de contratos |
| Governanca de PR/branch/ownership sem enforcement completo | alta | `ISSUE-F9-02-03` | planned | formalizar contrato de governanca e criterio de excecao |
| Superficies externas fora do pacote normativo `INTEGRATIONS` | media | `ISSUE-F9-03-02` | planned | formalizar ou declarar fora de escopo atual |
| Desorganizacao de links/path PM em auditorias e evidencias | alta | `ISSUE-F9-01-01` | in_progress | corrigido nesta rodada para refs quebradas F7 |

## Matriz de Failure Modes
| Failure mode da auditoria | Status na auditoria | Issue F9 vinculada | Status | Observacao |
|---|---|---|---|---|
| Autoridade dupla entre modelos | encontrado | `ISSUE-F9-01-02` | planned | regra de autoridade unica |
| Implementacao bypassando PRD | parcialmente contido | `ISSUE-F9-02-03` | planned | reforcar governanca de PR/policy |
| PRD desatualizado | encontrado | `ISSUE-F9-02-01` | planned | convergencia da cadeia estrutural |
| Felix propondo arquitetura nao formalizada | encontrado | `ISSUE-F9-03-03` | planned | override obrigatoriamente rastreado |
| CI nao refletindo criterios do PRD | parcialmente contido | `ISSUE-F9-02-03` | planned | contrato de governanca explicito |
| Pipeline multi-modelo nao documentado de forma sistemica | encontrado | `ISSUE-F9-02-02` | planned | manter como proposta ate harmonizacao |
| Micro-issues violando atomicidade | risco aberto | `ISSUE-F9-03-01` | planned | trilha minima por microtask |
| Drift entre roadmap e codigo | encontrado/explicitado | `ISSUE-F9-02-01` | planned | alinhar cadeia e taxonomia |
| Regras de branch nao documentadas | encontrado | `ISSUE-F9-02-03` | planned | policy de branch/ownership |
| Dependencias externas nao mapeadas | encontrado | `ISSUE-F9-03-02` | planned | matriz governada por superficie |
| Decisoes arquiteturais hardcoded | encontrado/parcialmente controlado | `ISSUE-F9-03-01` | planned | reforcar contrato e evidencias |

## Matriz Requirement -> Issue (F9 audit)
| Requirement ID | Descricao curta | Issue |
|---|---|---|
| `R1` | canonizar paths PM concluido/feito | `ISSUE-F9-01-01` |
| `R2` | precedencia normativa unica | `ISSUE-F9-01-02` |
| `R3` | secao permanente de auditoria + score | `ISSUE-F9-01-03` |
| `R4` | cadeia canonica de planejamento | `ISSUE-F9-02-01` |
| `R5` | pipeline multi-modelo como proposta | `ISSUE-F9-02-02` |
| `R6` | contrato de governanca PR/branch/ownership | `ISSUE-F9-02-03` |
| `R7` | trilha minima de microtask | `ISSUE-F9-03-01` |
| `R8` | classificacao de superficies externas | `ISSUE-F9-03-02` |
| `R9` | override Felix com issue+changelog+traceability | `ISSUE-F9-03-03` |

## Criterio de Aceite desta Cobertura
- 100% dos conflitos criticos/altos mapeados para ao menos uma issue `F9`.
- 100% dos requirements `R1..R9` mapeados para issues com metadata obrigatoria.
- nenhuma referencia quebrada para `PM/PHASES/F7-TRADING-POR-ESTAGIOS/*` nos arquivos de auditoria PM alvo desta rodada.
