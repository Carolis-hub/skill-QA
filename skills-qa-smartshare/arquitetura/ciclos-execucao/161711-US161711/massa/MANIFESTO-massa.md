# Manifesto de massa — RUN_ID 20261109-161711 (SQL Server local, ShareGuizao)

Autorização: QA, no chat em 09/11 ("Autorizo tudo"), para as operações abaixo. Backups: `massa/backup-*-antes.txt`.

| # | Operação | Objeto | Antes | Depois | Verificação | Rollback |
|---|---|---|---|---|---|---|
| 1 | INSERT | `JOB_CONFIG` (Id 35, módulo 1, job 20, `Ativo = 1`, marcador `INSERIDO_QA_161711_20261109`) | sem linha | 1 linha | lida após o INSERT | `DELETE ... WHERE Id = 35` |
| 2 | UPDATE | `PASSO_USUARIO` processo 1019, v3, passo 4: `id_permissao_observacao` | 3 | 4 | lido: v1 = 2, v2 = 3, v3 = 4 | voltar para 3 |
| 3 | DELETE | `JOB_BPM` módulo 1, job 28, status 1 (Agendado) | 22 linhas | 0 linhas | lido: restam job 32 (1) e job 34 status 4 (1) | não reversível; backup em `backup-job_bpm-job28-status1-antes.txt` |

Ativações de `JOB_CONFIG.Ativo` por bug: ver `sql/ativar-reverter-jobs.sql` (aplicadas na hora da execução).
Nenhum dado pessoal ou segredo neste arquivo.

## Operação 4 (autorizada pelo QA no chat em 09/11)
| # | Operação | Objeto | Antes | Depois | Verificação | Rollback |
|---|---|---|---|---|---|---|
| 4 | UPDATE | `PASSO_BD` processo 5, v2, passo 101: `ds_comando_sql` | `Select 1, 2` | `SELECT * FROM TABELA_QA_INEXISTENTE_161713` | lido após o UPDATE (1 linha; o passo 52 da v2 segue `SELECT 1 AS Resultado;`) | `UPDATE PASSO_BD SET ds_comando_sql = 'Select 1, 2' WHERE cd_processo=5 AND cd_versao_processo=2 AND cd_passo=101;` (backup em `backup-passo_bd-5v2-antes.txt`) |

## Operação 5 (autorizada pelo QA no chat em 09/11)
| # | Operação | Objeto | Antes | Depois | Verificação | Rollback |
|---|---|---|---|---|---|---|
| 5 | UPDATE | `PARAMETRO` cd 96 (Utilizar nova API do Engine), `ds_valor` (ntext) | `1` | `0` | lido após o UPDATE (1 linha) | `UPDATE PARAMETRO SET ds_valor = '1' WHERE cd_parametro = 96;` (backup em `backup-parametro-96-antes.txt`); permite iniciar fluxo pelo engine clássico sem a API 8081 |

# Oracle (SSHARE / SHAREGUIZAO) — RUN_ID 20261109-161711-ORA
Autorização: QA, no chat em 09/11 ("Autorizo as 4"), para as 4 operações do plano de massa do Oracle.

| # | Banco | Operação | Objeto | Antes | Depois | Verificação | Rollback |
|---|---|---|---|---|---|---|---|
| O1 | Oracle | INSERT | `JOB_CONFIG` Id 30, módulo 1, job 20, `Ativo = 1`, marcador `INSERIDO_QA_161711_ORA` | sem linha | 1 linha | lida após o COMMIT | `DELETE FROM JOB_CONFIG WHERE ID = 30 AND JOB = 20` (a 1ª tentativa falhou com `ORA-00001`: o contador de identidade da coluna `ID` está atrás dos ids; o INSERT foi refeito com `ID = MAX(ID) + 1`, sem alterar a sequência) |
| O2 | Oracle | Criação pelo desenhador do Share + liberação | processos 561 `QA-161711 SQL sem escape` e 581 `QA-161711 SQL com escape` (pasta 5, vínculo Geral, papéis Papel Default); passo SQL com `SELECT * FROM TABELA_QA_INEXISTENTE_161713`; 581 com passo 15 tipo 13 filho do 10 | inexistente | criado e liberado (`ID_STATUS` 2) | lido: `PASSO`, `PASSO_BD`, `VERSAO_PROCESSO` | excluir os processos pela tela do Share |
| O2b | Oracle | `PERFIL_CONEXAO` pela tela Gerenciamento de Conexões | conexão 1 × perfis 1, 2, 3 (3 linhas) | inexistente | criado | lido: 3 linhas | desassociar os perfis na aba PERFIS da conexão |
| O3a | Oracle | `UPDATE WS_CONSULTA` | `CD_CONSULTA` 2: `DS_URL_CONSULTA` de `https://postman-echo.com/get?teste=smartshare` para `http://localhost:44303/api/v1/Cliente/getCliente3` (1 linha) | URL externa | atualizado | lido: URL nova | `UPDATE` devolvendo a URL de `massa/backup-ws_consulta-2-antes-oracle.txt` |
| O3b | Oracle | 101+ fluxos do processo 501 pela tela (`IniciaFluxo.aspx?CDPROC=501`, opção "vai pro executaWS") | 103 tarefas abertas no passo 11 (WebService); fluxos 2282 em diante; sem job WS na fila (Worker parado) | 0 abertas | criado | lido: `COUNT` de `TAREFA` passo 11 sem `DT_TERMINO` = 103 | cancelar/excluir os fluxos pela tela ou deixar o Worker concluir |
| O3c | Oracle | 1 fluxo do processo 442 v4 (temporal) pela tela | fluxo 2385: tarefa 2 aberta no passo 3 (pai do timer passo 5), `DT_PRAZO` 14:15:06 vencido; **elegível ao AvancoTemporal pelo ramo de prazo** (query `GetAvancoTemporalPrazo` reproduzida por leitura: 1 linha). A opção "avanca" não funciona (formulário do 442 trava o site), mas não é necessária | nenhum elegível | criado e confirmado | lido: query de prazo devolve fluxo 2385 / tarefa 2 / timer 5 | cancelar o fluxo pela tela |
| O4 | Oracle | processo 601 `QA-161711 Temporal sem formulario` pelo desenhador (início, atividade com timer filho, atividade, fim) | criado, salvo e **não liberado** (`ID_STATUS` 1); sobra do plano B, sem uso | inexistente | criado | lido: `PASSO` 2,3,5,6,11 | excluir o processo pela tela |
| O3 | Oracle | Iniciar fluxos | 101 fluxos WS e 1 fluxo temporal | — | **não iniciado** | — | — |
| O4 | Share + net8 | Troca de banco SQL Server para Oracle | `Web.config` do Share (provider `OracleClient`, caminho `/smartshare/`), `appsettings.json` da API, e bloco `ConnectionStrings` dos 5 worktrees (Scheduler e Worker BPM, fonte e `bin`) | SQL Server | Oracle | provider e `DBType` lidos; login do Share mostra "licenciado para Guilherme H - Oracle" | cópias do SQL Server em `Temp/.../scratchpad/backup-config-sql` (API e Web.config); worktrees: copiar o bloco da API de volta |
