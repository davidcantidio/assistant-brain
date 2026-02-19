---
doc_id: "DOCUMENT-HIERARCHY.md"
version: "1.0"
status: "active"
owner: "PM"
last_updated: "2026-02-18"
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

Exclui:
- redefinicao de requisitos de negocio fora do fluxo de changelog
- detalhes de implementacao de codigo

## Regras Normativas
- [RFC-001] MUST resolver conflitos pela hierarquia oficial, nunca por preferencia local.
- [RFC-015] MUST priorizar seguranca quando qualquer regra colidir com performance/custo.
- [RFC-050] MUST registrar conflito resolvido em changelog e decision quando houver impacto operacional.
- [RFC-050] MUST manter fonte canonica unica para memoria/estado operacional.

## Ordem de Precedencia
1. SEC/
2. CORE/
3. ARC/
4. RAG/
5. PM/
6. DEV/
7. VERTICALS/
8. EVALS/, INCIDENTS/, META/

## Regra de Resolucao de Conflitos
- Identificar o conflito e os docs envolvidos.
- Aplicar precedencia da lista acima.
- Se conflito continuar, abrir decision com evidencias e impacto.
- Atualizar documento de menor precedencia para eliminar contradicao futura.
- Registrar no changelog normativo.

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
- Mudancas normativas MUST incrementar `version` e `last_updated`.
- Mudancas que alteram comportamento MUST citar RFC impactada.
- Mudancas sem impacto normativo SHOULD manter mesmo major.
- Remocao de regra MUST registrar migracao esperada.

## Links Relacionados
- [RFC Index](./RFC-INDEX.md)
- [PRD Master](../PRD/PRD-MASTER.md)
- [Changelog](../PRD/CHANGELOG.md)
