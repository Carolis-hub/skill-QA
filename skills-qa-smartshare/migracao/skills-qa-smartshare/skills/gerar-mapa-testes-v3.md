---
version: 1.3
description: Generate a test case map from an Azure DevOps story and publish it directly into the Description field of the "Criar Mapa de Teste" card (child of the story), via MCP only — no Test Plan, no REST, no PAT. v3 — checklist obrigatorio de dimensoes (permissao/dados/concorrencia/regressao), tecnica formal de teste por cenario, historico de defeitos e reaproveitamento de /analise-negocio e /analise-tecnica. Baseado no v2 (encoding-hardened) apenas na parte de analise; a parte de publicacao foi reescrita para nao usar Test Plan.
---

**Versão da skill: 1.3** (2026-11-12) · histórico em `CHANGELOG.md`

Generate a test map from Azure DevOps story arguments **$ARGUMENTS**.

Expected format: `[ID da história] [nome do projeto (opcional)]`

Examples:
- `146157` → projeto resolvido automaticamente a partir do próprio work item
- `146157 "Nome do Projeto"` → projeto explícito

> **Relação com o v2:** o v2 continua sendo o comando validado em produção para o fluxo de Test Plan (login) — não foi alterado. O v3 **não usa mais Test Plan**: o mapa de testes é publicado diretamente na Descrição do card **"Criar Mapa de Teste"**, que é filho da história no board principal. Isso elimina toda a dependência de REST/PAT que o v2 e as versões anteriores do v3 exigiam — a publicação é 100% via MCP.

---

## Regra transversal — Fidelidade à versão legada

Vale para todas as skills. O legado é a referência para descobrir o comportamento existente (a US explícita e as mudanças aprovadas prevalecem). Leia **`C:\skills-qualidade\skills-qa-smartshare\templates\DIRETRIZ_FIDELIDADE_LEGADO.md`** (fonte única; não replique o texto aqui) e aplique-a ao que esta skill faz: não presumir melhoria, investigar divergência legado × migrado e registrar exceção documentada.

## Regra transversal — Dúvidas viram aprendizados

Vale para todas as skills. Pasta: `C:\skills-qualidade\analises-diversas\aprendizados` (regras e formato em `README.md`, lista em `INDICE.md`).

1. **Antes de perguntar à usuária** qualquer dúvida, pendência ou pedido de retorno, ler `INDICE.md`. Se existir aprendizado `Ativo` aplicável à mesma situação (escopo `Geral`, da skill, ou da própria US), aplicar sem perguntar e escrever no relatório `Aplicado APR-NNN`.
2. **Ao perguntar**, depois da resposta e **antes de seguir**, gravar `APR-NNN_<slug>.md` (situação, pergunta, resposta, como aplicar, escopo) e a linha no `INDICE.md`. Resposta vaga ou adiada fica `Pendente`, não vira regra.
3. Nunca gravar segredo (senha, token, chave): registrar só "informado no chat, não gravado".
4. Resposta que contradiz um aprendizado: atualizar, marcar o antigo `Substituído por APR-NNN`.
5. O aprendizado **não dispensa** confirmação de ação irreversível ou de escrita, aprovação de recomendação (`REC-...`) nem os guardrails desta skill: nesses casos a skill pergunta, podendo citar o aprendizado como contexto.

## Encoding Policy (read before executing any step)

Diferente do v2/versões anteriores do v3: **não há mais chamadas REST nem montagem de XML via PowerShell**, então a maior fonte de corrupção de acentuação desaparece. Ainda assim:

1. Toda a construção do HTML do mapa (Step 5) é feita **diretamente como texto** para os parâmetros das chamadas MCP (`description` de `create_work_item`/`update_work_item`) — chamadas MCP (JSON-RPC) aceitam acentuação em português sem problema, então não monte esse HTML dentro de um comando PowerShell inline.
2. Se for necessário rascunhar/revisar o HTML antes de publicar (arquivo grande, muitas categorias), escreva-o primeiro em um arquivo `.html` via `Write` e releia com `Read` — nunca retranscreva um HTML longo manualmente dentro de uma resposta.
3. Qualquer step que ainda precise de PowerShell (ex.: criar o diretório de trabalho) deve evitar digitar texto acentuado como literal inline; use apenas para operações de arquivo (criar pasta, log), nunca para montar o conteúdo do mapa em si.
4. Cada step roda como uma chamada isolada. Log de progresso em `$WORK_DIR\run.log` (ASCII) é opcional nesta versão — recomendado para rastreabilidade, não obrigatório para a correção do resultado.

---

## Step 0 — Validate environment

### 0.1 — Validate arguments

```powershell
$errors = @()
if (-not "$ARGUMENTS".Trim()) {
    $errors += "Arguments are empty. Provide: [wiId] [projeto opcional]"
}
if ($errors.Count -gt 0) {
    Write-Output "VALIDATION_FAILED=1"
    foreach ($e in $errors) { Write-Output "ERROR: $e" }
    exit 1
} else {
    Write-Output "VALIDATION_OK=1"
}
```

Se falhar, **pare imediatamente** e reporte os erros. Não há PAT para validar nesta versão — publicação é 100% via MCP.

### 0.2 — Validate MCP server and required tools

Confirme que `mcp__azure-devops` está conectado e que as ferramentas a seguir estão disponíveis: `get_work_item`, `get_work_items_batch_by_ids` (ou equivalente), `search_work_items`, `update_work_item`, `create_work_item`. Um probe call com `workItemId: 1` retornando `404` é aceitável e confirma que o servidor está vivo. Se o servidor estiver indisponível ou faltar alguma ferramenta, pare e reporte — não tente contornar com REST.

### 0.3 — (Opcional) Working directory para log/rascunho

```powershell
$wiIdForDir = ("$ARGUMENTS".Trim() -split '\s+')[0]
$workDir = Join-Path (Get-Location) ".testmap-v3-$wiIdForDir"
New-Item -ItemType Directory -Path $workDir -Force | Out-Null
Write-Output "WORK_DIR=$workDir"
```

Use apenas para log e, se necessário, um rascunho do HTML antes de publicar (Step 5). Não é mais necessário para XML/JSON de Test Case.

---

## Step 1 — Fetch the story work item via MCP

Chame `mcp__azure-devops__get_work_item` com `workItemId`: $WI_ID, `expand`: `"all"`. Capture:

- `$STORY_TITLE`, `$STORY_DESC`, `$STORY_AC`
- `$STORY_RELATIONS` (para achar filhos no Step 2 e o card `Análise` no Step 3)
- `$STORY_AREA_PATH` (`System.AreaPath`), `$STORY_ITERATION_PATH` (`System.IterationPath`), `$STORY_PROJECT` (`System.TeamProject`) — necessários no Step 6 caso seja preciso criar o card "Criar Mapa de Teste" do zero, para que ele herde o mesmo Area Path/Iteration da história.

Se `$ARGUMENTS` trouxer um nome de projeto explícito, use-o para `$STORY_PROJECT`; caso contrário, use o `System.TeamProject` retornado pelo próprio work item (mais confiável que assumir um projeto fixo).

---

