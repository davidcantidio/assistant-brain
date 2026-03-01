---
doc_id: "EPIC-F8-02-REVISAO-PERIODICA-DE-CONTRATOS-E-DRIFT.md"
version: "1.3"
status: "active"
owner: "PM"
last_updated: "2026-03-01"
rfc_refs: ["RFC-001", "RFC-015", "RFC-030", "RFC-050", "RFC-060"]
---

# EPIC-F8-02 Revisao periodica de contratos e drift

## Objetivo
Identificar e tratar drift normativo/contratual de forma recorrente para preservar coerencia entre runtime, integracoes, trading e seguranca.

## Resultado de Negocio Mensuravel
- drifts criticos passam a ter detecao recorrente e tratamento rastreavel.
- promocao semanal fica condicionada ao fechamento efetivo de pendencias criticas.

## Definition of Done (Scrum)
- todas as issues do epico em estado `Done`.
- `make eval-gates` executado com sucesso no ciclo semanal.
- revisao semanal sem drift critico pendente sem owner/prazo.

## Issues (Scrum + TDD + Criterios de Aceitacao)

### ISSUE-F8-02-01 - Revisar contratos criticos e registrar conformidade
**User story**  
Como operador, quero revisar contratos criticos periodicamente para detectar incoerencias antes de virarem incidente.

**Metadata da issue**
- **Owner**: `tech-lead-trading`
- **Estimativa**: `1d`
- **Dependencias**: `scripts/ci/phase_f8_contract_review.py`, `scripts/ci/read_phase_f8_contract_review.sh`, `artifacts/phase-f8/contract-review/2026-W09.md`, `artifacts/phase-f8/weekly-governance/2026-W09.md`, `PM/DECISION-PROTOCOL.md`
- **Mapped requirements**: `R4`
- **Prioridade**: `P0`
- **Checklist QA/Repro**:
  1. rodar `make phase-f8-contract-review` e validar parsing dos quatro dominios obrigatorios;
  2. validar metadata nova: `review_validity_status`, `operational_conformance_status`, `failed_domains`, `critical_drifts_open`;
  3. validar export em env via `scripts/ci/read_phase_f8_contract_review.sh`;
  4. validar consumo do artifact no weekly governance.
- **Evidence refs**: `artifacts/phase-f8/contract-review/2026-W09.md`, `scripts/ci/phase_f8_contract_review.py`, `scripts/ci/read_phase_f8_contract_review.sh`

**Plano TDD**
1. `Red`: executar ciclo semanal sem revisao explicita de contratos criticos.
2. `Green`: revisar contratos de runtime, integracoes, trading e seguranca e registrar conformidade.
3. `Refactor`: padronizar formato de registro para comparacao semanal.

**Criterios de aceitacao**
- Given revisao contratual ausente, When fechamento semanal ocorre, Then resultado deve ser `hold`.
- Given revisao contratual concluida com evidencias, When fechamento semanal ocorre, Then item de conformidade fica `pass`.

### ISSUE-F8-02-02 - Abrir backlog de remediacao para cada drift encontrado com owner e prazo
**User story**  
Como operador, quero que cada drift detectado tenha dono e prazo para evitar pendencia cronica sem acao.

**Metadata da issue**
- **Owner**: `product-owner + tech-lead-trading`
- **Estimativa**: `0.5d`
- **Dependencias**: `scripts/ci/phase_f8_contract_review.py`, `scripts/ci/read_phase_f8_contract_review.sh`, `artifacts/phase-f8/contract-review/2026-W09.md`, `artifacts/phase-f8/weekly-governance/2026-W09.md`, `PM/DECISION-PROTOCOL.md`
- **Mapped requirements**: `R5`
- **Prioridade**: `P1`
- **Checklist QA/Repro**:
  1. validar `owner`, `due_date`, `evidence_ref` e severidade por drift;
  2. validar regra `risk_accepted => risk_exception_ref` obrigatoria;
  3. validar propagacao de `critical_drifts_open` para governanca semanal;
  4. rodar `make ci-quality` e confirmar validação do contrato.
- **Evidence refs**: `artifacts/phase-f8/contract-review/2026-W09.md`, `artifacts/phase-f8/epic-f8-02-issue-02-drift-remediation-backlog.md`, `scripts/ci/phase_f8_contract_review.py`

