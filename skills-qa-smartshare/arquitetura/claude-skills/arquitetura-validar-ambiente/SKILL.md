---
name: arquitetura-validar-ambiente
description: Valida e prepara o ambiente de execução dos testes da Arquitetura do SmartShare, incluindo conectividade, configuração e massas necessárias em Oracle e SQL Server; bloqueia a execução até que todas as massas aplicáveis estejam confirmadas.
metadata:
  short-description: Validar ambiente e massas antes dos testes
---

# Arquitetura-validar-ambiente

Validar o ambiente de execução antes de `/arquitetura-executar-teste`.

Formato esperado: `[ID da User Story OU ID do card Criar Mapa de Teste] [nome do projeto (opcional)] [ambiente (opcional, default: HMG)]`

Exemplos:

- `164251` → localiza a User Story, o card filho `Criar Mapa de Teste` e valida todas as massas do mapa.
- `164251 "Nome do Projeto" HMG`
- `164300 HMG` → aceita diretamente o card `Criar Mapa de Teste` quando o ID informado for desse tipo.

Esta skill é uma etapa de preparação e gate. Ela não navega pela aplicação, não executa cenários e não declara resultado funcional. Seu único resultado operacional é confirmar, com evidência, que o ambiente e todas as massas necessárias para a rodada estão prontos, ou bloquear a rodada com pendências objetivas.

## Regra de liberação

Só emitir `LIBERADO PARA EXECUÇÃO` quando todos os requisitos abaixo estiverem confirmados para o mesmo ambiente, banco, versão e mapa:

1. O Azure DevOps MCP e os recursos necessários para localizar a história e o mapa estão disponíveis.
2. O ambiente informado é não produtivo, está acessível e corresponde à versão que será testada.
3. Cada banco aplicável ao mapa — Oracle, SQL Server ou ambos — possui um caminho de validação confiável: MCP de banco, adapter local aprovado ou evidência manual verificável.
4. O schema, as tabelas/objetos, as configurações, os estados, os relacionamentos, os usuários e os demais dados exigidos por **todos** os cenários executáveis estão presentes e coerentes.
5. Toda massa ausente identificada foi criada e verificada, ou o usuário autorizou explicitamente a criação e ela ainda está pendente. Neste último caso, o resultado é `BLOQUEADO`, nunca `LIBERADO`.
6. O relatório de validação foi salvo no ciclo da história e sua assinatura de contexto ainda é válida quando `/arquitetura-executar-teste` iniciar.

Se uma massa de um único cenário estiver ausente, a rodada inteira fica bloqueada. Não liberar cenários independentes parcialmente: o objetivo desta skill é entregar uma pré-condição completa para a execução da rodada solicitada.

## Validade funcional da massa e hipóteses

Antes de propor escrita direta no banco, verifique se a condição preparada possui caminho de geração comprovado no produto, conforme a regra de condições artificiais de `./arquitetura-gerar-mapa-testes.md`.

Registre no `$MASSA_MANIFEST`:

- condição que será criada;
- caminho suportado equivalente e sua evidência, quando existente;
- classificação do cenário como confirmado ou `HIPOTESE:`.

Criar a massa e verificar sua integridade não confirma a validade funcional da condição e não remove a classificação de hipótese. Hipóteses continuam sujeitas à restrição de execução automática do mapa. Registre a classificação também para massas existentes que tenham sido preparadas artificialmente; a presença do registro não comprova sua origem funcional.

## Estratégia de acesso ao banco e bootstrap de primeira execução

O MCP de Oracle/SQL Server é o caminho preferencial, mas não é um pré-requisito absoluto. A skill deve escolher o primeiro caminho disponível nesta ordem:

| Prioridade | Caminho | Quando usar | Resultado possível |
|---|---|---|---|
| 1 | MCP de banco conectado | Existe ferramenta de consulta/leitura para o banco requerido | Validação automática; escritas autorizadas pelo mesmo MCP |
| 2 | Adapter local aprovado | Há `sqlcmd`, `sqlplus`, driver/cliente já instalado ou script oficial do repositório capaz de executar consulta parametrizada | Validação automática local; escritas somente após autorização explícita |
| 3 | Pacote de evidência manual | Não há MCP nem adapter local, mas o usuário possui acesso a um cliente de banco autorizado | A skill gera SQL de leitura e aguarda resultado/screenshot/export verificável |
| 4 | Sem caminho de acesso | Não há conexão, cliente, script oficial nem evidência manual | `BLOQUEADO` com diagnóstico objetivo |

