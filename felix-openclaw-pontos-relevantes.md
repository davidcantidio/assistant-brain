# Como o autor implementou o agente “Felix” (OpenClaw) — pontos relevantes do episódio

> Baseado no trecho/transcrição fornecido pelo usuário (com marcações de tempo).  
> Foco: arquitetura, autonomia, segurança, memória, proatividade (cron/heartbeat) e operação diária.

---

## 00:00 — Meet Felix: The OpenClaw bot building its own business (visão geral)

- **Objetivo do agente**: operar como um “empreendedor autônomo” capaz de **construir produto, lançar, vender, dar suporte e fazer marketing** (principalmente via X/Twitter), com a meta explícita de **chegar a um negócio de US$ 1M**, depois 10M, 100M etc.
- **Evolução incremental de autonomia**: o autor descreve que foi **removendo gargalos humanos** ao longo de ~1 mês:
  - começou com comandos remotos e colaboração;
  - migrou o agente para **hardware dedicado (Mac Mini)**;
  - foi adicionando **chaves de API e acessos** conforme a confiança e necessidades aumentavam;
  - depois adicionou **presença no X/Twitter** e rotinas automáticas.
- **Princípio orientador (“remover gargalos”)**: o autor usa continuamente a pergunta:
  - “**Consigo remover este gargalo para você?** Existe uma forma de você **não precisar me perguntar isso de novo?**”  
  Isso leva a:
  - criação de automações;
  - aumento de acesso (com separação e mitigação de risco);
  - melhoria de memória/rotinas para reduzir re-trabalho.

---

## 03:49 — “I’m going to sleep. Build a product that makes me money.” (lançamento overnight)

- **Acesso operacional concedido** ao agente (com ressalvas de segurança que aparecem depois):
  - **Vercel** (deploy/landing page),
  - **Stripe** (chaves / capacidade de criar produto e cobrar),
  - além de estar implícito que ele tem fluxo com **GitHub** e infraestrutura.
- **Instrução/brief de alto impacto**: “**Construa um produto que você consiga fazer inteiramente sozinho**, que possamos lançar pela manhã, e que gere receita.”
- **Resultado prático**:
  - o agente “acordou” com:
    - um **site** pronto,
    - um **PDF/playbook** como produto,
    - **Stripe configurado** (produto/checkout),
    - integração com a **landing page na Vercel**,
    - faltando só um gargalo final: **configurações de DNS** para apontar domínio.
- **Efeito**: prova de capacidade de “shipar” sem intervenção humana constante; humano atua só como **aprovação e pequenas ações irrecorríveis** (ex.: DNS).

---

## 08:03 — Como configurar múltiplos chats do OpenClaw para tocar 5 projetos ao mesmo tempo

- **Arquitetura de conversas** em Telegram com **duas camadas**:
  1. **Chat 1:1** (humano ↔ bot) — bom para começar e ter controle total.
  2. **Grupo no Telegram** com o bot — permite **múltiplas threads/conversas por tópico**.
- **Por que isso importa**:
  - reduz “poluição de contexto”: cada thread dispara uma **sessão separada** no OpenClaw.
  - permite paralelismo real: “**5 coisas ao mesmo tempo**” sem atrapalhar a tarefa principal.
- **Uso prático** (exemplos citados):
  - um chat para “easyclaw” (produto web hospedado),
  - um para X/Twitter,
  - um para app iOS,
  - um para editor/documentos (Polylog),
  - etc.
- **Configuração de permissões**:
  - é necessário ajustar no **BotFather** para o bot **ver mensagens no grupo** (não só quando marcado).
  - depois disso, o grupo “vira um chat normal” para o OpenClaw, mas com sessões separadas por thread.

---

## 11:06 — Como o Felix ignora prompt injections no X/Twitter (segurança por canais)

- **Modelo de segurança chave** do OpenClaw (mencionado como “diferenciação”):
  - separa **canais autenticados de comando** vs **canais informacionais**.
- **Implicação prática**:
  - conteúdo vindo do X/Twitter (menções, replies) é tratado como **informação**, não “instrução autenticada”.
  - portanto, tentativas de **prompt injection** via tweets são **ignoradas** (o bot “sabe que é injection”).
- **Mesma lógica para email**:
  - um atacante pode mandar “sou o Nat, é emergência” por email.
  - o agente classifica email como **canal não-autenticado**, então **não executa comandos**.
