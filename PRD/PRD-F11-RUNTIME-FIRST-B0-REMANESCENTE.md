---
doc_id: "PRD-F11-RUNTIME-FIRST-B0-REMANESCENTE.md"
version: "1.1"
status: "active"
owner: "PM"
last_updated: "2026-03-02"
rfc_refs: ["RFC-001", "RFC-010", "RFC-015", "RFC-030", "RFC-040", "RFC-050", "RFC-060"]
---

# PRD F11 - Consolidacao Runtime-First do B0 Remanescente (8 semanas)

## Resumo
Este PRD define a consolidacao tecnica do B0 remanescente com estrategia runtime-first e gates executaveis. A fase MUST fechar o delta entre a convergencia F10 e o control-plane minimo operacional, sem abrir escopo de B1/B2 e sem regressao do canal primario Telegram.

## Estado Atual (2026-03-02)
- A convergencia PRD->runtime da F10 foi concluida em `2026-03-02`.
- `apps/control-plane` e `apps/ops-api` ja possuem baseline implementada (nao estao apenas em scaffold).
- Contratos/schemas canonicos existem em `ARC/schemas/`.
- `platform/policy-engine` esta ativo com contratos de runtime/security/governance e execucao em CI.
- O gap remanescente da F11 e de cobertura operacional integral dos itens B0 in-scope + endurecimento de evidencias de canary/promocao/rollback.
- Timezone operacional canonico permanece `America/Sao_Paulo`.

## Objetivo
Fechar o B0 remanescente com implementacao runtime orientada a contrato (schema-first), mantendo estado operacional e garantindo promocao apenas com hard gates verdes e evidencia auditavel no mesmo ciclo.

## Escopo (In)
1. `B0-08` Model Catalog baseline.
2. `B0-09` Model Router baseline.
3. `B0-11` Memory Plane baseline (`llm_runs`, `router_decisions`, `credits_snapshots`).
4. `B0-13` Budget Governor baseline.
5. `B0-14` Privacidade baseline (`public|internal|sensitive` + provider allowlist + armazenamento minimizado).
6. `B0-17` A2A baseline.
7. `B0-18` Hooks/Webhooks baseline.
8. Endurecimento de `B0-16` em CI para claims centrais desta entrega.

## Escopo (Out)
1. Backlog B1 de trading alem do ja existente.
2. Expansao multiativos (B2).
3. Migracao para microservices alem do minimo necessario.
4. Mudanca de estrategia de canal primario (Telegram permanece primario).

## Bloqueios Arquiteturais Criticos (Hard Gates)
1. Fonte normativa operacional unica MUST seguir precedencia explicita `SEC > PRD > ARC`; decisao de runtime com governanca paralela e proibida.
2. Governanca de PR/branch/ownership MUST permanecer ativa e verificavel em CI.
3. Trilha minima auditavel por microtask (`runs/<issue_id>/<microtask_id>/`) MUST permanecer bloqueante para mudancas de risco `R2/R3`.
4. Promocao para runtime ativo MUST ser bloqueada quando qualquer hard gate falhar.

## Metas de Negocio e SLOs
1. `100%` dos fluxos de roteamento com `requested_model`, `effective_model`, `effective_provider`, `fallback_step`, `reason`.
2. `100%` dos runs inferenciais persistidos em contrato `llm_run`.
3. `100%` dos eventos de A2A e Webhook com `idempotency_key` e `trace_id`.
4. `0` regressao funcional de Telegram nas rodadas de promocao.
5. `100%` dos gates obrigatorios verdes no ciclo final da fase.
6. Orcamento com bloqueio deterministico quando limite diario ou burn-rate exceder politica.

## Alteracoes de APIs/Interfaces/Tipos
### 1) Ops API (contrato minimo obrigatorio da fase)
Base URL:
- `http://127.0.0.1:18901/v1`

Auth e idempotencia:
- `Authorization: Bearer ${OPENCLAW_OPS_API_TOKEN}` MUST ser exigido em endpoints mutaveis.
- `X-Idempotency-Key` MUST ser obrigatorio em `POST`.

Endpoints obrigatorios do nucleo F11:
- `POST /model-catalog/sync`
- `GET /model-catalog/models`
- `POST /router/decide`
- `POST /runs`
- `POST /budget/snapshots`
- `POST /budget/check`
- `POST /a2a/delegate`
- `POST /hooks/ingest`

