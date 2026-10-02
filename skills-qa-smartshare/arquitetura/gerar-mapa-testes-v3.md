---
description: Generate a test case map from an Azure DevOps story and publish it directly into the Description field of the "Criar Mapa de Teste" card (child of the story), via MCP only — no Test Plan, no REST, no PAT. v3 — checklist obrigatorio de dimensoes (permissao/dados/concorrencia/regressao), tecnica formal de teste por cenario, historico de defeitos e reaproveitamento de /analise-negocio e /analise-tecnica. Baseado no v2 (encoding-hardened) apenas na parte de analise; a parte de publicacao foi reescrita para nao usar Test Plan.
---

Generate a test map from Azure DevOps story arguments **$ARGUMENTS**.

Expected format: `[ID da história] [nome do projeto (opcional)]`

Examples:
- `146157` → projeto resolvido automaticamente a partir do próprio work item (`System.TeamProject`)
- `146157 "Nome do Projeto"` → projeto explícito

> **Relação com o v2:** o v2 continua sendo o comando validado em produção para o fluxo de Test Plan — não foi alterado. O v3 **não usa mais Test Plan**: o mapa de testes é publicado diretamente na Descrição do card **"Criar Mapa de Teste"**, que é filho da história no board principal. Isso elimina toda a dependência de REST/PAT que o v2 e as versões anteriores do v3 exigiam — a publicação é 100% via MCP.

---

## O que muda em relação ao v2

1. **Alvo de publicação diferente**: o mapa vai para a Descrição (HTML) do card "Criar Mapa de Teste" filho da história, não para um Test Case dentro de um Test Plan. Sem Test Plan, sem suíte, sem REST, sem PAT.
2. **Checklist obrigatório de dimensões** por regra condicional (Step 4) — positivo / negativo / permissão / dados / concorrência / regressão, em vez de deixar a cobertura a critério livre do modelo.
3. **Técnica formal de teste por cenário** (Step 4) — valor-limite, tabela-decisão, partição-equivalência ou exploratório, registrada explicitamente por linha.
4. **Categoria `REGRESSAO` de primeira classe**, alimentada pelo card `Análise` e pelo histórico de defeitos.
5. **Consulta a histórico de defeitos** (Step 3.5) via `search_work_items`.
6. **Reaproveitamento de `/analise-negocio` e `/analise-tecnica`** quando já tiverem rodado na mesma conversa (Step 3), em vez de sempre re-derivar tudo dos campos brutos.
7. **Verificação do card "Criar Mapa de Teste" antes de publicar** (Step 2): localiza o card existente, cria um novo se não existir, e nunca sobrescreve um card com conteúdo sem confirmação explícita.
8. **Tabela HTML com larguras de coluna proporcionais e categoria em linha separadora própria** (Step 5) — corrige o problema visual observado quando uma tabela colada do Word (colunas todas iguais, ~70px) foi publicada manualmente no card 160129: frases longas quebravam no meio, inclusive dentro do próprio rótulo da categoria.
9. **Notificação de hipóteses em aberto** (Step 6.5, 2026-09-15) — se o mapa aprovado tiver algum cenário `HIPOTESE:`, a skill posta um comentário na história (não no card do mapa) listando cada uma e pedindo confirmação de dev/PO. Não bloqueia a publicação nem a execução — é só visibilidade, para essas perguntas não ficarem "perdidas" dentro da tabela do card. As hipóteses continuam normalmente dentro do mapa (não saem de lá); o comentário aponta para o mapa, não o substitui.
10. **Escopo de origem restrito a 4 fontes** (Step 4.0, 2026-09-22) — decisão de Cintia após a US #138559: mapas anteriores puxavam cenário de qualquer trecho da narrativa investigativa da análise técnica (revalidações de infra, achados de performance em outro repositório, notas de investigação do dev para ele mesmo), o que gerava cenários difíceis/impossíveis de executar por irem além do que a própria história pede. A partir de agora, todo cenário do mapa precisa rastrear a uma destas 4 fontes: Instruções QA da história, Critérios de Aceite da história, `Custom.Pontosdeimpacto` (Pontos de Impacto do dev) ou `Custom.CasodeTeste` (Casos de Teste do dev). A narrativa completa da análise técnica (`System.Description` do card `Análise`, ou as seções sintetizadas de `/analise-tecnica` que vêm dela — Dependências, Integrações potencialmente impactadas, Discrepâncias, etc.) serve para dar contexto ao redigir a Ação/Resultado Esperado de um cenário já justificado por uma das 4 fontes, mas nunca para justificar sozinha a existência de um cenário novo. Ver Step 4.1 e 4.3.

