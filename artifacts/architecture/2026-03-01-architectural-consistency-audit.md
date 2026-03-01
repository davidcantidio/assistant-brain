---
doc_id: "2026-03-01-ARCHITECTURAL-CONSISTENCY-AUDIT.md"
version: "1.0"
status: "active"
owner: "Architecture"
last_updated: "2026-03-01"
rfc_refs: ["RFC-001", "RFC-010", "RFC-015", "RFC-040", "RFC-050", "RFC-060"]
---

# Auditoria de Consistencia Arquitetural do OpenClaw

## Escopo e baseline
- escopo auditado: `assistant-brain/`
- visoes comparadas:
  - `PRD(main)` = estado em `HEAD main`
  - `PRD(working tree)` = estado local atual
  - `Implementacao` = workflows, scripts, schemas, workspace canonico, artifacts e configuracao real do repo
  - `Felix` = `felixcraft.md` + `felix-openclaw-pontos-relevantes.md`
- exclusoes: `.git`, `.venv-docling`, binarios, `__pycache__`, `deep-research-report*.md` e qualquer arquivo fora de `assistant-brain/`

## Evidencia operacional observada em 2026-03-01
- `make ci-quality`: `PASS`
- `make phase-f2-gate`: `PASS`
- `make phase-f8-contract-review`: `PASS`
- `make eval-trading-multiasset`: `PASS`
- leitura correta dessa evidencia:
  - os gates atuais estao verdes;
  - isso prova governanca documental executavel;
  - isso NAO prova que o control-plane alvo ja esteja implementado.

## Matriz de Conflitos