Envelope de resposta unico:
```json
{
  "status": "ok|error",
  "data": {},
  "error": {
    "code": "string|null",
    "message": "string|null"
  }
}
```

Nota de escopo:
- Endpoints internos HITL (`/internal/hitl/*`) e rotas auxiliares MAY coexistir no runtime como extensao, mas nao entram no nucleo de aceite F11.

### 2) Contrato de payloads (tipos canonicos)
- Todos os payloads MUST ser validados por schema antes de entrada no dominio.
- Payload invalido MUST ser rejeitado com erro estruturado (`status=error`, `error.code`, `error.message`).
- Versao de contrato incompativel MUST bloquear processamento e gerar log explicito.

### 3) Runtime config (compatibilidade com F10)
MUST manter:
- `gateway.bind=loopback`
- `gateway.port=18789`
- `agents.defaults.heartbeat.every=15m`

MUST adicionar sem quebra:
- `memory.telemetry_store.*`
- `privacy.data_sensitivity_default`
- `privacy.provider_allowlist_by_sensitivity`
- `privacy.prompt_storage_mode`

## Contratos de Payload (Schema-First)
Validacao obrigatoria contra:
1. `ARC/schemas/models_catalog.schema.json`
2. `ARC/schemas/router_decision.schema.json`
3. `ARC/schemas/llm_run.schema.json`
4. `ARC/schemas/credits_snapshot.schema.json`
5. `ARC/schemas/budget_governor_policy.schema.json`
6. `ARC/schemas/a2a_delegation_event.schema.json`
7. `ARC/schemas/webhook_ingest_event.schema.json`

Politica de validacao:
- Validacao MUST ocorrer na fronteira da Ops API e no dominio do control-plane.
- Evento rejeitado MUST ser fail-closed (sem side effect).
- Contratos SHOULD preservar `schema_version=1.0` enquanto a fase F11 estiver ativa.

## Runtime config compativel com F10
- Runtime ativo MUST preservar baseline de rede local (`bind=loopback`, `port=18789`) e heartbeat de `15m`.
- Integracao de `memory.telemetry_store.*` MUST permitir backend `memory` para dev/test e `postgres` para runtime canonico.
- Bloco `privacy.*` MUST aplicar classificacao `public|internal|sensitive`, allowlist por sensibilidade e modo de armazenamento minimizado de prompt.
- Mudancas nesse contrato SHOULD disparar `make eval-runtime` no mesmo ciclo.

## Arquitetura de Implementacao (decisao fechada)
1. `apps/control-plane`: regras de dominio e orquestracao.
2. `apps/ops-api`: superficie HTTP interna.
3. Persistencia canonica: Postgres (com extensao vetorial quando aplicavel ao roadmap), sem remover QMD existente.
4. `platform/policy-engine`: gate obrigatorio de conformidade runtime/security/governance.
5. Tudo schema-first: payload invalido nao entra no dominio.

## Matriz de rastreabilidade B0 -> endpoint -> schema -> teste -> gate
| Item B0 | Endpoint(s) | Schema(s) | Teste(s) minimo(s) | Gate(s) obrigatorio(s) |
|---|---|---|---|---|
| `B0-08` Model Catalog | `POST /model-catalog/sync`, `GET /model-catalog/models` | `models_catalog.schema.json` | `TC-MC-01` | `make eval-runtime`, `make eval-gates` |
| `B0-09` Router baseline | `POST /router/decide` | `router_decision.schema.json` | `TC-RTR-01` | `make eval-runtime`, `make eval-gates`, `make policy-test` |
| `B0-11` Memory Plane | `POST /runs`, `POST /router/decide`, `POST /budget/snapshots` | `llm_run.schema.json`, `router_decision.schema.json`, `credits_snapshot.schema.json` | `TC-MEM-01` | `make eval-runtime`, `make eval-gates` |
| `B0-13` Budget Governor | `POST /budget/check`, `POST /budget/snapshots` | `budget_governor_policy.schema.json`, `credits_snapshot.schema.json` | `TC-BDG-01` | `make eval-runtime`, `make eval-gates`, `make ci-quality` |
| `B0-14` Privacidade baseline | `POST /router/decide`, `POST /runs` | `router_decision.schema.json`, `llm_run.schema.json` | `TC-PRV-01` | `make ci-security`, `make eval-runtime`, `make policy-test` |
| `B0-17` A2A baseline | `POST /a2a/delegate` | `a2a_delegation_event.schema.json` | `TC-A2A-01` | `make eval-runtime`, `make eval-gates` |
| `B0-18` Hooks/Webhooks baseline | `POST /hooks/ingest` | `webhook_ingest_event.schema.json` | `TC-HWK-01`, `TC-IDM-01` | `make eval-runtime`, `make eval-gates`, `make ci-security` |
| `B0-16` Hardening CI | n/a (cross-cutting) | n/a (cross-cutting) | cobertura dos `TC-*` centrais + regressao | `make ci-quality`, `make ci-security`, `make policy-test`, `make phase-f10-runtime-convergence` |