## Step 2 — Localizar ou preparar o card "Criar Mapa de Teste"

Extraia os IDs filhos de `$STORY_RELATIONS` (`rel == "System.LinkTypes.Hierarchy-Forward"`). Busque cada um via `mcp__azure-devops__get_work_item` (ou em lote, se disponível) e filtre pelo `System.WorkItemType` **exatamente igual a** `"Criar Mapa de Teste"`.

- **Nenhum encontrado:** `CARD_EXISTS = false`. O card será criado no Step 6, herdando `parentId = $WI_ID`, `areaPath = $STORY_AREA_PATH`, `iterationPath = $STORY_ITERATION_PATH`, `title = "Mapa de teste"`.
- **Exatamente um encontrado:** `CARD_EXISTS = true`. Capture `$MAPA_CARD_ID`, `$MAPA_CARD_STATE` e o `System.Description` atual (`$MAPA_CARD_DESC`).
  - Se `$MAPA_CARD_DESC` já tiver conteúdo não vazio, marque `MAPA_CARD_HAS_CONTENT = true` — isso dispara um aviso explícito no gate de aprovação do Step 4 (nunca sobrescrever silenciosamente um mapa já preenchido, mesmo que o card esteja em estado "Done").
- **Mais de um encontrado:** **pare e pergunte ao usuário** qual card usar (listando ID, título, estado de cada um), ou se deve criar um novo. Não decida sozinho — isso é ambíguo por definição.

---

## Step 3 — Reaproveitar análises anteriores ou buscar card `Análise`

Idêntico ao comportamento already validado desta skill:

**Antes de buscar qualquer coisa nova:** verifique se `/analise-negocio` e/ou `/analise-tecnica` já rodaram para esta mesma história (`$WI_ID`) nesta conversa.

- **Se `/analise-negocio` já rodou:** reaproveite diretamente do relatório dele: objetivo, comportamentos esperados (contratos verificáveis já no formato "Quando X, o sistema deve Y"), regras explícitas/implícitas, condições e exceções, dependências, ambiguidades e riscos. Não re-derive esses itens do zero a partir de `$STORY_DESC`/`$STORY_AC` — use o relatório, que já passou por um raciocínio mais profundo.
- **Se `/analise-tecnica` já rodou e não retornou bloqueio:** reaproveite especificamente a seção "Casos de teste sugeridos pelo dev" (equivalente a `Custom.CasodeTeste`) e os riscos que rastreiam a `Custom.Pontosdeimpacto` (normalmente citados como tal no relatório) — **não** as demais seções do relatório (Dependências diretas/indiretas, Integrações/Dados potencialmente impactados, Discrepâncias), que são sínteses da narrativa investigativa do dev e não devem, sozinhas, gerar cenário novo (ver item 10 de "O que muda"). Use essas outras seções só como contexto para redigir Ação/Resultado Esperado de um cenário já justificado por Pontos de Impacto/Casos de Teste/Instruções QA/Critérios de Aceite.
- **Se nenhuma das duas rodou ainda nesta conversa:** faça a busca mínima equivalente — extraia IDs filhos de `$STORY_RELATIONS`, busque em lote (`fields`: `["System.WorkItemType", "Custom.Pontosdeimpacto", "Custom.CasodeTeste"]`), e use o item cujo `System.WorkItemType` seja **exatamente** `"Análise"` (nunca `"Analise Review"`, que vem sempre vazio). Capture `$ANALISE_PONTOS` e `$ANALISE_CASOS` (vazio se não encontrado — isso não bloqueia o mapa de testes, só o deixa mais raso, ao contrário de `/analise-tecnica`, que bloqueia).

---

## Step 3.4 — Classificação técnica obrigatória da US (FE / BE / API)

Antes de qualquer cenário, classifique a US. Toda US é classificada antes da criação do mapa.

| Classificação | Responsabilidade |
|---|---|
| FE | Front-end: interface e interação com o usuário. |
| BE | Back-end: regras de negócio, processamento e acesso a dados. |
| API | Endpoints, contratos e integração entre sistemas. |

1. Identifique **todas** as áreas impactadas (título, descrição, CA, análise técnica, PR). Uma US pode ter mais de uma. Não limite os testes a uma área quando houver impacto em outras camadas.
2. Exemplos: alteração de layout/comportamento de botão → FE; regra de aprovação → BE; criar/alterar endpoint → API; funcionalidade nova com tela, regra e comunicação com serviços → FE + BE + API.
3. **Área não contemplada** (ex.: infraestrutura, migração de dados, relatório, integração externa): informe à usuária e **proponha uma nova classificação** com nome e responsabilidade; não force a US nas três.
4. **Sem como identificar com clareza:** assuma **BE + FE** e declare a suposição no relatório.
5. Registre a classificação (e a justificativa curta) em "Dimensões cobertas" e no relatório do Step 7. Ela comanda o restante: Step 3.9 (protótipo) só com FE; Step 3.10 (sem front) só quando **não há FE**; os tipos de teste do Step 4.1b dependem das áreas.

---

## Step 3.5 — Histórico de defeitos

Objetivo: identificar bugs anteriores relacionados à mesma área/funcionalidade, para que cenários que já quebraram antes virem regressão obrigatória no Step 4.

Chame `mcp__azure-devops__search_work_items` filtrando `System.WorkItemType = ["Bug"]` e, quando fizer sentido, `System.AreaPath`, combinando com termos-chave do título/objetivo da história no `searchText`. Capture até ~10 resultados relevantes como `$DEFECT_HISTORY` (ID, título, estado).

Se a busca não retornar nada relacionado, **isso não é bloqueante** — prossiga sem histórico e registre essa limitação explicitamente na seção "Histórico de defeitos considerado" do mapa (Step 5), não apenas silenciosamente. Bugs de módulos/áreas claramente distintas da história atual não contam como histórico relevante — não force uma relação que não existe.

---

## Step 3.7 — (Opcional) Consultar o código via hub

Consulta **somente leitura** ao código dos repositórios do hub SmartShare, apenas para **precisar Ação e Resultado Esperado** de cenários já justificados.

- **Localizar o hub:** variável `SMARTSHARE_HUB`; se ausente, `C:\GIT\smartshare-hub`. Se não existir, **pule sem erro** e siga.
- Use o código para detalhar nomes de campos/telas, mensagens, validações e valores reais. 
- **Regra do Clássico:** ao ler o legado (SmartShare clássico), carregue a skill `analyse-legacy-smartshare` (raiz do workspace) e siga a seção "Como ler o legado" da `DIRETRIZ_FIDELIDADE_LEGADO.md`: host de referência `SmartShareWeb`; busque com `git -C SmartShare grep`, porque a busca comum não enxerga essa pasta; nunca use código comentado como regra. Comandos de leitura do git (`grep`, `log`, `blame`) não violam a regra abaixo.
- **Regra fixa: não alterar nada no hub.** O hub (`SMARTSHARE_HUB` ou `C:\GIT\smartshare-hub`) é somente leitura: nenhum checkout, pull, fetch com alteração de branch, commit, push, edição, criação ou remoção de arquivo, nem execução de build, script ou comando que escreva no diretório.
- **Não crie cenário novo a partir do código.** Cenários só nascem das 4 fontes do Step 4.0; o código apenas refina a redação dos já existentes.

