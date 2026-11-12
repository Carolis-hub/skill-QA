---
name: arquitetura-gerar-mapa-testes
description: Gera e revisa mapas de testes para histórias do Azure DevOps, usando somente MCP Azure DevOps para localizar a história, consultar análises e publicar o mapa no card filho "Criar Mapa de Teste". Aplica o fluxo V3, as dimensões obrigatórias e a disciplina arquitetural da V1 para APIs, jobs, workers, integrações, banco, segurança, performance, observabilidade e migração Legado/Novo.
metadata:
  short-description: Gerar mapa de testes definitivo via Azure DevOps MCP
---

# Arquitetura-gerar-mapa-testes

## Objetivo e fronteiras

Atue como QA Engineer sênior para transformar uma história do Azure DevOps em um mapa de testes executável, rastreável, priorizado por risco e publicável diretamente na Descrição do card filho **Criar Mapa de Teste**.

Esta skill combina:

- o fluxo operacional da V3: variáveis, etapas, MCPs, aprovação antes de publicar, HTML, hipóteses, histórico de defeitos, log e ciclo de execução;
- a disciplina arquitetural da V1: classificação Legado/Novo/Transversal, evidências de código, paridade, banco dual, jobs, integrações, resiliência, observabilidade e passos alternados por ator real.

Não usar Test Plan, suíte, REST, PAT ou publicação fora do card filho. A publicação é 100% via MCP Azure DevOps.

Não declarar “100% de cobertura”. Demonstrar cobertura por requisitos, fontes, regras, estados, riscos, integrações, cenários e lacunas.

Para economizar tokens, leia primeiro o `README.md` do ciclo e os relatórios mais recentes de negócio
e técnica. Reutilize os campos estruturados e só consulte novamente a história, análise ou defeitos
quando a revisão tiver mudado ou o artefato não existir.

## Contrato de entrada e variáveis

Receba `$ARGUMENTS` no formato:

```text
[ID da história] [nome do projeto opcional]
```

Exemplos: `146157` ou `146157 "Nome do Projeto"`.

Preserve estes nomes e seu significado durante todo o fluxo:

- `$ARGUMENTS`: argumentos recebidos;
- `$WI_ID`: ID da história;
- `$STORY_TITLE`, `$STORY_DESC`, `$STORY_AC`: título, descrição e critérios de aceite;
- `$STORY_RELATIONS`: relações da história;
- `$STORY_AREA_PATH`, `$STORY_ITERATION_PATH`, `$STORY_PROJECT`: contexto para criação do card;
- `$CARD_EXISTS`: indica se há um card filho elegível;
- `$MAPA_CARD_ID`, `$MAPA_CARD_STATE`, `$MAPA_CARD_DESC`, `$MAPA_CARD_HAS_CONTENT`: estado do card do mapa;
- `$ANALISE_PONTOS`, `$ANALISE_CASOS`: Pontos de Impacto e Casos de Teste do card Análise;
- `$DEFECT_HISTORY`: defeitos relevantes encontrados;
- `$WORK_DIR`: diretório opcional de log/rascunho.

Quando algum valor não existir, registre a ausência; não invente valor padrão de negócio.

## Invariantes de segurança e escopo

- Baseie conclusões somente na história, critérios, instruções QA, análises, defeitos, código e fatos documentados.
- Não invente regra, mensagem, intervalo, limite, tabela, contrato, SLA, plataforma ou permissão.
- Separe fato, inferência, hipótese, ambiguidade, ausência e conflito.
- Não copie connection strings, tokens, chaves, senhas ou arquivos sensíveis; use marcadores.
- Ler código para produzir evidência não autoriza alterá-lo.
- Indicar automação não autoriza implementá-la.
- Não execute testes ofensivos, destrutivos, de carga destrutiva ou produtivos sem autorização explícita.
- Se faltar informação, registre lacuna, impacto, pergunta objetiva e cenário condicional quando possível.
- Pare e peça esclarecimento apenas se não for possível identificar a história, o componente/comportamento principal ou o resultado esperado; para migração, a localização do legado é obrigatória para declarar paridade.

## Condições artificiais e classificação como hipótese

Cenários que dependam de `INSERT`, `UPDATE` ou `DELETE` direto no banco para criar uma condição sem caminho de geração comprovado pela interface ou por um fluxo suportado do produto devem ser classificados como `HIPOTESE:`.

