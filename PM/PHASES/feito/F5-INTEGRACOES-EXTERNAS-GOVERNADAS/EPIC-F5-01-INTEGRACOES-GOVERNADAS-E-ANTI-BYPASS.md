---
doc_id: "EPIC-F5-01-INTEGRACOES-GOVERNADAS-E-ANTI-BYPASS.md"
version: "1.2"
status: "done"
owner: "PM"
last_updated: "2026-03-01"
rfc_refs: ["RFC-001", "RFC-010", "RFC-015", "RFC-050", "RFC-060"]
---

# EPIC-F5-01 Integracoes governadas e anti-bypass

## Objetivo
Fechar contratos de integracao externa com bloqueio tecnico de ordem direta, governanca explicita por modo permitido e trilha de auditoria ponta a ponta.

## Resultado de Negocio Mensuravel
- frameworks externos deixam de ter qualquer caminho direto para exchange.
- modo permitido de cada integracao fica verificavel por gate, sem ambiguidade.

## Cobertura ROADMAP
- `B1-01`, `B1-02`, `B1-03`, `B1-11`, `B1-20`, `B1-21`, `B1-22`, `B1-23`, `B1-24`.

## Source refs (felix)
- `felixcraft.md`: OpenClaw as gateway platform, hooks/transforms, channelized trust model.
- `felix-openclaw-pontos-relevantes.md`: separacao de chats/sessoes, anti-injection por canal, operacao multi-projeto sem mistura de contexto.

## Definition of Done (Scrum)
- todas as issues do epico em estado `Done`.
- `make eval-integrations` e `make eval-trading` em `PASS` no mesmo ciclo.
- evidencias anti-bypass consolidadas no artifact do epico e em `artifacts/phase-f5/validation-summary.md`.

## Issues (Scrum + TDD + Criterios de Aceitacao)

### ISSUE-F5-01-01 - Validar adapter TradingAgents signal_intent com normalizacao e deduplicacao
**Owner** `Tech Lead Integrations`
**Estimativa** `1d`
**Dependencias**
- `INTEGRATIONS/AI-TRADER.md`
- `VERTICALS/TRADING/TRADING-PRD.md`
- `artifacts/phase-f5/epic-f5-01-issue-01-tradingagents-signal-intent.md`
**Labels** `prio:medium`, `risk:integration`, `needs-qa`, `needs-owner`, `needs-estimation`
**Definition of Ready**
- fixture de payload valido/invalido mapeada para `signal_intent`.
- regra de deduplicacao por `trace_id` identificada no fluxo canonico.
**Definition of Done**
- contrato de entrada/saida descrito sem ambiguidade.
- evidencias da validacao e do replay rejeitado anexadas no artifact da issue.
- `make eval-trading` e `make eval-integrations` sem regressao documental.
**User story**
Como operador, quero sinais tipados e deduplicados para evitar ruido operacional e perda de rastreabilidade.

**Plano TDD**
1. `Red`: aceitar payload sem contrato `signal_intent` ou sem trace de origem.
2. `Green`: exigir adapter canonical + normalizacao + deduplicacao.
3. `Refactor`: consolidar trilha de origem no artifact do epico.

**Criterios de aceitacao**
- Given payload sem `signal_intent`, When `make eval-trading` roda, Then resultado deve ser `FAIL` com erro deterministico de contrato ausente.
- Given payload duplicado com o mesmo `trace_id`, When a normalizacao ocorre, Then apenas um evento pode seguir e o duplicado deve ser rejeitado como replay auditavel.
- Given payload valido com origem do engine registrada, When a validacao roda, Then o artifact da issue deve registrar engine de origem e resultado `PASS`.

**Passos QA**
1. Executar fixture sem `signal_intent` e capturar a falha esperada.
2. Executar fixture duplicada com mesmo `trace_id` e confirmar rejeicao do replay.
3. Executar fixture valida e anexar evidencia da origem do engine no artifact.

