# Etapa 32 — execucao-testes — US #161711 Bugs Instaladores — SQL SERVER (rodada 10/11/2026)

- **Pedido:** "Altere o banco para SQL e comece a rodar todos os cenários novamente" (10/11/2026), depois do Oracle.
- **Banco:** SQL Server local `NOTE-74VQ\SQLEXPRESS`, base `ShareGuizao`, ambiente local não produtivo.
- **Troca de banco (Oracle para SQL Server):** `SmartShareWeb/Web.config` do clássico voltou ao `HEAD` com `SmartShare4.0 = false` e `ConnectionString`/`ConnectionStringCalendar` com as credenciais criptografadas do `appsettings` SQL do clone net8 (sem exibir valores); `appsettings.json` da `bin` do Scheduler e do Worker BPM dos 5 worktrees (30104, 30060, 30457, 30486, 30253) com `DBType = SQLServer`, `Schema = dbo`, e `localhost:8080` trocado por `localhost:58149` (sem nginx 8080). Backups do estado Oracle em `scratchpad/bk_oracle`. Login do Share mostra "licenciado para QA - Guilherme" (SQL Server). A `bin` dos worktrees estava sem DLLs de terceiros (NLog, `Microsoft.Data.SqlClient`): o worktree de cada PR é recompilado (`dotnet build`) antes da rodada dele.
- **Serviços Windows do Agent** (`SmartShareAgent`, `_BPM_Borges`, `_Scheduler_Borges`) continuam parados pelo QA durante a rodada.
- **Autorizações do QA nesta rodada (chat, 10/11):** `DELETE` em `JOB_DUMP` (chaves ExecutaWs das tarefas pendentes do processo 1027, backup em `massa/bk_job_dump_ws_1027_sqlserver.csv`), `UPDATE` em `PASSO` (processo 1027 v1 passo 6, `cd_passo_pai` 3 para NULL, restaurado) e as escritas de massa usadas no Oracle (`JOB_CONFIG`, `PASSO_USUARIO`, `FREQUENCIA_INICIO`, `TAREFA`, `JOB_BPM`; `INSERT` de mensagem de passo e conexão; usuários pela tela), sempre restauradas ao fim.

## Resumo da rodada SQL Server (10/11/2026)
| Bug | PR | Passou | Passou com ressalva | Parcial / inconclusivo | Não executado / fora |
|---|---|---|---|---|---|
| #161716 | 30104 | 2, 4, 9 | 1, 6, 8 | 3 (parcial) | 5 (hipótese), 7 |
| #161713 | 30060 | 1, 3, 5, 7, 9 | 2, 6, 8 | 4 (inconclusivo) | 10 (hipótese) |
| #161712 | 30457 | 5 | 1, 2, 3, 4, 6, 7, 8, 9, 11, 12 | — | 10 (hipótese) |
| #161714 | 30486 | 4, 5 | 1, 2, 3 | — | — |
| #161839 | 30253 | 7 | 1, 3, 4, 5, 8, 9, 10 | — | 2, 6 (clássico, fora do escopo) |

Achado do cenário 8 do #161839 (ramos paralelos): em `NotifyWFExecHandler` (caso opção 4), o laço sobre os executores anteriores faz `strUsuario = executor.ToString()` (atribuição, não concatenação): com 2 ramos só o último executor retornado pela consulta é notificado, e a consulta (`SELECT DISTINCT` sem `ORDER BY`) devolve B1 no Oracle e B2 no SQL Server; o texto "só um é notificado" do mapa não distingue qual. Registrar para o dev.

Achados novos do SQL Server (não são resultado de cenário): (1) `WS_PARAMETRO_RETORNO` vazia com `CD_MENSAGEM_RETORNO = -1` faz o tratamento de erro do WS lançar `NullReferenceException` e o job concluir como sucesso com a tarefa aberta; (2) o log "inserido com sucesso" do Scheduler se repete a cada ciclo enquanto o job está em `FalhaParaRepetir`, com 1 linha por chave na tabela (30060 e 30457); (3) a branch 30457 ignora `JOB_DUMP` no `ExecutaSql`; (4) no SQL Server o envio de e-mail funciona (no Oracle falha no Graph), então os cenários de notificação do #161839 comprovam o destinatário pelo "Observação enviada com sucesso" e os alertas do #161712 saíram de verdade para o QA; (5) o formulário do processo 5 v2 quebra no avanço pela tela (`frame.confirmar is not a function`), o que impediu concluir tarefas pela interface em vários cenários, substituídos por `UPDATE` de massa autorizado.