São fluxos suportados, quando comprovados no contexto da história: interface, API, integração, importação, job, scheduler ou migração.

O uso de SQL para preparar massa não torna o cenário uma hipótese quando apenas reproduz um estado alcançável por esses fluxos. Nesse caso, documente o caminho equivalente e a finalidade da preparação.

Na ausência de comprovação, mantenha `HIPOTESE:`. Não presuma que um estado possível no banco seja possível no uso do produto.

A hipótese somente deixa essa classificação quando houver evidência de que a condição pode ocorrer por um fluxo suportado ou confirmação fundamentada de que o produto deve tratá-la. Registre a fonte da confirmação e atualize o cenário. Seu resultado não pode fundamentar a abertura de Bug enquanto essa confirmação estiver pendente.

## Diretriz compartilhada — Aprendizados

Antes do Step 0, siga `./aprendizados/COMO-USAR.md`: inicialize a estrutura, consulte conhecimentos relacionados à história, módulo, componente, riscos e defeitos recorrentes, e registre `$APRENDIZADOS_CONSULTADOS`. Use-os para enriquecer o mapa somente quando a relação com a história atual estiver demonstrada.

## Step 0 — Validar ambiente

### 0.1 Validar argumentos

Confirme que `$ARGUMENTS` não está vazio e que contém o ID da história. Se falhar, informe:

```text
VALIDATION_FAILED=1
ERROR: Arguments are empty. Provide: [wiId] [projeto opcional]
```

Pare imediatamente. Não faça chamadas de escrita.

### 0.2 Validar MCP e ferramentas

Confirme que `mcp__azure-devops` está conectado e que estão disponíveis:

- `get_work_item`;
- `get_work_items_batch_by_ids` ou equivalente;
- `search_work_items`;
- `update_work_item`;
- `create_work_item`.

Um probe de `get_work_item` com ID inexistente retornando `404` confirma que o servidor está vivo. Se o MCP ou uma ferramenta necessária estiver indisponível, pare e reporte; não contorne com REST.

### 0.3 Criar diretório opcional

Se for útil para log ou rascunho, derive `$WORK_DIR` dentro de `./ciclos-execucao/.tmp/`, usando o ID da história e uma identificação de execução, por exemplo `.testmap-$wiId-$runId`. Use-o somente para arquivos temporários, `run.log` ASCII e eventual `mapa-preview.html`. Não use PowerShell para montar o HTML longo e não grave segredos.

## Step 1 — Buscar a história via MCP

Chame `mcp__azure-devops__get_work_item` com `workItemId: $WI_ID` e `expand: "all"`. Capture:

- `$STORY_TITLE`, `$STORY_DESC`, `$STORY_AC`;
- `$STORY_RELATIONS`;
- `$STORY_AREA_PATH`, `$STORY_ITERATION_PATH`, `$STORY_PROJECT`.

Se o projeto vier em `$ARGUMENTS`, use-o em `$STORY_PROJECT`; caso contrário, use `System.TeamProject` retornado pela história.

## Step 2 — Localizar ou preparar o card do mapa

Extraia de `$STORY_RELATIONS` somente os filhos `rel == "System.LinkTypes.Hierarchy-Forward"`. Consulte-os com `get_work_item` ou em lote e filtre `System.WorkItemType` exatamente igual a **Criar Mapa de Teste**.

- Nenhum encontrado: defina `$CARD_EXISTS = false`. O card será criado no Step 6 com título `Mapa de teste`, `parentId: $WI_ID`, área, iteração e projeto da história.
- Exatamente um: defina `$CARD_EXISTS = true` e capture `$MAPA_CARD_ID`, `$MAPA_CARD_STATE` e `$MAPA_CARD_DESC`. Se a descrição não estiver vazia, defina `$MAPA_CARD_HAS_CONTENT = true`.
- Mais de um: pare e pergunte qual card usar ou se deve criar um novo, listando IDs, títulos e estados. Nunca escolha automaticamente.

Nunca sobrescreva descrição existente sem confirmação explícita no gate do Step 4.5, mesmo que o card esteja em `Done`.

## Step 3 — Reaproveitar análises ou consultar o card Análise

Antes de buscar dados novos, verifique se `/arquitetura-analise-negocio` e/ou `/arquitetura-analise-tecnica` já foram executadas nesta conversa para o mesmo `$WI_ID`.

