---
doc_id: "EPIC-F2-01-BASELINE-SEGURANCA-E-GATES.md"
version: "1.1"
status: "active"
owner: "PM"
last_updated: "2026-02-25"
rfc_refs: ["RFC-001", "RFC-015", "RFC-040", "RFC-050", "RFC-060"]
---

# EPIC-F2-01 Baseline de seguranca e gates

## Objetivo
Garantir baseline executavel de seguranca, policy de canal confiavel e gates obrigatorios de CI para bloquear regressao estrutural antes de promover fase.

## Resultado de Negocio Mensuravel
- comandos criticos operam apenas em canal confiavel com controles de autenticacao/challenge.
- nenhum ciclo de fase passa sem `ci-quality`, `ci-security` e `eval-gates` verdes.

## Cobertura ROADMAP
- `B0-14`, `B0-15`, `B0-16`, `B0-19`, `B0-21`.

## Source refs (felix)
- `felixcraft.md`: Trust Ladder, Non-Negotiable Safety Rules, Approval Queue Pattern, Email Security HARD RULES.
- `felix-openclaw-pontos-relevantes.md`: seguranca por canais autenticados vs informacionais; mitigacao gradual de risco.

## Definition of Done (Scrum)
- todas as issues do epico em estado `Done`.
- `make ci-quality`, `make ci-security` e `make eval-gates` executados com sucesso.
- artifact unico do epico com rastreabilidade `B*` e `source_refs`.

## Issues (Scrum + TDD + Criterios de Aceitacao)

### ISSUE-F2-01-01 - Validar gates obrigatorios em CI e fail-fast de promocao
**User story**
Como operador, quero gates obrigatorios no mesmo ciclo para impedir promocao com regressao conhecida.

**Plano TDD**
1. `Red`: simular ciclo sem um dos gates obrigatorios.
2. `Green`: exigir trio completo (`ci-quality`, `ci-security`, `eval-gates`) com bloqueio fail-fast.
3. `Refactor`: padronizar evidencia no artifact semanal/fase.

**Criterios de aceitacao**
- Given gate obrigatorio ausente ou `FAIL`, When revisao de fase ocorre, Then resultado deve ser `hold`.
- Given trio de gates em `PASS`, When revisao de fase ocorre, Then criterio de baseline fica `pass`.

### ISSUE-F2-01-02 - Validar baseline de policy allowlists privacidade e identidade de operador
**User story**
Como operador, quero baseline de allowlists, privacidade e policy canonica para bloquear operacao fora de contrato.

**Plano TDD**
1. `Red`: remover/invalidar allowlist, classificacao de sensibilidade ou policy critica.
2. `Green`: restaurar allowlists canonicas, classificacao `public/internal/sensitive`, provider allowlist e `OPERATORS.yaml` conforme contrato.
3. `Refactor`: rerodar `make ci-security` com evidencia de conformidade.

**Criterios de aceitacao**
- Given allowlist/policy/privacidade invalida, When `make ci-security` roda, Then o gate falha.
- Given baseline canonico restaurado com classificacao e provider allowlist por sensibilidade, When `make ci-security` roda, Then retorna `security-check: PASS`.

### ISSUE-F2-01-03 - Validar regra de canal confiavel + approval queue
**User story**
Como operador, quero fila de aprovacao para acao sensivel e bloqueio de comando por canal nao confiavel.

**Plano TDD**
1. `Red`: permitir comando critico vindo apenas de canal informacional.
2. `Green`: exigir confirmacao em Telegram (ou Slack fallback validado) e challenge.
3. `Refactor`: consolidar regra em protocolo de decisao e security policy.

**Criterios de aceitacao**
- Given comando sensivel vindo de email, When processamento ocorre, Then deve ser registrado como `UNTRUSTED_COMMAND_SOURCE` e bloqueado.
- Given confirmacao por canal confiavel com challenge valido, When processamento ocorre, Then a acao pode prosseguir com trilha auditavel.

## Artifact Minimo do Epico
- registrar em `artifacts/phase-f2/epic-f2-01-security-gates.md`:
  - status dos comandos obrigatorios;
  - status de allowlists e operador/canal;
  - evidencias de approval queue e bloqueio de canal nao confiavel;
  - referencias `B*` cobertas.

## Resultado desta Rodada
- `make ci-quality`: `PASS` (`quality-check: PASS`).
- `make ci-security`: `PASS` (`security-check: PASS`).
- `make eval-gates`: `PASS` (`eval-gates: PASS`).
- `make phase-f2-gate`: `PASS` (`phase-f2-gate: PASS`).
- artifact final publicado: `artifacts/phase-f2/epic-f2-01-security-gates.md`.
- status do epico nesta rodada: `done`.

## Dependencias
- [Security Policy](../../../SEC/SEC-POLICY.md)
- [Decision Protocol](../../../PM/DECISION-PROTOCOL.md)
- [Roadmap](../../../PRD/ROADMAP.md)
- [Felixcraft Architecture](../../../felixcraft.md)
- [Felix OpenClaw Pontos Relevantes](../../../felix-openclaw-pontos-relevantes.md)