| Origem | Elemento | Tipo de Conflito | Descricao | Severidade | Risco Sistemico | Opcoes de Resolucao | Recomendacao |
|---|---|---|---|---|---|---|---|
| `PRD(main) + Implementacao + Felix` | Hierarquia documental e fonte de autoridade | Autoridade decisoria | A hierarquia oficial coloca `felixcraft.md` acima de todo o resto, inclusive da pilha PRD/PM/ARC/SEC, e essa regra e repetida em docs operacionais. O proprio `PRD-MASTER` registra que `felixcraft.md` foi adotado como referencia arquitetural suprema. Isso cria autoridade paralela: Felix pode introduzir direcao arquitetural sem passar primeiro por normalizacao no PRD. Evidencias: `META/DOCUMENT-HIERARCHY.md:33-50`; `README.md:10-16`; `workspaces/main/AGENTS.md:6-18`; `PRD/PRD-MASTER.md@HEAD:701-707`. | Critica | Modelo de autoridade quebrado; arquitetura paralela implicita; qualquer conflito entre Felix e PRD passa a depender de interpretacao local. | `1)` rebaixar Felix para referencia conceitual/import externo e tornar PRD/SEC/ARC a fonte normativa; `2)` manter Felix no topo, mas tornar todo PRD explicitamente derivado e sincronizado por changelog/decision. | Adotar `1)`. Felix deve alimentar o sistema por traceabilidade e changelog, nao por precedencia suprema. |
| `PRD(main) vs Implementacao(PM)` | Cadeia estrutural de planejamento | Estrutural | O repositorio usa fases em `PM/PHASES/` e o `PRD-MASTER` define `Issue -> Microtask` com DAG, DoR/DoD e estados canonicamente tipados. Em paralelo, `SCRUM-GOV` ainda governa por `PRD -> epicos -> sprint -> tasks` e para nesse nivel. Isso fragmenta a linguagem estrutural: fase/issue/microtask existem no PRD e na arvore, mas sprint/task continuam como cadeia operacional concorrente. Evidencias: `PRD/ROADMAP.md:17-20,38-44`; `PRD/PRD-MASTER.md:133-174`; `PM/SCRUM-GOV.md:30-40`; arvore `PM/PHASES/` organizada por fases e epicos. | Alta | Drift na decomposicao do trabalho, ambiguidade entre `task` e `Issue/Microtask`, perda de rastreabilidade na governanca diaria. | `1)` canonizar `PRD -> Fases -> Epicos -> Issues -> Microtasks` e tratar sprint apenas como janela/capacidade; `2)` reduzir PRD para o modelo `epico -> sprint -> task` e abandonar formalmente `Issue/Microtask`. | Adotar `1)`. O repo ja tem fases/epicos e o PRD ja investiu no contrato de microtask; o menor ajuste e alinhar `SCRUM-GOV`. |
| `PRD(main) vs Implementacao` | Micro-issues executaveis e trilha por microtask | Drift tecnico | O `PRD-MASTER` exige microtasks tipadas, estados proprios e artifacts em `runs/<issue_id>/<microtask_id>/reviews/...`. Na implementacao real, a governanca materializada continua issue-level: `PM/PHASES/` contem epicos/fases, `artifacts/` concentra saidas por fase/epic/issue, e nao existe diretorio `runs/` no repo. Evidencias: `PRD/PRD-MASTER.md@HEAD:682-694`; `PRD/PRD-MASTER.md:825-826`; `PM/SCRUM-GOV.md:30-40`; snapshot da arvore de topo (`.github`, `ARC`, `PM`, `artifacts`, `scripts`, `workspaces`) sem `runs/`; `artifacts/` dominado por `epic-*` e `issue-*`. | Alta | Atomicidade prometida, replay por microtask e auditabilidade de execucao permanecem nao materializados. | `1)` implementar ledger/artifact minimo por microtask e caminho `runs/<issue_id>/<microtask_id>/`; `2)` rebaixar o contrato de microtask de "implementado" para "arquitetura alvo" enquanto o control-plane nao existir. | Adotar `1)` como norte e `2)` como status imediato. O texto atual superdeclara execucao frente ao que o repo materializa. |
| `PRD(working tree) vs ARC/DEV/PM` | Pipeline `M30 -> M14-Code -> Codex 5` | Sobreposicao de arquitetura | O working tree torna normativo um pipeline de codigo com novos papeis, ownership de commit/PR e gate especifico, mas sem harmonizar os contratos vigentes de roteamento, Tech Lead, Dev Junior e Decision Protocol. O proprio changelog local admite conflito pontual e ausencia de alteracao em `ARC/*`, `DEV/*`, `PM/*` e `.github/*`. Evidencias: `PRD/PRD-MASTER.md:696-858`; `PRD/CHANGELOG.md:32-63`; `DEV/DEV-TECH-LEAD-SPEC.md:31-40`; `DEV/DEV-JUNIOR-SPEC.md:30-39`; `ARC/ARC-MODEL-ROUTING.md:106-126`; `PM/DECISION-PROTOCOL.md:26-55`. | Alta | Dupla autoridade tecnica, gate paralelo de revisao e regra nova de PR sem enforcement correspondente. | `1)` rebaixar a secao para proposta/RFC ate normalizar ARC/DEV/PM/CI; `2)` manter a secao no PRD e atualizar, no mesmo ciclo, todos os contratos tocados. | Adotar `1)` no curto prazo. Hoje a secao esta mais madura como proposta de arquitetura do que como norma integrada. |
| `PRD(working tree) vs Implementacao(.github)` | PR governance, branch policy e ownership | Governanca | O pipeline do working tree depende de ownership explicito de PR, `gate_decision_ref` e follow-up de `CODEOWNERS`, mas a implementacao real continua limitada a workflows `push main`/`pull_request`, sem `CODEOWNERS` versionado e sem policy formal de branch protection. O changelog local reconhece explicitamente o placeholder ausente. Felix adiciona ainda a expectativa de `staging branch` e `auto-merge if tests pass`. Evidencias: `PRD/PRD-MASTER.md:764-786`; `PRD/CHANGELOG.md:52-63`; `ci-quality.yml:3-14`; `ci-trading.yml:3-34`; arvore `.github/` contendo apenas workflows; `felixcraft.md:267`; `felixcraft.md:354`; `felixcraft.md:595`; `felixcraft.md:613`; `felixcraft.md:628-633`. | Alta | Merge policy ambigua, ownership nao enforceable e alto risco de cada texto assumir um branch model diferente. | `1)` formalizar `CODEOWNERS` + branch policy + branch protection; `2)` remover do PRD qualquer dependencia normativa de branch/ownership nao implementada. | Adotar `1)` se o pipeline multi-modelo continuar. Sem isso, o working tree cria regra sem trilho de enforcement. |
| `Felix vs Implementacao normativa` | Superficies externas de operacao fora do pacote normativo | Drift conceitual | Felix opera ou sugere operar com Vercel, Stripe, X/Twitter, email/Fastmail/Himalaya, Sentry e fluxos de bugfix em staging. O repo, entretanto, formaliza o pacote `INTEGRATIONS/` apenas para AI-Trader, ClawWork e OpenClaw upstream. O template de ambiente ja expoe parte dessas dependencias, mas sem pacote normativo equivalente. Evidencias: `felix-openclaw-pontos-relevantes.md:63-77`; `felix-openclaw-pontos-relevantes.md:140-147`; `felix-openclaw-pontos-relevantes.md:196-240`; `felixcraft.md:354-376`; `felixcraft.md:595-633`; `config/openclaw.env.example:58-163`; `INTEGRATIONS/README.md:12-20`; `INTEGRATIONS/README.md:36-58`. | Media | Dependencias externas implicitas, superficie de risco maior que o pacote normativo documentado e espaco para governanca paralela por exemplo operacional. | `1)` formalizar cada superficie externa ativa em `INTEGRATIONS/`; `2)` declarar essas superficies como fora de escopo do OpenClaw atual e manter Felix apenas como referencia. | Adotar `2)` ate haver contrato por integracao. O env example nao deveria ser confundido com habilitacao governada. |