- Se `/arquitetura-analise-negocio` já rodou, reaproveite objetivo, comportamentos esperados, regras, condições, exceções, dependências, ambiguidades e riscos do relatório. Não rederive esses itens do zero.
- Se `/arquitetura-analise-tecnica` já rodou sem bloqueio, reaproveite somente **Casos de Teste sugeridos pelo dev** e riscos rastreados diretamente a **Pontos de Impacto**. Use dependências, integrações, discrepâncias e narrativa técnica apenas para enriquecer ação/resultado de um cenário já justificado.
- Se não houver análise no ciclo/conversa, extraia IDs filhos e busque em lote os campos `System.WorkItemType`, `Custom.Pontosdeimpacto` e `Custom.CasodeTeste`. Use somente o item cujo tipo seja exatamente `Análise`, nunca `Analise Review`. Capture `$ANALISE_PONTOS` e `$ANALISE_CASOS`.
- Se o card `Análise` não existir, ou existir mas estiver sem `Custom.Pontosdeimpacto` e `Custom.CasodeTeste`, bloqueie a geração do mapa e registre `BLOQUEADO — análise técnica obrigatória ausente ou não preenchida`.

Se uma análise da conversa for de outra história, ignore-a e refaça a busca para `$WI_ID`.

## Step 3.5 — Consultar histórico de defeitos

Use `mcp__azure-devops__search_work_items` para buscar até aproximadamente 10 bugs relacionados, com `System.WorkItemType = ["Bug"]`, termos-chave do título/objetivo e, quando fizer sentido, `$STORY_AREA_PATH`. Capture no `$DEFECT_HISTORY` ID, título e estado.

Defeito relevante deve gerar pelo menos um cenário de regressão. Nenhum resultado ou falha dessa busca não bloqueia o mapa, mas deve ser declarado explicitamente no mapa e no relatório final. Não force relação com bugs de área claramente distinta.

## Step 3.6 — Classificar a origem dos requisitos

Antes dos cenários, classifique cada requisito como:

- **Legado**: comportamento existente no SmartShareAgent ou rotina que precisa ser preservada na migração;
- **Novo**: comportamento criado sem expectativa de paridade;
- **Transversal**: configuração, infraestrutura, observabilidade, segurança, performance, implantação, compatibilidade ou outro comportamento que atravessa componentes.

Sinais de Legado incluem migração, portar, reescrever, paridade, substituir o Agent, ou citação de rotinas como `timerNotifyWF`, `InicioTemporal`, `EnvioEmail` e `FolderDelete`. A existência isolada de uma classe, job, handler ou Quartz novo não prova migração.

Para requisitos Legado:

1. localizar o projeto/caminho físico do legado, se informado;
2. localizar a rotina correspondente no legado e no novo;
3. registrar evidências no formato `arquivo:símbolo`;
4. montar matriz de paridade antes dos cenários;
5. aplicar teste back-to-back quando houver massa, relógio e configuração comparáveis.

Se a origem for incerta, registre `DUV-00`, crie cenários condicionais e não transforme a dúvida em paridade obrigatória. Se não houver caminho do legado quando a demanda exigir paridade, registre bloqueio/limitação e solicite-o antes de afirmar cobertura de migração.

## Step 4 — Gerar a tabela de cenários

### 4.0 Escopo obrigatório das fontes

Todo cenário final precisa rastrear uma fonte primária e, quando houver, fontes secundárias:

1. Instruções QA da história, quando existirem;
2. Critérios de Aceite da história;
3. `Custom.Pontosdeimpacto` do card `Análise`;
4. `Custom.CasodeTeste` do card `Análise`.

Fontes técnicas secundárias permitidas: análise técnica, PR/diff, arquivo:símbolo, dependência
indireta, histórico de defeito e evidência de legado/novo. Elas não podem inventar requisito, mas
podem justificar um cenário de risco arquitetural quando a relação com a história estiver explicada.

A narrativa investigativa da análise técnica, dependências indiretas, achados de outro repositório, notas de investigação e discrepâncias podem justificar cenário quando houver relação explícita com uma fonte primária e risco arquitetural verificável. Se a relação não puder ser demonstrada, registre o achado em **Fonte técnica** como observação e não crie cenário especulativo.

### 4.1 Análise arquitetural e técnica

Extraia objetivo, atores humanos e não humanos, início/término, dependências, regras, exceções, estados, eventos, transições, cancelamento, falha, reprocessamento, gatilho, agendamento, configuração, dados, volume, lote, concorrência, autenticação, payloads, timeout, retentativa, idempotência, persistência e efeitos colaterais.

