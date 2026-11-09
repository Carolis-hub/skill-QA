---
description: Executa de fato, via browser (MCP Playwright), os cenarios do mapa de testes publicado no card "Criar Mapa de Teste" filho de uma User Story do Azure DevOps, comparando resultado obtido vs esperado por cenario e parando para intervencao humana nos casos previstos (credencial, dado ausente, ambiente indisponivel, acao irreversivel). Tambem aceita o ID de um Bug ja corrigido para propor e rodar uma lista seletiva de reteste (regressao proporcional ao fix), em vez de reteste pontual raso ou mapa completo caro — e, quando chamada com o ID da propria US, detecta sozinha Bugs filhos corrigidos ainda sem reteste confirmado e oferece rodar esse reteste seletivo antes do mapa completo.
---

Executar os testes da User Story do Azure DevOps a partir de **$ARGUMENTS**.

Formato esperado: `[ID da User Story OU ID de um Bug] [nome do projeto (opcional)] [ambiente (opcional, default: HMG)]`

Exemplos:
- `157538` → projeto resolvido automaticamente a partir do próprio work item, ambiente HMG. Se houver Bug filho corrigido sem reteste, oferece o Modo B antes do mapa completo (auto-detecção); senão, roda o mapa completo (Modo A)
- `157538 "Nome do Projeto" HMG`
- `161821` → ID de um Bug já corrigido, passado diretamente: propõe lista seletiva de reteste (Modo B) para ele, sem passar pela auto-detecção

Esta é a Skill 4 (QA Test Executor): recebe o **ID de uma User Story** (Modo A, rodada normal — com auto-detecção de Bugs pendentes de reteste) ou o **ID de um Bug já corrigido** (Modo B direto, reteste seletivo pós-bug), localiza o card filho **"Criar Mapa de Teste"** com o mapa já publicado (por `/gerar-mapa-testes-v3`) na Description, executa cada cenário no navegador real e reporta Passou/Falhou com evidência — não decide sozinho quando falta base para isso.

Não usamos mais Test Case formal em Test Plan — os mapas de teste vivem sempre no card "Criar Mapa de Teste" anexo à US, e são executados a partir de lá.

---

## Regra fundamental (guardrails)

**As únicas razões válidas para não executar um cenário (`NAO EXECUTADO`) são estas três — nenhuma outra:**
1. **Dados ou informações insuficientes**, mesmo depois de uma tentativa real de destravar (dado de teste ausente, credencial ausente, resultado esperado indefinido/`HIPOTESE`).
2. **Problema de ambiente** (indisponível, instável, sessão que não autentica).
3. **O cenário exige um INSERT/UPDATE/DELETE real no banco de dados** — fora do seu acesso, que é somente leitura.

Dificuldade de execução, volume de trabalho, tempo gasto, "não tentei ainda" ou "não explorei" **não são motivos válidos** — são sinal de que a tentativa ainda não foi feita, e ela deve ser feita agora, no mesmo turno, antes de escrever qualquer relatório ou pergunta ao usuário.

