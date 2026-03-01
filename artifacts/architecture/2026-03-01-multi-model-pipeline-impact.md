---
doc_id: "2026-03-01-MULTI-MODEL-PIPELINE-IMPACT.md"
version: "1.0"
status: "active"
owner: "Architecture"
last_updated: "2026-03-01"
rfc_refs: ["RFC-001", "RFC-010", "RFC-040", "RFC-050", "RFC-060"]
---

# Pipeline Multi-Modelo para Mudancas com Codigo - Impacto Arquitetural

## Veredito estrutural
Sem conflito estrutural na hierarquia `PRD -> Epicos -> Fases -> Issues -> Micro-issues executaveis`; conflitos normativos pontuais detectados em autoridade, roteamento e precedencia documental.

## Inputs e placeholders
- `PRD_SECTION_REF`: `PRD/PRD-MASTER.md`
- `REPO_RULES`: GitHub Actions como plataforma oficial; push direto para bypass de governanca permanece proibido; mudanca normativa exige `PRD/CHANGELOG.md`.
- `CI_STEPS`: `make ci-quality`, `make ci-security`, `make eval-gates`, `make eval-models`; para paths `PRD/**`, `SEC/**`, `PM/**`, `ARC/**`, `DEV/**` e `VERTICALS/TRADING/**`, considerar tambem `make eval-trading`.
- `SECURITY_BASELINE`: `SEC/SEC-POLICY.md`, `SEC/SEC-SECRETS.md`, `PM/DECISION-PROTOCOL.md`.
- `CODEOWNERS_POLICY`: placeholder ausente no repo em `2026-03-01`.
- `MAX_ITERATIONS`: `3 ciclos totais`.

## Matriz de conflitos com o PRD atual

| Item impactado | Tipo de conflito | Severidade | Opcoes de resolucao (min. 2) | Recomendacao |
|---|---|---|---|---|
| `PRD-MASTER supervisor_contract / fallback_contract` vs pipeline fixo `M30 -> M14-Code -> Codex 5` | conflito de roteamento e especializacao por task type | media | `1)` tratar o pipeline como override restrito a microtasks com codigo; `2)` reescrever o supervisor_contract global para todo task type | tratar como override restrito a microtasks com codigo, sem alterar defaults globais |
| `DEV-TECH-LEAD-SPEC` vs autoridade final do `Codex 5` | sobreposicao de autoridade de revisao | alta | `1)` mapear `Codex 5` como gate tecnico especifico e manter humano/Tech Lead onde ja exigido; `2)` substituir o Tech Lead pelo gate AI | camada sobre papeis existentes, sem substituir humano obrigatorio |
| `DEV-JUNIOR-SPEC` vs divisao `M30/M14-Code` | conflito de contrato de entrega do executor local | media | `1)` tratar `M30` como gerador inicial e `M14-Code` como executor tecnico principal; `2)` fundir os dois modelos em um unico papel de worker | manter separacao `M30`/`M14-Code` so no pipeline de codigo |
| `ARC-CORE` e `ARC-MODEL-ROUTING` vs pipeline especifico de mudancas com codigo | conflito entre defaults globais de roteamento e fluxo dedicado de codigo | media | `1)` explicitar override documental futuro em `ARC/*`; `2)` assumir que o pipeline substitui o roteamento normativo atual | override restrito a codigo e conflito documentado para ajuste futuro |
| `PM/DECISION-PROTOCOL` vs nocao de gate final quando governanca humana continua obrigatoria | ambiguidade de aprovacao final | alta | `1)` tratar `Codex 5` como pre-gate quando HITL/decision forem exigidos; `2)` permitir que `Codex 5` substitua aprovacao humana | `Codex 5` como pre-gate; aprovacao humana permanece quando ja obrigatoria |
| `DEV-CI-RULES` vs posicao do gate `Codex 5` depois de CI | conflito de ordenacao entre verificacao automatica e revisao | media | `1)` CI obrigatorio antes do gate `Codex 5`; `2)` gate AI antes de CI para economizar custo | gate `Codex 5` sempre depois de CI verde |
| `META/DOCUMENT-HIERARCHY.md` vs uso do `PRD-MASTER` como portador de nova regra normativa, apesar de `PRD/` nao aparecer explicitamente na ordem de precedencia | lacuna de precedencia documental | media | `1)` registrar a lacuna como conflito e sugerir correcao futura; `2)` alterar `META/DOCUMENT-HIERARCHY.md` agora | registrar a lacuna e tratar correcao como sugestao estrutural sujeita a aprovacao |
| `CODEOWNERS_POLICY` ausente no repo vs necessidade de ownership formal de revisao de PR | lacuna de governance/ownership | media | `1)` explicitar placeholder ausente e manter ownership por politica textual; `2)` criar policy formal de `CODEOWNERS` e branch protection | declarar lacuna e tratar `CODEOWNERS` como sugestao estrutural sujeita a aprovacao |

