---
doc_id: "PHASE-F9-ONBOARDING-EPICS.md"
version: "1.1"
status: "active"
owner: "PM"
last_updated: "2026-03-01"
rfc_refs: ["RFC-001", "RFC-010", "RFC-015", "RFC-030", "RFC-040", "RFC-050"]
---

# F9 Onboarding Credenciais e Canais Automatizados - Epics

## Objetivo da Fase
Padronizar onboarding inicial com auto-geracao de chave LiteLLM, suporte opcional a OpenRouter, preload de Telegram por JSON e manifesto Slack Socket Mode versionado.

## Gate de Saida da Fase
Comandos obrigatorios:

```bash
INTERACTIVE=1 bash scripts/onboard_linux.sh
bash scripts/verify_linux.sh
make ci-quality
make ci-security
make eval-models
```

Criterio objetivo:
- onboarding interativo gera ou coleta `LITELLM_API_KEY` sem lacuna;
- parse de Telegram por JSON preenche defaults operacionais;
- manifesto Slack Socket Mode permanece importavel;
- todos os gates obrigatorios da rodada permanecem verdes.

## Epics da Fase
| Epic ID | Nome | Objetivo | Status | Documento |
|---|---|---|---|---|
| `EPIC-F9-01` | LiteLLM auto-key e OpenRouter opcional | automatizar `LITELLM_API_KEY` via `/key/generate` e manter OpenRouter opcional no baseline | done | [EPIC-F9-01-LITELLM-AUTOKEY-E-OPENROUTER.md](./EPIC-F9-01-LITELLM-AUTOKEY-E-OPENROUTER.md) |
| `EPIC-F9-02` | Bootstrap Telegram e Slack Socket Mode | habilitar preload Telegram por payload e manifesto Slack versionado com comandos HITL | planned | [EPIC-F9-02-BOOTSTRAP-TELEGRAM-E-SLACK-SOCKET-MANIFEST.md](./EPIC-F9-02-BOOTSTRAP-TELEGRAM-E-SLACK-SOCKET-MANIFEST.md) |

## Escopo desta entrega
- criar backlog executavel de onboarding em fase dedicada sem alterar regra canonica de cloud opcional;
- manter rastreabilidade `ROADMAP -> EPIC/ISSUE` para `B0-22`, `B0-23`, `B0-24`.