- **Nunca considerar um step aprovado sem evidência comprovada** (snapshot/screenshot + comparação explícita esperado vs. obtido). Se não for possível comprovar, o resultado é `NAO EXECUTADO — necessita validação humana`, nunca `Passou`.
- **Nunca pular um cenário silenciosamente** por não saber executá-lo — reportar explicitamente por que não foi executado, usando só uma das 3 categorias acima.
- **Sinal de alerta — pare e aja, não escreva:** se em algum momento você perceber que está prestes a escrever (ou já escreveu) algo como "não tentei ainda", "não explorei isso", "dava pra testar mas não fiz", "só não fiz por tempo/volume de trabalho" — isso não é uma explicação aceitável para uma linha de relatório. É a instrução de **parar de escrever e ir tentar agora**, no mesmo turno, antes de seguir para qualquer relatório ou pergunta. Esse padrão específico (admitir honestamente que não tentou, e mesmo assim deixar isso virar uma linha de "pendente" à espera de aprovação do usuário) já se repetiu mais de uma vez (US #157198, 2026-09-24; US #161881, 2026-09-25, cenário #13) mesmo depois de corrigido — a honestidade sobre não ter tentado não substitui tentar.
- **Nunca ofereça "pular"/"ignorar" um cenário como opção numa pergunta ao usuário (`AskUserQuestion` ou texto livre) sem antes ter mostrado, na mesma resposta, a tentativa real que você fez** (busca de dado alternativo já realizada e com que resultado, ou a pergunta explícita se há um caminho técnico — ex.: "o dev consegue validar isso na máquina dele, do jeito que resolveu outro cenário parecido?"). Perguntar ao usuário se algo vale a pena só é legítimo **depois** da tentativa; usar a pergunta como atalho para não tentar é a mesma falha disfarçada de outra forma.
- **Nunca executar ação irreversível ou de alto risco sem confirmação explícita do usuário antes daquele step específico** (ex.: excluir, cancelar definitivamente, enviar comunicação real ao cliente, qualquer ação que não tenha volta). Isso não é `NAO EXECUTADO` — é uma pausa para confirmação; depois de confirmado, o step é executado normalmente.
- **Nunca rodar contra ambiente de produção.** Se a URL resolvida para o ambiente informado parecer produção (sem `hom`/`homolog`/`hml`/`dev` no domínio, ou o usuário não confirmar que é ambiente de teste), parar e perguntar antes de navegar.
- **O ambiente de execução funcional é sempre HMG — nunca DEV**, a menos que o time decida o contrário para este produto: em HOM os retornos de integrações externas são fidedignos, em DEV não. Esta execução conta como "Rodada 1" (validação funcional); a "Rodada 2" (homologação oficial, mesmo ambiente HMG) acontece depois, via `/homologar-release`. Se o usuário pedir DEV explicitamente, avisar da convenção antes de aceitar.
- **Leitura no banco é permitida e deve ser tentada antes de desistir de um cenário — nunca escrita.** Se houver acesso de leitura via MCP dedicado (read-only) ao banco do ambiente, use-o ativamente: descubra schema via `information_schema` quando não souber nomes exatos de tabela/coluna, compare valor anterior/posterior de uma alteração, confirme ausência/presença de um registro de histórico, encontre um registro candidato que satisfaça a condição do cenário — muita coisa que antes virava `NAO EXECUTADO` por "não tenho um dado assim" na verdade é uma query de leitura de distância. **Nunca tente `INSERT`/`UPDATE`/`DELETE`** — esse acesso é somente leitura e não há outro acesso de escrita; isso continua sendo motivo válido de `NAO EXECUTADO` (categoria 3 acima), mas só depois de confirmar, por leitura, que uma escrita é de fato necessária (não presuma sem checar o schema/dado real primeiro). Quando a escrita for mesmo necessária, prepare o SQL exato (ou peça ao dev o formato certo) para a usuária ou o time de dev rodar manualmente — nunca adivinhe o formato de uma escrita que pode ter efeito colateral real no ambiente.
- **Nunca concluir "não dá pra testar" sem antes explorar e perguntar.** Diante de dado ausente, falta de acesso técnico (ex.: feature flag) ou um caminho de UI que parece bloqueado, tentar pelo menos uma alternativa óbvia (outra tela, outro botão, dado já existente no ambiente, uma consulta de leitura no banco, perguntar se o dev pode validar localmente) e, se ainda bloqueado, perguntar explicitamente à usuária se existe uma forma de testar — ela costuma ter acesso ou técnica que não foi considerada. Só marcar `NAO EXECUTADO` depois dessa tentativa. **Não se aplica** a cenários `HIPOTESE` (fora de escopo por definição, Step 3) nem a bloqueios já confirmados como definitivos (ambiente fora do ar, credencial de login ausente) — nesses dois casos, parar sem perguntar continua correto.

---

## Step 0 — Validar ambiente

1. Verifique que `mcp__azure-devops` está conectado (chamada de teste em `get_work_item`).
2. Verifique que `mcp__playwright` está conectado (chamada `browser_tabs` com `action: "list"` deve responder sem erro).
3. Se qualquer um dos dois estiver indisponível, pare e reporte qual servidor MCP falta.
4. **Gate obrigatório de contexto — antes de qualquer navegação no browser:**
   - **Memória:** busque na memória (`Grep`/leitura de `MEMORY.md` e dos arquivos apontados por ele) por entradas relacionadas ao produto/domínio da US (ex.: nome do produto, da tela, do fluxo) — não confie só no que já veio auto-carregado no início da sessão; procure ativamente por palavras-chave específicas da US antes de começar a navegar. Isso vale mesmo se você "já lembra" o suficiente pra começar — memória associativa falha silenciosamente, busca ativa não.
   - **KB de produto:** se existir uma base de conhecimento indexada para o produto (ex.: `~/.claude/docs/projetos/<produto>/00-INDICE.md`), carregue-a primeiro e escaneie o índice/atalhos contra as palavras-chave da US (nome da tela, ação, fluxo de negócio). Se algum arquivo bater, leia-o **antes** de tentar navegar pela UI, mesmo que pareça óbvio como chegar lá. Nunca tentar redescobrir por tentativa e erro um caminho de navegação que já pode estar documentado — isso já causou retrabalho repetido no passado.
   - Este gate não substitui a Regra fundamental de "explorar antes de concluir impossível" (abaixo) — é anterior a ela: primeiro checar o que já está documentado, só depois explorar/perguntar se realmente não houver nada.

---

## Step 1 — Detectar modo e localizar o mapa de testes

```
$parts = "$ARGUMENTS".Trim() -split '\s+'
$itemId     = $parts[0]
$project    = if ($parts.Count -gt 1) { $parts[1].Trim('"') } else { $null }
$ambiente   = if ($parts.Count -gt 2) { $parts[2] } else { "HMG" }
```

1. Chame `mcp__azure-devops_wit_get_work_item` com `id`: `$itemId`, `project`: `$project` (se `$null`, omita o parâmetro e deixe o MCP resolver pelo próprio work item), `expand`: `"all"`.
2. Olhe `System.WorkItemType`:
   - **`"Bug"`** → vá para **Modo B — Reteste Seletivo Pós-Bug** (abaixo) e não siga o resto deste Step.
   - **User Story/PBI**, ou `$itemId` já aponta direto para um card `"Criar Mapa de Teste"` → siga o **Modo A** logo abaixo.
   - Qualquer outro tipo (Test Case, etc.) → pare, reporte que o ID informado não é uma User Story/PBI nem um Bug.

### Modo A — Rodada normal (US/PBI)

3. Se `$itemId` já era o próprio card `"Criar Mapa de Teste"`, pule direto para o passo 6 (auto-detecção não se aplica — um card de mapa não tem Bugs filhos, só a US tem).
4. **Auto-detecção de Bug pendente de reteste:** nas `relations` da US, procure filhos (`System.LinkTypes.Hierarchy-Forward`) cujo `System.WorkItemType == "Bug"` e chame `get_work_item` em cada um.
   - Para cada Bug encontrado com `System.State` num estado equivalente a "corrigido" (`Done`, `Resolved`, ou o que o projeto usar — mesmo critério do passo 1 do Modo B), chame `mcp__azure-devops__get_work_item_comments` nele e procure o marcador fixo `"Reteste (Modo B)"` (gravado pelo próprio Modo B ao terminar — ver seu último passo, abaixo) **num comentário cuja data seja igual ou posterior a `Microsoft.VSTS.Common.StateChangeDate` do Bug** (a data da transição mais recente para o estado atual).
     - **Marcador encontrado, posterior à transição atual** → esse Bug já foi retestado para esta correção; ignore, não reoferecer.
     - **Marcador ausente, ou só existe um marcador anterior a `StateChangeDate`** → candidato. O segundo caso cobre Bug reaberto e corrigido de novo: um marcador de um ciclo de correção anterior não vale para o ciclo atual — comparar a data evita reoferecer um reteste já feito, mas também evita **deixar de** oferecer um reteste que o novo fix ainda não recebeu.
   - Se **nenhum candidato** for encontrado, siga direto para o passo 6.
   - Se **um ou mais candidatos** forem encontrados, liste-os (ID, título) e pergunte: **"Encontrei N Bug(s) corrigido(s) nesta US ainda sem reteste confirmado: #<ID> (<título>)... Quer que eu rode o reteste seletivo (Modo B) para ele(s) agora, antes de seguir? Posso rodar só o Modo B, o Modo B seguido do mapa completo, ou ignorar e ir direto pro mapa completo."**
     - Se ela escolher rodar Modo B para um Bug: trate esse Bug como `$itemId`/`$BUG_ID` e execute a seção **Modo B** inteira (abaixo) para ele — é a mesma lógica, só entrando por um caminho diferente. Se houver mais de um candidato aprovado, rode um de cada vez (nunca consolidar dois Bugs numa lista seletiva só — ver Troubleshooting).
     - Depois de cada Modo B concluído (relatório + log + marcador no Bug), pergunte se quer prosseguir também com o mapa completo (Modo A, resto deste Step) nesta mesma invocação, ou encerrar por aqui.
     - Se ela optar por ignorar os candidatos e seguir direto, respeite — não insista.
5. (retomando o Modo A normal, se chegou até aqui) Nas `relations` da US, procure filhos (`System.LinkTypes.Hierarchy-Forward`) e chame `get_work_item` em cada um até achar o(s) de `System.WorkItemType == "Criar Mapa de Teste"`.
   - Se **nenhum** filho desse tipo existir: pare e reporte que a US não tem mapa de testes publicado — sugerir rodar `/gerar-mapa-testes-v3` antes.
   - Se **mais de um** existir, apresente a lista (ID, título, data de alteração) e pergunte ao usuário qual usar (default: o de `System.ChangedDate` mais recente).
6. Capture do card de mapa de testes (`$MAPA_ITEM`):
   - `$MAPA_ID` (o próprio ID do card `Criar Mapa de Teste`)
   - `$STORY_ID` = `$itemId` (ou o pai do card, se `$itemId` já era o card)
   - `$STORY_TITLE` — título da US (do item pai, se precisar buscar)
   - `$DESCRIPTION_HTML` = `System.Description` do `$MAPA_ITEM` — é aqui que está a tabela de cenários
   - `$MODO = "A"`, `$SCENARIOS_ESCOPO = "completo"` (todo o mapa, filtrado só pela triagem do Step 3)

Siga direto para o Step 2.

### Modo B — Reteste Seletivo Pós-Bug (o `$itemId` é um Bug)

Acionado quando o ID informado é um Bug. Objetivo: em vez de escolher cegamente entre reteste pontual (só o cenário que originou o bug — raso, não pega regressão adjacente) ou mapa completo (caro, desproporcional para um fix isolado), montar uma lista seletiva de cenários do mapa cujo risco de regressão é real dado o que o fix mudou.

`$BUG_ID = $itemId`.

1. Confira `System.State` do Bug (já capturado no passo 1). Se não estiver em um estado equivalente a "corrigido" (`Done`, `Resolved`, ou o que o projeto usar) — avise que o Bug não parece corrigido ainda e pergunte se quer prosseguir mesmo assim (pode ser reteste prematuro, ainda vai falhar). Só continue com confirmação explícita.
2. Extraia `$STORY_ID`: nas `relations` do Bug, procure `rel == "System.LinkTypes.Hierarchy-Reverse"` com `attributes.name == "Parent"`. Se não achar, pare — reporte que o Bug não tem história pai vinculada (inesperado; `/gerar-defeito` sempre cria esse vínculo).
3. Extraia `$MAPA_ID` e `$ORIGIN_SCENARIOS` (um ou mais números) do campo `Microsoft.VSTS.TCM.ReproSteps` do Bug: procure o parágrafo com rótulo fixo `<strong>Cenário de origem:</strong>`, gravado pelo `/gerar-defeito` no formato `#<N> do mapa de testes #<MAPA_ID>` (ou `#<N1>, #<N2> do mapa de testes #<MAPA_ID>` para mais de um cenário).
   - Se o valor for `N/A — falha reportada manualmente...` → não há mapa de testes associado a este Bug; pare e informe que o Modo B não se aplica (não existe mapa para montar lista seletiva) — sugira rodar `/executar-teste` no Modo A (US) se fizer sentido, ou reteste manual.
   - Se o campo estruturado não existir de jeito nenhum (Bug criado antes desta atualização) → tente um fallback livre: procure no texto de "Contexto" algo como `cenário #(\d+)` e `mapa (?:de testes )? ?#(\d+)`. Se ainda assim não achar, **pergunte diretamente à usuária** qual(is) número(s) de cenário e qual card de mapa este Bug se refere — nunca adivinhe.
4. Busque o card do mapa (`$MAPA_ID`, mesmo `get_work_item` de sempre), trate-o como `$MAPA_ITEM` e capture `$DESCRIPTION_HTML` = `System.Description` dele — segue para o Step 2 parsear `$SCENARIOS` exatamente como no Modo A, sem nenhuma lógica de parsing diferente.
5. Nas `relations` do Bug, procure `ArtifactLink` do tipo `"name": "Pull Request"` e/ou `"name": "Fixed in Commit"` — é isso que identifica o fix.
   - **Nenhum encontrado** → pare e pergunte à usuária qual PR/commit corrigiu o bug (link ou número). Se ela não souber informar, ofereça as alternativas: rodar o Modo A (mapa completo) para esta US, ou só o reteste pontual de `$ORIGIN_SCENARIOS` — nunca monte lista seletiva sem saber o que o fix mudou.
   - **Um ou mais encontrados** → use todos (união dos diffs — pode ter havido mais de um commit/PR até corrigir de fato).
6. Para cada PR encontrado, chame `mcp__azure-devops__get_pull_request_changes` e colete a lista de arquivos alterados em `$FIX_FILES`.
7. Monte `$SELECTIVE_SCENARIOS` a partir de `$SCENARIOS` (já parseado no passo 4/Step 2), por esta heurística — **v1, deliberadamente aproximada**: o mapa de testes hoje não tem uma coluna de componente/camada por cenário, então o cruzamento com `$FIX_FILES` não é exato, é por categoria:
   - Sempre incluir `$ORIGIN_SCENARIOS` (o(s) cenário(s) que geraram o Bug — reconfirma o fix em si).
   - Sempre incluir todos os cenários da categoria `=== REGRESSAO ===` do mapa (existem justamente para pegar efeito colateral).
   - Incluir todos os cenários da(s) mesma(s) categoria(s) do(s) cenário(s) em `$ORIGIN_SCENARIOS` (ex.: se a origem foi `=== CONCORRENCIA ===`, inclui os demais cenários dessa categoria).
8. Apresente ao usuário, **antes de executar qualquer coisa**:
   - A lista seletiva proposta (números + nomes dos cenários, agrupados por categoria).
   - Os arquivos que o fix alterou (`$FIX_FILES`), para ela avaliar se a heurística capturou a área certa.
   - Pergunta explícita: **"Essa lista seletiva cobre o que você espera? Quer adicionar/remover algum cenário, ou prefere rodar o mapa completo (Modo A) dessa vez?"**
   - **Nunca execute nada automaticamente sem essa confirmação** — a heurística por categoria é aproximada por falta de mapeamento cenário↔arquivo de código no mapa hoje, e pode errar por falta ou por excesso (ex.: um fix que altera um método de validação compartilhado por categorias diferentes da origem, como aconteceu de fato na US #157195/Bug #161821, onde a origem era `CONCORRENCIA` mas o risco real estava em `VALIDACOES DE CAMPOS`).
9. Depois de aprovada (com os ajustes que a usuária pedir), defina `$SCENARIOS` = a lista final aprovada (em vez do mapa inteiro), `$MODO = "B"`, `$SCENARIOS_ESCOPO = "seletivo pós-bug #<BUG_ID>"`, e siga para o Step 3 (triagem) — todo o resto do fluxo (triagem, execução, evidência, relatório) é idêntico ao Modo A, sem nenhuma lógica nova a partir daqui.

---

## Step 2 — Parsear os cenários da tabela HTML

O `$DESCRIPTION_HTML` contém uma tabela (`<table>...</table>`) sob o cabeçalho "Cenarios de teste". Cada `<tr>` é uma linha:

- **Linha de cabeçalho de coluna** (a primeira, com `#`, `Cenario`, `Acao`, `Resultado Esperado`, `Tipo`, `Tecnica`, `Dimensao`, `Origem`) — ignorar, é só o cabeçalho da tabela.
- **Linha de categoria**: uma única `<td colspan=8>` com texto tipo `=== FLUXO PRINCIPAL ===`, `=== VALIDACOES DE CAMPOS ===` etc. — não é executável, serve só para agrupar visualmente o relatório final.
- **Linha de cenário executável**: 8 `<td>` distintos, na ordem `#`, `Cenario` (nome curto), `Acao`, `Resultado Esperado`, `Tipo` (positivo/negativo/borda), `Tecnica` (particao-equivalencia/tabela-decisao/valor-limite/exploratorio), `Dimensao` (positivo/negativo/permissao/dados/concorrencia/regressao), `Origem` (historia/analise tecnica/hipotese).

Monte a lista ordenada `$SCENARIOS` (categoria vigente, #, nome do cenário, ação, esperado, tipo, técnica, dimensão, origem). Ação com prefixo `HIPOTESE:` no nome do cenário ou na ação mantém esse literal — é usado na triagem do Step 3.

Ordene a execução priorizando `Dimensao = positivo` / `=== FLUXO PRINCIPAL ===` primeiro, como antes.

---

## Step 2.5 — Consultar pré-requisitos técnicos de execução (quando aplicável)

Para cenários de `Dimensao` `negativo`/`borda` que dependam de simular falha técnica ou config de infraestrutura (erro de integração, timeout, feature flag, credencial inválida):

1. Se `/analise-tecnica` já rodou **nesta conversa** para esta história, reaproveite diretamente a seção "Pré-requisitos técnicos de execução de teste" do relatório dela.
2. Senão, busque o card `Análise` (`Custom.Pontosdeimpacto`) e, se houver PR vinculado, `mcp__azure-devops__get_pull_request_changes`, procurando menção a um mecanismo que viabilize simular a falha (feature flag, mock, credencial inválida, LocalStack).

Se encontrar um mecanismo confirmado, use-o ativamente na tentativa antes de desistir do cenário. Se o dev registrou explicitamente que **não** existe mecanismo, ou nada for encontrado, isso **não dispensa** a Regra fundamental (tentar pelo menos um caminho alternativo + perguntar à usuária) — só evita reexplorar às cegas algo que já está documentado como impossível.

Se não for possível obter essa informação (sem PR vinculado, campo vazio, `/analise-tecnica` indisponível), **isso não é bloqueante** — prossiga normalmente sem esse insumo extra, seguindo só a Regra fundamental.

---

## Step 3 — Triagem human-in-the-loop (antes de executar qualquer coisa)

Para cada cenário em `$SCENARIOS`, classifique antes de tentar executar:

| Situação | O que fazer |
|---|---|
| Ação marcada `HIPOTESE:` ou resultado esperado contém "VERIFICAR COM DEV/PO" | **Não executar.** Marcar `NAO EXECUTADO — hipótese não validada, necessita decisão humana antes` |
| Ação requer dado que não existe no ambiente (ex.: um grupo específico, um cliente específico) e você não tem como criá-lo com segurança, ou parece bloqueada por falta de acesso técnico (ex.: feature flag, permissão) | **Antes de marcar como não executado:** tentar pelo menos um caminho alternativo (outra tela/botão, dado já existente no ambiente) e perguntar explicitamente à usuária se existe uma forma de testar (ver Regra fundamental). Só depois dessa tentativa, se ela confirmar que não há caminho, marcar `NAO EXECUTADO — dado de teste ausente` |
| Ação exige um arquivo especial (massa de dados gerada por skill dedicada) como entrada (upload/import) | **Não marcar como dado ausente.** Gerar o arquivo antes de executar — ver "Preparação de massa de dados específica" logo abaixo |
| Ação é irreversível ou de alto risco (excluir, cancelar definitivamente, disparar comunicação real, mexer em dado de produção) | **Parar e perguntar ao usuário antes de executar especificamente esse step**, mesmo que o restante do Test Case seja executado automaticamente |
| Credencial necessária não está disponível (arquivo/cofre de credenciais do ambiente, campo ainda `<preencher>` ou instância ausente) | **Parar tudo** e reportar exatamente qual instância/campo falta — nunca tentar adivinhar URL/senha |
| Cenário exige verificação/consulta em banco de dados (consultar tabela, comparar antes/depois, decodificar cookie salvo, conferir schema, achar um dado candidato) | **Tentar via leitura** com o MCP de banco disponível (read-only) antes de marcar como bloqueado — descubra schema via `information_schema` se não souber os nomes exatos. Só parar se a consulta confirmar que uma **escrita** (INSERT/UPDATE/DELETE) é necessária para o cenário — nesse caso, prepare o SQL exato e peça à usuária ou ao time de dev que rode manualmente (ver Regra fundamental) |
| Cenário de dimensão **negativo/borda** depende de simular falha técnica/infraestrutura (erro de integração, timeout, config específica) | **Consultar o Step 2.5 antes de tentar.** Se houver mecanismo confirmado (feature flag, mock, credencial inválida), usá-lo ativamente. Se não houver — documentado como ausente ou não encontrado — seguir a Regra fundamental (tentar alternativa + perguntar à usuária) antes de marcar `NAO EXECUTADO` |
| Ambiente parece indisponível (erro de DNS, timeout, página de erro genérica ao navegar) | **Parar tudo** e reportar; não tentar adivinhar se o teste "passaria" |
| Nenhuma das situações acima | Executar normalmente (Step 4) |

Apresente essa triagem ao usuário **antes** de começar a executar, como uma lista curta: quantos cenários serão executados automaticamente, quantos precisam de decisão humana antes, e quais (se houver) vão parar por ação de alto risco.

---

## Preparação de massa de dados específica (quando aplicável)

Aplica-se quando algum cenário do mapa exigir um arquivo de formato especial (layout próprio do produto, com estrutura/validações específicas) como entrada de upload/import, e existir uma skill dedicada para gerar esse arquivo.

**Como identificar que se aplica:** título/descrição da US, ou a própria "Ação" do cenário no mapa de testes, mencionam o formato de arquivo esperado ou a necessidade de "importar"/"carregar" um arquivo de massa de dados.

Para cada cenário assim identificado, **antes de tentar executar a ação de upload** (ainda na fase de triagem do Step 3, não durante a execução):

1. **Nunca gere o arquivo manualmente e nunca trate isso como "dado de teste ausente"** — se existir uma skill dedicada para gerar esse tipo de arquivo, chame-a via `Skill` tool, passando os parâmetros que o cenário pedir (quantidade de registros, variações específicas).
2. Se o cenário pedir explicitamente um teste de **nome de arquivo duplicado** (rejeição por duplicidade), gere o arquivo normalmente e depois copie/renomeie para bater com um arquivo já existente — não peça para a skill desativar o sufixo de nome único.
3. Use o caminho de arquivo retornado pela skill como entrada de `mcp__playwright__browser_file_upload` no step correspondente do cenário (Step 4.2).
4. No relatório final (Step 5), registre qual arquivo foi gerado e usado em cada step (nome do arquivo) — é evidência de massa de teste, não só o resultado da ação.

Se não existir skill dedicada para o formato exigido, e você não tiver como gerar o arquivo com segurança, trate como dado de teste ausente (Step 3) — não tente reescrever o formato/layout manualmente aqui.

---

## Step 4 — Executar os cenários elegíveis

### 4.1 — Login

Resolva URL/usuário/senha a partir do arquivo/cofre de credenciais do ambiente (ex.: `~/.claude/secrets/<produto>-ambientes.md`, se existir) — pergunte ao usuário onde estão armazenadas se não souber. Se o produto tiver mais de uma instância/canal (ex.: perfis de acesso diferentes), identifique qual instância o cenário precisa pelo domínio da funcionalidade descrita na US/mapa de testes; se não ficar claro, confirme com a usuária antes de navegar. Se o rótulo de instância/canal/banco escrito no mapa de testes parecer uma inferência (combina conhecimento genérico do produto com um trecho ambíguo da análise técnica, sem citação direta) em vez de um fato confirmado, não seguir cegamente — confirmar com a usuária antes de navegar. Se o campo relevante estiver ainda como `<preencher>`, trate como credencial ausente (Step 3). Nunca hardcode URL/credencial diferente do que está registrado na fonte oficial.

Se não houver fonte de credenciais conhecida para o sistema em questão, pergunte a URL e as credenciais antes de prosseguir — não adivinhe endpoint.

1. `mcp__playwright__browser_navigate` para a URL de login.
2. `mcp__playwright__browser_snapshot` para confirmar que a tela carregou.
3. `mcp__playwright__browser_fill_form` com usuário/senha.
4. `mcp__playwright__browser_click` no botão de entrar.
5. `mcp__playwright__browser_snapshot` para confirmar que chegou ao dashboard/tela pós-login. Se aparecer erro de credencial ou a tela de login persistir, **parar e reportar** — não é um "step falhou", é um bloqueio de ambiente.

### 4.2 — Por cenário executável

Para cada cenário, na ordem:

1. `mcp__playwright__browser_snapshot` (estado antes da ação) — usar para localizar o elemento certo por `ref`, nunca inventar seletor sem antes ter visto o snapshot.
2. Executar a ação descrita, com a ferramenta apropriada:
   - digitar → `browser_type`
   - clicar → `browser_click`
   - preencher formulário com múltiplos campos → `browser_fill_form`
   - selecionar opção → `browser_select_option`
   - esperar algo aparecer/mudar → `browser_wait_for`
3. `mcp__playwright__browser_snapshot` (estado depois da ação) e, se o resultado esperado envolver mensagem visual (toast, modal, texto específico), usar `mcp__playwright__browser_find` para localizar o texto exato esperado.
4. Se o resultado esperado envolver chamada de API (ex.: "sistema não deve gerar título"), usar `mcp__playwright__browser_network_requests` para conferir se a chamada esperada ocorreu (ou não ocorreu).
5. **Sempre que o resultado obtido divergir do esperado, ou o comportamento for ambíguo/inconclusivo pela UI** (erro genérico, tela travada, ação que parece não ter efeito, resposta assíncrona sem feedback claro de conclusão) — antes de classificar como `Falhou`, inspecionar a aba de rede:
   - Chamar `mcp__playwright__browser_network_requests` (com `static: false`) filtrando pela chamada relevante (ex.: o endpoint que a ação deveria acionar) para localizar a requisição.
   - Chamar `mcp__playwright__browser_network_request` com o índice encontrado para capturar o detalhe completo: status HTTP, request headers, response headers, e o corpo da resposta (`part: "response-body"`). Se o corpo indicar mais contexto (ex.: mensagem de erro estruturada, id de operação), registrar isso como evidência.
   - Isso deve ser feito **imediatamente após a ação**, antes de navegar para outra tela — navegar limpa o log de rede da página atual e a evidência se perde.
   - Guardar essa evidência (status, headers relevantes, corpo) junto com o snapshot/screenshot no relatório final — um `Falhou` motivado por comportamento assíncrono/técnico sem essa evidência de rede é considerado incompleto.
6. Comparar **literalmente** o obtido com o esperado do mapa de testes. Não flexibilizar mensagens de erro — se o esperado é um texto exato, o obtido precisa bater exatamente.
7. Classificar:
   - `Passou` — obtido bate com esperado, com evidência de snapshot/network anexada
   - `Falhou` — obtido diverge do esperado; capturar `browser_take_screenshot` e, se aplicável (item 5), a evidência de rede (status/headers/corpo) — registrar o texto/estado real encontrado
   - `NAO EXECUTADO` — já coberto no Step 3

   Para todo step `Falhou`, **registrar o caminho local do arquivo de screenshot** retornado por `browser_take_screenshot` (ex.: `.playwright-mcp\page-2026-09-04T18-09-58-660Z.png`) na linha da tabela do Step 5, não só a palavra "screenshot". Esse caminho é o que permite à `/gerar-defeito` anexar a evidência ao Bug depois — sem ele, a evidência visual se perde ao fim da conversa/sessão do navegador.
8. Se a sessão expirar no meio da execução (indício: redirecionado para tela de login), refazer o login (Step 4.1) e **retomar do mesmo step**, registrando no log que houve reautenticação — isso não conta como falha do cenário.

### 4.3 — Ações de alto risco sinalizadas no Step 3

Antes de cada uma, pare e pergunte: **"Confirma execução do step `<id>` (`<ação>`), que foi classificado como irreversível/alto risco?"**. Só prossiga com confirmação explícita para aquele step específico.

---

## Step 4.5 — Double-check independente (sub-agente)

Antes de montar o relatório final (Step 5), valide **cada linha** de `$SCENARIOS` já executado (Passou/Falhou/NAO EXECUTADO) via um sub-agente independente: ferramenta `Agent`, `subagent_type: "general-purpose"` — **nunca `fork`**, para garantir que ele não herda nenhum raciocínio desta execução, só a evidência bruta.

Monte, para cada cenário, um pacote com: # e nome do cenário, Ação, Resultado Esperado, Resultado Obtido e a classificação dada, caminho(s) de screenshot (se houver) e o resumo de evidência de rede (status/headers/corpo) capturado no Step 4. Passe tudo no prompt do sub-agente pedindo que ele releia cada screenshot indicado (via `Read`) e a evidência textual fornecida, e retorne, cenário por cenário, **sem re-executar nada e sem acessar o navegador**:

- `CONFIRMADO` — a evidência sustenta a classificação dada, ou
- `DIVERGENTE: <classificação sugerida> — <motivo>` — a evidência não sustenta, ou sustenta uma classificação diferente.

Peça o retorno em formato estruturado (tabela markdown: `# | Veredito | Motivo`).

**Nunca sobrescrever silenciosamente a classificação original com base no double-check.** Cada `DIVERGENTE` vira uma linha na seção "Divergências do double-check" do relatório (Step 5) — classificação original, sugestão do sub-agente, motivo — e fica para a usuária decidir, do mesmo jeito que já acontece com ação de alto risco.

Se o sub-agente falhar (erro de ferramenta, timeout, resposta malformada), isso **não bloqueia** a entrega do relatório principal — registre no relatório que o double-check não pôde ser executado e por quê, e prossiga com o restante do Step 5 normalmente.

---

## Step 5 — Relatório final

```
# Execução — Mapa de Testes #<MAPA_ID> <Título>

**Ambiente:** <ambiente> (<URL>)
**História relacionada:** #<STORY_ID> <STORY_TITLE>
```

Se `$MODO == "B"`, acrescente logo abaixo do cabeçalho:

```
**Modo:** Reteste Seletivo Pós-Bug — Bug #<BUG_ID>, fix analisado: <PR(s)/commit(s)>
**Cenários selecionados:** <lista de números, com indicação de quais são origem vs. adicionados pela heurística>
```

```
## Resumo
- Executados: N
- Passou: N
- Falhou: N
- Não executado (necessita humano): N

## Detalhe por step
| # | Categoria | Ação | Esperado | Obtido | Resultado | Evidência |
|---|---|---|---|---|---|---|

## Steps que pararam por ação de alto risco
...

## Steps não executados (necessitam decisão humana)
- <step>: <motivo>

## Divergências do double-check
| # | Classificação original | Sugestão do sub-agente | Motivo |
|---|---|---|---|
```

Se o Step 4.5 não encontrou nenhuma divergência, escreva `Nenhuma divergência encontrada — double-check confirmou todas as classificações.` no lugar da tabela. Se o double-check não pôde rodar (Step 4.5), escreva isso explicitamente aqui em vez de omitir a seção.

**Se `$MODO == "B"`**, depois de apresentar este relatório no chat, grave também um comentário resumido no próprio Bug (`mcp__azure-devops__update_work_item`, `additionalFields.System.History`), com o marcador fixo `"Reteste (Modo B)"` no início — é esse marcador que a auto-detecção do Modo A (Step 1, passo 4) procura depois para não reoferecer o mesmo Bug de novo:

```
<p><strong>Reteste (Modo B) registrado:</strong> <N> executados, <N> passou, <N> falhou, <N> não executado. Cenários: <lista>. Fix analisado: <PR(s)/commit(s)>.</p>
```

Grave esse comentário **mesmo se algum cenário falhou** (o marcador indica "o Modo B já rodou para este Bug", não "passou limpo") — se algo falhou, a usuária decide o que fazer a partir do relatório, mas não queremos que o Modo A fique reoferecendo o mesmo Bug indefinidamente a cada nova chamada.

Na coluna **Evidência**, para cada `Falhou`: caminho(s) de arquivo real(is) (screenshot local, ex. `.playwright-mcp\page-....png`) e/ou o resumo da evidência de rede (status HTTP, trecho do corpo) — nunca só a palavra "screenshot"/"network" sem o dado concreto. Essas evidências são o insumo que `/analise-falha` referencia e que `/gerar-defeito` anexa ao Bug — preserve os caminhos exatamente como retornados pelas tools, sem retranscrever.

Se houver pelo menos um `Falhou`, finalize perguntando se o usuário quer prosseguir para `/analise-falha` (quando existir) sobre os steps que falharam — não encadear automaticamente.

---

## Step 6 — Registrar no log de ações (governança)

Depois do relatório do Step 5, **sempre** (mesmo quando todos os cenários passaram, ou quando a
execução parou cedo por bloqueio de ambiente/credencial) acrescente uma linha ao final da tabela
em `~/.claude/docs/projetos/skills-qa/LOG-ACOES.md` (via `Edit`, nunca sobrescrevendo o arquivo):

```
| <data/hora atual, ex.: via `Get-Date -Format "yyyy-MM-dd HH:mm"`> | `/executar-teste` | Execução de mapa de testes | Card #<MAPA_ID> → US #<STORY_ID> | <N> executados: <N> passou, <N> falhou, <N> não executado | <nome do usuário que rodou/revisou a triagem do Step 3> | 1 (funcional, HOM) | <resumo de 1 linha dos achados, se dados reais foram criados no ambiente (ex.: "3 registros criados em HMG para Grupo Teste 66"), e quantas divergências o double-check (Step 4.5) encontrou (ou "double-check não pôde rodar", se for o caso)> |
```

Se `$MODO == "B"` (reteste seletivo pós-bug), use este formato em vez do padrão acima:

```
| <data/hora atual> | `/executar-teste` | Reteste seletivo pós-bug (Modo B) | Card #<MAPA_ID> → US #<STORY_ID>, Bug #<BUG_ID> | <N> executados: <N> passou, <N> falhou, <N> não executado | <usuário> | <Rodada> | Lista seletiva: cenários #<...> (origem: #<ORIGIN_SCENARIOS>; adicionados pela heurística: #<...>). Fix analisado: <PR(s)/commit(s)>, arquivos: <$FIX_FILES>. <resumo dos achados> |
```

`Rodada` é sempre `1 (funcional, HOM)` quando esta skill roda diretamente (logo após o mapa de testes ou logo após um reteste pós-bug). A `Rodada 2 (homologação oficial)` só é registrada por `/homologar-release`, quando a mesma US entra em um pacote de release — ver `feedback_estrategia_ambiente_testes` na memória.

Esta é, na prática, a ação mais importante de registrar entre todas as skills: é a única que
executa contra um ambiente vivo (HMG) e gera dados/evidência reais — mesmo quando não resulta em
Bug (que teria seu próprio registro via `/gerar-defeito`), a execução em si já é uma ação com
efeito no ambiente e deve ficar auditável.

---

## Fora de escopo (v1)

- Este comando **não** cria Test Run nem atualiza o card "Criar Mapa de Teste" no Azure DevOps — só reporta no chat. Publicar resultado formal de execução fica para uma iteração futura, se for necessário.
- Não lida com CAPTCHA, 2FA ou fluxos de autenticação fora do padrão usuário/senha simples.

---

## Troubleshooting

- **Botões que geram/baixam arquivo (PDF, CSV, Excel) podem derrubar o servidor MCP do Playwright ao clicar**, dependendo da implementação da tela. Se isso já tiver acontecido de forma reproduzível em alguma tela conhecida, antes de clicar num botão desse tipo (nome contém "Gerar", "Download", "Relatório", "Exportar" + resultado é um arquivo), inspecionar o handler via `browser_evaluate` (localizar a função/URL que o botão dispara) e reproduzir a chamada com `fetch()` dentro do próprio `browser_evaluate`/`browser_run_code_unsafe`, sem clicar — isso permite validar o resultado (status, headers, conteúdo) sem passar pelo mecanismo nativo de download/visualização que pode causar a queda.
- **Campos de busca que dependem de eventos de teclado reais (`keyup`) para disparar busca assíncrona** não filtram com `browser_type`/preenchimento direto — preencher o valor de uma vez deixa a lista de opções não filtrada. Usar `browser_press_key` uma tecla de cada vez para digitar o valor de busca, e conferir com `browser_snapshot` que a lista já filtrou antes de selecionar uma opção.
- Se `browser_snapshot` não achar o elemento descrito na ação, não invente um seletor genérico — use `browser_find` com o texto visível ou pare e reporte que o elemento não foi localizado (isso pode ser um indício real de bug de UI, não um erro do comando).
- Se a tabela de cenários do card "Criar Mapa de Teste" não tiver nenhuma linha executável (só cabeçalhos de categoria), pare e reporte — provavelmente é um mapa malformado ou ainda não preenchido.
- Se a US tiver mais de um card "Criar Mapa de Teste" filho, nunca escolher um sozinho sem perguntar — pode haver um mapa antigo/descartado misturado com o vigente.
- Sessão expira em ambientes com esse comportamento conhecido (verifique o tempo de expiração do ambiente específico) — sempre checar se caiu para tela de login antes de marcar um step como falho por "elemento não encontrado".
- Nunca reutilizar dados de teste de execuções anteriores sem antes confirmar que ainda existem no ambiente (grupos, cadastros) — o ambiente de homologação pode ter sido resetado.
- **Modo B (reteste pós-bug) — Bug sem campo "Cenário de origem" nem indício de contexto:** não invente o número do cenário nem o card do mapa. Pergunte diretamente à usuária. Bugs criados antes desta atualização do `/gerar-defeito` não terão o campo estruturado — o fallback por regex livre na "Contexto" é best-effort, não garantido.
- **Modo B — mais de um Bug aberto para a mesma US, cada um com fix diferente:** rode o Modo B uma vez por Bug (um ID por vez); não tente consolidar as listas seletivas de Bugs diferentes numa única execução — cada um pode ter tocado áreas diferentes, e misturar dificulta rastrear qual achado motivou qual cenário.
- **Modo B — heurística por categoria pode errar por falta.** Já aconteceu (US #157195/Bug #161821): a origem era categoria `CONCORRENCIA`, mas o fix mexeu num método de validação compartilhado por `VALIDACOES DE CAMPOS` e pelo happy path. É exatamente por isso que o Step 8 do Modo B nunca executa sem mostrar `$FIX_FILES` e pedir confirmação humana antes — não remover essa checagem para "agilizar".
- **Auto-detecção (Modo A, passo 4) depende do marcador `"Reteste (Modo B)"` no comentário do Bug.** Bugs retestados manualmente (sem passar pelo Modo B — ex.: alguém confirmou o fix direto na UI, sem rodar esta skill) não têm esse marcador e continuarão sendo oferecidos como candidato a cada nova chamada do Modo A para a mesma US. Isso não é um erro — é o comportamento esperado na ausência do marcador; se a usuária já confirmou manualmente, ela pode simplesmente responder "ignorar" quando a skill oferecer, ou postar o comentário com o marcador manualmente no Bug via UI.
- **"Não tentei ainda"/"só não fiz por tempo" numa linha de relatório é a mesma falha do 24/09, só disfarçada.** Aconteceu de novo em US #161881 (2026-09-25, cenário #13 "valor já zero não gera registro"): o relatório de pendências dizia literalmente "não tentei ainda — dava pra testar em outra conta... só não fiz por tempo". A usuária corrigiu apontando o print exato. A tentativa (buscar 1-2 contas a mais e conferir o histórico) era trivial e foi feita depois em segundos via leitura no banco. Regra: qualquer frase desse tipo, mesmo em rascunho interno, é o gatilho para tentar na hora — nunca vira uma linha de relatório esperando aprovação pra pular.
- **Auto-detecção não reabre Bugs reabertos.** Se um Bug marcado com `"Reteste (Modo B)"` for reaberto depois (voltou de `Done` para `Active`/`New` porque o fix não era completo), a auto-detecção do Step 1/passo 4 só olha Bugs em estado "corrigido" — um Bug reaberto não aparece como candidato até ser corrigido de novo e voltar pro estado "Done". O marcador antigo no comentário fica obsoleto (refere-se ao fix anterior), mas isso não trava nada: quando o Bug voltar a "Done", ele reaparece como candidato (o filtro é por estado atual, não por ausência total do marcador em qualquer comentário — releia com atenção o texto de cada comentário se houver mais de um antes de decidir se já foi retestado desta vez).