## Failure modes + salvaguardas

| Failure mode | Como detectar | Como mitigar | Acao automatica prevista |
|---|---|---|---|
| Loop infinito de PR | `iteration_index > 3` | cap rigido de iteracoes | `escalate_human` |
| Refactor infinito | rejeicoes repetidas de `Arquitetura` ou `Estilo` sem criterio novo | restringir correcoes ao criterio violado | `freeze_scope_and_split_issue` |
| PR grande demais | diff fora do escopo atomico da `Microtask` | quebrar em novas microtasks | `reject_and_replan` |
| Feedback ambiguo | item sem criterio violado ou sem validacao objetiva | invalidar gate e exigir feedback estruturado | `return_invalid_gate_to_codex5` |
| Flaky tests | alternancia `PASS/FAIL` com mesmo commit | rerun limitado e marca de instabilidade | `quarantine_test_and_escalate` |
| Regressoes silenciosas | CI verde sem teste novo para comportamento alterado | exigir teste ou evidencia explicita | `reject_missing_validation` |
| Drift PRD ↔ codigo | diff contradiz regra vigente ou artifact sem referencia normativa | vinculo obrigatorio a `issue_id` e `criterion_ref` | `hold_and_open_drift_item` |
| Permissoes GitHub insuficientes | falha de `push`, update de PR ou update de status | conta tecnica minima para `M14-Code` | `stop_pipeline_needs_human` |
| Vazamento de segredos | `ci-security` falha ou padrao sensivel aparece em diff/log | bloquear PR, rotacionar segredo e abrir incidente | `block_pr_open_security_incident` |
| Quebra de `CODEOWNERS` | ausencia de owner policy ou PR sem owner quando policy futura exigir | placeholder explicito agora e follow-up aprovado depois | `needs_owner_policy` |
| Conflito de ownership | divergencia entre autor tecnico, gate AI e aprovador humano | cadeia de autoridade explicita | `hold_until_authority_resolved` |
| Excesso de iteracoes | limite total atingido | escalada humana ou reducao de escopo | `escalate_or_split` |
| Divergencia arquitetural entre modelos | rejeicao repetida por `Arquitetura` ou direcao instavel entre `M30` e `M14-Code` | guideline de arquitetura e escopo menor | `human_arch_review` |
| CI falso-verde ou cobertura insuficiente | mudanca relevante sem teste novo ou sem check obrigatorio disparado | exigir evidencia minima de validacao | `reject_missing_ci_evidence` |

## Contrato formal de feedback do Codex 5

Formato canonico em JSON:

```json
{
  "gate_version": "1.0",
  "decision": "APPROVED|REJECTED|NEEDS_HUMAN",
  "issue_id": "ISSUE-...",
  "microtask_id": "MT-...",
  "iteration_index": 1,
  "pr_ref": "PR-...",
  "commit_sha": "abcdef...",
  "generator_model": "M30",
  "executor_model": "M14-Code",
  "gate_model": "Codex 5",
  "upstream_capability_tier": "local_small|local_mid|cloud_large|unknown",
  "ci": {
    "status": "PASS|FAIL",
    "required_checks": [
      "ci-quality",
      "ci-security",
      "ci-evals",
      "ci-routing",
      "ci-trading"
    ],
    "run_refs": ["..."]
  },
  "summary": "string",
  "items": [
    {
      "category": "Bug|Seguranca|Arquitetura|Estilo|Testes|Performance|Observabilidade",
      "file": "relative/or/absolute/path",
      "line_or_snippet": "L10-L16|function foo()|sha256:...",
      "problem": "string",
      "violated_criterion": "string",
      "expected_correction": "string",
      "validation_method": "string",
      "blocking": true
    }
  ]
}
```

