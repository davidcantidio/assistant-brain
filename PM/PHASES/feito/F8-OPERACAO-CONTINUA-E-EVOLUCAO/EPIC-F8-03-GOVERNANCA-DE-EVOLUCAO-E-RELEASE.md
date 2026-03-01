---
doc_id: "EPIC-F8-03-GOVERNANCA-DE-EVOLUCAO-E-RELEASE.md"
version: "1.4"
status: "active"
owner: "PM"
last_updated: "2026-03-01"
rfc_refs: ["RFC-001", "RFC-015", "RFC-040", "RFC-050", "RFC-060"]
---

# EPIC-F8-03 Governanca de evolucao e release

## Objetivo
Fechar cada ciclo semanal com decisao formal `promote|hold`, trilha de risco residual e plano de continuidade para evolucao sem regressao.

## Resultado de Negocio Mensuravel
- decisoes semanais de evolucao passam a ser explicitas, auditaveis e reproduziveis.
- risco residual e rollback ficam registrados antes de cada promocao.

## Definition of Done (Scrum)
- todas as issues do epico em estado `Done`.
- trio de gates (`eval-gates`, `ci-quality`, `ci-security`) com `PASS` no ciclo semanal.
- decisao semanal registrada com `promote|hold` e justificativa.

## Contexto normativo desta rodada
- fonte de verdade: `PRD/PRD-MASTER.md`, `PRD/ROADMAP.md`, `PRD/PHASE-USABILITY-GUIDE.md`, `PM/DECISION-PROTOCOL.md`, `EVALS/SYSTEM-HEALTH-THRESHOLDS.md` e `PRD/CHANGELOG.md`.
- a `F8` permanece em estado `planned` no planejamento da fase, sem novo enum de status.
- a ativacao prematura da `F8` MUST ser recuada documentalmente enquanto a decisao `F7 -> F8` permanecer `hold`.
- este epico consolida a trilha de release e auditoria da `F8`, mas NAO substitui a promocao formal entre fases.

## Issues (Scrum + TDD + Criterios de Aceitacao)

### ISSUE-F8-03-01 - Validar criterios de decisao semanal promote hold baseados no trio de gates drifts e decisao da fase anterior
**User story**  
Como operador, quero criterios objetivos de decisao semanal para evitar promocao por percepcao subjetiva.

**Metadata da issue**
- **Owner**: `product-owner + tech-lead-trading`
- **Estimativa**: `0.5d`
- **Dependencias**: `artifacts/phase-f7/validation-summary.md`, `scripts/ci/phase_f8_release_governance.py`, `scripts/ci/run_phase_f8_weekly_governance.sh`, `artifacts/phase-f8/weekly-governance/2026-W09.md`, `artifacts/phase-f8/validation-summary-2026-W09.md`
- **Mapped requirements**: `R7`, `R6`
- **Prioridade**: `P0`
- **Checklist QA/Repro**:
  1. validar leitura de `prior_phase_decision` a partir do summary da F7;
  2. validar formula de `decision` com gates, drifts e fase anterior;
  3. validar bloqueio explícito com `phase_transition_status=blocked` enquanto `F7 -> F8` estiver `hold`;
  4. rodar `make phase-f8-weekly-governance` e conferir resultado `hold`.
- **Evidence refs**: `artifacts/phase-f7/validation-summary.md`, `scripts/ci/phase_f8_release_governance.py`, `artifacts/phase-f8/weekly-governance/2026-W09.md`

**Plano TDD**
1. `Red`: considerar promocao sem validar gates, drifts e a decisao `F7 -> F8`.
2. `Green`: decidir `promote|hold` com base no trio de gates, status de drifts criticos e `prior_phase_decision`.
3. `Refactor`: padronizar criterio de decisao no sumario semanal com recuo formal da ativacao da `F8`.

**Criterios de aceitacao**
- Given qualquer gate em `FAIL`, drift critico aberto ou `prior_phase_decision != promote`, When decisao semanal e tomada, Then resultado deve ser `hold`.
- Given trio de gates em `PASS`, sem drift critico pendente e `prior_phase_decision=promote`, When decisao semanal e tomada, Then resultado pode ser `promote`.

