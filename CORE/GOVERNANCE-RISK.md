---
doc_id: "GOVERNANCE-RISK.md"
version: "1.0"
status: "active"
owner: "Frederisk"
last_updated: "2026-02-18"
rfc_refs: ["RFC-001", "RFC-010", "RFC-040", "RFC-050"]
---

# Governance Risk

## Objetivo
Definir o modelo operacional de classificacao de risco e gates de aprovacao para manter velocidade sem perder controle.

## Escopo
Inclui:
- criterios de classificacao de risco
- fluxo por classe (baixo, medio, alto)
- casos que MUST abrir decision obrigatoria

Exclui:
- detalhe de schema de decision e work order
- regras especificas de uma vertical particular

## Regras Normativas
- [RFC-010] MUST classificar toda tarefa antes da execucao.
- [RFC-010] MUST aplicar gate de aprovacao proporcional ao risco.
- [RFC-040] MUST abrir decision em conflito de risco, budget ou escopo.
- [RFC-050] MUST registrar evidencia de classificacao e motivo.

## Criterios de Risco
- impacto financeiro potencial (baixo, moderado, alto)
- acao no mundo real (deploy, compra, envio externo, trading)
- impacto reputacional e regulatorio
- alteracao de dados oficiais/sensiveis
- superficie de seguranca e privacidade

## Gates por Classe
- Baixo:
  - execucao 100% local com validacao deterministica.
  - sem aprovacao cloud obrigatoria.
- Medio:
  - execucao local com revisao cloud por amostragem ou checkpoint.
  - auditoria reforcada em saida.
- Alto:
  - execucao local apenas como rascunho/evidencia.
  - aprovacao cloud obrigatoria e HITL quando configurado.

## Politica de Amostragem (Medio Risco)
- taxa base: 20% dos itens por sprint.
- elevar para 50% quando houver regressao de qualidade.
- elevar para 100% quando houver incidente recente (ultimos 7 dias).
- reduzir para 10% apos 14 dias sem incidentes criticos.

## Tabela de Exemplos
| Exemplo | Classe | Gate |
|---|---|---|
| Ajuste textual interno com fonte citada | Baixo | Local + validacao |
| Repriorizacao de sprint com impacto de custo | Medio | Local + checkpoint cloud |
| Troca de estrategia de trading live | Alto | Decision + cloud + humano |
| Alteracao de permissao de dados entre empresas | Alto | Decision obrigatoria |

## Integracao com ARC e PM
- Circuit breaker (ARC) MUST interromper fluxo apos limite de falha/custo/tempo.
- Decision Protocol (PM) MUST ser acionado para overrides, excecoes e desbloqueios.

## Links Relacionados
- [ARC Core](../ARC/ARC-CORE.md)
- [ARC Observability](../ARC/ARC-OBSERVABILITY.md)
- [Decision Protocol](../PM/DECISION-PROTOCOL.md)
- [Work Order Spec](../PM/WORK-ORDER-SPEC.md)
