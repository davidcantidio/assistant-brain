---
doc_id: "EPIC-F1-02-CONTRATO-CONFIG-LOCAL.md"
version: "1.2"
status: "active"
owner: "PM"
last_updated: "2026-02-24"
rfc_refs: ["RFC-001", "RFC-010", "RFC-015", "RFC-040", "RFC-050"]
---

# EPIC-F1-02 Contrato de configuracao local

## Objetivo
Garantir que o setup local esteja coerente com o contrato de configuracao (`.env`, variaveis obrigatorias e defaults de runtime) sem vazamento de segredos.

## Resultado de Negocio Mensuravel
- operador consegue validar rapidamente se o ambiente esta conforme o contrato.
- risco de drift de configuracao local reduzido antes da promocao para a fase seguinte.

## Definition of Done (Scrum)
- todas as issues do epico em estado `Done`.
- `bash scripts/verify_linux.sh` executado com sucesso (`exit code 0`).
- `make eval-models` executado com sucesso.
- evidencias de validacao de configuracao registradas no artifact do epico.

## Issues (Scrum + TDD + Criterios de Aceitacao)

### ISSUE-F1-02-01 - Validar contrato de variaveis obrigatorias vs DEV-OPENCLAW-SETUP
**User story**  
Como operador, quero confirmar quais variaveis obrigatorias existem no contrato para evitar setup incompleto.

**Plano TDD**
1. `Red`: executar `bash scripts/verify_linux.sh` com variavel obrigatoria ausente e observar falha (`exit code != 0`).
2. `Green`: preencher variaveis obrigatorias conforme `DEV/DEV-OPENCLAW-SETUP.md`.
3. `Refactor`: rerodar `verify_linux.sh` para validar consistencia do contrato com `exit code 0`.

**Criterios de aceitacao**
- Given variavel obrigatoria ausente, When `verify_linux.sh` roda, Then o check falha com indicacao de requisito faltante e `exit code != 0`.
- Given variaveis obrigatorias preenchidas, When `verify_linux.sh` roda, Then o check de ambiente nao falha por ausencia de configuracao e retorna `exit code 0`.

### ISSUE-F1-02-02 - Validar defaults operacionais
**User story**  
Como operador, quero validar defaults de operacao para iniciar o runtime com comportamento previsivel.

**Plano TDD**
1. `Red`: validar divergencia proposital em default critico (`HEARTBEAT_MINUTES`, `STANDUP_TIME`, base URL de gateway/LiteLLM ou alias de supervisor) e observar falha no `verify_linux.sh`.
2. `Green`: ajustar defaults para o contrato normativo.
3. `Refactor`: executar `bash scripts/verify_linux.sh` e `make eval-models` para confirmar alinhamento.

**Criterios de aceitacao**
- Given defaults divergentes, When `verify_linux.sh` roda, Then o baseline e reprovado com indicacao explicita do default divergente.
- Given defaults alinhados, When `verify_linux.sh` roda, Then retorna `exit code 0`.
- Given defaults alinhados, When `make eval-models` roda, Then o comando retorna `eval-models: PASS`.

### ISSUE-F1-02-03 - Validar politica de cloud opcional no baseline local
**User story**  
Como operador, quero garantir que OpenRouter fique desabilitado por default no baseline para evitar habilitacao indevida de cloud.

**Plano TDD**
1. `Red`: introduzir linguagem/configuracao ambigua de cloud default e executar `make eval-models`.
2. `Green`: restaurar regra canonica de cloud opcional desabilitada por default.
3. `Refactor`: repetir `make eval-models` e registrar evidencia de compliance.

**Criterios de aceitacao**
- Given baseline com regra ambigua de cloud, When `make eval-models` roda, Then o check falha.
- Given baseline com regra canonica de cloud opcional desabilitada, When `make eval-models` roda, Then retorna `PASS`.

## Artifact Minimo do Epico
- registrar resumo em `artifacts/phase-f1/epic-f1-02-config-validation.md` com:
  - variaveis obrigatorias checadas;
  - defaults validados;
  - status final do `verify_linux.sh` e `make eval-models`.

## Resultado desta Rodada
- `bash scripts/verify_linux.sh` final: `PASS` (`exit code 0`).
- `make eval-models` final: `PASS`.
- evidencia consolidada: `artifacts/phase-f1/epic-f1-02-config-validation.md`.

## Dependencias
- [Dev OpenClaw Setup](../../../../DEV/DEV-OPENCLAW-SETUP.md)
- [ARC Model Routing](../../../../ARC/ARC-MODEL-ROUTING.md)
- [Security Policy](../../../../SEC/SEC-POLICY.md)
- [Phase Usability Guide](../../../../PRD/PHASE-USABILITY-GUIDE.md)