Quando aplicável, avalie:

- API: Controller → Service → Repository, contrato, tipos, erros e compatibilidade;
- jobs/workers/scheduler: primeira execução, intervalo, horário fixo, cron, misfire, sobreposição, ordem, retomada e reinício;
- banco: Oracle e SQL Server, transação, integridade, migração, fuso, arredondamento, encoding e SQL de verificação;
- segurança: autenticação, token inválido/expirado, escopo, isolamento e ausência de segredo em log;
- configuração: padrão, ausente, inválida, origem e alteração em runtime;
- observabilidade: log JSON/NLog, Sentry, health check e evidência sem dado sensível;
- integração: contrato, autenticação, timeout, falha, retentativa, backoff, resposta parcial e idempotência;
- operação: start/stop, instalação, reinício, rollback e coexistência.

Use o contexto SmartShare abaixo como checklist, nunca como regra inventada; confirme no código e na história:

- backend .NET 8 com Controller → Service → Repository, Dapper/DbContext e Flunt;
- Oracle 19c+ e SQL Server 2012+ quando SQL, repositório, job ou relatório forem afetados;
- JWT `Authorization` do engineApi e `X-User-Authorization` do portal Share4 somente em endpoints aplicáveis;
- NLog, Sentry e `/health` para observabilidade;
- legado WebForms/serviços/`SmartShareAgent` com `System.Threading.Timer`;
- novo Agent .NET 8/Quartz quando explicitamente pertinente.

### 4.2 Regras condicionais e dimensões obrigatórias

Liste cada regra “X só pode acontecer se Y”, usando nesta ordem: Instruções QA, Critérios de Aceite, análise de negócio e Pontos de Impacto/Casos de Teste. Para cada dimensão, marque `APLICÁVEL`, `N/A — motivo`, `BLOQUEADA` ou `FORA DO ESCOPO`. Não crie cenário artificial apenas para preencher uma dimensão; dimensões aplicáveis a risco alto devem gerar cobertura explícita:

| Dimensão | Obrigação |
|---|---|
| positivo | condição satisfeita e comportamento esperado |
| negativo | cada valor/estado relevante que não satisfaz a condição |
| permissão | perfil sem autorização tentando a mesma ação |
| dados | dado inexistente, nulo, vazio, duplicado ou inconsistente relevante |
| concorrência | execuções simultâneas disputando recurso/contador; se não aplicável, `N/A — motivo` |
| regressão | fluxo anterior/adjacente que não pode quebrar; incluir defeitos relevantes |

Além das dimensões, cubra fluxo alternativo, falha, limites, estados, persistência, agendamento, resiliência, banco dual, integrações, segurança, observabilidade, performance e implantação quando aplicáveis.

### 4.3 Técnica formal por cenário

Escolha explicitamente uma técnica:

- `valor-limite`: número, data, tamanho, quantidade, lote, intervalo, tentativas ou horário de corte;
- `tabela-decisão`: duas ou mais condições independentes determinando ações;
- `partição-equivalência`: classes válidas/inválidas, tipos, formatos, nulo, vazio ou ausência;
- `transição-de-estado`: estados, transições, repetição, falha, retomada e persistência;
- `pairwise`: dimensões como banco × configuração × módulo × volume, informando a estratégia;
- `exploratório`: fluxo, UI ou integração sem regra formal, com objetivo, risco, duração, heurísticas e evidências;
- `back-to-back`: somente quando houver requisito Legado e comparação controlada entre legado e novo.

Não escolha a técnica por estética: relacione-a à regra que originou o cenário.

### 4.4 Categorias fixas

Mantenha esta organização da V3, adaptando apenas o nome de domínio:

1. `=== FLUXO PRINCIPAL ===`
2. `=== FLUXO ALTERNATIVO ===`
3. `=== VALIDACOES DE CAMPOS ===`
4. `=== PERMISSAO ===`
5. `=== DADOS E CASOS DE BORDA ===`
6. `=== CONCORRENCIA ===` — sempre presente, ainda que contenha `N/A — motivo`;
7. `=== ERROS DE INTEGRACAO / API ===`
8. `=== REGRESSAO ===` — Pontos de Impacto + histórico de defeitos;
9. `=== CASOS DE BORDA / HIPOTESES ===` — hipóteses sempre marcadas `HIPOTESE:`.

