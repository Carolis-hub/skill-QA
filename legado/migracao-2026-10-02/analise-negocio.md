---
description: Interpreta uma User Story do Azure DevOps (regra de negocio, criterios de aceite) e extrai objetivo, regras explicitas/implicitas, ambiguidades, dependencias e riscos, sem inventar informacao.
---

Analisar o negocio da historia do Azure DevOps a partir de **$ARGUMENTS**.

Formato esperado: `[ID da historia] [nome do projeto (opcional)]`

Exemplos:
- `146157` → projeto resolvido automaticamente a partir do próprio work item
- `146157 "Nome do Projeto"` → projeto explicito

Este comando é **somente leitura** — não cria, edita nem comenta nada no Azure DevOps. É a etapa de Análise de Negócio (equivalente à Skill 1 / QA Business Analyst) que antecede a análise técnica e a criação do mapa de testes.

---

## Regra fundamental

**Não inventar regra de negócio.** Toda afirmação no relatório final deve ser rastreável a um campo específico da história (título, descrição, critérios de aceite, comentários). Quando uma informação necessária não estiver disponível, escrever literalmente:

> **Informação não encontrada / necessita validação.**

Nunca preencher esse vazio com suposição não marcada como tal.

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

Se qualquer um dos 9 itens não tiver conteúdo aplicável, escreva explicitamente `Nenhum identificado` — não omita a seção.

---

## Step 4 — Relatório final

Apresente em Markdown, nesta estrutura fixa:

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
```

Finalize perguntando ao usuário se deseja prosseguir para a análise técnica (`/analise-tecnica`, quando existir) ou diretamente para o mapa de testes (`/gerar-mapa-testes-v2 <ID>`) — não encadeie automaticamente.

---

## Troubleshooting

- Se a história não tiver critérios de aceite preenchidos, não invente critérios — registre isso na seção "Informações ausentes" e baseie os "Comportamentos esperados" apenas na descrição.
- Se `$STORY_RELATIONS` incluir cards filhos do tipo `Análise` ou `Analise Review`, **não os utilize aqui** — eles são insumo da análise técnica, não da análise de negócio.
- Se durante a extração você perceber uma dúvida que só o código/PR responde (ex.: qual configuração de infraestrutura é usada, como simular uma falha técnica, se um job de backfill já rodou em um ambiente), não a liste em "Informações ausentes" — apenas não invente a resposta; ela será endereçada em `/analise-tecnica`.
- Se o projeto informado não existir, o erro do MCP normalmente indica isso claramente; repasse a mensagem ao usuário em vez de tentar adivinhar o nome correto.
