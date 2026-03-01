---
doc_id: "EPIC-F8-01-CADENCIA-SEMANAL-DE-GATES.md"
version: "1.3"
status: "active"
owner: "PM"
last_updated: "2026-03-01"
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

**Metadata da issue**
- **Owner**: `pm`
- **Estimativa**: `0.5d`
- **Dependencias**: `Makefile`, `scripts/ci/run_phase_f8_weekly_governance.sh`, `scripts/ci/check_phase_f8_weekly_governance.sh`, `artifacts/phase-f8/weekly-governance/2026-W09.md`, `artifacts/phase-f8/weekly-governance/logs/2026-W09/*.log`
- **Mapped requirements**: `R1`
- **Prioridade**: `P2`
- **Checklist QA/Repro**:
  1. rodar `make eval-gates`, `make ci-quality` e `make ci-security` no mesmo ciclo semanal;
  2. rodar `make phase-f8-weekly-governance` e validar `week_id` + `executed_at`;
  3. validar presenca dos logs da rodada em `artifacts/phase-f8/weekly-governance/logs/<week_id>/`;
  4. validar que o relatorio semanal preserva `decision=hold` quando a semana nao atende todos os gates de promote.
- **Evidence refs**: `artifacts/phase-f8/weekly-governance/2026-W09.md`, `scripts/ci/run_phase_f8_weekly_governance.sh`, `scripts/ci/check_phase_f8_weekly_governance.sh`

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

**Metadata da issue**
- **Owner**: `tech-lead-trading`
- **Estimativa**: `0.5d`
- **Dependencias**: `Makefile`, `scripts/ci/run_phase_f8_weekly_governance.sh`, `scripts/ci/check_phase_f8_weekly_governance.sh`, `artifacts/phase-f8/weekly-governance/2026-W09.md`, `artifacts/phase-f8/weekly-governance/logs/2026-W09/*.log`
- **Mapped requirements**: `R2`
- **Prioridade**: `P1`
- **Checklist QA/Repro**:
  1. validar fail-fast: `eval-gates=FAIL` deve impedir `ci-quality` e `ci-security`;
  2. validar fail-fast: `ci-quality=FAIL` deve impedir `ci-security`;
  3. validar no checker semanal que qualquer combinacao fora da formula fechada gera `decision=hold`;
  4. validar logs de skip (`SKIPPED`) para gates nao executados.
- **Evidence refs**: `scripts/ci/run_phase_f8_weekly_governance.sh`, `scripts/ci/check_phase_f8_weekly_governance.sh`, `artifacts/phase-f8/epic-f8-01-issue-02-fail-fast-promotion-block.md`

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

**Metadata da issue**
- **Owner**: `pm`
- **Estimativa**: `0.5d`
- **Dependencias**: `Makefile`, `scripts/ci/run_phase_f8_weekly_governance.sh`, `scripts/ci/check_phase_f8_weekly_governance.sh`, `artifacts/phase-f8/weekly-governance/2026-W09.md`, `artifacts/phase-f8/weekly-governance/logs/2026-W09/*.log`
- **Mapped requirements**: `R3`
- **Prioridade**: `P2`
- **Checklist QA/Repro**:
  1. validar ordem e completude dos campos obrigatorios do report semanal;
  2. validar coerencia entre `weekly-governance` e `validation-summary` da mesma semana;
  3. rodar `bash scripts/ci/check_phase_f8_weekly_governance.sh`;
  4. rodar `make ci-quality` e confirmar enforce do checker semanal.
- **Evidence refs**: `artifacts/phase-f8/weekly-governance/2026-W09.md`, `artifacts/phase-f8/validation-summary-2026-W09.md`, `scripts/ci/check_phase_f8_weekly_governance.sh`

**Plano TDD**
1. `Red`: manter evidencias dispersas sem relatorio padronizado.
2. `Green`: consolidar um relatorio semanal unico com resultados e plano de acao.
3. `Refactor`: revisar links e consistencia com `make ci-quality`.

**Criterios de aceitacao**
- Given relatorio semanal ausente, When revisao de fase ocorre, Then decisao deve ser `hold`.
- Given relatorio semanal completo, When revisao de fase ocorre, Then evidencias ficam auditaveis e reutilizaveis.

### ISSUE-F8-01-04 - Materializar trilha minima de microtask em `runs` e check de coerencia arquitetural
**User story**  
Como operador, quero trilha minima por microtask para garantir auditabilidade atomica entre issue-level e execucao real.