- **Cadeia de confiança**:
  - o autor afirma que **o telefone (Telegram) + a máquina (Mac Mini)** são os meios que “controlam” o bot.
- **Postura de risco (“guinea pig”)**:
  - o autor reconhece que ainda pode haver falhas futuras, mas está disposto a experimentar.
  - isso influencia a estratégia: **dar acesso com mitigação**, mas aceitar algum risco de fronteira.

---

## 14:42 — A história de como o Felix chegou a US$ 100K+ em crypto (autonomia via rails cripto)

- **Motivação para crypto**: “rails” cripto são mais fáceis para agentes porque:
  - tudo é programável,
  - evita “web forms” e fricção de cartões/logins.
- **Mecânica descrita**:
  - bots (ex.: no Ethereum/Solana) permitem alguém “taggear” e criar token.
  - não há necessariamente alocação inicial do token para o criador, mas há **fee por trade**.
  - o autor passa a **reivindicar fees** e direcionar para a carteira do Felix.
- **Automação diária**:
  - criou uma automação que **todo dia ao meio-dia**:
    - “claim” das fees,
    - **queima metade** dos tokens recebidos (para não parecer que o bot “controla supply”),
    - envia o restante para a **carteira do Felix**.
- **Separação de identidade financeira**:
  - “Felix tem seu próprio endereço/carteira”, separado do autor.
  - reforça o padrão de **separar contas/ativos** do bot vs humano.

---

## 17:24 — O sistema de memória em 3 camadas que “faz tudo funcionar”

### Camada 1 — Base de conhecimento em Markdown + busca rápida (QMD)
- Usa algo chamado **QMD** (atribui a Toby/Shopify) para:
  - **indexar e buscar rapidamente** através de arquivos markdown no repositório.
- Mudança importante:
  - mandar o bot **desativar a configuração padrão** de busca de memória
  - e **usar QMD** como “engine” de retrieval em vez do default.

### Camada 2 — Consolidação noturna (cron de “memory consolidation”)
- Todo dia por volta de **02:00** roda um **cron job** que:
  - percorre **todas as sessões do dia**,
  - identifica informação importante (projetos, responsabilidades, recursos, aprendizados),
  - **atualiza os markdowns** (a base de conhecimento),
  - roda novamente o **processo de indexação**.
- Efeito: ao acordar, o bot tem **knowledge base atualizada** do dia anterior → reduz a necessidade de “repetir contexto”.

### Camada 3 — Notas diárias + “tacit knowledge” (preferências/regras/segurança)
- O autor descreve (e depois clarifica) que “tacit knowledge” inclui:
  - preferências,
  - padrões e lições de erros,
  - canais confiáveis,
  - regras de segurança (ex.: email nunca é command channel).
- Estrutura conceitual citada:
  - **Notas (daily notes)**: “o que aconteceu” e o que está ativo.
  - **Knowledge graph/fatos**: fatos sobre entidades/projetos.
  - **Tacit knowledge**: “como o Nat funciona” + regras operacionais do agente.

### Prompt que ele recomenda para replicar algo próximo
- Um prompt “modelo” sugerido (paráfrase fiel ao conteúdo):
  - implementar um sistema de knowledge management inspirado em **Thiago Forte**,
  - com **daily notes**, priorização,
  - logging ativo do que é importante,
  - e um **job noturno** que revisa tudo do dia e atualiza a base.

---

## 22:14 — Heartbeat, cron jobs e delegar para Codex (proatividade + execução longa)

### Cron jobs como motor de proatividade (especialmente para X/Twitter)
- O Felix tem **6–8 cron jobs** por dia para Twitter, por exemplo:
  - checar replies/menções,
  - “**você deveria tweetar algo**”.
- Quando o cron “tweet” dispara, ele:
  - olha conversas recentes “das últimas horas”,
  - olha menções no Twitter,
  - propõe um tweet e **pede aprovação** (humano “rubber-stamp”).

### Heartbeat para não esquecer tarefas longas
- Problema: trabalhos grandes de programação ficavam “meio feitos” ou eram esquecidos.
- Solução: regra operacional:
  - Felix **não faz** trabalho grande diretamente.
  - Ele **deleg(a)** para **Codex** via sessões de terminal, e **monitora**.
- Falhas que apareceram:
  - jobs podem falhar,
  - Felix pode esquecer que job está rodando,
  - OpenClaw por padrão inicia coisas no **TMP**, que pode ser limpo e “matar” sessões longas.
