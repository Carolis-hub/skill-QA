---
description: Interpreta uma User Story do Azure DevOps (regra de negocio, criterios de aceite) e extrai objetivo, regras explicitas/implicitas, ambiguidades, dependencias e riscos, sem inventar informacao.
---

Analisar o negocio da historia do Azure DevOps a partir de **$ARGUMENTS**.

Formato esperado: `[ID da historia] [nome do projeto (opcional)]`

Exemplos:
- `146157` → projeto resolvido automaticamente a partir do próprio work item
- `146157 "Nome do Projeto"` → projeto explicito

Este comando é **somente leitura no Azure DevOps**, com uma única exceção autorizada pela usuária (2026-11-04): ao iniciar o ciclo de qualidade, o Step 1.5 move a US para `Committed` (se ainda não estiver) e adiciona a tag `agentqa`. Fora isso, não cria, edita nem comenta nada lá. A única escrita local permitida é, dentro de `$CICLOS_DIR` (`C:\skills-qualidade\ciclos-executados`): o relatório da análise e o arquivo de pendências do dev (ver Step 4.5 e Step 5). Esta skill **não emite recomendações (`REC-...`)**: elas só são dadas pela `/analise-tecnica`, depois das duas análises e da validação no hub (ver Step 4.6). É a etapa de Análise de Negócio (equivalente à Skill 1 / QA Business Analyst) que antecede a análise técnica e a criação do mapa de testes.

---

## Regra transversal — Fidelidade à versão legada

Vale para todas as skills. O legado é a referência para descobrir o comportamento existente (a US explícita e as mudanças aprovadas prevalecem). Leia **`C:\skills-qualidade\skills-qa-smartshare\skills-qa-smartshare\templates\DIRETRIZ_FIDELIDADE_LEGADO.md`** (fonte única; não replique o texto aqui) e aplique-a ao que esta skill faz: não presumir melhoria, investigar divergência legado × migrado e registrar exceção documentada.

## Regra transversal — Dúvidas viram aprendizados

Vale para todas as skills. Pasta: `C:\skills-qualidade\analises-diversas\aprendizados` (regras e formato em `README.md`, lista em `INDICE.md`).

1. **Antes de perguntar à usuária** qualquer dúvida, pendência ou pedido de retorno, ler `INDICE.md`. Se existir aprendizado `Ativo` aplicável à mesma situação (escopo `Geral`, da skill, ou da própria US), aplicar sem perguntar e escrever no relatório `Aplicado APR-NNN`.
2. **Ao perguntar**, depois da resposta e **antes de seguir**, gravar `APR-NNN_<slug>.md` (situação, pergunta, resposta, como aplicar, escopo) e a linha no `INDICE.md`. Resposta vaga ou adiada fica `Pendente`, não vira regra.
3. Nunca gravar segredo (senha, token, chave): registrar só "informado no chat, não gravado".
4. Resposta que contradiz um aprendizado: atualizar, marcar o antigo `Substituído por APR-NNN`.
5. O aprendizado **não dispensa** confirmação de ação irreversível ou de escrita, aprovação de recomendação (`REC-...`) nem os guardrails desta skill: nesses casos a skill pergunta, podendo citar o aprendizado como contexto.

## Regra fundamental

**Não inventar regra de negócio.** Toda afirmação no relatório final deve ser rastreável a um campo específico da história (título, descrição, critérios de aceite, comentários). Quando uma informação necessária não estiver disponível, escrever literalmente:

> **Informação não encontrada / necessita validação.**

Nunca preencher esse vazio com suposição não marcada como tal.

**Remissão ao legado não é definição.** Se a história diz apenas "manter o comportamento legado" (ou equivalente) sem descrever o comportamento esperado, a análise **não pode ser concluída** — aplique o Step 3.5.

---

## Regra — US de BE: sem escopo nem dependência de front

**Escopo da regra (classificação técnica):** vale a classificação do mapa (Step 3.4 do `/gerar-mapa-testes-v3`). A regra se aplica quando a US é só BE e/ou API, sem FE; classificada com FE, não se aplica à parte de front. Sem classificação, vale o critério abaixo.