---

## Step 3.8 — Recomendações do Claude (se existirem)

Procure o arquivo `C:\skills-qualidade\pendencias-skills\US <ID>.txt` (gerado pela `/analise-tecnica`, uma linha por par `pendência -> recomendação [Status]`). Se não existir, ou se nenhuma linha tiver recomendação, siga sem erro. Se existir, trate cada recomendação (`REC-<ID>-NN`, com `NN` = número do item na lista) conforme o `[Status]`:

- **Aprovada / Ajustada:** vale como 5ª fonte do Step 4.0, só para a pendência que ela resolve. O cenário derivado (Ação/Resultado Esperado, usando o texto ajustado quando houver) deve trazer, na célula de origem/justificativa, a marca **"Recomendação do Claude (REC-<ID>-NN), aprovada pela usuária em <data>, não definida na US"**.
- **Pendente de aprovação:** **pergunte à usuária antes de gerar o mapa** se aprova, ajusta ou rejeita (nunca presuma). Sem resposta explícita, **não gere cenário com resultado esperado** a partir dela: liste na seção "Fonte técnica" como "REC-<ID>-NN pendente de aprovação (sem cenário)". Esta skill **não altera** o `[Status]` do arquivo; quem registra a decisão é a `/analise-tecnica` (ao receber a resposta da usuária) ou a própria usuária.
- **Rejeitada:** ignore.

Divergência em cenário marcado como recomendação **não vira defeito automaticamente**: antes, confirmar a regra com PM/PO (registrar isso na marca do cenário).

---

## Step 3.9 — Protótipo (Figma) em US de FE (somente leitura)

**Quando roda:** a história é de front-end **e** `$STORY_DESC` ou `$STORY_AC` traz link de protótipo `figma.com/design/...`. É de FE quando o título tem `FE` (ex.: `(FE)`), a descrição se declara de FE/front-end ou o módulo é um front do Share 4. Em dúvida se é FE, pergunte à usuária. Sem link, ou US que não é de FE: **pule sem erro** e registre em "Fonte técnica" `Protótipo não consultado: <motivo>`.