## Mapa de Drift

### Drift do estado commitado

| Topico | `PRD(main)` | `PRD(working tree)` | Implementacao | Felix | Classe | Justificativa |
|---|---|---|---|---|---|---|
| Fonte de autoridade | o proprio `PRD-MASTER` registra `felixcraft.md` como referencia arquitetural suprema | mantem esse quadro | `META`, `README` e `AGENTS` executam Felix no topo da hierarquia | Felix continua sendo documento conceitual externo e amplo | Critico | O drift nao e "texto atrasado"; e um modelo de autoridade onde o PRD deixa de ser capaz de fechar a arquitetura sozinho. Evidencias: `PRD/PRD-MASTER.md@HEAD:701-707`; `META/DOCUMENT-HIERARCHY.md:33-50`; `README.md:10-16`; `workspaces/main/AGENTS.md:6-18`. |
| Cadeia de planejamento | fases + backlog formal em `PRD/ROADMAP` e `Issue -> Microtask` em `PRD-MASTER` | working tree reforca `Micro-issue executavel = Microtask` | `SCRUM-GOV` governa por sprint/task e os artifacts seguem issue-level | Felix trabalha com PRDs/checklists e Ralph loops, sem cadeia formal de fases/issues | Alto | A arquitetura real de planejamento e tripla: fase/epico na arvore, sprint/task em PM e PRD/checklist em Felix. Evidencias: `PRD/ROADMAP.md:17-20,38-44`; `PRD/PRD-MASTER.md:133-174`; `PM/SCRUM-GOV.md:30-40`; `PRD/PRD-MASTER.md:722-729`. |
| Maturidade do control-plane | o status do repo reconhece "arquitetura de papel" enquanto ARC define o alvo `Control Plane`/`Memory Plane` | sem mudanca estrutural | a implementacao presente e composta por schemas, scripts, workflows, allowlists, artifacts e workspace state | Felix descreve um runtime vivo com cron, tmux, webhooks, canais e operacao diaria | Moderado | Existe diferenca grande entre a arquitetura alvo e a implementacao atual, mas o proprio repo a declara. O risco e de leitura equivocada, nao de declaracao falsa explicita. Evidencias: `README.md:5-8`; `ARC/ARC-CORE.md:34-56`; `ARC/ARC-CORE.md:188-213`; `DEV/DEV-OPENCLAW-SETUP.md:46-84`; `felix-openclaw-pontos-relevantes.md:138-170`. |
| Integracoes externas | pacote normativo cobre AI-Trader, ClawWork e OpenClaw upstream | sem mudanca | o env example ja expoe Telegram, Slack, email, GitHub, Sentry, Stripe, Cloudflare, Calendar e QMD | Felix assume Vercel, Stripe, X/Twitter, Sentry, email e GitHub como superficies operacionais do agente | Moderado | O repo esta mais perto de "capacidade tecnica latent" do que de "integracao governada". Evidencias: `INTEGRATIONS/README.md:12-20`; `INTEGRATIONS/README.md:36-58`; `config/openclaw.env.example:46-163`; `felix-openclaw-pontos-relevantes.md:196-240`. |

### Drift introduzido pelo working tree

