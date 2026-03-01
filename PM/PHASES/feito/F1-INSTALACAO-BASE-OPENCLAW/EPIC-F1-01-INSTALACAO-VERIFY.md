---
doc_id: "EPIC-F1-01-INSTALACAO-VERIFY.md"
version: "1.3"
status: "active"
owner: "PM"
last_updated: "2026-03-01"
rfc_refs: ["RFC-001", "RFC-010", "RFC-040", "RFC-050"]
---

# EPIC-F1-01 Baseline de Instalacao e Verify

## Objetivo
Fechar a primeira etapa com ambiente local executavel, verificacao tecnica padrao e evidencia minima para promocao de fase.

## Resultado de Negocio Mensuravel
- operador consegue preparar ambiente e validar runtime sem bloqueio manual.
- trilha minima de evidencias de setup fica registrada para auditoria.

## Definition of Done (Scrum)
- todas as issues do epico em estado `Done`.
- `bash scripts/onboard_linux.sh` executado com sucesso em host Linux ou macOS.
- `bash scripts/verify_linux.sh` executado com sucesso com `exit code 0`.
- evidencia de execucao registrada em artifact operacional da fase.

## Issues (Scrum + TDD + Criterios de Aceitacao)

### ISSUE-F1-01 - Preparar host e pre-requisitos
**User story**  
Como operador, quero validar e preparar os pre-requisitos do host para executar o onboarding sem falhas de ambiente.

**Metadados de governanca (DoR/DoD)**
- objetivo_verificavel: `onboard/verify reproduziveis em host alvo sem ajuste manual pos-setup`
- risk_tier: `R1`
- owner_issue: `Tech Lead`
- estimativa: `0.5 dia util`
- dependencias: `scripts/onboard_linux.sh`, `scripts/verify_linux.sh`, `DEV/DEV-OPENCLAW-SETUP.md`
- inputs_minimos: `host_os=linux|macos`, `shell=bash|zsh`, `permissoes de execucao para scripts`
- gate_path: `Ready -> Decomposed -> InProgress -> Verify -> Done`
- evidence_refs_obrigatorios:
  - `artifacts/phase-f1/validation-summary.md`
  - `stdout://bash scripts/verify_linux.sh`

**Plano TDD**
1. `Red`: executar `bash scripts/verify_linux.sh` em host sem setup final para capturar faltas de pre-requisito (`exit code != 0`).
2. `Green`: executar `bash scripts/onboard_linux.sh` para instalar/configurar dependencias por plataforma (Linux/macOS).
3. `Refactor`: repetir `verify_linux.sh` para garantir estabilidade e idempotencia basica.

**Criterios de aceitacao**
- Given host sem setup completo, When `verify_linux.sh` roda, Then o script aponta requisitos faltantes e retorna `exit code != 0`.
- Given onboarding executado, When `verify_linux.sh` roda novamente, Then nao ha erro bloqueante e o retorno e `exit code 0`.
- Given issue encerrada, When evidencias sao revisadas, Then existe `evidence_ref` para comando executado e resultado observado.

### ISSUE-F1-02 - Instalar e validar runtime OpenClaw
**User story**  
Como operador, quero confirmar que o runtime OpenClaw esta instalado e acessivel via CLI para iniciar operacao local.

**Metadados de governanca (DoR/DoD)**
- objetivo_verificavel: `openclaw CLI funcional em shell atual e em shell novo`
- risk_tier: `R1`
- owner_issue: `Tech Lead`
- estimativa: `0.5 dia util`
- dependencias: `scripts/onboard_linux.sh`, `CLI openclaw`, `PATH persistente no shell`
- inputs_minimos: `runtime instalado`, `terminal novo para teste de persistencia`
- gate_path: `Ready -> Decomposed -> InProgress -> Verify -> Done`
- evidence_refs_obrigatorios:
  - `artifacts/phase-f1/validation-summary.md`
  - `stdout://openclaw --version`

**Plano TDD**
1. `Red`: validar ausencia/inconsistencia do comando `openclaw --version`.
2. `Green`: executar onboarding e confirmar `openclaw --version` com retorno valido.
3. `Refactor`: abrir novo shell (`zsh -lic` no macOS, `bash -lic` no Linux) e repetir o comando para validar persistencia do setup.

**Criterios de aceitacao**
- Given ambiente preparado, When `openclaw --version` e executado, Then a versao e exibida sem erro.
- Given nova sessao de terminal, When `openclaw --version` e executado, Then o comando segue funcional sem ajuste manual de PATH.
- Given validacao concluida, When auditoria da issue ocorre, Then o stdout da versao fica anexado via `evidence_ref`.

### ISSUE-F1-03 - Smoke de governanca local e evidencias de fase
**User story**  
Como operador, quero validar os gates minimos de governanca apos instalacao para liberar promocao para a proxima fase.

**Metadados de governanca (DoR/DoD)**
- objetivo_verificavel: `gates de qualidade/seguranca/eval verdes com trilha de evidencia estruturada`
- risk_tier: `R2`
- owner_issue: `QA`
- estimativa: `1 dia util`
- dependencias: `make ci-quality`, `make ci-security`, `make eval-gates`, `PRD/PRD-MASTER.md`
- inputs_minimos: `setup F1 concluido`, `ambiente com make`, `artifact de fase habilitado`
- gate_path: `Ready -> Decomposed -> InProgress -> Verify -> Review/Gate -> Done`
- evidence_refs_obrigatorios:
  - `artifacts/phase-f1/validation-summary.md`
  - `stdout://make ci-quality`
  - `stdout://make ci-security`
  - `stdout://make eval-gates`

**Plano TDD**
1. `Red`: executar checks sem setup completo e registrar falhas de baseline (quando houver).
2. `Green`: apos setup valido, executar `make ci-quality`, `make ci-security`, `make eval-gates`.
3. `Refactor`: consolidar resultado em artifact de fase para auditoria.

**Criterios de aceitacao**
- Given setup concluido, When `make ci-quality` e executado, Then retorna `quality-check: PASS`.
- Given setup concluido, When `make ci-security` e executado, Then retorna `security-check: PASS`.
- Given setup concluido, When `make eval-gates` e executado, Then todos os evals obrigatorios retornam `PASS`.
- Given cada gate executado, When evidencia e registrada, Then cada comando possui `evidence_ref` estruturado com `command`, `result` e `timestamp`.
- Given risco `R2`, When a issue avanca apos `Verify`, Then existe registro de `Review/Gate` antes de `Done`.
- Given gates verdes, When a evidencia da fase e registrada, Then o epico fica apto a promover `F1 -> F2`.

## Artifact Minimo da Fase
- registrar resumo da execucao em `artifacts/phase-f1/validation-summary.md` com:
  - data/hora;
  - host alvo;
  - comandos executados;
  - status final (`PASS`/`FAIL`).

## Resultado desta Rodada
- `bash scripts/verify_linux.sh` final: `PASS` (`exit code 0`).
- `openclaw --version` validado no host local e nova sessao.
- evidencia consolidada e atualizada em `artifacts/phase-f1/validation-summary.md`.
- conclusao: EPIC-F1-01 apto para status `done` no fechamento da F1.

## Dependencias
- [Dev OpenClaw Setup](../../../../DEV/DEV-OPENCLAW-SETUP.md)
- [Work Order Spec](../../../../PM/WORK-ORDER-SPEC.md)
- [Phase Usability Guide](../../../../PRD/PHASE-USABILITY-GUIDE.md)
