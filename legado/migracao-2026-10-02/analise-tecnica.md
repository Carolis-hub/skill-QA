---
description: Le o card de Analise Tecnica (preenchido pelo dev) vinculado a uma historia do Azure DevOps, cruza com o PR vinculado quando existir, e mapeia classes/componentes impactados, dependencias e risco por camada.
---

Analisar o impacto tecnico da historia do Azure DevOps a partir de **$ARGUMENTS**.

Formato esperado: `[ID da historia] [nome do projeto (opcional)]`

Exemplos:
- `146157` → projeto resolvido automaticamente a partir do próprio work item
- `146157 "Nome do Projeto"` → projeto explicito

Este comando é **somente leitura**. É a etapa de Análise Técnica (equivalente à Skill 2 / QA Technical Analyst): responde "se isto mudar, quem depende disso e o que pode mudar de comportamento?". Roda depois de `/analise-negocio` e antes de `/gerar-mapa-testes-v2`.

---

## Regra fundamental

**A fonte da verdade técnica é o card `Análise`, preenchido pelo dev — não o LLM.** Este comando não deve inferir classes, métodos ou componentes impactados que não estejam:
- no card `Análise` (campos `Custom.Pontosdeimpacto` / `Custom.CasodeTeste`), ou
- no PR/commit vinculado à história (diff real via MCP).

Onde faltar essa base, escrever `Informação não encontrada / necessita validação.` — nunca supor.

**Escopo da análise de risco (decisão de 2026-09-15, Cintia + time de dev):** dependências, impacto
e risco (Step 3, itens 3–5) são avaliados **apenas para mudanças dentro do escopo declarado da US**
(o escopo que `/analise-negocio` já extraiu, ou a seção "Escopo" da própria história). Quando o diff
do PR tocar arquivos fora desse escopo, esta skill continua **detectando e listando o fato** (é o
cruzamento card × PR que ela já faz por natureza — não deixar de sinalizar), mas **não analisa risco
nem recomenda ação** sobre esses itens — isso é trabalho de uma skill própria do time de dev (a
criar, roda depois dos testes de QA), não de QA. Ver seção "Discrepâncias" no Step 4.

---

## Pré-requisito bloqueante: card `Análise` do dev

Antes de qualquer análise, é obrigatório localizar, entre os filhos (`Hierarchy-Forward`) da história, um card cujo `System.WorkItemType` seja **exatamente** `Análise`.

⚠️ **Atenção com o card `Analise Review`**: existe um segundo tipo de card, `Analise Review`, criado por outro dev para *revisar* a análise técnica. Seus campos `Custom.Pontosdeimpacto` e `Custom.CasodeTeste` estarão **sempre vazios**. Nunca use esse card como fonte — filtre por `System.WorkItemType == "Análise"` (comparação exata) e ignore qualquer tipo que contenha "Review".

**Se nenhum card `Análise` for encontrado** (ou se existir só o `Analise Review`), **pare imediatamente** e reporte, sem gerar nenhuma seção de análise:

> ⏸️ **Análise técnica ainda não disponível.** A história #`<ID>` não possui um card filho do tipo `Análise` preenchido pelo dev. Esta etapa depende desse insumo — aguarde o dev registrar a análise técnica no Azure DevOps antes de rodar `/analise-tecnica` novamente.
>
> Enquanto isso, é possível seguir direto para `/gerar-mapa-testes-v2 <ID>`, que usa apenas a história (sem os pontos de impacto técnico) — mas o mapa ficará mais raso.

Não tente compensar a ausência do card lendo o código diretamente por conta própria como substituto — isso muda a fonte de verdade combinada com o time (o dev é quem valida o que foi de fato alterado) e foge do escopo desta skill.

---

## Step 0 — Validar ambiente

Igual ao `/analise-negocio`: chame `mcp__azure-devops_wit_get_work_item` com o ID informado. Se o MCP estiver indisponível ou a ferramenta não existir, pare e reporte. Um `404` (história inexistente) não é falha de ambiente — repasse o erro e pare.

