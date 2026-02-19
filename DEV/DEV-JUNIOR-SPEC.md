---
doc_id: "DEV-JUNIOR-SPEC.md"
version: "1.0"
status: "active"
owner: "Marvin"
last_updated: "2026-02-18"
rfc_refs: ["RFC-001", "RFC-015", "RFC-050"]
---

# Dev Junior Spec

## Objetivo
Definir o contrato de entrega do agente Dev Junior local para tarefas de codigo de baixo/medio risco.

## Escopo
Inclui:
- formato obrigatorio de entrega tecnica
- checklist de seguranca e edge cases
- limites de atuacao do agente local

Exclui:
- decisoes arquiteturais finais
- merge sem revisao em tarefa relevante

## Regras Normativas
- [RFC-050] MUST entregar `diff/patch + testes + checklist`.
- [RFC-015] MUST operar sem network e sem acesso a secrets.
- [RFC-001] MUST seguir formato padrao de output tecnico.

## Entregaveis Obrigatorios
- patch/diff minimamente invasivo.
- resultado de testes executados.
- checklist de edge cases e limitacoes.
- nota de risco da mudanca.

## Regras de Seguranca
- sem acesso a segredo, token ou credencial.
- sem chamada de rede externa por padrao.
- execucao em sandbox com limites de recurso.

## Formato Padrao de PR/Patch
```md
Contexto:
Mudanca:
Validacao:
Riscos:
Rollback:
```

## Escalacao para Tech Lead
- duvida de arquitetura.
- falha recorrente de teste.
- impacto potencial em seguranca/compliance.

## Links Relacionados
- [Tech Lead Spec](./DEV-TECH-LEAD-SPEC.md)
- [CI Rules](./DEV-CI-RULES.md)
- [SEC Sandboxing](../SEC/SEC-SANDBOXING.md)
