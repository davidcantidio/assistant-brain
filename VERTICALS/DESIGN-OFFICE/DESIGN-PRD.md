---
doc_id: "DESIGN-PRD.md"
version: "1.0"
status: "active"
owner: "Lupa"
last_updated: "2026-02-18"
rfc_refs: ["RFC-001", "RFC-010", "RFC-030", "RFC-050"]
---

# Design Office PRD

## Objetivo
Definir vertical de Design Office para gerar direcao criativa auditavel a partir de texto, mantendo controle de risco reputacional.

## Escopo
Inclui:
- fluxo texto -> prompt de imagem
- formato de saida padronizado (prompt, negativos, parametros)
- validacao de formato antes da geracao

Exclui:
- publicacao automatica sem revisao
- geracao sem governanca de risco reputacional

## Regras Normativas
- [RFC-050] MUST registrar prompt final, negativos e parametros usados.
- [RFC-030] MUST validar formato e constraints antes da chamada de geracao.
- [RFC-010] MUST classificar risco reputacional por campanha.

## Formato Auditavel Obrigatorio
```yaml
design_request_id: "DES-YYYYMMDD-XXX"
brief: "..."
style_direction: "..."
prompt_final: "..."
negative_prompt: "..."
params:
  aspect_ratio: "..."
  seed: 123
  steps: 30
  guidance: 7.0
```

## Validacoes
- tamanho minimo/maximo do prompt.
- bloqueio de termos proibidos.
- consistencia entre estilo e publico-alvo.
- seed e parametros presentes.

## Governanca por Risco
- baixo: exploracao interna.
- medio: revisao cloud por amostragem.
- alto (reputacional): checkpoint humano obrigatorio.

## Links Relacionados
- [ARC Model Routing](../../ARC/ARC-MODEL-ROUTING.md)
- [Decision Protocol](../../PM/DECISION-PROTOCOL.md)
- [Security Policy](../../SEC/SEC-POLICY.md)
