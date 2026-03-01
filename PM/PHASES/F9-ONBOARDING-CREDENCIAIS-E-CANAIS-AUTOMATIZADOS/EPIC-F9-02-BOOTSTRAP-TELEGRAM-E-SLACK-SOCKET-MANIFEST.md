---
doc_id: "EPIC-F9-02-BOOTSTRAP-TELEGRAM-E-SLACK-SOCKET-MANIFEST.md"
version: "1.0"
status: "active"
owner: "PM"
last_updated: "2026-03-01"
rfc_refs: ["RFC-001", "RFC-010", "RFC-015", "RFC-040", "RFC-050"]
---

# EPIC-F9-02 Bootstrap Telegram e Slack Socket Mode Manifest

## Objetivo
Padronizar bootstrap de canais no onboarding: Telegram com parse de payload JSON e Slack com manifesto Socket Mode versionado e comandos HITL.

## Resultado de Negocio Mensuravel
- operador consegue iniciar setup de canal confiavel sem etapa manual de descoberta de IDs;
- install do app Slack fica reproduzivel por manifesto versionado.

## Definition of Done (Scrum)
- todas as issues do epico em estado `Done`.
- onboarding reconhece payload Telegram e preenche defaults operacionais.
- manifesto Slack importavel em "Create app from manifest".
- `make ci-quality` e `make ci-security` permanecem `PASS`.

## Issues (Scrum + TDD + Criterios de Aceitacao)

### ISSUE-F9-02-01 - Preload de Telegram por `TELEGRAM_UPDATE_JSON` e `TELEGRAM_UPDATE_JSON_FILE`
**User story**
Como operador, quero carregar IDs de Telegram a partir do update bruto para evitar erro de digitacao na configuracao inicial.

**Metadata da issue**
- **Owner**: `engineering`
- **Estimativa**: `1d`
- **Dependencias**: `scripts/onboard_linux.sh`
- **Mapped requirements**: `B0-23`
- **Prioridade**: `P1`
- **Checklist QA/Repro**:
  1. fornecer payload via `TELEGRAM_UPDATE_JSON`;
  2. fornecer payload via `TELEGRAM_UPDATE_JSON_FILE`;
  3. validar parse de `message.from.id`, `message.chat.id` e `message.chat.type`;
  4. validar defaults dos prompts `TELEGRAM_CHAT_ID` e `TELEGRAM_USER_ID`.
- **Evidence refs**: `scripts/onboard_linux.sh`

**Plano TDD**
1. `Red`: onboarding sem defaults exige preenchimento manual completo.
2. `Green`: onboarding extrai defaults do payload.
3. `Refactor`: manter fallback manual quando payload nao existir ou for invalido.

**Criterios de aceitacao**
- Given payload valido, When onboarding inicia, Then prompts de Telegram chegam pre-preenchidos.
- Given payload invalido, When onboarding continua, Then fluxo nao quebra e mantem entrada manual.

### ISSUE-F9-02-02 - Manifesto Slack Socket Mode com `/oc-approve`, `/oc-reject`, `/oc-kill`
**User story**
Como operador, quero um manifesto pronto para criar app Slack com comandos HITL sem montar configuracao manual no painel.

**Metadata da issue**
- **Owner**: `pm+engineering`
- **Estimativa**: `0.5d`
- **Dependencias**: `config/slack-app-manifest.socket-mode.yaml`, `PM/DECISION-PROTOCOL.md`
- **Mapped requirements**: `B0-24`
- **Prioridade**: `P1`
- **Checklist QA/Repro**:
  1. validar `socket_mode_enabled=true`;
  2. validar comandos `/oc-approve`, `/oc-reject`, `/oc-kill`;
  3. validar scopes minimos para comandos/eventos;
  4. validar placeholders explicitos para URLs obrigatorias do schema.
- **Evidence refs**: `config/slack-app-manifest.socket-mode.yaml`

**Plano TDD**
1. `Red`: app sem manifesto exige setup manual repetitivo.
2. `Green`: manifesto versionado reproduz setup.
3. `Refactor`: documentar passos de importacao no README e DEV setup.

**Criterios de aceitacao**
- Given manifesto versionado, When operador cria app no Slack via manifest, Then comandos HITL ficam provisionados.
- Given uso em Socket Mode, When manifest e validado, Then placeholders de URL permanecem explicitados.

### ISSUE-F9-02-03 - Sincronizar README/DEV/PRD com onboarding de canais
**User story**
Como operador, quero instrucoes consistentes nos docs para repetir onboarding sem drift entre guias.

**Metadata da issue**
- **Owner**: `pm`
- **Estimativa**: `0.5d`
- **Dependencias**: `README.md`, `DEV/DEV-OPENCLAW-SETUP.md`, `PRD/PRD-MASTER.md`, `PRD/PHASE-USABILITY-GUIDE.md`, `PRD/CHANGELOG.md`
- **Mapped requirements**: `B0-23`, `B0-24`
- **Prioridade**: `P2`
- **Checklist QA/Repro**:
  1. validar instrucoes de onboarding interativo em `README`;
  2. validar passo-a-passo de manifesto Slack nos docs operacionais;
  3. validar registro normativo no changelog;
  4. validar cobertura da fase no guide de usabilidade.
- **Evidence refs**: `README.md`, `DEV/DEV-OPENCLAW-SETUP.md`, `PRD/CHANGELOG.md`

**Plano TDD**
1. `Red`: docs divergentes entre setup operacional e norma.
2. `Green`: docs sincronizados com fluxo real do script.
3. `Refactor`: manter rastreabilidade `ROADMAP -> F9` atualizada.

**Criterios de aceitacao**
- Given instrucoes de onboarding, When operador segue README/DEV setup, Then consegue reproduzir bootstrap de canais sem ambiguidade.
- Given release normativa, When auditoria verifica changelog, Then impacto e migracao estao explicitados.

## Artifact Minimo do Epico
- registrar resumo em `artifacts/phase-f9/epic-f9-02-telegram-slack-bootstrap.md` com:
  - payload de exemplo de Telegram parseado;
  - checklist de importacao do manifesto Slack;
  - evidencias de testes/gates.

## Dependencias
- [Decision Protocol](../../../PM/DECISION-PROTOCOL.md)
- [Roadmap](../../../PRD/ROADMAP.md)
- [Phase Usability Guide](../../../PRD/PHASE-USABILITY-GUIDE.md)
- [Security Policy](../../../SEC/SEC-POLICY.md)
