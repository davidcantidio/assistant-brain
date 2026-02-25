---
doc_id: "EPIC-F1-03-WORKSPACE-STATE-MEMORY.md"
version: "1.1"
status: "active"
owner: "PM"
last_updated: "2026-02-25"
rfc_refs: ["RFC-001", "RFC-010", "RFC-040", "RFC-050"]
---

# EPIC-F1-03 Workspace state e memoria operacional minima

## Objetivo
Garantir que o estado canonico do workspace e o baseline de memoria diaria estejam prontos para uso humano real na F1.

## Resultado de Negocio Mensuravel
- operador passa a ter fonte de verdade operacional valida para estado e memoria.
- reducao de perda de contexto no fechamento e reabertura de sessoes.

## Definition of Done (Scrum)
- todas as issues do epico em estado `Done`.
- `make eval-runtime` executado com sucesso.
- evidencias de estado e memoria registradas no artifact do epico.

## Issues (Scrum + TDD + Criterios de Aceitacao)

### ISSUE-F1-03-01 - Validar estado canonico do workspace
**User story**  
Como operador, quero confirmar a presenca e consistencia do estado canonico para evitar ambiguidade operacional.

**Plano TDD**
1. `Red`: remover/invalidar referencia de estado e executar `make eval-runtime`.
2. `Green`: restaurar `workspaces/main/.openclaw/workspace-state.json` conforme contrato.
3. `Refactor`: rerodar `make eval-runtime` para garantir estabilidade.

**Criterios de aceitacao**
- Given estado canonico ausente/invalido, When `make eval-runtime` roda, Then o check falha por contrato de runtime.
- Given estado canonico valido, When `make eval-runtime` roda, Then nao ha falha por ausencia de estado.

### ISSUE-F1-03-02 - Validar estrutura minima de memoria operacional
**User story**  
Como operador, quero manter `MEMORY.md` e `memory/YYYY-MM-DD.md` no formato esperado para preservacao de contexto.

**Plano TDD**
1. `Red`: validar nota diaria sem secoes obrigatorias.
2. `Green`: ajustar nota diaria para conter estrutura minima valida.
3. `Refactor`: rerodar `make eval-runtime` para garantir conformidade continua.

**Criterios de aceitacao**
- Given nota diaria sem secoes obrigatorias, When `make eval-runtime` roda, Then o check de memoria falha.
- Given nota diaria com estrutura obrigatoria, When `make eval-runtime` roda, Then retorna `eval-runtime-contracts: PASS`.

### ISSUE-F1-03-03 - Validar heartbeat e ciclo noturno
**User story**  
Como operador, quero confirmar baseline de heartbeat e nightly extraction para operar com rotina previsivel.

**Plano TDD**
1. `Red`: introduzir divergencia de baseline/timezone em heartbeat.
2. `Green`: alinhar heartbeat/noturno ao contrato canonicamente definido.
3. `Refactor`: executar `make eval-runtime` e registrar evidencia.

**Criterios de aceitacao**
- Given baseline/timezone divergente, When `make eval-runtime` roda, Then o check falha.
- Given baseline/timezone alinhado (`15 minutos`, `America/Sao_Paulo`), When `make eval-runtime` roda, Then retorna `PASS`.

## Artifact Minimo do Epico
- registrar resumo em `artifacts/phase-f1/epic-f1-03-runtime-memory.md` com:
  - estado canonico validado;
  - nota diaria validada;
  - resultado de `make eval-runtime`.

## Resultado desta Rodada
- `make eval-runtime` final: `PASS` (`eval-runtime-contracts: PASS`).
- evidencia consolidada: `artifacts/phase-f1/epic-f1-03-runtime-memory.md`.
- nota diaria operacional criada e validada: `workspaces/main/memory/2026-02-25.md`.
- conclusao: EPIC-F1-03 concluido no escopo documental/tdd desta rodada.

## Dependencias
- [ARC Heartbeat](../../../../ARC/ARC-HEARTBEAT.md)
- [PRD Master](../../../../PRD/PRD-MASTER.md)
- [Phase Usability Guide](../../../../PRD/PHASE-USABILITY-GUIDE.md)
