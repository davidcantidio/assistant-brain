---
doc_id: "EPIC-F4-02-CONTRATOS-SCHEMAS-INTEGRACAO.md"
version: "1.1"
status: "active"
owner: "PM"
last_updated: "2026-02-26"
rfc_refs: ["RFC-001", "RFC-015", "RFC-030", "RFC-040", "RFC-050", "RFC-060"]
---

# EPIC-F4-02 Contratos e schemas de integracao

## Objetivo
Formalizar e validar os contratos de integracao em schemas versionados com campos minimos obrigatorios e coerencia de runtime.

## Resultado de Negocio Mensuravel
- integracoes externas passam a operar com contratos verificaveis e rastreaveis.
- erro de schema ou campo obrigatorio ausente bloqueia fase antes de impacto operacional.

## Definition of Done (Scrum)
- todas as issues do epico em estado `Done`.
- `make eval-integrations` executado com sucesso.
- evidencia de validacao de schema registrada no artifact do epico.

## Issues (Scrum + TDD + Criterios de Aceitacao)

### ISSUE-F4-02-01 - Validar presenca e JSON valido dos schemas obrigatorios
**User story**  
Como operador, quero confirmar presenca e validade JSON dos schemas obrigatorios para evitar contrato quebrado.

**Plano TDD**
1. `Red`: remover ou quebrar schema obrigatorio e executar `make eval-integrations`.
2. `Green`: restaurar todos os schemas obrigatorios com JSON valido.
3. `Refactor`: rerodar `make eval-integrations` para confirmar integridade.

**Criterios de aceitacao**
- Given schema obrigatorio ausente ou invalido, When `make eval-integrations` roda, Then o gate falha.
- Given todos os schemas obrigatorios validos, When `make eval-integrations` roda, Then a validacao de schema passa.

### ISSUE-F4-02-02 - Validar campos minimos signal_intent order_intent execution_report economic_run
**User story**  
Como operador, quero garantir campos minimos obrigatorios por contrato para manter rastreabilidade e auditoria ponta a ponta.

**Plano TDD**
1. `Red`: simular ausencia de campo obrigatorio em um dos schemas de integracao.
2. `Green`: restaurar campos minimos obrigatorios em todos os contratos.
3. `Refactor`: rerodar `make eval-integrations` e registrar cobertura de campos.

**Criterios de aceitacao**
- Given campo obrigatorio ausente em contrato de integracao, When `make eval-integrations` roda, Then o gate falha.
- Given campos minimos completos nos quatro contratos, When `make eval-integrations` roda, Then retorna `PASS`.

### ISSUE-F4-02-03 - Validar contrato dual runtime e provider_path
**User story**  
Como operador, quero validar compatibilidade dual de interface no runtime e trilha de provider para metrica economica.

**Plano TDD**
1. `Red`: remover referencia de `gateway.control_plane.ws`, `chatCompletions` opcional ou `provider_path`.
2. `Green`: restaurar contrato dual de runtime e `provider_path` conforme policy.
3. `Refactor`: rerodar `make eval-integrations` para confirmar compatibilidade.

**Criterios de aceitacao**
- Given contrato dual de runtime ausente ou incompleto, When `make eval-integrations` roda, Then o gate falha.
- Given runtime dual coerente e `provider_path` presente, When `make eval-integrations` roda, Then retorna `PASS`.

## Artifact Minimo do Epico
- registrar resumo em `artifacts/phase-f4/epic-f4-02-schema-validation.md` com:
  - status de presenca/validade dos schemas obrigatorios;
  - status de campos minimos dos contratos;
  - resultado final de `make eval-integrations`.

## Resultado desta Rodada
- `make eval-integrations` final: `PASS` (`eval-integrations: PASS`).
- evidencias por issue publicadas:
  - `artifacts/phase-f4/epic-f4-02-issue-01-schema-presence-json-valid.md`;
  - `artifacts/phase-f4/epic-f4-02-issue-02-min-required-fields.md`;
  - `artifacts/phase-f4/epic-f4-02-issue-03-runtime-dual-provider-path.md`.
- evidencia consolidada do epico:
  - `artifacts/phase-f4/epic-f4-02-schema-validation.md`.
- conclusao: `EPIC-F4-02` concluido no escopo documental/tdd desta rodada.

## Dependencias
- [Signal Intent Schema](../../../ARC/schemas/signal_intent.schema.json)
- [Order Intent Schema](../../../ARC/schemas/order_intent.schema.json)
- [Execution Report Schema](../../../ARC/schemas/execution_report.schema.json)
- [Economic Run Schema](../../../ARC/schemas/economic_run.schema.json)
- [OpenClaw Runtime Config Schema](../../../ARC/schemas/openclaw_runtime_config.schema.json)
- [Eval Integrations Script](../../../scripts/ci/eval_integrations.sh)