**Procedimento:**
1. Do link, extraia `fileKey` e `node-id` (`14246-2550` → `14246:2550`). Chame `create_session` do conector Figma com a `fileKey` e use o `sessionId` nas demais chamadas.
2. `get_metadata` no nó do link para listar os quadros. A resposta costuma ser grande: salve e liste só os nomes dos quadros (ex.: com `python -I`/`jq`), em vez de lê-la inteira. O metadata **não traz os textos**.
3. Escolha os quadros que mostram o que a US trata: a tela principal, os estados (vazio, busca sem resultado, carregando/scroll, erro), os modais de confirmação e bloqueio e os toasts de sucesso. Ignore os quadros de telas que a US declara fora do escopo.
4. `get_screenshot` de cada quadro escolhido (`maxDimension` suficiente para ler o texto). Baixe o PNG (a URL é de curta duração e não deve ser repassada) para `$CICLOS_DIR\US-<ID>\mapas-teste\prototipo\` e leia a imagem. Transcreva **literalmente**: mensagens, títulos, botões, rótulos de coluna, tooltips, textos de estado vazio e de toast.
5. Compare com a US e registre, em "Fonte técnica", só o que diverge ou que a US não define (ex.: elemento que o protótipo mostra e o CA manda não exibir; valor de coluna que só o protótipo mostra).
6. **Inventário de quadros.** Liste **todos** os quadros e estados do protótipo que a US cobre (tela principal, cada estado: vazio, erro de validação por tipo de campo, duplicidade, edição, confirmação, bloqueio, carregando, toasts, modais) e marque os que a US declara fora do escopo. **Nenhum quadro do escopo pode ficar sem cenário de fidelidade.** Grave o inventário na especificação do item 7.
7. **Especificação de design por quadro.** Para cada quadro do inventário chame `get_design_context` (somente leitura) e extraia, usando o valor padrão que aparece depois da vírgula em cada `var(--...)` do código retornado: textos literais; família, peso, tamanho e altura de linha; cor do texto, do fundo e da borda (hex); padding, gap, largura e altura fixas; largura e cor da borda; raio; sombra; tamanho e nome dos ícones; estados (hover, desabilitado, inativo, erro, foco quando o quadro mostra). Grave em `$CICLOS_DIR\US-<ID>\mapas-teste\prototipo\especificacao_<AAAA-MM-DD>.md`, uma tabela por quadro. É essa especificação que o `/executar-teste` mede contra a tela. O que não puder ser lido do quadro vai para uma lista "não especificado no protótipo" (não vira cenário).

**Regras fixas:**
- O Figma é **somente leitura**: nada é criado, editado ou comentado nele.
- **A US vence o protótipo** só quando a US declara um comportamento ou texto diferente do protótipo (o protótipo pode estar desatualizado nesse ponto): o resultado esperado do cenário segue a US e, se mudar o esperado, pergunte à usuária antes de fechar o mapa. **Mesmo assim a divergência entre protótipo e US é sinalizada**: registre-a em "Fonte técnica" e no relatório da execução como "divergência declarada pela US". Fora disso, **o protótipo é a referência de fidelidade e não admite desvio**.
- **Conector Figma não conectado**, ou arquivo sem acesso (página de login do Figma): **não autentique pelo navegador**. Pule o passo, registre `Protótipo não consultado: conector Figma não conectado` e marque os textos que a US remete ao Figma como `texto do Figma (não verificado)`. Isso não bloqueia o mapa.
- O protótipo vale só para o que o Step 4.0 permite abaixo (6ª fonte); não cria regra de negócio.

---

## Step 3.10 — US de BE: nenhuma dependência de front

**Quando roda:** a classificação do Step 3.4 **não inclui FE** (só BE e/ou API). Sem classificação, é de BE quando o título tem `BE` (ex.: `(BE)`), a descrição se declara de BE/back-end ou o módulo é a API; em dúvida, pergunte à usuária. Se a US inclui FE, pule sem erro: as regras de front deste mapa valem para a parte de FE.

**Regras (valem para o Step 4 inteiro):**
1. **Proibido** cenário que exija tela, formulário, botão, mensagem exibida em tela, tooltip, aviso de saída, navegação, layout, protótipo (Figma) ou o Clássico/Portal/outro front como interface. Nunca gerar a categoria `FIDELIDADE AO PROTOTIPO`.
2. **Como verificar:** pela API (status, payload e mensagem de erro **devolvida**) e pelos dados (o que foi ou não gravado no banco e no log). Ação = chamada HTTP com payload; Resultado Esperado = resposta e estado dos dados. Nunca "abrir a tela", "clicar" ou "ver na listagem".
3. **Consumidores (outros módulos, telas do Clássico, Indexador, Portal etc.):** não testar pela interface deles. Verificar o **contrato de dados** (colunas, tipos, valores não nulos, formato) que eles leem, na resposta da API ou no banco. Ação de consumidor por tela é de outra US.
4. **Indicador devolvido ao FE** (ex.: ambiente tem ou não o módulo X): testar o campo na resposta da API, nunca o que a tela mostra ou esconde.
5. **Pré-requisitos** sem item de tela: permitidos build, usuário/perfil/sessão (token), massa de dados, configuração, acesso de leitura ao banco e cliente HTTP. Proibidos `[AMBIENTE] Clássico acessível`, usuário de uso de tela e dado que só serve a um fluxo de tela.
6. **Critérios de aceite de FE na US** (tela, tooltip, campo ou seta, aviso de saída, rótulo, comportamento de formulário) **não geram cenário**: liste em "Fonte técnica" `Fora do escopo do mapa (FE): CA <n> — <motivo>`. Se um CA só pode ser verificado pela tela, trate do mesmo modo (`verificação depende de FE`).
7. Em "Dimensões cobertas" registre que os itens de FE ficaram fora do mapa por ser US de BE. A coluna Origem segue igual (CA, CT, PI, Bug).

---

## Step 4 — Generate test map table

### 4.0 — Escopo de origem (obrigatório, ler antes de 4.1)

Todo cenário do mapa final precisa rastrear a **pelo menos uma** destas 4 fontes:

1. **Instruções QA da história** (seção "Instruções QA" de `$STORY_DESC`, quando existir).
2. **Critérios de Aceite da história** (`$STORY_AC`).
3. **Pontos de Impacto do dev** (`Custom.Pontosdeimpacto` do card `Análise`, ou a seção do relatório `/analise-tecnica` que rastreia diretamente a esse campo).
4. **Casos de Teste do dev** (`Custom.CasodeTeste` do card `Análise`, ou a seção "Casos de teste sugeridos pelo dev" do relatório `/analise-tecnica`).

**6ª fonte restrita, só quando o Step 3.9 rodou — Protótipo Figma:** serve (a) para redigir, dentro de um cenário já justificado pelas fontes acima, as mensagens, títulos, botões, rótulos e estados **literais** do protótipo e (b) para o **cenário único de paridade visual** do Step 4.4. Elemento que existe só no protótipo, sem Critério de Aceite, Ponto de Impacto ou Caso de Teste que o sustente, **não gera cenário**: vira observação em "Fonte técnica". A US prevalece sobre o protótipo quando divergem (Step 3.9).

**Não é fonte suficiente, sozinha:** a narrativa investigativa da análise técnica (revalidações de infraestrutura, achados de performance em outro repositório/caminho de código, notas de "pontos de atenção" do dev que não viraram item explícito em Pontos de Impacto, discrepâncias entre análise e PR, dependências indiretas). Esse material serve para enriquecer a *Ação*/*Resultado Esperado* de um cenário já justificado pelas 4 fontes acima — nunca para, sozinho, criar um cenário novo. Motivo: mapas que puxavam cenário dessa narrativa vinham ficando difíceis/impossíveis de executar por irem além do que a própria história pede (decisão do time, 2026-09-22, herdada do produto anterior, US #138559).

Se, ao ler a narrativa, você identificar algo que parece um risco real mas não está em nenhuma das 4 fontes, **não vire cenário** — sinalize como observação de 1 linha na seção "Fonte técnica" do mapa (Step 5) e, se for grave, avise a usuária no chat antes de prosseguir, em vez de inflar a tabela.

### 4.1 — Identificar regras condicionais

Antes de gerar a tabela final, liste explicitamente cada **regra condicional** da história — qualquer regra do tipo "X só pode acontecer se Y" (status, permissão, existência de dado, papel de usuário, limite numérico/data). Use como fonte, nesta ordem: (1) Instruções QA da história, (2) Critérios de Aceite (`$STORY_AC`), (3) o relatório de `/analise-negocio` (seção "Comportamentos esperados" e "Condições e exceções", que já deriva das duas anteriores), (4) `Custom.Pontosdeimpacto`/`Custom.CasodeTeste` do dev — nesta ordem de prioridade, e sempre dentro do escopo definido em 4.0.

Para **cada** regra condicional identificada, aplique o checklist obrigatório de dimensões abaixo — não é opcional, e cada dimensão deve gerar pelo menos uma linha na tabela final, mesmo que seja para registrar "N/A":

| Dimensão | O que gerar |
|---|---|
| **Positivo** | Condição satisfeita → comportamento esperado ocorre |
| **Negativo** | Condição não satisfeita — uma linha por valor/estado relevante diferente do exigido (não um único genérico "estado inválido") |
| **Permissão** | Usuário/perfil sem permissão tenta a mesma ação |
| **Dados** | Dado inexistente, nulo ou vazio relevante à regra (ex.: grupo sem membros, documento inexistente) |
| **Concorrência** | Duas execuções simultâneas disputando o mesmo recurso/contador — se genuinamente não aplicável à regra, registrar explicitamente `N/A — <motivo>` em vez de omitir |
| **Regressão** | Fluxo anterior/adjacente que não pode quebrar por causa desta mudança |

### 4.1b — Tipos de teste por área técnica (selecionar, não esgotar)

Para cada área da classificação (Step 3.4), escolha **só os tipos aplicáveis** à funcionalidade, aos riscos e ao impacto da US; não é necessário cobrir todos os tipos em toda US. Registre em "Dimensões cobertas" os tipos escolhidos e os descartados com o motivo. Cada cenário indica o tipo na técnica/categoria.

- **FE:** Funcional (botões, campos, filtros, formulários); Interface (UI); Usabilidade; Responsividade; Acessibilidade; Compatibilidade (navegadores/ambientes); Regressão; Integração (interface × APIs); Visual Regression (diferenças visuais entre versões).
- **BE:** Funcional (regras de negócio); Unitário (métodos/componentes isolados); Integração (serviços, componentes, banco); Banco de dados (consultas, gravações, atualizações, integridade); Regressão; Desempenho; Carga; Estresse; Segurança (autorização, exposição de dados).
- **API:** Funcional de API (endpoints, métodos HTTP); Contrato (requisição/resposta); Integração; Validação de dados (obrigatórios, formatos, tipos); Autenticação; Autorização; Tratamento de erros (códigos HTTP, mensagens); Desempenho; Carga; Segurança; Compatibilidade (não quebrar consumidores existentes).

Desempenho, carga e estresse só entram com critério mensurável (APR-002/APR-011); sem ele, não invente tempo. Tipos que a skill de execução não consegue rodar (ex.: carga, estresse) viram cenário `NAO EXECUTADO` justificado ou ficam fora, conforme a usuária decidir.

### 4.2 — Escolher a técnica formal de teste por cenário

Para cada linha gerada, atribua uma técnica, escolhida pelo tipo de regra que originou o cenário — não é livre-escolha estética:

- **valor-limite** — regra envolve número, data, tamanho ou contagem com limite (ex.: quantidade mínima/máxima, prazo, faixa de parcelas)
- **tabela-decisão** — regra combina duas ou mais condições independentes que juntas determinam o resultado (ex.: combinação de duas condições independentes → ações disponíveis para o usuário)
- **partição-equivalência** — regra separa entradas em classes válidas/inválidas sem envolver limite numérico (ex.: tipo de usuário, tipo de documento)
- **exploratório** — cenário de fluxo, UI ou integração sem uma regra formal aplicável (ex.: navegação, mensagens de erro de integração)

### 4.2b — Definir os pré-requisitos de ambiente por cenário

Para cada linha, preencha a coluna **Pré-requisitos**: o que o **ambiente de teste** precisa ter, configurado ou disponível para que a Ação possa ser executada e o Resultado Esperado possa ser observado. Essa coluna é o contrato de entrada de uma skill posterior que vai inspecionar o ambiente e validar se ele suporta o teste — por isso precisa ser **específica, quantificada e verificável**, nunca genérica.

**Formato (obrigatório):** um ou mais itens `[CATEGORIA] requisito`, separados por `<br>` no HTML (e por `; ` na tabela markdown do chat). Categorias permitidas:

| Categoria | O que declarar | Exemplo |
|---|---|---|
| `[PROCESSO]` | Processo/fluxo/workflow configurado, com as características que o teste exige (nº e tipo de atividades/etapas, regras, SLA) | `[PROCESSO] fluxo configurado com 2 atividades de usuário em sequência` |
| `[USUARIO]` | Usuários/perfis/permissões/papéis necessários, e quantos | `[USUARIO] 2 usuários distintos, um com perfil Aprovador e outro sem permissão de aprovação` |
| `[DADOS]` | Massa de dados/estado prévio de registros | `[DADOS] documento em status Rascunho, sem anexos` |
| `[CONFIG]` | Parâmetros, feature flags, licenças, módulos habilitados | `[CONFIG] feature flag X habilitada` |
| `[INTEGRACAO]` | Serviço/API/sistema externo que precisa estar acessível (ou simulável) | `[INTEGRACAO] serviço de notificação por e-mail acessível` |
| `[AMBIENTE]` | Versão/build, URL, banco, infraestrutura específica | `[AMBIENTE] build com a US #{wiId} implantado` |

