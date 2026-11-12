---
name: arquitetura-gerar-defeito
description: Monta o registro estruturado de um defeito (Bug) a partir de uma analise de falha ja concluida e cria no Azure DevOps via MCP — sempre com confirmacao explicita do usuario antes de escrever. Severidade e sempre sugestao, nunca decisao automatica.
---

Gerar o defeito a partir de **$ARGUMENTS**.

Formato esperado: `[ID da história, Bug ou cenário do mapa] [nome do projeto (opcional)]`

Exemplo: `157538` ou `157538 "Nome do Projeto"`

Este comando é a Skill 6 (Geração de Defeito). Ele **depende de uma análise de falha com veredito `SIM`** — de `/arquitetura-analise-falha`, preferencialmente registrada no ciclo, ou de informação equivalente fornecida explicitamente pelo usuário agora. Nunca inventa contexto, e nunca cria o item no Azure DevOps sem confirmação explícita do usuário.

Antes do rascunho final, pesquise Bugs existentes por história, cenário, componente, título e comportamento
esperado/obtido. Se houver possível duplicidade, apresente os IDs e pare para decisão humana.

Para economizar tokens, reutilize o relatório de falha e os campos estruturados do ciclo; não recapture
evidências nem releia todos os logs quando o relatório já contiver a fonte.

---

## Pré-requisito bloqueante

1. Se `/arquitetura-analise-falha` rodou nesta conversa para o mesmo ID e o veredito foi `NÃO`, **pare** e informe que a evidência ainda não é suficiente — não gere o defeito mesmo que o usuário peça, a menos que ele forneça agora informação nova que mude o veredito (nesse caso, rode o Step 2 do `/arquitetura-analise-falha` de novo mentalmente antes de prosseguir).
2. Se `/arquitetura-analise-falha` não rodou para este ID nesta conversa, e o usuário não forneceu manualmente contexto/passos/esperado/obtido/evidência suficientes, **não prossiga** — peça essas informações ou sugira rodar `/arquitetura-analise-falha` primeiro.

---

## Bloqueio de defeito baseado em hipótese não confirmada

Não propor a criação de Bug baseado exclusivamente em hipótese não confirmada que dependa de condição artificial no banco, conforme a regra de `./arquitetura-gerar-mapa-testes.md`.

Para esses casos, a análise de falha deve registrar o caminho suportado que produz a condição ou a fonte que confirma a exigência de tratamento, além do veredito `SIM`. Preserve essa informação nas pré-condições do rascunho do Bug.

Uma autorização para preparar massa ou executar a hipótese não equivale à confirmação da regra de negócio.

## Diretriz compartilhada — Aprendizados

Antes do Step 0, siga `./aprendizados/COMO-USAR.md` para consultar contexto histórico relevante. Não use aprendizados para preencher campos ausentes do defeito: esperado, obtido, passos e evidências precisam vir de fontes reais da falha atual. Ao final, registre apenas aprendizados derivados de evidência confirmada.

## Step 0 — Reunir os dados do defeito

A partir do relatório de `/arquitetura-analise-falha` (reaproveitar diretamente) ou do que o usuário forneceu agora, monte:

- **Contexto** — o que estava sendo testado e por quê (história, cenário do mapa de testes).
- **Cenário de origem** — campo estruturado, obrigatório sempre que a falha veio de um cenário publicado num card "Criar Mapa de Teste" (via `/arquitetura-executar-teste`/`/arquitetura-analise-falha`): registre no formato exato `#<N> do mapa de testes #<MAPA_ID>` (mais de um cenário: `#<N1>, #<N2> do mapa de testes #<MAPA_ID>`). Se a falha foi reportada manualmente, sem mapa de testes por trás, escreva `N/A — falha reportada manualmente, sem cenário de mapa associado`. **Não é só documentação**: é esse campo, gravado com esse formato fixo, que o `/arquitetura-executar-teste` (modo de reteste seletivo pós-bug) lê de volta depois para saber quais cenários sempre reincluir ao retestar este Bug — variar a redação quebra a leitura automática.
- **Pré-condições** — estado necessário para reproduzir.
- **Passos para reprodução** — sequência exata, numerada.
- **Resultado esperado** — literal, da regra de negócio/critério de aceite.
- **Resultado atual** — o que de fato aconteceu, com evidência.
- **Impacto** — quem/o que é afetado se isso for para produção sem correção.
- **Severidade sugerida** — Crítica / Alta / Média / Baixa, com uma linha de justificativa. É uma **sugestão**, não uma decisão — o texto do bug deve deixar isso claro (ex.: "Severidade sugerida: Alta — a confirmar com o time").
- **Ambiente** — onde foi observado (ex.: HMG).
- **Versão** — build/commit/PR, se conhecido; senão `Informação não encontrada / necessita validação.`
- **Evidências** — caminho(s) de arquivo local (screenshot) e/ou trecho de evidência de rede (status/headers/corpo), reaproveitados **exatamente como capturados** no relatório de `/arquitetura-executar-teste` (coluna Evidência) ou no que o usuário forneceu. Esta skill nunca recaptura evidência — não abre navegador, não tira screenshot novo. Se não houver caminho de arquivo disponível (ex.: usuário só descreveu o bug em texto), registrar isso e seguir sem anexo (Step 3.5 fica sem o que anexar).

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

