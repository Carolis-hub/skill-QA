---
description: Interpreta uma User Story do Azure DevOps (regra de negocio, criterios de aceite) e extrai objetivo, regras explicitas/implicitas, ambiguidades, dependencias e riscos, sem inventar informacao.
---

Analisar o negocio da historia do Azure DevOps a partir de **$ARGUMENTS**.

Formato esperado: `[ID da historia] [nome do projeto (opcional)]`

Exemplos:
- `146157` → projeto resolvido automaticamente a partir do próprio work item
- `146157 "Nome do Projeto"` → projeto explicito

Este comando é **somente leitura no Azure DevOps** — não cria, edita nem comenta nada lá. A única escrita permitida é local, dentro de `$CICLOS_DIR` (`C:\skills-qualidade\ciclos-executados`): o relatório da análise e o arquivo de pendências do dev (ver Step 4.5 e Step 5). É a etapa de Análise de Negócio (equivalente à Skill 1 / QA Business Analyst) que antecede a análise técnica e a criação do mapa de testes.

---

## Regra fundamental

**Não inventar regra de negócio.** Toda afirmação no relatório final deve ser rastreável a um campo específico da história (título, descrição, critérios de aceite, comentários). Quando uma informação necessária não estiver disponível, escrever literalmente:

> **Informação não encontrada / necessita validação.**

Nunca preencher esse vazio com suposição não marcada como tal.

**Remissão ao legado não é definição.** Se a história diz apenas "manter o comportamento legado" (ou equivalente) sem descrever o comportamento esperado, a análise **não pode ser concluída** — aplique o Step 3.5.

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

Mesmo com a análise bloqueada, execute o Step 4.5 para os pontos de atenção do dev. Nada é criado, editado ou comentado no Azure DevOps. Só conclua a análise (Step 4) quando o Step 3.5 não encontrar nenhuma pendência bloqueante.

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
- Informação não encontrada / necessita validação: <pergunta específica>

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

Informe no fim do relatório os caminhos dos arquivos gerados nos Steps 4.5 e 5.

Finalize perguntando ao usuário se deseja prosseguir para a análise técnica (`/analise-tecnica`, quando existir) ou diretamente para o mapa de testes (`/gerar-mapa-testes-v2 <ID>`) — não encadeie automaticamente.

---

## Step 4.5 — Registrar os pontos de atenção do dev (executar sempre, inclusive quando o Step 3.5 bloqueia)

**Regra de registro (diretório único):** todo arquivo gravado por esta skill vai para o diretório fixo `$CICLOS_DIR` = `C:\skills-qualidade\ciclos-executados`, nunca para uma pasta relativa ao diretório de trabalho nem para dentro de `skills-qa-smartshare`. Se a sessão estiver em outro diretório, use mesmo assim o caminho absoluto; crie as subpastas se não existirem.

Defina `$EXEC` = data e hora da execução no formato `AAAA-MM-DD_HHmm` (ex.: `2026-10-15_1432`), a mesma para os arquivos deste Step e do Step 5.

Grave os pontos de atenção do dev (item 10 do Step 3) em `$CICLOS_DIR\US-<ID>\pendencias-dev\US-<ID>_<$EXEC>.md` (crie os diretórios se não existirem). **Nunca sobrescreva** arquivo de execução anterior: cada execução gera um arquivo novo. É o arquivo mais recente (maior `$EXEC` no nome) que `/analise-tecnica` usa para validar se tudo o que a US pediu ao dev foi respondido.

Formato fixo:

```
# Pendências do dev — US #<ID> <Título>

Gerado em: <AAAA-MM-DD> por /analise-negocio | Revisão da US (System.Rev): <rev>

| ID | Item (transcrito da descrição) | Onde na US | CA que depende | Responsável declarado | Status |
|---|---|---|---|---|---|
| PD-<ID>-01 | <trecho literal> | <seção da descrição / CA n> | <CA n ou "—"> | <dev / back-end / time> | Aberto |
```

- Um ID por item (`PD-<ID>-NN`), na ordem em que aparecem na descrição; transcreva literalmente, sem reinterpretar nem responder.
- Inclua no cabeçalho a linha `Execução: <$EXEC>`.
- `Status` sempre `Aberto` — quem atualiza é a `/analise-tecnica`, nunca esta skill.
- Se não houver pontos de atenção, grave o arquivo mesmo assim com a linha `Nenhuma pendência atribuída ao dev na descrição da US.` no lugar da tabela, para a `/analise-tecnica` distinguir "sem pendências" de "análise de negócio não executada".
- Não grave nada no Azure DevOps.

---

## Step 5 — Salvar o relatório da análise (executar sempre)

Grave **exatamente o que foi apresentado ao usuário** — o relatório do Step 4 ou o relatório de bloqueio do Step 3.5 — em `$CICLOS_DIR\US-<ID>\analises-negocio\US-<ID>_<$EXEC>.md` (mesmo `$EXEC` do Step 4.5; crie os diretórios se não existirem). **Nunca sobrescreva** execuções anteriores: cada execução gera um arquivo novo.

Cabeçalho obrigatório no topo do arquivo, antes do relatório:

```
---
us: <ID>
titulo: <título>
execucao: <$EXEC>
revisao_us: <System.Rev>
resultado: Concluída | Bloqueada
pendencias_dev: C:\skills-qualidade\ciclos-executados\US-<ID>\pendencias-dev\US-<ID>_<$EXEC>.md
---
```

Informe ao usuário, no fim, os caminhos dos dois arquivos gravados (análise e pendências). Não grave nada no Azure DevOps.

---

## Troubleshooting

- Se a história depende de "igual ao legado" / "como hoje" sem descrever o comportamento (inclusive quando a própria US manda "comparar com o legado antes de codar"), aplique o Step 3.5: se a descrição não atribuir a verificação ao dev, é pendência de negócio bloqueante (pare), não "Informações ausentes" do relatório final; se atribuir ao dev, é ponto de atenção (não bloqueia) e vai para o arquivo do Step 4.5.

- Se a história não tiver critérios de aceite preenchidos, não invente critérios — registre isso na seção "Informações ausentes" e baseie os "Comportamentos esperados" apenas na descrição.
- Se `$STORY_RELATIONS` incluir cards filhos do tipo `Análise` ou `Analise Review`, **não os utilize aqui** — eles são insumo da análise técnica, não da análise de negócio.
- Se durante a extração você perceber uma dúvida que só o código/PR responde (ex.: qual configuração de infraestrutura é usada, como simular uma falha técnica, se um job de backfill já rodou em um ambiente), não a liste em "Informações ausentes" — apenas não invente a resposta; ela será endereçada em `/analise-tecnica`.
- Se o projeto informado não existir, o erro do MCP normalmente indica isso claramente; repasse a mensagem ao usuário em vez de tentar adivinhar o nome correto.