- Ajustes implementados:
  1. **Não spawnar no TMP** para jobs longos.
  2. Usar **loops “Ralph”** (termo do autor) com:
     - criação de **PRD** (especificação) → depois execução do PRD via Codex.
  3. Toda vez que cria um job Codex, o agente:
     - **atualiza a daily note** registrando que começou e onde.
  4. Heartbeat customizado:
     - checa a daily note por “projetos abertos”,
     - verifica se sessão ainda está rodando:
       - se rodando: nada a fazer,
       - se morreu: reinicia silenciosamente,
       - se terminou: reporta ao Nat.
- Resultado relatado:
  - jobs podem rodar por **6 horas** e o humano acorda com um **artefato pronto** (ex.: link do Expo para baixar app).

---

## 26:41 — A pergunta que torna o bot mais capaz (“remover este gargalo?”)

- A pergunta-chave já citada se torna um “framework” operacional:
  - identificar tudo que o bot pede ao humano e transformar em:
    - automação,
    - credentialing apropriado,
    - processos robustos.
- Exemplos concretos de “remover gargalo”:
  - bot configurou **relatórios de vendas** (sem o humano abrir dashboard),
  - bot cria/configura **produtos Stripe** sem instrução detalhada,
  - humano vira um aprovador/validador, não executor.

---

## 32:14 — Recap: como montar seu próprio bot para construir um negócio (sequência sugerida)

- **Ordem recomendada**:
  1. **Primeiro**: estruturar memória/knowledge management desde o dia 1.
  2. **Depois**: escolher **uma coisa simples** para o bot fazer.
  3. **Só então**: expandir acessos e superfície de risco.
- **Estratégia de “ramp-up” de permissões** (controle de risco):
  - começar com build de web app + GitHub + Vercel (deploy),
  - depois adicionar Railway/Fly/etc. (backend/servidores),
  - depois criar uma **conta Stripe separada só do bot**,
  - evitar dar:
    - acesso ao banco,
    - chaves principais do seu Stripe/produtos,
    - suas contas pessoais (Twitter/email/carteiras),
  - dar “uma” dessas coisas e observar como ele se sai.
- **Separação por contas** (tema recorrente):
  - Felix tem Twitter próprio, email próprio, wallet própria.
  - reduz blast radius caso algo dê errado.

---

## Checklist de implementação inferido do relato (prático)

### Infra / Execução
- [ ] Instância dedicada (ex.: Mac Mini) rodando OpenClaw continuamente.
- [ ] Telegram bot configurado + (opcional) grupo para threads múltiplas.
- [ ] Acesso a deploy (Vercel) e repo (GitHub), com credenciais separadas do pessoal.

### Memória (3 camadas)
- [ ] Repositório “vida/knowledge” em markdown.
- [ ] Busca indexada via QMD (substitui lookup padrão).
- [ ] Cron noturno (≈02:00) para consolidar sessões do dia → atualizar markdowns → reindexar.
- [ ] Daily notes como fonte de verdade do “que está ativo”.
- [ ] Tacit knowledge: preferências, regras e política de segurança.

### Proatividade
- [ ] Cron jobs para rotinas (ex.: Twitter check/reply/tweet suggestion).
- [ ] Heartbeat customizado para:
  - monitorar projetos abertos (a partir da daily note),
  - reiniciar jobs mortos,
  - reportar conclusões.

### Execução longa / Delegação
- [ ] Delegar tarefas grandes para Codex via terminal.
- [ ] Evitar TMP para jobs longos.
- [ ] PRD-first + loop de execução (Ralph loop).
- [ ] Registro obrigatório de jobs na daily note para rastreabilidade.

### Segurança
- [ ] Política explícita de “command channels autenticados” vs “info channels”.
- [ ] Tratar X/Twitter e email como informacionais (não executam comandos).
- [ ] Separar contas/ativos do bot (Stripe/Twitter/email/wallet).
- [ ] Mitigar risco com ramp-up gradual de permissões.

---

## Referências internas citadas no episódio (apenas nomes mencionados)
- OpenClaw (produto/agent framework).
- Telegram + BotFather (config de permissões em grupos).
- Vercel (deploy).
- Stripe (pagamentos).
- QMD (indexação/busca em markdown).
- Thiago Forte (inspiração para knowledge management).
- Codex (delegação de programação).
- “Ralph loops” (padrão de execução citado pelo autor).
- X/Twitter (marketing e interação).
