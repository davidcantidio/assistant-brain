---
doc_id: "2026-03-01-ARCHITECTURAL-CONSISTENCY-AUDIT-BACKLOG.md"
version: "1.0"
status: "active"
owner: "Architecture"
last_updated: "2026-03-01"
rfc_refs: ["RFC-001", "RFC-015", "RFC-040", "RFC-050", "RFC-060"]
---

# Backlog Executavel - Auditoria de Consistencia Arquitetural (F8)

## Escopo
- baseline oficial: `HEAD main` vs `working tree` em paralelo.
- repositorio auditado: `assistant-brain`.
- fonte de evidencia: `artifacts/architecture/2026-03-01-architectural-consistency-audit.md`.
- contrato maquina-consumivel: `PM/audit/ARCH-CONSISTENCY-BACKLOG-2026-03-01.json`.
- schema: `ARC/schemas/architecture_consistency_backlog.schema.json`.

## Mapeamento Conflito -> Issue -> Micro-issues
| Conflito | Severidade | Issue de remediacao | Micro-issues executaveis |
|---|---|---|---|
| `C-01` autoridade documental paralela | Critica | `ISSUE-F8-03-04` | `MT-F8-03-04-01`, `MT-F8-03-04-02`, `MT-F8-03-04-03` |
| `C-02` cadeia estrutural divergente | Alta | `ISSUE-F8-02-04` | `MT-F8-02-04-01`, `MT-F8-02-04-02`, `MT-F8-02-04-03` |
| `C-03` microtask sem trilha de runs | Alta | `ISSUE-F8-01-04` | `MT-F8-01-04-01`, `MT-F8-01-04-02`, `MT-F8-01-04-03` |
| `C-04` pipeline multi-modelo sem harmonizacao integral | Alta | `ISSUE-F8-03-06` | `MT-F8-03-06-01`, `MT-F8-03-06-02`, `MT-F8-03-06-03` |
| `C-05` governanca de PR/branch e ownership | Alta | `ISSUE-F8-03-05` | `MT-F8-03-05-01`, `MT-F8-03-05-02`, `MT-F8-03-05-03` |
| `C-06` dependencias externas sem classificacao binaria | Media | `ISSUE-F8-02-05` | `MT-F8-02-05-01`, `MT-F8-02-05-02`, `MT-F8-02-05-03` |

## Mapeamento Drift -> Issue
### Drift do estado commitado
| Drift | Classe | Issue |
|---|---|---|
| `D-MAIN-01` fonte de autoridade | Critico | `ISSUE-F8-03-04` |
| `D-MAIN-02` cadeia de planejamento | Alto | `ISSUE-F8-02-04` |
| `D-MAIN-03` trilha de microtask | Alto | `ISSUE-F8-01-04` |
| `D-MAIN-04` superficies externas | Moderado | `ISSUE-F8-02-05` |

### Drift introduzido pelo working tree
| Drift | Classe | Issue |
|---|---|---|
| `D-WT-01` pipeline multi-modelo | Alto | `ISSUE-F8-03-06` |
| `D-WT-02` ownership de PR e branch model | Moderado | `ISSUE-F8-03-05` |

### Felix como terceira direcao
| Drift | Classe | Issue |
|---|---|---|
| `D-FELIX-01` heartbeat/operacao | Leve | `ISSUE-F8-03-06` |
| `D-FELIX-02` superficies externas | Moderado | `ISSUE-F8-02-05` |

## Mapeamento Failure Mode -> Issue
| Failure mode | Status | Issue |
|---|---|---|
| `FM-01` autoridade_dupla_entre_modelos | encontrado | `ISSUE-F8-03-04` |
| `FM-02` implementacao_bypassando_prd | parcialmente_contido | `ISSUE-F8-03-06` |
| `FM-03` prd_desatualizado | encontrado | `ISSUE-F8-02-04` |
| `FM-04` felix_propondo_arquitetura_nao_formalizada | encontrado | `ISSUE-F8-03-04` |
| `FM-05` ci_nao_refletindo_criterios_do_prd | parcialmente_contido | `ISSUE-F8-03-06` |
| `FM-06` seguranca_nao_alinhada_com_principios_felix | ok | `ISSUE-F8-02-05` |
| `FM-07` pipeline_multi_modelo_nao_documentado | encontrado | `ISSUE-F8-03-06` |
| `FM-08` micro_issues_violando_atomicidade | risco_aberto | `ISSUE-F8-01-04` |
| `FM-09` drift_entre_roadmap_e_codigo | encontrado | `ISSUE-F8-02-04` |
| `FM-10` regras_de_branch_nao_documentadas | encontrado | `ISSUE-F8-03-05` |
| `FM-11` dependencias_externas_nao_mapeadas | encontrado | `ISSUE-F8-02-05` |
| `FM-12` decisoes_arquiteturais_hardcoded | encontrado | `ISSUE-F8-01-04` |

## Backlog Priorizado
| Issue | Prioridade | Owner | Prazo alvo | Estado |
|---|---|---|---|---|
| `ISSUE-F8-03-04` normalizar fonte de autoridade | `P0` | `pm + architecture-owner` | `2026-03-08` | `planned` |
| `ISSUE-F8-03-05` formalizar branch governance e ownership | `P0` | `tech-lead` | `2026-03-08` | `planned` |
| `ISSUE-F8-02-04` normalizar cadeia estrutural | `P0` | `pm` | `2026-03-08` | `planned` |
| `ISSUE-F8-01-04` materializar trilha minima de microtask | `P0` | `tech-lead` | `2026-03-08` | `planned` |
| `ISSUE-F8-03-06` harmonizar pipeline multi-modelo | `P1` | `architecture-owner + tech-lead` | `2026-03-15` | `planned` |
| `ISSUE-F8-02-05` mapear dependencias externas | `P1` | `security-owner + pm` | `2026-03-15` | `planned` |

## Criterio de aceite do backlog
- todo conflito `Critica` ou `Alta` possui `issue_id` e micro-issue vinculada no JSON.
- todos os 12 failure modes obrigatorios estao presentes no JSON.
- toda micro-issue contem `owner`, `estimate`, `acceptance_checks` e `evidence_targets`.
- `bash scripts/ci/check_architecture_consistency_backlog.sh` retorna `PASS`.
- `make ci-quality` retorna `PASS` com checker acoplado.

## Evidencias desta rodada
- auditoria base: `artifacts/architecture/2026-03-01-architectural-consistency-audit.md`.
- impacto do pipeline multi-modelo: `artifacts/architecture/2026-03-01-multi-model-pipeline-impact.md`.
- backlog maquina-consumivel: `PM/audit/ARCH-CONSISTENCY-BACKLOG-2026-03-01.json`.