---

## Step 1 — Buscar a história e seus filhos

```
$parts = "$ARGUMENTS".Trim() -split '\s+'
$wiId    = $parts[0]
$project = if ($parts.Count -gt 1) { ($parts[1..($parts.Count-1)] -join ' ').Trim('"') } else { $null }
```

1. Chame `mcp__azure-devops_wit_get_work_item` com `id`: `$wiId`, `project`: `$project` (se `$null`, omita o parâmetro e deixe o MCP resolver pelo próprio work item), `expand`: `"all"`.
2. Extraia `$STORY_TITLE`, `$STORY_RELATIONS`.
3. Filtre `$STORY_RELATIONS` onde `rel == "System.LinkTypes.Hierarchy-Forward"` → lista de IDs filhos.
4. Se não houver filhos, aplique o bloqueio descrito acima (nenhum card `Análise` possível).
5. Chame `mcp__azure-devops_wit_get_work_items_batch_by_ids` com os IDs filhos, `project`: `$project`, `fields`: `["System.WorkItemType", "System.Title", "System.State", "Custom.Pontosdeimpacto", "Custom.CasodeTeste"]`.
6. Encontre o item com `fields.'System.WorkItemType' == "Análise"` (exato). Se não existir, aplique o bloqueio.

Capture:
- `$ANALISE_ID`, `$ANALISE_TITLE`, `$ANALISE_STATE`
- `$ANALISE_PONTOS` = `Custom.Pontosdeimpacto` (HTML/texto)
- `$ANALISE_CASOS` = `Custom.CasodeTeste` (HTML/texto)

Se `$ANALISE_PONTOS` estiver vazio mesmo com o card existindo, trate como bloqueio também — um card `Análise` criado mas não preenchido equivale, na prática, a análise ainda não disponível.

---

## Step 2 — Cruzar com Pull Request vinculado (quando existir)

Procure em `$STORY_RELATIONS` (ou nas relations do próprio card `Análise`, se ele tiver) um `ArtifactLink` para Pull Request (`vstfs:///Git/PullRequestId/...`).

- **Se existir PR vinculado**: chame `mcp__azure-devops__get_pull_request` para metadados e `mcp__azure-devops__get_pull_request_changes` para a lista real de arquivos alterados. Use isso para **corroborar ou expandir** (nunca substituir) o que o dev escreveu em `$ANALISE_PONTOS`.
- **Se não existir PR vinculado ainda**: prossiga apenas com `$ANALISE_PONTOS`/`$ANALISE_CASOS` e registre na seção de riscos que a análise não pôde ser confirmada contra o código real.

Se um arquivo do diff tocar em algo não mencionado em `$ANALISE_PONTOS`, sinalize isso explicitamente como discrepância — não incorpore silenciosamente como se o dev já tivesse dito. Para cada arquivo em discrepância, classifique em 1 linha se ele está **dentro** ou **fora** do escopo declarado da US (usando o escopo de `/analise-negocio` ou da própria história como critério — não decidir por impressão própria). Discrepâncias dentro do escopo seguem para a análise normal do Step 3 (dependências/risco); discrepâncias fora do escopo só são listadas como fato, sem risco/recomendação (ver Step 4).

---

## Step 3 — Estruturar a análise técnica

Produza, sempre citando a origem (`análise do dev` ou `PR #<n>, arquivo <path>`):