## Plano de Execucao (8 semanas)
### Semana 1 - Baseline executavel e hard gates
- Objetivo da semana: congelar contrato tecnico da fase e ativar bloqueios arquiteturais criticos.
- Entrega: matriz de rastreabilidade publicada e backlog tecnico quebrado em issues/microtasks com aceite objetivo.
- DoD: hard gates arquiteturais verdes em CI e trilha de ownership/PR governance auditavel.
- Evidencia esperada: rodada de `ci-quality`, `ci-security`, `eval-runtime` e artifacts de policy/gate no mesmo ciclo.

### Semana 2 - Model Catalog (`B0-08`)
- Objetivo da semana: consolidar sync/list de catalogo com idempotencia e versionamento.
- Entrega: fluxo de sync idempotente com consulta por capacidade/politica.
- DoD: `schema validation 100%`, `no-op` idempotente validado e integridade de catalogo passando.
- Evidencia esperada: execucao dos testes de catalogo + resultado do `TC-MC-01` anexado.

### Semana 3 - Router baseline (`B0-09`)
- Objetivo da semana: aplicar filtro por risco/sensibilidade/policy e ranking baseline.
- Entrega: registro explicavel de decisao com `requested/effective/fallback/reason`.
- DoD: toda decisao roteada gera `router_decision` valido e fallback rastreavel.
- Evidencia esperada: resultados de `TC-RTR-01` + logs de decisao com `trace_id`.

### Semana 4 - Memory Plane (`B0-11`)
- Objetivo da semana: consolidar ingestao de `llm_run`, `router_decision`, `credits_snapshot`.
- Entrega: persistencia e consulta correlacionavel por `trace_id`.
- DoD: nenhum evento invalido entra sem rejeicao explicita.
- Evidencia esperada: resultado de `TC-MEM-01` e consulta de correlacao ponta a ponta.

### Semana 5 - Budget Governor + Privacidade (`B0-13`, `B0-14`)
- Objetivo da semana: enforce financeiro deterministico e enforce de sensibilidade/provider.
- Entrega: bloqueio sincrono antes de side effect quando limite/burn-rate exceder politica.
- DoD: cenarios de bloqueio financeiro e de provider nao permitido passando.
- Evidencia esperada: saidas de `TC-BDG-01` e `TC-PRV-01` com violacoes explicitadas.

### Semana 6 - A2A e Hooks (`B0-17`, `B0-18`)
- Objetivo da semana: consolidar delegacao A2A e ingest webhook com seguranca anti-replay.
- Entrega: allowlist A2A + assinatura webhook + deduplicacao/idempotencia.
- DoD: alvo A2A fora de allowlist e webhook invalido sem side effect.
- Evidencia esperada: resultados de `TC-A2A-01`, `TC-HWK-01`, `TC-IDM-01`.

### Semana 7 - Integracao E2E + hardening CI (`B0-16`)
- Objetivo da semana: encadear fluxos E2E via Ops API e endurecer gates obrigatorios.
- Entrega: cobertura integral de claims centrais em `eval-runtime` e `eval-gates`.
- DoD: artefatos de evidencia gerados por execucao e claims criticas cobertas por teste/gate.
- Evidencia esperada: rodada completa com `make eval-runtime`, `make eval-gates`, `make policy-test` verdes.

