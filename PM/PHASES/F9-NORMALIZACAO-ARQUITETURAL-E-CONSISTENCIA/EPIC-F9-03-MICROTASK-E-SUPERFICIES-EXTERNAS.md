---
doc_id: "EPIC-F9-03-MICROTASK-E-SUPERFICIES-EXTERNAS.md"
version: "1.0"
status: "active"
owner: "PM"
last_updated: "2026-03-01"
rfc_refs: ["RFC-001", "RFC-015", "RFC-040", "RFC-050", "RFC-060"]
---

# EPIC-F9-03 Microtask e superficies externas

## Objetivo
Fechar lacunas de materializacao de microtask e governar superficies externas/overrides conceituais para reduzir drift entre arquitetura declarada e pacote normativo executavel.

## Resultado de Negocio Mensuravel
- trilha minima de microtask definida com caminho canonico e evidencia obrigatoria.
- superficies externas classificadas como `governadas` ou `fora_de_escopo` de forma explicita.
- overrides originados de Felix passam a exigir trilha obrigatoria em issue + changelog + traceability.

## Definition of Done (Scrum)
- todas as issues do epic em estado `Done`.
- contrato de microtask com path e artefatos minimos publicado.
- matriz de superficies externas com decisao de escopo publicada.

## Issues (Scrum + TDD + Criterios de Aceitacao)

### ISSUE-F9-03-01 - Definir trilha minima auditavel para microtask
**User story**
Como engineer, quero um contrato minimo de microtask com path canonico para garantir atomicidade, replay e auditoria por unidade executavel.

**Metadata da issue**
- **Owner**: `architecture + pm`
- **Estimativa**: `1d`
- **Dependencias**: `PRD/PRD-MASTER.md`, `PM/WORK-ORDER-SPEC.md`, `scripts/ci/*`
- **Mapped requirements**: `R7`
- **Prioridade**: `P0`
- **Checklist QA/Repro**:
  1. definir path canonico `runs/<issue_id>/<microtask_id>/`;
  2. definir artefatos minimos (`status.json`, `verify.log`, `output.*`, `review/*.json`);
  3. definir regra de bloqueio quando issue de codigo fechar sem evidencia minima.
- **Evidence refs**: `assistant-brain/artifacts/architecture/2026-03-01-architectural-consistency-audit.md:36`, `assistant-brain/artifacts/architecture/2026-03-01-architectural-consistency-audit.md:105-113`

**Plano TDD**
1. `Red`: manter contrato de microtask sem materializacao minima no repositorio.
2. `Green`: explicitar path/artefatos e regra de validacao.
3. `Refactor`: alinhar contrato de microtask com governanca de issue.

**Criterios de aceitacao**
- Given issue com execucao de codigo, When status for `done`, Then trilha de microtask deve existir com artefatos minimos.
- Given ausencia de trilha minima, When validacao rodar, Then resultado deve ser bloqueante.

### ISSUE-F9-03-02 - Governar superficies externas (formalizar ou declarar fora de escopo)
**User story**
Como owner de seguranca, quero classificar superficies externas para evitar dependencias implicitas fora do pacote normativo.

**Metadata da issue**
- **Owner**: `security + pm`
- **Estimativa**: `1d`
- **Dependencias**: `INTEGRATIONS/README.md`, `config/openclaw.env.example`, `felixcraft.md`, `felix-openclaw-pontos-relevantes.md`
- **Mapped requirements**: `R8`
- **Prioridade**: `P1`
- **Checklist QA/Repro**:
  1. listar superficies externas citadas nas fontes Felix e no env template;
  2. classificar cada item como `governado` ou `fora_de_escopo_atual`;
  3. publicar trilha de decisao para itens nao governados.
- **Evidence refs**: `assistant-brain/artifacts/architecture/2026-03-01-architectural-consistency-audit.md:40-41`, `assistant-brain/artifacts/architecture/2026-03-01-architectural-consistency-audit.md:115-120`

**Plano TDD**
1. `Red`: manter superficies externas implicitas sem classificacao formal.
2. `Green`: publicar matriz de classificacao e decisao por superficie.
3. `Refactor`: alinhar matriz com `INTEGRATIONS` e policy de seguranca.

**Criterios de aceitacao**
- Given superficie externa ativa, When revisao de governanca ocorrer, Then deve existir classificacao e trilha de decisao.
- Given superficie nao governada, When for mantida no ambiente, Then deve constar como fora de escopo com risco explicitado.

### ISSUE-F9-03-03 - Endurecer workflow de override Felix com issue + changelog + traceability
**User story**
Como PM, quero que todo override vindo de Felix seja tratado como excecao formal para impedir mudanca estrutural sem trilha normativa.

**Metadata da issue**
- **Owner**: `pm`
- **Estimativa**: `0.5d`
- **Dependencias**: `PM/TRACEABILITY/FELIX-ALIGNMENT-MATRIX.md`, `PRD/CHANGELOG.md`, `PM/TRACEABILITY/ARCHITECTURE-AUDIT-COVERAGE.md`
- **Mapped requirements**: `R9`
- **Prioridade**: `P1`
- **Checklist QA/Repro**:
  1. definir regra obrigatoria de abertura de issue para novo override;
  2. exigir entrada de changelog no mesmo ciclo;
  3. exigir atualizacao da matriz de traceability correspondente.
- **Evidence refs**: `assistant-brain/artifacts/architecture/2026-03-01-architectural-consistency-audit.md:124-129`, `assistant-brain/artifacts/architecture/2026-03-01-architectural-consistency-audit.md:148-156`

**Plano TDD**
1. `Red`: aceitar override Felix sem trilha formal completa.
2. `Green`: exigir trilha completa `issue + changelog + traceability`.
3. `Refactor`: padronizar template de excecao para novos overrides.

**Criterios de aceitacao**
- Given novo override arquitetural, When aprovado, Then deve existir issue vinculada, changelog e update de traceability.
- Given ausencia de um desses itens, When override for revisado, Then resultado deve permanecer `hold`.

## Artifact Minimo do Epico
- publicar cobertura consolidada em `PM/TRACEABILITY/ARCHITECTURE-AUDIT-COVERAGE.md` com:
  - mapeamento de `R7`, `R8`, `R9` para issues;
  - status por superficie externa e por contrato de microtask;
  - riscos residuais e proxima acao recomendada.

## Dependencias
- [Architecture Audit](../../../artifacts/architecture/2026-03-01-architectural-consistency-audit.md)
- [Work Order Spec](../../WORK-ORDER-SPEC.md)
- [Integrations](../../../INTEGRATIONS/README.md)
- [Felix Alignment Matrix](../../TRACEABILITY/FELIX-ALIGNMENT-MATRIX.md)