Regras:

- **Derivar só do que o cenário realmente exige**, a partir das 4 fontes do Step 4.0 (Instruções QA, Critérios de Aceite, Pontos de Impacto, Casos de Teste do dev). Não listar pré-requisito "por precaução".
- **Quantificar sempre que a regra depende de quantidade** (ex.: "2 atividades de usuário", "grupo com 0 membros", "pelo menos 3 parcelas") — é isso que permite à skill posterior responder sim/não ao olhar o ambiente.
- **Cada item deve ser verificável por observação do ambiente** (consultando configuração, cadastro ou dados). Evite itens vagos como "ambiente configurado" ou "dados válidos".
- Cenário sem exigência específica além de acesso ao sistema: `Nenhum específico`. Não deixar a célula vazia.
- Pré-requisito que você está supondo (não está explícito nas fontes): prefixar o item com `HIPOTESE:` — mesma regra do Step 4.4, nunca inventar sem marcar.
- Requisitos repetidos entre cenários devem usar **exatamente o mesmo texto**, para que a skill posterior consiga consolidá-los e validar cada um uma única vez.

### 4.3 — Categorias fixas (adaptar nomes de domínio, manter a estrutura)

1. `=== FLUXO PRINCIPAL ===`
2. `=== FLUXO ALTERNATIVO ===`
3. `=== VALIDACOES DE CAMPOS ===`
4. `=== PERMISSAO ===`
5. `=== DADOS E CASOS DE BORDA ===`
6. `=== CONCORRENCIA ===` (mesmo que só contenha uma linha `N/A` justificada)
7. `=== ERROS DE INTEGRACAO / API ===`
8. `=== REGRESSAO ===` — alimentada por: (a) `Custom.Pontosdeimpacto` do card `Análise` (arquivos/componentes que o dev listou como alterados — não a lista mais ampla de "dependências indiretas" ou "integrações potencialmente impactadas" que só aparecem na narrativa); (b) `$DEFECT_HISTORY` do Step 3.5 — todo defeito histórico relevante vira pelo menos um cenário de regressão aqui
9. `=== CASOS DE BORDA / HIPOTESES ===` (hipóteses não confirmadas — marcar `HIPOTESE:` e nunca inventar sem marcar)
10. `=== FIDELIDADE AO PROTOTIPO ===` — só em US de FE com protótipo (Step 3.9): **um cenário por quadro/estado do inventário**; nunca um cenário único para a tela inteira.

### 4.4 — Regras de geração

- Não inventar regra além do que está descrito; hipóteses sempre marcadas `HIPOTESE:`.
- Não repetir cenários.
- Todo cenário tem a coluna Pré-requisitos preenchida (Step 4.2b) — `Nenhum específico` quando não houver exigência, nunca vazia.
- Todo cenário rastreia a uma das 4 fontes do Step 4.0 (Instruções QA, Critérios de Aceite, Pontos de Impacto do dev, Casos de Teste do dev) — nunca só à narrativa da análise técnica.
- Considerar: validação de campos, comportamento de UI, consistência de dados, falhas de integração — sempre ancorado numa das 4 fontes acima, não como exploração livre do código/PR.
- **Legado como referência de esperado (diretriz de fidelidade ao legado):** quando a US não define o Resultado Esperado, use o comportamento do legado (código via hub, Step 3.7, e/ou o legado executando), marque o cenário "conforme legado" e inclua cenários de regressão para o que deve ser preservado. A US explícita e a decisão documentada prevalecem. Não trate diferença como melhoria sem requisito.
- **US só BE/API (Step 3.10):** nenhum cenário de tela, UI, protótipo ou Clássico/Portal como interface; só API e dados. Antes de apresentar a tabela, releia cada Ação, Resultado Esperado e Pré-requisito e remova ou reescreva (como chamada de API e conferência de dados) o que citar tela, botão, formulário, listagem, "abrir" ou front.
- **Quando o Step 3.9 consultou o protótipo**, o Resultado Esperado dos cenários de mensagem, modal, toast e estado (vazio, sem resultado, carregando) leva o texto literal lido no Figma, não "texto do Figma". Crie, na categoria `=== FIDELIDADE AO PROTOTIPO ===`, **um cenário por quadro/estado do inventário** (Step 3.9, item 6), todos com técnica `exploratório`, tipo `positivo`, dimensão `regressão` e origem `história + protótipo`, pré-requisitos `[CONFIG] conector Figma conectado ao chat`, `[AMBIENTE]` com a US implantada e `[DADOS]` equivalentes aos do quadro. **Ação (padrão):** abrir o estado do quadro `<nome> (nodeId)` no mesmo tamanho de janela do quadro e comparar, item a item, com a especificação do Step 3.9 (item 7): (a) textos literais; (b) estrutura e elementos (ordem, rótulos, ícones, botões, campos); (c) medidas de design (tipografia, cores, espaçamentos, bordas, raios, tamanhos de controles e ícones); (d) estados e interações que o quadro mostra; (e) prints lado a lado. **Resultado Esperado (padrão):** zero divergência (tolerância apenas de ±1 px por arredondamento); toda divergência registrada com os dois prints e os valores esperado × obtido, e **o cenário só é `Passou` com zero divergência e nenhum aspecto não verificado**. Itens que a US manda ignorar (ex.: botão que o protótipo mostra e o CA manda não exibir) não contam como divergência, mas são citados. É esse conjunto que `/executar-teste` (Step 4.2b) executa por completo.

