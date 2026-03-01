---
doc_id: "EPIC-F3-01-CONTRATO-RUNTIME-MINIMO.md"
version: "1.2"
status: "active"
owner: "PM"
last_updated: "2026-03-01"
rfc_refs: ["RFC-001", "RFC-030", "RFC-040", "RFC-050"]
---

# EPIC-F3-01 Contrato de runtime minimo

## Objetivo
Garantir que o baseline de runtime esteja coerente com os contratos canonicos exigidos pelo gate de runtime, sem ambiguidade de arquivo, schema ou interface.

## Resultado de Negocio Mensuravel
- operador valida rapidamente se o runtime minimo esta integro antes de evoluir para integracoes externas.
- risco de drift de contrato em runtime base reduzido por checagem objetiva.

## Definition of Done (Scrum)
- todas as issues do epico em estado `Done`.
- `make eval-runtime` executado com sucesso.
- evidencias do contrato de runtime registradas no artifact do epico com `actual_assert_message` explicita.
- todas as issues do epico com DoR completo (`owner`, `estimate_hours`, `estimate_points`, `risk_class`, `risk_tier`, `dependencies`, `required_inputs`).

## Issues (Scrum + TDD + Criterios de Aceitacao)

### ISSUE-F3-01-01 - Validar arquivos obrigatorios do gate runtime
**User story**
Como operador, quero confirmar a presenca dos arquivos obrigatorios de runtime para evitar baseline incompleto.

**Metadados DoR (obrigatorio)**
- owner: `PO`
- estimate_hours: `3`
- estimate_points: `2`
- risk_class: `medio`
- risk_tier: `R1`
- dependencies:
  - `PRD/PRD-MASTER.md`
  - `scripts/ci/eval_runtime_contracts.sh`
  - `PRD/CHANGELOG.md`
- required_inputs:
  - output atual de `make eval-runtime`
  - lista de `required_files` vigente no gate

**Plano TDD**
1. `Red`: simular ausencia de arquivo obrigatorio e executar `make eval-runtime`.
2. `Green`: restaurar todos os arquivos obrigatorios conforme contrato.
3. `Refactor`: rerodar `make eval-runtime` para garantir estabilidade.

**Criterios de aceitacao**
- Given arquivo obrigatorio ausente, When `make eval-runtime` roda, Then o gate falha com indicacao explicita do arquivo faltante.
- Given arquivos obrigatorios presentes, When `make eval-runtime` roda, Then nao ha falha por ausencia de baseline documental.
- Given alteracao em `required_files`, When issue for atualizada, Then owner/estimativa/dependencias devem ser revisados.

**Checklist QA (DoD da issue)**
- executar `Red/Green/Refactor` e anexar logs no artifact da issue.
- validar que o artifact contem `scenario`, `command`, `expected_result`, `actual_assert_message`, `trace_id_or_ref`, `status`.

### ISSUE-F3-01-02 - Validar schema/runtime contract e pontos A2A hooks gateway
**User story**
Como operador, quero validar schema e contrato de runtime para garantir interface padrao de operacao.

**Metadados DoR (obrigatorio)**
- owner: `Tech Lead`
- estimate_hours: `8`
- estimate_points: `5`
- risk_class: `alto`
- risk_tier: `R2`
- dependencies:
  - `ARC/schemas/openclaw_runtime_config.schema.json`
  - `ARC/schemas/a2a_delegation_event.schema.json`
  - `ARC/schemas/webhook_ingest_event.schema.json`
  - `scripts/ci/eval_runtime_contracts.sh`
- required_inputs:
  - schema runtime atual
  - fixture valida e invalida de A2A/webhook

**Plano TDD**
1. `Red`: introduzir quebra proposital no schema ou remocao de referencia contratual de A2A/hooks/gateway.
2. `Green`: restaurar schema valido e referencias canonicas exigidas.
3. `Refactor`: rerodar `make eval-runtime` para confirmar conformidade continua.

**Criterios de aceitacao**
- Given required field removido em A2A/hooks/gateway, When `make eval-runtime` roda, Then o gate falha com identificacao do campo faltante.
- Given schema valido e contrato completo, When `make eval-runtime` roda, Then a verificacao retorna `PASS`.
- Given alteracao de schema, When issue for atualizada, Then owner e risco devem ser revisados no bloco da issue.

**Checklist QA (DoD da issue)**
- executar fixtures invalidas/validas e anexar stdout do gate.
- validar rastreabilidade com `trace_id` nos cenarios de hooks/webhooks.

### ISSUE-F3-01-03 - Validar fonte canonica de estado do workspace
**User story**
Como operador, quero garantir o caminho canonico de estado do workspace para evitar conflitos de fonte de verdade.

**Metadados DoR (obrigatorio)**
- owner: `PO`
- estimate_hours: `4`
- estimate_points: `2`
- risk_class: `medio`
- risk_tier: `R1`
- dependencies:
  - `PRD/PRD-MASTER.md`
  - `META/DOCUMENT-HIERARCHY.md`
  - `ARC/ARC-CORE.md`
  - `workspaces/main/.openclaw/workspace-state.json`
- required_inputs:
  - caminho canonico de workspace-state aprovado
  - regra de unicidade de arquivo no workspace

**Plano TDD**
1. `Red`: simular estado fora do caminho canonico e executar `make eval-runtime`.
2. `Green`: alinhar para `workspaces/main/.openclaw/workspace-state.json`.
3. `Refactor`: rerodar `make eval-runtime` e registrar evidencia.

**Criterios de aceitacao**
- Given mais de um `workspace-state.json`, When `make eval-runtime` roda, Then o gate falha por conflito de fonte canonica.
- Given somente `workspaces/main/.openclaw/workspace-state.json`, When `make eval-runtime` roda, Then a validacao de estado passa sem bloqueio.
- Given regra canonica sem referencia normativa no PRD, When issue for revisada, Then registrar referencia formal cruzada.

**Checklist QA (DoD da issue)**
- validar cenario com caminho conflitante e cenario com caminho unico.
- anexar log do gate com mensagem assertiva da regra canonica.

## Artifact Minimo do Epico
- registrar resumo em `artifacts/phase-f3/epic-f3-01-runtime-contract.md` com:
  - arquivos obrigatorios verificados;
  - status do schema de runtime;
  - resultado final de `make eval-runtime`.

## Resultado desta Rodada (Pos-Audit)
- escopo documental atualizado com contrato DoR/DoD nas 3 issues.
- evidencias por issue migradas para contrato padrao de artifact.
- conclusao: `EPIC-F3-01` pronto para reauditoria de cobertura F3.

## Dependencias
- [PRD Master](../../../../PRD/PRD-MASTER.md)
- [ARC Core](../../../../ARC/ARC-CORE.md)
- [Runtime Config Schema](../../../../ARC/schemas/openclaw_runtime_config.schema.json)
- [Document Hierarchy](../../../../META/DOCUMENT-HIERARCHY.md)
- [Eval Runtime Contracts Script](../../../../scripts/ci/eval_runtime_contracts.sh)