---

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

## Step 3.5 — Histórico de defeitos

Objetivo: identificar bugs anteriores relacionados à mesma área/funcionalidade, para que cenários que já quebraram antes virem regressão obrigatória no Step 4.

Chame `mcp__azure-devops__search_work_items` filtrando `System.WorkItemType = ["Bug"]` e, quando fizer sentido, `System.AreaPath`, combinando com termos-chave do título/objetivo da história no `searchText`. Capture até ~10 resultados relevantes como `$DEFECT_HISTORY` (ID, título, estado).

Se a busca não retornar nada relacionado, **isso não é bloqueante** — prossiga sem histórico e registre essa limitação explicitamente na seção "Histórico de defeitos considerado" do mapa (Step 5), não apenas silenciosamente. Bugs de módulos/áreas claramente distintas da história atual não contam como histórico relevante — não force uma relação que não existe.

---

## Step 4 — Generate test map table

### 4.0 — Escopo de origem (obrigatório, ler antes de 4.1)

Todo cenário do mapa final precisa rastrear a **pelo menos uma** destas 4 fontes:

1. **Instruções QA da história** (seção "Instruções QA" de `$STORY_DESC`, quando existir).
2. **Critérios de Aceite da história** (`$STORY_AC`).
3. **Pontos de Impacto do dev** (`Custom.Pontosdeimpacto` do card `Análise`, ou a seção do relatório `/analise-tecnica` que rastreia diretamente a esse campo).
4. **Casos de Teste do dev** (`Custom.CasodeTeste` do card `Análise`, ou a seção "Casos de teste sugeridos pelo dev" do relatório `/analise-tecnica`).