Quando a US é de back-end (título com `BE`, ex.: `(BE)`; descrição declarada de BE/back-end; ou módulo da API; em dúvida, pergunte à usuária), a análise de negócio trata **só do que a API e os dados fazem**. Critérios, regras ou textos que são de front (tela, tooltip, aviso de saída, campo ou seta, rótulo, layout, protótipo) **não entram** em "Comportamentos esperados", "Regras", "Dependências", "Riscos", nem viram pendência ou recomendação: liste-os em uma linha `Fora do escopo desta US (FE): CA <n> — <motivo>` no relatório. **Não liste front como dependência** da US e não trate a tela como forma de verificar um critério.

---

## Step 0 — Validar ambiente

Verifique que o servidor MCP `mcp__azure-devops` está disponível chamando `mcp__azure-devops_wit_get_work_item` com o ID informado. Se a chamada falhar porque o servidor MCP está indisponível ou a ferramenta não existe, **pare imediatamente** e reporte:

> `MCP server mcp__azure-devops indisponivel ou ferramenta ausente.`

Um erro `404 Not Found` (história inexistente) não é falha de ambiente — significa apenas que o ID está errado; reporte isso ao usuário e pare.

---

## Step 1 — Parse de argumentos e busca da história

```
$parts = "$ARGUMENTS".Trim() -split '\s+'
$wiId    = $parts[0]
$project = if ($parts.Count -gt 1) { ($parts[1..($parts.Count-1)] -join ' ').Trim('"') } else { $null }
```

Chame `mcp__azure-devops_wit_get_work_item` com:
- `id`: `$wiId`
- `project`: `$project` (se `$null`, omita o parâmetro e deixe o MCP resolver pelo próprio work item)
- `expand`: `"all"`

Capture do resultado:
- `$STORY_TITLE` = `fields.'System.Title'`
- `$STORY_TYPE` = `fields.'System.WorkItemType'`
- `$STORY_STATE` = `fields.'System.State'`
- `$STORY_DESC` = `fields.'System.Description'` (HTML)
- `$STORY_AC` = `fields.'Microsoft.VSTS.Common.AcceptanceCriteria'` (HTML, quando existir)
- `$STORY_TAGS` = `fields.'System.Tags'`
- `$STORY_RELATIONS` = `relations` (array, se houver)

Isso é uma chamada MCP — texto acentuado na resposta é seguro, sem necessidade de sanitização.

Ao renderizar `$STORY_DESC` e `$STORY_AC` no relatório final, remova tags HTML e decodifique entidades (`&nbsp;`, `&amp;`, `&lt;`, `&gt;`) para texto plano legível, preservando quebras de lista/parágrafo como marcadores markdown.

---

## Step 1.5 — Marcar o início do ciclo de qualidade na US (escrita autorizada)

Decisão da usuária (2026-11-04): a `/analise-negocio` é o início do ciclo de qualidade, e é ela que marca a US. Executar logo depois do Step 1, com `$STORY_STATE` e `$STORY_TAGS` já lidos, **uma única chamada** `mcp__azure-devops__wit_work_item_write` (`action: "update"`, `id`: `$wiId`, `project`: `$project`) com só as operações necessárias:

1. **Tag `agentqa`:** se `$STORY_TAGS` ainda não a contém (comparação sem diferenciar maiúsculas), grave `/fields/System.Tags` com as tags existentes **preservadas** mais `agentqa`, separadas por `; ` (ex.: `Tag1; agentqa`). Nunca remova nem reescreva as outras tags.
2. **Estado `Committed`:** se `$STORY_STATE` for `New` ou `Approved` (ainda antes de `Committed`), grave `/fields/System.State` = `Committed`. Se já estiver em `Committed` ou em estado posterior (`Done`, `Removed` etc.), **não mude o estado** e não retroceda a US.
3. Se nenhuma das duas operações for necessária (tag já presente e estado já `Committed` ou posterior), **não chame o MCP** e escreva no relatório `US já marcada (agentqa, <estado>)`.
4. Altere **somente** esses dois campos: nenhum outro campo, comentário, relação nem card filho (inclusive o card "Criar Mapa de Teste", que não é alterado por esta regra).
5. Se a escrita falhar (permissão, transição de estado inválida), **não bloqueie a análise**: registre a falha em uma linha no relatório (campo e mensagem do MCP) e siga em frente. Não tente contornar.
6. Reporte no relatório final, em uma linha, o que foi alterado (ex.: `US marcada: tag agentqa adicionada; estado Approved → Committed`).