| Topico | `PRD(main)` | `PRD(working tree)` | Implementacao | Felix | Classe | Justificativa |
|---|---|---|---|---|---|---|
| Pipeline multi-modelo de codigo | papeis canonicamente descritos como Worker, Verifier, Gatekeeper e humano | adiciona `M30`, `M14-Code` e `Codex 5` com ownership e fluxo proprios | nao ha workflow, policy, schema ou artifact operacional novo suportando esse pipeline | Felix fala em split planejamento/execucao, worktrees e staging, mas nao define esse trio de papeis | Alto | O working tree cria direcao nova que ainda nao virou contrato sistemico. Evidencias: `PRD/PRD-MASTER.md@HEAD:680-694`; `PRD/PRD-MASTER.md:696-858`; `PRD/CHANGELOG.md:32-63`; `artifacts/architecture/2026-03-01-multi-model-pipeline-impact.md:23-34`. |
| Ownership de PR e branch model do pipeline | merge criteria genericos em CI e Tech Lead | working tree passa a depender de `M14-Code` como unico autor tecnico de PR e de `Codex 5` como pre-gate | `.github/` continua sem `CODEOWNERS` e sem branch policy formal; workflows seguem `main`/`pull_request` | Felix opera com `staging branch`, worktrees e `auto-merge if tests pass` em certos cenarios | Alto | O delta local introduz uma norma de PR que ainda nao tem nem enforcement nem branch model fechado. Evidencias: `PRD/PRD-MASTER.md:764-786`; `PRD/CHANGELOG.md:56-63`; `ci-quality.yml:3-14`; `ci-trading.yml:3-34`; `felixcraft.md:521`; `felixcraft.md:630-633`. |

### Felix como terceira direcao

| Topico | `PRD(main)` | `PRD(working tree)` | Implementacao | Felix | Classe | Justificativa |
|---|---|---|---|---|---|---|
| Branching, staging e auto-merge | GitHub Actions em `main`/`pull_request`, sem branch model formal | adiciona dependencia de pipeline por PR sem resolver branch policy | workflows nao expressam `staging`, `auto-merge` nem `CODEOWNERS` | Felix assume staging, worktrees e `auto-merge if tests pass` para certos fluxos | Alto | Felix opera com uma filosofia de branch/release nao absorvida pela governanca atual do repo. Evidencias: `DEV/DEV-CI-RULES.md:57-70`; `ci-quality.yml:3-14`; `felixcraft.md:267`; `felixcraft.md:521`; `felixcraft.md:628-633`. |
| Superficies de negocio do agente | foco atual em Mission Control + Trading; nenhuma norma para marketing/social/payments web | sem mudanca | env example habilita capacidade tecnica parcial, mas `INTEGRATIONS/` segue restrito | Felix descreve bot com Vercel, Stripe, X/Twitter, email e wallet proprios | Moderado | Felix aponta uma arquitetura de agente-empresa; o repo atual continua um Agent OS de governanca e trading. Evidencias: `README.md:18-39`; `INTEGRATIONS/README.md:12-20`; `config/openclaw.env.example:98-163`; `felix-openclaw-pontos-relevantes.md:10-37`; `felix-openclaw-pontos-relevantes.md:196-205`. |
| Cadencia do ciclo noturno | baseline oficial `23:00 America/Sao_Paulo` e heartbeat de 15 minutos | sem mudanca | workspace e ARC refletem esse horario | Felixcraft mostra `23:00 America/Chicago`; o episodio resume consolidacao "por volta de 02:00" | Leve | Este drift esta documentado e mitigado pela matriz de alinhamento, entao e override controlado, nao conflito aberto. Evidencias: `ARC/ARC-HEARTBEAT.md:32-46`; `workspaces/main/HEARTBEAT.md:3-10`; `felixcraft.md:276-289`; `felix-openclaw-pontos-relevantes.md:110-116`; `PM/TRACEABILITY/FELIX-ALIGNMENT-MATRIX.md:35-38`. |

## Analise de Impacto Sistemico

