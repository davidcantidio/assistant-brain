---
doc_id: "EPIC-F1-04-HITL-BOOTSTRAP-EVIDENCIAS.md"
version: "1.0"
status: "active"
owner: "PM"
last_updated: "2026-02-24"
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

**Plano TDD**
1. `Red`: simular baseline com arquivo de allowlist ausente/invalidado.
2. `Green`: restaurar baseline canonico de allowlists e policy.
3. `Refactor`: executar `make ci-security` e registrar resultado.

**Criterios de aceitacao**
- Given allowlist canonica ausente/invalida, When `make ci-security` roda, Then o check falha.
- Given baseline de seguranca canonico, When `make ci-security` roda, Then retorna `security-check: PASS`.

### ISSUE-F1-04-02 - Validar checklist humano de canal confiavel (HITL)
**User story**  
Como operador, quero confirmar o canal humano confiavel para comandos criticos antes de promover a fase.

**Plano TDD**
1. `Red`: checklist HITL incompleto (operador/canal nao validado).
2. `Green`: preencher checklist com Telegram primario e Slack fallback validado por policy.
3. `Refactor`: revisar `PM/DECISION-PROTOCOL.md` e `SEC/SEC-POLICY.md` para aderencia.

**Criterios de aceitacao**
- Given checklist HITL incompleto, When revisao de fase ocorre, Then promocao para F2 fica bloqueada.
- Given checklist HITL completo, When revisao de fase ocorre, Then fase fica apta sob criterio humano de canal confiavel.

### ISSUE-F1-04-03 - Consolidar evidencias da F1 em artifact unico
**User story**  
Como operador, quero um artifact unico da fase para auditoria e handoff operacional sem lacunas.

**Plano TDD**
1. `Red`: evidencias dispersas e sem padrao de fechamento.
2. `Green`: consolidar em `artifacts/phase-f1/validation-summary.md`.
3. `Refactor`: validar links/documentos do artifact com `make ci-quality`.

**Criterios de aceitacao**
- Given evidencias consolidadas, When `make ci-quality` roda, Then nao ha links quebrados na documentacao da fase.
- Given artifact unico concluido, When gate de fase e revisado, Then existe trilha minima para promocao `F1 -> F2`.

## Artifact Minimo do Epico
- `artifacts/phase-f1/validation-summary.md` com:
  - resultado de `onboard` e `verify`;
  - resultado de `ci-quality` e `ci-security`;
  - status dos epicos `EPIC-F1-01..EPIC-F1-04`;
  - decisao de promocao da fase (`promote|hold`) e justificativa.

## Dependencias
- [Decision Protocol](../../../PM/DECISION-PROTOCOL.md)
- [Security Policy](../../../SEC/SEC-POLICY.md)
- [Phase Usability Guide](../../../PRD/PHASE-USABILITY-GUIDE.md)