**Plano TDD**
1. `Red`: registrar drift sem owner/prazo.
2. `Green`: abrir backlog de remediacao com owner, prazo e referencia de evidencia.
3. `Refactor`: agrupar drifts por severidade e impacto no gate semanal.

**Criterios de aceitacao**
- Given drift sem owner ou prazo, When revisao semanal ocorre, Then resultado deve ser `hold`.
- Given drifts com owner/prazo definidos, When revisao semanal ocorre, Then backlog de remediacao fica conforme.

### ISSUE-F8-02-03 - Validar fechamento de drifts da semana anterior antes de nova promocao
**User story**  
Como operador, quero validar fechamento dos drifts anteriores para evitar acumulacao de risco residual.

**Metadata da issue**
- **Owner**: `product-owner + tech-lead-trading`
- **Estimativa**: `1d`
- **Dependencias**: `scripts/ci/phase_f8_contract_review.py`, `scripts/ci/read_phase_f8_contract_review.sh`, `artifacts/phase-f8/contract-review/2026-W09.md`, `artifacts/phase-f8/weekly-governance/2026-W09.md`, `PM/DECISION-PROTOCOL.md`
- **Mapped requirements**: `R6`
- **Prioridade**: `P0`
- **Checklist QA/Repro**:
  1. validar que `previous_week_id` segue ISO week e aceita `none` apenas sem semana anterior real;
  2. validar `carried_over_drifts` somente com `closed|risk_accepted|open`;
  3. validar `risk_accepted` com `risk_exception_ref` obrigatorio;
  4. validar, na rodada real `2026-W10`, que todo drift critico herdado de `2026-W09` foi classificado.
- **Evidence refs**: `artifacts/phase-f8/contract-review/2026-W09.md`, `artifacts/phase-f8/epic-f8-02-issue-03-prior-week-critical-drift-closure.md`, `scripts/ci/phase_f8_contract_review.py`

**Plano TDD**
1. `Red`: permitir promocao com drift critico herdado da semana anterior.
2. `Green`: bloquear promocao ate fechamento ou excecao formal de risco.
3. `Refactor`: registrar status de fechamento no relatorio da semana atual.

**Criterios de aceitacao**
- Given drift critico anterior aberto, When promocao semanal e avaliada, Then resultado deve ser `hold`.
- Given drifts criticos anteriores fechados, When promocao semanal e avaliada, Then item de continuidade fica `pass`.

### ISSUE-F8-02-04 - Normalizar cadeia `PRD -> Fases -> Epicos -> Issues -> Microtasks`
**User story**  
Como operador, quero cadeia estrutural unica para eliminar sobreposicao entre `task` generica e `Issue/Microtask` contratual.

**Metadata da issue**
- **Owner**: `pm`
- **Estimativa**: `1.25d`
- **Dependencias**: `PRD/PRD-MASTER.md`, `PRD/ROADMAP.md`, `PM/SCRUM-GOV.md`, `PM/WORK-ORDER-SPEC.md`, `artifacts/architecture/2026-03-01-architectural-consistency-audit-backlog.md`
- **Mapped requirements**: `R11`
- **Prioridade**: `P0`
- **Checklist QA/Repro**:
  1. alinhar `PM/SCRUM-GOV.md` a cadeia canonica sem remover uso de sprint como capacidade;
  2. validar consistencia terminologica entre `PRD/ROADMAP.md` e `PRD/PRD-MASTER.md`;
  3. publicar glossario anti-ambiguidade em `PM/WORK-ORDER-SPEC.md`;
  4. executar `bash scripts/ci/check_architecture_consistency_backlog.sh`.
- **Evidence refs**: `artifacts/phase-f8/epic-f8-02-issue-04-planning-chain-normalization.md`, `PM/audit/ARCH-CONSISTENCY-BACKLOG-2026-03-01.json`

**Micro-issues executaveis**
- `MT-F8-02-04-01`: alinhar `SCRUM-GOV` com cadeia canonica.
- `MT-F8-02-04-02`: sincronizar `ROADMAP` e `PRD-MASTER` na mesma taxonomia.
- `MT-F8-02-04-03`: publicar glossario anti-ambiguidade de planejamento.

**Plano TDD**
1. `Red`: manter coexistencia indefinida de `task` e `microtask` sem regra de precedencia.
2. `Green`: canonizar cadeia unica com sprint como recipiente de capacidade.
3. `Refactor`: remover linguagem ambigua e consolidar termos em glossario.

