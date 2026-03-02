---
doc_id: "EPIC-F9-01-LITELLM-AUTOKEY-E-OPENROUTER.md"
version: "1.2"
status: "active"
owner: "PM"
last_updated: "2026-03-01"
rfc_refs: ["RFC-001", "RFC-010", "RFC-015", "RFC-030", "RFC-040", "RFC-050"]
---

# EPIC-F9-01 LiteLLM auto-key e OpenRouter opcional

## Objetivo
Automatizar a obtencao de `LITELLM_API_KEY` no onboarding via `/key/generate`, mantendo fallback manual e compatibilidade com OpenRouter opcional.

## Resultado de Negocio Mensuravel
- setup inicial reduzido para um fluxo interativo unico sem copiacao manual obrigatoria da virtual key;
- onboarding permanece aderente a policy: OpenRouter suportado, porem nao obrigatorio.
- onboarding suporta `OPENCLAW_RUNTIME_MODE` para operacao local-first sem exigir LiteLLM/Codex no modo `local-only`.

## Definition of Done (Scrum)
- todas as issues do epico em estado `Done`.
- `INTERACTIVE=1 bash scripts/onboard_linux.sh` comprova auto-key + fallback manual.
- `make eval-models`, `make ci-quality` e `make ci-security` com `PASS`.

## Issues (Scrum + TDD + Criterios de Aceitacao)

### ISSUE-F9-01-01 - Auto-gerar `LITELLM_API_KEY` no onboarding com fallback manual
**User story**
Como operador, quero gerar automaticamente a virtual key LiteLLM no onboarding para reduzir erros de configuracao inicial.

**Metadata da issue**
- **Owner**: `engineering`
- **Estimativa**: `1d`
- **Dependencias**: `scripts/onboard_linux.sh`, `generate_litellm_virtual_key.py`, `config/openclaw.env.example`, `.env_example`
- **Mapped requirements**: `B0-22`
- **Prioridade**: `P1`
- **Checklist QA/Repro**:
  1. executar onboarding com `LITELLM_MASTER_KEY` e `LITELLM_BASE_URL` validos;
  2. validar derivacao de `LITELLM_PROXY_URL` sem `/v1`;
  3. validar que `LITELLM_API_KEY` e persistida no `.env` quando `/key/generate` responde com sucesso;
  4. forcar falha do endpoint e validar fallback manual de `LITELLM_API_KEY`.
- **Evidence refs**: `scripts/onboard_linux.sh`, `generate_litellm_virtual_key.py`, `config/openclaw.env.example`

**Plano TDD**
1. `Red`: onboarding sem `LITELLM_API_KEY` e sem fallback bloqueia setup.
2. `Green`: auto-geracao preenche chave no `.env`.
3. `Refactor`: fallback manual acionado somente em falha real do endpoint.

**Criterios de aceitacao**
- Given `LITELLM_MASTER_KEY` valido, When onboarding chama `/key/generate`, Then `LITELLM_API_KEY` e gravada no `.env`.
- Given falha no `/key/generate`, When onboarding continua, Then prompt manual de `LITELLM_API_KEY` e exibido.

### ISSUE-F9-01-02 - Tornar `generate_litellm_virtual_key.py` maquina-consumivel sem `requests`
**User story**
Como maintainer, quero que o gerador de key seja consumivel por script shell sem dependencias extras para manter onboarding previsivel.

**Metadata da issue**
- **Owner**: `engineering`
- **Estimativa**: `0.5d`
- **Dependencias**: `generate_litellm_virtual_key.py`
- **Mapped requirements**: `B0-22`
- **Prioridade**: `P1`
- **Checklist QA/Repro**:
  1. validar remocao de dependencia `requests`;
  2. validar modo `LITELLM_OUTPUT_MODE=key-only`;
  3. validar erro explicito quando resposta nao contem chave.
- **Evidence refs**: `generate_litellm_virtual_key.py`