Antes da aprovação, informe também que a operação aprovada poderá incluir o vínculo à história e o
upload dos caminhos de evidência listados no rascunho. O PAT corporativo, quando necessário para o
upload, nunca deve ser exibido, gravado ou incluído no relatório.

## Step 2 — Criar o Bug via MCP (só após aprovação)

Chame `mcp__azure-devops__create_work_item` com:
- `projectId`: conforme `$ARGUMENTS`, ou resolvido a partir do projeto da história de origem quando não informado explicitamente
- `workItemType`: `"Bug"`
- `title` = título aprovado (com o prefixo `BUG -`)
- `additionalFields`:
  - `Microsoft.VSTS.TCM.ReproSteps` **sempre** = a estrutura completa em HTML (contexto + cenário de origem + pré-condições + passos + resultado esperado/atual + impacto + severidade sugerida + ambiente + versão + evidências, incluindo a tabela comparativa quando fizer sentido). **Este é o campo padrão para o conteúdo do bug — não o `description`/`System.Description`.**
  - `Microsoft.VSTS.Common.Severity` = severidade sugerida, depois de confirmar a escala de valores suportada pelo projeto

⚠️ **O parágrafo "Cenário de origem" precisa de rótulo fixo no HTML**, exatamente `<p><strong>Cenário de origem:</strong> #21 do mapa de testes #161676</p>` (ajustando os números) — é esse rótulo literal, em negrito, que o `/arquitetura-executar-teste` procura depois via regex para montar o reteste seletivo pós-bug. Não reescrever com sinônimos ("Origem do defeito", "Cenário relacionado" etc.) nem mudar a pontuação do formato `#<N> do mapa de testes #<MAPA_ID>`.

