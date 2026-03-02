---
doc_id: "EPIC-F10-03-ROLLOUT-CANARIO-E-PROMOCAO.md"
version: "1.0"
status: "active"
owner: "PM"
last_updated: "2026-03-02"
rfc_refs: ["RFC-001", "RFC-010", "RFC-035", "RFC-040", "RFC-050", "RFC-060"]
---

# EPIC-F10-03 Rollout Canario e Promocao

## Objetivo
Executar convergencia primeiro no perfil `--dev`, comprovar ausencia de regressao, promover para runtime ativo com janela de manutencao controlada e rollback deterministico validado.

## Resultado de Negocio Mensuravel
- risco de regressao na promocao reduzido por validacao previa em perfil isolado;
- runtime ativo converge para PRD sem perda de estado e com plano de retorno testado.

## Definition of Done (Scrum)
- canario `--dev` aprovado com report de no-loss;
- promocao ativa concluida com backup integral + validacao pos-start;
- cenario de rollback exercitado e documentado em artifact.

## Issues (Scrum + TDD + Criterios de Aceitacao)

### ISSUE-F10-03-01 - Executar canario `--dev` com copia controlada de estado
**User story**
Como operador, quero validar convergencia em ambiente isolado antes de tocar runtime ativo.

**Metadata da issue**
- **Owner**: `engineering`
- **Estimativa**: `0.5d`
- **Dependencias**: `scripts/runtime/export_runtime_state.sh`, `scripts/runtime/apply_runtime_merge_plan.sh`, `scripts/runtime/verify_runtime_convergence.sh`
- **Mapped requirements**: `B0-07`, `B0-15`, `B0-16`
- **Prioridade**: `P0`
- **Checklist QA/Repro**:
  1. gerar baseline `--dev` antes da aplicacao;
  2. aplicar merge plan no `--dev`;
  3. gerar inventario pos-canario;
  4. validar no-loss e convergencia em report.
- **Evidence refs**: `artifacts/phase-f10/epic-f10-03-canary-rollout-playbook.md`

**Plano TDD**
1. `Red`: promocao direta sem ensaio isolado.
2. `Green`: canario com evidencias estruturadas.
3. `Refactor`: reduzir passos manuais no runbook.

**Criterios de aceitacao**
- Given canario `--dev`, When validacoes rodam, Then nenhum diff nao permitido e detectado.

### ISSUE-F10-03-02 - Promover para runtime ativo com parada longa e restart unico
**User story**
Como owner do runtime, quero aplicar a convergencia no ambiente ativo com procedimento reprodutivel e seguro.

**Metadata da issue**
- **Owner**: `ops+engineering`
- **Estimativa**: `0.5d`
- **Dependencias**: `scripts/runtime/apply_runtime_merge_plan.sh`, `scripts/check_telegram_conflict.sh`
- **Mapped requirements**: `B0-07`, `B0-15`, `B0-16`
- **Prioridade**: `P0`
- **Checklist QA/Repro**:
  1. criar backup integral do state-dir ativo;
  2. aplicar merge plan no perfil ativo;
  3. restart unico do gateway no bind/port canonicos;
  4. validar `openclaw status/health` e Telegram probe pos-start.
- **Evidence refs**: `artifacts/phase-f10/epic-f10-03-canary-rollout-playbook.md`

**Plano TDD**
1. `Red`: aplicacao ativa sem passos formais de manutencao.
2. `Green`: roteiro com backup, aplicacao, restart e validacao final.
3. `Refactor`: simplificar checklist operacional.

**Criterios de aceitacao**
- Given promocao ativa, When convergencia finaliza, Then heartbeat passa para `15m` e Telegram segue operacional.

### ISSUE-F10-03-03 - Exercitar rollback deterministico e registrar evidencias
**User story**
Como operador de risco, quero rollback testado para recuperar runtime rapidamente em caso de falha.

**Metadata da issue**
- **Owner**: `ops`
- **Estimativa**: `0.5d`
- **Dependencias**: `scripts/runtime/apply_runtime_merge_plan.sh`, backups em `artifacts/phase-f10/runtime-backups/`
- **Mapped requirements**: `B0-05`, `B0-06`, `B0-15`
- **Prioridade**: `P1`
- **Checklist QA/Repro**:
  1. simular falha de validacao pos-merge;
  2. restaurar backup integral do state-dir;
  3. validar retorno ao baseline funcional;
  4. registrar incidente/evidencia de rollback.
- **Evidence refs**: `artifacts/phase-f10/epic-f10-03-canary-rollout-playbook.md`

**Plano TDD**
1. `Red`: rollback nao testado antes da promocao.
2. `Green`: rollback reproduzivel e medido.
3. `Refactor`: reduzir tempo de recuperacao e passos ambiguos.

**Criterios de aceitacao**
- Given falha pos-promocao, When rollback e acionado, Then runtime retorna ao baseline sem perda de estado.

## Artifact Minimo do Epico
- `artifacts/phase-f10/epic-f10-03-canary-rollout-playbook.md` com roteiro, resultados de canario/promocao e trilha de rollback.

## Dependencias
- [EPICS F10](./EPICS.md)
- [ARC Degraded Mode](../../../ARC/ARC-DEGRADED-MODE.md)
- [Incident Procedure](../../../INCIDENTS/DEGRADED-MODE-PROCEDURE.md)