## Preparação comum
| Ação | Escopo | Rollback |
|---|---|---|
| `UPDATE JOB_CONFIG` ativo = 0 nos jobs do módulo 1 que não são o do bug em teste | 12 linhas por bug | estado original (ativos 7, 8, 9, 18, 20, 32): `massa/bk_jobconfig_sql.txt` |

---

## Bug #161716 (ExecutaWs, jobs duplicados) — PR 30104, commit `e1396988`, worktree `wt30104` recompilado

**Massa:** processo 1027 "Processo de envenenamento WS" (passo 3, atividade WS, consulta 1 para o mock HTTP `ferramentas/mock_ws_44303.py` na 44303). As 138 tarefas abertas antigas estavam com `ST_AVANCA_AGENT = 0` (não eram pendência); um fluxo novo iniciado pela tela (900751) nasce com a tarefa em 1 (evidência de que é o valor nativo), então as 138 foram marcadas com `UPDATE TAREFA SET ST_AVANCA_AGENT = 1` (backup `massa/bk_tarefas_1027_avanca0.csv`). 135 das chaves já estavam em `JOB_DUMP` (rodadas anteriores): só 3 entravam na fila; com o `DELETE` autorizado de 348 linhas da dump (backup em CSV) a massa ficou limpa. `WS_PARAMETRO_RETORNO` estava vazia e o passo aponta `cd_mensagem_retorno = -1`: no erro do WS isso gerava `NullReferenceException`, tratada pelo handler como sucesso; foi inserida 1 linha (consulta 1, retorno -1, propriedade `erro`) para o cenário 6.

| # | Cenário | Resultado | Evidência |
|---|---|---|---|
| 1 | 101 fluxos WS sem duplicar job | **PASSOU COM RESSALVA** | 139 pendências. Com o Worker parado, `JOB_BPM` foi a 48 e depois 101 linhas (3 que já estavam + 98), **101 chaves distintas, 0 repetidas**. Com o Worker: 139 "executado com sucesso", 0 erros, `JOB_BPM` zerado, 0 tarefas abertas no passo 3; na dump, 136 chaves da massa com 1 linha cada, todas status 3, 0 repetidas. Ressalva: 139 em vez de 101 e 3 já estavam na fila antes (carryover) |
| 2 | Pendência relida é ignorada com log | **PASSOU** | 531 "Job ExecutaWs não agendado: já existe uma execução pendente ou em andamento para a ChaveUnica ..." em ~1 min com Worker parado, `JOB_BPM` fixo em 101 |
| 3 | Limite 99/100/101 | **PARCIAL (101+ observado)** | com 139 pendências a fila encheu em 2 ciclos sem passar de 101 linhas e sem repetir; 99 e 100 não repetidos (massa consumida) |
| 4 | Chave na dump bloqueia só a mesma chave | **PASSOU** | antes do `DELETE`, 135 chaves da massa na dump: 602 "foi localizada na tabela JOB_DUMP" e `JOB_BPM` com só as 3 chaves fora da dump (900751, 900444, 900445) |
| 5 | HIPOTESE: duas instâncias do Scheduler | **NÃO EXECUTADO** | hipótese (restrição do mapa) |
| 6 | Endpoint WS fora do ar | **PASSOU COM RESSALVA** | mock em 500; 3 fluxos novos; sem o passo de escape (`UPDATE PASSO` autorizado, restaurado): `JOB_BPM` ficou em **3 linhas** (status 4), `Qt_de_Tentativas` subindo 1 a 4, sem recriar job; ao esgotar, os 3 saíram de `JOB_BPM` e entraram em `JOB_DUMP` com status **5**, 1 linha por chave. Ressalva: 3 fluxos, não 101; o processo 1027 tem passo de escape (passo 6), com ele o erro avança pelo escape e o job conclui; sem a linha em `WS_PARAMETRO_RETORNO` o erro vira `NullReferenceException` e o job conclui como sucesso com a tarefa aberta (achado do ambiente, fora do PR) |
| 7 | Falha ao enfileirar 1 pendência | **NÃO EXECUTADO** | mecanismo não definido pelo dev |
| 8 | SQL Server e Oracle | **PASSOU COM RESSALVA** | mesmos cenários 1, 2, 4, 6 e 9 passaram nos dois bancos (Oracle em 09/11, SQL Server em 10/11), 0 duplicados; 3 e 7 e 5 como acima |
| 9 | 1 fluxo WS segue funcionando | **PASSOU** | fluxo 900751 iniciado pela tela: job criado e concluído (log do Worker), tarefa avançada, `JOB_BPM` vazio |