Para arquitetura, ordene cenários dentro das categorias por risco e, quando fizer sentido, por fluxo principal, regras, limites, negativos, estados, persistência, agendamento, concorrência/idempotência, resiliência, banco, integração, segurança, observabilidade, performance, regressão e exploração.

### 4.5 Passo a passo obrigatório

Cada cenário deve conter um único bloco **Passo a passo sequencial**, alternando ação e resposta na mesma lista numerada:

1. passos ímpares são ações;
2. passos pares são respostas observáveis;
3. a ação começa pelo ator verdadeiro: `O usuário deve...`, `O executor deve...`, `O cliente da API deve...`, `O job deve...` ou `O scheduler deve...`;
4. a resposta seguinte começa com `O sistema deve...`;
5. cada resposta corresponde diretamente à ação anterior;
6. ações detalham endpoint/tela, serviço, configuração, dado, SQL, tempo, evidência e restauração;
7. respostas descrevem status, registro, mensagem, e-mail, arquivo, log, HTTP, persistência ou ausência de efeito;
8. não agrupe respostas independentes.

Exemplo arquitetural:

```md
**Passo a passo sequencial:**

1. O executor deve inserir o registro de preparação com o SQL da seção **Dados** e anotar o ID retornado.
2. O sistema deve retornar uma linha com STATUS = 'P'.
3. O executor deve aguardar o próximo ciclo do job, com o serviço em execução, por até [INTERVALO].
4. O sistema deve registrar no log [CAMINHO_LOG] a execução de [ROTINA] sem erro.
5. O executor deve executar o SQL de verificação no banco selecionado.
6. O sistema deve retornar STATUS = 'C', DT_PROCESSAMENTO preenchida e nenhum efeito duplicado.
```

### 4.6 Dados, pré-condições e evidências

Cada cenário deve informar ambiente, build/branch, banco e versão, serviços, configuração, massa, acesso a logs/banco, estado inicial, integrações e restauração.

Quando o resultado for observado no banco, inclua SQL de preparação e verificação. Para `INSERT`, `UPDATE` ou `DELETE`, registre escopo, autorização necessária e limpeza/rollback. Use marcadores para dados não fornecidos; nunca apresente marcador como valor real e nunca inclua credenciais.

Evidência de código deve ser `arquivo:símbolo`. Para Legado, acrescente no cenário **Evidência legado** e **Evidência novo**. Para paridade, registre massa, relógio, configuração, estado final e divergências.

### 4.7 Apresentar tabela e aguardar aprovação

Apresente no chat a tabela completa antes de qualquer escrita:

```md
| # | Cenário | Ação | Resultado Esperado | Tipo | Técnica | Dimensão | Origem | Camada | Componente |
|---|---|---|---|---|---|---|---|---|---|
```

Tipos: `positivo`, `negativo`, `borda`. Origens: `história`, `análise técnica/PR`, `histórico de defeitos`, `hipótese` ou `Legado/Novo/Transversal` na rastreabilidade.

Pare e aguarde confirmação explícita. Nunca publique automaticamente.

- `$CARD_EXISTS = false`: “Aprovar publicação deste mapa? Vou criar o card ‘Criar Mapa de Teste’ filho da história e publicar o mapa na Descrição dele.”
- card existente sem conteúdo: “Aprovar publicação deste mapa no card ‘Criar Mapa de Teste’ #$MAPA_CARD_ID?”
- card existente com conteúdo: “O card #$MAPA_CARD_ID já tem conteúdo na Descrição (estado: $MAPA_CARD_STATE). Publicar substituirá esse conteúdo. Confirma a sobrescrita?”

Se houver `HIPOTESE:`, informe também que um comentário será postado na história após a publicação, listando as hipóteses e pedindo confirmação de dev/PO.

## Step 5 — Montar o HTML do mapa

Construa o HTML diretamente como texto para `description` do MCP. Não monte HTML longo em PowerShell, XML ou editor intermediário. Se precisar revisar, grave e releia `$WORK_DIR\mapa-preview.html`.

O mapa deve conter, nesta ordem:

1. título, história, projeto e iteração;
2. objetivo, escopo, fora de escopo e risco;
3. fonte técnica e fontes analisadas;
4. critérios de aceite;
5. origem dos requisitos e, quando aplicável, matriz de paridade;
6. premissas, ambiguidades, ausências e conflitos;
7. histórico de defeitos considerado;
8. dimensões cobertas e N/A justificados;
9. tabela de cenários;
10. matriz de rastreabilidade;
11. cobertura de riscos e riscos residuais;
12. itens bloqueados e resumo.