### Bootstrap seguro

Na primeira execução, ou quando o adapter salvo não funcionar:

1. Descubra as ferramentas disponíveis e os arquivos de configuração já existentes no ambiente. Procure somente nomes de executáveis, aliases, host/banco/schema não sensíveis e nomes de variáveis; nunca exiba senha, token ou connection string completa.
2. Para SQL Server, considere um cliente/adapter local já instalado, como `sqlcmd`, ODBC ou um script oficial do projeto. Para Oracle, considere `sqlplus`, ODP.NET/driver já instalado ou um script oficial do projeto. Os nomes são exemplos; confirme a existência real antes de usar.
3. Se houver exatamente um caminho local compatível, crie ou atualize apenas uma configuração local não sensível em `./.claude/qa-arquitetura/validacao-banco.local.json` (ou em `./ciclos-execucao/.config/validacao-banco.local.json` se o primeiro caminho não for gravável). Grave somente `tipo`, `executavel`, `alias`, `ambiente`, `banco/schema` não sensíveis, `modo: read-only` e os nomes das variáveis que fornecerão os segredos.
4. Nunca altere a configuração global de MCP, instale driver, crie usuário de banco, peça senha em texto livre ou grave credenciais no repositório sem uma solicitação explícita do usuário e um mecanismo seguro de segredo.
5. Faça um probe read-only com o adapter local. Se funcionar, registre `método = ADAPTER_LOCAL`, a ferramenta usada e a data; não registre a linha de comando completa quando ela contiver segredo.
6. Se mais de um adapter for encontrado, escolha o que já estiver documentado pelo projeto; se não houver preferência, apresente as opções e peça uma escolha antes de conectar. Não testar clientes aleatórios contra hosts desconhecidos.
7. Se nenhum adapter funcionar, gere o pacote manual em `$ENV_VALIDATION_DIR/sql/00-validar-ambiente-oracle.sql` e/ou `00-validar-ambiente-sqlserver.sql`, com consultas somente leitura e placeholders para o usuário preencher no cliente autorizado. O relatório fica `PAUSADO — aguardando evidência manual`, não `LIBERADO`.
8. Aceite evidência manual somente se ela identificar banco/schema/ambiente, data/hora, consulta executada e resultado suficiente para cada requisito. Um “funcionou” sem saída, arquivo, captura ou export verificável não libera a rodada.

O bootstrap é local e reversível. Ele não configura automaticamente o MCP global porque esse registro pertence ao ambiente do usuário e pode exigir credenciais, permissões ou reinício do host. Depois que o adapter local estiver salvo, as próximas execuções tentam reutilizá-lo e fazem um probe read-only antes de confiar nele.

## Guardrails de banco e segurança

- Nunca usar produção. Se o ambiente, host, banco ou schema não puder ser identificado como não produtivo, pare e peça confirmação; não faça probe nem escrita.
- Nunca copiar, exibir ou registrar senhas, tokens, connection strings completas ou dados pessoais desnecessários. Use a configuração segura já conectada ao MCP, cofre ou variáveis de ambiente em tempo de execução.
- Leituras de metadados e dados de validação podem ser feitas sem autorização adicional, desde que o ambiente já esteja identificado como não produtivo e o escopo seja o mapa da rodada.
- `INSERT` e `UPDATE` para criar massa exigem autorização explícita antes da execução. A autorização deve ser específica para ambiente, banco, schema/objeto, operação, filtro/identificador da execução, quantidade esperada, finalidade, impacto e rollback.
- `DELETE`, truncamento, limpeza de massa existente, alteração de configuração e qualquer operação irreversível exigem autorização explícita separada para aquele comando. Sem ela, mantenha `BLOQUEADO`.
- As escritas devem ser idempotentes quando possível, usar um marcador único da execução (`$RUN_ID`), limitar o escopo aos registros da rodada e ser executadas somente pelo MCP de banco disponível. Não usar REST, PAT, scripts ad hoc ou acesso alternativo para contornar um MCP ausente.
- Antes de qualquer escrita, reúna a lista completa de massas faltantes. Solicite uma autorização consolidada, mas descreva cada operação individualmente; a autorização não vale para outro ambiente, objeto ou operação não listados.
- Após cada criação, releia os registros pelo MCP e confirme os vínculos, estados, quantidades e chaves usados pelos cenários. Falha na confirmação mantém a rodada bloqueada.
- Registre os identificadores criados, os comandos/planos aplicados sem segredos, a quantidade esperada, a verificação e o plano de limpeza em `$MASSA_MANIFEST`. Não apague a massa antes da execução dos testes.

