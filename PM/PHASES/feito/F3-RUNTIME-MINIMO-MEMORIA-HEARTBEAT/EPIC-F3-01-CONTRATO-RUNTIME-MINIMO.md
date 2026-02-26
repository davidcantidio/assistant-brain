---
doc_id: "EPIC-F3-01-CONTRATO-RUNTIME-MINIMO.md"
version: "1.1"
status: "active"
owner: "PM"
last_updated: "2026-02-26"
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
- evidencias do contrato de runtime registradas no artifact do epico.

## Issues (Scrum + TDD + Criterios de Aceitacao)

### ISSUE-F3-01-01 - Validar arquivos obrigatorios do gate runtime
**User story**  
Como operador, quero confirmar a presenca dos arquivos obrigatorios de runtime para evitar baseline incompleto.

**Plano TDD**
1. `Red`: simular ausencia de arquivo obrigatorio e executar `make eval-runtime`.
2. `Green`: restaurar todos os arquivos obrigatorios conforme contrato.
3. `Refactor`: rerodar `make eval-runtime` para garantir estabilidade.

**Criterios de aceitacao**
- Given arquivo obrigatorio ausente, When `make eval-runtime` roda, Then o gate falha com indicacao do arquivo faltante.
- Given arquivos obrigatorios presentes, When `make eval-runtime` roda, Then nao ha falha por ausencia de baseline documental.

### ISSUE-F3-01-02 - Validar schema/runtime contract e pontos A2A hooks gateway
**User story**  
Como operador, quero validar schema e contrato de runtime para garantir interface padrao de operacao.

**Plano TDD**
1. `Red`: introduzir quebra proposital no schema ou remocao de referencia contratual de A2A/hooks/gateway.
2. `Green`: restaurar schema valido e referencias canonicas exigidas.
3. `Refactor`: rerodar `make eval-runtime` para confirmar conformidade continua.

**Criterios de aceitacao**
- Given schema invalido ou contrato ausente, When `make eval-runtime` roda, Then o gate falha.
- Given schema valido e contrato completo, When `make eval-runtime` roda, Then a verificacao retorna `PASS`.

### ISSUE-F3-01-03 - Validar fonte canonica de estado do workspace
**User story**  
Como operador, quero garantir o caminho canonico de estado do workspace para evitar conflitos de fonte de verdade.

**Plano TDD**
1. `Red`: simular estado fora do caminho canonico e executar `make eval-runtime`.
2. `Green`: alinhar para `workspaces/main/.openclaw/workspace-state.json`.
3. `Refactor`: rerodar `make eval-runtime` e registrar evidencia.

**Criterios de aceitacao**
- Given estado canonico divergente, When `make eval-runtime` roda, Then o gate falha por conflito de contrato.
- Given estado canonico alinhado, When `make eval-runtime` roda, Then a validacao de estado passa sem bloqueio.

## Artifact Minimo do Epico
- registrar resumo em `artifacts/phase-f3/epic-f3-01-runtime-contract.md` com:
  - arquivos obrigatorios verificados;
  - status do schema de runtime;
  - resultado final de `make eval-runtime`.

## Resultado desta Rodada
- `make eval-runtime` final: `PASS` (`eval-runtime-contracts: PASS`).
- evidencias por issue publicadas:
  - `artifacts/phase-f3/epic-f3-01-issue-01-required-files.md`;
  - `artifacts/phase-f3/epic-f3-01-issue-02-runtime-schema-a2a-hooks-gateway.md`;
  - `artifacts/phase-f3/epic-f3-01-issue-03-workspace-state-canonical-source.md`.
- evidencia consolidada do epico:
  - `artifacts/phase-f3/epic-f3-01-runtime-contract.md`.
- conclusao: `EPIC-F3-01` concluido no escopo documental/tdd desta rodada.

## Dependencias
- [PRD Master](../../../../PRD/PRD-MASTER.md)
- [ARC Core](../../../../ARC/ARC-CORE.md)
- [Runtime Config Schema](../../../../ARC/schemas/openclaw_runtime_config.schema.json)
- [Document Hierarchy](../../../../META/DOCUMENT-HIERARCHY.md)
- [Eval Runtime Contracts Script](../../../../scripts/ci/eval_runtime_contracts.sh)