⚠️ **Por que `ReproSteps` e não `Description`:** o template de Bug deste projeto exibe `Microsoft.VSTS.TCM.ReproSteps` como o campo principal do card — `System.Description` existe mas fica pouco visível/pode nem aparecer na tela padrão. Descoberto em 2026-09-21 (US #161109, Bug #161659): o defeito foi criado só com `description` preenchido, a usuária abriu o card e não viu a explicação/passos, porque olhava o card real, onde `ReproSteps` estava vazio. Nunca usar o parâmetro `description` do `create_work_item` como único lugar do conteúdo — ele mapeia para `System.Description`, não para o campo visível no card. Se preferir, pode espelhar o mesmo conteúdo em `description` também (redundância inofensiva), mas `ReproSteps` via `additionalFields` é obrigatório.

Capture o `$BUG_ID` retornado. **Antes de declarar sucesso no Step 4, chame `mcp__azure-devops__get_work_item` no `$BUG_ID` e confirme que `Microsoft.VSTS.TCM.ReproSteps` não está `null`/vazio** — não confie só no eco da chamada de criação.
Antes da criação, confirme também que `Microsoft.VSTS.TCM.ReproSteps` e `Microsoft.VSTS.Common.Severity`
existem e aceitam valores no projeto atual. Se o campo de passos ou a escala de severidade forem
divergentes, pare e adapte o rascunho ao contrato do projeto.

---

## Step 3 — Vincular à história (só após criação, com confirmação separada)

Pergunte se deseja vincular o Bug à história de origem (`$STORY_ID`, se conhecida).

⚠️ **O vínculo correto é filho (Hierarchy), não "Related".** No board do Azure DevOps, o menu de contexto do card da US (⋯ → "Add Bug") cria o Bug como **filho** da história — é esse vínculo que faz o ícone de bug (joaninha) aparecer nos badges do card, ao lado dos badges de Análise/Mapa de Teste (que também são filhos). Um link `Related` cria a relação, mas ela fica invisível na visão compacta do board — o Bug "desaparece" dentro da US para quem só olha o board.

Se o usuário confirmar o vínculo, chame `mcp__azure-devops__wit_work_item_link_write` com `action: "link"`, `project`, e `updates: [{ "id": <BUG_ID>, "linkToId": <STORY_ID>, "type": "parent" }]` — isso cria o Bug como filho da história (equivalente ao "Add Bug" do board). Depois confirme no corpo da resposta que `relations` contém `"rel": "System.LinkTypes.Hierarchy-Reverse"` apontando para a história, com `"name": "Parent"`, antes de reportar sucesso.

Se por engano o Bug tiver sido criado/vinculado como `Related`, corrija: `wit_work_item_link_write` com `action: "unlink"`, `id: <BUG_ID>`, `type: "related"` para remover, e então repita o link acima com `type: "parent"`.

---

## Step 3.5 — Anexar evidências ao Bug (se houver arquivo de evidência)

Se o Step 0 capturou caminho(s) de arquivo local (screenshot(s) do `/arquitetura-executar-teste`), anexe ao Bug recém-criado. **Não existe tool MCP de upload de anexo** (`wit_work_item_attachment` só faz *download*) — use o fluxo corporativo de PAT autorizado pela empresa como fallback. O PAT não pode aparecer no prompt, no log, no relatório ou no histórico do card.

Não pergunte aprovação separada para isto — anexar a evidência que já embasou o Bug aprovado no Step 1 é parte da mesma criação, não uma ação nova.

Para cada arquivo de evidência, em um único bloco PowerShell:

```powershell
$org     = "$AZURE_DEVOPS_ORG"   # resolvido da configuração corporativa; nunca fixar no código
$project = "$PROJECT"   # mesmo valor usado no Step 2
$bugId   = "$BUG_ID"
$filePath = "<caminho local do screenshot, ex.: .playwright-mcp\page-....png>"

# Derive PAT from PERSONAL_ACCESS_TOKEN (fluxo corporativo de anexos autorizado)
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
$patchBody = @(@{ op = "add"; path = "/relations/-"; value = @{ rel = "AttachedFile"; url = $attachment.url; attributes = @{ comment = "Evidencia capturada durante /arquitetura-executar-teste" } } }) | ConvertTo-Json -Depth 5
$patchHeaders = $authHeader + @{ "Content-Type" = "application/json-patch+json" }
Invoke-RestMethod -Uri "https://dev.azure.com/$org/$([Uri]::EscapeDataString($project))/_apis/wit/workitems/$bugId`?api-version=7.1" -Headers $patchHeaders -Method Patch -Body $patchBody | Out-Null
Write-Output "ATTACHED_TO_BUG=$bugId"
```

Repita para cada arquivo de evidência distinto. Se o upload falhar, classifique o resultado como
`Bug criado — evidência não anexada` ou `INCONCLUSIVO — vínculo do anexo não confirmado`. Informe o
arquivo, o motivo e a ação necessária. Se a evidência for obrigatória para reproduzir o defeito, não
declare o Bug como pronto para triagem até que ela esteja no corpo ou anexada ao card.

---

## Step 4 — Confirmar e reportar

```
**Bug criado:** #<BUG_ID>
**Link:** https://dev.azure.com/<org>/<project>/_workitems/edit/<BUG_ID>
**Vinculado à história:** #<STORY_ID> (ou "não vinculado — usuário optou por não vincular agora")
**Evidências anexadas:** <lista de arquivos anexados, ou "nenhuma — motivo">
```

---

## Step 5 — Registrar no log de ações (governança)

Depois de reportar o sucesso, acrescente uma linha ao final da tabela em
`./log/LOG-ACOES.md` (via `Edit`, nunca sobrescrevendo o arquivo):

```
| <data/hora atual, ex.: via `Get-Date -Format "yyyy-MM-dd HH:mm"`> | `/arquitetura-gerar-defeito` | Criação de Bug + vínculo à história | Bug #<BUG_ID> → US #<STORY_ID> | Sucesso | <nome do usuário que aprovou no chat> | — | <resumo de 1 linha do bug + se evidência foi anexada> |
```

Se o Bug foi criado mas o vínculo ou o anexo de evidência falhou (ver Troubleshooting), registre
mesmo assim — com `Resultado` descrevendo o que funcionou e o que não (ex.: "Sucesso parcial —
Bug criado, anexo falhou por falta de PAT"). Nunca pule este passo silenciosamente; se a escrita
no log falhar, avise no relatório ao usuário, mas isso não desfaz a criação do Bug.

---

## Step 6 — Registrar a etapa no ciclo de execução

Depois de montar o relatório final, avalie e registre aprendizados conforme `./aprendizados/COMO-USAR.md`. Em seguida, siga o procedimento de
`./ciclos-execucao/COMO-REGISTRAR.md` com `<etapa>` = `defeito-<BUG_ID>`: grave o `NN-defeito-<BUG_ID>.md` com o
relatório completo, atualize o `README.md` do ciclo da task e o índice `ciclos-execucao\README.md`.
Acrescente o Bug criado (id + link) e o vínculo/anexo na tabela de Artefatos do README do ciclo.
Isso é escrita **local**, além do registro no log de ações. Se a gravação falhar, avise no chat; isso não bloqueia nem desfaz a skill.

---

## Troubleshooting

- Se o usuário pedir para "criar o bug direto" sem ter rodado `/arquitetura-analise-falha` e sem fornecer os campos mínimos (esperado, obtido, passos, evidência), não crie nada — explique o que falta.
- Nunca decidir a severidade final sozinho — sempre apresentar como sugestão e deixar claro que é editável.
- Se `create_work_item` falhar por campo obrigatório do projeto não preenchido (ex.: Area Path, Iteration Path específicos de Bug), preencher com os mesmos valores da história de origem, não com um default genérico.
- Se `$env:PERSONAL_ACCESS_TOKEN` não estiver definido no Step 3.5, não trate como erro bloqueante — o Bug já foi criado e vinculado; apenas informe que a evidência não pôde ser anexada automaticamente por falta do PAT, e que o usuário pode anexar manualmente pela UI do Azure DevOps.
