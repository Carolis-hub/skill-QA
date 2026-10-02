---
description: Monta o registro estruturado de um defeito (Bug) a partir de uma analise de falha ja concluida e cria no Azure DevOps via MCP — sempre com confirmacao explicita do usuario antes de escrever. Severidade e sempre sugestao, nunca decisao automatica.
---

Gerar o defeito a partir de **$ARGUMENTS**.

Formato esperado: `[ID da história ou Test Case] [nome do projeto (opcional)]`

Exemplo: `157538` ou `157538 "Nome do Projeto"`

Este comando é a Skill 6 (Geração de Defeito). Ele **depende de uma análise de falha com veredito `SIM`** — de `/analise-falha`, já rodada nesta conversa, ou de informação equivalente fornecida explicitamente pelo usuário agora. Nunca inventa contexto, e nunca cria o item no Azure DevOps sem confirmação explícita do usuário.

---

## Pré-requisito bloqueante

1. Se `/analise-falha` rodou nesta conversa para o mesmo ID e o veredito foi `NÃO`, **pare** e informe que a evidência ainda não é suficiente — não gere o defeito mesmo que o usuário peça, a menos que ele forneça agora informação nova que mude o veredito (nesse caso, rode o Step 2 do `/analise-falha` de novo mentalmente antes de prosseguir).
2. Se `/analise-falha` não rodou para este ID nesta conversa, e o usuário não forneceu manualmente contexto/passos/esperado/obtido/evidência suficientes, **não prossiga** — peça essas informações ou sugira rodar `/analise-falha` primeiro.

---

## Step 0 — Reunir os dados do defeito

A partir do relatório de `/analise-falha` (reaproveitar diretamente) ou do que o usuário forneceu agora, monte:

- **Contexto** — o que estava sendo testado e por quê (história, cenário do mapa de testes).
- **Cenário de origem** — campo estruturado, obrigatório sempre que a falha veio de um cenário publicado num card "Criar Mapa de Teste" (via `/executar-teste`/`/analise-falha`): registre no formato exato `#<N> do mapa de testes #<MAPA_ID>` (mais de um cenário: `#<N1>, #<N2> do mapa de testes #<MAPA_ID>`). Se a falha foi reportada manualmente, sem mapa de testes por trás, escreva `N/A — falha reportada manualmente, sem cenário de mapa associado`. **Não é só documentação**: é esse campo, gravado com esse formato fixo, que o `/executar-teste` (modo de reteste seletivo pós-bug) lê de volta depois para saber quais cenários sempre reincluir ao retestar este Bug — variar a redação quebra a leitura automática.
- **Pré-condições** — estado necessário para reproduzir.
- **Passos para reprodução** — sequência exata, numerada.
- **Resultado esperado** — literal, da regra de negócio/critério de aceite.
- **Resultado atual** — o que de fato aconteceu, com evidência.
- **Impacto** — quem/o que é afetado se isso for para produção sem correção.
- **Severidade sugerida** — Crítica / Alta / Média / Baixa, com uma linha de justificativa. É uma **sugestão**, não uma decisão — o texto do bug deve deixar isso claro (ex.: "Severidade sugerida: Alta — a confirmar com o time").
- **Ambiente** — onde foi observado (ex.: HMG).
- **Versão** — build/commit/PR, se conhecido; senão `Informação não encontrada / necessita validação.`
- **Evidências** — caminho(s) de arquivo local (screenshot) e/ou trecho de evidência de rede (status/headers/corpo), reaproveitados **exatamente como capturados** no relatório de `/executar-teste` (coluna Evidência) ou no que o usuário forneceu. Esta skill nunca recaptura evidência — não abre navegador, não tira screenshot novo. Se não houver caminho de arquivo disponível (ex.: usuário só descreveu o bug em texto), registrar isso e seguir sem anexo (Step 3.5 fica sem o que anexar).

Se qualquer um desses campos não puder ser preenchido com uma fonte real, escreva `Informação não encontrada / necessita validação.` — não complete com suposição para "fechar" o registro.

---

## Step 1 — Montar o rascunho e apresentar para aprovação

```
**Título:** BUG - [<comportamento inesperado, resumido>]

**Contexto:**
...

**Cenário de origem:** ...

**Pré-condições:**
...

**Passos para reprodução:**
1. ...
2. ...

**Resultado esperado:**
...

**Resultado atual:**
...

**Impacto:**
...

**Severidade sugerida:** <Crítica|Alta|Média|Baixa> — a confirmar com o time
**Ambiente:** ...
**Versão:** ...
**Evidências:** ...
```

