---
doc_id: "EPIC-F10-01-AUDITORIA-E-BASELINE-RUNTIME.md"
version: "1.0"
status: "active"
owner: "PM"
last_updated: "2026-03-02"
rfc_refs: ["RFC-001", "RFC-010", "RFC-015", "RFC-040", "RFC-050"]
---

# EPIC-F10-01 Auditoria e Baseline Runtime

## Objetivo
Gerar baseline auditavel do runtime ativo, identificar gaps contra PRD e `.env`, e converter o resultado em backlog executavel de convergencia sem mutacao inicial do ambiente produtivo.

## Resultado de Negocio Mensuravel
- equipe passa a operar com fonte unica de verdade para estado real do runtime;
- plano de convergencia deixa de depender de inferencia manual e passa a usar diff deterministico.

## Definition of Done (Scrum)
- baseline `runtime_inventory.v1` gerado com hash e redacao de segredo;
- matriz de gaps PRD/.env/runtime publicada em artifact;
- issues do epico em `Done` com evidencias e checklist QA preenchidos.

## Issues (Scrum + TDD + Criterios de Aceitacao)

### ISSUE-F10-01-01 - Exportar inventario `runtime_inventory.v1` do runtime ativo
**User story**
Como operador, quero um inventario padrao e sanitizado do runtime para ter baseline confiavel antes de qualquer mudanca.

**Metadata da issue**
- **Owner**: `engineering`
- **Estimativa**: `0.5d`
- **Dependencias**: `scripts/runtime/export_runtime_state.sh`
- **Mapped requirements**: `B0-07`, `B0-15`
- **Prioridade**: `P0`
- **Checklist QA/Repro**:
  1. executar export com `--profile active --redact-secrets true`;
  2. validar campos obrigatorios do `runtime_inventory.v1`;
  3. validar que hash e estavel para mesma entrada;
  4. validar ausencia de segredos em claro no output.
- **Evidence refs**: `scripts/runtime/export_runtime_state.sh`, `artifacts/phase-f10/epic-f10-01-runtime-baseline-audit.md`

**Plano TDD**
1. `Red`: nao existe inventario deterministico do runtime.
2. `Green`: export gera JSON padrao com hash e redacao.
3. `Refactor`: consolidar validacoes e normalizacao de shape.

**Criterios de aceitacao**
- Given runtime ativo, When export e executado, Then `runtime_inventory.v1` e gerado com os campos fixos definidos.
- Given `--redact-secrets true`, When arquivo e produzido, Then tokens/chaves nao aparecem em claro.

### ISSUE-F10-01-02 - Auditar drift `.env` x runtime x PRD schema
**User story**
Como PM/engenharia, quero ver divergencias objetivas entre contrato e runtime para transformar o trabalho em backlog claro e priorizado.

**Metadata da issue**
- **Owner**: `pm+engineering`
- **Estimativa**: `0.5d`
- **Dependencias**: `assistant-brain/.env`, `~/.openclaw/openclaw.json`, `ARC/schemas/openclaw_runtime_config.schema.json`
- **Mapped requirements**: `B0-07`, `B0-15`, `B0-16`
- **Prioridade**: `P1`
- **Checklist QA/Repro**:
  1. comparar heartbeat esperado vs runtime atual;
  2. comparar bind/port de gateway com contrato;
  3. registrar gaps estruturais do schema canonico;
  4. classificar gaps por risco e prioridade.
- **Evidence refs**: `artifacts/phase-f10/epic-f10-01-runtime-baseline-audit.md`

**Plano TDD**
1. `Red`: divergencias ficam dispersas e sem priorizacao.
2. `Green`: matriz de gaps objetiva e versionada.
3. `Refactor`: transformar gaps em input direto para merge plan.

**Criterios de aceitacao**
- Given baseline exportado, When auditoria roda, Then cada gap possui origem, impacto e prioridade.
- Given gap de parametro critico (ex.: heartbeat), When auditoria conclui, Then existe issue com acao rastreavel.

### ISSUE-F10-01-03 - Extrair backlog PM da auditoria em formato padrao
**User story**
Como time, quero backlog em formato PM existente para executar convergencia sem ambiguidade.

**Metadata da issue**
- **Owner**: `pm`
- **Estimativa**: `0.5d`
- **Dependencias**: `PM/WORK-ORDER-SPEC.md`, `PM/PHASES/F10-CONVERGENCIA-PRD-RUNTIME-SEM-REGRESSAO/EPICS.md`
- **Mapped requirements**: `B0-15`, `B0-16`
- **Prioridade**: `P1`
- **Checklist QA/Repro**:
  1. validar metadata obrigatoria por issue;
  2. validar links para evidencias/artefatos;
  3. validar rastreabilidade com requirements do roadmap.
- **Evidence refs**: `PM/PHASES/F10-CONVERGENCIA-PRD-RUNTIME-SEM-REGRESSAO/*.md`

**Plano TDD**
1. `Red`: gaps tecnicos sem trilha PM consistente.
2. `Green`: epico/issue com metadata completa.
3. `Refactor`: harmonizar termos e criterios de aceite.

**Criterios de aceitacao**
- Given auditoria concluida, When backlog e publicado, Then cada acao critica possui issue PM no formato canonico.

## Artifact Minimo do Epico
- `artifacts/phase-f10/epic-f10-01-runtime-baseline-audit.md` com baseline, matriz de gaps e prioridade.

## Dependencias
- [EPICS F10](./EPICS.md)
- [PRD Master](../../../PRD/PRD-MASTER.md)
- [Runtime Config Schema](../../../ARC/schemas/openclaw_runtime_config.schema.json)