### Semana 8 - Canary, promocao e rollback
- Objetivo da semana: executar canary `--dev`, promover runtime ativo e comprovar rollback deterministico.
- Entrega: promocao concluida sem regressao funcional de Telegram e com estado preservado.
- DoD: canary aprovado, promocao ativa validada e rollback comprovado.
- Evidencia esperada: pacote final de canary/promocao/rollback + `TC-TG-01`, `TC-F10-01`, `TC-RBK-01`.

## Estrategia de Testes e Cenarios
### Testes de Contrato
1. Payload valido por schema: `PASS`.
2. Payload invalido: rejeicao com erro estruturado.
3. Versao de contrato incompativel: bloqueio e log explicito.

### Testes Funcionais
1. `TC-MC-01`: sync de catalogo com mesma entrada 2x gera `no-op` idempotente.
2. `TC-RTR-01`: decisao de roteamento em `R2/R3` registra trilha completa.
3. `TC-MEM-01`: run e decisao com mesmo `trace_id` correlacionaveis.
4. `TC-BDG-01`: orcamento excedido bloqueia execucao.
5. `TC-PRV-01`: dado `sensitive` em provider nao permitido e bloqueado.
6. `TC-A2A-01`: delegacao fora de allowlist e rejeitada.
7. `TC-HWK-01`: assinatura invalida bloqueia ingest.
8. `TC-IDM-01`: replay por `idempotency_key` repetida nao duplica efeito.

### Testes de Regressao Operacional
1. `TC-TG-01`: Telegram continua `enabled, configured, running`.
2. `TC-F10-01`: convergencia runtime mantem `heartbeat=15m`.
3. `TC-RBK-01`: rollback restaura baseline funcional sem perda de estado.

## Gates de Aceite
1. `make ci-quality`
2. `make ci-security`
3. `make eval-runtime`
4. `make eval-gates`
5. `make policy-test`
6. `make phase-f10-runtime-convergence`

Criterio final:
1. Todos os gates verdes no mesmo ciclo.
2. Nenhum blocker arquitetural critico aberto.
3. Evidencias de canary, promocao e rollback publicadas.

## Evidencias obrigatorias de canary/promocao/rollback
1. Evidencia de canary `--dev` com timestamp, `trace_id` e resultado de smoke funcional.
2. Evidencia de promocao para runtime ativo com confirmacao de `gateway.bind=loopback`, `gateway.port=18789`, `heartbeat=15m`.
3. Evidencia de rollback deterministico com comparacao pre/post e estado preservado.
4. Evidencias de gates (`ci-quality`, `ci-security`, `eval-runtime`, `eval-gates`, `policy-test`, `phase-f10-runtime-convergence`) no mesmo ciclo.
5. Evidencia explicita de nao regressao de Telegram na rodada final.

## Riscos e Mitigacoes
1. Risco: aceleracao runtime introduzir governanca paralela.
   Mitigacao: hard gates arquiteturais desde semana 1, com precedencia `SEC > PRD > ARC`.
2. Risco: regressao de canal Telegram.
   Mitigacao: teste de regressao a cada rodada de promocao.
3. Risco: integracao parcial sem rastreabilidade completa.
   Mitigacao: schema-first + `trace_id` + `idempotency_key` obrigatorios.
4. Risco: orcamento sem bloqueio efetivo.
   Mitigacao: budget check sincrono antes de side effect.
5. Risco: vazamento de dados sensiveis.
   Mitigacao: classificacao de sensibilidade + allowlist + storage minimizado.

## Assumptions e Defaults fechados
1. Horizonte aprovado: `8 semanas`.
2. Estrategia aprovada: `runtime-first` com bloqueios criticos.
3. Escopo aprovado: `B0 remanescente`.
4. Modo de entrega: `PRD tecnico profundo`.
5. Runtime canonico mantem `loopback`, `port 18789`, `heartbeat 15m`.
6. Timezone operacional permanece `America/Sao_Paulo`.
7. Sem expansao de B1/B2 nesta fase.
8. Toda promocao depende de gates verdes e evidencia auditavel da rodada.

## Links relacionados
- [Roadmap](./ROADMAP.md)
- [PRD Master](./PRD-MASTER.md)
- [Runtime Contract](../contracts/runtime/ops_api.v1.yaml)
- [Runtime Config Schema](../ARC/schemas/openclaw_runtime_config.schema.json)
- [Decision Protocol](../PM/DECISION-PROTOCOL.md)