### ISSUE-F8-03-02 - Registrar risco residual rollback e acoes da proxima semana
**User story**  
Como operador, quero registrar risco residual e rollback para manter continuidade segura entre ciclos semanais.

**Metadata da issue**
- **Owner**: `pm`
- **Estimativa**: `0.5d`
- **Dependencias**: `artifacts/phase-f7/validation-summary.md`, `scripts/ci/phase_f8_release_governance.py`, `scripts/ci/run_phase_f8_weekly_governance.sh`, `artifacts/phase-f8/weekly-governance/2026-W09.md`, `artifacts/phase-f8/validation-summary-2026-W09.md`
- **Mapped requirements**: `R8`
- **Prioridade**: `P1`
- **Checklist QA/Repro**:
  1. validar presença de `release_justification`, `residual_risk_summary`, `rollback_plan`, `next_actions`;
  2. validar consistência desses campos entre weekly report e validation summary;
  3. validar que o pacote permanece não vazio para `decision=hold`;
  4. rodar `bash scripts/ci/check_phase_f8_weekly_governance.sh`.
- **Evidence refs**: `artifacts/phase-f8/weekly-governance/2026-W09.md`, `artifacts/phase-f8/validation-summary-2026-W09.md`, `artifacts/phase-f8/epic-f8-03-issue-02-residual-risk-rollback.md`

**Plano TDD**
1. `Red`: registrar decisao semanal sem risco residual/rollback.
2. `Green`: incluir risco residual, estrategia de rollback e acoes da semana seguinte.
3. `Refactor`: alinhar plano semanal com backlog de remediacao de drift e baseline vigente da `F7/F8-02`.

**Criterios de aceitacao**
- Given decisao semanal sem risco residual ou rollback, When revisao de release ocorre, Then resultado deve ser `hold`.
- Given decisao semanal com risco residual/rollback/next actions, When revisao de release ocorre, Then criterio de continuidade fica `pass`.

### ISSUE-F8-03-03 - Consolidar sumario executivo semanal para auditoria e continuidade operacional
**User story**  
Como operador, quero um sumario executivo semanal para auditoria rapida e handoff sem lacunas.

**Metadata da issue**
- **Owner**: `pm + tech-lead-trading`
- **Estimativa**: `0.5d`
- **Dependencias**: `artifacts/phase-f7/validation-summary.md`, `scripts/ci/phase_f8_release_governance.py`, `scripts/ci/run_phase_f8_weekly_governance.sh`, `artifacts/phase-f8/weekly-governance/2026-W09.md`, `artifacts/phase-f8/validation-summary-2026-W09.md`
- **Mapped requirements**: `R9`, `R8`
- **Prioridade**: `P1`
- **Checklist QA/Repro**:
  1. validar ordem dos campos executivos no topo do summary (`operational_readiness`, `decision`, `phase_transition_status`, `failed_domains`, `critical_drifts_open`);
  2. validar coerência total entre weekly report e validation summary;
  3. validar status dos EPICs `F8-01..04` no summary;
  4. rodar `make ci-quality` e confirmar verificação integrada.
- **Evidence refs**: `artifacts/phase-f8/validation-summary-2026-W09.md`, `artifacts/phase-f8/weekly-governance/2026-W09.md`, `artifacts/phase-f8/epic-f8-03-issue-03-executive-summary-audit.md`

**Plano TDD**
1. `Red`: manter evidencias semanais dispersas em multiplos locais.
2. `Green`: consolidar sumario unico com status de gates, drifts, decisao e proximos passos.
3. `Refactor`: validar coerencia de links e referencias com `make ci-quality`.

**Criterios de aceitacao**
- Given sumario semanal ausente, When auditoria semanal ocorre, Then resultado deve ser `hold`.
- Given sumario semanal completo e coerente, When auditoria semanal ocorre, Then continuidade operacional fica rastreavel.