Regras obrigatorias:
- `decision=APPROVED` exige `items=[]` ou apenas itens com `blocking=false`.
- `decision=REJECTED` exige ao menos um item com `blocking=true`.
- `decision=NEEDS_HUMAN` exige `summary` com motivo operacional verificavel e ao menos um gatilho de escalada.
- cada item MUST conter exatamente:
  - `category`;
  - `file`;
  - `line_or_snippet`;
  - `problem`;
  - `violated_criterion`;
  - `expected_correction`;
  - `validation_method`;
  - `blocking`.
- `validation_method` e obrigatorio em todos os itens.
- `upstream_capability_tier` altera apenas didatica e granularidade do feedback, nunca a barra de aceite.
- local canonico do artifact:
  - `runs/<issue_id>/<microtask_id>/reviews/codex5-iteration-<n>.json`.

## Impacto Arquitetural Sistemico

Classificacao global: `Moderado`.

### Mudanca no modelo de autoridade
- impacto: moderado.
- leitura: a autoridade fica mais clara se o pipeline for tratado como camada de execucao especifica para codigo.
- risco: sobreposicao semantica com `Tech Lead`, `Gatekeeper/Reviewer` e aprovador humano.

### Aumento de complexidade operacional
- impacto: moderado.
- leitura: adiciona uma etapa tecnica (`M14-Code`) e um gate formal (`Codex 5`) entre implementacao e promote.
- controle: a complexidade permanece contida porque CI, HITL e gates atuais nao sao substituidos.

### Risco de sobreengenharia
- impacto: controlado.
- leitura: o risco existe se o pipeline for aplicado a `doc_change` puro ou a microtasks pequenas demais.
- controle: o pipeline fica restrito a mudancas com codigo/config/script/automacao operacional.

### Risco de latencia no fluxo de entrega
- impacto: moderado.
- leitura: ha aumento de latencia por adicionar revisao `M14-Code`, reruns de CI e gate `Codex 5`.
- controle: `MAX_ITERATIONS=3`, `MAX_CI_REPAIR_ATTEMPTS=2` e fallback humano reduzem churn.

### Custo computacional
- impacto: moderado.
- leitura: ha custo adicional por usar tres modelos/papeis na mesma mudanca com codigo.
- controle: aplicar somente onde ha codigo executavel e risco real de regressao.

### Dependencia excessiva de LLM
- impacto: moderado.
- leitura: o pipeline aumenta dependencia de LLM para gerar, corrigir e revisar.
- controle: CI obrigatorio, contratos tipados, observabilidade, trilha de auditoria e fallback humano.

### Impacto no roadmap
- impacto: controlado.
- leitura: o pipeline e compativel com a camada de execucao do PRD atual e nao muda Fases/Epics/Issues.
- controle: qualquer alinhamento em `ARC/*`, `DEV/*` ou policy de ownership fica como follow-up aprovado.

### Impacto na governanca de PR
- impacto: moderado.
- leitura: melhora rastreabilidade, mas requer clareza de autoridade para nao conflitar com revisao humana e `Tech Lead`.
- controle: `Codex 5` como pre-gate quando houver governanca humana obrigatoria.

## Sugestoes Estruturais (Requer Aprovacao)
- alinhar `ARC/ARC-CORE.md` e `ARC/ARC-MODEL-ROUTING.md` para explicitar override de pipeline em mudancas com codigo.
- alinhar `DEV/DEV-TECH-LEAD-SPEC.md` e `DEV/DEV-JUNIOR-SPEC.md` ao mapeamento `M30/M14-Code/Codex 5`.
- corrigir a precedencia documental em `META/DOCUMENT-HIERARCHY.md` para incluir `PRD/`.
- definir uma politica formal de `CODEOWNERS` e branch protection.
- considerar um agregador formal de status do gate `Codex 5` no CI, sem criar isso nesta rodada.

## Assuncoes fechadas
- `role_mapping = camada sobre papeis existentes`
- `MAX_ITERATIONS = 3 ciclos totais`
- `MAX_CI_REPAIR_ATTEMPTS = 2 por ciclo`
- `CODEOWNERS_POLICY = placeholder ausente no repo`