**Não é fonte suficiente, sozinha:** a narrativa investigativa da análise técnica (revalidações de infraestrutura, achados de performance em outro repositório/caminho de código, notas de "pontos de atenção" do dev que não viraram item explícito em Pontos de Impacto, discrepâncias entre análise e PR, dependências indiretas). Esse material serve para enriquecer a *Ação*/*Resultado Esperado* de um cenário já justificado pelas 4 fontes acima — nunca para, sozinho, criar um cenário novo. Motivo: mapas que puxavam cenário dessa narrativa vinham ficando difíceis/impossíveis de executar por irem além do que a própria história pede (decisão de Cintia, 2026-09-22, US #138559).

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

### 4.2 — Escolher a técnica formal de teste por cenário

Para cada linha gerada, atribua uma técnica, escolhida pelo tipo de regra que originou o cenário — não é livre-escolha estética:

- **valor-limite** — regra envolve número, data, tamanho ou contagem com limite (ex.: quantidade mínima/máxima, prazo, faixa de parcelas)
- **tabela-decisão** — regra combina duas ou mais condições independentes que juntas determinam o resultado (ex.: combinação de dois atributos do documento/registro → ação disponível)
- **partição-equivalência** — regra separa entradas em classes válidas/inválidas sem envolver limite numérico (ex.: tipo de usuário, tipo de documento)
- **exploratório** — cenário de fluxo, UI ou integração sem uma regra formal aplicável (ex.: navegação, mensagens de erro de integração)

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

### 4.4 — Regras de geração

- Não inventar regra além do que está descrito; hipóteses sempre marcadas `HIPOTESE:`.
- Não repetir cenários.
- Todo cenário rastreia a uma das 4 fontes do Step 4.0 (Instruções QA, Critérios de Aceite, Pontos de Impacto do dev, Casos de Teste do dev) — nunca só à narrativa da análise técnica.
- Considerar: validação de campos, comportamento de UI, consistência de dados, falhas de integração — sempre ancorado numa das 4 fontes acima, não como exploração livre do código/PR.

### 4.5 — Apresentar a tabela e pedir aprovação

Apresente a tabela completa no chat (markdown):

```
| # | Cenário | Ação | Resultado Esperado | Tipo | Técnica | Dimensão | Origem |
|---|---------|------|--------------------|------|---------|----------|--------|
```

- Tipo: `positivo`, `negativo`, `borda`
- Técnica: `valor-limite`, `tabela-decisão`, `partição-equivalência`, `exploratório`
- Dimensão: `positivo`, `negativo`, `permissão`, `dados`, `concorrência`, `regressão`
- Origem: `história` (Instruções QA ou Critérios de Aceite), `análise técnica` (especificamente `Custom.Pontosdeimpacto` ou `Custom.CasodeTeste` — nunca a narrativa investigativa isolada, ver Step 4.0), `histórico de defeitos`, `hipótese`

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

<h3>Cenarios de teste</h3>
<table style="border-collapse:collapse;width:100%;table-layout:fixed;">
<tr style="background:#e6e6e6;font-weight:bold;">
<td style="border:1px solid #999;padding:4px;width:4%;">#</td>
<td style="border:1px solid #999;padding:4px;width:14%;">Cenario</td>
<td style="border:1px solid #999;padding:4px;width:24%;">Acao</td>
<td style="border:1px solid #999;padding:4px;width:24%;">Resultado Esperado</td>
<td style="border:1px solid #999;padding:4px;width:8%;">Tipo</td>
<td style="border:1px solid #999;padding:4px;width:10%;">Tecnica</td>
<td style="border:1px solid #999;padding:4px;width:8%;">Dimensao</td>
<td style="border:1px solid #999;padding:4px;width:8%;">Origem</td>
</tr>
<tr><td colspan="8" style="background:#d9e8f5;font-weight:bold;border:1px solid #999;padding:4px;">=== {CATEGORIA} ===</td></tr>
<tr>
<td style="border:1px solid #999;padding:4px;">{id}</td>
<td style="border:1px solid #999;padding:4px;">{cenario}</td>
<td style="border:1px solid #999;padding:4px;">{acao}</td>
<td style="border:1px solid #999;padding:4px;">{esperado}</td>
<td style="border:1px solid #999;padding:4px;">{tipo}</td>
<td style="border:1px solid #999;padding:4px;">{tecnica}</td>
<td style="border:1px solid #999;padding:4px;">{dimensao}</td>
<td style="border:1px solid #999;padding:4px;">{origem}</td>
</tr>
```

Regras obrigatórias:

- **Larguras proporcionais fixas** (as do exemplo acima: 4/14/24/24/8/10/8/8%) — nunca deixar o Word/ADO distribuir igualmente as colunas. `table-layout:fixed` no `<table>` garante que os `width` sejam respeitados.
- **Uma linha `<tr><td colspan="8">`** por categoria, antes do primeiro cenário daquela categoria — nunca embutir o rótulo da categoria dentro da célula "Cenário" do primeiro item.
- Sem estilos herdados do Word (sem `font-family:Aptos`, sem `background:silver`) — usar paleta neutra simples (cabeçalho `#e6e6e6`, separador de categoria `#d9e8f5`) para ficar consistente independente de onde o conteúdo foi originado.
- Texto direto, sem colar de nenhum editor — monte o HTML você mesmo, célula por célula, a partir dos dados já validados no Step 4.

Se a tabela for muito grande e você quiser revisar antes de publicar, salve o HTML em `$WORK_DIR\mapa-preview.html` via `Write` e releia com `Read` antes do Step 6 — mas isso é opcional, não é uma exigência de encoding como era no fluxo antigo baseado em PowerShell.

---

## Step 6 — Publicar via MCP

- **Se `CARD_EXISTS = false`:** chame `mcp__azure-devops__create_work_item` com `workItemType: "Criar Mapa de Teste"`, `title: "Mapa de teste"`, `description: {HTML do Step 5}`, `parentId: $WI_ID`, `areaPath: $STORY_AREA_PATH`, `iterationPath: $STORY_ITERATION_PATH`, `projectId: $STORY_PROJECT`. Capture o `id` retornado como `$MAPA_CARD_ID`.
- **Se `CARD_EXISTS = true`:** chame `mcp__azure-devops__update_work_item` com `workItemId: $MAPA_CARD_ID`, `description: {HTML do Step 5}`.

Não altere `state`, `assignedTo` nem qualquer outro campo do card além da Descrição, a menos que o usuário peça explicitamente — a decisão de mover o card para "Done" é do time, não da skill.

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
- Quantidade de cenários publicados e categorias cobertas.
- **Dimensões cobertas:** lista das dimensões (positivo/negativo/permissão/dados/concorrência/regressão) efetivamente presentes na tabela aprovada, e quais ficaram `N/A` com o motivo.
- **Histórico de defeitos considerado:** IDs dos bugs de `$DEFECT_HISTORY` que geraram cenário de regressão, ou "nenhum encontrado / busca indisponível".
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

Se o Step 4.5 registrou uma sobrescrita de conteúdo existente, mencione isso explicitamente na
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
- Se, ao montar um cenário, a única justificativa que você consegue escrever na coluna Origem é "achei isso interessante na análise técnica" sem apontar para Instruções QA/Critérios de Aceite/Pontos de Impacto/Casos de Teste (Step 4.0), **não crie o cenário** — é sinal de que ele está fora do escopo da história, mesmo que pareça um risco técnico legítimo.