### 4.5 — Apresentar a tabela e pedir aprovação

Apresente a tabela completa no chat (markdown):

```
| # | Cenário | Pré-requisitos | Ação | Resultado Esperado | Tipo | Técnica | Dimensão | Origem |
|---|---------|----------------|------|--------------------|------|---------|----------|--------|
```

- Pré-requisitos: itens `[PROCESSO]`/`[USUARIO]`/`[DADOS]`/`[CONFIG]`/`[INTEGRACAO]`/`[AMBIENTE]` conforme Step 4.2b, ou `Nenhum específico`
- Tipo: `positivo`, `negativo`, `borda`
- Técnica: `valor-limite`, `tabela-decisão`, `partição-equivalência`, `exploratório`
- Dimensão: `positivo`, `negativo`, `permissão`, `dados`, `concorrência`, `regressão`
- Origem: `história` (Instruções QA ou Critérios de Aceite; quando o texto vem do protótipo, acrescente `+ protótipo`), `análise técnica` (especificamente `Custom.Pontosdeimpacto` ou `Custom.CasodeTeste` — nunca a narrativa investigativa isolada, ver Step 4.0), `histórico de defeitos`, `hipótese`

**STOP HERE. Do NOT proceed to Step 5 until the user explicitly confirms.**

Monte a pergunta de acordo com o resultado do Step 2:

- Se `CARD_EXISTS = false`: **"Aprovar publicação deste mapa? Vou criar o card 'Criar Mapa de Teste' filho da história e publicar o mapa na Descrição dele."**
- Se `CARD_EXISTS = true` e `MAPA_CARD_HAS_CONTENT = false`: **"Aprovar publicação deste mapa no card 'Criar Mapa de Teste' #$MAPA_CARD_ID?"**
- Se `CARD_EXISTS = true` e `MAPA_CARD_HAS_CONTENT = true`: **"O card #$MAPA_CARD_ID já tem conteúdo na Descrição (estado atual: $MAPA_CARD_STATE). Publicar vai SUBSTITUIR esse conteúdo. Confirma a sobrescrita?"** — e aguardar confirmação explícita, nunca assumir.

Se a tabela aprovada tiver pelo menos um cenário `HIPOTESE:`, acrescente à pergunta: **"Também vou postar um comentário na história #$WI_ID listando as N hipóteses em aberto, pedindo confirmação de dev/PO."** — a aprovação do mapa já cobre essa ação, não é preciso um segundo gate.

Aguarde a resposta antes de qualquer chamada de escrita no Azure DevOps.

---

## Step 5 — Montar o HTML do mapa

Construa o HTML diretamente (sem PowerShell, sem intermediário XML) para usar como `description` no Step 6. Estrutura:

```html
<h2>Mapa de Testes - US {wiId}</h2>
<p><strong>{titulo da historia}</strong></p>
<p>Projeto: {projeto} | Sprint: {iteration}</p>

<h3>Objetivo</h3>
<p>{objetivo extraido da analise de negocio ou da historia}</p>

<h3>Fonte tecnica</h3>
<p>{resumo do card Analise / analise tecnica, se houver}</p>

<h3>Criterios de aceite</h3>
<ul>
  <li>{AC 1}</li>
  ...
</ul>

<h3>Historico de defeitos considerado</h3>
<p>{resumo do Step 3.5 — inclusive quando nao encontrou nada relacionado}</p>

<h3>Dimensoes cobertas</h3>
<p>{lista das dimensoes presentes, e quais ficaram N/A com o motivo}</p>

<h3>Pre-requisitos de ambiente (consolidado)</h3>
<ul>
  <li>{item unico no formato [CATEGORIA] requisito} — cenarios: #{ids}</li>
  ...
</ul>

<h3>Cenarios de teste</h3>
<table style="border-collapse:collapse;width:100%;table-layout:fixed;">
<tr style="background:#e6e6e6;font-weight:bold;">
<td style="border:1px solid #999;padding:4px;width:3%;">#</td>
<td style="border:1px solid #999;padding:4px;width:11%;">Cenario</td>
<td style="border:1px solid #999;padding:4px;width:16%;">Pre-requisitos</td>
<td style="border:1px solid #999;padding:4px;width:20%;">Acao</td>
<td style="border:1px solid #999;padding:4px;width:20%;">Resultado Esperado</td>
<td style="border:1px solid #999;padding:4px;width:7%;">Tipo</td>
<td style="border:1px solid #999;padding:4px;width:9%;">Tecnica</td>
<td style="border:1px solid #999;padding:4px;width:7%;">Dimensao</td>
<td style="border:1px solid #999;padding:4px;width:7%;">Origem</td>
</tr>
<tr><td colspan="9" style="background:#d9e8f5;font-weight:bold;border:1px solid #999;padding:4px;">=== {CATEGORIA} ===</td></tr>
<tr>
<td style="border:1px solid #999;padding:4px;">{id}</td>
<td style="border:1px solid #999;padding:4px;">{cenario}</td>
<td style="border:1px solid #999;padding:4px;">{pre-requisitos: [CATEGORIA] item, um por linha separados por &lt;br&gt;; ou Nenhum especifico}</td>
<td style="border:1px solid #999;padding:4px;">{acao}</td>
<td style="border:1px solid #999;padding:4px;">{esperado}</td>
<td style="border:1px solid #999;padding:4px;">{tipo}</td>
<td style="border:1px solid #999;padding:4px;">{tecnica}</td>
<td style="border:1px solid #999;padding:4px;">{dimensao}</td>
<td style="border:1px solid #999;padding:4px;">{origem}</td>
</tr>
```

Regras obrigatórias:

- **Larguras proporcionais fixas** (as do exemplo acima: 3/11/16/20/20/7/9/7/7%) — nunca deixar o Word/ADO distribuir igualmente as colunas. `table-layout:fixed` no `<table>` garante que os `width` sejam respeitados.
- **Uma linha `<tr><td colspan="9">`** por categoria, antes do primeiro cenário daquela categoria — nunca embutir o rótulo da categoria dentro da célula "Cenário" do primeiro item.
- **Pré-requisitos**: um item por linha dentro da célula (separados por `<br>`), sempre no formato `[CATEGORIA] requisito` do Step 4.2b — o prefixo entre colchetes é o que permite à skill posterior parsear. A seção "Pre-requisitos de ambiente (consolidado)" lista cada requisito distinto uma única vez, com os IDs dos cenários que dependem dele.
- Sem estilos herdados do Word (sem `font-family:Aptos`, sem `background:silver`) — usar paleta neutra simples (cabeçalho `#e6e6e6`, separador de categoria `#d9e8f5`) para ficar consistente independente de onde o conteúdo foi originado.
- Texto direto, sem colar de nenhum editor — monte o HTML você mesmo, célula por célula, a partir dos dados já validados no Step 4.

