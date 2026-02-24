---
doc_id: "DOCUMENT-HIERARCHY.md"
version: "1.2"
status: "active"
owner: "PM"
last_updated: "2026-02-20"
rfc_refs: ["RFC-001", "RFC-015", "RFC-050"]
---

# Document Hierarchy

## Objetivo
Definir precedencia documental e processo de resolucao de conflitos para manter conformidade normativa sem ambiguidade.

## Escopo
Inclui:
- ordem de precedencia entre dominios documentais
- regra de desempate quando houver contradicao
- politica de versionamento sem quebra de compliance
- convencao de nome para reduzir drift por arquivos homonimos

Exclui:
- redefinicao de requisitos de negocio fora do fluxo de changelog
- detalhes de implementacao de codigo

## Regras Normativas
- [RFC-001] MUST resolver conflitos pela hierarquia oficial, nunca por preferencia local.
- [RFC-015] MUST priorizar seguranca quando qualquer regra colidir com performance/custo.
- [RFC-050] MUST registrar conflito resolvido em changelog e decision quando houver impacto operacional.
- [RFC-050] MUST manter fonte canonica unica para memoria/estado operacional.
- [RFC-001] MUST tratar README e guias auxiliares de workspace como documentacao de apoio, nunca como fonte normativa primaria.

## Ordem de Precedencia
1. SEC/
2. CORE/
3. ARC/
4. RAG/
5. PM/
6. DEV/
7. VERTICALS/
8. EVALS/, INCIDENTS/, META/
9. README.md e guias auxiliares de workspace

## Regra de Resolucao de Conflitos
- identificar o conflito e os docs envolvidos.
- aplicar precedencia da lista acima.
- se conflito continuar, abrir decision com evidencias e impacto.
- atualizar documento de menor precedencia para eliminar contradicao futura.
- registrar no changelog normativo.

## Regra para Documentacao Auxiliar
- README e docs operacionais auxiliares MUST refletir os documentos canonicos.
- "documentacao auxiliar prevalece" e proibido para governanca/risco/seguranca.
- contradicao encontrada em doc auxiliar MUST ser corrigida no mesmo ciclo de mudanca.
- `workspaces/*/BOOTSTRAP.md`, `IDENTITY.md`, `USER.md` e `SOUL.md` sao artefatos de onboarding e nao podem bloquear checklist operacional diario.

## Convencao de Nome e Unicidade
- todo documento normativo MUST ter `doc_id` unico no repositorio.
- documentos normativos SHOULD manter prefixo de dominio no nome (`PRD-`, `ARC-`, `SEC-`, `TRADING-`).
- arquivos de scaffold de workspace (`AGENTS.md`, `TOOLS.md`, `BOOTSTRAP.md`) podem repetir nome por design;
  - nesses casos, a identidade canonica e o caminho completo (`workspaces/<office>/...`).

## Fonte de Verdade de Memoria/Estado (Operacional)
- objetivo:
  - eliminar ambiguidade entre memoria de raiz e memoria de workspace.
- canonico (MVP/Fase 0):
  - memoria operacional: `workspaces/main/memory/`.
  - estado de workspace: `workspaces/main/.openclaw/workspace-state.json`.
- nao canonico:
  - `memory/` na raiz (deve ser apenas ponteiro informativo, sem dados operacionais).
  - `sessions/` versionado em git (proibido; usar armazenamento local/segregado).
- em conflito de estado:
  - `workspaces/main/memory/` prevalece;
  - discrepancia MUST abrir incident + task de reconciliacao.

## Versionamento Documental
- mudancas normativas MUST incrementar `version` e `last_updated`.
- mudancas que alteram comportamento MUST citar RFC impactada.
- mudancas sem impacto normativo SHOULD manter mesmo major.
- remocao de regra MUST registrar migracao esperada.

## Links Relacionados
- [RFC Index](./RFC-INDEX.md)
- [PRD Master](../PRD/PRD-MASTER.md)
- [Changelog](../PRD/CHANGELOG.md)
