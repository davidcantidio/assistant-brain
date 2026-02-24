# Auditoria do “Modo IA” e guia atualizado de LLMs locais no Mac Studio 32GB com Ollama

## Escopo e critérios de validade

O texto do “Modo IA” que você colou tenta recomendar “o melhor LLM local” para um Mac Studio com 32GB e Ollama, incluindo modelos “reasoning” e até opções 70B/72B. A checagem aqui foi feita **na data de hoje (24 de fevereiro de 2026)**, comparando as afirmações com: (i) tamanhos/variantes reais no registro do entity["company","Ollama","local llm runtime"]; (ii) documentação oficial de contexto, “thinking” e KV-cache; e (iii) páginas oficiais de famílias de modelos e notas técnicas (incluindo licenças). citeturn14view1turn14view2turn14view0turn8view0turn6view2

O objetivo é apontar **onde a recomendação está desatualizada ou simplesmente errada** e, em seguida, condensar **casos de uso práticos** de LLMs locais que façam sentido nesse hardware. citeturn14view1turn15view0turn8view0turn6view0

## Memória unificada e o mito do “32GB de VRAM”

Em Mac (Apple Silicon), “VRAM” não é um chip separado: é **memória unificada** que CPU e GPU compartilham, mas o macOS impõe um **limite de quanto a GPU pode “prender” (wired)** para evitar que o sistema morra asfixiado. Inclusive há um kernel tunable (`iogpu.wired_limit_mb`) para ajustar esse limite. citeturn15view0turn15view2

O ponto crucial: **não é porque você tem 32GB no total que você tem 32GB “livres” para modelo**. Por padrão, o macOS deixa uma fração para GPU (ex.: ~2/3 em máquinas até 36GB, segundo um guia técnico popular) e o resto precisa sobrar para o próprio sistema e apps. citeturn15view0

E sim, dá para aumentar o limite com `sudo sysctl iogpu.wired_limit_mb=...`, mas:
- **efetiva na hora (sem reboot)**;  
- e **não é “sticky”**: costuma resetar ao reiniciar, a menos que você force persistência (com ressalvas). citeturn15view3turn15view2turn15view1

Se você exagerar (tipo “vou dar 28GB de 32GB pra GPU e fé”), a chance de dar ruim sobe: o próprio macOS Daily alerta para instabilidade/crash se você alocar VRAM demais em máquinas com pouca RAM, e outros guias reforçam a necessidade de deixar folga para o sistema. citeturn15view3turn15view0turn15view1turn15view2

image_group{"layout":"carousel","aspect_ratio":"16:9","query":["Mac Studio Apple Silicon","Ollama app interface screenshot","Apple Silicon unified memory diagram"],"num_per_query":1}

## Como o Ollama decide se algo “cabe”: contexto, KV cache, thinking e tools

A recomendação do “Modo IA” não dá o devido peso a quatro coisas que mudam tudo:

**Contexto (num_ctx / context length).** O Ollama documenta que o contexto consome memória e que ele define padrões por VRAM (ex.: <24GiB → 4k; 24–48GiB → 32k; ≥48GiB → 256k). Em 32GB unificado, é comum você ficar **abaixo** de 24GiB de “VRAM efetiva” sem mexer no limite — então o padrão tende a ser conservador. citeturn14view1turn15view0

**KV cache (memória que cresce com o contexto).** O próprio FAQ do Ollama explica que RAM/VRAM necessária escala com `OLLAMA_CONTEXT_LENGTH` e também com paralelismo (`OLLAMA_NUM_PARALLEL`), porque KV cache cresce por requisição. citeturn14view2

**Flash Attention + KV cache quantizado.** O Ollama expõe `OLLAMA_FLASH_ATTENTION=1` e permite quantizar KV cache via `OLLAMA_KV_CACHE_TYPE` (padrão `f16`; `q8_0` usa ~metade; `q4_0` ~1/4, com trade-offs). Isso é chave para contexto maior sem estourar memória. citeturn14view2turn2search2

**“Thinking” (reasoning rastreável).** Desde 2025, o Ollama tem suporte formal a thinking: você pode habilitar/desabilitar e até **ocultar o traço** (`--hidethinking`). A doc mostra exemplos explícitos, inclusive com `deepseek-r1` e `gpt-oss`. citeturn14view0turn14view3

**Tool/function calling (“tools”).** Aqui está uma pegadinha: alguns modelos aparecem como “tools”/“thinking”, mas na prática podem falhar com erro de “does not support tools” dependendo do template/runner. Isso aparece repetidamente em issues para DeepSeek-R1. citeturn18search3turn18search5

## Checagem direta do “Modo IA”: pontos desatualizados ou imprecisos

A seguir, os pontos em que o texto do “Modo IA” mais escorrega (e por quê), já com as correções baseadas em fontes atuais.