### ISSUE-F5-01-02 - Validar bloqueio tecnico de ordem direta externa e allowlist de venue
**Owner** `Tech Lead Trading`
**Estimativa** `1d`
**Dependencias**
- `VERTICALS/TRADING/TRADING-PRD.md`
- `SEC/allowlists/DOMAINS.yaml`
- `artifacts/phase-f5/epic-f5-01-issue-02-direct-order-block-venue-allowlist.md`
**Labels** `prio:p0`, `risk:security`, `blocking-release`, `needs-qa`, `needs-owner`
**Definition of Ready**
- venue allowlist mapeada para os dominios ativos da fase.
- regra de rollback para bypass live alinhada com `TRADING_BLOCKED`.
**Definition of Done**
- tentativa de bypass gera bloqueio, incidente e rollback descritos no texto.
- caminho fora da allowlist fica explicitamente reprovado.
- artifact da issue referencia anti-bypass e rollback no mesmo ciclo dos gates.
**User story**
Como operador, quero bloqueio hard de ordem direta para exchange para impedir bypass de risco.

**Plano TDD**
1. `Red`: permitir tentativa de ordem direta fora do execution gateway.
2. `Green`: bloquear tecnicamente e exigir venue em allowlist.
3. `Refactor`: consolidar testes de bloqueio no gate de trading.

**Criterios de aceitacao**
- Given tentativa de ordem direta fora do `execution_gateway`, When a validacao ocorre, Then resultado deve ser `FAIL`, abrir incidente com `trace_id` e impedir qualquer envio a venue.
- Given dominio de venue fora da `SEC/allowlists/DOMAINS.yaml`, When a validacao ocorre, Then resultado deve ser `FAIL` com bloqueio hard e sem bypass operacional.
- Given bypass detectado em contexto live, When o incidente e classificado, Then o sistema MUST entrar em `TRADING_BLOCKED` e executar rollback conforme runbook de degradacao.

**Passos QA**
1. Simular tentativa de ordem direta fora do gateway e registrar o `trace_id` do bloqueio.
2. Simular venue fora da allowlist e confirmar ausencia de envio.
3. Validar que o artifact registra `TRADING_BLOCKED`, incidente e rollback executavel.

### ISSUE-F5-01-03 - Validar contratos versionados de integracao e compatibilidade dual do runtime
**Owner** `Tech Lead Integrations`
**Estimativa** `1d`
**Dependencias**
- `ARC/schemas/`
- `INTEGRATIONS/OPENCLAW-UPSTREAM.md`
- `artifacts/phase-f5/epic-f5-01-issue-03-versioned-contracts-runtime-dual.md`
**Labels** `prio:high`, `risk:integration`, `needs-qa`, `needs-owner`
**Definition of Ready**
- quatro contratos obrigatorios identificados em `ARC/schemas/`.
- politica de runtime dual (`gateway.control_plane.ws` canonico e `chatCompletions` opcional) revisada.
**Definition of Done**
- ausencia de versionamento ou campo minimo quebra `make eval-integrations`.
- compatibilidade dual e policy de provider ficam descritas no texto.
- artifact consolida evidencias por schema obrigatorio.
**User story**
Como operador, quero contratos versionados para manter integracao estavel e auditavel.

**Plano TDD**
1. `Red`: remover versao ou campos minimos de contratos de integracao.
2. `Green`: restaurar schemas versionados + compatibilidade `ws` canonico e `chatCompletions` opcional.
3. `Refactor`: alinhar links de contrato com matriz de integracoes.

**Criterios de aceitacao**
- Given qualquer um dos quatro contratos obrigatorios sem `schema_version`, When `make eval-integrations` roda, Then o gate deve retornar `FAIL` com identificacao do schema faltante.
- Given runtime dual sem `gateway.control_plane.ws` canonico ou com `chatCompletions` fora de policy, When `make eval-integrations` roda, Then o gate deve retornar `FAIL`.
- Given contratos completos e compatibilidade dual valida, When `make eval-integrations` roda, Then o gate deve retornar `PASS` e o artifact deve anexar a cobertura por arquivo.

**Passos QA**
1. Validar cada schema obrigatorio com ausencia de `schema_version`.
2. Validar cenario negativo de runtime dual fora de policy.
3. Registrar as evidencias de `PASS` por contrato e por provider path.