## Descoberta e uso dos MCPs

### Step 0 — Descobrir capacidades sem inventar ferramentas

1. Confirme `mcp__azure-devops` com uma leitura de work item. Um `404` para um ID inexistente confirma que o servidor está vivo; não confunda `404` com falha de conexão.
2. Descubra, no conjunto de ferramentas MCP conectado à sessão, os recursos de banco disponíveis para **consulta de Oracle** e **consulta de SQL Server**. Os nomes exatos são os fornecidos pelo ambiente; exemplos como `mcp__oracle__query` ou `mcp__sqlserver__query` são apenas ilustrativos e não devem ser inventados.
3. Se não houver MCP para algum banco exigido, execute o bootstrap de primeira execução e procure um adapter local aprovado. A ausência do MCP, isoladamente, não bloqueia.
4. Se houver adapter local, confirme que ele oferece leitura/consulta e que usa configuração segura. Se não houver MCP nem adapter, gere o pacote de evidência manual e marque `PAUSADO`; só classifique `BLOQUEADO` quando não houver nenhum caminho viável ou quando a evidência manual não for entregue.
5. Não instale drivers, altere configuração global de MCP, use REST/PAT ou execute cliente contra host desconhecido como atalho. `sqlcmd`, `sqlplus`, drivers locais e scripts oficiais são permitidos somente quando encontrados/configurados no ambiente e registrados como adapter aprovado.
6. Registre no relatório o método real (`MCP`, `ADAPTER_LOCAL` ou `EVIDENCIA_MANUAL`), sem registrar credenciais ou parâmetros sensíveis.

### Step 1 — Resolver história, mapa e contexto

Use somente MCP Azure DevOps para localizar os itens.

1. Parseie `$ARGUMENTS` mantendo nomes de projeto com espaços:

   ```text
   $parts     = "$ARGUMENTS".Trim() -split '\\s+'
   $itemId    = $parts[0]
   $ambiente  = if ($parts.Count -gt 2) { $parts[-1] } else { "HMG" }
   $project   = se houver projeto entre o ID e o ambiente, preserve o texto completo
   $RUN_ID    = data/hora + ID da história + identificador curto da execução
   ```

2. Chame `mcp__azure-devops_wit_get_work_item` ou a ferramenta equivalente realmente disponível, com `expand: "all"`.
3. Se o item for uma User Story/PBI, localize entre os filhos `System.LinkTypes.Hierarchy-Forward` o item cujo `System.WorkItemType` seja exatamente `Criar Mapa de Teste`. Se houver mais de um, pare e peça a escolha; nunca escolher silenciosamente um mapa antigo.
4. Se o item já for `Criar Mapa de Teste`, use-o diretamente e localize a história pai quando disponível.
5. Se não houver mapa publicado, pare com `BLOQUEADO — mapa de testes ausente`. Não crie nem altere o mapa nesta skill.
6. Capture `$STORY_ID`, `$STORY_TITLE`, `$MAPA_ID`, `$MAPA_CHANGED_DATE`, `$DESCRIPTION_HTML`, `$STORY_PROJECT` e `$STORY_RELATIONS`.
7. Releia, quando existirem, o relatório de análise técnica e o card `Análise` da história. Use-os para identificar componentes, versão, legado/novo, jobs, integrações e bancos; quando houver conflito, o mapa e a configuração atual do ambiente precisam ser revalidados, nunca substituídos por memória.
8. Consulte `./aprendizados/COMO-USAR.md` e os aprendizados relacionados à história, componente e ambiente. Registre `$APRENDIZADOS_CONSULTADOS`, mas revalide qualquer massa/configuração antes de usá-la.

### Step 2 — Montar o inventário de requisitos