**Criterios de aceitacao**
- Given cadeia mista sem regra formal, When checker de backlog roda, Then resultado deve ser `FAIL`.
- Given cadeia unica e glossario alinhado, When checker de backlog roda, Then resultado deve ser `PASS`.

### ISSUE-F8-02-05 - Mapear dependencias externas como governadas ou fora de escopo
**User story**  
Como operador, quero classificar dependencias externas para evitar expansao implicita de superficie operacional.

**Metadata da issue**
- **Owner**: `security-owner + pm`
- **Estimativa**: `1.25d`
- **Dependencias**: `INTEGRATIONS/README.md`, `config/openclaw.env.example`, `SEC/SEC-POLICY.md`, `SEC/SEC-PROMPT-INJECTION.md`, `felix-openclaw-pontos-relevantes.md`
- **Mapped requirements**: `R12`
- **Prioridade**: `P1`
- **Checklist QA/Repro**:
  1. classificar cada superficie externa em `governada` ou `fora_de_escopo`;
  2. refletir classificacao no `env example` sem remover capacidade tecnica existente;
  3. alinhar limites e responsabilidades na policy de seguranca;
  4. executar `bash scripts/ci/check_architecture_consistency_backlog.sh`.
- **Evidence refs**: `artifacts/phase-f8/epic-f8-02-issue-05-external-dependencies-governance-map.md`, `PM/audit/ARCH-CONSISTENCY-BACKLOG-2026-03-01.json`

**Micro-issues executaveis**
- `MT-F8-02-05-01`: mapa de superficies em `INTEGRATIONS/README.md`.
- `MT-F8-02-05-02`: classificacao das variaveis em `config/openclaw.env.example`.
- `MT-F8-02-05-03`: alinhamento de limites em `SEC/SEC-POLICY.md`.

**Plano TDD**
1. `Red`: manter superficie externa implcita sem classificacao formal.
2. `Green`: publicar classificacao binaria por superficie com ownership.
3. `Refactor`: reforcar limites de seguranca para capacidades opcionais.

**Criterios de aceitacao**
- Given dependencia externa sem status normativo, When checker de backlog roda, Then resultado deve ser `FAIL`.
- Given toda dependencia classificada com evidencia, When checker de backlog roda, Then resultado deve ser `PASS`.

## Artifact Minimo do Epico
- registrar revisao em `artifacts/phase-f8/contract-review/<week_id>.md` com:
  - lista de contratos revisados;
  - drifts detectados por severidade;
  - owner/prazo por drift;
  - status de fechamento da semana anterior.

## Resultado desta Rodada
- `make phase-f8-contract-review` final: `PASS`.
- `make ci-quality` final: `PASS`.
- evidencias por issue publicadas:
  - `artifacts/phase-f8/epic-f8-02-issue-01-contract-review-conformity.md`;
  - `artifacts/phase-f8/epic-f8-02-issue-02-drift-remediation-backlog.md`;
  - `artifacts/phase-f8/epic-f8-02-issue-03-prior-week-critical-drift-closure.md`.
- evidencias consolidadas:
  - `artifacts/phase-f8/contract-review/2026-W09.md`;
  - `artifacts/phase-f8/weekly-governance/2026-W09.md`;
  - `artifacts/phase-f8/epic-f8-02-contract-review-drift.md`.
- decisao semanal atual: `hold`.
- justificativa: `DRIFT-F8-2026-W09-01` permanece `critical/open`, com `review_validity_status=PASS`, `operational_conformance_status=FAIL` e `failed_domains=trading`.
- carry-over real:
  - o fechamento de auditoria de `ISSUE-F8-02-03` depende da primeira rodada operacional real `2026-W10`;
  - nesta rodada `2026-W10`, `previous_week_id` deve ser `2026-W09` e `carried_over_drifts` deve classificar `DRIFT-F8-2026-W09-01` como `closed`, `risk_accepted` (com `risk_exception_ref`) ou `open`;
  - nenhum artifact sintetico `2026-W10` deve ser publicado antes da semana real.
- conclusao: `EPIC-F8-02` concluido no escopo documental/tdd desta rodada.

## Dependencias
- [PRD Master](../../../../PRD/PRD-MASTER.md)
- [Integrations README](../../../../INTEGRATIONS/README.md)
- [Trading Enablement Criteria](../../../../VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md)
- [Security Policy](../../../../SEC/SEC-POLICY.md)
- [System Health Thresholds](../../../../EVALS/SYSTEM-HEALTH-THRESHOLDS.md)
