---
description: Identifica paginas da wiki do Azure DevOps impactadas por uma historia validada e propoe atualizacao (funcionalidade, regra de negocio, FAQ, exemplos, procedimentos) — sempre com aprovacao explicita, pagina por pagina, antes de publicar.
---

Atualizar a documentação a partir de **$ARGUMENTS**.

Formato esperado: `[ID da história] [nome do projeto (opcional)] [nome da wiki (opcional)]`

Exemplo: `157538` ou `157538 "Nome do Projeto" "Nome do Projeto.wiki"`

Este comando é a Skill 8 (QA Documentation Agent). Recomendado rodar **depois** de uma alteração já validada (idealmente após `/homologar-release` ter aprovado, ou pelo menos após `/analise-negocio` ter confirmado as regras de negócio) — documentar um comportamento que ainda pode mudar gera trabalho perdido e informação errada publicada.

---

## Regra fundamental

**Nunca publicar em página de documentação sem aprovação explícita, página por página.** A ferramenta de escrita (`update_wiki_page`/`create_wiki_page`) substitui o conteúdo inteiro da página — não existe "patch" parcial no Azure DevOps Wiki. Por isso, o rascunho apresentado para aprovação deve ser sempre o **conteúdo final completo da página**, não só o trecho alterado, para o usuário revisar exatamente o que vai substituir o que já existe.

Nunca aprovar em lote — se várias páginas forem impactadas, aprovar uma de cada vez.

---

## Step 0 — Validar ambiente e localizar a wiki

Confirme `mcp__azure-devops` conectado. Chame `mcp__azure-devops__get_wikis` com o projeto informado (ou o projeto da própria história, quando não informado explicitamente) para obter `$WIKI_ID` (se o usuário não tiver informado o nome da wiki). Se houver mais de uma wiki no projeto, pergunte qual usar antes de prosseguir — não escolha a primeira arbitrariamente.

---

## Step 1 — Reunir o que de fato mudou

- Se `/analise-negocio` já rodou para essa história nesta conversa, reaproveite diretamente: objetivo, comportamentos esperados (contratos verificáveis), regras explícitas/implícitas.
- Se `/homologar-release` já rodou e incluiu essa história com status Aprovada/Aprovada com ressalvas, use isso como confirmação de que o comportamento é real e estável o suficiente para documentar.
- Se nenhuma das duas rodou, busque a história via `mcp__azure-devops_wit_get_work_item` e monte o mesmo resumo do `/analise-negocio` (objetivo + comportamentos esperados), deixando claro no relatório final que não houve validação prévia formal — isso deve reduzir a confiança da sugestão, não impedi-la.

---

## Step 2 — Localizar documentação potencialmente impactada

1. Chame `mcp__azure-devops__search_wiki` com termos-chave extraídos do título/domínio da história (nome da funcionalidade, módulo, tela). Rode mais de uma busca com sinônimos se o primeiro termo não achar nada (ex.: nome popular da tela, nome do módulo, apelido usado pelo time).
2. Para cada página candidata, chame `mcp__azure-devops__get_wiki_page` (`wikiId`, `pagePath`) para ler o conteúdo atual completo.
3. Se a busca não encontrar nenhuma página relacionada, não conclua automaticamente que não existe documentação — chame `mcp__azure-devops__list_wiki_pages` para navegar a árvore e checar manualmente se a funcionalidade está descrita em uma página com nome que a busca de texto não capturou.

---

## Step 3 — Comparar e propor

Para cada página encontrada, compare o conteúdo atual com os comportamentos confirmados no Step 1 e classifique a proposta em uma ou mais categorias:

- **Atualização de funcionalidade** — descrição de uma tela/fluxo que mudou.
- **Regra de negócio** — condição/regra documentada que ficou desatualizada ou incompleta.
- **FAQ** — pergunta que passa a ter resposta diferente, ou pergunta nova que a mudança introduz.
- **Exemplos** — exemplo/print/passo a passo que não reflete mais a tela real.
- **Procedimentos** — passo a passo operacional que muda por causa da alteração.

Se nenhuma página existente cobrir a funcionalidade e ela for relevante o suficiente para merecer documentação, proponha **criar uma página nova** (caminho sugerido + esboço de conteúdo) em vez de forçar a informação em uma página que não é sobre isso.

Nunca afirmar que uma regra mudou se isso não estiver confirmado no Step 1 — se a comparação for inconclusiva, registrar `Informação não encontrada / necessita validação.` em vez de propor uma edição especulativa.

---

## Step 4 — Apresentar para aprovação (página por página)

Para cada página impactada, mostrar:

```
### Página: <pagePath> (wiki: <wikiId>)
**Categoria(s) da mudança:** ...
**O que está desatualizado hoje:** <trecho atual relevante, citado>
**Conteúdo final proposto (completo):**
<conteúdo markdown completo que substituiria a página>
```

**STOP HERE por página.** Pergunte: **"Aprovar a publicação desta página?"** e aguarde confirmação individual antes de seguir para a próxima página ou para o Step 5.

---

## Step 5 — Publicar (só após aprovação daquela página específica)

- Página existente aprovada → `mcp__azure-devops__update_wiki_page` com `wikiId`, `pagePath`, `content` (o conteúdo final completo aprovado), `comment` (ex.: `"Atualizado após #<ID> — <resumo curto>"`).
- Página nova aprovada → `mcp__azure-devops__create_wiki_page` com `wikiId`, `pagePath` (o caminho proposto), `content`, `comment`.

Após publicar, releia a página (`get_wiki_page`) para confirmar que o conteúdo publicado bate com o que foi aprovado — não presumir sucesso só pela ausência de erro na chamada.

Imediatamente após confirmar a publicação **desta página**, acrescente uma linha ao final da
tabela em `~/.claude/docs/projetos/skills-qa/LOG-ACOES.md` (via `Edit`, nunca sobrescrevendo o
arquivo) — uma linha por página publicada, não uma linha resumindo todas de uma vez:

```
| <data/hora atual, ex.: via `Get-Date -Format "yyyy-MM-dd HH:mm"`> | `/atualizar-documentacao` | Publicação de página de wiki (<criação\|atualização>) | Página `<pagePath>` (wiki `<wikiId>`) → US #<ID> | Sucesso | <nome do usuário que aprovou no chat> | Categoria(s): <...> |
```

---

## Step 6 — Relatório final

```
# Documentação atualizada — #<ID>

## Páginas publicadas
- <pagePath> — <categoria(s)>

## Páginas propostas mas não aprovadas ainda
- <pagePath> — motivo (usuário optou por revisar depois / rejeitou a proposta)

## Páginas novas sugeridas (não criadas)
- <pagePath sugerido> — <resumo do que conteria>
```

---

## Troubleshooting

- Se `search_wiki` não retornar nada e `list_wiki_pages` mostrar uma árvore muito grande para revisar manualmente, apresente ao usuário a lista de páginas de nível superior e peça para indicar onde a funcionalidade provavelmente está documentada, em vez de abrir dezenas de páginas às cegas.
- Nunca reescrever uma página inteira quando só uma seção precisa mudar — preservar todo o restante do conteúdo original ao montar o "conteúdo final completo" do Step 4, já que a API substitui a página inteira.
- Se o usuário aprovar a publicação mas o conteúdo lido de volta no Step 5 não bater com o aprovado, reportar isso como uma falha de publicação, não como sucesso.