---

## Step 2 — Histórico de comentários (opcional, enriquece contexto)

Se `mcp__azure-devops_wit_get_work_item_comments` estiver disponível, chame-a com `id`: `$wiId`, `project`: `$project`. Use os comentários apenas para:
- entender decisões/mudanças de escopo já discutidas,
- identificar se alguma dúvida de negócio já foi respondida ali.

Não trate opinião de comentário como regra de negócio definitiva a menos que esteja clara e não contestada. Se a busca de comentários falhar ou não houver nenhum, prossiga sem eles — isso não bloqueia a análise.

---

## Step 3 — Extração analítica

A partir de `$STORY_TITLE`, `$STORY_DESC`, `$STORY_AC` (e comentários, se houver), produza cada um dos itens abaixo. Para cada item, cite a origem entre parênteses (ex.: `(critérios de aceite)`, `(descrição)`, `(comentário de dd/mm)`).

1. **Objetivo da alteração** — o que a US pretende resolver/entregar.
2. **Comportamentos esperados** — o que o sistema deve fazer, em termos verificáveis (transforme cada critério de aceite em uma condição do tipo "Quando X, o sistema deve Y").
3. **Regras explícitas** — regras escritas literalmente na história.
4. **Regras implícitas** — regras que decorrem logicamente do que está escrito, mas não foram ditas diretamente (marque como `IMPLÍCITA:` e explique o raciocínio).
5. **Condições e exceções** — situações que alteram o comportamento padrão (status, permissão, tipo de usuário, limites).
6. **Dependências** — outras histórias, sistemas, integrações ou dados mencionados ou inferíveis de `$STORY_RELATIONS`.
7. **Informações ausentes** — perguntas de negócio (regra, escopo, prioridade) que a história não responde e que são necessárias para testar com segurança. **Não liste aqui perguntas técnicas ou de ambiente de execução** (nome de bucket/config específica, mecanismo para simular falha técnica, se um job já rodou em determinado ambiente, política de log) — essas são resolvidas por `/analise-tecnica`, que tem acesso ao PR/código. Se notar uma lacuna desse tipo durante a extração, não a trate como bloqueio de negócio.
8. **Ambiguidades** — trechos que admitem mais de uma interpretação; explique as interpretações possíveis.
9. **Riscos** — o que pode dar errado do ponto de vista de negócio se a regra for mal interpretada ou mal implementada.
10. **Itens pendentes da descrição da US** — pendências que a **própria descrição** declara como em aberto, transcritas como estão escritas (sem reinterpretar). Procure por seções e expressões como "Pendências", "Confirmar antes de iniciar", "Verificar pelo dev", "O dev verifica/valida", "a confirmar", "a definir", "TBD", "pendente", "registrar o resultado no PBI". Para cada item, informe: o trecho, quem é o responsável declarado (PM, dev/back-end/time, QA — ou "não informado") e se há CA que depende dele. Classifique cada item em:
    - **Ponto de atenção (dev):** a descrição atribui expressamente a resposta ao dev/back-end/time de desenvolvimento ("o dev verifica", "o dev valida", "o back-end precisa confirmar", "registrar o resultado no PBI"). **Não bloqueia** a análise; será respondido na análise técnica e **deve ser salvo no arquivo do Step 4.5**.
    - **Pendência de outro responsável** (PM, PO, negócio ou "não informado"): listar na tabela; se for remissão ao legado sem comportamento definido, aplica-se o Step 3.5.

    **Valor de "nenhuma pendência":** se o campo de pendências a confirmar antes do desenvolvimento trouxer um valor semelhante a "nenhuma pendência", "sem alterações", "nada a confirmar" ou "não há pendências", interprete como **não existem itens a validar antes do desenvolvimento**. Registre `Nenhum item a validar antes do desenvolvimento (descrição: "<frase literal>")` e **não** trate essa frase como item pendente nem como lacuna. Isso vale só para o campo em que a frase aparece: itens atribuídos ao dev em outras partes da descrição continuam sendo listados como pontos de atenção.

**Sem recomendações nesta skill (item 7):** liste cada informação ausente de negócio como `Informação não encontrada / necessita validação: <pergunta específica>`, **sem propor `REC-...`, sem sugerir solução e sem pedir aprovação**. A recomendação só pode ser dada depois das duas análises (negócio e técnica) e da validação no hub, e quem a emite é a `/analise-tecnica` (Step 4.6 dela), que pode já encontrar a resposta no PR, no card do dev ou no clássico. Ver Step 4.6.