Parseie a tabela de cenários do mapa sem transformar hipótese em requisito confirmado. Para cada cenário, crie uma entrada `$REQUIREMENTS` com:

- número, categoria e título do cenário;
- camada/componente e origem da evidência;
- banco requerido: `ORACLE`, `SQL SERVER`, `AMBOS`, `NÃO APLICÁVEL` ou `NÃO VALIDADO`;
- ambiente, build/branch/commit, serviço, worker/scheduler, configuração e integração exigidos;
- entidades/tabelas/objetos, colunas, chaves, relacionamentos, estados, timestamps, volumes, arquivos, usuários/perfis e dados negativos necessários;
- estado inicial, resultado observável e consultas de verificação;
- seed/fixture/script autorizado existente, se o mapa ou o repositório fornecer um;
- dependências e plano de restauração/limpeza.

Regras para identificar a massa:

- O mapa de testes, a análise do dev, o PR/diff e a configuração real são fontes de evidência. Não invente tabela, coluna, status, ID, conta ou regra.
- Se o cenário disser apenas “ter dados disponíveis”, sem permitir identificar o dado de modo verificável, marque `NÃO VALIDADO` e bloqueie até obter a especificação ou descobrir a massa por leitura controlada do schema.
- Para cenários Legado/Novo ou de paridade, valide as massas nos dois lados e registre que relógio, configuração, estado inicial e volume precisam ser comparáveis.
- Para cenários sem persistência/banco, marque `NÃO APLICÁVEL` com justificativa. Para cenários que observam ou preparam banco, nunca marque `NÃO APLICÁVEL` por conveniência.
- Uma massa pode ser reutilizada somente depois de confirmada no contexto atual. Não reutilize IDs ou registros de ciclos anteriores sem nova consulta.

### Step 3 — Validar ambiente e conectividade

Execute apenas leituras/probes seguros nesta etapa:

1. Confirme que o ambiente é HMG/QA/local não produtivo, a URL e o build/commit correspondem ao escopo do mapa e os serviços necessários estão ativos. Use o MCP ou fonte de observabilidade configurada; se não houver como comprovar, marque `PENDENTE`.
2. Para Oracle, pelo adapter selecionado (`MCP`, `ADAPTER_LOCAL` ou evidência manual), confirme conexão, usuário/schema efetivo sem expor senha, versão, acesso de leitura e o schema dos objetos necessários. Prefira metadados equivalentes a `ALL_TABLES`, `ALL_TAB_COLUMNS` e `ALL_CONSTRAINTS`, adaptados ao mecanismo usado; não assuma que o schema do ambiente de referência é o atual.
3. Para SQL Server, pelo adapter selecionado (`MCP`, `ADAPTER_LOCAL` ou evidência manual), confirme conexão, banco/schema efetivo, versão, acesso de leitura e os objetos necessários. Prefira metadados equivalentes a `sys.tables`, `sys.columns`, `sys.foreign_keys` ou `INFORMATION_SCHEMA`, adaptados ao mecanismo usado.
4. Confirme serviços, jobs, workers, filas, integrações, feature flags e parâmetros somente quando forem requisitos de algum cenário. Ausência de evidência é `PENDENTE`, não `OK`.
5. Classifique cada requisito de ambiente como `OK`, `NÃO APLICÁVEL`, `PENDENTE`, `INCONCLUSIVO` ou `BLOQUEADO`, sempre com fonte, consulta/probe, timestamp e evidência resumida.

### Step 4 — Conferir massas existentes

Para cada item de `$REQUIREMENTS` aplicável:

1. Faça primeiro uma consulta de presença/contagem com filtro específico da massa. Depois, confirme os campos críticos, relacionamentos, status, datas, usuário/perfil e ausência de duplicidade.
2. Para dados de volume, confirme a quantidade mínima e a distribuição exigida; uma contagem total sem conferir os estados necessários não valida a massa.
3. Para massas negativas, confirme a condição inválida real e que não existe um registro concorrente que torne o caso positivo.
4. Para múltiplos usuários, confirme cada conta, perfil, área, permissões e isolamento exigidos; não deduza permissão pelo nome do usuário.
5. Para jobs e estados temporais, confirme timestamps e relógio/fuso usados pelo cenário; não declare massa pronta se o job ou o mecanismo de avanço de tempo não estiver demonstrado.
6. Para Oracle e SQL Server, execute as verificações separadamente. `OK` em um banco não cobre o outro. Evidência manual só vale para o banco/schema e o conjunto de consultas que ela comprovar.
7. Registre uma linha por requisito em `$MASSA_MATRIX` com `EXISTENTE E CONFIRMADA`, `AUSENTE`, `INCOMPATÍVEL`, `NÃO VALIDADA` ou `NÃO APLICÁVEL`, incluindo IDs/quantidades não sensíveis e consulta de verificação.