Se a tabela for muito grande e você quiser revisar antes de publicar, salve o HTML em `$WORK_DIR\mapa-preview.html` via `Write` e releia com `Read` antes do Step 6 — mas isso é opcional, não é uma exigência de encoding como era no fluxo antigo baseado em PowerShell.

---

## Step 5b — Gerar o HTML interativo local (modelo)

Executar **depois da aprovação do Step 4.5**, com a mesma tabela aprovada, e **independente do Step 6** (se a publicação falhar, o arquivo local ainda deve ser gravado). Este passo não escreve nada no Azure DevOps.

**Variáveis:** `$CICLOS_DIR` = `C:\skills-qualidade\ciclos-executados`; `$TEMPLATES_DIR` = `C:\skills-qualidade\skills-qa-smartshare\templates`; `$EXEC` = data da execução (`AAAA-MM-DD`).

1. Leia `$TEMPLATES_DIR\mapa-teste-viewer.template.html`. Se não existir, **pule o passo sem erro** e avise no Step 7 que o HTML interativo não foi gerado. O comentário no topo do template descreve cada placeholder e o formato exato das linhas.
2. **Não altere o CSS nem o JS do template.** Substitua apenas os placeholders `{{...}}`:
   - `{{TITULO}}`: `Mapa de Testes — US <ID> — <título curto da história>`; `{{PROJETO}}`, `{{SPRINT}}` e `{{CARD_MAPA_ID}}` do Step 1/2.
   - `{{RESUMO_HTML}}`: parágrafos **Objetivo**, **Fonte técnica**, **Origem (siglas)**, **Histórico de defeitos considerado** e **Dimensões cobertas** (mesmo conteúdo do HTML do Step 5), seguidos de `<h4>Critérios de aceite</h4><ul>…</ul>`.
   - `{{LINHAS_HTML}}`: uma linha `<tr class="group">` por categoria (nomes **com acentos**: `VALIDAÇÕES DE CAMPOS`, `PERMISSÃO`, `CONCORRÊNCIA`, `ERROS DE INTEGRAÇÃO / API`, `REGRESSÃO`, `CASOS DE BORDA / HIPÓTESES`) e uma linha `<tr data-id="N">` por cenário, no formato do template. `{{TOTAL}}` = número de cenários.
   - `{{PREREQ_HTML}}`: o mesmo consolidado do Step 5, em `<li>`.
   - `{{CHAVE_STORAGE}}` = `mapa-teste-us-<ID>-<slug>-testados-v1`; `{{ARQUIVO_EXPORT}}` = `mapa-teste-us-<ID>-<slug>.html` (`<slug>` curto, minúsculo, sem acentos).
3. **Regras de apresentação (as mesmas do modelo de referência):**
   - Coluna **Origem** em siglas: `CA<n>` (Critério de Aceite), `CT` (Casos de Teste do dev), `PI` (Pontos de Impacto do dev), `Bug #<id>` (histórico de defeitos), `+ protótipo` quando o texto literal veio do Figma (Step 3.9). Cenário `HIPOTESE:` leva `HIPOTESE: <siglas>, hipótese` e a linha recebe `class="row-hipotese"` e o selo `<span class="hip-badge">hipótese</span>` antes do nome (sem repetir o prefixo `HIPOTESE:` no texto).
   - Tags: `tag-positivo` / `tag-negativo` em Tipo e Dimensão, `tag-regressao` em Dimensão `regressão`, `tag` simples nos demais.
   - Linha `N/A` (ex.: Concorrência): Configurações = `Nenhum específico`; Ação, Resultado, Tipo e Técnica = `—`.
   - Pré-requisitos no formato `[CATEGORIA] requisito` separados por `<br>`, texto idêntico ao do Step 5. Escape de `&`, `<` e `>` em todo texto de célula.
4. Grave em `$CICLOS_DIR\US-<ID>\mapas-teste\US-<ID>_<$EXEC>_mapa-teste.html` (crie os diretórios se não existirem; **nunca sobrescreva** uma execução anterior: se o nome já existir, acrescente `_HHmm`). Nunca grave em pasta relativa ao diretório de trabalho nem dentro de `skills-qa-smartshare`.
5. Confira antes de reportar: nenhum `{{` restante no arquivo e o número de `<tr data-id` igual ao total de cenários.

---

## Step 6 — Publicar via MCP

- **Se `CARD_EXISTS = false`:** chame `mcp__azure-devops__create_work_item` com `workItemType: "Criar Mapa de Teste"`, `title: "Mapa de teste"`, `description: {HTML do Step 5}`, `parentId: $WI_ID`, `areaPath: $STORY_AREA_PATH`, `iterationPath: $STORY_ITERATION_PATH`, `projectId: $STORY_PROJECT`. Capture o `id` retornado como `$MAPA_CARD_ID`.
- **Se `CARD_EXISTS = true`:** chame `mcp__azure-devops__update_work_item` com `workItemId: $MAPA_CARD_ID`, `description: {HTML do Step 5}`.

**Regra fixa de publicação (2026-11-05, pedido da usuária):** ao publicar o mapa (criação do card ou atualização da Descrição), a skill também (1) muda o `System.State` do card "Criar Mapa de Teste" para **`Committed`** e (2) adiciona a tag **`agenteqa`** em `System.Tags`, **preservando as tags já existentes** (nunca substituir: leia `System.Tags` do card, acrescente `agenteqa` só se ainda não estiver, separando por `; `). Faça isso depois de a Descrição estar gravada, com `mcp__azure-devops__wit_work_item_write` (`action: "update"`, `id: $MAPA_CARD_ID`), usando `/fields/System.State` = `Committed` e `/fields/System.Tags`. Vale também para card que já existia e foi sobrescrito com a confirmação do Step 4.5. Se a mudança de estado ou a tag falhar (ex.: transição inválida), **não é bloqueante**: o mapa já está publicado; reporte o erro exato no Step 7 e avise a usuária. Não altere `assignedTo` nem outros campos além de Descrição, `State` e `Tags`; mover o card para "Done" continua sendo decisão do time, não da skill.

---

## Regra fixa — não anexar o HTML interativo ao card (2026-11-12, pedido da usuária)

O HTML interativo do Step 5b **nunca** é anexado ao card "Criar Mapa de Teste" nem à US: o mapa vai somente no conteúdo (Descrição) do card. Não chame `wit_work_item_attachment_upload`/`_link` neste fluxo.

---

## Step 6.5 — Notificar hipóteses em aberto (se houver, não bloqueante)

Se a tabela aprovada no Step 4 **não** tiver nenhum cenário `HIPOTESE:`, pule este step inteiramente.

Se tiver pelo menos um, monte um comentário e poste na **história** (`$WI_ID`, não no card do mapa) chamando `mcp__azure-devops__update_work_item` com `workItemId: $WI_ID` e `additionalFields: {"System.History": "{HTML abaixo}"}`:

```html
<p><strong>Hipóteses em aberto no mapa de testes (card #{MAPA_CARD_ID})</strong> — precisam de confirmação de dev/PO antes de poderem virar teste executável:</p>
<ul>
<li>#{numero} {cenario}: {acao} — resultado esperado hoje: VERIFICAR COM DEV/PO ({esperado, se tiver mais contexto})</li>
...
</ul>
<p>Mapa completo: <a href="https://dev.azure.com/selbettidev/{projeto}/_workitems/edit/{MAPA_CARD_ID}">#{MAPA_CARD_ID}</a></p>
```

Isso **não** move nenhum cenário para fora do mapa — eles continuam lá, marcados `HIPOTESE:`, e `/executar-teste` continua nunca os executando sozinho. O comentário é só um apontador para o time ver e decidir, sem exigir que alguém reabra o card do mapa para notar que há pergunta pendente.

Se `update_work_item` falhar ao postar o comentário, isso **não é bloqueante** — o mapa já foi publicado com sucesso no Step 6; registre a falha do comentário no relatório do Step 7 e siga em frente (o usuário pode postar manualmente se quiser).

---

## Step 7 — Confirm, report, and clean up

Reporte ao usuário:

- Card publicado: `#$MAPA_CARD_ID` (criado ou atualizado), com link (`https://dev.azure.com/selbettidev/{projeto}/_workitems/edit/{id}`).
- **Estado e tag:** confirme que o card ficou em `Committed` e com a tag `agenteqa` (ou o erro, se a alteração falhou).
- Quantidade de cenários publicados e categorias cobertas.
- **HTML interativo local:** caminho do arquivo gravado no Step 5b (ou aviso de que o template não foi encontrado e o passo foi pulado).
- **Dimensões cobertas:** lista das dimensões (positivo/negativo/permissão/dados/concorrência/regressão) efetivamente presentes na tabela aprovada, e quais ficaram `N/A` com o motivo.
- **Pré-requisitos de ambiente:** lista consolidada dos requisitos distintos (por categoria) e quantos cenários dependem de cada um — é o que a skill de validação de ambiente vai consumir.
- **Histórico de defeitos considerado:** IDs dos bugs de `$DEFECT_HISTORY` que geraram cenário de regressão, ou "nenhum encontrado / busca indisponível".
- **Protótipo (Figma):** se o Step 3.9 rodou, quais quadros foram lidos, onde ficaram os prints (`$CICLOS_DIR\US-<ID>\mapas-teste\prototipo\`) e as divergências entre protótipo e US (a US prevalece); ou o motivo de `Protótipo não consultado`.
- **Hipóteses em aberto:** se o Step 6.5 rodou, quantas hipóteses foram notificadas via comentário na história (ou, se falhou ao postar, avisar explicitamente que o comentário não saiu e o mapa segue com as hipóteses marcadas, só sem o aviso na história).

```powershell
if (Test-Path $WORK_DIR) { Remove-Item -LiteralPath $WORK_DIR -Recurse -Force -ErrorAction SilentlyContinue }
```

---

## Step 8 — Registrar no log de ações (governança)

Depois de reportar o Step 7, acrescente uma linha ao final da tabela em
`~/.claude/docs/projetos/skills-qa/LOG-ACOES.md` (via `Edit`, nunca sobrescrevendo o arquivo):

```
| <data/hora atual, ex.: via `Get-Date -Format "yyyy-MM-dd HH:mm"`> | `/gerar-mapa-testes-v3` | Publicação de mapa de testes (<criação\|atualização> do card) | Card #<MAPA_CARD_ID> → US #<WI_ID> | Sucesso | <nome do usuário que aprovou no chat> | <nº de cenários publicados> cenários, dimensões: <lista> |
```

Se o estado do card foi para `Committed`, a tag `agenteqa` foi adicionada (Step 6), mencione isso na coluna Observações. Se o Step 4.5 registrou uma sobrescrita de conteúdo existente, mencione isso explicitamente na
coluna Observações (ex.: "sobrescreveu mapa anterior do card, com confirmação do usuário"). Se o Step 6.5
rodou, mencione também quantas hipóteses foram notificadas via comentário na história (ou que o comentário
falhou, se for o caso).

---

## Troubleshooting

- Se o Step 2 encontrar **mais de um** card "Criar Mapa de Teste" filho da história, sempre pare e pergunte qual usar — nunca escolha automaticamente (ex.: "o mais recente").
- Se o card encontrado já tiver conteúdo na Descrição, o gate do Step 4.5 é obrigatório e específico (menciona o ID e o estado do card) — nunca reaproveitar o texto de aprovação genérico usado quando o card está vazio ou será criado.
- Se uma regra condicional não tiver dimensão de concorrência aplicável, isso deve aparecer como uma linha `N/A — <motivo>` na categoria `CONCORRENCIA`, nunca como ausência silenciosa da categoria.
- Se `search_work_items` (Step 3.5) não existir ou falhar, isso não bloqueia o mapa — registre a limitação no relatório final, não tente adivinhar histórico de defeitos.
- Se `/analise-negocio`/`/analise-tecnica` tiverem rodado para uma história **diferente** da informada em `$ARGUMENTS` nesta mesma conversa, não reaproveite — refaça a busca do zero (Step 3) para a história correta.
- Se `create_work_item`/`update_work_item` falhar (ex.: `"Criar Mapa de Teste"` não é um tipo válido no processo do projeto informado, ou `parentId`/`areaPath` inconsistentes), pare e reporte o erro exato retornado pelo MCP — nunca tente contornar criando um tipo de work item diferente ou publicando em outro lugar sem confirmar com o usuário.
- O comentário do Step 6.5 vai na **história** (`$WI_ID`), nunca no card "Criar Mapa de Teste" — postar lá misturaria o conteúdo do mapa com discussão, e ninguém olha o histórico de comentários de um card de mapa. Nunca mover os cenários `HIPOTESE:` para fora da tabela do mapa por causa desse comentário — ele é um apontador, não um substituto do mapa.
- Se não for possível determinar o pré-requisito de um cenário a partir das 4 fontes, não deixe a célula vazia nem invente: registre o item com prefixo `HIPOTESE:` (Step 4.2b), para que a skill de validação de ambiente o trate como não verificável.
- O HTML interativo do Step 5b é só um arquivo local de apoio à execução manual: o que vale como mapa é o conteúdo publicado no card. Se os dois divergirem, refaça o Step 5b a partir da tabela aprovada — nunca edite o mapa só no arquivo local.
- Se o protótipo (Step 3.9) mostra algo que a US não pede ou manda não exibir (ex.: botão de filtro), **não crie cenário** nem trate como defeito: a US prevalece, e a diferença vai como observação em "Fonte técnica" e como nota no cenário de paridade visual.
- Se, ao montar um cenário, a única justificativa que você consegue escrever na coluna Origem é "achei isso interessante na análise técnica" sem apontar para Instruções QA/Critérios de Aceite/Pontos de Impacto/Casos de Teste (Step 4.0), **não crie o cenário** — é sinal de que ele está fora do escopo da história, mesmo que pareça um risco técnico legítimo.

- Se a US é de BE e algum cenário da tabela cita tela, UI, protótipo ou Clássico/Portal como interface (Step 3.10), **reescreva como API/dados ou remova**; nunca publique o mapa com dependência de front. O CA de FE vira nota em "Fonte técnica", não cenário.