1. **O que foi alterado** — classes/métodos/componentes citados em `$ANALISE_PONTOS` e/ou nos arquivos do diff.
2. **Onde foi alterado** — camada: front-end, API, serviço/domínio, banco de dados, integrações, relatórios.
3. **Quem depende disso** — dependências diretas (chamadores imediatos) e indiretas (efeito em cascata), conforme descrito pelo dev ou visível no diff. **Restrito a mudanças dentro do escopo da US** (ver "Escopo da análise de risco" na Regra fundamental).
4. **O que pode ser impactado** — funcionalidades, integrações e dados potencialmente afetados, mesmo que não tenham sido alterados diretamente. **Restrito ao escopo da US.**
5. **Qual o risco** — classifique cada camada tocada como Alto / Médio / Baixo, com uma linha justificando (frequência de uso, criticidade de negócio, histórico de defeitos se mencionado). **Restrito ao escopo da US** — arquivos do diff fora do escopo vão só na seção "Discrepâncias" (Step 4), sem classificação de risco aqui.
6. **Casos de teste sugeridos pelo dev** (`$ANALISE_CASOS`) — reproduza como está, marcado claramente como sugestão do dev, não validada pelo QA ainda.
7. **Pré-requisitos técnicos de execução de teste** — para cada critério de aceite que dependa de infraestrutura/configuração (ex.: nome de bucket, variável de ambiente, URL) ou de cenário negativo/falha técnica, identifique no card de Análise ou no PR: (a) qual configuração real é usada, (b) se existe mecanismo para reproduzir a falha em ambiente de teste (feature flag, credencial inválida, mock/stub, LocalStack). Quando essa informação não estiver no card nem no PR, registre em "Informações ausentes" e marque explicitamente como **bloqueante para `/executar-teste`** — não apenas como observação técnica.

Se `$ANALISE_PONTOS` for muito genérico (ex.: "ajustes no back-end"), não crie detalhamento fictício para preencher a tabela — registre a limitação em "Informações ausentes".

---

## Step 4 — Relatório final

```
# Análise Técnica — #<ID> <Título da história>

**Card de Análise:** #<ANALISE_ID> (<estado>)
**PR vinculado:** <#PR ou "nenhum vinculado ainda">

## O que foi alterado
...

## Onde foi alterado (por camada)
| Camada | Alterado | Risco | Justificativa |
|---|---|---|---|

## Dependências diretas
...

## Dependências indiretas
...

## Funcionalidades potencialmente impactadas
...

## Integrações potencialmente impactadas
...

## Dados potencialmente impactados
...

## Discrepâncias entre análise do dev e o PR (se houver)

### Dentro do escopo da US
<arquivo(s) do diff não mencionados no card, mas dentro do escopo declarado — seguem incorporados na análise de risco acima>

### Fora do escopo da US
<apenas fato: arquivo + resumo de 1 linha do que mudou + "fora do escopo desta US". Sem análise de risco/recomendação aqui — é matéria da skill de revisão de branch/PR do time de dev (a criar), não desta análise.>

## Casos de teste sugeridos pelo dev
...

## Pré-requisitos técnicos de execução de teste
- <config/mecanismo encontrado no card ou no PR, ou "Informação não encontrada / necessita validação — bloqueante para /executar-teste">

## Informações ausentes
- Informação não encontrada / necessita validação: ...
```

Finalize perguntando se o usuário quer seguir para `/gerar-mapa-testes-v2 <ID>` — não encadeie automaticamente.

---

## Troubleshooting

- Card `Análise` existe mas ambos os campos (`Custom.Pontosdeimpacto`, `Custom.CasodeTeste`) vêm vazios → trate como bloqueio (ver seção de pré-requisito), não como "nenhum risco identificado".
- Mais de um card `Análise` entre os filhos → use o de `System.ChangedDate` mais recente e avise o usuário da duplicidade.
- `get_pull_request_changes` falhar ou não existir PR linkado → não é erro bloqueante, apenas reduz a confiança da análise; registre isso no relatório.
- Nunca confundir `Análise` com `Analise Review` — reconferir o `System.WorkItemType` exato antes de extrair os campos.
- Discrepância "fora do escopo da US" não é motivo para aprofundar risco/recomendação por conta própria, mesmo que pareça relevante (ex.: mudança de infraestrutura, regra de negócio de outro módulo) — listar o fato e apontar para a skill de revisão de branch/PR do time de dev; se essa skill ainda não existir, dizer isso explicitamente em vez de preencher o vácuo com análise própria.