Se qualquer um dos 10 itens não tiver conteúdo aplicável, escreva explicitamente `Nenhum identificado` — não omita a seção.

---

## Step 3.5 — Gate de conclusão: comportamento esperado indefinido (bloqueante)

Antes de gerar o relatório, varra título, descrição, critérios de aceite e comentários procurando **remissões ao legado/comportamento atual sem comportamento esperado definido**. Padrões típicos (não exaustivo): "manter o comportamento legado", "igual ao legado", "mesma regra/mensagem do legado", "conforme o legado", "como hoje", "como no Clássico", "comportamento atual", "comparar com o legado antes de codar".

Para cada ocorrência, verifique se a própria história descreve **de forma verificável** o resultado esperado (regra, valor, mensagem, destino, formato, passo a passo) — ou seja, se um QA conseguiria escrever o resultado esperado de um teste **sem consultar o sistema legado**.

- **Definido na história** (ex.: "mantém o legado: grava em X, no formato Y, com a mensagem Z") → não é bloqueio; trate como regra explícita.
- **Não definido, mas atribuído expressamente ao dev** (a descrição diz que o dev/back-end/time verifica, valida ou confirma e registra o resultado no PBI — ex.: "o dev verifica o nome do provider Oracle", "o back-end confirma onde a string é gravada") → **ponto de atenção, não bloqueio**. Não preencha a resposta; liste-o em "Pontos de atenção (dev)" e salve-o no arquivo do Step 4.5 para a `/analise-tecnica` validar.
- **Não definido e sem atribuição ao dev** (a história apenas remete ao legado, sem descrever o que ele faz e sem dizer quem verifica) → é **pendência bloqueante de negócio**. Essa lacuna é de **regra de negócio**, não técnica: a exceção do item 7 do Step 3 ("perguntas técnicas vão para `/analise-tecnica`") **não se aplica** a ela, e ela não pode ser empurrada para a análise técnica nem para o dev.
- Não preencha o comportamento esperado por suposição, nem pelo código, nem por conhecimento do produto.

**Se houver ao menos uma pendência bloqueante, pare aqui.** Não gere o relatório do Step 4 nem proponha o próximo passo. Reporte somente:

```
⏸️ Análise de negócio NÃO concluída — #<ID> <Título>

A história remete ao comportamento legado sem definir o comportamento esperado. Os itens abaixo precisam ser definidos (PO/PM/analista de negócio) e registrados na história antes de reexecutar `/analise-negocio`.

| # | Trecho da história (origem) | Remissão ao legado | O que precisa ser definido |
|---|---|---|---|
| 1 | <citação curta + onde está: descrição / CA n> | <ex.: "mesma regra e mensagem do legado"> | <pergunta de negócio específica> |

Itens já definidos de forma verificável (não bloqueiam): <lista ou "Nenhum">.

## Pontos de atenção (respondidos pelo dev) — não bloqueiam
| # | Item (transcrito da descrição) | Responsável declarado | CA que depende |
|---|---|---|---|
(ou `Nenhum identificado`)

## Outras pendências da descrição da US
<itens atribuídos a PM/PO/negócio/não informado, ou `Nenhum item a validar antes do desenvolvimento (descrição: "<frase literal>")`>
```

Mesmo com a análise bloqueada, apresente no chat os pontos de atenção do dev (Step 4.5). Nada é criado, editado ou comentado no Azure DevOps (além da marcação do Step 1.5). Só conclua a análise (Step 4) quando o Step 3.5 não encontrar nenhuma pendência bloqueante.

---

## Step 4 — Relatório final

Só execute este passo se o Step 3.5 não tiver encontrado pendência bloqueante. Apresente em Markdown, nesta estrutura fixa:

```
# Análise de Negócio — #<ID> <Título>

**Projeto:** <project> | **Tipo:** <tipo> | **Status:** <estado>

## Objetivo da alteração
...

## Comportamentos esperados (contratos verificáveis)
- Quando <condição>, o sistema deve <comportamento esperado>. (origem)
...

## Regras explícitas
...

## Regras implícitas
...

## Condições e exceções
...

## Dependências
...

## Informações ausentes
- Informação não encontrada / necessita validação: <pergunta específica> (origem: <CA/trecho>)

## Ambiguidades
...

## Riscos identificados
...

## Pontos de atenção (respondidos pelo dev)
| ID | Item (transcrito da descrição) | Responsável declarado | CA que depende |
|---|---|---|---|
(ou `Nenhum identificado`)

## Outras pendências da descrição da US
<itens de PM/PO/negócio/não informado, ou `Nenhum item a validar antes do desenvolvimento (descrição: "<frase literal>")`>
```

Se houver informações ausentes, avise em uma linha que as recomendações serão dadas pela `/analise-tecnica`, depois da validação no hub. Finalize perguntando ao usuário se deseja prosseguir para a análise técnica (`/analise-tecnica`) ou diretamente para o mapa de testes (`/gerar-mapa-testes-v3 <ID>`) — não encadeie automaticamente.

---

## Step 4.5 — Pontos de atenção do dev: registrar só no chat (executar sempre, inclusive quando o Step 3.5 bloqueia)

Os pontos de atenção do dev (item 10 do Step 3) são registrados **apenas no chat**, na seção "Pontos de atenção (respondidos pelo dev)" do relatório (Step 4) ou do relatório de bloqueio (Step 3.5). **Esta skill não grava nenhum arquivo** (nem de pendências, nem do relatório): o que vale é o que foi apresentado na conversa, e a `/analise-tecnica` lê esse relatório da própria conversa.

- Um ID por item (`PD-<ID>-NN`), na ordem em que aparecem na descrição; transcreva literalmente, sem reinterpretar nem responder.
- `Responsável declarado` e `CA que depende` seguem a tabela do Step 4. Não há coluna `Status`: quem verifica a resposta é a `/analise-tecnica`.
- Se não houver pontos de atenção, escreva `Nenhum identificado` na seção, para a `/analise-tecnica` distinguir "sem pendências" de "análise de negócio não rodou".
- Não grave nada no Azure DevOps (além da marcação do Step 1.5).

---

## Step 4.6 — Recomendações NÃO são emitidas nesta skill

Esta skill **não gera `REC-...`, não grava arquivo de recomendação e não pergunta aprovação de recomendação.** A recomendação só pode ser dada **depois das duas análises (negócio e técnica) e depois de validar no hub** (comportamento do SmartShare clássico, somente leitura). Quem emite é a `/analise-tecnica` (Step 4.6 dela), que parte das "Informações ausentes" deste relatório e só recomenda o que continuar sem resposta depois do card do dev, do PR e do hub.

- Toda lacuna de negócio fica apenas como `Informação não encontrada / necessita validação` no relatório (Step 4).
- Não proponha solução, "menor desvio" nem texto de regra no lugar da lacuna.
- Recomendação já existente de execução anterior (arquivo `pendencias-skills` da `/analise-tecnica`) não é lida, alterada nem aprovada aqui.
- Não grave nada no Azure DevOps (além da marcação do Step 1.5).

---

## Troubleshooting

- Se a história depende de "igual ao legado" / "como hoje" sem descrever o comportamento (inclusive quando a própria US manda "comparar com o legado antes de codar"), aplique o Step 3.5: se a descrição não atribuir a verificação ao dev, é pendência de negócio bloqueante (pare), não "Informações ausentes" do relatório final; se atribuir ao dev, é ponto de atenção (não bloqueia) e vai para o arquivo do Step 4.5.

- Se a história não tiver critérios de aceite preenchidos, não invente critérios — registre isso na seção "Informações ausentes" e baseie os "Comportamentos esperados" apenas na descrição.
- Se `$STORY_RELATIONS` incluir cards filhos do tipo `Análise` ou `Analise Review`, **não os utilize aqui** — eles são insumo da análise técnica, não da análise de negócio.
- Se durante a extração você perceber uma dúvida que só o código/PR responde (ex.: qual configuração de infraestrutura é usada, como simular uma falha técnica, se um job de backfill já rodou em um ambiente), não a liste em "Informações ausentes" — apenas não invente a resposta; ela será endereçada em `/analise-tecnica`.
- Se o projeto informado não existir, o erro do MCP normalmente indica isso claramente; repasse a mensagem ao usuário em vez de tentar adivinhar o nome correto.