Use a tabela HTML fixa da V3:

```html
<table style="border-collapse:collapse;width:100%;table-layout:fixed;">
<tr style="background:#e6e6e6;font-weight:bold;">
<td style="border:1px solid #999;padding:4px;width:4%;">#</td>
<td style="border:1px solid #999;padding:4px;width:12%;">Cenário</td>
<td style="border:1px solid #999;padding:4px;width:20%;">Ação</td>
<td style="border:1px solid #999;padding:4px;width:20%;">Resultado Esperado</td>
<td style="border:1px solid #999;padding:4px;width:7%;">Tipo</td>
<td style="border:1px solid #999;padding:4px;width:9%;">Técnica</td>
<td style="border:1px solid #999;padding:4px;width:7%;">Dimensão</td>
<td style="border:1px solid #999;padding:4px;width:7%;">Origem</td>
<td style="border:1px solid #999;padding:4px;width:7%;">Camada</td>
<td style="border:1px solid #999;padding:4px;width:7%;">Componente</td>
</tr>
<tr><td colspan="10" style="background:#d9e8f5;font-weight:bold;border:1px solid #999;padding:4px;">=== CATEGORIA ===</td></tr>
</table>
```

Regras: larguras `4/12/20/20/7/9/7/7/7/7%`; `table-layout:fixed`; uma linha `colspan="10"` antes do primeiro cenário de cada categoria; paleta neutra; nenhuma herança do Word; escape de texto HTML; categoria nunca dentro da célula de cenário.

## Step 6 — Publicar via MCP

- Se `$CARD_EXISTS = false`, chame `mcp__azure-devops__create_work_item` com `workItemType: "Criar Mapa de Teste"`, `title: "Mapa de teste"`, `description: [HTML]`, `parentId: $WI_ID`, `areaPath: $STORY_AREA_PATH`, `iterationPath: $STORY_ITERATION_PATH` e `projectId: $STORY_PROJECT`. Capture o ID como `$MAPA_CARD_ID`.
- Se `$CARD_EXISTS = true`, chame `mcp__azure-devops__update_work_item` com `workItemId: $MAPA_CARD_ID` e apenas `description: [HTML]`.

Não altere `state`, `assignedTo` ou outros campos sem pedido explícito.

Após criar ou atualizar, releia o card pelo MCP e valide: título, ID, estado, quantidade de cenários,
presença das categorias, existência da tabela HTML e ausência de truncamento. Se o conteúdo lido não
corresponder ao aprovado, classifique como `INCONCLUSIVO — publicação não confirmada` e não declare o
mapa publicado com sucesso.

## Step 6.5 — Notificar hipóteses

Se não houver cenário `HIPOTESE:`, pule este step.

Se houver, use `mcp__azure-devops__update_work_item` na história `$WI_ID`, nunca no card do mapa, com `additionalFields: {"System.History": [HTML do comentário]}`. Liste cada hipótese e inclua o link do mapa. As hipóteses continuam na tabela e não podem ser executadas automaticamente.

Se o comentário falhar, não desfaça a publicação: registre a falha e informe o usuário.

## Step 7 — Reportar e limpar

Informe card criado/atualizado, ID e link, quantidade de cenários, categorias, dimensões cobertas e N/A, defeitos que geraram regressão, hipóteses notificadas, falhas não bloqueantes e riscos residuais. Remova `$WORK_DIR` somente depois de concluir o relatório; se a limpeza falhar, registre-a sem apagar evidências necessárias.

## Step 8 — Registrar governança

Depois do relatório, acrescente uma linha ao final da tabela de `./log/LOG-ACOES.md` via edição incremental, nunca sobrescrevendo:

```text
| <data/hora> | /arquitetura-gerar-mapa-testes | Publicação de mapa de testes (<criação|atualização>) | Card #<MAPA_CARD_ID> → US #<WI_ID> | Sucesso | <usuário que aprovou> | — | <n> cenários, dimensões: <lista> |
```

Inclua sobrescrita confirmada, número de hipóteses e falha de comentário quando aplicável. Se o caminho não estiver acessível, informe a limitação; não invente que o log foi atualizado.