**STOP HERE.** Pergunte: **"Aprovar criação deste Bug no Azure DevOps (projeto `<project>`)?"** e aguarde confirmação explícita. Não chame nenhuma ferramenta de escrita antes disso.

---

## Step 2 — Criar o Bug via MCP (só após aprovação)

Chame `mcp__azure-devops__create_work_item` com:
- `projectId`: conforme `$ARGUMENTS`, ou resolvido a partir do projeto da história de origem quando não informado explicitamente
- `workItemType`: `"Bug"`
- `title` = título aprovado (com o prefixo `BUG -`)
- `additionalFields`:
  - `Microsoft.VSTS.TCM.ReproSteps` **sempre** = a estrutura completa em HTML (contexto + cenário de origem + pré-condições + passos + resultado esperado/atual + impacto + severidade sugerida + ambiente + versão + evidências, incluindo a tabela comparativa quando fizer sentido). **Este é o campo padrão para o conteúdo do bug — não o `description`/`System.Description`.**
  - `Microsoft.VSTS.Common.Severity` = severidade sugerida (mapear para a escala do Azure DevOps do projeto, ex. `2 - High`)

⚠️ **O parágrafo "Cenário de origem" precisa de rótulo fixo no HTML**, exatamente `<p><strong>Cenário de origem:</strong> #21 do mapa de testes #161676</p>` (ajustando os números) — é esse rótulo literal, em negrito, que o `/executar-teste` procura depois via regex para montar o reteste seletivo pós-bug. Não reescrever com sinônimos ("Origem do defeito", "Cenário relacionado" etc.) nem mudar a pontuação do formato `#<N> do mapa de testes #<MAPA_ID>`.

