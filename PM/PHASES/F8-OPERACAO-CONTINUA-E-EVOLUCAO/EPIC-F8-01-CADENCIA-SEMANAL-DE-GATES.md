---
doc_id: "EPIC-F8-01-CADENCIA-SEMANAL-DE-GATES.md"
version: "1.0"
status: "active"
owner: "PM"
last_updated: "2026-02-24"
rfc_refs: ["RFC-001", "RFC-040", "RFC-050", "RFC-060"]
---

# EPIC-F8-01 Cadencia semanal de gates

## Objetivo
Formalizar rotina semanal de execucao e evidencia dos gates obrigatorios para manter operacao continua com bloqueio automatico de regressao.

## Resultado de Negocio Mensuravel
- equipe passa a operar com ciclo previsivel de verificacao semanal.
- regressao em gate critico bloqueia promocao de fase no mesmo ciclo.

## Definition of Done (Scrum)
- todas as issues do epico em estado `Done`.
- `make eval-gates`, `make ci-quality` e `make ci-security` executados com sucesso no mesmo ciclo.
- relatorio semanal registrado com resultado completo e timestamp.

## Issues (Scrum + TDD + Criterios de Aceitacao)

### ISSUE-F8-01-01 - Executar ciclo semanal do trio de gates com registro timestamp
**User story**  
Como operador, quero executar semanalmente os gates obrigatorios para manter estado continuo de conformidade.

**Plano TDD**
1. `Red`: executar ciclo semanal sem rodar os tres gates.
2. `Green`: executar `make eval-gates`, `make ci-quality` e `make ci-security` no mesmo ciclo.
3. `Refactor`: registrar evidencias com timestamp em relatorio semanal unico.

**Criterios de aceitacao**
- Given trio de gates incompleto, When revisao semanal ocorre, Then resultado deve ser `hold`.
- Given trio de gates completo e verde, When revisao semanal ocorre, Then criterio de execucao semanal fica `pass`.

### ISSUE-F8-01-02 - Aplicar regra fail-fast e bloqueio de promocao quando qualquer gate falhar
**User story**  
Como operador, quero bloqueio imediato quando gate falhar para evitar promocao com risco conhecido.

**Plano TDD**
1. `Red`: permitir promocao semanal mesmo com falha em gate.
2. `Green`: aplicar regra fail-fast e bloqueio automatico de promocao.
3. `Refactor`: alinhar mensagem de resultado no relatorio da semana.

**Criterios de aceitacao**
- Given qualquer gate com `FAIL`, When ciclo semanal e avaliado, Then resultado deve ser `hold`.
- Given todos os gates com `PASS`, When ciclo semanal e avaliado, Then fase pode seguir para decisao `promote|hold`.

### ISSUE-F8-01-03 - Consolidar relatorio semanal com resultado falhas e acoes corretivas
**User story**  
Como operador, quero um relatorio semanal padrao para auditoria e continuidade operacional.

**Plano TDD**
1. `Red`: manter evidencias dispersas sem relatorio padronizado.
2. `Green`: consolidar um relatorio semanal unico com resultados e plano de acao.
3. `Refactor`: revisar links e consistencia com `make ci-quality`.

**Criterios de aceitacao**
- Given relatorio semanal ausente, When revisao de fase ocorre, Then decisao deve ser `hold`.
- Given relatorio semanal completo, When revisao de fase ocorre, Then evidencias ficam auditaveis e reutilizaveis.

## Artifact Minimo do Epico
- registrar relatorio semanal em `artifacts/phase-f8/weekly-governance/<week_id>.md` contendo obrigatoriamente:
  - `week_id` (`YYYY-Www`)
  - `executed_at`
  - `eval_gates_status` (`PASS|FAIL`)
  - `ci_quality_status` (`PASS|FAIL`)
  - `ci_security_status` (`PASS|FAIL`)
  - `contract_review_status` (`PASS|FAIL`)
  - `critical_drifts_open`
  - `decision` (`promote|hold`)
  - `risk_notes`
  - `next_actions`

## Dependencias
- [Makefile](../../../Makefile)
- [Dev CI Rules](../../../DEV/DEV-CI-RULES.md)
- [Phase Usability Guide](../../../PRD/PHASE-USABILITY-GUIDE.md)
- [Eval Gates Script](../../../scripts/ci/eval_gates.sh)
