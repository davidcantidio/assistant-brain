---
doc_id: "SEC-INCIDENT-RESPONSE.md"
version: "1.0"
status: "active"
owner: "Security"
last_updated: "2026-02-18"
rfc_refs: ["RFC-001", "RFC-015", "RFC-035", "RFC-050"]
---

# SEC Incident Response

## Objetivo
Definir resposta padrao a incidentes de seguranca com severidade, comunicacao, contencao e aprendizado normativo.

## Escopo
Inclui:
- classificacao SEV-1/SEV-2/SEV-3
- playbook de resposta e comunicacao
- fallback offline e pos-mortem

Exclui:
- investigacao forense detalhada fora do escopo operacional
- fechamento de incidente sem evidencia

## Regras Normativas
- [RFC-015] MUST classificar severidade no momento da deteccao.
- [RFC-035] MUST manter operacao segura em modo degradado quando necessario.
- [RFC-050] MUST registrar linha do tempo, impacto e acao corretiva.
- [RFC-001] MUST atualizar RFC/docs quando incidente expor lacuna normativa.

## Severidades
- SEV-1: risco critico imediato (vazamento ativo, acao perigosa em curso).
- SEV-2: risco relevante controlavel (falha de controle sem impacto irreversivel).
- SEV-3: anomalia menor, sem impacto critico imediato.

## Playbook
1. Detectar e classificar severidade.
2. Conter impacto (bloqueio, kill switch, sandbox restrito).
3. Comunicar humano via Telegram.
4. Acionar degraded mode se dependencia critica falhar.
5. Corrigir causa raiz e validar recuperacao.
6. Fechar com pos-mortem e plano preventivo.

## Comunicacao
- Telegram: alerta imediato para SEV-1/SEV-2.
- fallback offline: registrar em `incidents.log` quando canal indisponivel.
- se Convex/Telegram indisponivel, gerar `human_action_required.md` com passos de recuperacao.
- resumo final MUST incluir impacto, causa e medidas.

## Pos-mortem
- o que aconteceu, por que aconteceu, como foi detectado, como evitar recorrencia.
- atualizar docs afetados e RFCs relacionadas.
- abrir tasks de melhoria com owner e prazo.

## Links Relacionados
- [ARC Degraded Mode](../ARC/ARC-DEGRADED-MODE.md)
- [Incident Log Policy](../INCIDENTS/INCIDENT-LOG-POLICY.md)
- [Security Policy](./SEC-POLICY.md)