## Step 9 — Registrar no ciclo de execução

Antes de encerrar, avalie e registre aprendizados conforme `./aprendizados/COMO-USAR.md`. Depois siga `./ciclos-execucao/COMO-REGISTRAR.md` com `<etapa> = mapa-testes`: crie `NN-mapa-testes.md`, atualize o `README.md` do ciclo e o índice `ciclos-execucao/README.md`, incluindo tabela aprovada, card, comentário de hipóteses e os aprendizados consultados/registrados. Falha nessa escrita local não desfaz a publicação; reporte-a.

## Formato mínimo do mapa publicado

```md
# Mapa de Testes — [Componente/Funcionalidade]

**Estratégia:** [Paridade / Novo / Transversal — justificativa]
**Origem dos requisitos:** [Legado, Novo, Transversal por requisito]

## 1. Visão geral
## 2. Fontes analisadas
## 3. Requisitos e regras
## 4. Matriz de paridade — somente se houver Legado
## 5. Premissas, ambiguidades e ausências
## 6. Pré-requisitos gerais
## 7. Cobertura planejada
## 8. Cenários
## 9. Cenários exploratórios
## 10. Matriz de rastreabilidade
## 11. Cobertura de riscos
## 12. Itens bloqueados
## 13. Resumo
```

Cada cenário contém ID, título, objetivo, requisitos/fontes, origem, prioridade P0–P3, tipo, técnica, pré-condições, dados, passos alternados, evidências, pós-condição, automação e observações. Requisitos Legado também contêm evidência do legado e do novo.

## Controle de qualidade antes da entrega

Verifique:

- estratégia e origem de cada requisito declaradas;
- cada cenário rastreia fonte permitida;
- cada critério/regra tem cenário ou justificativa;
- dimensões positivo, negativo, permissão, dados, concorrência e regressão presentes ou justificadas como N/A;
- categorias fixas preservadas;
- técnica formal atribuída por cenário;
- fluxos positivos, negativos, alternativos, falha e limites aplicáveis;
- estados, persistência, configuração, agendamento, concorrência, idempotência, resiliência, bancos, integração, segurança, observabilidade, performance e regressão avaliados quando pertinentes;
- riscos P0/P1 cobertos ou explicitamente residuais;
- ações executáveis por leigo e respostas objetivamente observáveis;
- ator verdadeiro usado em cada ação e `O sistema deve...` na resposta;
- SQL, dados, ambiente, logs e restauração claros;
- evidência `arquivo:símbolo` e matriz back-to-back presentes quando Legado;
- sem duplicidade, IDs repetidos, regra inventada, segredo, promessa de cobertura total ou hipótese apresentada como fato.

## Revisão de mapas existentes

Preserve cenários válidos e identifique duplicidades, lacunas, ações inexequíveis, resultados subjetivos, dados insuficientes, técnica ausente, regressão ausente, banco sem cobertura, riscos sem tratamento e requisitos de migração sem paridade. Classifique cada achado como crítico, alto, médio ou baixo.

## Candidatos à automação

Favoreça cenários determinísticos, frequentes, de regressão, alto risco, contratos de API, regras unitárias/integradas, validações de banco e comparações de paridade controladas. Trate com cautela relógio real, integração instável, preparação complexa e exploração. Justifique `Sim`, `Não` ou `Parcial`.

## Troubleshooting

- Mais de um card elegível: pare e pergunte.
- Card com descrição: gate de sobrescrita obrigatório.
- Concorrência não aplicável: linha `N/A — motivo` obrigatória.
- Histórico de defeitos indisponível: não bloqueie; registre a limitação.
- Análise de outra história: não reaproveite.
- Falha de criação/atualização: pare e reporte o erro exato; não crie outro tipo de item nem publique em outro local.
- Comentário de hipótese: sempre na história, nunca no card do mapa.
- Cenário justificado somente por narrativa técnica: não crie; registre como observação.
- Requisito Legado sem caminho/evidência: não declare paridade concluída; registre bloqueio ou cenário condicional.

## Idioma e resultado esperado

Responda no idioma do usuário, preserve nomes de classes, tabelas, rotinas e campos, explique termos técnicos quando necessário e não use “etc.” para esconder comportamentos. O resultado deve permitir compreender escopo, preparar ambiente, executar cenários, decidir aprovação/falha, rastrear requisitos e paridade, visualizar riscos e lacunas e selecionar automação.