O “72B em 32GB é viável” não fecha na matemática  
O “Modo IA” sugere Qwen2.5 72B em quantizações como `Q3_K_M` ou similares como “apertado, mas viável” em 32GB. Só que no registro do Ollama, **Qwen2.5 72B Q3_K_M tem ~38GB** e o **Q2_K tem ~30GB**. Num Mac de 32GB, isso entra no território “o sistema operacional também quer viver”. Em outras palavras: 32GB não vira 38GB por carisma. citeturn6view1turn6view0turn6view2turn15view0

Para comparação, o “qwen2.5:72b” padrão aparece com **~47GB** no próprio catálogo de tags. citeturn6view2

O “DeepSeek-R1 70B em Q2_K” não é uma opção oficial no Ollama  
O texto fala em tentar DeepSeek-R1 70B com “q2_k”. No catálogo oficial do Ollama, o **DeepSeek-R1 70B** aparece como **~43GB** (distill Q4) e não há uma variante “q2_k” ali listada. Resultado: na prática, em 32GB, essa sugestão vira “rodar, roda… se você aceitar CPU+swap e rezar”. citeturn11view3turn4view2

“Precisa reinicialização” para `sysctl iogpu.wired_limit_mb` está errado  
O “Modo IA” diz que o comando “requer reinicialização”. Guias técnicos e artigos explicam exatamente o oposto: a alteração **toma efeito imediatamente**; o que acontece é ela **não persistir** após reboot sem configuração adicional. citeturn15view2turn15view3turn15view1

“Você pode subir contexto para 16k sem problemas” é excesso de otimismo  
O Ollama deixa claro que aumentar contexto aumenta memória; e a FAQ reforça que memória escala também com paralelismo. Em 32GB, um modelo de ~20GB (32B em Q4) já come boa parte do budget, sobrando pouco para KV cache grande. Não é impossível ajustar `num_ctx`, mas “sem problemas” depende totalmente de (i) limite de GPU, (ii) KV cache quantizado e (iii) disciplina com apps abertos. citeturn14view1turn14view2turn15view0turn14view2

“Reasoning = sempre mostrar chain-of-thought no terminal” é meia-verdade  
No Ollama, thinking é um **modo**: pode estar habilitado por padrão em modelos compatíveis, mas dá para desligar (`--think=false`) e dá para **usar thinking sem mostrar o traço** (`--hidethinking`). Ou seja: não é uma característica inevitável; é configurável. citeturn14view0turn14view3

“DeepSeek-R1 é perfeito para agentes com tools” precisa de asterisco gigante  
Mesmo quando aparece “tools” em listagens, há relatos/bugs recorrentes de erro “does not support tools” com DeepSeek-R1 em integrações. Para quem quer agent/tool calling “sem drama”, você precisa testar o template/versão ou escolher modelo com suporte mais consistente. citeturn18search3turn18search5

“Llama 3.3 70B tem a inteligência do 405B” é formulação forte demais  
A própria página do Ollama usa linguagem de **“similar performance compared to Llama 3.1 405B”**, e materiais técnicos populares repetem o “comparável”. Isso não é a mesma coisa que “equivalente”. citeturn2search0turn2search4turn2search19

A recomendação ignora uma mudança grande: Qwen3 já é “a geração atual”  
O “Modo IA” centra Qwen2.5 como “melhor tudo-em-um”. Só que desde 2025 o Ollama hospeda **Qwen3** (densos e MoE) e o blog oficial da família afirma que os modelos densos do Qwen3 chegam a **igualar ou superar Qwen2.5 maiores**, especialmente em STEM/código/raciocínio. Em fevereiro de 2026, isso já é parte do “estado da arte” local. citeturn8view0turn2search32turn16search2

Licença: Qwen2.5 72B não é Apache 2.0  
Para uso comercial, isso muda o jogo. O próprio registro do Ollama (e o blog do Qwen) avisam que **os modelos 3B e 72B do Qwen2.5 ficam sob a licença Qwen** (não Apache 2.0), enquanto os demais tamanhos têm Apache 2.0. O “Modo IA” não menciona isso. citeturn13search0turn13search1turn13search9

## Modelos que fazem mais sentido em 32GB no início de 2026

A regra prática em 32GB unificado é: **modelos ~14–20GB (Q4)** tendem a ser “zona confortável”; qualquer coisa acima disso vira “engenharia de sobrevivência” (alterar limite de GPU, reduzir contexto, fechar apps, aceitar offload para CPU). citeturn15view0turn14view1turn14view2

Abaixo, uma seleção “pé-no-chão” por tarefa, usando tamanhos e capacidades do catálogo do Ollama.