### ISSUE-F8-03-04 - Normalizar fonte de autoridade arquitetural
**User story**  
Como operador, quero fonte de autoridade unica para evitar conflito entre PRD e referencia conceitual Felix.

**Metadata da issue**
- **Owner**: `pm + architecture-owner`
- **Estimativa**: `1d`
- **Dependencias**: `META/DOCUMENT-HIERARCHY.md`, `README.md`, `workspaces/main/AGENTS.md`, `PRD/PRD-MASTER.md`, `PRD/CHANGELOG.md`
- **Mapped requirements**: `R13`
- **Prioridade**: `P0`
- **Checklist QA/Repro**:
  1. validar que PRD/SEC/ARC ficam explicitos como fonte normativa;
  2. validar que Felix fica definido como referencia conceitual com traceabilidade;
  3. validar consistencia de mensagem entre `META`, `README` e `AGENTS`;
  4. executar `bash scripts/ci/check_architecture_consistency_backlog.sh`.
- **Evidence refs**: `artifacts/phase-f8/epic-f8-03-issue-04-authority-source-normalization.md`, `artifacts/architecture/2026-03-01-architectural-consistency-audit-backlog.md`

**Micro-issues executaveis**
- `MT-F8-03-04-01`: ajustar precedencia documental em `META` e `PRD`.
- `MT-F8-03-04-02`: alinhar texto operacional em `README` e `AGENTS`.
- `MT-F8-03-04-03`: registrar decisao no changelog e backlog arquitetural.

**Plano TDD**
1. `Red`: manter precedencia paralela sem regra de resolucao de conflito.
2. `Green`: explicitar fonte normativa unica e relegar Felix a referencia importada.
3. `Refactor`: consolidar rastreabilidade de override no changelog.

**Criterios de aceitacao**
- Given conflito de precedencia documental, When checker roda, Then resultado deve ser `FAIL`.
- Given precedencia unica com evidencias de alinhamento, When checker roda, Then resultado deve ser `PASS`.

### ISSUE-F8-03-05 - Formalizar branch governance e ownership de PR
**User story**  
Como operador, quero ownership e policy de branch enforceaveis para manter trilha de release sem ambiguidade.

**Metadata da issue**
- **Owner**: `tech-lead`
- **Estimativa**: `1d`
- **Dependencias**: `.github/CODEOWNERS`, `DEV/DEV-CI-RULES.md`, `scripts/ci/check_pr_governance.sh`, `scripts/ci/check_quality.sh`
- **Mapped requirements**: `R14`
- **Prioridade**: `P0`
- **Checklist QA/Repro**:
  1. validar regra global e cobertura minima no `CODEOWNERS`;
  2. validar termos normativos de branch policy em `DEV/DEV-CI-RULES.md`;
  3. executar `bash scripts/ci/check_pr_governance.sh`;
  4. executar `make ci-quality`.
- **Evidence refs**: `artifacts/phase-f8/epic-f8-03-issue-05-branch-governance-codeowners-enforcement.md`, `.github/CODEOWNERS`, `scripts/ci/check_pr_governance.sh`

**Micro-issues executaveis**
- `MT-F8-03-05-01`: consolidar `CODEOWNERS`.
- `MT-F8-03-05-02`: harmonizar policy de branch no `DEV`.
- `MT-F8-03-05-03`: manter enforcement automatizado no CI.

**Plano TDD**
1. `Red`: permitir governanca de PR sem ownership enforceavel.
2. `Green`: consolidar ownership + policy + checker no pipeline de qualidade.
3. `Refactor`: reduzir falsos positivos mantendo regras minimas explicitas.

**Criterios de aceitacao**
- Given arquivo de ownership ausente ou policy incompleta, When checker roda, Then resultado deve ser `FAIL`.
- Given ownership e policy validos com enforcement CI, When checker roda, Then resultado deve ser `PASS`.

### ISSUE-F8-03-06 - Harmonizar pipeline `M30 -> M14-Code -> Codex 5` com ARC/DEV/PM
**User story**  
Como operador, quero pipeline multi-modelo alinhado aos contratos canonicos para evitar governanca paralela.