⚠️ **Por que `ReproSteps` e não `Description`:** o template de Bug deste projeto exibe `Microsoft.VSTS.TCM.ReproSteps` como o campo principal do card — `System.Description` existe mas fica pouco visível/pode nem aparecer na tela padrão. Descoberto em 2026-09-21 (US #161109, Bug #161659): o defeito foi criado só com `description` preenchido, a usuária abriu o card e não viu a explicação/passos, porque olhava o card real, onde `ReproSteps` estava vazio. Nunca usar o parâmetro `description` do `create_work_item` como único lugar do conteúdo — ele mapeia para `System.Description`, não para o campo visível no card. Se preferir, pode espelhar o mesmo conteúdo em `description` também (redundância inofensiva), mas `ReproSteps` via `additionalFields` é obrigatório.

Capture o `$BUG_ID` retornado. **Antes de declarar sucesso no Step 4, chame `mcp__azure-devops__get_work_item` no `$BUG_ID` e confirme que `Microsoft.VSTS.TCM.ReproSteps` não está `null`/vazio** — não confie só no eco da chamada de criação.

---

## Step 3 — Vincular à história (só após criação, com confirmação separada)

Pergunte se deseja vincular o Bug à história de origem (`$STORY_ID`, se conhecida).

⚠️ **O vínculo correto é filho (Hierarchy), não "Related".** No board do Azure DevOps, o menu de contexto do card da US (⋯ → "Add Bug") cria o Bug como **filho** da história — é esse vínculo que faz o ícone de bug (joaninha) aparecer nos badges do card, ao lado dos badges de Análise/Mapa de Teste (que também são filhos). Um link `Related` cria a relação, mas ela fica invisível na visão compacta do board — o Bug "desaparece" dentro da US para quem só olha o board.

Se o usuário confirmar o vínculo, chame `mcp__azure-devops__wit_work_item_link_write` com `action: "link"`, `project`, e `updates: [{ "id": <BUG_ID>, "linkToId": <STORY_ID>, "type": "parent" }]` — isso cria o Bug como filho da história (equivalente ao "Add Bug" do board). Depois confirme no corpo da resposta que `relations` contém `"rel": "System.LinkTypes.Hierarchy-Reverse"` apontando para a história, com `"name": "Parent"`, antes de reportar sucesso.

Se por engano o Bug tiver sido criado/vinculado como `Related`, corrija: `wit_work_item_link_write` com `action: "unlink"`, `id: <BUG_ID>`, `type: "related"` para remover, e então repita o link acima com `type: "parent"`.

---

## Step 3.5 — Anexar evidências ao Bug (se houver arquivo de evidência)

Se o Step 0 capturou caminho(s) de arquivo local (screenshot(s) do `/executar-teste`), anexe ao Bug recém-criado. **Não existe tool MCP de upload de anexo** (`wit_work_item_attachment` só faz *download*) — use REST direto, mesmo padrão de PAT já usado em `/gerar-mapa-testes-v2`.

Não pergunte aprovação separada para isto — anexar a evidência que já embasou o Bug aprovado no Step 1 é parte da mesma criação, não uma ação nova.

Para cada arquivo de evidência, em um único bloco PowerShell:

```powershell
$org     = "selbettidev"
$project = "$PROJECT"   # mesmo valor usado no Step 2
$bugId   = "$BUG_ID"
$filePath = "<caminho local do screenshot, ex.: .playwright-mcp\page-....png>"

# Derive PAT from PERSONAL_ACCESS_TOKEN (mesmo padrão do gerar-mapa-testes-v2)
$encoded = $env:PERSONAL_ACCESS_TOKEN
$decoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encoded))
$pat = ($decoded -split ':', 2)[1]
$base64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$pat"))
$authHeader = @{ Authorization = "Basic $base64" }

# 1. Upload do arquivo como anexo "solto" (ainda não ligado a nenhum work item)
$fileName = Split-Path $filePath -Leaf
$uploadUri = "https://dev.azure.com/$org/$([Uri]::EscapeDataString($project))/_apis/wit/attachments?fileName=$([Uri]::EscapeDataString($fileName))&api-version=7.1"
$attachment = Invoke-RestMethod -Uri $uploadUri -Headers $authHeader -Method Post -InFile $filePath -ContentType "application/octet-stream"
Write-Output "ATTACHMENT_URL=$($attachment.url)"

# 2. Vincular o anexo ao Bug via JSON Patch (relation rel=AttachedFile)
$patchBody = @(@{ op = "add"; path = "/relations/-"; value = @{ rel = "AttachedFile"; url = $attachment.url; attributes = @{ comment = "Evidencia capturada durante /executar-teste" } } }) | ConvertTo-Json -Depth 5
$patchHeaders = $authHeader + @{ "Content-Type" = "application/json-patch+json" }
Invoke-RestMethod -Uri "https://dev.azure.com/$org/$([Uri]::EscapeDataString($project))/_apis/wit/workitems/$bugId`?api-version=7.1" -Headers $patchHeaders -Method Patch -Body $patchBody | Out-Null
Write-Output "ATTACHED_TO_BUG=$bugId"
```

Repita para cada arquivo de evidência distinto. Se `Invoke-RestMethod` falhar (ex.: PAT sem escopo de anexos, arquivo não encontrado no caminho informado), não bloqueie a criação do Bug — ele já existe e está vinculado à história; apenas registre no relatório final que o anexo não pôde ser enviado e por quê.

---

## Step 4 — Confirmar e reportar

```
**Bug criado:** #<BUG_ID>
**Link:** https://dev.azure.com/selbettidev/<project>/_workitems/edit/<BUG_ID>
**Vinculado à história:** #<STORY_ID> (ou "não vinculado — usuário optou por não vincular agora")
**Evidências anexadas:** <lista de arquivos anexados, ou "nenhuma — motivo">
```

---

## Step 5 — Registrar no log de ações (governança)

Depois de reportar o sucesso, acrescente uma linha ao final da tabela em
`~/.claude/docs/projetos/skills-qa/LOG-ACOES.md` (via `Edit`, nunca sobrescrevendo o arquivo):

```
| <data/hora atual, ex.: via `Get-Date -Format "yyyy-MM-dd HH:mm"`> | `/gerar-defeito` | Criação de Bug + vínculo à história | Bug #<BUG_ID> → US #<STORY_ID> | Sucesso | <nome do usuário que aprovou no chat> | <resumo de 1 linha do bug + se evidência foi anexada> |
```

Se o Bug foi criado mas o vínculo ou o anexo de evidência falhou (ver Troubleshooting), registre
mesmo assim — com `Resultado` descrevendo o que funcionou e o que não (ex.: "Sucesso parcial —
Bug criado, anexo falhou por falta de PAT"). Nunca pule este passo silenciosamente; se a escrita
no log falhar, avise no relatório ao usuário, mas isso não desfaz a criação do Bug.

---

## Troubleshooting

- Se o usuário pedir para "criar o bug direto" sem ter rodado `/analise-falha` e sem fornecer os campos mínimos (esperado, obtido, passos, evidência), não crie nada — explique o que falta.
- Nunca decidir a severidade final sozinho — sempre apresentar como sugestão e deixar claro que é editável.
- Se `create_work_item` falhar por campo obrigatório do projeto não preenchido (ex.: Area Path, Iteration Path específicos de Bug), preencher com os mesmos valores da história de origem, não com um default genérico.
- Se `$env:PERSONAL_ACCESS_TOKEN` não estiver definido no Step 3.5, não trate como erro bloqueante — o Bug já foi criado e vinculado; apenas informe que a evidência não pôde ser anexada automaticamente por falta do PAT, e que o usuário pode anexar manualmente pela UI do Azure DevOps.