**Metadata da issue**
- **Owner**: `tech-lead`
- **Estimativa**: `1.5d`
- **Dependencias**: `PRD/PRD-MASTER.md`, `ARC/schemas/architecture_consistency_backlog.schema.json`, `PM/audit/ARCH-CONSISTENCY-BACKLOG-2026-03-01.json`, `scripts/ci/check_architecture_consistency_backlog.sh`, `scripts/ci/check_quality.sh`, `Makefile`
- **Mapped requirements**: `R10`
- **Prioridade**: `P0`
- **Checklist QA/Repro**:
  1. criar trilha minima de `runs/<issue_id>/<microtask_id>/` no repositorio;
  2. validar schema e backlog JSON com micro-issues contendo `owner`, `estimate`, `acceptance_checks`, `evidence_targets`;
  3. executar `bash scripts/ci/check_architecture_consistency_backlog.sh`;
  4. executar `make architecture-consistency-backlog-check` e `make ci-quality`.
- **Evidence refs**: `artifacts/phase-f8/epic-f8-01-issue-04-microtask-run-ledger-coherence-check.md`, `PM/audit/ARCH-CONSISTENCY-BACKLOG-2026-03-01.json`, `scripts/ci/check_architecture_consistency_backlog.sh`

**Micro-issues executaveis**
- `MT-F8-01-04-01`: template canonico de `runs` para trilha por microtask.
- `MT-F8-01-04-02`: schema e backlog JSON com contrato de micro-issue auditavel.
- `MT-F8-01-04-03`: checker de coerencia arquitetural integrado ao `ci-quality`.

**Plano TDD**
1. `Red`: manter contrato de microtask apenas declarativo, sem trilha minima no repo.
2. `Green`: publicar trilha minima de `runs` + schema + backlog e validar por checker dedicado.
3. `Refactor`: integrar o checker no `ci-quality` e manter relacao explicita entre issue e micro-issues.

**Criterios de aceitacao**
- Given conflito `C-03` ou failure mode `FM-08` sem remediacao vinculada, When checker roda, Then resultado deve ser `FAIL`.
- Given backlog JSON completo com micro-issues auditaveis e links validos, When checker roda, Then resultado deve ser `PASS`.

## Artifact Minimo do Epico
- registrar relatorio semanal em `artifacts/phase-f8/weekly-governance/<week_id>.md` contendo obrigatoriamente:
  - `week_id` (`YYYY-Www`)
  - `executed_at`
  - `prior_phase_decision`
  - `phase_transition_status`
  - `blocking_reason`
  - `operational_readiness` (`blocked|hold|ready`)
  - `review_validity_status` (`PASS|FAIL`)
  - `operational_conformance_status` (`PASS|FAIL`)
  - `failed_domains` (`none|runtime,integrations,trading,security`)
  - `eval_gates_status` (`PASS|FAIL`)
  - `ci_quality_status` (`PASS|FAIL`)
  - `ci_security_status` (`PASS|FAIL`)
  - `critical_drifts_open`
  - `decision` (`promote|hold`)
  - `risk_notes`
  - `next_actions`

## Resultado desta Rodada
- `make eval-gates` final: `PASS` (`eval-gates: PASS`).
- `make ci-quality` final: `PASS` (`quality-check: PASS`).
- `make ci-security` final: `PASS` (`security-check: PASS`).
- evidencias por issue publicadas:
  - `artifacts/phase-f8/epic-f8-01-issue-01-weekly-gates-timestamp.md`;
  - `artifacts/phase-f8/epic-f8-01-issue-02-fail-fast-promotion-block.md`;
  - `artifacts/phase-f8/epic-f8-01-issue-03-weekly-report-actions.md`.
- evidencias consolidadas:
  - `artifacts/phase-f8/weekly-governance/2026-W09.md`;
  - `artifacts/phase-f8/epic-f8-01-weekly-governance.md`.
- decisao semanal atual: `hold`.
- justificativa: `review_validity_status=PASS`, `operational_conformance_status=FAIL`, `failed_domains=trading`, `critical_drifts_open=1` e `phase_transition_status=blocked`.
- conclusao: `EPIC-F8-01` concluido no escopo documental/tdd desta rodada.

## Dependencias
- [Makefile](../../../../Makefile)
- [Dev CI Rules](../../../../DEV/DEV-CI-RULES.md)
- [Phase Usability Guide](../../../../PRD/PHASE-USABILITY-GUIDE.md)
- [Eval Gates Script](../../../../scripts/ci/eval_gates.sh)
