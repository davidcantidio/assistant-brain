---
doc_id: "DEV-CI-RULES.md"
version: "1.0"
status: "active"
owner: "Marvin"
last_updated: "2026-02-18"
rfc_refs: ["RFC-001", "RFC-015", "RFC-050"]
---

# Dev CI Rules

## Objetivo
Definir gates de integracao continua para garantir qualidade minima e seguranca antes de merge/deploy.

## Escopo
Inclui:
- checks obrigatorios de qualidade
- checks de seguranca
- condicoes de bloqueio de merge

Exclui:
- bypass manual sem trilha de aprovacao
- merge sem execucao de testes obrigatorios

## Regras Normativas
- [RFC-050] MUST executar lint, typecheck e testes antes de merge.
- [RFC-015] MUST executar verificacoes de seguranca obrigatorias.
- [RFC-001] SHOULD manter pipeline reproduzivel e versionado.

## Gates Obrigatorios
- lint/style.
- typecheck.
- testes unitarios/minimos.
- validacao de schema de artifacts.

## Seguranca
- secret scan em alteracoes.
- dependencia critica com CVE aberto bloqueia merge.
- SAST MAY ser aplicado em modulos de risco elevado.
- validacao de allowlists versionadas:
  - parse de `SEC/allowlists/*.yaml`;
  - checagem de schema/campos obrigatorios;
  - bloqueio de merge em policy invalida ou incompleta.

## Criterios de Merge
- todos os gates verdes.
- sem violacao de politica de seguranca.
- cobertura minima atingida quando definida.
- excecao apenas por decision registrada.

## Links Relacionados
- [Dev Principles](./DEV-PRINCIPLES.md)
- [Tech Lead Spec](./DEV-TECH-LEAD-SPEC.md)
- [Security Policy](../SEC/SEC-POLICY.md)