### Step 5 — Criar massas ausentes, quando autorizado

Se existir qualquer item `AUSENTE` ou `INCOMPATÍVEL`:

1. Identifique se há seed/fixture/script oficial já previsto no mapa, no PR ou na documentação do ambiente. Se houver, prefira-o; se não houver, descreva o plano mínimo de criação sem inventar a modelagem.
2. Apresente antes da escrita uma solicitação específica contendo, para cada operação: `$RUN_ID`, ambiente, banco, schema, tabela/objeto, operação, campos/valores sem segredos, filtro/relacionamento, quantidade esperada, finalidade, impacto, validação e rollback/limpeza.
3. Aguarde autorização explícita. Sem autorização, o status geral é `BLOQUEADO — massa ausente e criação não autorizada`.
4. Após autorização, execute pelo MCP ou pelo adapter local aprovado, em transação quando suportado, usando chaves/marcadores da execução. Não misture Oracle e SQL Server em uma operação não transacional entre bancos; registre a ordem e o ponto de falha. O pacote manual é read-only e não pode ser usado para escrita automática.
5. Reconsulte cada massa criada com as mesmas verificações do Step 4. Se qualquer verificação falhar, não prossiga para testes.
6. Registre no `$MASSA_MANIFEST` os IDs/chaves criados, a quantidade, o banco, a verificação e o plano de limpeza. O manifest não pode conter senha, token ou dados pessoais além do mínimo necessário para rastrear o cenário.
7. Se a criação exigir `DELETE`, truncamento ou alteração de registros preexistentes, pare e solicite autorização separada. Nunca “limpe para tentar de novo” por inferência.

### Step 6 — Emitir o gate e salvar o relatório

O status geral deve ser:

- `LIBERADO PARA EXECUÇÃO`: todas as verificações aplicáveis estão `OK` ou `CRIADA E CONFIRMADA`, nenhum requisito está `PENDENTE`, `INCONCLUSIVO`, `AUSENTE`, `INCOMPATÍVEL` ou `NÃO VALIDADO`, e o relatório foi salvo.
- `BLOQUEADO`: existe qualquer requisito ausente, inconsistente, não comprovado, nenhum caminho de acesso viável, ambiente não confirmado, autorização pendente ou falha de criação/verificação.
- `PAUSADO`: aguarda escolha de adapter, configuração segura ou evidência manual/autorização explícita do usuário; não significa que a execução está liberada.

Defina o diretório do ciclo antes de gerar o relatório ou os SQLs de evidência manual:

```text
$ENV_VALIDATION_DIR  = ./ciclos-execucao/<task>-US<story>
$ENV_VALIDATION_FILE = $ENV_VALIDATION_DIR/00-validacao-ambiente.md
```

Salve o relatório completo em:

```text
$ENV_VALIDATION_FILE = $ENV_VALIDATION_DIR/00-validacao-ambiente.md
```

Inclua no relatório:

```text
# Validação de ambiente — US #<STORY_ID> / Mapa #<MAPA_ID>

**Status do gate:** LIBERADO PARA EXECUÇÃO | BLOQUEADO | PAUSADO
**Ambiente:** <nome e URL não sensível>
**Banco(s):** Oracle | SQL Server | ambos | não aplicável
**Build/commit:** <valor confirmado ou pendência>
**RUN_ID:** <identificador>
**Validade do relatório:** mapa #<MAPA_ID> com ChangedDate <data>, ambiente <nome>, banco/schema <identificador não sensível>

## Resumo
| Dimensão | Status | Evidência | Pendência |
|---|---|---|---|
| MCP Azure DevOps | ... | ... | ... |
| Acesso Oracle (MCP/adapter/evidência) | ... | ... | ... |
| Acesso SQL Server (MCP/adapter/evidência) | ... | ... | ... |
| Ambiente/build | ... | ... | ... |
| Serviços/configuração | ... | ... | ... |
| Massas | ... | ... | ... |

## Matriz de massas
| Cenário | Banco | Requisito de massa | Verificação | Resultado | IDs/quantidade | Evidência |
|---|---|---|---|---|---|---|

## Massas criadas nesta execução
| RUN_ID | Banco | Objeto | Operação autorizada | IDs/chaves | Quantidade | Verificação | Limpeza/rollback |
|---|---|---|---|---|---:|---|---|

## Pendências bloqueantes
- <item, tentativa realizada, evidência, ação necessária e condição objetiva de liberação>

## Decisão
<LIBERADO PARA EXECUÇÃO ou BLOQUEADO, com a condição objetiva para retomar>
```

Ao salvar, inclua uma assinatura simples de contexto (ID do mapa, `System.ChangedDate`, ambiente, build/commit e identificadores não sensíveis de banco/schema). O executor deve comparar esses valores antes de iniciar; se algum mudou, a validação expirou e esta skill deve ser rodada novamente.

Registre uma linha em `./log/LOG-ACOES.md` com a ação `/arquitetura-validar-ambiente`, o mapa/US, ambiente, bancos, status do gate, arquivo do relatório e massas criadas. Nunca sobrescreva o log.

## Contrato com `/arquitetura-executar-teste`

Antes de qualquer login, navegação ou step de teste, `/arquitetura-executar-teste` deve:

1. localizar `$ENV_VALIDATION_FILE` do mesmo ciclo;
2. confirmar que o status é exatamente `LIBERADO PARA EXECUÇÃO`;
3. comparar mapa, `ChangedDate`, ambiente, build/commit e banco/schema com o contexto atual;
4. conferir que todas as massas do manifest continuam presentes por leitura;
5. se o arquivo faltar, estiver expirado ou qualquer massa tiver mudado, invocar novamente esta skill e aguardar liberação.

A execução não pode contornar o gate dizendo que o cenário é independente ou que a massa poderá ser criada durante o teste. Se o teste descobrir uma nova necessidade de escrita, ele deve pausar e voltar ao fluxo de autorização de banco.

## Fora de escopo

- Executar UI, API, jobs ou cenários do mapa.
- Criar ou publicar mapa de testes no Azure DevOps.
- Alterar configuração de aplicação, serviço ou banco sem autorização específica.
- Validar produção ou copiar massa de produção.
- Declarar que um cenário passou; isso pertence exclusivamente à skill de execução com evidência funcional.

## Troubleshooting

- **MCP de banco ausente:** execute o bootstrap. Procure um adapter local aprovado; se não houver, gere o pacote read-only de evidência manual. Só bloqueie quando não houver caminho viável ou a evidência entregue for insuficiente.
- **Nenhum cliente local encontrado:** não instale automaticamente. Gere os SQLs de validação, registre `PAUSADO` e informe quais consultas o usuário precisa executar em um cliente autorizado.
- **Adapter local encontrado, mas sem credencial:** não peça segredo em texto livre. Informe os nomes das variáveis/alias esperados e aguarde que o usuário configure o mecanismo seguro; depois repita o probe read-only.
- **Schema/tabela não encontrado:** confirme conexão, banco e schema efetivos; só depois conclua que a massa está ausente. Se a divergência persistir, `BLOQUEADO`.
- **Mapa sem SQL, dados ou pré-condições suficientes:** não invente massa. Liste o requisito não especificado e peça atualização do mapa ou decisão do responsável.
- **Massa existe, mas estado/relacionamento diverge:** classifique `INCOMPATÍVEL`; não “ajuste” registro preexistente sem autorização de `UPDATE` específica.
- **Criação parcialmente concluída:** pare, registre os IDs criados e o ponto de falha, faça somente rollback autorizado e não declare liberação.
- **Relatório antigo:** qualquer mudança no mapa, build, ambiente, banco/schema, serviço ou manifest invalida a liberação; rode a validação novamente.
- **Credenciais ausentes ou inválidas:** não registre o segredo; classifique o requisito como `BLOQUEADO` e peça a credencial pelo mecanismo seguro configurado.

