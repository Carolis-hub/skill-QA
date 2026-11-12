---
name: arquitetura-executar-teste
description: Executa, no fluxo do time de Arquitetura do Share, os cenarios do mapa de testes publicado no card "Criar Mapa de Teste" filho de uma User Story do Azure DevOps, usando os MCPs conectados e o browser real. Valida os pre-requisitos globais e por cenário antes de executar; bloqueia a rodada quando faltar requisito global e bloqueia somente os cenários dependentes quando a falta for específica. Tambem aceita o ID de um Bug ja corrigido para propor e rodar uma lista seletiva de reteste proporcional ao fix.
---

Executar os testes da User Story do Azure DevOps a partir de **$ARGUMENTS**.

Formato esperado: `[ID da User Story OU ID de um Bug] [nome do projeto (opcional)] [ambiente (opcional, default: HMG)]`

Exemplos:
- `157538` → projeto resolvido automaticamente a partir do próprio work item, ambiente HMG. Se houver Bug filho corrigido sem reteste, oferece o Modo B antes do mapa completo (auto-detecção); senão, roda o mapa completo (Modo A)
- `157538 "Nome do Projeto" HMG`
- `161821` → ID de um Bug já corrigido, passado diretamente: propõe lista seletiva de reteste (Modo B) para ele, sem passar pela auto-detecção

Esta é a Skill 4 (QA Test Executor): recebe o **ID de uma User Story** (Modo A, rodada normal — com auto-detecção de Bugs pendentes de reteste) ou o **ID de um Bug já corrigido** (Modo B direto, reteste seletivo pós-bug), localiza o card filho **"Criar Mapa de Teste"** com o mapa já publicado (por `/arquitetura-gerar-mapa-testes`) na Description, executa cada cenário no navegador real e reporta o resultado com evidência — não decide sozinho quando falta base para isso.

Não usamos mais Test Case formal em Test Plan — os mapas de teste vivem sempre no card "Criar Mapa de Teste" anexo à US, e são executados a partir de lá.

Esta versão é a referência da frente **Arquitetura do Share**. Preserve os nomes das variáveis de fluxo e dos MCPs já usados neste arquivo (`$ARGUMENTS`, `$itemId`, `$project`, `$ambiente`, `$MAPA_ITEM`, `$MAPA_ID`, `$STORY_ID`, `$DESCRIPTION_HTML`, `$SCENARIOS`, `$MODO`, `$FIX_FILES` e equivalentes). Não substitua as chamadas MCP por REST, PAT ou acesso alternativo sem orientação explícita do time.

---

## Regra fundamental (guardrails)

**As razões válidas precisam ser classificadas, não misturadas:**
1. **Dados ou informações insuficientes**, mesmo depois de uma tentativa real de destravar (dado de teste ausente, credencial ausente, resultado esperado indefinido/`HIPOTESE`).
2. **Problema de ambiente** (indisponível, instável, sessão que não autentica).
3. **O cenário exige uma ação de alto risco ou escrita sem autorização**, incluindo `DELETE` direto no banco sem a autorização específica prevista nesta skill.
4. **Há indício sem evidência suficiente**, que deve ser `INCONCLUSIVO`, não `PASSOU` nem `FALHOU`.

Dificuldade de execução, volume de trabalho, tempo gasto, "não tentei ainda" ou "não explorei" não
são motivos suficientes por si só. Faça até **duas tentativas seguras e reversíveis**, registre o que foi
tentado e, se ainda não houver caminho, classifique como `BLOQUEADO` ou `INCONCLUSIVO` e peça decisão.