| Risco avaliado | Nivel | Justificativa tecnica |
|---|---|---|
| Fragmentacao arquitetural | Alto | Existem pelo menos tres centros ativos de descricao do sistema: PRD/ARC/PM, hierarquia Felix-suprema em `META`, e o novo pipeline multi-modelo do working tree. |
| Duplicidade de logica | Alto | Worker/Verifier/Gatekeeper/Tech Lead/Dev Junior coexistem com `M30/M14-Code/Codex 5`, sem mapeamento unico e enforceable. |
| Governanca paralela | Alto | `felixcraft.md` pode prevalecer por precedencia, enquanto o PRD do working tree tenta introduzir nova norma sem atualizar toda a pilha. |
| Dependencia implicita | Moderado | O env template abre superficies tecnicas bem alem do pacote normativo de integracoes. |
| Autoridade ambigua | Critico | A pergunta "quem decide em caso de conflito?" nao tem resposta unica: Felix, PRD, Tech Lead, Gatekeeper e o novo gate `Codex 5` competem entre si. |
| Regressao futura | Alto | O working tree mostra como e facil adicionar norma nova em PRD/CHANGELOG sem alterar `ARC/*`, `DEV/*`, `.github/*` e branch governance. |
| Complexidade acumulada | Alto | Fases, epicos, sprints, tasks, issues, microtasks e agora `micro-issue executavel` convivem com semantica sobreposta. |
| Custo de manutencao | Alto | Cada mudanca relevante precisa sincronizar `PRD`, `META`, `ARC`, `DEV`, `PM`, `TRACEABILITY`, workflows e material Felix. |

**Classificacao global do impacto:** `Alto`

**Justificativa tecnica**
- o estado atual nao e `Critico` no impacto global porque o repo ainda se assume como arquitetura/gates, sem control-plane operacional completo, e os gates documentais principais estao verdes;
- o estado atual tambem nao e `Moderado`, porque a ambiguidade de autoridade ja esta escrita nas normas e o working tree acrescenta nova camada de governanca de codigo sem integracao completa;
- o risco dominante e governanca paralela: a implementacao esta relativamente contida, mas a arquitetura documental que deveria governa-la nao esta convergida.

## Proposta de Normalizacao

### 1. Ajustes no PRD
- atualizar `PRD/PRD-MASTER.md` para separar explicitamente:
  - `fonte de autoridade normativa`;
  - `arquitetura alvo`;
  - `estado de implementacao atual`.
- atualizar `PRD/ROADMAP.md` e `PM/SCRUM-GOV.md` para tornar canonica a cadeia:
  - `PRD -> Fases -> Epicos -> Issues -> Microtasks`
  - `Sprint` permanece apenas como recipiente de capacidade/execucao.
- criar no PRD uma secao permanente de status:
  - `implementado`
  - `simulado_por_contrato`
  - `declarado_sem_execucao`
- rebaixar a secao `Pipeline Multi-Modelo para Mudancas com Codigo` do working tree para `proposta/RFC` ate que `ARC/*`, `DEV/*`, `PM/*` e `.github/*` sejam atualizados no mesmo ciclo.
- criar a secao `Auditoria de Consistencia Arquitetural` no PRD com criterio de convergencia e owners claros.

### 2. Ajustes na Implementacao
- formalizar governanca de branch/PR:
  - adicionar `.github/CODEOWNERS`;
  - documentar branch policy e branch protection;
  - declarar se existe ou nao branch `staging`.
- implementar o minimo auditavel para `Microtask`:
  - caminho canonico `runs/<issue_id>/<microtask_id>/`;
  - artifact estruturado de review/execucao;
  - validacao CI quando issue de codigo for marcada como concluida.
- criar um check de coerencia arquitetural:
  - falhar quando `META`, `PRD`, `DEV` e `.github` divergirem sobre ownership, merge gate ou branch model.
- reduzir superficie ambigua do `config/openclaw.env.example`:
  - ou formalizar `Sentry`, `Stripe`, `email`, `Cloudflare` e afins em `INTEGRATIONS/`;
  - ou mover essas variaveis para um template separado de "capacidade opcional nao governada".
- manter a leitura correta do estado atual:
  - schemas, scripts e artifacts permanecem `simulado_por_contrato` enquanto o runtime alvo nao existir de fato.

### 3. Ajustes nos Arquivos Felix
- manter e formalizar como principios documentados:
  - canais autenticados vs informacionais;
  - trust ladder;
  - approval queue;
  - memoria em camadas com QMD;
  - heartbeat com monitoracao de jobs;
  - segregacao de contas/ativos do agente.
- descartar do nucleo normativo atual, ou mover para apendice conceitual:
  - `staging branch` como regra implicita;
  - `auto-merge if tests pass`;
  - playbooks de Vercel/Stripe/X/Twitter/Sentry/Fastmail enquanto nao houver integracao formal.