### ISSUE-F5-01-04 - Validar modo permitido por integracao sem ambiguidade operacional
**Owner** `PM + Tech Lead Integrations`
**Estimativa** `1d`
**Dependencias**
- `INTEGRATIONS/README.md`
- `INTEGRATIONS/CLAWWORK.md`
- `artifacts/phase-f5/epic-f5-01-issue-04-allowed-modes-no-ambiguity.md`
**Labels** `prio:high`, `risk:compliance`, `needs-qa`, `needs-po-review`, `needs-owner`
**Definition of Ready**
- template normativo `INTEGRATIONS` com campos obrigatorios identificado.
- politica E2B de ClawWork revisada com owner funcional.
**Definition of Done**
- objetivo, modo permitido, contratos, riscos, testes e rollback ficam explicitos no template.
- `AI-Trader` e `ClawWork` ficam sem ambiguidade operacional.
- artifact da issue referencia a matriz completa e a policy E2B.
**User story**
Como operador, quero regras explicitas de modo permitido para AI-Trader e ClawWork sem interpretacao ad hoc.

**Plano TDD**
1. `Red`: manter linguagem ambigua sobre modo permitido por integracao.
2. `Green`: explicitar AI-Trader `signal_only` e ClawWork `lab_isolated` default + `governed` com gateway-only.
3. `Refactor`: consolidar checklist de conformidade por integracao.

**Criterios de aceitacao**
- Given integracao sem qualquer campo obrigatorio do template (`objetivo`, `modo`, `contratos`, `riscos`, `testes`, `rollback`), When a revisao ocorre, Then resultado deve ser `hold`.
- Given `AI-Trader` em `signal_only` e `ClawWork` em `lab_isolated` por default ou `governed` com `gateway-only`, When a policy E2B esta explicita, Then resultado deve ser `PASS`.
- Given ausencia de rollback documentado ou de matriz de compatibilidade runtime, When a revisao ocorre, Then resultado deve ser `hold` e bloquear promote da fase.

**Passos QA**
1. Validar o template campo a campo no pacote `INTEGRATIONS`.
2. Confirmar a policy E2B e a matriz de compatibilidade runtime.
3. Registrar evidencia da revisao de rollback e do resultado final da issue.

## Artifact Minimo do Epico
- registrar em `artifacts/phase-f5/epic-f5-01-integrations-anti-bypass.md`:
  - status do adapter de sinais;
  - evidencias de bloqueio de ordem direta;
  - status de contratos versionados e compatibilidade dual;
  - referencias `B*` cobertas;
  - referencia cruzada para `artifacts/phase-f5/validation-summary.md`.

## Resultado desta Rodada
- `make eval-integrations` final: registrar em `artifacts/phase-f5/validation-summary.md`.
- `make eval-trading` final: registrar em `artifacts/phase-f5/validation-summary.md`.
- `make ci-quality` final: sem regressao documental esperada para os markdowns da F5.
- evidencias por issue publicadas:
  - `artifacts/phase-f5/epic-f5-01-issue-01-tradingagents-signal-intent.md`;
  - `artifacts/phase-f5/epic-f5-01-issue-02-direct-order-block-venue-allowlist.md`;
  - `artifacts/phase-f5/epic-f5-01-issue-03-versioned-contracts-runtime-dual.md`;
  - `artifacts/phase-f5/epic-f5-01-issue-04-allowed-modes-no-ambiguity.md`.
- evidencia consolidada do epico:
  - `artifacts/phase-f5/epic-f5-01-integrations-anti-bypass.md`.
- conclusao: `EPIC-F5-01` corrigido para atender a auditoria documental da F5.

## Dependencias
- [Integrations Readme](../../../../INTEGRATIONS/README.md)
- [Trading Enablement Criteria](../../../../VERTICALS/TRADING/TRADING-ENABLEMENT-CRITERIA.md)
- [Roadmap](../../../../PRD/ROADMAP.md)
- [Felixcraft Architecture](../../../../felixcraft.md)
- [Felix OpenClaw Pontos Relevantes](../../../../felix-openclaw-pontos-relevantes.md)