**Plano TDD**
1. `Red`: modo shell nao consegue extrair chave de forma estavel.
2. `Green`: `key-only` retorna apenas a chave.
3. `Refactor`: manter `pretty` e `json` para compatibilidade.

**Criterios de aceitacao**
- Given `LITELLM_OUTPUT_MODE=key-only`, When script executa com sucesso, Then stdout contem somente a key.
- Given resposta sem campo de key, When modo `key-only` executa, Then processo termina com erro.

### ISSUE-F9-01-03 - OpenRouter opcional integrado no onboarding e docs
**User story**
Como operador, quero configurar OpenRouter no mesmo onboarding sem tornalo requisito obrigatorio de verify.

**Metadata da issue**
- **Owner**: `pm+engineering`
- **Estimativa**: `0.5d`
- **Dependencias**: `scripts/onboard_linux.sh`, `scripts/verify_linux.sh`, `README.md`, `DEV/DEV-OPENCLAW-SETUP.md`, `PRD/*`
- **Mapped requirements**: `B0-22`
- **Prioridade**: `P2`
- **Checklist QA/Repro**:
  1. validar prompt explicito de `OPENROUTER_API_KEY` no onboarding;
  2. validar `verify_linux.sh` sem bloqueio quando `OPENROUTER_API_KEY` vazio;
  3. validar docs com semantica de cloud opcional preservada.
- **Evidence refs**: `scripts/onboard_linux.sh`, `scripts/verify_linux.sh`, `README.md`, `DEV/DEV-OPENCLAW-SETUP.md`

**Plano TDD**
1. `Red`: onboarding sem OpenRouter gera ambiguidade documental.
2. `Green`: onboarding pergunta OpenRouter de forma explicita e opcional.
3. `Refactor`: docs normativos e operacionais alinhados.

**Criterios de aceitacao**
- Given `OPENROUTER_API_KEY` vazio, When `verify_linux.sh` roda, Then check nao falha por esse campo opcional.
- Given OpenRouter informado, When onboarding conclui, Then `.env` preserva chave e defaults LiteLLM.

## Artifact Minimo do Epico
- registrar resumo em `artifacts/phase-f9/epic-f9-01-litellm-autokey-openrouter.md` com:
  - cenario de sucesso (`auto-key`);
  - cenario de fallback manual;
  - evidencia dos gates.

## Resultado desta Rodada
- status do epico: `Done`.
- evidencia por issue:
  - `artifacts/phase-f9/epic-f9-01-issue-01-autokey-fallback-hardening.md`;
  - `artifacts/phase-f9/epic-f9-01-issue-02-litellm-keygen-ci-checks.md`;
  - `artifacts/phase-f9/epic-f9-01-issue-03-openrouter-optional-docs.md`;
  - `artifacts/phase-f9/epic-f9-01-litellm-autokey-openrouter.md`.
- gates finais da rodada:
  - `bash scripts/ci/check_quality.sh`: `PASS`;
  - `bash scripts/ci/check_security.sh`: `PASS`;
  - `bash scripts/ci/eval_models.sh`: `PASS`;
  - `bash scripts/verify_linux.sh`: `PASS` com `.env` sem lacuna para `LITELLM_API_KEY`.
- regra preservada:
  - `OPENROUTER_API_KEY` permanece opcional e nao bloqueante no `verify_linux.sh`.
  - `OPENCLAW_RUNTIME_MODE=local-only` torna `LITELLM_API_KEY`, `LITELLM_MASTER_KEY` e `CODEX_OAUTH_ACCESS_TOKEN` opcionais no onboarding/verify;
  - `OPENCLAW_RUNTIME_MODE=hybrid|cloud` mantem obrigatoriedade dessas credenciais.

## Dependencias
- [Roadmap](../../../PRD/ROADMAP.md)
- [PRD Master](../../../PRD/PRD-MASTER.md)
- [Dev OpenClaw Setup](../../../DEV/DEV-OPENCLAW-SETUP.md)
- [Security Policy](../../../SEC/SEC-POLICY.md)