- transformar Felix em fonte de principios e exemplos:
  - nunca em autoridade suprema de arquitetura.
- manter os overrides documentados na `FELIX-ALIGNMENT-MATRIX`, mas exigir que qualquer novo override venha acompanhado de changelog e issue/epic correspondente.

## Secao pronta para PRD

## Auditoria de Consistencia Arquitetural

### Estado atual
- o repositorio mantem governanca documental executavel com gates verdes em `ci-quality`, `phase-f2-gate`, `phase-f8-contract-review` e `eval-trading-multiasset`;
- a arquitetura alvo segue mais avancada que a implementacao real: o repo materializa contratos, schemas, allowlists, workflows e artifacts, mas ainda nao o control-plane completo descrito em `ARC/*`;
- ha conflito aberto de autoridade porque `felixcraft.md` permanece acima do PRD na hierarquia oficial;
- o working tree adiciona um pipeline multi-modelo de codigo (`M30 -> M14-Code -> Codex 5`) sem normalizacao completa em `ARC`, `DEV`, `PM` e `.github`.

### Conflitos detectados
- precedencia documental ambigua entre Felix e PRD;
- cadeia estrutural inconsistente entre `Fases/Epicos/Issues/Microtasks` e `epicos/sprints/tasks`;
- claims de microtask executavel ainda nao materializados por artifacts/run path;
- branch policy e ownership de PR nao formalizados, apesar de normas locais e exemplos Felix dependerem disso;
- superficies externas presentes em Felix e no template de ambiente sem pacote normativo correspondente.

### Plano de normalizacao
1. redefinir a fonte de autoridade para `PRD + SEC + ARC`, com Felix como referencia conceitual importada por changelog/traceability;
2. alinhar `PRD/ROADMAP.md`, `PM/SCRUM-GOV.md` e `PRD/PRD-MASTER.md` para a cadeia canonica `PRD -> Fases -> Epicos -> Issues -> Microtasks`;
3. formalizar branch governance (`CODEOWNERS`, branch policy, branch protection) antes de qualquer pipeline de PR baseado em papeis de modelo;
4. introduzir trilha minima por microtask em `runs/<issue_id>/<microtask_id>/` ou reclassificar explicitamente esse contrato como arquitetura alvo;
5. ampliar `INTEGRATIONS/` para qualquer superficie externa ativa, ou declarar essas superficies fora de escopo do OpenClaw atual.

### Responsaveis
- `PM/Architecture`: precedencia documental, cadeia estrutural e secao de auditoria no PRD;
- `Engineering`: branch policy, `CODEOWNERS`, CI coherence checks e trilha minima de microtask;
- `Security`: classificacao das superficies externas, allowlists e limites de uso para integracoes opcionais;
- `Owner do workspace`: decidir se o pipeline multi-modelo continua como proposta ou vira norma integrada.

### Criterio de encerramento da auditoria
- `authority_conflicts_open = 0`;
- `critical_drifts_open = 0`;
- `branch_policy_defined = true`;
- `code_ownership_defined = true`;
- `microtask_evidence_path_defined = true`;
- `external_surfaces_governed_or_out_of_scope = 100%`.

### Metrica de convergencia arquitetural
- `architecture_convergence_score = 1 - (critical_conflicts*0.35 + high_conflicts*0.20 + moderate_conflicts*0.10 + ungated_external_surfaces*0.05 + undocumented_branch_rules*0.10 + missing_microtask_evidence*0.20)`;
- criterio de aceite:
  - `>= 0.90` e `critical_conflicts = 0`;
  - `high_conflicts <= 1`;
  - `ungated_external_surfaces = 0`.

## Classificacao Final do Estado Arquitetural

**Estado atual:** `Alto`

**Fatores decisivos**
- `felixcraft.md` segue como autoridade arquitetural suprema na hierarquia oficial;
- a cadeia de planejamento nao esta normalizada entre `Fases/Epicos/Issues/Microtasks` e `epicos/sprints/tasks`;
- o working tree introduz o pipeline `M30 -> M14-Code -> Codex 5` sem atualizar toda a pilha de contratos tocados;
- branch governance e ownership de PR ainda nao sao fonte de verdade do repo;
- a implementacao continua majoritariamente `simulado_por_contrato`, o que contem o dano operacional, mas nao resolve o drift de governanca.