- **Nunca considerar um step aprovado sem evidência comprovada** (snapshot/screenshot + comparação explícita esperado vs. obtido). Se houver indício mas a comprovação não for possível, o resultado é `INCONCLUSIVO — necessita validação humana`, nunca `PASSOU`.
- **Nunca pular um cenário silenciosamente** por não saber executá-lo — reportar explicitamente por que não foi executado, usando só uma das 3 categorias acima.
- **Sinal de alerta — pare e aja, não escreva:** se em algum momento você perceber que está prestes a escrever (ou já escreveu) algo como "não tentei ainda", "não explorei isso", "dava pra testar mas não fiz", "só não fiz por tempo/volume de trabalho" — isso não é uma explicação aceitável para uma linha de relatório. É a instrução de **parar de escrever e ir tentar agora**, no mesmo turno, antes de seguir para qualquer relatório ou pergunta. Esse padrão específico (admitir honestamente que não tentou, e mesmo assim deixar isso virar uma linha de "pendente" à espera de aprovação do usuário) já se repetiu mais de uma vez (US #157198, 2026-09-24; US #161881, 2026-09-25, cenário #13) mesmo depois de corrigido — a honestidade sobre não ter tentado não substitui tentar.
- **Nunca ofereça "pular"/"ignorar" um cenário como opção numa pergunta ao usuário (`AskUserQuestion` ou texto livre) sem antes ter mostrado, na mesma resposta, a tentativa real que você fez** (busca de dado alternativo já realizada e com que resultado, ou a pergunta explícita se há um caminho técnico — ex.: "o dev consegue validar isso na máquina dele, do jeito que resolveu outro cenário parecido?"). Perguntar ao usuário se algo vale a pena só é legítimo **depois** da tentativa; usar a pergunta como atalho para não tentar é a mesma falha disfarçada de outra forma.
- **Nunca executar ação irreversível ou de alto risco sem confirmação explícita do usuário antes daquele step específico** (ex.: excluir, cancelar definitivamente, enviar comunicação real ao cliente, qualquer ação que não tenha volta). Isso não é `NAO EXECUTADO` — é uma pausa para confirmação; depois de confirmado, o step é executado normalmente.
- **Nunca rodar contra ambiente de produção.** Se a URL resolvida para o ambiente informado parecer produção (sem `hom`/`homolog`/`hml`/`dev` no domínio, ou o usuário não confirmar que é ambiente de teste), parar e perguntar antes de navegar.
- **O ambiente de execução funcional é sempre HMG — nunca DEV**, salvo decisão explícita do time de Arquitetura do Share para a história em questão: em HMG os retornos de integrações externas são fidedignos, em DEV não. Esta execução conta como validação funcional; após uma correção, o teste de confirmação deve usar o Modo B desta mesma skill. Se o usuário pedir DEV, avisar da convenção antes de aceitar.
- **Validações em banco são permitidas.** Leituras podem ser feitas sem solicitar autorização: descubra o schema via `information_schema`, localize dados de teste, confirme presença/ausência de registros, compare estados antes/depois e valide históricos. Faça a leitura antes de concluir que um dado ou condição não existe.
- **`INSERT` e `UPDATE` diretos são permitidos somente mediante autorização explícita do usuário que está executando a skill.** Durante a validação dos pré-requisitos, analise o mapa, a análise técnica e os dados do ambiente para identificar antecipadamente todas as escritas necessárias. Solicite a autorização já nessa etapa, informando ambiente, tabela/objeto, operação, finalidade, escopo dos dados, comando ou plano de alteração e impacto esperado. Não peça uma autorização genérica e não execute antes de recebê-la.
- **`DELETE` direto no banco exige autorização explícita do usuário executor antes daquele comando específico.** A solicitação deve informar ambiente não produtivo, tabela/objeto, filtro por identificador da execução, finalidade, quantidade esperada, limpeza/rollback e impacto. Sem autorização, classifique o cenário como `BLOQUEADO`; nunca execute por inferência.
- Se uma necessidade de `INSERT`/`UPDATE` surgir somente durante a execução, pause antes da escrita, apresente a solicitação específica e aguarde autorização explícita. Se a autorização for negada ou não vier, mantenha a execução pausada; não converta isso silenciosamente em `NAO EXECUTADO`.
- **Nunca concluir "não dá pra testar" sem antes explorar e perguntar.** Diante de dado ausente, faça até duas tentativas seguras e registre o resultado. Não faça tentativas de alto risco sem aprovação.
- **Pré-requisitos têm dois níveis:** bloqueios globais impedem toda a rodada; dependências específicas bloqueiam somente os cenários que dependem delas. Não deixe um cenário de banco bloquear um cenário de UI independente, nem o inverso.
- **O resultado da validação deve ser verificável.** Para cada requisito, registre fonte, evidência e status `OK`, `NAO APLICAVEL`, `PENDENTE` ou `INCONCLUSIVO`. "A configuração deve existir", "o serviço deve estar funcionando" ou "o dado deve estar disponível" sem prova no ambiente não é um requisito validado. Para `INSERT`/`UPDATE`, registre também a autorização explícita recebida.

---

## Condições artificiais durante a execução

Não transforme um cenário confirmado em uma execução baseada em estado artificial sem reavaliar sua classificação, conforme a regra de `./arquitetura-gerar-mapa-testes.md`.

Se, durante a execução, for necessário criar por SQL uma condição sem caminho comprovado pela interface ou por outro fluxo suportado, registre o cenário como `HIPOTESE:` e interrompa sua execução automática.

Caso a hipótese seja executada mediante solicitação explícita, registre o resultado como observação investigativa. Uma divergência nessa condição, isoladamente, não comprova defeito do produto. A solicitação de execução não substitui as autorizações específicas de escrita em banco nem os demais gates desta skill.

Preserve no relatório a preparação realizada, o caminho equivalente quando comprovado e a confirmação pendente. Não contabilize uma divergência de hipótese não confirmada como `FALHOU` de cenário funcional; identifique-a como observação investigativa de `HIPOTESE:`.

## Diretriz compartilhada — Aprendizados

Antes do Step 0, siga `./aprendizados/COMO-USAR.md`: inicialize a estrutura, consulte aprendizados relevantes para a história, cenário, componente e ambiente, e registre `$APRENDIZADOS_CONSULTADOS`. Revalide qualquer informação de ambiente, massa ou configuração antes de usá-la. No final, avalie descobertas reutilizáveis sem substituir a evidência atual.

## Step 0 — Validar ambiente

1. Verifique que `mcp__azure-devops` está conectado (chamada de teste em `get_work_item`).
2. Verifique que `mcp__playwright` está conectado (chamada `browser_tabs` com `action: "list"` deve responder sem erro).
3. Se qualquer um dos dois estiver indisponível, pare e reporte qual servidor MCP falta.
4. Preserve e utilize as variáveis de fluxo e os nomes de ferramentas MCP definidos nesta skill. Não invente nomes de ferramentas equivalentes: se a ferramenta esperada não estiver disponível, registre o MCP/ferramenta ausente e pause.
5. **Gate obrigatório de contexto — antes de qualquer navegação no browser:**
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
- Se **nenhum** filho desse tipo existir: pare e reporte que a US não tem mapa de testes publicado — sugerir rodar `/arquitetura-gerar-mapa-testes` antes.
   - Se **mais de um** existir, apresente a lista (ID, título, data de alteração) e pergunte ao usuário qual usar (default: o de `System.ChangedDate` mais recente).
6. Capture do card de mapa de testes (`$MAPA_ITEM`):
   - `$MAPA_ID` (o próprio ID do card `Criar Mapa de Teste`)
   - `$STORY_ID` = `$itemId` (ou o pai do card, se `$itemId` já era o card)
   - `$STORY_TITLE` — título da US (do item pai, se precisar buscar)
   - `$DESCRIPTION_HTML` = `System.Description` do `$MAPA_ITEM` — é aqui que está a tabela de cenários
    - `$MODO = "A"`, `$SCENARIOS_ESCOPO = "completo"` (todo o mapa, filtrado só pela triagem do Step 3)

  ### Gate obrigatório — `/arquitetura-validar-ambiente`

  Antes de parsear os cenários para execução, execute a skill `/arquitetura-validar-ambiente` para o mesmo
  `$ARGUMENTS` e aguarde o relatório `$ENV_VALIDATION_FILE`. Essa etapa é obrigatória tanto no Modo A quanto no
  Modo B e não executa UI, API ou cenário funcional.

  1. Localize `./ciclos-execucao/<task>-US<STORY_ID>/00-validacao-ambiente.md`.
  2. Se o arquivo não existir, estiver com status diferente de `LIBERADO PARA EXECUÇÃO`, ou tiver alguma massa
     `PENDENTE`, `INCONCLUSIVA`, `AUSENTE`, `INCOMPATÍVEL` ou `NÃO VALIDADA`, pare a rodada como `PAUSADA`/`BLOQUEADA`.
  3. Compare a assinatura do relatório com o contexto atual: `$MAPA_ID`, `System.ChangedDate` do mapa, `$ambiente`,
     build/commit, banco/schema e `$MASSA_MANIFEST`. Se qualquer valor divergir ou não puder ser confirmado por
     leitura, rode novamente `/arquitetura-validar-ambiente` antes de prosseguir.
  4. Reconfirme por leitura, usando o MCP de banco correspondente, a presença das massas listadas no manifest. Não
     basta confiar no relatório anterior, em IDs de ciclos antigos ou em uma contagem agregada.
  5. Se a skill de validação solicitar autorização para `INSERT`/`UPDATE`/`DELETE`, aguarde a autorização específica
     e só então prossiga. A autorização para validar massas não autoriza ações de alto risco durante os testes.

  **Não iniciar login, navegação, chamadas da aplicação ou qualquer step funcional antes de o gate estar
  `LIBERADO PARA EXECUÇÃO`.** A ausência de uma massa de um único cenário bloqueia a rodada inteira, conforme o
  contrato da skill de validação.

  Siga para o Step 2 somente após o gate.

### Modo B — Reteste Seletivo Pós-Bug (o `$itemId` é um Bug)

Acionado quando o ID informado é um Bug. Objetivo: em vez de escolher cegamente entre reteste pontual (só o cenário que originou o bug — raso, não pega regressão adjacente) ou mapa completo (caro, desproporcional para um fix isolado), montar uma lista seletiva de cenários do mapa cujo risco de regressão é real dado o que o fix mudou.

`$BUG_ID = $itemId`.

1. Confira `System.State` do Bug (já capturado no passo 1). Se não estiver em um estado equivalente a "corrigido" (`Done`, `Resolved`, ou o que o projeto usar) — avise que o Bug não parece corrigido ainda e pergunte se quer prosseguir mesmo assim (pode ser reteste prematuro, ainda vai falhar). Só continue com confirmação explícita.
2. Extraia `$STORY_ID`: nas `relations` do Bug, procure `rel == "System.LinkTypes.Hierarchy-Reverse"` com `attributes.name == "Parent"`. Se não achar, pare — reporte que o Bug não tem história pai vinculada (inesperado; `/arquitetura-gerar-defeito` sempre cria esse vínculo).
3. Extraia `$MAPA_ID` e `$ORIGIN_SCENARIOS` (um ou mais números) do campo `Microsoft.VSTS.TCM.ReproSteps` do Bug: procure o parágrafo com rótulo fixo `<strong>Cenário de origem:</strong>`, gravado pelo `/arquitetura-gerar-defeito` no formato `#<N> do mapa de testes #<MAPA_ID>` (ou `#<N1>, #<N2> do mapa de testes #<MAPA_ID>` para mais de um cenário).
   - Se o valor for `N/A — falha reportada manualmente...` → não há mapa de testes associado a este Bug; pare e informe que o Modo B não se aplica (não existe mapa para montar lista seletiva) — sugira rodar `/arquitetura-executar-teste` no Modo A (US) se fizer sentido, ou reteste manual.
   - Se o campo estruturado não existir de jeito nenhum (Bug criado antes desta atualização) → tente um fallback livre: procure no texto de "Contexto" algo como `cenário #(\d+)` e `mapa (?:de testes )? ?#(\d+)`. Se ainda assim não achar, **pergunte diretamente à usuária** qual(is) número(s) de cenário e qual card de mapa este Bug se refere — nunca adivinhe.
4. Busque o card do mapa (`$MAPA_ID`, mesmo `get_work_item` de sempre), trate-o como `$MAPA_ITEM` e capture `$DESCRIPTION_HTML` = `System.Description` dele — segue para o Step 2 parsear `$SCENARIOS` exatamente como no Modo A, sem nenhuma lógica de parsing diferente.
5. Nas `relations` do Bug, procure `ArtifactLink` do tipo `"name": "Pull Request"` e/ou `"name": "Fixed in Commit"` — é isso que identifica o fix.
   - **Nenhum encontrado** → pare e pergunte à usuária qual PR/commit corrigiu o bug (link ou número). Se ela não souber informar, ofereça as alternativas: rodar o Modo A (mapa completo) para esta US, ou só o reteste pontual de `$ORIGIN_SCENARIOS` — nunca monte lista seletiva sem saber o que o fix mudou.
   - **Um ou mais encontrados** → use todos (união dos diffs — pode ter havido mais de um commit/PR até corrigir de fato).
6. Para cada PR encontrado, chame `mcp__azure-devops__get_pull_request_changes` e colete a lista de arquivos alterados em `$FIX_FILES`.
7. Monte `$SELECTIVE_SCENARIOS` a partir de `$SCENARIOS` (já parseado no passo 4/Step 2), priorizando correspondência exata entre `$FIX_FILES` e as colunas `Camada`/`Componente` do mapa. Use a categoria apenas como fallback quando esses campos estiverem `NÃO VALIDADO`:
   - Sempre incluir `$ORIGIN_SCENARIOS` (o(s) cenário(s) que geraram o Bug — reconfirma o fix em si).
   - Sempre incluir todos os cenários da categoria `=== REGRESSAO ===` do mapa (existem justamente para pegar efeito colateral).
   - Incluir todos os cenários da(s) mesma(s) categoria(s) do(s) cenário(s) em `$ORIGIN_SCENARIOS` (ex.: se a origem foi `=== CONCORRENCIA ===`, inclui os demais cenários dessa categoria).
8. Apresente ao usuário, **antes de executar qualquer coisa**:
   - A lista seletiva proposta (números + nomes dos cenários, agrupados por categoria).
   - Os arquivos que o fix alterou (`$FIX_FILES`), para ela avaliar se a heurística capturou a área certa.
   - Pergunta explícita: **"Essa lista seletiva cobre o que você espera? Quer adicionar/remover algum cenário, ou prefere rodar o mapa completo (Modo A) dessa vez?"**
   - **Nunca execute nada automaticamente sem essa confirmação** — a heurística por categoria é aproximada por falta de mapeamento cenário↔arquivo de código no mapa hoje, e pode errar por falta ou por excesso (ex.: um fix que altera um método de validação compartilhado por categorias diferentes da origem, como aconteceu de fato na US #157195/Bug #161821, onde a origem era `CONCORRENCIA` mas o risco real estava em `VALIDACOES DE CAMPOS`).
  9. Depois de aprovada (com os ajustes que a usuária pedir), defina `$SCENARIOS` = a lista final aprovada (em vez do mapa inteiro), `$MODO = "B"`, `$SCENARIOS_ESCOPO = "seletivo pós-bug #<BUG_ID>"`, e siga para o Gate obrigatório de `/arquitetura-validar-ambiente` acima. Somente depois de `LIBERADO PARA EXECUÇÃO`, continue no Step 2/Step 3 — todo o resto do fluxo (triagem, execução, evidência, relatório) é idêntico ao Modo A, sem nenhuma lógica nova a partir daqui.

---

## Step 2 — Parsear os cenários da tabela HTML

O `$DESCRIPTION_HTML` contém uma tabela (`<table>...</table>`) sob o cabeçalho "Cenarios de teste". Cada `<tr>` é uma linha:

- **Linha de cabeçalho de coluna** (a primeira, com `#`, `Cenario`, `Acao`, `Resultado Esperado`, `Tipo`, `Tecnica`, `Dimensao`, `Origem`, `Camada`, `Componente`) — ignorar, é só o cabeçalho da tabela.
- **Linha de categoria**: uma única `<td colspan=10>` com texto tipo `=== FLUXO PRINCIPAL ===`, `=== VALIDACOES DE CAMPOS ===` etc. — não é executável, serve só para agrupar visualmente o relatório final.
- **Linha de cenário executável**: 10 `<td>` distintos, na ordem `#`, `Cenario`, `Acao`, `Resultado Esperado`, `Tipo`, `Tecnica`, `Dimensao`, `Origem`, `Camada` e `Componente`. `Camada` e `Componente` devem ser informados quando conhecidos; quando não forem, usar `NÃO VALIDADO`, nunca inventar.

Monte a lista ordenada `$SCENARIOS` (categoria vigente, #, nome do cenário, ação, esperado, tipo, técnica, dimensão, origem, camada, componente). Ação com prefixo `HIPOTESE:` no nome do cenário ou na ação mantém esse literal — é usado na triagem do Step 3.

Ordene a execução priorizando `Dimensao = positivo` / `=== FLUXO PRINCIPAL ===` primeiro, como antes.

---

## Step 2.5 — Validar todos os pré-requisitos do ambiente (gate obrigatório)

Esta etapa é obrigatória para a execução da frente **Arquitetura do Share**. Ela acontece depois de localizar e parsear o mapa, mas antes da triagem final e antes de qualquer cenário. O escopo da validação é o conjunto de cenários em `$SCENARIOS` — mapa completo no Modo A ou lista aprovada no Modo B.

O relatório `00-validacao-ambiente.md` produzido por `/arquitetura-validar-ambiente` é a fonte do gate. Se ele não estiver `LIBERADO PARA EXECUÇÃO`, não iniciar cenários independentes parcialmente. A ausência de MCP de banco, sozinha, não bloqueia: usar o método registrado no relatório (`MCP`, `ADAPTER_LOCAL` ou `EVIDENCIA_MANUAL`). O que bloqueia é não existir método confiável ou não haver evidência suficiente para algum requisito da rodada.

### 2.5.1 — Levantar a matriz de pré-requisitos

Monte `$PREREQUISITOS_EXECUCAO` a partir de:

1. Ação, resultado esperado, dimensão, técnica e origem de cada cenário.
2. Card `Análise` (`Custom.Pontosdeimpacto` e demais campos relevantes) e, quando existir, o relatório de `/arquitetura-analise-tecnica` nesta conversa ou no ciclo da história.
3. PR/commit vinculado, consultado via `mcp__azure-devops__get_pull_request_changes` quando essa informação for necessária.
4. Fonte oficial de variáveis, credenciais e endpoints do ambiente, especialmente `./Variveis de Ambiente/variaveis-de-ambiente-smartshare.example.md` ou cofre autorizado. Nunca exponha senha, token ou connection string no relatório.

Não presuma que um pré-requisito existe apenas porque foi mencionado no mapa. Para cada item, registre: `id`, `cenários dependentes`, `fonte`, `como validar`, `evidência`, `status` e `pendência/ação necessária`.

Quando houver dependência de banco, monte também `$OPERACOES_BANCO` com cada operação prevista (`READ`, `INSERT`, `UPDATE` ou `DELETE`), objetivo, tabela/objeto, escopo e cenário dependente. Para `INSERT`/`UPDATE`/`DELETE`, monte `$AUTORIZACOES_BANCO` e faça a solicitação específica ao usuário nesta etapa, antes de iniciar o cenário dependente.

### 2.5.2 — Validar no ambiente disponibilizado

Valide somente o que for necessário aos cenários em escopo, incluindo:

- **MCPs e ferramentas:** Azure DevOps, Playwright e, se algum cenário exigir banco, um caminho de acesso registrado pela skill de validação (`MCP`, `ADAPTER_LOCAL` ou `EVIDENCIA_MANUAL`). Leitura não exige autorização; se houver `INSERT`/`UPDATE`, valide também que existe caminho autorizado para executá-los. A ausência isolada de um MCP de banco não é bloqueio; a ausência de qualquer método confiável é bloqueio da rodada.
- **Ambiente correto:** ambiente solicitado resolvido para HMG por padrão, URL não produtiva, host acessível e aplicação/revisão da US disponível. Se não for possível comprovar a versão/implantação esperada, pause.
- **Autenticação e autorização:** URL, usuário, senha/segredo, instância, perfil e permissões necessárias. Faça o login de validação com Playwright e confirme dashboard/tela inicial; credencial ausente, inválida ou perfil insuficiente pausa a rodada.
- **Dependências técnicas:** banco, serviços, workers, filas, jobs, integrações externas, feature flags, mocks/stubs, LocalStack e configurações citadas pelo mapa/análise. Para cenários negativos/borda, valide também o mecanismo real de simulação; uma descrição genérica não basta.
- **Dados e massas:** registros, grupos, clientes, permissões, estados anteriores, arquivos de importação e demais massas. Confirme por UI ou consulta read-only; não reutilize dado de execução anterior sem comprovar que ainda existe.
- **Observabilidade e evidência:** snapshots, screenshots, rede quando necessária e diretório de saída acessíveis. Se o cenário exigir evidência que não pode ser coletada, pause.
- **Banco e segurança da rodada:** confirme que o banco pertence ao ambiente não produtivo e que a conexão está correta. Leituras são executadas sem autorização. Para cada `INSERT`/`UPDATE`/`DELETE` necessário, prepare a solicitação específica e obtenha autorização explícita do usuário nesta etapa ou imediatamente antes do comando, informando filtro, quantidade, finalidade e limpeza/rollback. Ações irreversíveis da aplicação continuam exigindo confirmação específica no step correspondente.

Use a tabela:

```text
| ID | Cenários | Pré-requisito | Fonte | Evidência da validação | Status | Pendência/ação |
| PR-01 | #... | ... | ... | ... | OK/PENDENTE/INCONCLUSIVO/NAO APLICAVEL | ... |
```

### 2.5.3 — Regra de pausa

1. Se houver escrita necessária sem autorização explícita, bloqueie a rodada e solicite/registre a decisão antes de prosseguir. Não execute cenários independentes parcialmente enquanto o gate de ambiente estiver incompleto.
2. Se todos os pré-requisitos necessários estiverem `OK` ou `NAO APLICAVEL` e as autorizações de `INSERT`/`UPDATE` necessárias tiverem sido concedidas, prossiga para o Step 3.
3. Se houver `PENDENTE` ou `INCONCLUSIVO` em qualquer requisito necessário, pause a rodada antes do primeiro cenário. A skill de validação deve tentar MCP, adapter local e evidência manual antes de concluir que não há caminho.
4. Informe a matriz, o impacto por cenário e instrução objetiva para cada pendência. Depois das correções, revalide os itens afetados e os globais que possam ter mudado.
5. Registre a situação como `PAUSADA` quando a rodada não iniciar. Este gate não libera execução parcial por cenário.

---

## Step 3 — Triagem human-in-the-loop (antes de executar qualquer coisa)

Só entre neste step se o Step 2.5 estiver aprovado. Para cada cenário em `$SCENARIOS`, classifique antes de tentar executar. A triagem não pode liberar execução quando houver pendência de ambiente ainda não validada.

| Situação | O que fazer |
|---|---|
| Ação marcada `HIPOTESE:` ou resultado esperado contém "VERIFICAR COM DEV/PO" | **Não executar.** Marcar `HIPÓTESE NÃO VALIDADA — necessita decisão humana antes` |
| Ação requer dado que não existe no ambiente (ex.: um grupo específico, um cliente específico) e a ausência não foi resolvida no Step 2.5 | **Bloquear somente os cenários dependentes** e registrar o dado, tentativa de localização e ação necessária. Executar os demais cenários independentes |
| Ação exige um arquivo especial (massa de dados gerada por skill dedicada) como entrada (upload/import) | **Não marcar como dado ausente.** Gerar o arquivo antes de executar — ver "Preparação de massa de dados específica" logo abaixo |
| Ação é irreversível ou de alto risco (excluir, cancelar definitivamente, disparar comunicação real, mexer em dado de produção) | **Parar e perguntar ao usuário antes de executar especificamente esse step**, mesmo que o restante do cenário seja executado automaticamente |
| Credencial necessária não está disponível (arquivo/cofre de credenciais do ambiente, campo ainda `<preencher>` ou instância ausente) | **Pausar toda a execução** e reportar exatamente qual instância/campo falta — nunca tentar adivinhar URL/senha |
| Cenário exige verificação/consulta em banco de dados (consultar tabela, comparar antes/depois, decodificar cookie salvo, conferir schema, achar um dado candidato) | **Usar a leitura durante o Step 2.5 sem solicitar autorização.** Usar o MCP, adapter local ou evidência manual registrados no relatório de validação. Se nenhum método, schema, registro candidato ou consulta necessária puder ser validado, bloquear a rodada inteira. Se a análise indicar `INSERT`/`UPDATE`/`DELETE`, solicitar autorização específica com escopo e limpeza |
| Cenário de dimensão **negativo/borda** depende de simular falha técnica/infraestrutura (erro de integração, timeout, config específica) | **Validar o mecanismo no Step 2.5.** Se feature flag, mock, credencial inválida ou outro mecanismo não puder ser comprovado, pausar toda a rodada antes de executar qualquer cenário |
| Ambiente parece indisponível (erro de DNS, timeout, página de erro genérica ou versão incorreta) | **Parar tudo** e reportar; não tentar adivinhar se o teste "passaria" |
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

### 4.0 — Acompanhamento ao vivo no chat

Nos modos A e B, envie atualizações curtas no chat enquanto executa. A pessoa que acompanha precisa conseguir identificar o cenário e a etapa atual mesmo quando a tela do SmartShare fica parada.

- **Antes da primeira ação de cada cenário**, informe o ID e nome do mapa, a posição na rodada, o ambiente, o que será feito e qual resultado será conferido. Use o mesmo ID nas atualizações seguintes.
- **Ao passar para uma etapa fora da tela**, diga o que vai fazer e o que essa etapa comprova. Exemplos: conferir se a API aceitou a solicitação, acompanhar o processamento no log do worker ou consultar em modo leitura se o registro chegou ao estado esperado. Agrupe ações rápidas em uma atualização.
- **Antes de iniciar uma espera**, informe o último estado confirmado, o que falta observar e a próxima checagem. Se o cenário tiver um prazo de processamento, informe-o. Sempre que a ferramenta permitir, faça checagens espaçadas com esperas de até 60 segundos e publique uma atualização a cada minuto enquanto a espera continuar. Use o tempo decorrido e o último estado verificado. Preserve a frequência de consulta e o prazo definidos pelo cenário ou pelo serviço. Se a chamada só puder rodar de forma bloqueante, informe isso antes de iniciá-la e atualize o chat assim que ela retornar.
- **Antes de seguir para o próximo cenário**, publique o status observado, o resultado obtido e a fonte da evidência. Se houver uma pausa ou impedimento, informe qual etapa foi alcançada e o que falta para retomar. O resultado final segue os critérios de evidência e revisão da rodada.
- Use IDs de teste ou de correlação que possam ser compartilhados. Omita credenciais, tokens, dados pessoais e conteúdo sensível das atualizações.

Exemplo ilustrativo de mensagens durante a execução:

> CT-07 (3 de 12) · HMG · Vou solicitar o processamento e conferir se o worker atualiza o status do registro.
>
> CT-07 · API aceitou a solicitação. Vou acompanhar o worker e consultar o status do registro no banco.
>
> CT-07 · 1 min de espera. O registro ainda está Pendente. Vou consultar novamente em 30 s.
>
> CT-07 · PASSOU · O registro chegou a Processado. A consulta confirmou o status para o ID desta operação.


### 4.1 — Login

Resolva URL/usuário/senha a partir da fonte oficial já validada no Step 2.5 (por exemplo, `./Variveis de Ambiente/variaveis-de-ambiente-smartshare.example.md` ou cofre autorizado) — nunca adivinhe endpoint, usuário ou senha. Se o produto tiver mais de uma instância/canal (ex.: perfis de acesso diferentes), use a instância comprovada na matriz de pré-requisitos. Se o campo relevante estiver ainda como `<preencher>`, a rodada deve permanecer pausada.

Se não houver fonte de credenciais conhecida para o sistema em questão, pergunte a URL e as credenciais antes de prosseguir — não adivinhe endpoint.

1. `mcp__playwright__browser_navigate` para a URL de login.
2. `mcp__playwright__browser_snapshot` para confirmar que a tela carregou.
3. `mcp__playwright__browser_fill_form` com usuário/senha.
4. `mcp__playwright__browser_click` no botão de entrar.
5. `mcp__playwright__browser_snapshot` para confirmar que chegou ao dashboard/tela pós-login. Se aparecer erro de credencial ou a tela de login persistir, **pausar a rodada e reportar** — não é um "step falhou" e nenhum cenário deve continuar.

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
   - `PASSOU` — obtido bate com esperado, com evidência de snapshot/network anexada
   - `FALHOU` — obtido diverge do esperado; capturar `browser_take_screenshot` e, se aplicável, evidência de rede — registrar o texto/estado real encontrado
   - `INCONCLUSIVO` — há indício, mas a evidência não permite concluir
   - `BLOQUEADO` — pré-requisito, autorização ou ação de risco impede a execução
   - `HIPÓTESE NÃO VALIDADA` — regra depende de confirmação humana

   Para todo step `Falhou`, **registrar o caminho local do arquivo de screenshot** retornado por `browser_take_screenshot` (ex.: `.playwright-mcp\page-2026-09-04T18-09-58-660Z.png`) na linha da tabela do Step 5, não só a palavra "screenshot". Esse caminho é o que permite à `/arquitetura-gerar-defeito` anexar a evidência ao Bug depois — sem ele, a evidência visual se perde ao fim da conversa/sessão do navegador.
8. Se a sessão expirar no meio da execução (indício: redirecionado para tela de login), refazer o login (Step 4.1) e **retomar do mesmo step**, registrando no log que houve reautenticação — isso não conta como falha do cenário.

### 4.3 — Operações diretas no banco identificadas durante a execução

- Leituras continuam liberadas sem nova autorização, desde que permaneçam dentro do ambiente validado e do escopo da execução.
- Se surgir uma necessidade de `INSERT`, `UPDATE` ou `DELETE` que não foi identificada no Step 2.5, **pause antes de executar a escrita**. Apresente ao usuário a operação exata, ambiente não produtivo, tabela/objeto, filtro por marcador da execução, finalidade, quantidade esperada, impacto, forma de validação e limpeza/rollback; só retome após autorização explícita.
- `DELETE` direto no banco é permitido somente após autorização específica do usuário executor, dentro de ambiente não produtivo e com filtro que não atinja dados de outras execuções. Sem essas condições, bloqueie o cenário.
- A autorização para `INSERT`/`UPDATE` não autoriza outras operações, outros registros ou outros ambientes. Cada escopo deve estar descrito na solicitação e no log.

Para toda escrita autorizada, registre `$PLANO_LIMPEZA` com os identificadores criados, comando de
restauração, quantidade esperada e verificação pós-limpeza. Ao terminar a execução, aplique a limpeza
autorizada e registre se o ambiente voltou ao estado esperado.

### 4.4 — Ações de alto risco sinalizadas no Step 3

Antes de cada uma, pare e pergunte: **"Confirma execução do step `<id>` (`<ação>`), que foi classificado como irreversível/alto risco?"**. Só prossiga com confirmação explícita para aquele step específico.

---

## Step 4.5 — Double-check independente (sub-agente)

Antes de montar o relatório final (Step 5), valide **cada linha** de `$SCENARIOS` já executado (PASSOU/FALHOU/INCONCLUSIVO/BLOQUEADO) via um sub-agente independente: ferramenta `Agent`, `subagent_type: "general-purpose"` — **nunca `fork`**, para garantir que ele não herda nenhum raciocínio desta execução, só a evidência bruta.

Monte, para cada cenário, um pacote com: # e nome do cenário, componente/camada, Ação, Resultado Esperado,
Resultado Obtido e a classificação dada, caminho(s) de screenshot (se houver) e o resumo de evidência de
rede capturado no Step 4. Passe tudo no prompt do sub-agente pedindo que ele releia cada screenshot indicado
(via `Read`) e a evidência textual fornecida, e retorne, cenário por cenário, **sem re-executar nada e sem
acessar o navegador**. Se não conseguir ler um arquivo, deve retornar `INCONCLUSIVO — evidência não lida`,
nunca `CONFIRMADO`.

- `CONFIRMADO` — a evidência sustenta a classificação dada e foi efetivamente lida, ou
- `DIVERGENTE: <classificação sugerida> — <motivo>` — a evidência não sustenta, ou sustenta uma classificação diferente.

Peça o retorno em formato estruturado (tabela markdown: `# | Veredito | Motivo`).

**Nunca sobrescrever silenciosamente a classificação original com base no double-check.** Cada `DIVERGENTE` vira uma linha na seção "Divergências do double-check" do relatório (Step 5) — classificação original, sugestão do sub-agente, motivo — e fica para a usuária decidir, do mesmo jeito que já acontece com ação de alto risco.

Se o sub-agente falhar (erro de ferramenta, timeout, resposta malformada), isso **não bloqueia** a entrega do relatório principal — registre no relatório que o double-check não pôde ser executado e por quê, e prossiga com o restante do Step 5 normalmente.

---

## Step 5 — Relatório final

```
# Execução — Mapa de Testes #<MAPA_ID> <Título>

**Status:** <CONCLUÍDA | PARCIAL | PAUSADA | INCONCLUSIVA>
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
- PASSOU: N
- PASSOU COM RESSALVA: N
- FALHOU: N
- BLOQUEADO: N
- INCONCLUSIVO: N
- HIPÓTESE NÃO VALIDADA: N
- NÃO APLICÁVEL: N

## Pré-requisitos do ambiente
| ID | Cenários | Pré-requisito | Evidência | Status | Pendência/ação |
|---|---|---|---|---|---|
| PR-01 | #... | ... | ... | OK/NAO APLICAVEL/PENDENTE/INCONCLUSIVO | ... |

Se a execução estiver `PAUSADA`, este relatório deve parar após esta seção e informar que nenhum cenário foi iniciado. Não preencher resultados com estimativas.

## Detalhe por step
| # | Categoria | Ação | Esperado | Obtido | Resultado | Evidência |
|---|---|---|---|---|---|---|

## Steps que pararam por ação de alto risco
...

## Steps não executados (necessitam decisão humana)
- <step>: <motivo>

## Pendências e instruções para retomada

Se restar qualquer cenário não executado ao finalizar a rodada, identifique individualmente:

1. **Qual cenário/step** não foi executado.
2. **Por que** ele não foi executado, com a evidência da tentativa realizada ou do bloqueio confirmado.
3. **O que o usuário precisa corrigir ou providenciar** para liberar o cenário.
4. **Como retomar:** após realizar as correções, o usuário deve executar novamente esta skill usando os mesmos argumentos da rodada (`$ARGUMENTS`), para que os pré-requisitos sejam validados novamente e os cenários pendentes sejam executados.
5. **Condição de liberação:** descreva o sinal objetivo que confirmará que o cenário pode ser executado (por exemplo: credencial válida, registro criado, serviço disponível, autorização de `INSERT`/`UPDATE` concedida ou mecanismo de simulação habilitado).

Não finalize com instruções genéricas como "corrigir e tentar novamente". Se não houver cenários pendentes, informe explicitamente: `Nenhum cenário ficou pendente de execução.`

## Divergências do double-check
| # | Classificação original | Sugestão do sub-agente | Motivo |
|---|---|---|---|
```

Se o Step 4.5 não encontrou nenhuma divergência, escreva `Nenhuma divergência encontrada — double-check confirmou todas as classificações.` no lugar da tabela. Se o double-check não pôde rodar (Step 4.5), escreva isso explicitamente aqui em vez de omitir a seção.

**Se `$MODO == "B"`**, depois de apresentar este relatório no chat, grave também um comentário resumido no próprio Bug (`mcp__azure-devops__update_work_item`, `additionalFields.System.History`), com o marcador fixo `"Reteste (Modo B)"` no início — é esse marcador que a auto-detecção do Modo A (Step 1, passo 4) procura depois para não reoferecer o mesmo Bug de novo:

```
<p><strong>Reteste (Modo B) registrado:</strong> <N> executados, <N> passou, <N> falhou, <N> bloqueado/inconclusivo. Cenários: <lista>. Fix analisado: <PR(s)/commit(s)>.</p>
```

Grave esse comentário **mesmo se algum cenário falhou** (o marcador indica "o Modo B já rodou para este Bug", não "passou limpo") — se algo falhou, a usuária decide o que fazer a partir do relatório, mas não queremos que o Modo A fique reoferecendo o mesmo Bug indefinidamente a cada nova chamada.

Na coluna **Evidência**, para cada `Falhou`: caminho(s) de arquivo real(is) (screenshot local, ex. `.playwright-mcp\page-....png`) e/ou o resumo da evidência de rede (status HTTP, trecho do corpo) — nunca só a palavra "screenshot"/"network" sem o dado concreto. Essas evidências são o insumo que `/arquitetura-analise-falha` referencia e que `/arquitetura-gerar-defeito` anexa ao Bug — preserve os caminhos exatamente como retornados pelas tools, sem retranscrever.

### 5.1 — Salvar e anexar o relatório completo

Depois de concluir o relatório, grave uma cópia completa em Markdown no ciclo de execução:

```text
$EXECUTION_REPORT_FILE = ./ciclos-execucao/<task>-US<story>/NN-execucao-testes.md
```

Apresente ao usuário o caminho do arquivo e o conteúdo/resumo completo para revisão. **Não anexe
automaticamente.** Após aprovação explícita, localize entre os filhos da US principal o card de tipo ou
título exatamente `Teste`:

1. Se houver um único card `Teste`, capture `$TEST_CARD_ID`.
2. Se não houver, informe que o relatório foi salvo localmente e não crie card automaticamente.
3. Se houver mais de um, pare e pergunte qual card deve receber o anexo.
4. Após aprovação, anexe `$EXECUTION_REPORT_FILE` ao card `Teste` usando o MCP de anexos quando existir.
   Se o MCP não oferecer upload, use o PAT corporativo autorizado pela empresa, sem registrar o valor.
5. Releia o card e confirme que o anexo foi associado ao card correto. Registre o resultado como
   `ANEXADO`, `NÃO ANEXADO` ou `INCONCLUSIVO` no relatório, no log e no ciclo.

Essa aprovação é independente da aprovação para executar cenários: executar os testes não autoriza
automaticamente o upload do relatório.

Se houver pelo menos um `Falhou`, finalize perguntando se o usuário quer prosseguir para `/arquitetura-analise-falha` (quando existir) sobre os steps que falharam — não encadear automaticamente.

---

## Step 6 — Registrar no log de ações (governança)

Depois do relatório e da tentativa de anexação do Step 5.1, **sempre** (mesmo quando todos os cenários passaram, ou quando a
execução parou cedo por bloqueio de ambiente/credencial) acrescente uma linha ao final da tabela
em `./log/LOG-ACOES.md` (via `Edit`, nunca sobrescrevendo o arquivo):

```
| <data/hora atual, ex.: via `Get-Date -Format "yyyy-MM-dd HH:mm"`> | `/arquitetura-executar-teste` | Execução de mapa de testes | Card #<MAPA_ID> → US #<STORY_ID> | <Status e contagens> | <nome do usuário> | <rodada/ambiente> | <relatório .md e anexo no card Teste: ANEXADO/NÃO ANEXADO/INCONCLUSIVO> |
```

Se `$MODO == "B"` (reteste seletivo pós-bug), use este formato em vez do padrão acima:

```
| <data/hora atual> | `/arquitetura-executar-teste` | Reteste seletivo pós-bug (Modo B) | Card #<MAPA_ID> → US #<STORY_ID>, Bug #<BUG_ID> | <N> executados: <N> passou, <N> falhou, <N> não executado | <usuário> | <Rodada> | Lista seletiva: cenários #<...> (origem: #<ORIGIN_SCENARIOS>; adicionados pela heurística: #<...>). Fix analisado: <PR(s)/commit(s)>, arquivos: <$FIX_FILES>. <resumo dos achados> |
```

`Rodada` é sempre `1 (funcional, HMG)` quando esta skill roda diretamente. O teste de confirmação pós-Bug também é registrado nesta skill, usando o Modo B e a etapa `reteste-bug-<BUG_ID>`. Se a execução for pausada no gate, registre `PAUSADA` e não a apresente como concluída.

Esta é, na prática, a ação mais importante de registrar entre todas as skills: é a única que
executa contra um ambiente vivo (HMG) e gera dados/evidência reais — mesmo quando não resulta em
Bug (que teria seu próprio registro via `/arquitetura-gerar-defeito`), a execução em si já é uma ação com
efeito no ambiente e deve ficar auditável.

---

## Step 7 — Registrar a etapa no ciclo de execução

Depois de montar o relatório final, avalie e registre aprendizados conforme `./aprendizados/COMO-USAR.md`. Em seguida, siga o procedimento de
`./ciclos-execucao/COMO-REGISTRAR.md` com `<etapa>` = `execucao-testes`: grave o `NN-execucao-testes.md` com o
relatório completo, atualize o `README.md` do ciclo da task e o índice `ciclos-execucao\README.md`.
No Modo B, use `<etapa>` = `reteste-bug-<BUG_ID>`. Inclua o resultado por cenário (passou/falhou/não executado), os caminhos das evidências e os dados criados no ambiente; registre falhas e cenários não executados em Pendências do README do ciclo.
Isso é escrita **local**, além do registro no log de ações. Se a gravação falhar, avise no chat; isso não bloqueia nem desfaz a skill.

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
- Se um pré-requisito global estiver `PENDENTE` ou `INCONCLUSIVO`, não execute a rodada. Se a pendência for específica, execute os cenários independentes e entregue os dependentes como `BLOQUEADO` ou `INCONCLUSIVO`, com a matriz, evidência e ação necessária.
- Não classifique uma indisponibilidade de ambiente, credencial, dependência, massa, versão implantada ou evidência como falha funcional. Use `BLOQUEADO` para impedimento objetivo e `INCONCLUSIVO` quando houver indício sem comprovação.
- **Modo B (reteste pós-bug) — Bug sem campo "Cenário de origem" nem indício de contexto:** não invente o número do cenário nem o card do mapa. Pergunte diretamente à usuária. Bugs criados antes desta atualização do `/arquitetura-gerar-defeito` não terão o campo estruturado — o fallback por regex livre na "Contexto" é best-effort, não garantido.
- **Modo B — mais de um Bug aberto para a mesma US, cada um com fix diferente:** rode o Modo B uma vez por Bug (um ID por vez); não tente consolidar as listas seletivas de Bugs diferentes numa única execução — cada um pode ter tocado áreas diferentes, e misturar dificulta rastrear qual achado motivou qual cenário.
- **Modo B — heurística por categoria pode errar por falta.** Já aconteceu (US #157195/Bug #161821): a origem era categoria `CONCORRENCIA`, mas o fix mexeu num método de validação compartilhado por `VALIDACOES DE CAMPOS` e pelo happy path. É exatamente por isso que o Step 8 do Modo B nunca executa sem mostrar `$FIX_FILES` e pedir confirmação humana antes — não remover essa checagem para "agilizar".
- **Auto-detecção (Modo A, passo 4) depende do marcador `"Reteste (Modo B)"` no comentário do Bug.** Bugs retestados manualmente (sem passar pelo Modo B — ex.: alguém confirmou o fix direto na UI, sem rodar esta skill) não têm esse marcador e continuarão sendo oferecidos como candidato a cada nova chamada do Modo A para a mesma US. Isso não é um erro — é o comportamento esperado na ausência do marcador; se a usuária já confirmou manualmente, ela pode simplesmente responder "ignorar" quando a skill oferecer, ou postar o comentário com o marcador manualmente no Bug via UI.
- **"Não tentei ainda"/"só não fiz por tempo" numa linha de relatório é a mesma falha do 24/09, só disfarçada.** Aconteceu de novo em US #161881 (2026-09-25, cenário #13 "valor já zero não gera registro"): o relatório de pendências dizia literalmente "não tentei ainda — dava pra testar em outra conta... só não fiz por tempo". A usuária corrigiu apontando o print exato. A tentativa (buscar 1-2 contas a mais e conferir o histórico) era trivial e foi feita depois em segundos via leitura no banco. Regra: qualquer frase desse tipo, mesmo em rascunho interno, é o gatilho para tentar na hora — nunca vira uma linha de relatório esperando aprovação pra pular.
- **Auto-detecção não reabre Bugs reabertos.** Se um Bug marcado com `"Reteste (Modo B)"` for reaberto depois (voltou de `Done` para `Active`/`New` porque o fix não era completo), a auto-detecção do Step 1/passo 4 só olha Bugs em estado "corrigido" — um Bug reaberto não aparece como candidato até ser corrigido de novo e voltar pro estado "Done". O marcador antigo no comentário fica obsoleto (refere-se ao fix anterior), mas isso não trava nada: quando o Bug voltar a "Done", ele reaparece como candidato (o filtro é por estado atual, não por ausência total do marcador em qualquer comentário — releia com atenção o texto de cada comentário se houver mais de um antes de decidir se já foi retestado desta vez).