| Caso de uso local | Modelos que cabem bem em 32GB (Ollama) | Por que faz sentido |
|---|---|---|
| Chat geral “forte” (português incluso), resumo, escrita, Q&A | Qwen3 32B (≈20GB) citeturn8view0; Qwen2.5 32B Instruct Q4_K_M (≈20GB) citeturn4view1; gpt-oss 20B (≈14GB) citeturn10search0 | Todos ficam em faixa de tamanho que respeita 32GB e têm contexto alto no catálogo; gpt-oss ainda traz “thinking levels” no Ollama. citeturn14view0turn10search0turn4view1 |
| Coding: gerar/refatorar/testar código | Qwen2.5-Coder 32B (família) citeturn16search4; Codestral 22B (≈13GB) citeturn1search1turn1search14 | Qwen2.5-Coder 32B é descrito como forte em geração/razão/fix de código; Codestral é um código-model clássico e relativamente leve. citeturn0search1turn1search14 |
| “Raciocínio”/debug difícil (com thinking rastreável) | DeepSeek-R1 32B (≈20GB) citeturn4view2; Magistral (≈14GB) citeturn19search2turn19search5; Phi-4 Reasoning 14B (≈11GB) citeturn9search5turn9search30 | Thinking é suportado pelo Ollama e pode ser ocultado; modelos de 11–20GB tendem a caber sem gambiarra extrema. citeturn14view0turn14view3turn19search2turn4view2 |
| OCR/Docs com imagem (prints, PDFs escaneados, tabelas) | Qwen3-VL 8B Q4 (≈6.1GB, texto+imagem) citeturn12search2; Gemma 3 27B Q4 (≈17GB, multimodal) citeturn9search0turn9search8 | Modelos multimodais no Ollama aceitam imagem; o 8B-VL é leve e costuma ser o ponto de partida ideal. citeturn12search2turn9search11 |
| Tradução/localização | TranslateGemma (4B/12B/27B) citeturn9search14 | Linha específica para tradução, útil quando você quer consistência terminológica local/offline. citeturn9search14 |
| RAG local (buscar em documentos) | Qwen3-Embedding (embeddings) citeturn1search25 + um modelo de chat (ex.: Qwen3 14B/32B) citeturn8view0 | RAG bom separa “indexar” (embeddings) de “responder” (LLM). O Ollama tem modelos de embedding dedicados. citeturn1search25 |

Dois “alertas úteis” para evitar frustração:
- Se você mirar 70B/72B em 32GB, você vai cair em **q2** ultra-agressivo, offload para CPU, swap e queda brutal de velocidade — quando não falhar direto. Os próprios tamanhos listados no Ollama já deixam isso claro (26–43GB+ mesmo em quantizações mais agressivas/variantes). citeturn4view3turn4view2turn6view0turn6view1  
- Para conferir se você está realmente em GPU ou virou “CPU disfarçado”, a recomendação oficial é `ollama ps` e olhar o campo PROCESSOR (100% GPU vs CPU/GPU split). citeturn18search0turn14view1

## Casos de uso de LLMs locais e quando local vale a pena

**Privacidade e dados sensíveis.** O discurso central do Ollama é rodar modelos abertos mantendo dados locais (“keeping your data safe”). Isso é relevante quando você joga na conversa: contratos, dados de clientes, logs internos, código proprietário ou qualquer coisa que você não quer mandar para terceiros. citeturn12search6

**Baixa latência previsível e “sem fila”.** Local é especialmente bom para fluxo de trabalho: IDE, terminal, pequenas perguntas e refatorações rápidas. Você troca “depender da internet e de rate limit” por “depender da sua RAM”. (Pelo menos a RAM não cai. Normalmente.) citeturn14view2turn16search4

**Automação/agents sem depender de SaaS.** Hoje você já tem modelos com foco em tarefas agentic e reasoning no próprio catálogo, como gpt-oss (com thinking configurável) e recursos de “thinking” no Ollama. Mas tool calling ainda não é “uniformemente chato-free” em todos os modelos (vide DeepSeek-R1), então o caso de uso “agente com ferramentas” precisa de teste em cima da versão e do template. citeturn14view0turn10search1turn18search3turn18search5

**Long context e “chat com arquivos” (RAG).** Se você quer jogar PDFs, repositórios e bases inteiras, o gargalo vira **contexto + KV cache**. A doc oficial é direta: contexto maior = mais memória; e dá para ajustar no server (`OLLAMA_CONTEXT_LENGTH`) ou por request (`num_ctx`). Em 32GB, o jeito certo de fazer isso sem se sabotar é: (i) usar embeddings + recuperação (RAG) para não empurrar “o mundo” no prompt; e (ii) se precisar mesmo de contexto grande, usar Flash Attention e KV cache quantizado. citeturn14view1turn14view2turn2search2turn1search25

**Multimodal local (OCR, screenshot-to-steps, entender tabela/diagrama).** Isso virou viável com modelos como Qwen3-VL (texto+imagem) e Gemma 3 (multimodal). Em 32GB, começar pelo Qwen3-VL 8B é pragmático: custo baixo de memória e bom para OCR/extração. citeturn12search2turn9search11turn9search0

**Custo previsível.** Local é “pague com seu hardware”, e isso pode ser ótimo quando o volume de uso é alto e repetitivo. Guias de self-hosting em 2026 destacam justamente o apelo de custo e controle em comparação com uso constante de APIs. citeturn1search9turn9search16