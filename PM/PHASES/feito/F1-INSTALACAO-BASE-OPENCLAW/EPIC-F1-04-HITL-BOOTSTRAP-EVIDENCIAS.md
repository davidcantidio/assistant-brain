---
doc_id: "EPIC-F1-04-HITL-BOOTSTRAP-EVIDENCIAS.md"
version: "1.2"
status: "active"
owner: "PM"
last_updated: "2026-03-01"
rfc_refs: ["RFC-001", "RFC-010", "RFC-015", "RFC-040", "RFC-050", "RFC-060"]
---

# EPIC-F1-04 HITL bootstrap e pacote de evidencias de fase

## Objetivo
Fechar a F1 com prontidao operacional humana minima (canal confiavel + baseline de seguranca) e evidencia auditavel para promover a F2.

## Resultado de Negocio Mensuravel
- operador consegue executar fluxo humano critico com canal confiavel definido.
- fase `F1` termina com evidencias auditaveis consolidadas para governanca.

## Definition of Done (Scrum)
- todas as issues do epico em estado `Done`.
- `make ci-security` executado com sucesso.
- `make ci-quality` executado com sucesso.
- artifact unico de validacao de fase consolidado e referenciado.

## Issues (Scrum + TDD + Criterios de Aceitacao)

### ISSUE-F1-04-01 - Validar baseline de seguranca e allowlists
**User story**  
Como operador, quero validar as allowlists e policy de seguranca no bootstrap para evitar operacao fora de conformidade.

**Metadados de governanca (DoR/DoD)**
- objetivo_verificavel: `baseline de seguranca cobrindo allowlist, secrets, redaction e ZDR`
- risk_tier: `R2`
- owner_issue: `Compliance/Security`
- estimativa: `1 dia util`
- dependencias: `SEC/SEC-POLICY.md`, `SEC/allowlists`, `make ci-security`, `PRD/PRD-MASTER.md`
- inputs_minimos: policy de seguranca, allowlists vigentes, regras de redaction e politica ZDR para dados sensiveis
- gate_path: `Ready -> Decomposed -> InProgress -> Verify -> Review/Gate -> Done`
- evidence_refs_obrigatorios:
  - `artifacts/phase-f1/validation-summary.md`
  - `stdout://make ci-security`

**Plano TDD**
1. `Red`: simular baseline com arquivo de allowlist ausente/invalidado.
2. `Green`: restaurar baseline canonico de allowlists e policy.
3. `Refactor`: executar `make ci-security` e registrar resultado.

**Criterios de aceitacao**
- Given allowlist canonica ausente/invalida, When `make ci-security` roda, Then o check falha.
- Given baseline de seguranca canonico, When `make ci-security` roda, Then retorna `security-check: PASS`.
- Given secrets, redaction ou politica ZDR divergentes do contrato, When `make ci-security` ou revisao documental roda, Then a issue reprova.
- Given dados/classificacoes `sensitive`, When a conformidade e revisada, Then provider allowlist restrita, ZDR e minimizacao de armazenamento ficam explicitadas no artifact.

### ISSUE-F1-04-02 - Validar checklist humano de canal confiavel (HITL)
**User story**  
Como operador, quero confirmar o canal humano confiavel para comandos criticos antes de promover a fase.

**Metadados de governanca (DoR/DoD)**
- objetivo_verificavel: `checklist HITL tecnico completo, fail-closed e aderente a approval_policy`
- risk_tier: `R3`
- owner_issue: `Compliance/Security`
- estimativa: `1 dia util`
- dependencias: `PM/DECISION-PROTOCOL.md`, `SEC/SEC-POLICY.md`, `PRD/PRD-MASTER.md`, `artifacts/phase-f1/validation-summary.md`
- inputs_minimos: `checklist_id`, `decision_id`, `risk_tier`, `operator_id`, trusted channels, `items[item_id,evidence_ref,status]`
- gate_path: `Ready -> Decomposed -> InProgress -> Verify -> Review/Gate -> Done`
- evidence_refs_obrigatorios:
  - `artifacts/phase-f1/validation-summary.md`
  - `PM/DECISION-PROTOCOL.md`
  - `SEC/SEC-POLICY.md`

