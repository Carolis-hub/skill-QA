# Execução — Mapa de Testes #164885 (US 164849, BE via API)

**Ambiente:** HMG (http://localhost:8080/smartshare/), banco interno Oracle. Execução: 2026-11-06, Rodada 1 (funcional).
**História relacionada:** #164849 Migração tela de gerenciamento | Gerenciamento de índice (BE) | Lançamento e integração
**Forma de execução (US de BE):** chamadas HTTP à API `/smartshare/api/api/TipoIndice`, `/Conexao` com a sessão do `Claude-adm` (admin) e, nos cenários de permissão, com a sessão do `qa.publicador.us163012`. O Swagger do backend (`:8081/swagger/v1/swagger.json`) foi usado para descobrir endpoints (`PUT /TipoIndice`, `POST /TipoIndice/TestarSql`, `GET /Conexao/{cd}/Perfis`, `POST/PUT /TipoIndice/Opcoes`).
**Limites:** sem acesso de leitura ao banco nem a `LOG_APLICACAO`; build da US não confirmado (sem PR vinculado, versão do front 4.13.13). Resultados com `*` têm ressalva descrita na coluna Obtido.

## Resumo
- Cenários no mapa: 73 linhas (#1 a #73; o título do card diz 72 porque o #56 é N/A de concorrência)
- Executados: 66 (65 `Passou`, 0 `Parcial`, 1 `Falhou`); o #49 passou de `Parcial` para `Passou*` ao aplicar o APR-013, o #62 foi executado depois da troca do banco para SQL Server, as hipóteses #66, #68, #72 e #73 passaram, e o #70 foi executado e passou com ressalva (ver a seção das hipóteses)
- Falhou: 1 (#53, com a regra legada a confirmar: ver o detalhe)
- Não executado: 7 (#56 N/A, #63, #64, #65, #67, #69 e #71)
- Achados: 1 pendente de decisão do dev/PO (A) e 1 retirado (B, era efeito do depurador; ver "Achados")

## Detalhe por cenário executado
| # | Cenário | Obtido | Resultado |
|---|---|---|---|
| 1 | Fixo no lançamento ligado | POST 200, cd 1220; GetOne `st_fixo_lancamento` = 1 | Passou |
| 2 | Fixo desligado | cd 1221; GetOne = 0 | Passou |
| 3 | Permitir edição desligado | cd 1222; `st_permitir_edicao_lancamento` = 0 grava `st_desabilita_lancamento` = 1 | Passou |
| 4 | Permitir edição ligado e leitura inversa | cd 1223; desabilita = 0 e permitir = 1 na leitura | Passou |
| 5 | Valor inicial Letras e Números | cd 1224; "ABC 123 xyz" gravado | Passou |
| 6 | Valor inicial Números | cd 1225; "12345" | Passou |
| 7 | Valor inicial Data fixa | cd 1226; "15/03/2026" (formato dd/mm/aaaa; a hora zerada não é observável pela API) | Passou* |
| 8 | Valor inicial Data Atual | cd 1227; `[DT_ATUAL]`, desabilita = 1 e permitir = 0 mesmo enviando permitir = 1 e desabilita = 0 | Passou |
| 9 | Seleção com código válido | Seleção 1233 com valores 1 e 2; PUT com ini 2 grava "2" | Passou |
| 10 | Seleção sem valor inicial | PUT com ini vazio grava NULL, 200 | Passou |
| 11 | Informado + Consulta com conexão e SQL | cd 1235; `cd_conexao` 1 e `ds_sql` gravados, DI = 5 | Passou |
| 12 | Lista de conexões por perfil | `TipoIndice/Conexoes` devolve `[null,142,82,122,202,1,2,103]`: primeiro item vazio, sem duplicar, sem a 183 (sem perfis) nem a 242 (inativa, sem perfis) | Passou |
| 13 | SQL com apóstrofos | cd 1236; `'O''Brien'` e `'D''Agua'` devolvidos idênticos | Passou |
| 14 | Modo Parcial (1) | cd 1237; `id_tipo_comparacao` = 1 | Passou |
| 15 | Modo Total (2) | cd 1238; = 2 | Passou |
| 16 | Modo Selecione | cd 1239; grava 0 (não NULL) | Passou |
| 17 | Modo lido do formulário de inclusão | POST com modo 2 grava 2 (cd 1238). A distinção "formulário de inclusão × de detalhes" é do Clássico/FE e não existe na API | Passou* |
| 18 | Testar SQL | `SELECT ds_usuario FROM USUARIO` na conexão 1: 200 em 238 ms, `campos`, `linhas`, `total` 605, `hasMore`; página 1 traz 5 linhas | Passou |
| 19 | Filtro com WHERE existente | `... WHERE cd_usuario > 0` + filtro texto: 200, total 1 (filtro aplicado, sem erro de sintaxe). O trecho final `1 = 1` não é observável | Passou* |
| 20 | Filtro sem WHERE | 200, total 1 | Passou* |
| 21 | Tags `<campo id=...>` substituídas | `WHERE ds_usuario = '<campo id="100" />'` + `valoresIndices {"100":"Claude-adm"}`: total 1, linha "Claude-adm" | Passou |
| 22 | Filtro inteiro e decimal | filtro `cd_usuario` = "1" devolve só a linha 1 (comparação `=`, não LIKE). No Oracle as duas colunas são do tipo "decimal" na API, então inteiro × decimal não se distingue | Passou* |
| 23 | Filtro de texto, modo Total | modo 2, "Usuario T": 0 linhas (igualdade) | Passou |
| 24 | Filtro de texto, modo Parcial | modo 1: 4 linhas (LIKE) | Passou |
| 25 | Filtro de texto, modo 0 ou ausente | modo 0 e modo nulo: 4 linhas cada (LIKE) | Passou |
| 26 | Data Atual trocada por "Outro" | PUT no cd 1227: desabilita 1 → 0, permitir 0 → 1, ini "20/04/2026" | Passou |
| 27 | Tag sem valor preenchido | `valoresIndices {}`: total 0 (tag trocada por vazio). Evidência indireta (não vejo o SQL final) | Passou* |
| 28 | Específico e Múltipla Seleção | cd 1228 e 1229: valor inicial "xyz" ignorado (NULL) e desabilita = 0 | Passou |
| 29 | Tipo diferente de Informado | cd 1240 (Específico) com `cd_conexao` 1 e SQL: GetOne devolve `cd_conexao` e `ds_sql` NULL | Passou |
| 30 | Inclusão de Seleção sem códigos | `ValoresIniciais` (com 0 e sem parâmetro): 200 e lista vazia | Passou |
| 31 | Registro legado com SQL inválido | índice 1131 (Consulta sem conexão e sem SQL): GetOne 200 abre; PUT sem alterar → 500 "Por favor, preencha uma conexão." (o erro aparece só ao salvar) | Passou |
| 32 | Modo sem conexão | cd 1241: modo 2 sem conexão grava 0 | Passou |
| 33 | Modo com Tipo de valor ≠ Letras e Números | cd 1242 (Números, modo 2): grava 0 | Passou |
| 34 | Leitura do modo de comparação | GetOne devolve o valor gravado (0, 1 e 2 nos cd 1239, 1237 e 1238). A regra de exibição do campo é de FE | Passou* |
| 35 | Números com letras | 500 "Somente números"; nada gravado | Passou |
| 36 | Letras e Números com 50 caracteres | cd 1230; 50 caracteres gravados | Passou |
| 37 | Data vazia | 500 "Por favor, selecione uma data inicial."; nada gravado | Passou |
| 38 | Seleção com código de outro tipo | código 3 (só no tipo B) e 99 (inexistente): 500 "Valor inicial inválido: selecione um valor cadastrado deste tipo de índice."; valor continua "2" | Passou |
| 39 | Consulta sem conexão | 500 "Por favor, preencha uma conexão."; nada gravado | Passou |
| 40 | Consulta sem SQL | 500 "Por favor, preencha um comando SQL para consulta."; nada gravado | Passou |
| 41 | Conexão sem vínculo ao salvar | conexão 183 (`Perfis` vazio): 500 "Conexão não permitida para o usuário."; nada gravado | Passou |
| 42 | Comandos proibidos ao salvar | INSERT, UPDATE, DELETE, DROP, ALTER, CREATE, TRUNCATE, MERGE e EXEC (todos sobre `QA_US164849_INEXISTENTE`): 9 × 500 "Somente comandos SELECT são aceitos."; nenhum registro criado | Passou |
| 43 | Mais de um comando (;) | `SELECT ...; DELETE FROM QA_US164849_INEXISTENTE`: 500 com a mesma mensagem | Passou |
| 44 | Comando proibido ao testar | TestarSql com DELETE no alvo inexistente: 500 "Somente comandos SELECT são aceitos." em 22 ms (não chegou ao banco) | Passou |
| 45 | SELECT válido com espaços, comentário e minúsculas | cd 1243: aceito; SQL gravado íntegro (`/* comentario */ select ... '<campo id="100" />'`) | Passou |
| 46 | Validação sem o front-end | todas as chamadas dos cenários acima foram feitas direto na API | Passou |
| 47 | Sem sessão válida | sem cabeçalhos: GET e POST 403; Bearer inválido 403 (CA95 aceita 401/403; o texto do mapa diz 401) | Passou* |
| 48 | Sem permissão no menu de Configurações | `qa.publicador.us163012`: listar, GetOne, Conexoes, incluir, alterar, excluir e TestarSql todos 403 (controle: o `Claude-adm` pelo mesmo caminho recebe 200) | Passou |
| 49 | Sem permissão de gerenciar índices | Aplicado APR-013 (a regra do Clássico vale: "com permissão" = tipo Administrador, `BasePageTG.cs:validaSessao`; "sem permissão" = qualquer outro tipo). `qa.publicador.us163012` (tipo 2): incluir, alterar e excluir bloqueados (403). O usuário também não acessa a listagem: pela regra do Clássico, só o administrador abre essa tela, então o trecho "mesmo vendo a listagem" do mapa não é atingível (defeito de redação do mapa, a corrigir no `/gerar-mapa-testes-v3`) | Passou* |
| 50 | Conexão sem leitura ou inativa | 242 (inativa) e 183 não aparecem na lista. As duas não têm perfis, então não prova sozinho o caso `st_leitura` = 0 | Passou* |
| 51 | Conexão sem vínculo na lista | 183 (`Perfis` vazio) não aparece | Passou |
| 52 | Conexão sem duplicar | conexão 263 vinculada a 3 perfis aparece uma única vez na lista do admin e do `qa.admin2`. Que o usuário pertença a 2 ou mais desses perfis é inferido | Passou* |
| 53 | Usuário sem conexões | Massa criada seguindo a regra legada (APR-015): perfil 12027 (sem nenhuma conexão vinculada, confirmado nas 12 conexões) e usuário `qa.semconexao.us164849` (cd 9022, Administrador, área principal 12027); o backend reproduziu o `InserePerfil` do Clássico: leitura só no 12027 (`Usuario.aspx.cs:2592-2617`). `GET TipoIndice/Conexoes` com esse usuário devolveu **`[vazio, 142, 82, 202, 1, 103]`**, e o esperado era só o item vazio. As 5 conexões chegam pelos **perfis pais** do usuário (as linhas de navegação, `st_navegacao = 1`) | **Falhou** (regra a confirmar). **Análise de falha (2026-11-06) REVISTA no mesmo dia:** o veredito "NÃO" abaixo foi dado com base na cópia `WebApplication` do Clássico. No host de referência (`SmartShareWeb/Gerenciamento/TipoIndiceForm.ascx.cs:34-53 e 863-899`) a lista usa só os perfis do usuário com `StLeitura` (as linhas de navegação dos pais ficam de fora) e o CA42 diz "perfis do usuário com permissão de leitura". Logo o esperado do mapa ("só o item vazio") é o do Clássico e **o veredito passa a SIM (evidência suficiente para Bug)**, pendente de aprovação para gerar o defeito. Texto original da análise: veredito NÃO para abrir Bug. Causa comprovada: a cadeia do usuário é `12027 → RH_TESTE 11107 → RHteste 9388 → Geral 1`, e as conexões que apareceram (142, 82, 202, 1, 103) são exatamente as ligadas a 9388 e a Geral; as que não aparecem (122, 2, 263) não têm vínculo com a cadeia. O card de Análise do dev (#164863) define a regra como "perfis do usuário (`PERFIL_USUARIO`) → `PERFIL_CONEXAO` com `st_leitura = 1` → `CONEXAO` com `st_ativo = 1`", e `PERFIL_USUARIO` inclui as linhas de navegação dos pais (`st_navegacao = 1`, `Usuario.aspx.cs:2607`). O BE segue essa descrição. Falta decisão do dev/PO sobre se as linhas de navegação contam. Como todo perfil descende de Geral e Geral tem conexões, o pré-requisito do #53 ("perfis sem vínculo a nenhuma conexão") não é atingível enquanto os pais contarem |
| 54 | Valor inicial vazio | cd 1231 (null) e 1232 (vazio): ambos gravam NULL e a leitura devolve null | Passou |
| 55 | Legado com modo 0 e valor inicial nulo | índice 124 (modo 0, ini nulo): PUT com os mesmos valores → 200 e nenhum campo diferente no GetOne | Passou |
| 57 | Credencial inválida | conexão 263 (criada): TestarSql 500 em 7,9 s "Não foi possível conectar ao banco de dados da conexão selecionada."; sem usuário, senha, servidor, SQL ou pilha na resposta | Passou |
| 58 | Banco indisponível | conexão 202 (PostgreSQL inacessível): 500 em 0,7 s com a mesma mensagem, sem vazamento | Passou |
| 59 | SQL com sintaxe inválida | `SELECT x FROM`: 500 "Erro ao executar o SQL. Verifique o comando e tente novamente." (legível, sem pilha). Levou 43,7 s na primeira medição, o que se mostrou efeito do depurador anexado (ver Achado B retirado); sem ele, 0,7 a 0,9 s | Passou* |
| 60 | Erro técnico padronizado | #57, #58 e #59: mensagem padronizada; checagem de termos sensíveis (usuário, senha, servidor, `ORA-`, `Exception`, pilha, SQL) vazia nos dois primeiros | Passou |
| 61 | Filtro sem injeção de SQL | filtro `' OR '1'='1` no modo 2: 200, 0 linhas, sem erro | Passou |
| 62 | SQL Server e Oracle idênticos | **Banco interno em SQL Server** (usuária trocou o ambiente; login com o `root`, a senha não foi gravada). Repeti no SQL Server as mesmas chamadas do Oracle: 10 inclusões (fixo, permitir edição, valor inicial de texto, data fixa e `[DT_ATUAL]`, SQL com apóstrofos, modos de comparação 0 e 2, modo zerado com Tipo de valor Números, Específico com conexão e SQL nulos) e 8 rejeições (Números com letras, data vazia, consulta sem conexão e sem SQL, INSERT, `;`, 51 caracteres, conexão sem vínculo): **0 divergências** de valores gravados e de mensagens literais. Chave gerada: `POST` devolve o código, o `GetOne` confere, e os códigos 68 a 77 saíram em sequência. Paginação da listagem de índices (75 registros): páginas de 5 em ordem crescente e decrescente, sem repetição, última página com 5, página além da última vazia (200), `hasMore` coerente. Paginação do Testar SQL em banco externo **Oracle** (conexão 3, a partir do SQL Server interno): 20 valores em 4 páginas, sem repetição e em ordem, total 608. **Paginação do Testar SQL em banco externo SQL Server (verificada depois, com a conexão de teste 36, criada com os dados da conexão 1 e a senha informada pela usuária, ligada ao perfil 326 só durante o teste):** 4 páginas de 5 sobre `sys.objects`, sem repetição e em ordem; filtro inteiro por `=` (1 linha), texto por `LIKE` no modo 1 (82) e por igualdade no modo 2 (0), injeção tratada como texto (0 linhas). **Mesmo comportamento do Oracle externo** (`all_objects`): total 1000 com `totalExcedeLimite: true`, última página alcançável (índice 199) com 5 linhas e `hasMore: true`, página seguinte vazia. Observação: o limite de 1000 linhas existe nos dois bancos; com ele, `hasMore` fica `true` na última página alcançável e a seguinte vem vazia (a regra não está na US). As conexões 4 e 17 seguem inacessíveis (`OleDbException`: "SQL Server inexistente ou acesso negado"), mas não eram necessárias | Passou |

## Não executados
| # | Motivo | Categoria |
|---|---|---|
| 56 | N/A no mapa (concorrência) | — |
| 63 | As conexões PostgreSQL (103 e 202) não conectam. Causa confirmada pela pilha do backend (informada pela usuária): `OdbcException IM002`, "Nome da fonte de dados não encontrado e nenhum driver padrão especificado" em `ExternalDatabaseRepository.cs:27`, isto é, o servidor da API não tem o driver ODBC ou o DSN do PostgreSQL. O cliente recebe só "Não foi possível conectar ao banco de dados..." (sem vazamento). Repetido mais tarde e de novo com a conexão 2 (PostgreSQL visível ao `root`, SQL Server interno): igual (2,3 s) | ambiente |
| 64 | Repetido após a usuária avisar que o BE do BPM subiu: `/Share4/be/bpmApi/` responde (403), mas o front `/bpm` segue 502, e o ECM-BE e o `SmartShareAPI` também (502). Apuração no código (hub, `main`, sem os commits da US): os consumidores do componente compartilhado ficam no net8, sem endpoint HTTP (147 rotas no Swagger, nenhuma de agente ou comitê): `AgentBpmService` (passo de banco de dados: `ExecuteWorkflowFirstRow` e `ExecuteWorkflowNonQuery`, ambos com `validateSingleColumnScript: false`, `AgentBpmService.cs:1336/1354`, então **não** passam pela validação de SELECT) e `ComiteService` (`ExecuteWorkflowQuery`, `ComiteService.cs:125`, sem o flag, então passa pela validação `ExternalDbSqlIntercept`, `DBTranslator.cs:334-339`). Risco de regressão: o Comitê, se a US mudou a validação compartilhada; o passo de banco do Workflow está isolado pelo flag. Para executar é preciso um processo com esses passos, o front do BPM (ou a API do BPM-BE) e o agente do net8 rodando. Execução do passo de banco pode gravar no banco externo (alto risco, exige confirmação). **Encaminhado ao dev por decisão da usuária (2026-11-06)**: validar na máquina dele, com os commits da US, o passo de banco do Workflow e a consulta externa do Comitê | ambiente (com o dev) |
| 65 | Exige abrir o Lançamento de Documentos (tela): cenário de FE em US de BE (defeito do mapa). Prova de back-end feita à parte (não substitui o cenário): num índice de teste (cd 68), alternar `st_fixo_lancamento` muda **só** esse campo no `GetOne` e **nenhum** campo na listagem; o registro foi restaurado e conferido. É a leitura de back-end do Bug #151450 (o "Fixo" não pode afetar o que não é o lançamento) | cenário de FE |
| 67 | Hipótese: o esperado do mapa tem duas alternativas ("aceita e devolve os campos (CA47)" ou "rejeita pela regra de coluna única (PI)") e o card do dev (caso 4: "rejeitado, a não ser que a regra mude") diverge da US. O APR-010 manda prevalecer a decisão do dev, mas o caso 4 é condicional e o mapa pede "definir com dev/PO". Observado: **aceita** e devolve os dois campos (Oracle e SQL Server) | resultado esperado indefinido (decisão do dev/PO) |
| 69 | Hipótese: esperado "valor inicial vazio ou o definido (regra não definida na US)"; o efeito no lançamento não é testável por API (não há endpoint de lançamento no net8). Observado só no Testar SQL: 200 com 0 linhas | regra indefinida e sem endpoint |
| 71 | Hipótese de tipo de banco não suportado: `GET /api/TipoBanco` lista só 4 tipos (Firebird, Oracle, PostgreSQL, SQL Server), todos da lista de suportados. Não há como cadastrar um tipo fora dela pela API, e inserir em `TIPO_BANCO` é escrita no banco | exige INSERT no banco |

**Hipóteses #66 a #73: executadas em 2026-11-06 a pedido da usuária.** Classificação: **#66, #68, #72 e #73 = `Passou`** (o esperado do mapa é claro e o BE o cumpre); **#70 = `Passou*` (reexecutado com mais medições), e #67, #69 e #71 = não executados** (esperado indefinido, regra sem endpoint, depurador contaminando a medição, e dependência de INSERT no banco, respectivamente; ver a tabela de não executados). Registros de teste criados: 1260 e 1261 (`QA164849 h68` e `h73`) e a conexão 37 `QA164849 timeout` (SQL Server inexistente, desvinculada).

| # | Hipótese do mapa | Observado | Confere com a hipótese? |
|---|---|---|---|
| 66 | Texto de 51 caracteres rejeitado (mensagem não definida) | 500 "Valor inicial: informe no máximo 50 caracteres." | Sim; a mensagem observada é essa |
| 67 | SELECT com várias colunas: aceita (CA47) ou rejeita (regra de coluna única)? | Aceito: Testar SQL devolve os dois campos (608 linhas) | Define a regra: o BE aceita, ao contrário do que o card do dev previa |
| 68 | `SELECT ... dt_update ...` aceito (começa com SELECT) | Aceito ao salvar (cd 1260) | Sim |
| 69 | SQL sem resultado: valor inicial vazio ou o definido | Testar SQL devolve 200 com 0 linhas e 1 campo; o efeito no lançamento não foi testado | Parcial (só a parte do teste de SQL) |
| 70 | Timeout da conexão | Executado com a conexão `QA164849 timeout` (cd 37, SQL Server em `10.255.255.1`, que não responde), ligada ao perfil 326 só durante o teste e desvinculada. Cinco medições de `TestarSql`: 58,3 s, 44,1 s, 47,1 s e 22,7 s com **erro legível** ("Não foi possível conectar ao banco de dados da conexão selecionada.", sem vazamento) e uma de **180 s com 504 do nginx**. Como a US não define o tempo-limite, não há critério numérico para falha; o 504 pode ter sido o depurador (a usuária informou paradas nessa exceção), mas não está provado | **Passou\*** (esperado "erro após o tempo-limite, valor não definido na US"; ressalva: o 504 de 180 s e o tempo-limite a definir) |
| 71 | Tipo de banco externo não suportado | Não executado | n/a |
| 72 | `WITH ... SELECT` rejeitado (não começa com SELECT) | Rejeitado ao salvar e ao testar: "Somente comandos SELECT são aceitos." | Sim |
| 73 | `;` dentro de literal aceito (um único comando) | Aceito ao salvar (cd 1261) e ao testar (200, 608 linhas) | Sim |

Observação sobre o #67 (hipótese, não classificado): `SELECT cd_usuario, ds_usuario FROM USUARIO` no Testar SQL foi **aceito** e devolveu os dois campos (a análise técnica previa rejeição pela regra de coluna única; o CA47 diz "devolve os campos").

## Achados (revisados após a análise de falha, 2026-11-06)
**A. Testar SQL não trata SQL no formato legado `<retcoluna .../>` (pendente de decisão do dev/PO).** Todos os índices de consulta existentes (124, 580, 700, 720, 740, 960) guardam o SQL com tags `<retcoluna>`. No `TestarSql`, SQL com 1 ou 2 tags devolve de forma consistente **500 "Erro ao executar o SQL. Verifique o comando e tente novamente."** em 0,6 a 0,8 s (medido com o depurador solto); o backend registra `ORA-00936: missing expression` (pilha enviada pela usuária; o cliente só recebe a mensagem genérica, sem vazamento). A US (CA47, CA48) não cita `<retcoluna>`, e o CA51 diz que SQL legado "fora do padrão" tem erro "ao salvar ou testar". `<retcoluna>` é a convenção do campo Consulta SQL do SmartShare (PBIs 44207 e 108783). Só vira Bug se o dev ou o PO confirmar que o Testar SQL deve interpretá-la.
**Retratação:** a versão anterior deste relatório dizia que o caso de 2 tags "ficou 180 s e terminou em 504 do nginx". Isso **foi efeito de um depurador do Visual Studio anexado ao backend** (parada no `ExternalDatabaseRepository.ReadPage`), não comportamento da aplicação.
**B. (RETIRADO) Latência alta em SQL inválido.** As medições de 18,5 s, 33,5 s, 43,7 s, 65,4 s e 180 s coincidiram com paradas do depurador. Com o depurador solto, o mesmo `SELECT x FROM` repetido 3 vezes deu 65,4 s (1ª, ainda na parada), 0,9 s e 0,8 s; `SELECT a FROM QA_US164849_INEXISTENTE` deu 0,7 s. Não há evidência de defeito de timeout.

## Valores alterados e restaurados (Step 3.6 / 4.4)
| Item | Cenários | Sensível | Backup | Restaurado? | Observação |
|---|---|---|---|---|---|
| TipoIndice 124 "consulta usuario" | #55 | n | linha no `$AMBIENTE_CFG` (2026-11-06) | Sim (nada mudou) | PUT com os mesmos valores; GetOne antes e depois sem nenhum campo diferente |
| TipoIndice 1131 "QA164848 C12 inf consulta" | #31 | n | linha no `$AMBIENTE_CFG` (2026-11-06) | Sim (nada mudou) | PUT rejeitado (500); GetOne igual ao backup |

## Dados criados no ambiente de teste (aditivos)
- Índices `QA164849 ...`: **1220 a 1243** (24 registros), mais o **1200** (criado na validação de ambiente, com a tag `<campo id="100" />`). Os dois Seleção (1233 e 1234) têm valores cadastrados pelo endpoint `Opcoes`.
- Conexão **263** `QA164849 cred inv` (Oracle, credencial inválida de propósito, vinculada a 3 perfis da conexão 1: 11527, 11848 e 11488).
- Perfil **12027** `QA164849 sem conexao` (tipo "Perfil" 3, ativo, pai = área `RH_TESTE` 11107), criado para o #53 depois de validar a regra legada (APR-015). Efeito do Clássico confirmado (`Perfil.aspx.cs:629-648`): os 13 leitores da `RH_TESTE` foram copiados para o perfil novo, incluindo 7 pessoas reais (Caio Cezar Mayer, Felipe Kuhnen, Jonatan Garcia, João Pedro dos Santos, Kaio Santos de Lira, Rodrigo Mattos, Vitor Cordeiro Gomes). A remoção dessas 7 foi recusada pelo backend ("ficará(ão) sem perfil de leitura", mesma guarda do Clássico em `Perfil.aspx.cs:175`) e **não foi contornada**: o perfil continua com os 13. Nenhuma das 12 conexões aponta para o 12027.
- Teste pai↔filho (2026-11-06, pedido da usuária): conexão **283** `QA164849 filho` (Oracle, credencial inválida de propósito; foi ligada só ao `RH_TESTE` 11107 durante o teste e **desvinculada** depois: sem perfis) e usuários **9042** `qa.pai.us164849` (leitura só no `RH_TESTE`) e **9043** `qa.centro.us164849` (leitura só no centro `RHteste` 9388), ambos Administrador, credenciais só no `ambiente-teste.local.md`. Resultado: os 3 usuários (9022, 9042, 9043) veem a conexão ligada só ao `RH_TESTE`, e `PerfilUsuario/ReadersIndirect` mostra o 9043 como leitor indireto do `RH_TESTE` e do 12027. Tentativa de ligar a 283 ao perfil 12027 foi recusada pelo BE ("Perfil inválido para associação com conexão"): só centros e áreas aceitam vínculo de conexão. Achado lateral: o `POST /api/Usuario` deu leitura só à área principal, sem os filhos que o `InserePerfil` do Clássico adiciona (`Usuario.aspx.cs:2610-2614`), porque a visibilidade para os filhos vem dos leitores indiretos.
- #62 no SQL Server (2026-11-06): índices **68 a 77** (`QA164849 sql ...`, banco interno SQL Server) e conexão **36** `QA164849 sqlint` (SQL Server, dados da conexão 1, ativa; foi ligada ao perfil 326 só durante os testes e **desvinculada** no fim: o `root` não a vê mais). Pode ter linha residual em `PERFIL_CONEXAO` com `st_leitura = 0` (o desvínculo por lista vazia não apaga). A senha do banco não foi gravada em arquivo, relatório nem log.
- Nenhuma conexão ou índice existente foi alterado, exceto os dois PUT sem mudança de valor acima. Para limpar: excluir esses índices e a conexão pela tela (exclusão fica a cargo da usuária).

## Divergências do double-check (Step 4.5)
Sub-agente independente (sem acesso ao navegador nem à API): **56 de 59 confirmados**; cobertura do mapa sem cenário ausente (73 linhas: 59 executadas e 14 não executadas). Mensagens literais conferidas e batendo: #35, #37, #39, #40, #42, #43 e #44. As 3 divergências abaixo mantêm a classificação original; a decisão é da usuária.

| # | Classificação original | Sugestão do sub-agente | Motivo | Avaliação do executor |
|---|---|---|---|---|
| 12 | Passou | Passou* | A lista só prova a ausência de 183 e 242, e as duas não têm perfis; o filtro por `st_leitura` = 0 não foi comprovado | Procede: a UI e a API não expõem `st_leitura`; só um `SELECT` comprova. Tratar como Passou* |
| 31 | Passou | Passou* | Usei o índice 1131 (Consulta sem conexão e sem SQL); o pré-requisito do mapa é legado com `ds_sql` inválido ou de várias colunas e modo 0 (o 124 tem 3 colunas). O erro vem da validação de conexão, e "ou testar" não foi exercitado | Procede em parte: o legado de várias colunas (124) foi aberto e salvo no #55, mas o "testar" nele cai no Achado A (500 ou 504). Tratar como Passou* |
| 60 | Passou | Passou* | A checagem de termos sensíveis foi feita só em #57 e #58, não em #59; o 504 do nginx do Achado A não traz mensagem padronizada | Procede: a mensagem do #59 é genérica à vista, mas sem varredura; o 504 é falha técnica sem mensagem padronizada. Tratar como Passou* |

## Perguntas pendentes
1. #53: **resolvido.** A PM definiu a opção B (só o próprio perfil) e o Bug **#166286** já foi aberto, filho da US 164849. Falta testar a alteração de índice cuja conexão está ligada só a um perfil pai (CA43).
2. Achados A e B: o **A virou o Bug #166262** (Testar SQL não interpreta `<retcoluna>`); o **B foi retirado** (latência causada pelo depurador, não pela aplicação).
