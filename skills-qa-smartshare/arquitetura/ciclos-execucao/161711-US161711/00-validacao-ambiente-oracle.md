# Validação de ambiente — ORACLE — US #161711 Bugs Instaladores (mapas locais 21 a 25)

**Status do gate (Oracle):** LIBERADO PARA EXECUÇÃO COM RESSALVA (decisão do QA em 09/11: #161713 falha por conexão) — ver seções de atualização ao fim
**Ambiente:** local (máquina do QA), não produtivo; banco Oracle 19c Standard Edition 2 (`SSHARE`), schema `SHAREGUIZAO`
**Método de banco:** `ADAPTER_LOCAL` (`sqlplus` 12.2, só leitura). Credencial lida em tempo de execução do arquivo de variáveis do projeto e passada por stdin, sem exibir ou gravar.
**Data:** 2026-11-09 | **RUN_ID:** 20261109-161711-ORA
**Escritas no Oracle nesta validação:** nenhuma. Troca de banco do Share e do net8: **não feita**.
**Escopo:** #161716 (cenário 7 fora), #161713, #161712, #161714 e #161839 só net8 (clássico fora). Mesmos mapas do SQL Server.

> A troca de banco do Share clássico e dos `appsettings.json` invalida a assinatura do gate do SQL Server (`00-validacao-ambiente.md`). Para voltar ao SQL Server é preciso trocar de novo e revalidar.

## Resumo
| Dimensão | Status | Evidência | Pendência |
|---|---|---|---|
| Mapas | OK (local) | arquivos 21 a 25 | nenhuma |
| Acesso Oracle | OK | `sqlplus` conectou (schema `SHAREGUIZAO`, Oracle 19c); 12 tabelas esperadas existem; `JOB_BPM.CHAVE_CONCORRENCIA` existe | nenhuma |
| Parâmetro 96 (Engine) | OK | valor `0` (engine clássico); fluxo inicia sem a API 8081 | nenhuma |
| `JOB_CONFIG` módulo 1 | PENDENTE | jobs 7, 8, 9, 16, 18, 19, 22, 25, 28, 32, 33 e 34 com `Ativo = 1`; job 19 `Max_Tentativas = 5`, `Interval_Ms = 30000`; job 28 `Interval_Ms = 60000`; **job 20 sem linha** | INSERT do job 20 (autorização) |
| Build/branch | PENDENTE | worktrees compilados, mas com `appsettings.json` do SQL Server; o `wt30253` guarda a configuração Oracle em `.oracle.bak` | copiar o bloco `ConnectionStrings` do Oracle para os worktrees |
| Share/API apontando para o Oracle | PENDENTE | Share e `appsettings.json` da API estão em SQL Server | troca via `webconfig.aspx` (`QA-KB-20261106-001`, a revalidar) |
| Serviços | PENDENTE | Scheduler e Worker parados | subir na execução |
| Massas | BLOQUEADO | ver matriz | criação aguarda autorização |

## Matriz de massas (Oracle, leitura em 09/11 14:44)
| Bug | Requisito de massa | Resultado | Evidência |
|---|---|---|---|
| #161716 | 101 tarefas abertas em passo WebService | **AUSENTE** | processo 501: passo 11 (WS) com 0 abertas e 3 concluídas; 3 abertas no passo 5 (outro passo) |
| #161716 | Endpoint da consulta WS (mock) | a conferir | `WS_CONSULTA` do Oracle não foi lida nesta rodada; mock `ferramentas/mock_ws_44303.py` pronto |
| #161713 | Processo com passo SQL **sem** escape que falha | **AUSENTE** | `PASSO_BD` vazio em todos os processos |
| #161713 | Processo com passo SQL **com** escape (tipo 13) que falha | **AUSENTE** | nenhum `PASSO` tipo 13 |
| #161714 | Tarefa elegível ao AvancoTemporal | **AUSENTE** | consultas de passo de tempo e de prazo vencido devolvem 0 linhas; processo 442 tem 11 fluxos, nenhum elegível agora |
| #161712 | Linha de `JOB_CONFIG` do job 20 | **AUSENTE** | sem linha |
| #161712 | Massa por job (InicioPublicacao, NotifyScheduler, Exclusão, ExecutaPassoAplicacao, alertas) | aceita nos passos do cenário (decisão do QA em 09/11) | processos 421, 441, 442, 461 existem |
| #161839 | Passo com observação = opção 4 e tarefa aberta nele | **EXISTENTE E CONFIRMADA** | 481 v1, v2, v4, v6 (passo 5) e 522 v1 (passo 6) com 1 tarefa aberta cada |
| #161839 | Cenários com tarefa automática, dois fluxos e ramos paralelos | nasce nos passos do cenário | — |

**Estado herdado a restaurar ao fim da rodada Oracle:** `PASSO_USUARIO.ID_PERMISSAO_OBSERVACAO` do processo 522 v1, passo 6 = 4 (valor original 0, UPDATE da etapa 05).

## Plano de massa proposto (nada executado — aguarda autorização)
1. `INSERT` em `JOB_CONFIG` (Oracle): módulo 1, job 20, `Max_Tentativas` 5, `Politica_Backoff` 0, `Max_Paralelo` 1, `Lease_Segundos` 60, `Schedule_Type` 1, `Interval_Ms` 60000, `TimeZone_Id` `America/Sao_Paulo`, `Ativo` 1, `Batch_Size` 50, marcador `INSERIDO_QA_161711_ORA`. 1 linha. Rollback: `DELETE` pelo `ID` retornado.
2. Dois processos de teste criados no **desenhador do Share** (`workflow/processo.aspx?tpAcao=novo&cdPasta=5`, via Playwright MCP): SQL sem escape e SQL com escape (tipo 13), com SQL inválido (`SELECT * FROM TABELA_QA_INEXISTENTE_161713`), publicados. Rollback: excluir os processos pela tela.
3. 101 fluxos de um processo com passo WebService, iniciados por `IniciaFluxo.aspx?CDPROC=<processo>` (loop controlado), mais 1 fluxo de um processo temporal (442) para o #161714.
4. Troca de banco: Share clássico por `webconfig.aspx` (reescreve `Web.config` e o `appsettings.json` da API) e cópia do bloco `ConnectionStrings` para os 5 worktrees (Scheduler e Worker BPM, fonte e `bin`).

## Pendências bloqueantes
- Autorização das operações 1 a 4 acima.
- Confirmação por leitura da consulta WS do Oracle e do processo WS a usar nas 101 tarefas.
- Mesmos mecanismos de falha do SQL Server (SQL inválido; erro do AvancoTemporal pelo procedimento de concluir o fluxo com o Worker parado).

## Decisão
**BLOQUEADO.** Retomar quando as massas acima existirem e forem lidas, o Share e os worktrees apontarem para o Oracle e o relatório for revalidado.

Assinatura de contexto: ambiente local Oracle SSHARE / schema SHAREGUIZAO, RUN_ID 20261109-161711-ORA, mapas locais 21 a 25 (aprovados só local), parâmetro 96 = 0. Expira se o build, o banco, o mapa ou a massa mudarem.


## Atualização — massa e troca de banco aplicadas (09/11, depois da autorização do QA)
- **O4 feita:** Share clássico e os 5 worktrees agora apontam para o Oracle (login do Share mostra "licenciado para Guilherme H - Oracle"). **O gate do SQL Server fica expirado** até nova troca e revalidação.
- **O1 feita:** `JOB_CONFIG` Id 30 (job 20, `Ativo = 1`), conferido por leitura.
- **O2 parcial:** processo 561 `QA-161711 SQL sem escape` criado (v1 em edição, **sem passos**). Faltam desenhar o fluxo (início, passo SQL com SQL inválido, fim) e publicar; e criar o processo **com escape** (passo filho tipo 13). O editor tem seção FLUXOGRAMA gráfica; a automação do desenho não foi tentada.
- **O3 pendente:** 101 fluxos WS e 1 fluxo temporal ainda não iniciados.
- **Status do gate Oracle:** **BLOQUEADO** (processos SQL sem passos, 101 tarefas WS e tarefa elegível ao AvancoTemporal ausentes).

## Atualização — desenho do processo 561 (09/11, Playwright, depois de "Tente arrastar")
- **Fluxograma do 561 salvo pelo editor gráfico** (arrastar funcionou): início (passo 2) → atividade (passo 5) → fim (passo 6). Lido no Oracle: `PASSO` 2/5/6, `PASSO_BD` do passo 5 criado.
- **Passo 5 marcado como tipo SQL** (`ID_TIPO_ATIVIDADE = 3`, descrição "Passo SQL invalido") pelo menu Propriedades do editor. `PASSO_BD` está **sem conexão e sem comando** (`CD_CONEXAO` e `DS_COMANDO_SQL` vazios).
- **Bloqueio novo:** a lista de conexões da tela de atividade vem vazia. `CONEXAO` tem a conexão 1 "SmartShare" ativa, mas `PERFIL_CONEXAO` não tem nenhuma linha, e a tela só mostra conexão ligada a um perfil do usuário. Liberar a conexão 1 para um perfil do usuário `root` é escrita **não coberta** pelas 4 autorizações. Aguardando decisão do QA.
- Gate Oracle segue **BLOQUEADO**.

## Atualização — O2 concluída (09/11, depois da autorização "Autorizo" da conexão)
- **Escrita autorizada e feita:** `PERFIL_CONEXAO` ganhou 3 linhas (conexão 1 "SmartShare" × perfis 1, 2 e 3) pela tela Gerenciamento de Conexões (marcado "Geral" na árvore, cascata para filhos). Rollback: desassociar os perfis na mesma tela (aba PERFIS), ou `DELETE FROM PERFIL_CONEXAO WHERE CD_CONEXAO = 1`.
- **Processo 561 `QA-161711 SQL sem escape`:** v1 liberada (`ID_STATUS` 2). Passo 5 = SQL (`PASSO_BD`: conexão 1, comando `SELECT * FROM TABELA_QA_INEXISTENTE_161713`). Sem passo tipo 13.
- **Processo 581 `QA-161711 SQL com escape`:** v1 liberada (`ID_STATUS` 2). Passo 10 = SQL (mesmo comando e conexão), passo 15 = tipo 13 filho do 10 (`CD_PASSO_PAI = 10`), ligado ao fim 16.
- **Alerta:** a conexão 1 está cadastrada como tipo "Sql Server" e o botão de teste da tela falha ("SQL Server inexistente ou acesso negado"). Não sei ainda se o passo SQL do Worker usa essa conexão ou o banco padrão (Oracle). Se usar, o passo falha por conexão, não por SQL inválido. **Confirmar no código do handler antes do cenário do #161713.**
- **Pendente (O3):** 101 fluxos no passo WebService e 1 fluxo temporal. Fatos lidos: processo 501 tem 3 fluxos; `WS_CONSULTA` 2 do Oracle aponta para `https://postman-echo.com/get?teste=smartshare` (externo), não para o mock `localhost:44303`. Trocar essa URL é escrita nova, sem autorização.
- Gate Oracle segue **BLOQUEADO**.

## Atualização — O3 (09/11, depois de "Autorizo" da URL da consulta WS)
- **Escrita autorizada e feita:** `WS_CONSULTA` 2 agora aponta para o mock `http://localhost:44303/api/v1/Cliente/getCliente3`. Valor original em `massa/backup-ws_consulta-2-antes-oracle.txt`.
- **#161716 (101 tarefas WS): massa criada.** Processo 501: cada fluxo foi iniciado pela tela e avançado pela opção "vai pro executaWS". Lido no Oracle: **103 tarefas abertas no passo 11**. `JOB_BPM` sem job 28 novo (Worker parado); só o job 32 status 1 que já existia.
- **#161714 (temporal): incompleto.** Fluxo 2385 (processo 442 v4) parou na tarefa 2 (passo 3). A opção "avanca" não conclui: o frame do formulário cai em `Erro.aspx` (`FormularioPadrao20.aspx`) e o script dá `frame.confirmar is not a function`. Causa ainda não lida. Fluxo 2385 segue aberto, prazo da tarefa 2 às 14:15:06.
- **Mock `localhost:44303` ainda não está no ar** (sobe na execução).
- Gate Oracle segue **BLOQUEADO** (falta massa do #161714 e confirmação da conexão 1 no passo SQL).

## Conferência do handler do passo SQL (09/11, leitura de código e do Oracle)
- **Código (`lida-no-codigo`):** `AgentBpmService.ExecutarExecutaSql` chama `_externalDatabaseService.ExecuteWorkflowFirstRow/NonQuery(sql, passoBd.cd_conexao)`. `ExternalDatabaseRepository.GetConexaoInfo` monta a conexão a partir de `CONEXAO`, `TIPO_BANCO`, `CAMPO_TIPO_BANCO` e `CAMPO_CONEXAO` da conexão informada. Não usa o banco padrão do Worker. Qualquer exceção cai em `AvancaPassoEscapeExecutaSql` (se houver passo tipo 13) e `ArmazenarErroVariavelFluxoExecutaSql`.
- **Oracle (leitura):** conexão 1 = tipo "Sql Server", provider `sqloledb`, `Data Source` = `servidor`, `Database` = `banco`, usuário `sa` (senha oculta). Valores de exemplo, sem servidor real.
- **Consequência:** nos processos 561 e 581, o passo SQL vai falhar **por conexão**, não por `TABELA_QA_INEXISTENTE_161713`. O caminho de falha (retry, escape no 581) é o mesmo, mas o cenário "SQL inválido" não fica provado com essa causa. Para falha por SQL real a conexão precisa apontar para um banco alcançável (mudança de configuração com segredo, **não feita**). Decisão do QA: aceitar a falha por conexão como mecanismo, ou autorizar outra conexão.

## Revalidação por leitura — 09/11 (depois de O1 a O4)
| Bug | Requisito | Resultado | Evidência |
|---|---|---|---|
| #161716 | 101 tarefas abertas em passo WS | **EXISTENTE E CONFIRMADA** | 103 tarefas abertas no passo 11 do processo 501 |
| #161716 | Endpoint da consulta WS no mock | **CONFIRMADA** (URL); mock **fora do ar** | `WS_CONSULTA` 2 = `http://localhost:44303/api/v1/Cliente/getCliente3`; mock sobe na execução |
| #161713 | SQL sem escape que falha | **CRIADA E CONFIRMADA, com ressalva** | processo 561 liberado, passo 5 SQL; falha será **por conexão** (conexão 1 = SQL Server `servidor`/`banco`) |
| #161713 | SQL com escape tipo 13 | **CRIADA E CONFIRMADA, com ressalva** | processo 581 liberado, passo 10 SQL, passo 15 tipo 13 (pai 10); mesma ressalva |
| #161714 | Tarefa elegível ao AvancoTemporal | **CRIADA E CONFIRMADA** | fluxo 2385 (processo 442 v4), prazo vencido, ramo de prazo reproduzido por leitura |
| #161712 | `JOB_CONFIG` job 20 | **CONFIRMADA** | job 20 `Ativo` 1, `Max_Tentativas` 5, `Interval_Ms` 60000 |
| #161839 | Passo obs = 4 com tarefa aberta | **CONFIRMADA** | 481 v1, v2, v6 (passo 5) e 522 v1 (passo 6), 1 aberta cada. A nota anterior citava 481 v4; hoje o v4 tem obs 5 (não alterado por esta rodada) |
| Geral | Parâmetro 96 | **OK** | `DS_VALOR` = 0 |
| Geral | `JOB_CONFIG` módulo 1 | **OK** | 13 jobs com `Ativo` = 1 (7, 8, 9, 16, 18, 19, 20, 22, 25, 28, 32, 33, 34) |
| Geral | `JOB_BPM` | OK | só o job 32 status 1 (herdado) |
| Geral | Share/net8/worktrees em Oracle | OK | login "licenciado para ... Oracle"; blocos de conexão copiados |
| Geral | Serviços | PENDENTE (sobem na execução) | Scheduler, Worker e mock parados |

**Estado herdado a restaurar ao fim da rodada Oracle:** `PASSO_USUARIO.ID_PERMISSAO_OBSERVACAO` do 522 v1 passo 6 = 4 (original 0).

**Decisão do gate Oracle: BLOQUEADO — aguardando decisão do QA.** Todas as massas existem e foram lidas. Falta uma decisão: aceitar que o #161713 falhe por conexão (conexão 1 sem servidor real) ou autorizar apontar a conexão 1 para um banco alcançável. Com a primeira opção, o gate pode ser liberado como "LIBERADO COM RESSALVA" no cenário de SQL inválido.
Assinatura: ambiente local Oracle SSHARE / SHAREGUIZAO, RUN_ID 20261109-161711-ORA, mapas 21 a 25, parâmetro 96 = 0, IIS Express reiniciado em 09/11 (PID 12060). Expira se o banco, o build, o mapa ou a massa mudarem.

## Decisão do QA e gate final (09/11)
- **QA aceitou** que o #161713 falhe por conexão (conexão 1 = SQL Server de exemplo), sem alterar a conexão.
- **Status final do gate Oracle: LIBERADO PARA EXECUÇÃO COM RESSALVA.**
- **Ressalva (vale para os mapas 22):** o mecanismo de falha do passo SQL é erro de conexão, não SQL inválido. Os cenários do mapa 22 que exigem **mensagem de erro do SQL** (`TABELA_QA_INEXISTENTE_161713`) ficam `INCONCLUSIVO` no Oracle; retry, `Qt_de_Tentativas`, poisoning e escape (581) podem ser avaliados.
- **Antes de executar:** subir mock (`ferramentas/mock_ws_44303.py`), Scheduler e Worker de cada branch em Oracle, ativar jobs por bug (`sql/ativar-reverter-jobs.sql`, escrita com autorização), e restaurar o 522 v1 passo 6 (obs 4 para 0) ao fim da rodada.
- Validade: expira se banco, build, mapa ou massa mudarem. IIS Express reiniciado em 09/11 (PID 12060).