**Estado ao fim (#161716):** Scheduler, Worker e mock encerrados; passo de escape restaurado; `JOB_CONFIG` só com o job 28 ativo (será restaurado ao fim da rodada); 3 fluxos de teste anteriores ao escape desligado e 6 de teste ficam abertos no processo 1027; linha inserida em `WS_PARAMETRO_RETORNO` mantida até o fim da rodada.

---

## Bug #161713 (ExecutaSql não envenena o job) — PR 30060, commit `d4a98152`, worktree `wt30060` recompilado

**Massa (autorizada pelo QA no chat, 10/11):** `JOB_CONFIG` só o job 19 ativo (`Max_Tentativas` = **2** no SQL Server, 5 no Oracle; `Politica_Backoff` = 0; restaurados). `DELETE` de 87 linhas de `JOB_DUMP` (ExecutaSql, fluxos 1267 a 1269, backup `massa/bk_job_dump_sql_1267-1269_sqlserver.csv`) e `UPDATE TAREFA.ST_AVANCA_AGENT = 1` nas 3 tarefas do passo 52 desses fluxos (processo 5 v1, SQL `SELECT 1, 2 FROM DUAL`, que falha no SQL Server por `Invalid object name 'DUAL'`; sem passo de escape). Para escape e SQL válido o processo 5 v2 não avança pela tela (formulário quebra, `frame.confirmar is not a function`): `UPDATE TAREFA` reposicionando duas tarefas abertas (fluxo 900767 do passo 3 para o 101, SQL inválido com escape 103; fluxo 900121 do passo 3 para o 52, `SELECT 1 AS Resultado;`) com executor 0/0 (valores originais em `massa/bk_tarefas_900121_900767_sqlserver.txt`; as tarefas já avançaram, não dá para restaurar). A conexão 1 (SQL Server local) responde: a falha vem do SQL, não da conexão (diferente do Oracle). `UPDATE JOB_CONFIG` de `Max_Tentativas` e `Politica_Backoff` só no cenário 6, restaurados (2 e 0).

| # | Cenário | Resultado | Evidência |
|---|---|---|---|
| 1 | Retry quando ainda há tentativa | **PASSOU** | fluxos 1267, 1268, 1269: 1ª execução falhou com `OleDbException` "Invalid object name 'DUAL'", log "Tentativas: 1, Status: FalhaParaRepetir"; `JOB_BPM` 3 linhas, `Qt_de_Tentativas` = 1, status 4; tarefa segue aberta no passo 52. Falha de SQL real (não de conexão) |
| 2 | Esgotada, escape avança | **PASSOU COM RESSALVA** | fluxo 900767 (posicionado por `UPDATE TAREFA`): 1ª tentativa falhou (reagendada), 2ª (limite) avançou pelo escape: tarefa do passo 101 encerrada 13:30:15, nova tarefa no passo 5 (via escape 103), `JOB_DUMP` com status **3 (Sucesso)**, não Envenenado, `JOB_BPM` zerado. Ressalva: posicionamento artificial da tarefa |
| 3 | Esgotada, sem passo de escape | **PASSOU** | fluxos 1267, 1268, 1269 (sem escape): 2ª tentativa deu "Status: Envenenado"; log "Não avançou para o passo de escape do ExecutaSQL"; `JOB_BPM` zerou, `JOB_DUMP` 3 linhas status **5**, `Qt` 2; tarefas seguem abertas no passo 52 |
| 4 | Esgotada, escape falha ao avançar | **INCONCLUSIVO** | no Oracle a falha real era `ORA-01407` (`DS_FLUXO` vazio vira NULL). No SQL Server `FLUXO.DS_FLUXO` é `NOT NULL` e `''` não vira NULL: não há mecanismo natural para o escape falhar (duas tentativas de análise: coluna e comportamento do UPDATE; provocar por `UPDATE` seria `HIPOTESE`) |
| 5 | Pendência envenenada não volta à fila | **PASSOU** | depois do envenenamento (13:23), 18 vezes por chave "não agendado. ChaveUnica ... foi localizada na tabela JOB_DUMP" (fluxos 1267, 1268, 1269) e `JOB_BPM` com 0 linhas dessas chaves |
| 6 | Duas políticas de backoff | **PASSOU COM RESSALVA** | política 0 (padrão): 1ª espera 60 s. Política 1 (`FixedDelay`, fluxos 1268 e 1269, limite 5): `DATA_PROGRAMADA` menos `DATA_ATUALIZACAO` = **60 s** em qt 1, 2, 3 e 4, e envenenados no limite (`JOB_DUMP` 2 linhas status 5). Política 2 (`Exponential`, fluxo 1267): **60 s, 120 s, 240 s** nas tentativas 1, 2 e 3 (a de 480 s não foi aguardada). Ressalva: `UPDATE JOB_CONFIG` autorizado, restaurado; Linear (0) só a 1ª espera; 4ª espera do exponencial não medida |
| 7 | Limite de tentativas | **PASSOU** | `Max_Tentativas` = 2: tentativa 1 reagendou (`FalhaParaRepetir`), a 2ª foi `Envenenado`; com limite 5 (cenário 6) as 4 primeiras reagendaram e a 5ª envenenou |
| 8 | SQL Server e Oracle | **PASSOU COM RESSALVA** | 1, 3, 5, 6 e 7 passaram nos dois bancos; 2 e 9 passaram no SQL Server e o 2 também no Oracle; 4 só passou no Oracle (SQL Server sem mecanismo); diferença de ambiente: `Max_Tentativas` 2 no SQL Server e 5 no Oracle |
| 9 | ExecutaSql sem erro | **PASSOU** | fluxo 900121 (posicionado por `UPDATE TAREFA`): SQL válido no passo 52, "executado com sucesso" na 1ª tentativa (`Qt` = 0), sem retry, escape ou ocorrência; tarefa do passo 52 encerrada 13:29:15 e passo 71 criado, `JOB_DUMP` status 3 |
| 10 | HIPOTESE: erro não reagendável | **NÃO EXECUTADO** | hipótese; mecanismo não definido |

**Observação investigativa:** com o job em `FalhaParaRepetir` (status 4) o Scheduler do 30060 loga "inserido com sucesso" a cada ciclo (8 vezes por chave em ~80 s), mas `JOB_BPM` fica com 1 linha por chave (o `AddSql` impede a duplicata). É o mesmo log enganoso já visto no 30457: o `ExisteJobAtivo` desta branch não conta o job "aguardando nova tentativa" como ativo. Resultado de tabela correto, log impreciso.

**Estado ao fim (#161713):** Scheduler e Worker encerrados; `JOB_CONFIG` job 19 com `Max_Tentativas` 2 e `Politica_Backoff` 0; `JOB_BPM` com 1 linha pendente do fluxo 1267 (status 4); só o job 19 ativo (restauração geral ao fim da rodada).

---

## Bug #161712 (jobs do Scheduler duplicados) — PR 30457, commit `9816142b`, worktree `wt30457` recompilado

**Preparação (autorizada pelo QA, 10/11):** `UPDATE JOB_CONFIG` ativando os 13 jobs do módulo 1 (no SQL Server só 6 estavam ativos); só o Scheduler no início (Worker parado, para os jobs ficarem Agendados), Worker ligado depois para os cenários 7, 8, 11 e 12. `JOB_BPM` partiu com 8 linhas antigas de 09/11 (chaves de NotifyWf, EnviaAlertaFluxo, ExcluiFluxo, InicioTemporal 1010, InicioDesassociar). Massa criada: fluxo 900768 do processo 1019 pela tela (tarefa pendente de notificação); `INSERT` em `OBSERVACAO_TAREFA` (fluxo 165 tarefa 2, `ST_NOTIFICADO` = 0); `UPDATE TAREFA` (fluxo 900767: passo 58 de aplicação, executor 0/0, `ST_AVANCA_AGENT` = 1); `UPDATE FREQUENCIA_INICIO` (5 e 6) e `UPDATE JOB_CONFIG` (timezone do job 9 e cron do job 32), tudo restaurado ao fim.

Medição de `JOB_BPM` por ~10 ciclos: **27 linhas, 27 chaves distintas, 0 repetidas** (e `repetidas = 0` em todas as amostras posteriores, mesmo com o Worker consumindo).

| # | Cenário | Resultado | Evidência |
|---|---|---|---|
| 1 | AvancoTemporal não duplica | **PASSOU COM RESSALVA** | fluxo 900750: 1 job (`bpm:job:1:cd_fluxo=900750:cd_tarefa=2:AvancoTemporalStep:Verif...`), 15 "não agendado" na janela. Só havia o ponto de prazo; tempo, anexos e lote sem massa |
| 2 | ExecutaPassoAplicacao não duplica | **PASSOU COM RESSALVA** | tarefa do fluxo 900767 reposicionada no passo 58 (aplicação, processo 5 v2) por `UPDATE TAREFA`: 1 job `BPM|ExecutaPassoAplicacao|fluxo=900767|tarefa=3|passo=58|processo=5`, 1 linha/1 chave em 4 amostras, 121 "não agendado" no log. Ressalva: posicionamento artificial; 1 pendência só |
| 3 | ExecutaSql e InicioPublicacao | **PASSOU COM RESSALVA** | ExecutaSql: jobs dos fluxos 1267, 1268, 1269 (de #161713), 28 "não agendado", 0 repetidos. As chaves 1268 e 1269 estavam em `JOB_DUMP` e voltaram à fila: esta branch ignora a dump (já observado no Oracle). InicioPublicacao sem pendência (sem massa) |
| 4 | NotifyScheduler pendência (3 tipos) | **PASSOU COM RESSALVA** | **tarefa:** fluxo 900768 criado pela tela, 1 job `NotificaTarefa|fluxo=900768|tarefa=2` em 4 amostras; **observação:** pendência por `INSERT`, job `NotificaObservacao|fluxo=165|tarefa=2` 1 inserido e 3 "não agendado"; **mensagem nova:** jobs `NotifyWf|fluxo=139|tarefa=2` e `165|2` (`TAREFA_NOTIFICACAO` pendente) 1 por chave, 60 "não agendado". Ressalva: observação por `INSERT` (a tarefa do fluxo 165 não estava na lista do portal) e mensagem com massa já existente |
| 5 | NotifyScheduler alertas e exceção de alçada | **PASSOU** | 1 job `NotificarAlertas` e 1 `NotificarMensagemExcecaoAlcada` por ciclo, 0 repetidos |
| 6 | ExcluiFluxo, EnviaAlertaFluxo, InicioTemporal | **PASSOU COM RESSALVA** | `ExcluiFluxoEmSolicitacao`: 1 job, 15 "não agendado"; `EnviaAlertaFluxo`: 1 job, 15 "não agendado"; `InicioTemporal` (processo 1010): 1 job `bpm:job:1:cd_processo=1010`, 16 "não agendado" (pula quando já ativo). Ressalva: jobs de 1010 e dos demais partiram da linha antiga de 09/11 |
| 7 | Job recorrente volta após terminar | **PASSOU COM RESSALVA** | Worker do 30457: NotifyWf 22 "executado com sucesso" e EnviaAlertaFluxo 4 em ~3 min; o Scheduler recriou os jobs a cada ciclo (ex.: `NotificarAlertas`/`ExcecaoAlcada` e `EnviaAlertaFluxo` com `DATA_CRIACAO` 13:55:32) sem bloquear. Job 32 com cron temporário `0 * * * * ?` (restaurado `0 0 0 * * ?`). Ressalva: cron alterado |
| 8 | Timezone configurado | **PASSOU COM RESSALVA** | `JOB_CONFIG.TIMEZONE_ID` do job 9 para `Asia/Tokyo` (restaurado): relógio local 13:55 (UTC-3), novos jobs `NotificarAlertas` e `ExcecaoAlcada` com `DATA_PROGRAMADA` = `DATA_CRIACAO` = **01:55:32** (fuso de Tóquio, +12 h). Ressalva: testado no job 9 |
| 9 | Jobs `// TODO` não agendam | **PASSOU COM RESSALVA** | jobs 25, 33 e 34 ativos: nenhuma linha nova deles em `JOB_BPM` nos ciclos. Ressalva: existe 1 linha antiga de 09/11 do `InicioDesassociarAutomatico` (job 34, status 4), de outra branch |
| 10 | HIPOTESE: limite de tentativas | **NÃO EXECUTADO** | hipótese |
| 11 | InicioTemporal por frequência | **PASSOU COM RESSALVA** | processos 1010 v9 (diária), 1012 (semanal) e 1013 (mensal) com `UPDATE FREQUENCIA_INICIO` (dia, mês e hora ajustados para hoje; restaurados): diária gerou o job e o fluxo 900770 (13:58), semanal o fluxo 900771 e mensal o 900772 (14:03), 1 job e 1 fluxo por ocorrência, `DT_ULTIMA_VERIFICACAO` atualizada. O fluxo 900769 (13:53) veio da linha antiga de 09/11 (carryover). Ressalva: dados ajustados em vez de esperar |
| 12 | EnviaAlertaFluxo vários alertas (#161717) | **PASSOU COM RESSALVA** | fluxos 900549 e 900550 (2 linhas em `FLUXO_ALERTA` cada, alertas 3, 4 e 7): o log do handler registra "Alerta de Fluxo enviado com sucesso" para os três em cada fluxo, nenhum suprimido; 6 de 17 `DT_ULTIMO_ALERTA` atualizados. Ressalva: **o e-mail saiu de verdade** (Graph do ambiente funciona no SQL Server) para o endereço do QA, 1 vez por minuto durante o cron temporário (~12 min); contagens do log somam rodadas do dia |

**Observações:** (1) 30457 não altera o handler de `ExecutaWs`: o Scheduler logou 225 "inserido com sucesso" para as chaves WS em poucos ciclos enquanto `JOB_BPM` tinha ~15 linhas (log enganoso, a proteção parece ser do `AddSql`); (2) dump ignorada nesta branch (chaves envenenadas de ExecutaSql voltaram à fila); (3) o fluxo 900769 e o job de 1010 de 09/11 são anteriores ao PR.

**Estado ao fim (#161712):** Scheduler e Worker encerrados; timezone do job 9, cron do job 32 e frequências 5, 6 e 27 restaurados; os 13 jobs seguem ativos até a restauração geral.

---

## Bug #161714 (log do AvancoTemporal esconde o erro real) — PR 30486, commit `3ac5ea98`, worktree `wt30486` recompilado

**Mecanismo (autorizado, `UPDATE TAREFA`):** a tela não conclui tarefa neste ambiente (`frame.confirmar is not a function`), então as falhas foram provocadas por `UPDATE` em tarefas de fluxos criados pela tela (processo 9, passo 4 com prazo de 1 min; valores originais em `massa/bk_tarefas_900773_900774_sqlserver.txt`). Sequência: só o job 8 ativo; Scheduler sozinho enfileira o job 8 de cada fluxo; com o Worker parado altera-se a tarefa; sobe o Worker do PR e lê-se o log. Este é o mecanismo proposto na preparação de 09/11, agora executado.

| # | Cenário | Resultado | Evidência |
|---|---|---|---|
| 1 | Log do AvancoTemporal traz o erro real | **PASSOU COM RESSALVA** | fluxo 900774 com a tarefa já encerrada (`UPDATE DT_TERMINO`, equivale a concluir pela tela antes do agente): job 60750, log `ERROR` "Erro ao executar Job AvancoTemporal ... Tentativas: 1, Status: FalhaParaRepetir" com `exception` = `System.Exception: 0050` e stack em `FluxoService.AtualizarTarefaDataTermino` (o erro real, com exceção e pilha). Ressalva: a mensagem da exceção é só o código `0050`; causa provocada por `UPDATE` |
| 2 | Duas causas de erro diferentes | **PASSOU COM RESSALVA** | causa A (tarefa encerrada): `Exception: 0050` em `AtualizarTarefaDataTermino`; causa D (fluxo 900776 com `CD_TAREFA` renumerado, tarefa inexistente): `System.NullReferenceException` em `TarefaService.PreencherDataTerminoTarefa` (job 60752, `FalhaParaRepetir`). Mensagens e pilhas diferentes, cada uma no log. As causas B (tarefa movida para passo 3, fluxo 900773) e C (tarefa no passo 2, fluxo 900775) não geraram erro: job concluído com sucesso. Ressalva: causas provocadas por `UPDATE` |
| 3 | Efeito sobre o status do job | **PASSOU COM RESSALVA** | com erro o job fica em `FalhaParaRepetir` (status 4) com `Qt_de_Tentativas` subindo 1, 2, 3 e 4 (900774) e 1 a 4 (900776), sem virar sucesso; a 5ª tentativa (envenenamento, coberta em #161713) não foi aguardada |
| 4 | AvancoTemporal sem erro | **PASSOU** | fluxos 900773 e 900775 (sem erro): "Job AvancoTemporal executado com sucesso", `JOB_DUMP` status 3, `Qt` 0, sem `ERROR` |
| 5 | Outros handlers continuam logando | **PASSOU** | com os 13 jobs ativos e Worker do PR, em ~3 min: ExecutaSql 16 `INFO` e 4 `ERROR`, ExecutaWs 137 `INFO` e 41 `ERROR` (mock fora), ExcluiFluxo, ExecutaPassoAplicacao, InicioPublicacao, NotifyWf e AvancoTemporal com `INFO`; os `ERROR` seguem com exceção e pilha |

**Estado ao fim (#161714):** Scheduler e Worker encerrados; 13 jobs ativos (restauração geral ao fim da rodada); fluxos 900773 a 900776 de teste ficam no ambiente com as tarefas alteradas.

---

## Bug #161839 (observação opção 4 notifica o executor anterior) — PR 30253 (net8), commit `bfaf8358`, worktree `wt30253` recompilado

**Escopo:** só o net8 (cenários 1, 3, 4, 5, 7, 8, 9 e 10). Clássico (2, 6 e 11, PR 30254) fora da rodada por decisão do QA de 09/11.

**Massa (autorizada, restaurada):** processo 1019 "QA - Notifica Observação": a versão vigente é a v2 (a v3 com opção 4 está obsoleta), então `UPDATE PASSO_USUARIO.ID_PERMISSAO_OBSERVACAO` da v2 passo 4 de 3 para 4 durante os cenários e de volta para 3. Fluxos novos pela tela (`IniciaFluxo`) com a observação incluída pela aba ANOTAÇÕES: 900778 a 900784. O executor anterior (tarefa 1, passo 2) foi definido por `UPDATE TAREFA.CD_USUARIO` (backup em `massa/bk_tarefas_900778_900782_sqlserver.txt`), porque no SQL Server só existe `root` e a tela de login dos demais usuários não tem senha conhecida: 900778 = 1 (root), 900779 = 4, 900780 = 20, 900781 = NULL com executor 0/0, 900782 = 0, 900783 = 21, 900784 = 23. Só o job 9 ativo; Scheduler e Worker do PR. Diferente do Oracle: no SQL Server o envio de e-mail **funciona** (log "Observação enviada com sucesso"), os usuários de teste têm e-mails fictícios (`@local.test`) e o `root` recebe no endereço do QA.

| # | Cenário | Resultado | Evidência |
|---|---|---|---|
| 1 | Executor anterior recebe e-mail (net8) | **PASSOU COM RESSALVA** | fluxo 900778 (opção 4, tarefa anterior do `root`): Scheduler criou `NotificaObservacao|fluxo=900778|tarefa=2`, Worker logou "Observação enviada com sucesso ... Email: guilherme.borges@selbetti.com.br" e `ST_NOTIFICADO` = 1, 0 `ERROR`. Ressalva: o executor anterior é o `root`, que também é destinatário padrão; o caso distinguível é o 3 |
| 2 | Mesma regra no clássico | **FORA DE ESCOPO** | decisão do QA |
| 3 | Tarefa anterior de papel ou comitê | **PASSOU COM RESSALVA** | fluxos 900779 (executor anterior usuário 4), 900783 (21) e 900784 (23): "Observação enviada com sucesso" para `qa.ct02@local.test`, `qa.ct03@local.test` e `qa.ct05@local.test`, isto é, o usuário que concluiu a tarefa anterior; 0 `ERROR`. Ressalva: papel apenas (comitê não testado); o `CD_USUARIO` da tarefa anterior foi definido por `UPDATE` (a tela não permite logar como os usuários de teste) |
| 4 | Tarefa anterior automática | **PASSOU COM RESSALVA (simulado)** | fluxo 900781 (tarefa anterior com `CD_USUARIO` nulo e executor 0/0, como uma automática): job concluído sem erro, **nenhuma** linha "Observação enviada" nem "não enviada", `ST_NOTIFICADO` = 1. Ressalva: simulado por `UPDATE`; não há no SQL Server processo com WS ou SQL imediatamente antes de um passo com opção 4 |
| 5 | Isolamento entre fluxos (net8) | **PASSOU COM RESSALVA** | fluxos 900783 e 900784 (mesmo processo e versão, executores anteriores 21 e 23): o primeiro notificou só `qa.ct03@local.test` e o segundo só `qa.ct05@local.test`, sem cruzar. Ressalva: executores definidos por `UPDATE` |
| 6 | Isolamento entre fluxos (clássico) | **FORA DE ESCOPO** | decisão do QA |
| 7 | Executor anterior com `cd_usuario` nulo ou 0 | **PASSOU** | fluxos 900781 (NULL) e 900782 (0): jobs concluídos, 0 `ERROR`, sem destinatário de observação, `ST_NOTIFICADO` = 1 nos dois (o caso `cd_usuario` = 0 explícito, que faltou no Oracle) |
| 8 | Ramos paralelos | **PASSOU COM RESSALVA** (exploratório) | 2ª tentativa (10/11, "desenhar" autorizado pelo QA): processo novo 1038 `QA-161839 Ramos paralelos SQL (usar)` desenhado no editor gráfico (Início, A Inicial, paralelo, B1 e B2, junção, C Final, Fim; passos 2 a 9, mesma estrutura do 621 do Oracle) e liberado (versão 1, status 2). Executor "Papel Default", opção "Proximo" em A, B1, B2 e C e opção 4 em C por `UPDATE`/`INSERT` autorizados em `PASSO_USUARIO` e `PASSO_USUARIO_OPCAO` (corpo da mensagem de observação copiado do 1019). Fluxo 900785 pela tela: A concluída, o split abriu B1 (tarefa 4) e B2 (tarefa 5), B1 concluída 14:57:41 e B2 14:59:12 pela tela, a junção abriu C Final (tarefa 7). `CAMINHO_FLUXO`: 4 para 7 e 5 para 7 (igual ao 2442 do Oracle). Executores dos ramos atribuídos por `UPDATE TAREFA.CD_USUARIO` (B1 = 4, B2 = 21; os dois foram concluídos pelo root). Observação do root em C: a 1ª foi marcada como notificada sem envio por falta do corpo da mensagem; com o corpo, a 2ª gerou `NotificaObservacao|fluxo=900785|tarefa=7` e o Worker logou "Observação enviada com sucesso ... Email: **qa.ct03@local.test**" (B2). Foi notificado **só um** dos dois executores. No Oracle foi o B1. Coerente com "só um é notificado"; ressalva: exploratório e executores por `UPDATE` |
| 9 | SQL Server e Oracle | **PASSOU COM RESSALVA** | 1, 3, 4, 5, 7, 8 e 10 passaram nos dois bancos (Oracle em 09 e 10/11, SQL Server em 10/11); no 8 o executor notificado difere (B1 no Oracle, B2 no SQL Server). Diferença: envio de e-mail funciona no SQL Server e falha no Graph do Oracle |
| 10 | Outras opções de observação | **PASSOU COM RESSALVA (só opção 3)** | opção 3 (`PASSO_USUARIO` restaurado), `INSERT` de observação do `root` no fluxo 900553 (executor `root`): "Observação enviada com sucesso ... guilherme.borges@selbetti.com.br" e `ST_NOTIFICADO` = 1, como antes da mudança. Opções 5 e 7 não testadas (sem tarefa com outros destinatários) |

**Estado ao fim:** Scheduler, Worker e mock encerrados.

---

## Restauração do ambiente SQL Server ao fim da rodada
- `JOB_CONFIG` módulo 1 no estado original (ativos 7, 8, 9, 18, 20 e 32); `Max_Tentativas` do job 19 = 2, `Politica_Backoff` = 0, timezone do job 9 e cron do job 32 originais.
- `WS_PARAMETRO_RETORNO` vazia de novo; `PASSO` 1027 v1 passo 6 com `CD_PASSO_PAI` = 3; `PASSO_USUARIO` 1019 v2 com opção 3; frequências 5, 6 e 27 restauradas.
- **Não revertido (anotado):** `JOB_DUMP` (348 + 87 linhas apagadas, backup em CSV); `TAREFA` de fluxos de teste alteradas (900121, 900767 e 900773 a 900776 já avançaram ou mudaram, valores originais nos `massa/bk_*`); `ST_AVANCA_AGENT` das 138 tarefas do processo 1027 (processadas); linhas pendentes antigas em `JOB_BPM`; fluxos de teste abertos (900751 a 900784); `INSERT` em `OBSERVACAO_TAREFA` (fluxos 165 e 900553).
- **Configuração do ambiente:** o clássico (`SmartShareWeb/Web.config`) e as `appsettings` dos 5 worktrees ficam apontando para o SQL Server; o estado Oracle está em `scratchpad/bk_oracle`. Serviços Windows do Agent seguem parados.


## Complemento (10/11): processo 1038
Processo `QA-161839 Ramos paralelos SQL (usar)` (1038, versão 1 vigente) e fluxo 900785 ficam no ambiente. Os processos 1036 e 1037 (mesmo nome, sem "(usar)") são rascunhos criados por cliques duplicados na tela de cadastro e não foram liberados. `JOB_CONFIG` restaurado de novo (ativos 7, 8, 9, 18, 20 e 32).