**Metadata da issue**
- **Owner**: `architecture-owner + tech-lead`
- **Estimativa**: `1.75d`
- **Dependencias**: `PRD/PRD-MASTER.md`, `PRD/CHANGELOG.md`, `ARC/ARC-MODEL-ROUTING.md`, `DEV/DEV-TECH-LEAD-SPEC.md`, `DEV/DEV-JUNIOR-SPEC.md`, `PM/DECISION-PROTOCOL.md`
- **Mapped requirements**: `R15`
- **Prioridade**: `P1`
- **Checklist QA/Repro**:
  1. declarar se pipeline e `proposta` ou `norma` no PRD;
  2. validar coerencia de papeis em `ARC/DEV/PM`;
  3. validar cobertura da remediacao no backlog maquina-consumivel;
  4. executar `bash scripts/ci/check_architecture_consistency_backlog.sh` e `make ci-quality`.
- **Evidence refs**: `artifacts/phase-f8/epic-f8-03-issue-06-multi-model-pipeline-contract-harmonization.md`, `artifacts/architecture/2026-03-01-multi-model-pipeline-impact.md`

**Micro-issues executaveis**
- `MT-F8-03-06-01`: fixar status proposta/norma no PRD.
- `MT-F8-03-06-02`: alinhar contratos `ARC/DEV/PM` com o status definido.
- `MT-F8-03-06-03`: manter gate de coerencia arquitetural no CI.

**Plano TDD**
1. `Red`: manter pipeline declarado sem status normativo fechado.
2. `Green`: definir status e harmonizar contratos tocados no mesmo ciclo.
3. `Refactor`: garantir que checker impeça regressao de coerencia.

**Criterios de aceitacao**
- Given pipeline com status ambiguo, When checker roda, Then resultado deve ser `FAIL`.
- Given status fechado e contratos harmonizados, When checker roda, Then resultado deve ser `PASS`.

## Artifact Minimo do Epico
- registrar sumario em `artifacts/phase-f8/validation-summary-<week_id>.md` com:
  - status de `eval-gates`, `ci-quality`, `ci-security`;
  - status dos epicos `EPIC-F8-01..EPIC-F8-04`;
  - decisao `promote|hold` e justificativa;
  - risco residual, rollback e `next_actions`.

## Resultado desta Rodada
- `make eval-gates` final: `PASS`.
- `make phase-f8-weekly-governance` final: `hold`.
- `make ci-quality` final: `PASS`.
- `make ci-security` final: `PASS`.
- evidencias por issue publicadas:
  - `artifacts/phase-f8/epic-f8-03-issue-01-weekly-decision-criteria.md`;
  - `artifacts/phase-f8/epic-f8-03-issue-02-residual-risk-rollback.md`;
  - `artifacts/phase-f8/epic-f8-03-issue-03-executive-summary-audit.md`.
- evidencias consolidadas:
  - `artifacts/phase-f8/weekly-governance/2026-W09.md`;
  - `artifacts/phase-f8/validation-summary-2026-W09.md`;
  - `artifacts/phase-f8/epic-f8-03-governanca-evolucao-release.md`.
- decisao semanal atual: `hold`.
- justificativa:
  - `critical_drifts_open=1`;
  - `prior_phase_decision=hold`;
  - `phase_transition_status=blocked`.
- conclusao: `EPIC-F8-03` concluido no escopo documental/tdd desta rodada, sem promover automaticamente a fase `F8`.

## Dependencias
- [PRD Master](../../../../PRD/PRD-MASTER.md)
- [Decision Protocol](../../../../PM/DECISION-PROTOCOL.md)
- [Roadmap](../../../../PRD/ROADMAP.md)
- [Phase Usability Guide](../../../../PRD/PHASE-USABILITY-GUIDE.md)
- [System Health Thresholds](../../../../EVALS/SYSTEM-HEALTH-THRESHOLDS.md)
