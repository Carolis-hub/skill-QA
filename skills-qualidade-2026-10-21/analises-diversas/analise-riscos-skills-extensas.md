# Análise de Riscos e Estratégias — Skills Extensas em Processos de QA para BPM/ECM

Esta análise combina duas fontes: (a) evidência concreta observada na auditoria anterior das 9 skills do diretório `Skills-QA-Processo_2026-09-28` (citada quando aplicável) e (b) práticas reconhecidas de engenharia de software, QA e IA aplicada, explicitamente citadas como conhecimento geral — não como fato documentado nos arquivos. Onde misturo os dois, deixo claro qual é qual.

**Premissa declarada:** nenhuma das afirmações de mercado/prática geral abaixo é verificável nos arquivos analisados previamente — são conhecimento geral sobre engenharia de prompts, LLMs e QA, trazido porque esta pergunta (diferente da auditoria anterior) pede explicitamente para basear a análise em "práticas reconhecidas".

---

## 1. Riscos de Skills Extensas

`executar-teste.md` (354 linhas, dezenas de regras na seção "Regra fundamental" sozinha) e `gerar-mapa-testes-v3.md` (346 linhas) são exemplos concretos, já auditados, do padrão que esta pergunta descreve — usados como caso real ao longo desta seção.

| Risco | Mecanismo causador | Evidência/observação |
|---|---|---|
| **Perda de contexto durante a execução** | LLMs processam instruções long-form com atenção não uniforme; regras no meio de um documento longo têm probabilidade maior de serem "esquecidas" ou subponderadas conforme a janela de contexto se enche com raciocínio intermediário (histórico de conversa, resultados de ferramentas) | `executar-teste.md` já documenta esse próprio risco acontecendo na prática: registra que o padrão "não tentei ainda / não explorei" **se repetiu mais de uma vez, mesmo depois de corrigido** (US #157198, #161881) — sinal direto de que uma regra escrita não garante execução, mesmo dentro da própria skill que a define |
| **Omissão de validações obrigatórias** | Quanto mais steps sequenciais e condicionais, maior a chance de um deles ser pulado silenciosamente, especialmente quando a condição de disparo é sutil (ex.: "se X e não Y, faça Z") | `gerar-mapa-testes-v3.md` tenta mitigar isso ativamente com o checklist obrigatório do Step 4.1 ("não é opcional, e cada dimensão deve gerar pelo menos uma linha... mesmo que seja para registrar 'N/A'") — a própria skill reconhece que sem esse mecanismo explícito, dimensões seriam omitidas por omissão silenciosa |
| **Degradação da qualidade das respostas pelo tamanho** | Instruções muito longas competem por "orçamento de atenção"; seções finais de um documento longo podem receber processamento mais raso que as iniciais | Não há evidência direta disso nos 9 arquivos (não é auto-observável pela skill), mas é um padrão amplamente discutido na literatura de prompt engineering ("lost in the middle") |
| **Conflito entre instruções em diferentes seções** | Regras adicionadas incrementalmente (por skill que evolui por patches ao longo do tempo, como `executar-teste.md` claramente fez) tendem a acumular exceções que podem colidir com regras anteriores não revisadas em conjunto | Encontrei uma divergência real entre arquivos na auditoria anterior: `priorizar-automacao.md` usa nomes de categoria diferentes de `gerar-mapa-testes-v3.md` — evidência concreta de que manutenção incremental gera inconsistência entre artefatos que deveriam estar alinhados |
| **Dificuldade de manutenção e evolução** | Cada nova regra precisa ser lida e integrada mentalmente com todas as anteriores para não contradizê-las; o custo de revisão cresce mais que linearmente com o tamanho | `executar-teste.md` já tem uma seção de Troubleshooting com 15+ itens, cada um documentando uma correção pontual — um padrão de "patch sobre patch" que é sintoma, não causa, da dificuldade de manter uma skill monolítica |
| **Dificuldade de reutilização em outros produtos/módulos** | Regras de domínio específico ficam entrelaçadas com o mecanismo genérico, tornando impossível extrair só a parte reutilizável sem reescrever o arquivo inteiro | Confirmado na auditoria anterior: `executar-teste.md` mistura o mecanismo genérico de execução via Playwright com conteúdo 100% específico de Cobrança (credenciais, CNAB, MySQL) — resultado: classificação de "Recomendada reconstrução" para uso em outro produto, mesmo com o núcleo técnico sendo bom |
| **Impacto na consistência dos resultados** | Skills grandes com múltiplos caminhos condicionais (Modo A/Modo B em `executar-teste.md`, por exemplo) aumentam a superfície de decisão que o modelo precisa navegar a cada execução — mais pontos de decisão = mais variância entre execuções | O próprio double-check independente via subagente existe precisamente para compensar essa variância — é uma admissão estrutural de que a execução única não é confiável o suficiente sozinha |
| **Dependência excessiva de uma única skill** | Quando uma skill concentra geração de mapa + execução + decisão de bloqueio, uma falha ou ambiguidade nela paralisa todo o pipeline a jusante | `homologar-release.md` depende inteiramente de `/analise-tecnica`, `/executar-teste` e `/analise-falha` como sub-rotinas — qualquer limitação nelas se propaga sem contenção; não há fallback ou validação independente entre elas |

### Limitações de tamanho de contexto (janela do modelo) e impacto prático

Isto é conhecimento geral sobre LLMs, não documentado nos arquivos:

- **Janela de contexto finita:** uma sessão que executa uma skill de 350+ linhas, mais o histórico da conversa (resultados de ferramentas MCP, snapshots de tela, respostas de rede), pode acumular dezenas de milhares de tokens antes de chegar ao relatório final. Quando a soma se aproxima do limite da janela, o sistema geralmente recorre a **sumarização automática do histórico** — o que pode comprimir ou descartar detalhes finos (ex.: qual exatamente era o "esperado" de um cenário específico, citado dezenas de mensagens atrás).
- **Impacto prático concreto no caso de `executar-teste.md`:** a skill executa dezenas de cenários, cada um gerando snapshot + ação + snapshot + evidência de rede — é exatamente o tipo de fluxo que mais rapidamente enche a janela de contexto. Um cenário próximo do fim de um mapa longo corre risco real de ser avaliado com menos "memória" fiel de uma regra explicada só uma vez no início do que se essa mesma execução fosse quebrada em lotes menores.
- **Mitigação já usada de fato pelas skills auditadas:** reaproveitamento explícito de relatórios já gerados por outras skills na mesma conversa (em vez de reprocessar do zero) — isso reduz a necessidade de manter tudo "vivo" na cabeça do modelo simultaneamente, mas só funciona porque a arquitetura já é multi-skill; uma skill monolítica não teria essa saída.

---

## 2. Riscos para o Processo de Testes (contexto BPM/ECM on-premise)

| Falha possível | Causa (o que a skill deixa de considerar) | Consequência concreta no BPM/ECM |
|---|---|---|
| **Cenários não mapeados** | Escopo de origem restrito demais (ex.: `gerar-mapa-testes-v3.md` só aceita 4 fontes textuais) combinado com uma história que não descreve explicitamente uma dependência de configuração | Um fluxo de publicação de documento que depende de tipo de índice previamente cadastrado nunca vira cenário de teste, porque nenhuma das 4 fontes aceitas menciona isso — a lacuna só aparece em produção |
| **Dependências não identificadas** | Análise técnica escopada a um único PR/repositório (`analise-tecnica.md`) | Uma mudança de contrato de API consumida por um repositório de frontend separado nunca é detectada como dependência, porque a skill nunca olha o outro repositório |
| **Pré-requisitos não configurados** | Ausência de mecanismo de rastreamento de cadeia de configuração (identificado como gap na auditoria anterior) | Teste de publicação de documento ECM falha por falta de "usuário com permissão de publicação" — e é classificado erroneamente como bug de aplicação, não como falha de preparação de ambiente |
| **Cobertura insuficiente** | Skill única tentando cobrir Oracle e SQL Server sem instrução dedicada para cada um (nenhuma das 9 skills trata isso hoje) | Um teste "passou" reportado sem indicar em qual banco rodou pode mascarar uma falha real só em um dos dois SGBDs (ex.: comportamento de `NULL`/tipo de dado diferente entre Oracle e SQL Server) |
| **Falsos positivos** | Comparação de "esperado vs. obtido" sem evidência de rede em cenário assíncrono, ou double-check que não roda (falha silenciosa aceita) | Um cenário marcado `Passou` sem verificação cruzada pode mascarar uma falha de integração entre módulos BPM que só se manifesta sob concorrência |
| **Falsos negativos** | Comparação literal e rígida de mensagem de erro sem considerar que dois SGBDs podem gerar mensagens de erro tecnicamente equivalentes mas textualmente diferentes | Um cenário é marcado `Falhou` incorretamente porque a mensagem de erro do Oracle difere textualmente da esperada (validada originalmente só contra SQL Server), quando o comportamento de negócio está correto |
| **Regressões não detectadas** | Heurística de regressão por categoria, não por arquivo real de código — o próprio arquivo `executar-teste.md` documenta um caso real de falha (US #157195/Bug #161821) em que a heurística errou por categoria | Num produto com múltiplos módulos compartilhando validação (comum em BPM/ECM, onde regras de workflow são reaproveitadas entre subprodutos), um fix num componente compartilhado pode não disparar reteste na área realmente afetada |
| **Regressões cross-repo não detectadas** | Nenhuma skill audita "quem mais usa esta configuração/API" além do escopo do PR analisado | Uma mudança de configuração compartilhada entre dois subprodutos (ex.: perfil de permissão usado tanto por BPM quanto por ECM) pode quebrar o segundo subproduto sem que nenhuma skill tenha olhado para ele |

---

## 3. Estratégias de Mitigação

| Estratégia | Vantagens | Desvantagens |
|---|---|---|
| **Divisão em múltiplas skills especializadas** (já é o padrão observado nas 9 skills auditadas — `analise-negocio` ≠ `analise-tecnica` ≠ `gerar-mapa-testes-v3` ≠ `executar-teste`) | Reduz o tamanho de contexto por execução; permite reutilização parcial (ex.: `analise-falha.md` foi classificada como reutilizável quase sem mudanças justamente por ser pequena e focada); facilita manutenção isolada; erros ficam contidos a uma etapa | Aumenta a complexidade de orquestração entre skills (quem chama quem, em que ordem); risco de inconsistência entre elas se não houver contrato de formato rígido (o problema real de nomenclatura encontrado entre `priorizar-automacao.md` e `gerar-mapa-testes-v3.md` é sintoma exatamente disso) |
| **Skills hierárquicas / orquestradoras** (`homologar-release.md` já cumpre esse papel, chamando `/analise-tecnica`, `/executar-teste`, `/analise-falha` como sub-rotinas) | Centraliza a decisão de alto nível sem duplicar lógica de execução; permite paralelização futura (já prevista textualmente no próprio arquivo, "só deve ser feito via múltiplos agentes... se você pedir isso explicitamente") | A orquestradora herda cegamente qualquer limitação das sub-rotinas — se elas tiverem gap de cobertura (ex.: multi-repo), a orquestradora não percebe isso sozinha; precisa de validação própria de que os insumos que recebeu são completos |
| **Checklists obrigatórios** (já usado em `gerar-mapa-testes-v3.md`, dimensões positivo/negativo/permissão/dados/concorrência/regressão, com regra de "gerar linha mesmo que N/A") | Transforma uma verificação implícita (fácil de esquecer) em uma verificação explícita e auditável — reduz diretamente o risco de "omissão silenciosa" | Um checklist rígido demais pode gerar ruído (linhas "N/A" sem valor real) ou, pior, ser preenchido de forma mecânica/superficial só para "satisfazer a forma", sem investigação real por trás — precisa de amostragem humana periódica para verificar se o preenchimento é genuíno |
| **Templates estruturados** (relatórios em formato fixo, presentes em todas as 9 skills auditadas) | Facilita comparação entre execuções, parsing automatizado, e detecção de campo ausente | Não garante qualidade do conteúdo dentro de cada campo — um template bem preenchido com informação rasa passa despercebido se a validação for só estrutural |
| **Validações cruzadas** (double-check via subagente independente, `executar-teste.md`, explicitamente "nunca `fork`, para garantir que ele não herda nenhum raciocínio") | Reduz falso positivo por viés de confirmação do mesmo agente que executou; já demonstrou valor real ("cada `DIVERGENTE` vira uma linha... e fica para a usuária decidir") | Custo adicional de execução (tempo/tokens); só verifica a evidência já coletada — não recoleta evidência nova, então não pega um erro de coleta em si (ex.: screenshot do elemento errado) |
| **Revisões automáticas / regressão de skill** (não observado nos 9 arquivos — recomendação de mercado) | Permite detectar quando uma mudança na skill quebra um caso de uso que antes funcionava (equivalente a teste de regressão de software aplicado à própria skill) | Exige um conjunto de casos de referência mantido e atualizado — esforço de engenharia adicional, e a "correção" de uma execução de LLM é mais difícil de automatizar do que a de um teste de software determinístico |
| **Rastreabilidade entre requisitos, cenários e testes** (parcialmente implementada: `gerar-mapa-testes-v3.md` já exige coluna "Origem" por cenário; `gerar-defeito.md` já grava "Cenário de origem" com formato fixo lido de volta por `executar-teste.md`) | Permite auditoria de cobertura (que requisito não tem cenário; que cenário nunca foi executado; que bug não tem cenário de origem) | Rastreabilidade é só tão boa quanto a disciplina de preenchimento — um campo de rastreio com formato livre (não fixo) já se mostrou frágil o suficiente para a skill precisar de "rótulo fixo... nunca reescrever com sinônimos" |
| **Gates de qualidade** (já em uso: `analise-tecnica.md` bloqueia sem card `Análise` preenchido; `gerar-defeito.md` bloqueia sem veredito `SIM` de `/analise-falha`) | Impede propagação de trabalho baseado em insumo incompleto — falha rápido e visivelmente, em vez de gerar resultado de baixa confiança silenciosamente | Gate rígido demais pode travar o pipeline inteiro por um insumo secundário ausente, mesmo quando o restante do trabalho poderia prosseguir (mitigado parcialmente em `homologar-release.md`, que não trava a release inteira por uma história sem impacto mapeado — um bom padrão de gate "localizado" em vez de "global") |
| **Métricas de cobertura** (não implementada em nenhuma das 9 skills como métrica numérica formal — apenas listas textuais) | Permite decisão objetiva (ex.: "80% das dimensões do checklist têm pelo menos 1 cenário não-N/A") em vez de impressão subjetiva | Métrica de cobertura de teste gerado por LLM é enganosa se não for pareada com métrica de *qualidade* do cenário (uma dimensão "coberta" com um cenário raso conta igual a uma bem investigada) |

---

## 4. Garantia de Qualidade das Skills (meta-QA)

Esta seção é fundamentada primariamente em práticas gerais de engenharia de software e QA aplicadas ao contexto de "skills como artefato de engenharia", não em conteúdo dos 9 arquivos (que não descrevem processo de QA sobre si mesmas, exceto o histórico informal de correções citado em `executar-teste.md`).

- **Validar que uma skill produz o resultado esperado:** manter um conjunto de casos de referência (histórias/PRs/cenários reais já resolvidos manualmente) com o resultado "gabarito" conhecido, e rodar a skill periodicamente contra eles, comparando saída atual vs. gabarito — equivalente a teste de regressão, mas com avaliação humana ou por segundo modelo (LLM-as-judge) no lugar de asserção exata, já que a saída é texto livre.
- **Detectar regressões em uma skill:** versionar a skill (a própria numeração "v2"/"v3" observada em `gerar-mapa-testes-v3.md` já é um indício desse hábito) e, a cada mudança de versão, rodar o mesmo conjunto de casos de referência, sinalizando qualquer divergência inesperada de comportamento em casos que antes passavam.
- **Medir qualidade das saídas:** amostragem humana periódica (revisão de uma fração dos relatórios gerados) comparando com o padrão esperado — especialmente em pontos identificados como frágeis nesta análise (ex.: cenários marcados `HIPOTESE:`, evidência de rede, comparação literal de mensagem de erro).
- **Medir cobertura:** cruzar, para cada história, a lista de critérios de aceite/regras de negócio (saída de `/analise-negocio`) com a lista de cenários gerados (saída de `/gerar-mapa-testes-v3`) e sinalizar todo critério sem nenhum cenário rastreado a ele — isso é factível com o dado que já existe (coluna "Origem" já presente), só falta o passo de auditoria cruzada automatizada.
- **Identificar instruções conflitantes:** revisão periódica (humana ou por outra IA) comparando terminologia/regras entre skills que deveriam ser consistentes — a divergência de nomenclatura de categorias entre `priorizar-automacao.md` e `gerar-mapa-testes-v3.md`, encontrada nesta auditoria, é exatamente o tipo de conflito que uma checagem de consistência periódica capturaria antes de virar problema em produção.
- **Validar aderência ao processo de QA:** auditar amostralmente se os gates estão de fato sendo respeitados (ex.: nenhum defeito foi criado sem veredito `SIM` de `/analise-falha`; nenhuma publicação de wiki ocorreu sem aprovação página por página) — o log de governança já existente (`LOG-ACOES.md`, citado em várias das 9 skills) é o material bruto ideal para essa auditoria, mas exige alguém (ou uma skill dedicada) revisando esse log periodicamente, o que não está descrito em nenhum dos 9 arquivos.

---

## 5. Observabilidade e Monitoramento

Indicadores recomendados, organizados por o que já tem insumo bruto disponível nas skills auditadas (log de ações, campos estruturados) versus o que precisaria ser instrumentado:

| Indicador | Já há insumo bruto nas skills atuais? | Como calcular |
|---|---|---|
| Cobertura funcional (% de critérios de aceite com cenário) | Parcial — coluna "Origem" já existe | Cruzar relatório de `/analise-negocio` (comportamentos esperados) com cenários do mapa por Origem = "história" |
| Cobertura de dependências (% de dependências de configuração com cenário) | Não — depende de skill nova recomendada | Requer o rastreador de dependências de configuração ainda inexistente |
| Cobertura de integrações | Parcial — "Integrações potencialmente impactadas" já é campo de `analise-tecnica.md` | Cruzar esse campo com cenários da categoria `ERROS DE INTEGRACAO / API` |
| Cobertura Oracle x SQL Server | Não — nenhuma skill distingue isso hoje | Requer instrumentação nova (tag de SGBD por cenário/execução) |
| Cobertura BPM x ECM | Não — nenhuma skill tem esse conceito | Requer categorização por subproduto nas skills reconstruídas |
| Taxa de defeitos encontrados (por release/período) | Sim — `LOG-ACOES.md` já registra cada Bug criado | Contagem direta do log |
| Taxa de defeitos escapados para produção | Não diretamente — exigiria correlacionar Bugs abertos após deploy com a release que "aprovou" | Cruzar data de abertura do Bug com a recomendação de release mais próxima anterior |
| Reabertura de bugs | Parcial — `executar-teste.md` já reconhece o conceito ("Auto-detecção não reabre Bugs reabertos"), mas não emite métrica agregada | Contar Bugs cujo estado voltou de "Done"/"Resolved" para "Active"/"New" |
| Efetividade dos testes (bugs encontrados / cenários executados) | Sim — dado bruto existe em `LOG-ACOES.md` (resumo de N passou/N falhou) | Razão simples por execução, agregável por período |
| Rastreabilidade requisito → teste | Parcial — já existe granularidade de "Origem" e "Cenário de origem", falta consolidação em painel | Consolidar os campos já existentes num relatório cross-skill |
| Consistência dos artefatos gerados pelas skills | Não — só detectada manualmente nesta auditoria (divergência de nomenclatura) | Requer checagem periódica de vocabulário/formato entre skills, como feito nesta análise |

**Recomendação prática:** dado que boa parte do insumo bruto já existe (o `LOG-ACOES.md` centralizado é um ativo valioso, presente em 5 das 9 skills), o maior ganho de curto prazo é uma skill/processo dedicado a **consolidar e agregar** esse log em indicadores, em vez de criar coleta nova do zero.

---

## 6. Validações Existentes (mercado) — conhecimento geral, não extraído dos arquivos

- **Avaliação de aderência a instruções em LLMs:** a prática mais estabelecida é o uso de **LLM-as-judge** — um segundo modelo (ou o mesmo modelo, em chamada isolada) avalia se a saída de uma execução seguiu cada regra de um checklist, produzindo um veredito estruturado. O padrão de "double-check via subagente independente" já presente em `executar-teste.md` é, na prática, uma instância manual desse mesmo princípio, aplicada a um caso específico (evidência de execução), não à aderência da skill como um todo.
- **Testes de regressão de prompt/skill ("prompt regression testing" / "eval suites"):** organizações que operam bibliotecas de prompts/skills em produção mantêm conjuntos de casos de teste com entrada e saída esperada (ou critérios de aceitação), rodados a cada alteração da skill — o mesmo princípio de CI/CD de software aplicado a artefatos de linguagem natural.
- **Anotação/auditoria humana amostral:** mesmo com avaliação automatizada, é prática comum revisar uma amostra periódica de execuções reais com um humano especialista de domínio (QA sênior, no caso), especialmente para os pontos identificados nesta análise como de maior risco de falso positivo (comparação de evidência, cenários de borda).
- **Como organizações maduras monitoram esse risco (padrão geral, não específico de nenhuma ferramenta):** tratam a skill como um artefato de engenharia com dono, versão, changelog e suíte de casos de referência — não como um documento de texto livre editado ad hoc. A prática de datar decisões dentro do próprio arquivo (visto em várias das 9 skills) já é um passo nessa direção (rastreabilidade de decisão), mas não substitui uma suíte de teste formal da skill em si.

**Limitação explícita:** não há, nos arquivos fornecidos, nenhuma evidência de que exista hoje uma suíte de teste formal, versionamento estruturado ou processo de revisão periódica das próprias skills — o único mecanismo observado de "aprendizado" é a adição reativa de regras de troubleshooting após incidentes reais (citados nos arquivos). Isso é válido como prática de melhoria contínua, mas é reativo, não preventivo.

---

## Resultado Consolidado

### 1. Principais riscos identificados
Perda de contexto em execuções longas (já documentada como recorrente em `executar-teste.md`); omissão silenciosa de validação sem checklist obrigatório; inconsistência entre skills por manutenção incremental não sincronizada (divergência real encontrada); acoplamento de domínio que impede reuso; ausência de cobertura estrutural para multi-banco, multi-repo e dependências de configuração — os três gaps centrais para BPM/ECM identificados na auditoria anterior.

### 2. Probabilidade e impacto

| Risco | Probabilidade | Impacto |
|---|---|---|
| Omissão de cenário por escopo de origem restrito | Alta (já é comportamento de desenho, não acidente) | Alto — funcionalidade sem teste chega em produção |
| Falso positivo por falta de evidência de rede | Média (mitigada por regra explícita) | Alto — bug real não detectado |
| Inconsistência entre skills (nomenclatura/formato) | Alta (já observada) | Médio — gera retrabalho e confusão, não necessariamente bug em produção |
| Cobertura ausente Oracle x SQL Server | Certa, dado o estado atual (0% de cobertura) | Alto — é requisito obrigatório do produto |
| Regressão cross-repo não detectada | Alta em arquitetura multi-repo sem skill dedicada | Alto — efeito colateral silencioso entre subprodutos |

### 3. Estratégias recomendadas
Priorizar, nesta ordem: (a) checklists obrigatórios com categoria "N/A justificado" para toda nova dimensão (config, SGBD, multi-repo); (b) manter a arquitetura multi-skill já existente em vez de consolidar em uma skill única, adicionando uma camada de orquestração explícita quando necessário; (c) instituir revisão periódica de consistência entre skills (a divergência de nomenclatura encontrada nesta auditoria não teria sido pega sem uma leitura comparativa completa); (d) dobrar a aposta em rastreabilidade de campo fixo (como já feito no rótulo "Cenário de origem") para todo novo relacionamento entre artefatos.

### 4. Indicadores de monitoramento recomendados
Cobertura funcional e de dependências (a construir), taxa de defeitos escapados, reabertura de bugs, efetividade dos testes — todos com insumo bruto já parcialmente disponível no `LOG-ACOES.md` existente, faltando consolidação.

### 5. Arquitetura recomendada para a biblioteca de skills de QA (BPM/ECM)
Manter o padrão já observado de múltiplas skills especializadas encadeadas manualmente (não automaticamente, preservando o gate humano entre etapas), com uma camada orquestradora explícita (equivalente a `homologar-release.md`) para consolidação de decisão final. Adicionar: uma skill de rastreamento de dependências de configuração, uma (ou duas) skill(s) de validação multi-banco, e uma skill de análise de impacto multi-repositório — todas consumidas pelas demais skills existentes sem precisar reescrevê-las inteiramente, desde que o contrato de dados entre elas (como já é o padrão de "Origem"/"Cenário de origem") seja definido com o mesmo rigor de formato fixo já demonstrado em `gerar-defeito.md`.

### 6. Recomendações práticas contra perda de contexto, omissão e degradação
- Manter skills pequenas e especializadas (o padrão já em uso é o correto — resistir à tentação de consolidar).
- Checklist obrigatório com "N/A justificado" em vez de campo livre para toda validação que precisa ser garantida.
- Reaproveitar relatórios de skills anteriores na mesma conversa (já praticado) em vez de reprocessar, para reduzir volume de contexto ativo por execução.
- Double-check independente (subagente sem histórico herdado) em qualquer decisão de alto risco ou baixa confiança.
- Revisão periódica de consistência terminológica/estrutural entre skills, tratando a biblioteca de skills como um sistema (com testes de regressão), não como documentos independentes.