**Plano TDD**
1. `Red`: checklist HITL incompleto (operador/canal nao validado).
2. `Green`: preencher checklist com Telegram primario validado, `decision_id` obrigatorio, `items[]` com `evidence_ref`/`status` e status de fallback Slack explicitamente registrado conforme policy da fase (`pending_f6` no fechamento da F1).
3. `Refactor`: revisar `PM/DECISION-PROTOCOL.md` e `SEC/SEC-POLICY.md` para aderencia fail-closed.

**Criterios de aceitacao**
- Given checklist HITL incompleto, When revisao de fase ocorre, Then promocao para F2 fica bloqueada.
- Given comando recebido apenas por email, When nao houver confirmacao em Telegram ou Slack fallback validado, Then a acao permanece bloqueada e a origem e classificada como `UNTRUSTED_COMMAND_SOURCE`.
- Given checklist sem `decision_id`, `risk_tier`, `operator_id` ou `items[].evidence_ref`, When revisao de fase ocorre, Then o resultado deve ser `hold`.
- Given qualquer item do checklist com `status=fail`, When revisao de fase ocorre, Then a fase permanece fail-closed.
- Given checklist HITL completo com Telegram primario validado e fallback Slack com status explicitamente registrado por policy, When revisao de fase ocorre, Then fase fica apta sob criterio humano de canal confiavel.

### ISSUE-F1-04-03 - Consolidar evidencias da F1 em artifact unico
**User story**  
Como operador, quero um artifact unico da fase para auditoria e handoff operacional sem lacunas.

**Metadados de governanca (DoR/DoD)**
- objetivo_verificavel: `artifact unico da F1 com claims, risco, gates e evidence_refs por issue`
- risk_tier: `R2`
- owner_issue: `QA`
- estimativa: `0.5 dia util`
- dependencias: `artifacts/phase-f1/validation-summary.md`, `make ci-quality`, `EPIC-F1-01..04`
- inputs_minimos: status por issue, `risk_tier`, `Verify`, `Review/Gate`, matriz requirement -> issue -> evidence -> gate
- gate_path: `Ready -> Decomposed -> InProgress -> Verify -> Review/Gate -> Done`
- evidence_refs_obrigatorios:
  - `artifacts/phase-f1/validation-summary.md`
  - `stdout://make ci-quality`

**Plano TDD**
1. `Red`: evidencias dispersas e sem padrao de fechamento.
2. `Green`: consolidar em `artifacts/phase-f1/validation-summary.md`.
3. `Refactor`: validar links/documentos do artifact com `make ci-quality`.

**Criterios de aceitacao**
- Given evidencias consolidadas, When `make ci-quality` roda, Then nao ha links quebrados na documentacao da fase.
- Given artifact sem matriz claim -> gate -> evidence, When gate de fase e revisado, Then o fechamento da issue reprova.
- Given risco `R2`, When a issue conclui `Verify`, Then o fechamento requer `Review/Gate`.
- Given artifact unico concluido, When gate de fase e revisado, Then existe trilha minima para promocao `F1 -> F2`.

## Artifact Minimo do Epico
- `artifacts/phase-f1/validation-summary.md` com:
  - resultado de `onboard` e `verify`;
  - resultado de `ci-quality` e `ci-security`;
  - status dos epicos `EPIC-F1-01..EPIC-F1-04`;
  - decisao de promocao da fase (`promote|hold`) e justificativa.

## Resultado desta Rodada
- `make ci-security` final: `PASS` (`security-check: PASS`).
- `make ci-quality` final: `PASS` (`quality-check: PASS`).
- checklist HITL bootstrap consolidado com Telegram primario validado e fallback Slack pendente para F6 sem bypass de policy.
- evidencia consolidada de fase: `artifacts/phase-f1/validation-summary.md`.
- decisao de fase registrada: `promote` (`F1 -> F2`).

## Dependencias
- [Decision Protocol](../../../../PM/DECISION-PROTOCOL.md)
- [Security Policy](../../../../SEC/SEC-POLICY.md)
- [Phase Usability Guide](../../../../PRD/PHASE-USABILITY-GUIDE.md)