**Leitura final**
- o principal problema hoje e `governanca + autoridade`, nao `seguranca operacional imediata`;
- o repo ainda nao colapsou em caos porque a maior parte do sistema continua documental e os gates estao verdes;
- se o delta do working tree for promovido sem normalizacao completa, o estado tende a escalar de `Alto` para `Critico`.

## Verificacao dos Failure Modes

| Failure mode | Status | Evidencia | Impacto | Observacao |
|---|---|---|---|---|
| Autoridade dupla entre modelos | Encontrado | `META/DOCUMENT-HIERARCHY.md:33-50`; `PRD/PRD-MASTER.md@HEAD:701-707`; `PRD/PRD-MASTER.md:731-748` | Alto | Felix e novo pipeline local disputam autoridade com PRD/Tech Lead/Gatekeeper. |
| Implementacao bypassando PRD | Parcialmente contido | gates verdes em 2026-03-01; `README.md:5-8`; `.github/workflows/*.yml` | Medio | Nao ha bypass tecnico evidente hoje, mas ha bypass potencial por precedencia Felix. |
| PRD desatualizado | Encontrado | `PM/SCRUM-GOV.md:30-40`; `PRD/PRD-MASTER.md:133-174`; `PRD/CHANGELOG.md:32-63` | Alto | Parte do PRD/PM descreve cadeias e papeis diferentes no mesmo sistema. |
| Felix propondo arquitetura nao formalizada | Encontrado | `felixcraft.md:595-633`; `felix-openclaw-pontos-relevantes.md:196-240`; `INTEGRATIONS/README.md:12-20` | Medio | Staging/Vercel/Stripe/X/Sentry nao viraram pacote normativo. |
| CI nao refletindo criterios do PRD | Parcialmente contido | `DEV/DEV-CI-RULES.md:32-70`; `ci-quality.yml:3-14`; `ci-trading.yml:3-34` | Medio | CI cobre a governanca atual, mas nao cobre ownership/branch model nem o novo pipeline do working tree. |
| Seguranca nao alinhada com principios Felix | Nao encontrado como conflito aberto | `SEC/SEC-POLICY.md:89-116`; `PM/DECISION-PROTOCOL.md:33-41`; `felixcraft.md:360-376`; `felix-openclaw-pontos-relevantes.md:63-77` | Baixo | Canal confiavel, email nao confiavel e approval queue estao bem alinhados. |
| Pipeline multi-modelo nao documentado | Encontrado em `main`, parcialmente documentado no working tree | `PRD/PRD-MASTER.md@HEAD:680-694`; `PRD/PRD-MASTER.md:696-858`; `PRD/CHANGELOG.md:32-63` | Alto | A direcao existe no working tree, mas ainda nao virou contrato sistemico completo. |
| Micro-issues violando atomicidade | Risco aberto | `PRD/PRD-MASTER.md:156-174`; `PM/SCRUM-GOV.md:30-40`; ausencia de `runs/` | Alto | O contrato de atomicidade existe, mas a evidencia materializada ainda nao. |
| Drift entre roadmap e codigo | Encontrado, mas explicitado | `README.md:5-8`; `ARC/ARC-CORE.md:34-56`; `PRD/ROADMAP.md:46-50` | Medio | A diferenca entre arquitetura alvo e implementacao e reconhecida, mas continua grande. |
| Regras de branch nao documentadas | Encontrado | ausencia de `.github/CODEOWNERS`; `ci-quality.yml:3-14`; `felixcraft.md:267`; `felixcraft.md:630-633` | Alto | O repo executa CI, mas nao possui fonte normativa de ownership/branch protection. |
| Dependencias externas nao mapeadas | Encontrado | `config/openclaw.env.example:58-163`; `INTEGRATIONS/README.md:12-20`; `felix-openclaw-pontos-relevantes.md:196-240` | Medio | O template tecnico expande mais rapido que o pacote normativo. |
| Decisoes arquiteturais hardcoded | Encontrado e parcialmente controlado | `config/openclaw.env.example:27-43`; `ARC/ARC-HEARTBEAT.md:32-46`; `workspaces/main/HEARTBEAT.md:3-10` | Medio | Alias de modelos, timezone e cadencia estao fixados; isso e aceitavel enquanto assumido como baseline canonico. |
