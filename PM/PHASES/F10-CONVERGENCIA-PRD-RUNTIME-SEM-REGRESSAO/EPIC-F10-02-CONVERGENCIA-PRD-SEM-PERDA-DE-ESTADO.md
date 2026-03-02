---
doc_id: "EPIC-F10-02-CONVERGENCIA-PRD-SEM-PERDA-DE-ESTADO.md"
version: "1.0"
status: "active"
owner: "PM"
last_updated: "2026-03-02"
rfc_refs: ["RFC-001", "RFC-010", "RFC-030", "RFC-040", "RFC-050"]
---

# EPIC-F10-02 Convergencia PRD sem Perda de Estado

## Objetivo
Implementar politica de merge deterministica para aplicar contratos minimos do PRD no runtime preservando estado completo do ambiente atual.

## Resultado de Negocio Mensuravel
- convergencia deixa de ser edit manual de `openclaw.json`;
- estado operacional existente permanece intacto apos ajuste de parametros normativos.

## Definition of Done (Scrum)
- `runtime_merge_plan.v1` gerado e validado;
- aplicacao em `--dry-run` sem divergencia fora da allowlist;
- regras de preservacao e enforce documentadas com rollback explicito.

## Issues (Scrum + TDD + Criterios de Aceitacao)

### ISSUE-F10-02-01 - Gerar `runtime_merge_plan.v1` a partir de `.env`, runtime e schema PRD
**User story**
Como engenheiro, quero um plano de merge maquina-consumivel para evitar mudancas ad-hoc no runtime.

**Metadata da issue**
- **Owner**: `engineering`
- **Estimativa**: `0.5d`
- **Dependencias**: `scripts/runtime/build_runtime_merge_plan.py`
- **Mapped requirements**: `B0-07`, `B0-15`
- **Prioridade**: `P0`
- **Checklist QA/Repro**:
  1. gerar merge plan com input `.env` e `openclaw.json`;
  2. validar campos obrigatorios (`plan_id`, `preserve_paths`, `enforce_paths`, `operations[]`, `rollback`);
  3. validar inclusao dos paths preservados obrigatorios;
  4. validar enforce de `gateway.bind`, `gateway.port`, `agents.defaults.heartbeat.every`.
- **Evidence refs**: `scripts/runtime/build_runtime_merge_plan.py`, `artifacts/phase-f10/epic-f10-02-runtime-merge-policy.md`

**Plano TDD**
1. `Red`: sem plano formal, alteracoes manuais suscetiveis a erro.
2. `Green`: merge plan produzido com operacoes explicitas.
3. `Refactor`: reduzir operacoes desnecessarias via no-op detection.

**Criterios de aceitacao**
- Given runtime e `.env`, When builder roda, Then merge plan inclui apenas alteracoes necessarias.

### ISSUE-F10-02-02 - Aplicar merge plan com backup e suporte a `dry-run`
**User story**
Como operador, quero aplicar convergencia com backup automatico e rollback preparado para minimizar risco operacional.

**Metadata da issue**
- **Owner**: `engineering`
- **Estimativa**: `1d`
- **Dependencias**: `scripts/runtime/apply_runtime_merge_plan.sh`
- **Mapped requirements**: `B0-07`, `B0-15`, `B0-16`
- **Prioridade**: `P0`
- **Checklist QA/Repro**:
  1. executar `--dry-run true` e validar plano sem escrita;
  2. executar `--dry-run false` em ambiente controlado;
  3. validar criacao de backup state-dir antes da escrita;
  4. validar preservacao dos blocos obrigatorios.
- **Evidence refs**: `scripts/runtime/apply_runtime_merge_plan.sh`, `artifacts/phase-f10/epic-f10-02-runtime-merge-policy.md`

**Plano TDD**
1. `Red`: aplicacao sem backup e sem simulado.
2. `Green`: fluxo com backup+dry-run deterministico.
3. `Refactor`: simplificar contrato de parametros e logs.

**Criterios de aceitacao**
- Given `dry-run=true`, When script executa, Then nenhuma escrita em `openclaw.json` ocorre.
- Given `dry-run=false`, When script executa, Then backup e criado antes da primeira mutacao.

### ISSUE-F10-02-03 - Verificar no-loss estrutural e convergencia controlada
**User story**
Como time de confiabilidade, quero validação automatizada de no-loss para bloquear promocao com regressao.

**Metadata da issue**
- **Owner**: `engineering`
- **Estimativa**: `0.5d`
- **Dependencias**: `scripts/runtime/verify_runtime_convergence.sh`
- **Mapped requirements**: `B0-15`, `B0-16`
- **Prioridade**: `P0`
- **Checklist QA/Repro**:
  1. comparar baseline e pos-convergencia;
  2. validar que diff fora da allowlist bloqueia sucesso;
  3. validar Telegram configurado e probe `ok=true`;
  4. validar heartbeat final em `15m`.
- **Evidence refs**: `scripts/runtime/verify_runtime_convergence.sh`, `artifacts/phase-f10/epic-f10-02-runtime-merge-policy.md`

**Plano TDD**
1. `Red`: promocao sem prova de no-loss.
2. `Green`: verificador gera report objetivo com pass/fail.
3. `Refactor`: padronizar formato de report para CI.

**Criterios de aceitacao**
- Given baseline e pos, When verify roda, Then retorna falha se qualquer path preservado divergir.

## Artifact Minimo do Epico
- `artifacts/phase-f10/epic-f10-02-runtime-merge-policy.md` com politica de preservacao/enforce e evidencias de dry-run.

## Dependencias
- [EPICS F10](./EPICS.md)
- [Runtime Config Schema](../../../ARC/schemas/openclaw_runtime_config.schema.json)
- [Security Policy](../../../SEC/SEC-POLICY.md)
