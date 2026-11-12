# Etapa 04 — Execução de testes — #160823 Rotina - Inicio Desassociar Automático

- **Skill:** `/arquitetura-executar-teste 160823` (Modo A, mapa do card #161490)
- **Data:** 2026-11-04 15:00–15:40 (hora local da máquina; o `sysdate` do Oracle marca +3 h)
- **Escreveu no Azure DevOps:** não
- **Ambiente:** local do QA (não HMG), Oracle `SHAREGUIZAO`, Share em IIS Express (`localhost:58149/smartshare/`), Scheduler e Worker BPM .NET 8 rodando de `smartshare-net8\src\3 - Core\...\bin\Debug\net8.0` na branch `feature/US160823-migracao-job-inicio-desassociar-automatico` (commit `ae01cc40`).
- **Autorização do usuário (chat):** leitura no Oracle, criação de massa pela tela e 3 `UPDATE` específicos (`TAREFA.dt_inicio` de fluxos de QA, `PASSO_USUARIO` passo 6 do processo 522, `JOB_CONFIG` Id 12). Nenhum `INSERT` nem `DELETE`. Hipóteses (#15, #28, #29, #30) não são executadas, por decisão do usuário.
- **Status da rodada:** **PARCIAL**. Restam o Agent clássico, a tela de configuração, o cancelamento de fluxo, #17/#18 e os bloqueados (ver Pendências).

## Pré-requisitos do ambiente

| ID | Cenários | Pré-requisito | Evidência | Status |
|---|---|---|---|---|
| PR-01 | todos | Build com a feature | Processos `SmartShareAgent_BpmWorker` e `_SchedulerWorker` iniciados 04/11 13:33 de `bin\Debug\net8.0`; símbolos `InicioDesassociarAutomaticoHandler`, `...ExecHandler`, `PrazoExpirou`, `ListarPendenciasInicioDesassociarAutomatico` presentes nas DLLs; HEAD `ae01cc40` | OK |
| PR-02 | todos | JOB_CONFIG Id=12 ativo | Oracle: Id 12, Módulo 1, Job 34, `ATIVO=1`, 300000 ms, `MAX_PARALELO=1`, `BATCH_SIZE=50` | OK |
| PR-03 | #1–#9, #12, #13, #16 | Massa (processo papel + tempo + fluxo) | Criada pela tela: processo 521 (2 min) e 522 "Matriz" (M1 papel 2 min, M2 papel sem tempo, M3 papel 60 min, M4 usuário). Fluxos 2062–2067. | OK |
| PR-04 | #10, #14 | Escrita no banco (`UPDATE`) | Autorizada pelo usuário no chat (3 `UPDATE`: `TAREFA.dt_inicio` de fluxos de QA, `PASSO_USUARIO` passo 6 do processo 522, `JOB_CONFIG` Id 12). Aplicados e restaurados (ver Massa). | OK |
| PR-05 | #11, #24, #27 | Alternar JOB_CONFIG e Agent clássico | `UPDATE JOB_CONFIG` autorizado e aplicado; Serviço Windows `SmartShareAgent` (clássico, build de 23/10) roda; `UPDATE JOB_CONFIG` Id 12 Ativo=0 às 09:48 (SQL) | EXECUTADO (ver seção Agent clássico) |
| PR-06 | #21, #22, #23 | Mecanismo de duas instâncias e de falha | Não informado | BLOQUEADO |
| PR-07 | #4 | API net8 e front de configuração no ar | `GET /api/JobConfig` existe em `JobConfigController`, mas a API não está rodando (portas 5000/5001/7001 sem resposta) e a tela não é a do WebForms | INCONCLUSIVO |
| PR-08 | #20 | Workers apontando para SQL Server | Workers estão em `DBType=Oracle` | BLOQUEADO |

## Resultado por cenário

| # | Cenário | Resultado | Evidência (resumo) |
|---|---|---|---|
| 1 | Desassocia tarefa vencida | **PASSOU** | Fluxo 2063/tarefa 2, `dt_inicio` 15:07:00, prazo 2 min. Scheduler enfileirou às 15:09:09; Worker (ciclo 15:14:07) logou "Tarefa desassociada. Fluxo: 2063 | Tarefa: 2." e `cd_usuario`/`dt_inicio` ficaram nulos. Repetido no fluxo 2064 (15:19:07). |
| 2 | Efeitos de dados | **PASSOU** | `TAREFA`: `cd_responsavel=2` (= `cd_executor`) e `id_tipo_responsavel=2`; `OPCAO_TAREFA` com nova linha (15:14:23); `LOG_APLICACAO` com 2 linhas por desassociação: aplicação 37 / ação 45 ("Usuario 1 se desassociou de um fluxo. Fluxo: 2063. Tarefa: 2.") e aplicação 47 / ação 45 ("Desassociado Usuario: 1 - Fluxo: 2063 - Tarefa: 2"). |
| 3 | Log do serviço com fluxo e tarefa | **PASSOU** | Log do Worker `JOB_BPM\InicioDesassociarAutomatico` com `Fluxo`, `Tarefa`, `Id` do job e `ChaveUnica`. |
| 4 | Rotina na listagem da configuração | **PASSOU COM RESSALVA** | API net8 subida localmente (`dotnet run`, `Engine.Api`, `http://localhost:8081`, `/health` Healthy com Oracle). `GET /api/JobConfig` (mesma consulta da listagem) retornou 29 rotinas, incluindo Id 12 `BPM` / `InicioDesassociarAutomatico`, `ativo=true`, 300000 ms; `GET /api/JobConfig/GetOne?id=12` confere (maxParalelo 1, batchSize 50). Ressalva: o front que consome a API não foi exercitado, só o contrato. A chamada não exigiu token. |
| 5 | Dentro do prazo não é alterada | **PASSOU** | Fluxo 2067/tarefa 4 (M3, 60 min) associada ao root desde 15:31:25; nenhuma inserção do Scheduler para o fluxo 2067 e usuário mantido. |
| 6 | Limite do prazo | **PASSOU COM RESSALVA** | Primeira inserção sempre depois do prazo: 2063 (prazo 15:09:00 → 15:09:09), 2064 (prazo 15:18:45 → 15:18:47), 2063 reassociada (prazo 15:20:43 → 15:20:46). Resolução de 10 s; limite exato não medido em ambiente (exigiria `UPDATE`). Complemento por teste unitário (`dotnet test`, `InicioDesassociarAutomaticoHelperTests`, 10/10 aprovados): `PrazoExpirou_ExatamenteNoPrazo_NaoConsideraExpirado` confirma que agora = prazo não vence (regra `agora > prazo`). |
| 7 | Tarefa sem usuário | **PASSOU** | Após 15:24:07 a tarefa 2063/2 ficou sem usuário e vencida; última inserção do Scheduler em 15:24:06; nenhuma depois. |
| 8 | Tarefa concluída | **PASSOU** | Fluxos 2066 e 2067, tarefa 2 (M1, 2 min) concluídas e vencidas; nenhuma inserção do Scheduler. Obs.: em processo de uma atividade só o fluxo some da `TAREFA` ao concluir (fluxo 2065). |
| 9 | Reassociada volta a ser avaliada | **PASSOU** | Fluxo 2063/2 reassociado às 15:18:43; novo job (Id 35679, mesma `ChaveUnica`) e segunda desassociação às 15:24:07, com `OPCAO_TAREFA` 1→3 e 2 novos logs. Sem bloqueio de chave única. |
| 10 | Unidades de tempo | **PASSOU** | Processo 541 "Unidades" (U1 1 hora, U2 1 dia, U3 1 semana; `id_tempo_desassociar` 1, 2, 3 conferido no banco). Fluxos 2083, 2084, 2085 com `dt_inicio` recuado por `UPDATE` autorizado (1 linha cada). Antes do prazo: 0 inserções em 12 ciclos. Primeira inserção depois do prazo: 2083 (16:04:13 → 16:04:16), 2084 (16:04:33 → 16:04:36), 2085 (16:05:43 → 16:05:46). Worker 16:09: "Tarefa desassociada" para os três. Teste unitário do helper para minuto, hora, dia e semana também aprovado. |
| 11 | Ativar/desativar alterna novo e clássico | **PASSOU COM RESSALVA** | Metade net8: `JOB_CONFIG` Id 12 `ATIVO` 1→0 às 15:49:34 (`UPDATE` autorizado): o Scheduler parou de ciclar (último ciclo 15:49:26) e a tarefa 2063/2 vencida às 15:51:29 não foi enfileirada. `ATIVO` 0→1 às 15:53:27: ciclos retomaram e 2063/2 foi enfileirada às 15:53:36; Worker desassociou às 15:54:07. Valor restaurado (`ATIVO=1`). Double-check: o log não registra a desativação nem a reativação, só a ausência de ciclos (15:49:26 → 15:53:36); os horários do `UPDATE` vêm da saída do banco. Metade clássica (o Agent clássico assumir ao desativar) **não exercitada**: o Agent clássico não está rodando. |
| 12 | Passo sem tempo | **PASSOU** | Fluxos 2066 (tarefa 3) e 2067 (tarefa 3, depois concluída), M2 sem tempo, associadas e vencidas; nenhuma inserção. |
| 13 | JOIN por `cd_passo` | **PASSOU** | Fluxo 2066: M1 com 2 min e M2 sem tempo; a tarefa 3 (M2, associada desde 15:30:10) não foi enfileirada, mas seria se o JOIN casasse o tempo de M1. Correção equivalente no clássico (diff: `AND PU.cd_passo = T.cd_passo`). |
| 14 | Executor tipo usuário | **PASSOU** | Fluxo 2082, tarefa 5 (M4, executor usuário) associada ao root, com `vl_tempo_total_desassociar=2` via `UPDATE` autorizado em `PASSO_USUARIO` (1 linha, restaurada para 0). Vencida desde 15:50:41. Com a rotina ativa, 15 ciclos depois de 15:53:27: 0 inserções para 2082, enquanto 2063/2 (papel) foi enfileirada e processada (controle). Obs.: a tela Avançadas não oferece o campo para executor usuário. Double-check: o log prova a ausência de inserção (0 ocorrências de 2082 em 99 ciclos), não o motivo; o filtro por tipo de executor é inferência, apoiada pelo controle de 2063/2 e por `TarefaRepository` (`id_tipo_executor = Papel`). |
| 15 | HIPOTESE | **HIPÓTESE NÃO VALIDADA** | Decisão do usuário. |
| 16 | Muda entre agendamento e execução | **PASSOU** | Fluxo 2064: tarefa reassociada 15:22:49, job 35692 agendado, tarefa concluída às 15:27:11, Worker 15:29:07 logou "Tarefa não está mais pendente (concluída ou sem usuário associado desde o agendamento), nada a fazer. Fluxo: 2064 | Tarefa: 2." e o job fechou com sucesso, sem erro. O Scheduler ainda logou uma inserção para 2064/2 às 15:27:16, 5 s depois da conclusão (15:27:11), e nenhuma depois; sem explicação no log, perguntar ao dev (provável ciclo que leu a pendência antes da conclusão). Não invalida o cenário. |
| 17 | Campos de formulário corrente | **PASSOU** | Processo 542 "QA-161495 Formulario" (atividade papel, 2 min, formulário "Form QA 161495"). Campos 3 e 4 com tipo de valor 5 (Propriedade do Processo), valores iniciais `[ds_usuario_corrente]` e `[ds_email_corrente]` (criados por `INSERT` autorizado, porque a tela comum não oferece os valores "corrente"). Fluxo 2087, `CAMPO_VALOR_TAREFA` da tarefa 2: campo 3 de "Papel Responsavel Papel Default" para "Papel Responsavel Papel Principal dos Processos" após a desassociação (Worker 16:44:07); campo 4 manteve o e-mail do primeiro usuário do papel. Controle negativo (fluxo 2086): campos 1 e 2, de tipo de valor 3, não foram alterados (a consulta só pega `id_tipo_valor = 5`). |
| 18 | Liberação de anexo | **PASSOU** | Fluxo 2089, anexo 1 versão 1 (inseridos com `INSERT` autorizado, pois `VERSAO_ANEXO` estava vazia) e duas liberações: usuário 1 (root) e usuário 3 (qa.usuario2, criado pela tela). Depois da desassociação (Worker 16:49:07) restou só a liberação do usuário 3; a do usuário 1 foi apagada. |
| 19 | Configuração SQL Server e Oracle | **PASSOU COM RESSALVA** | Scripts `0.1 PreCarga.sql` e `Database/Oracle/0.4 PreCarga.sql` (branch do PR 29228) carregam `JOB_CONFIG` e `JOB_CONFIG_PADRAO` com os mesmos valores: Id 12, Módulo 1, Job 34, `MAX_PARALELO=1`, 300000 ms, `ATIVO=0`, lote 50. Oracle vivo confere (Id 12). Instância SQL Server não consultada (sem autorização). |
| 20 | Bancos x cenários | **NÃO EXECUTADO NO ORACLE; PASSOU NO SQL SERVER** | Nesta rodada o ambiente estava apontado só para o Oracle (`DBType` dos Workers); a comparação entre bancos foi feita depois, com o ambiente trocado para SQL Server (ver rodada SQL). Não é limitação dos Workers. |
| 21 | Duas instâncias | **PASSOU** | Segunda instância do Worker BPM subida de uma cópia do build (`NLOG_LOGROOT` próprio), contra o mesmo Oracle. Com 14 jobs pendentes (fluxos 2100 a 2113), as duas consultaram a fila juntas às 17:09:06 a 17:09:10, com logs intercalados. Instância 1 processou 6 jobs (2101, 2102, 2103, 2105, 2107, 2113) e a instância 2 processou 8 (2100, 2104, 2106, 2108 a 2112); nenhum fluxo apareceu nos dois logs. Banco: 14 linhas em `OPCAO_TAREFA` (máximo 1 por fluxo), 14 tarefas desassociadas, 28 linhas de `LOG_APLICACAO` (14 + 14), nenhuma linha restante em `JOB_BPM`. Tentativas anteriores (fluxos 2090 a 2099) não sobrepuseram, porque a segunda instância consulta a fila ~10 s depois de iniciar e fechou os jobs sozinha. |
| 22 | Erro numa tarefa não trava as outras | **FALHOU** (condicional à massa) | Fluxos 2119, 2120, 2121 (processo 543, com um campo de tipo 5 e `ds_valor_inicial` nulo, via `INSERT`), 2122, 2123. 2119 e 2120 foram desassociados (17:24:07). O job do 2121 (Id 36093) iniciou às 17:24:08 e **não terminou**: sem log de erro, `JOB_BPM` em status 2 (Executando) com lease vencido às 17:25:08 e 0 tentativas, linha `TAREFA` do 2121 travada (`ORA-00054` na sondagem), CPU do Worker ociosa. Os jobs 36094 e 36095 (fluxos 2122 e 2123) ficaram pendentes (status 1) e o ciclo das 17:29:07 não rodou. Esperado: erro com `cd_fluxo` e `cd_tarefa`, restantes processadas. Obtido: o Worker travou, e a rotina inteira parou até reiniciar. A causa provável é o `item.ds_valor_inicial.ToLower()` com valor nulo em `FluxoService.AtualizarValoresCorrenteCampoFormularioDaTarefa`, mas não confirmei a pilha. A massa é artificial: pela tela o combo não permite valor inicial vazio. |
| 23 | Falha reagendável | **INCONCLUSIVO** | Não consegui uma falha limpa (exceção capturada em `Executar` e job em `FalhaParaRepetir`). Tentativa 1: lock de linha por `SELECT ... FOR UPDATE` no fluxo 2116 (88 s): o Worker esperou sem timeout e concluiu com sucesso depois da liberação; os fluxos 2117 e 2118 ficaram atrás dele. Tentativa 2: campo com valor inicial nulo (cenário #22): travou em vez de lançar erro. |
| 24 | Paridade back-to-back | **PASSOU (SQL Server, com o build do PR 29228)** | Build antigo: desassociou tarefa de passo sem tempo (fluxo 900599, passo 4). Build do PR (06/11 10:22 a 10:28): desassociou só o 900705 (passo 3, 2 min) e manteve o 900599; 2 ciclos sem erro. Ver seção "Agent clássico com o fix". Oracle não repetido. |
| 25 | `AvancarFluxo` e `CancelarFluxo` | **PASSOU COM RESSALVA** | Avançar (Concluir) exercitado em vários fluxos sem falha. Cancelar: portal > Atividades > "Minhas Solicitações" > ícone "Cancelar Fluxo" > confirmação, no fluxo 2085 às 16:25:25. Resultado: `FLUXO` e `TAREFA` do 2085 removidos (0 linhas) e `LOG_APLICACAO` com ação 38 "Fluxo [2085] - [QA-161495 Unidades], foi cancelado em 04/11/2026 16:25:25". Ressalva: não verifiquei se o cancelamento passou pela API net8 ou pelo motor clássico (depende do parâmetro "utiliza nova API Engine"). |
| 26 | Outros jobs BPM | **PASSOU COM RESSALVA** | Nenhuma linha `ERROR` nos logs de 04/11 do Worker e do Scheduler; jobs `ExcluiFluxoEmSolicitacao`, `ExecutaSql`, `ExecutaWs`, `InicioPublicacao`, `NotifyWf` seguiram executando. Verificação por log, sem massa específica. |
| 27 | Clássico inalterado com rotina desativada | **PASSOU COM RESSALVA (SQL Server)** | Ativo=0 às 09:48: o clássico assumiu no ciclo de 09:50 e desassociou os expirados (900704/900705 às 09:55), com log em arquivo `DesassociarAutomatico` e `LOG_APLICACAO` 47/45. Ressalva: build instalado sem o fix do PR 29228. |
| 28–30 | HIPOTESE | **HIPÓTESE NÃO VALIDADA** | Decisão do usuário. |

### Resumo consolidado (atualizado em 05/11/2026)

Total do mapa: 30 cenários = 26 executáveis + 4 hipóteses não executadas por decisão do usuário (#15, #28, #29, #30).

| Resultado | Oracle | SQL Server |
|---|---|---|
| Passou | 18: #1, #2, #3, #5, #7, #8, #9, #10, #12, #13, #14, #16, #17, #18, #21, #23, #24, #27 | 19: #1, #2, #3, #5, #7, #8, #9, #10, #12, #13, #14, #16, #17, #18, #20, #21, #23, #24, #25 |
| Passou com ressalva | 7: #4, #6, #11 (só net8), #19, #20, #25, #26 | 6: #4, #6, #11, #19, #26, **#27** (Agent clássico) |
| Falhou | 1: #22 (valor inicial nulo derruba o job; Bug #166161) | 1: #22 (mesmo gatilho, reteste de 05/11; Bug #166161) |
| Inconclusivo | 0 | 0 |
| Bloqueado / não rodado | 0 (#20 no Oracle: #1 e #13 repetidos, #5 não) | 0 |
| Executados | 26 | 26 |

- Correção: a contagem anterior para SQL Server (17 passou, 6 com ressalva) estava errada. Contagem atual (já com #24 em PASSOU): 19 passou, 6 com ressalva (#24 e #27 inclusos) e 1 falhou (#22, retestado com valor nulo em 05/11).
- **Achados que exigem decisão do dev:** (1) Oracle sem timeout de comando: lote parou 88 s e travou com valor inicial nulo (#22); SQL Server aborta em 30 s e segue. (2) Build instalado do Agent clássico não contém o fix do PR 29228: desassociou tarefa de passo sem tempo (fluxo 900599) e falhou em cascata por transação aberta (#24). (3) `[ds_usuario_corrente]` difere entre clássico e net8 (#17). (4) Scheduler loga "inserido com sucesso" a cada ciclo para a mesma chave. (5) `JOB_CONFIG_PADRAO` Id 12 com `Ativo=1` no SQL Server (script manda 0).
- Não validado: build do clássico com o PR 29228; #24 e #27 em Oracle; hipóteses.
- Estado do ambiente (SQL Server): parâmetro 96 = 1 e `JOB_CONFIG` Id 12 `Ativo=0` (ambos originais); API net8 em `http://localhost:8081`; massa de teste não removida (nenhum `DELETE` autorizado).
- Relatório não anexado ao card Teste.

## Achados e observações

1. **Log "inserido com sucesso" repetido a cada 10 s.** Enquanto o Worker não roda (ciclo de 5 min), o Scheduler registra a inserção da mesma `ChaveUnica` a cada ciclo (51 linhas para 2063/2 e 18 para 2064/2). O `JOB_BPM` fica com 1 linha por chave, então não há duplicidade de processamento; o ruído é só de log. Vale confirmar com o dev se é o comportamento desejado.
2. **Relógio.** `dt_inicio` é gravado em hora local da aplicação (15:xx) e o `sysdate` do Oracle marca +3 h (18:xx). A rotina comparou com o relógio local e o prazo foi respeitado nos testes; o ponto fica relevante se o Worker rodar em fuso diferente do banco.
3. **Atividade de executor usuário não tem "Tempo total para desassociar"** na tela Avançadas (campo só aparece para papel).
4. **`DesassociaTarefa.cs` (clássico):** o diff do PR 29228 mostra remoção de dois `using` não usados e o `AND PU.cd_passo = T.cd_passo` no JOIN. Resolve a pendência "o que mudou no clássico".
10. **Worker trava e para a rotina inteira (#22).** Com um campo de tipo "Propriedade do Processo" de valor inicial nulo, o job do fluxo 2121 ficou em "Executando" sem erro nem timeout, segurando a linha da `TAREFA`. Os outros jobs da fila ficaram pendentes e o Quartz não disparou o ciclo seguinte. Também: um lock de linha de 88 s travou o lote (fluxo 2116) sem timeout de comando. O processamento é sequencial; uma tarefa lenta ou travada atrasa todas. **Resolução (05/11, com autorização do usuário):** o Worker original deixou de existir depois da reabertura do ambiente e o lock caiu. `UPDATE` de 1 linha em `CAMPO_FORMULARIO` (processo 543, campo 1): valor inicial nulo → `[ds_usuario_corrente]`. Worker BPM iniciado de novo às 07:36:08 (PID 15060): os jobs 36093, 36094 e 36095 (fluxos 2121, 2122, 2123) foram processados com sucesso às 07:36:31 a 07:36:33. O fluxo 2121, o mesmo que travou, concluiu assim que o valor deixou de ser nulo, o que reforça o valor nulo como gatilho (a pilha continua sem confirmar).
11. **Duas instâncias (#21).** O job usa lease (`LOCK_ID`) e cada job foi consumido por uma só instância.
6. **Valor "corrente" diferente entre clássico e net8 (#17).** Ao iniciar o fluxo, o campo `[ds_usuario_corrente]` da tarefa de papel ficou "Papel Responsavel Papel Default" (papel 1, vindo do motor clássico), enquanto o net8 gravou "Papel Responsavel Papel Principal dos Processos" (papel 2, o `cd_executor` real). O valor do net8 é o do executor configurado; vale o dev confirmar qual é o esperado.
7. **Tela de formulário só oferece "solicitante".** O combo de valor inicial de "Propriedade do Processo" não lista os valores `*_corrente`, só aparecem no editor gráfico de formulário (`SSFormEditor`). Por isso os campos do #17 foram criados por `INSERT`.
8. **A rotina só atualiza campos de tipo de valor 5.** Campos de tipo 3 com o texto `[ds_...]` não são tocados (controle no fluxo 2086).
9. **O `PASSO_USUARIO` do passo de 60 min (#5)** foi desassociado às 16:34:07, depois de vencer em 16:31:25: coerente com o prazo de 60 min.
5. **Processo de uma atividade só:** ao concluir, o fluxo é removido da `TAREFA`; ao fechar a tela sem avançar, o fluxo era excluído até marcar "Não excluir fluxo ao não avançar atividade inicial" no processo.

## Massa criada no ambiente (não removida)

- Processos: 521 "QA-161495 Desassociar Automatico"; 522 e 523 "QA-161495 Matriz" (523 é cópia sem atividades, criada por duplo clique).
- Fluxos: 2062 (excluído pelo sistema), 2063, 2064 (concluído), 2065 (concluído), 2066 e 2067 (abertos, com tarefas associadas ao `root`).
- Processo 541 "QA-161495 Unidades" (U1 1 hora, U2 1 dia, U3 1 semana); fluxos 2082 (M4, aberto, associado ao root), 2083, 2084 e 2085 (tarefas desassociadas pela rotina).
- Escritas diretas autorizadas pelo usuário e aplicadas (todas com `commit`): `UPDATE PASSO_USUARIO` 522/v1/passo 6 `vl_tempo_total_desassociar` 0→2 (restaurado para 0); `UPDATE JOB_CONFIG` Id 12 `ATIVO` 1→0→1 (restaurado para 1); `UPDATE TAREFA.dt_inicio` recuado em 2083/2 (−56 min), 2084/3 (−1436 min) e 2085/4 (−10076 min), originais 16:00:13, 16:00:33 e 16:01:43. Como a rotina desassociou essas tarefas (`dt_inicio` nulo), o valor original não tem mais o que restaurar. Nenhum `INSERT` nem `DELETE` nessa primeira leva.
- **Rodada seguinte (autorização de `INSERT` dada no chat):** processos 542 "QA-161495 Formulario" (campos 1 e 2 de tipo 3; campos 3 e 4 de tipo 5 inseridos em `CAMPO_FORMULARIO`) e 543 "QA-161495 Form2" (descartável); fluxos 2086 a 2089; usuário `qa.usuario2` (`cd_usuario` 3, criado pela tela e registrado em `Variveis de Ambiente`, seção 4.1); `INSERT` de 1 linha em `ANEXO`, 1 em `VERSAO_ANEXO` e 2 em `VERSAO_ANEXO_LIBERACAO` (ids 4 e 5; a 4 foi apagada pela rotina, a 5 permanece). Fluxo 2085 cancelado pelo portal. A API net8 (`Engine.Api`) ficou rodando em segundo plano em `http://localhost:8081`. Nenhum `DELETE` direto.

## Pendências e instruções para retomada

1. ~~#10 e #14~~ — executados após a autorização.
2. ~~#11 (metade clássica), #24 e #27~~ — executados em SQL Server (seção Agent clássico). Falta repetir em Oracle e testar um build do clássico com o PR 29228.
2b. ~~#4, #17, #18 e #25~~ — executados na rodada seguinte (ver tabela).
4. ~~#4~~ — resolvido (API net8 subida; `GET /api/JobConfig`).
5. ~~#25~~ — resolvido (portal > Minhas Solicitações > Cancelar Fluxo).
6. ~~#17 e #18~~ — executados com massa criada nesta rodada. Double-check por log confirmou só a parte de log (Scheduler e Worker, sem `ERROR`); o conteúdo dos campos e das liberações vem do banco.
7. ~~#20, #21, #22, #23~~ — executados na rodada SQL Server; em Oracle, #22 falhou e #23 ficou inconclusivo.
8. Retomada: rodar `/arquitetura-executar-teste 160823` de novo; os pré-requisitos serão revalidados.

---

# Rodada SQL Server (paridade com Oracle) — 05/11/2026 — CONCLUÍDA (Agent clássico na seção final)

- **Ambiente:** SQL Server 2019 Express, instância `NOTE-74VQ\SQLEXPRESS`, banco `ShareGuizao`; web em `localhost:58149/smartshare/` ("Sistema licenciado para QA - Guilherme"); Scheduler (PID 32740) e Worker BPM (PID 14676) com `DBType=SQLServer`. A API net8 foi subida por mim em `http://localhost:8081` (saúde `sqlserver` OK).
- **Autorização:** pedido do usuário no chat ("realize os testes de SQL"). Escritas na rodada: `UPDATE JOB_CONFIG SET Ativo=1 WHERE Id=12` (1 linha; estava `Ativo=0`, o seed padrão), necessário para a rotina rodar.
- **Massa criada (pela tela):** processos 1028 "Desassociar Automatico" (papel, 2 min), 1029 "Matriz" (M1 2 min, M2 sem tempo, M3 60 min, M4 usuário), 1030 "Unidades" (1 hora, 1 dia, 1 semana) e 1031 "Formulario" (ainda sem formulário). Passos conferidos no banco, iguais aos do Oracle; 1028 a 1030 liberados.

| # | Resultado SQL | Evidência |
|---|---|---|
| 4 | **PASSOU COM RESSALVA** (igual ao Oracle) | `GET /api/JobConfig` na API apontada para SQL Server: 29 rotinas, Id 12 "BPM / InicioDesassociarAutomatico", ativo, 300000 ms. Front não exercitado. |
| 19 | **PASSOU COM RESSALVA** | `JOB_CONFIG` Id 12 em SQL Server: Módulo 1, Job 34, `Max_Tentativas` 5, `Max_Paralelo` 1, lease 60, 300000 ms, `America/Sao_Paulo`, lote 50 (igual ao Oracle e ao script `0.1 PreCarga.sql`). Ressalva: `JOB_CONFIG_PADRAO` Id 12 está com `Ativo=1` no SQL Server, e o script do PR manda `Ativo=0`. |

## Bloqueio inicial (resolvido): início de fluxo pela API do Engine

O parâmetro 96 ("Utilizar nova API do Engine") está em **1** no SQL Server e em **0** no Oracle. Com 1, o web clássico inicia, avança e cancela fluxos pela API net8, chamando `<origem>/smartshare/api/v1/engine/...` (a origem vem do cabeçalho `X-Original-URL`, que o nginx do ambiente de desenvolvimento injeta e cujo prefixo `/smartshare` ele remove). Sem esse proxy, "iniciar fluxo" retorna "Erro inesperado" (`EngineService.IniciarFluxo`). A API aceita as rotas só sem o prefixo (`/api/v1/engine/IniciarFluxo` responde 401 sem token; `/smartshare/api/...` responde 404; `ASPNETCORE_PATHBASE` não tem efeito). Subir um proxy próprio foi negado pelo sistema de permissões do Claude Code (expor serviço local), e eu não segui por outro caminho.

**Opções:** (A) o usuário sobe o nginx de desenvolvimento (ou equivalente) apontando `/smartshare/api` para `http://localhost:8081`; (B) o usuário autoriza `UPDATE PARAMETRO SET ds_valor='0' WHERE cd_parametro=96` no SQL Server (1 linha, restaurável), igualando as condições do Oracle; (C) chamar a API direto com a chave de API lida da tabela `APIKEY` (descartado: seria usar credencial do banco).


**Resolução do bloqueio (05/11, com autorização do usuário):** `UPDATE PARAMETRO SET ds_valor='0' WHERE cd_parametro=96` no SQL Server (1 linha; estava 1, o Oracle estava com 0). A rodada seguiu com o motor clássico, como no Oracle. O valor segue 0; restaurar para 1 é decisão do usuário.

## Escritas feitas no SQL Server (todas análogas às autorizadas no Oracle)

- `PARAMETRO` 96: 1 → 0 (1 linha).
- `JOB_CONFIG` Id 12: `Ativo` 0 → 1, depois alternado 1 → 0 → 1 (cenário #11) e uma pausa curta para alinhar a janela do #21; estado final `Ativo=1` (o original era 0).
- `PASSO_USUARIO` (processo 1029, passo 6): `vl_tempo_total_desassociar` 0 → 2 (#14; não restaurado, o processo é de teste).
- `TAREFA.dt_inicio` recuado em 900602 (−56 min), 900603 (−1436 min) e 900604 (−10076 min) (#10).
- `INSERT`: 2 linhas em `CAMPO_FORMULARIO` (processo 1031, campos 3 e 4 de tipo 5), 1 em `ANEXO`, 1 em `VERSAO_ANEXO` e 2 em `VERSAO_ANEXO_LIBERACAO` (fluxo 900597, usuários 1 e 25; o usuário 25 `qa_ct09_multiplos` já existia, nenhum usuário novo foi criado).
- `SELECT ... WITH (UPDLOCK)` por 110 s na `TAREFA` do fluxo 900703 (sem alterar dado).
- Segunda instância do Worker iniciada de cópia (removida depois); API net8 em `http://localhost:8081` (SQL Server); Scheduler e Worker reiniciados por mim às 08:43:48, porque a rotina estava inativa na partida e o job só é registrado no início (sem ciclos no log até o reinício).

## Resultado por cenário no SQL Server, com paridade em relação ao Oracle

| # | SQL Server | Evidência (SQL) | Paridade com o Oracle |
|---|---|---|---|
| 1 | **PASSOU** | Fluxos 900596 a 900598: Worker "Tarefa desassociada" às 08:44:02; `cd_usuario` e `dt_inicio` nulos, `cd_responsavel=2`, `id_tipo_responsavel=2` | Igual |
| 2 | **PASSOU** | `OPCAO_TAREFA` +1 por desassociação; `LOG_APLICACAO` aplicação 37 / ação 45 ("Usuário 1 se desassociou de um fluxo...") e aplicação 47 / ação 45 ("Desassociado Usuário: 1 - Fluxo: ... - Tarefa: 2") | Igual |
| 3 | **PASSOU** | Log do Worker com "Fluxo: N | Tarefa: M." (separador `|`), `Id`, `ChaveUnica` e `HashArgumentos` do job | Igual |
| 4 | **PASSOU COM RESSALVA** | `GET /api/JobConfig` (API em SQL Server): Id 12 listado | Igual (front não exercitado) |
| 5 | **PASSOU** | Fluxo 900600 (M3, 60 min): 0 inserções do Scheduler | Igual |
| 6 | **PASSOU COM RESSALVA** | Primeira inserção depois do prazo: 900602 (prazo 08:46:00, inserção 08:46:06); ciclos do Scheduler mais espaçados (~50 s) | Igual no resultado; resolução menor |
| 7 | **PASSOU** | 900596 sem inserção depois de 08:43:35 | Igual |
| 8 | **PASSOU** | 900599: M1 concluída, 0 inserções | Igual |
| 9 | **PASSOU** | 900598 desassociado, reassociado (08:46:03) e desassociado de novo às 08:49:01; novo job com a mesma chave | Igual |
| 10 | **PASSOU** | 900602 (hora), 900603 (dia), 900604 (semana): primeira inserção após o prazo (08:46:06 e 08:46:45); Worker 08:49:01 | Igual |
| 11 | **PASSOU COM RESSALVA** | `Ativo` 1→0 às 09:00:20: Scheduler parou (último ciclo 08:59:42), 0 inserções para o 900598 vencido; 0→1 às 09:04:25: retomou às 09:04:55 e enfileirou. Metade clássica: ver a seção "Agent clássico (SQL Server, 05/11)" e a de 06/11 (o clássico assumiu em 09:50 e em 10:22 com a rotina net8 desativada) | Igual (retoma em ~30 s; no Oracle 9 s) |
| 12 | **PASSOU** | M2 sem tempo (900599): nunca enfileirada | Igual |
| 13 | **PASSOU** | M1 com 2 min e M2 sem tempo no mesmo fluxo: M2 não enfileirada (JOIN por `cd_passo`) | Igual |
| 14 | **PASSOU** | 900601 (M4, usuário, `vl=2`, vencida desde 08:43:55): 0 inserções com a rotina ativa | Igual |
| 16 | **PASSOU** | Fluxo 900606 concluído com o job na fila; Worker 08:59:01 "Tarefa não está mais pendente... nada a fazer" e job com sucesso | Igual |
| 17 | **PASSOU** | Fluxo 900605: campo "usuário corrente" de "Papel Responsável Papel Default" para "Papel Responsável Papel Principal dos Processos" (Worker 08:59:01) | Igual |
| 18 | **PASSOU** | Fluxo 900597: liberação do usuário 1 apagada, a do usuário 25 mantida (Worker 08:54:01) | Igual |
| 19 | **PASSOU COM RESSALVA** | `JOB_CONFIG` Id 12 igual ao Oracle e ao script; `JOB_CONFIG_PADRAO` Id 12 está com `Ativo=1` no SQL Server (o script manda 0) | Igual no `JOB_CONFIG`; seed padrão difere do script |
| 20 | **PASSOU** | #1, #5 e #13 repetidos no SQL Server com o mesmo resultado | Igual |
| 21 | **PASSOU** | Segunda instância do Worker (cópia, `NLOG_LOGROOT` próprio): instância 1 de 09:24:01,5 a 09:24:03,7 e instância 2 de 09:24:03,0 a 09:24:03,7. A 1 processou 27 fluxos e a 2 processou 8, nenhum em comum; `OPCAO_TAREFA` no máximo 1 por fluxo; `LOG_APLICACAO` 35 + 35 | Igual |
| 22 | **FALHOU com valor nulo (reteste 05/11); PASSOU com lock de linha** | Lock de linha no fluxo 900703 (09:33:45): após ~30 s o Worker logou "Erro na execução. Fluxo: 900703, Tarefa: 2." e os fluxos 900704 e 900705 foram processados em seguida (09:34:31) | **DIFERENTE**: no Oracle a mesma espera ficou sem timeout (88 s) e travou o lote |
| 23 | **PASSOU** | Job 59563 em `FalhaParaRepetir` (1 tentativa), nova programação para 09:35:31 (+1 min), reexecução às 09:35:31, concluída às 09:35:36 depois da liberação do lock: "Tarefa desassociada", 1 linha em `OPCAO_TAREFA` e 1 log (sem duplicidade) | **DIFERENTE**: no Oracle ficou inconclusivo |
| 25 | **PASSOU COM RESSALVA** | 05/11, parâmetro 96 = 0: provado só no motor clássico (log 52084, ação 38, "pelo Engine Clássico"; 232 mensagens "Engine Clássico" e 0 "Nova API do Engine" na janela). 06/11, parâmetro 96 = 1 com nginx e API: ver seção "#25 com a API net8 do Engine". O log 52084 sai com `cd_usuario=0` e "pelo Sistema", não "pelo portal". | Igual ao Oracle (com ressalva) |
| 26 | **PASSOU COM RESSALVA** | Na janela do SQL Server (05/11 08:40 a 16:50): 0 `ERROR` no Scheduler; no Worker, 8 `ERROR` do #22 (2 por lock às 09:34, 6 por nulo às 16:42). O Worker tem outros 18 `ERROR` de Oracle (15:55 a 15:59), e o Scheduler tem 30 a 31 `ERROR` por job de Oracle entre 00:00 e 01:20 (fora da janela): os logs misturam os dois bancos. NotifyWf, ExcluiFluxoEmSolicitacao, InicioTemporal e AvancoTemporal rodando; ExecutaSql, ExecutaWs e InicioPublicacao sem linhas na janela. É verificação de ausência de erro, sem massa própria. | Igual (com a ressalva acima) |
| 24, 27 | Não executados | Agent clássico, etapa seguinte combinada com o usuário | n/a |

## Divergência entre bancos (achado)

O timeout de comando é diferente: no **SQL Server** o `UPDATE` bloqueado vira exceção em 30 s e o Worker segue (retry em 1 min); no **Oracle** o comando espera sem limite e **todo o lote fica parado**. Como o Worker processa em série, uma linha bloqueada por tempo indeterminado (ou o valor nulo do #22 no Oracle) pára a rotina inteira. Sugestão ao dev: configurar `CommandTimeout` também para Oracle. A reprodução do valor inicial nulo (que travou o Worker no Oracle) não foi repetida no SQL Server, porque exigiria derrubar o Worker de novo e um `UPDATE` de recuperação.

## Outras observações do SQL Server

- O Scheduler faz ciclos mais espaçados (~50 s) do que no Oracle (10 s); a janela entre prazo vencido e enfileiramento é maior.
- A rotina inativa na partida não registra o job; é preciso reiniciar depois de ativar.
- O relógio do SQL Server é local (`GETDATE()` igual ao da aplicação); o do Oracle estava 3 h à frente.
- Com o parâmetro 96 em 1, o web local depende do nginx de desenvolvimento; sem ele, o início de fluxo falha com "Erro inesperado" (`EngineService.IniciarFluxo`).


## Agent clássico (SQL Server, 05/11) — #27, #24 e metade clássica do #11

Evidência: `vista-no-banco` e `vista-em-log`. O serviço `SmartShareAgent` (clássico) roda como serviço Windows, build de 23/10/2026 16:13, cliente `GuizaoLocal`. Nenhum `DELETE`.

| Passo | Hora | Resultado |
|---|---|---|
| `UPDATE JOB_CONFIG` Id 12 `Ativo=1→0` (net8 desligado) | 09:48:43 | feito (valor original no SQL era 0) |
| Massa: fluxos 900704 e 900705 (processo 1028, papel 2 min), `cd_usuario`=1 e `dt_inicio` via `UPDATE` | 09:49 | 900705 expirado; 900704 não expirado no ciclo de 09:50 |
| Ciclo do clássico | 09:50 | desassociou o fluxo 900599 tarefa 3 (passo 4 sem tempo!), depois erro `0052` no mesmo fluxo e `SqlConnection não dá suporte para transações paralelas` ao tentar o 900705 |
| Ciclo do clássico | 09:55 | desassociou 900704 e 900705; `LOG_APLICACAO` tipo 47/ação 45 `Desassociado Usuário: 1 - Fluxo: N - Tarefa: 2` |

- **#11 clássico — passou:** com Ativo=1 o log de arquivo do clássico no dia não tem entrada; só aparece após Ativo=0. Quem agiu em cada janela é distinguível pelo log em arquivo (`DesassociarAutomatico_5_11_2026.log`, só o clássico grava) e pela ausência de duplicidade em `LOG_APLICACAO` após 09:48.
- **#27 — passou com ressalva:** o clássico segue desassociando com a rotina net8 desativada.
- **#24 — divergência:** o fluxo 900599 (processo 1029, passo 4 com `vl_tempo_total_desassociar`=0) foi desassociado pelo clássico porque o JOIN com `PASSO_USUARIO` não filtra `cd_passo`: a tarefa do passo 4 casa com os passos 3 (2 min) e 5 (60 min). Isso também gerou duas linhas para a mesma tarefa: a segunda falhou com `0052` e deixou a transação aberta, o que fez o 900705 falhar no mesmo ciclo (ficou para o ciclo seguinte). O net8 não desassocia passo sem tempo (#8). É o defeito que o PR 29228 corrige; **o build instalado do clássico não o contém** (confirmado pelo comportamento; a string do JOIN não aparece no exe).
- Controle: 900704 não foi um controle válido (2 min vencem antes do ciclo de 5 min).
- Não validado: build do clássico com o PR 29228; Oracle (cliente `SHAREGUIZAO` no mesmo serviço).
- Estado deixado: `JOB_CONFIG` Id 12 `Ativo=0` (original), parâmetro 96 = 0 (original 1), massa 900599 tarefa 3 agora sem usuário.

## Reteste do #22 no Oracle (05/11, 15:48 a 15:57) — ver etapa 05

Campo 543/1 voltou a nulo (`UPDATE` de 1 linha). Fluxos 2143 a 2145: jobs 36279, 36283 e 36284 terminaram em `FalhaParaRepetir` com `NullReferenceException` em `FluxoService.AtualizarValoresCorrenteCampoFormularioDaTarefa` (linha 7742); o Worker não travou desta vez e seguiu para os outros jobs. A tarefa vencida não foi desassociada (2 tentativas, mesma exceção). Análise de falha: [05-analise-falha.md](05-analise-falha.md), veredito SIM (defeito proposto, aguardando aprovação). O #22 no Oracle segue **FALHOU**, agora com causa confirmada no código.

## Reteste do #22 no SQL Server com o gatilho do Oracle (05/11, 16:37 a 16:53)

Correção da paridade: a rodada anterior do #22 no SQL Server usou lock de linha, não o valor nulo do Oracle. Agora repetido com Workers em `DBType=SQLServer`.

- **Valor inicial nulo** (processo 1031, campo 3 tipo 5): fluxos 900710 a 900712, jobs 59836 a 59838 em `FalhaParaRepetir` às 16:42:42 com `NullReferenceException` em `FluxoService.AtualizarValoresCorrenteCampoFormularioDaTarefa`. Tarefas continuaram associadas. **Igual ao Oracle: FALHOU no SQL Server também.**
- **Texto vazio** (`''`): fluxo 900713 desassociado normalmente às 16:48:42 (job 59859 com sucesso). Com o campo não nulo, as tarefas de 900710 a 900712 ficaram desassociadas nas retentativas.
- O #22 deixa de ser "PASSOU" no SQL Server: **FALHOU** (valor nulo), igual ao Oracle. O isolamento entre jobs (lock de linha) e o reagendamento (#23) continuam passando.
- Inferência (não confirmada): Oracle trata `''` como `NULL`, o que tornaria o problema mais frequente nele.
- Restaurado no SQL Server: campo 1031/3 = `[ds_usuario_corrente]`, parâmetro 96 = 1, `JOB_CONFIG` Id 12 `Ativo=0`. No Oracle, o campo 543/1 segue nulo.
- Bug #166161 recebeu um comentário com este resultado.

## Agent clássico com o fix do PR 29228 (SQL Server, 06/11) — #24

- **Build testado:** branch `feature/US160823-migracao-job-inicio-desassociar-automatico` do clássico (commit `4b2b504ec`), `SmartShareAgent.exe` compilado em 06/11 10:16 e confirmado com `cd_passo = T.cd_passo` no SQL (o instalado de 23/10 não tem). Instalado temporariamente: só `SmartShareAgent.exe`, `SmartShareAgent.Framework.dll` e `SmartShare.BPM.dll` copiados sobre o Agent, com backup completo prévio (406 arquivos).
- **Massa (via `UPDATE` de `TAREFA`):** 900599/3 (processo 1029, passo 4 sem tempo, associado há 120 min) e 900705/2 (processo 1028, passo 3 com 2 min, associado há 10 min). `JOB_CONFIG` Id 12 `Ativo=0` (net8 desligado).
- **Resultado:** ciclo de 10:22:47: Agent desassociou 900705 (log `DesassociarAutomatico` + `LOG_APLICACAO` 47/45); 900599 permaneceu associado. Ciclo de 10:27:47: sem alteração, sem nenhuma linha de erro (não ocorreram o `0052` nem a falha de transações paralelas do build antigo).
- **Ressalva:** a `VersaoAgent` que o build novo gravou em `ConfigAgent.xml` (3.84.4.26063) é menor que a do instalado (3.88.0.26296): a branch do PR parte de uma base mais antiga da `master`. Dev deve integrar a `master` antes do release. Oracle (cliente `SHAREGUIZAO`) não foi repetido.
- **Reversão feita (06/11, após o usuário parar o serviço):** os 3 arquivos e o `ConfigAgent.xml` (reescrito pelo Agent) restaurados do backup; comparação por hash de todos os arquivos do backup: nenhuma diferença. Ficaram 13 arquivos de log novos em `LOG\` e a pasta `Agent_backup_231026`. 900599/3 devolvido a sem usuário e sem `dt_inicio`. Serviço `SmartShareAgent` parado, partida Automática (como antes). `JOB_CONFIG` Id 12 `Ativo=0` e parâmetro 96 = 1, inalterados.
- Observação: durante o teste havia uma sessão de debug do Visual Studio (`SmartShareAgent.exe` de `bin\Debug`, iniciada às 10:17) do próprio usuário; sem logs de desassociação dela, a desassociação foi do serviço instalado.

## Rodada SQL Server com o build novo do net8 (06/11, 10:34 a 10:57) — #16, #21, #22, #23

Build: Workers recompilados em 05/11 17:04 a partir de `ab180c0f` (inclui `0c58397b` e `ab180c0f`, do Scheduler, posteriores ao build anterior). Workers com `DBType=SQLServer`, `JOB_CONFIG` Id 12 `Ativo=1`, parâmetro 96 = 0 (restaurados ao fim).

- **#21 e #22 e #23 (20 fluxos, processo 1031, 900714 a 900733):** lock de linha em `TAREFA` do fluxo 900720 (10:39:38 a ~10:43). Os outros 19 jobs foram processados e desassociados entre 10:40:10 e 10:40:13 (19 linhas em `LOG_APLICACAO` 47/45). O job 59932 (900720) falhou por timeout SQL (`Tempo Limite de Execução Expirado`) às 10:40:42 e 10:42:12 e teve sucesso na 3ª tentativa, às 10:44:12 (intervalos de 90 s e 120 s). Nenhum Id de job iniciado duas vezes fora dessas retentativas. **#22 isolamento: PASSOU; #23 reagendamento: PASSOU** (o #22 com valor nulo segue FALHOU, ver etapa 05).
- **#21 duas instâncias — PASSOU COM RESSALVA:** nenhuma duplicidade e há consumo concorrente (19 jobs em 3 s enquanto outro job ficou bloqueado 30 s; com `Max_Paralelo=1` por instância isso exige 2 consumidores). **Limites (double-check):** o log não traz PID/host (`instância: 1` é índice do job, não do processo), as duas cópias do Worker gravaram no mesmo arquivo, e a instância original não pegou nenhum job nesta rodada (só ciclos "sem itens"). Não há prova de disputa real pelo mesmo job nem de lease expirado. Por engano de script, 2 cópias do Worker foram iniciadas (10:39:56 e 10:39:57), além da original; todas as cópias foram paradas.
- **#16 — PASSOU:** fluxo 900740 concluído às 10:54:19 (`dt_termino`, por `UPDATE`, depois de enfileirado às 10:54:15). Worker às 10:56:23: "Tarefa não está mais pendente... nada a fazer", job com sucesso, nenhum `LOG_APLICACAO` de desassociação para o 900740; 900738 e 900739 desassociados. Limite: a conclusão foi simulada por `UPDATE` de `dt_termino`, não pela tela (a rodada de 05/11 usou a tela). Uma primeira tentativa (900734 a 900736) não deu certo por erro do meu loop e foi refeita.
- **Campo tipo 5 em branco pela tela — testado na tela (06/11, SQL Server) e CORRIGIDO:** a leitura de código sugeria que a tela gravaria `NULL`, mas o teste real mostrou o contrário. Processo rascunho 1032 "QA-161495 Branco", formulário e campo tipo de valor 5 salvos sem tocar no valor inicial: `CAMPO_FORMULARIO.ds_valor_inicial = [ds_usuario_solicitante]`. O servidor limpa a seleção (`CampoFormularioForm.ascx.cs:1019`), mas o navegador seleciona o primeiro item do combo e envia esse valor. **A tela não gera valor nulo**; o nulo dos testes foi criado por `UPDATE`/`INSERT`. A origem de um `NULL` real em produção segue não confirmada (importação, dados antigos, integrações: não verificados). O comentário anterior no Bug #166161 foi corrigido por um novo comentário.
- **#4 front — NÃO EXECUTADO:** o front de analytics usa `ENDPOINT_API: "/api"` relativo e precisa da mesma origem do Share (cookie); exigiria proxy local, que foi negado antes, e alterar a config do front.
- **Double-check por subagente Sonnet (somente leitura):** confirmou A (#22 nulo SQL, com a nuance de que as tentativas posteriores a 16:43 tiveram sucesso depois que o campo deixou de ser nulo), B, D; C parcial (ver acima); E confirmado quanto à causa e ao 900705, com "2 ciclos" apoiado só no relatório (o log de arquivo só grava quando o Agent age; o 2º ciclo, 10:27:47, não deixa registro) e o fluxo 900599/3 já revertido; F apontou o texto obsoleto "18 passou, 7 com ressalva" (corrigido) e que #20 passou por repetição de #1, #5 e #13 e não por teste próprio.
- **Restaurado:** `JOB_CONFIG` Id 12 `Ativo=0`, parâmetro 96 = 1, campo 1031/3 = `[ds_usuario_corrente]`, Workers e cópia temporária removidos. `JOB_BPM` sem jobs da rotina pendentes (restam 23 de outros jobs).
- **Massa nova do teste de tela (SQL Server, não removida):** processo 1032 "QA-161495 Branco" (rascunho, `id_status` 1), com o formulário "Form QA Branco" e o campo 1 (tipo de valor 5). Nenhum `DELETE` autorizado.

## #25 com a API net8 do Engine (SQL Server, 06/11, parâmetro 96 = 1) e double-check dos demais cenários

- **Problema inicial:** com 96 = 1, o Share clássico monta `/smartshare/api/api/auth` e `/smartshare/api/api/v1/engine/...` na própria origem (`EngineUriHelper`, `EngineService`, `AuthenticationService`). No IIS Express isso dá 404 ("Erro inesperado" ao iniciar fluxo). O nginx do ambiente (`D:
ginx`), que não estava rodando, também não tinha a rota.
- **Ajuste temporário (autorizado):** backup do `nginx.conf`; `location /smartshare/api/` apontando para `http://localhost:8081/` e cabeçalho `X-Original-URL` no `location /smartshare` (que o clássico lê em DEBUG); nginx subido na 8080; API net8 (`Engine.Api`) na 8081 com `DBType=SQLServer`. Share acessado por `http://localhost:8080/smartshare/`.
- **Resultado:** fluxo 900744 iniciado (log da API: `POST api/v1/engine/IniciarFluxo`, `LOG_APLICACAO` 112/40 "foi iniciado" e 112/39 "tarefa 1 avançada") e cancelado pela tela (Minhas Solicitações > Cancelar Fluxo): `POST api/v1/engine/CancelarFluxo`, `LOG_APLICACAO` 112/38 "foi cancelado", 0 tarefas restantes. Idem para o fluxo 900745. **Passou para Iniciar e Cancelar pela API net8 com 96 = 1.**
- **Não exercitado:** `AvancarFluxo` explícito (concluir uma tarefa de atividade) pela API. A atividade do processo 1031 não tem opção de conclusão na tela; o log da API tem só `IniciarFluxo` e `CancelarFluxo`.
- **Reversão:** nginx parado e `nginx.conf` restaurado do backup (hash idêntico, backup removido; só a data de modificação do arquivo mudou). API parada. Parâmetro 96 = 1 (original) e `JOB_CONFIG` Id 12 `Ativo=0`.

### Double-check por subagente Sonnet (somente leitura), #1 a #26 em SQL

- **CONFIRMADO:** #1, #2, #3, #5, #9, #10, #12, #13, #18. **CONFIRMADO COM RESSALVA:** #6 (limite exato só no teste unitário; ciclos do SQL de 30 a 50 s), #11, #14, #19, #26. **CONFIRMADO só por ausência de log (inferência):** #7, #8 (e #14). **#17:** só o estado final é verificável (o "antes" está só no relatório; o campo de e-mail não discrimina). **#25:** insuficiente para "PASSOU" sem ressalva (corrigido acima).
- **Lacunas apontadas:** (1) #7, #8, #12 e #14 provados por ausência de inserção; só #12 e #13 têm controle positivo (o clássico com bug desassociou 900599/3). (2) Os `UPDATE`s de `dt_inicio`, `PASSO_USUARIO` e `JOB_CONFIG` e os horários de liga e desliga não são auditáveis no banco; vêm só deste relatório. (3) As desassociações de 09:13:57 (900598 e 900607 a 900620) e os ciclos de 09:04 e 09:09 não aparecem no log do Worker: foram processadas por outro consumidor (a cópia do #21), cujo log não está na pasta. (4) A afirmação de que o Scheduler "só registra o job no início" e foi reiniciado às 08:43:48 não bate com o log, que mostra ciclos desde 08:32 e a inserção do 900596 às 08:42:34.

## Troca do ambiente para Oracle (06/11/2026, 11:34 a 11:40)

Executada passo a passo conforme indicado pelo dono do ambiente; procedimento registrado em `aprendizados/entradas/QA-KB-20261106-001.md`.

1. `webconfig.aspx` salvo com Provider `System.Data.OracleClient`, servidor/instância Oracle, usuário do schema, caminho virtual `/smartshare/` e usuário administrador `root`: "Configurações Salvas com Sucesso!". Efeito verificado: o `Web.config` do clássico mudou (`ConnectionString`, `ProviderName`, `ConnectionStringCalendar`, `CaminhoSmartShare`) e o `appsettings.json` da API passou a `DBType` = `Oracle` e `Schema` = `SHAREGUIZAO`.
2. Bloco `ConnectionStrings` copiado da API para os `appsettings.json` do Scheduler e do Worker BPM; JSON válido nos três e `DefaultConnection` idêntica.
3. Como os Workers leem a pasta `bin`, o `appsettings.json` dos dois foi copiado para `bin\Debug\net8.0`; Scheduler e Worker BPM iniciados às 11:37.
4. Conferência: log do Worker "Iniciando worker/Bpm SHAREGUIZAO" (antes `dbo`), sem `ERROR`; login do Share "licenciado para ... - Oracle". No Oracle: `JOB_CONFIG` Id 12 `Ativo=1`, parâmetro 96 = 0.
- Backup do estado anterior (SQL Server): `appsettings.json` dos três projetos e `Web.config` no scratchpad da sessão. Alterações locais de ambiente (aparecem no git); não commitar.

## Rodada Oracle com o build novo do net8 e o Agent clássico corrigido (06/11, 11:47 a 13:45)

Ambiente: troca para Oracle feita às 11:34 (seção anterior), Workers recompilados em 05/11 17:04 a partir de `ab180c0f`, `JOB_CONFIG` Id 12 `Ativo=1`, parâmetro 96 = 0. Os jobs antigos do NRE (fluxos 2143 a 2145) estavam em retentativa na fila e foram concluídos às 12:06 depois de restaurar o campo 543/1 (para não interferirem).

- **#21 e #22 isolamento — PASSOU (build novo):** 20 fluxos do processo 542 (2202 a 2221), lock de linha no 2209 e duas instâncias do Worker iniciadas juntas (original + cópia). 19 jobs processados em menos de 1 s cada; o job bloqueado (36453, cópia) ficou 80,3 s esperando e terminou com sucesso quando soltei o lock (12:18:04). Nenhum Id iniciado nas duas instâncias. O fluxo 2215 teve um 2º job (36472, 12:21:39) tratado como "nada a fazer". Limite: o log não traz PID; a cópia gravou em `worker2\Log` (não no `NLOG_LOGROOT`). Uma 1ª tentativa de lock (11:56) não coincidiu com o ciclo e foi descartada.
- **#23 reagendamento — PASSOU:** com o campo 543/1 nulo, 3 jobs (fluxos 2225 a 2227) falharam às 12:36:39 a 12:36:41 com `NullReferenceException` (`FalhaParaRepetir`), 2ª tentativa às 12:37:41 (+60 s) com o mesmo erro; após restaurar o campo, a tentativa seguinte desassociou os três (12:40). **Em Oracle o lock de linha não gera falha:** não há timeout de comando e o job só espera (80 s no #21/#22).
- **#22 com valor nulo — FALHOU de novo (build novo):** 6 `NullReferenceException` (3 jobs x 2 tentativas) em `FluxoService.AtualizarValoresCorrenteCampoFormularioDaTarefa`. Desta vez sem travamento do Worker e sem o atraso de 57 s da rodada de 05/11. Bug #166161; fix ainda não está no código.
- **#16 — PASSOU:** fluxo 2224 concluído por `UPDATE` de `dt_termino` às 12:30:12 (depois de enfileirado); Worker às 12:31:40: "nada a fazer", job com sucesso, sem desassociação; 2222 e 2223 desassociados. Conclusão simulada por `UPDATE`, não pela tela.
- **#20 — PASSOU COM RESSALVA:** #1 repetido (20 fluxos acima) e #13 repetido: fluxo 2066, tarefa 3 (processo 522, passo 4 sem tempo, associado desde 04/11 15:30) nunca foi enfileirado (0 jobs, 0 linhas nos logs de 06/11). O #5 (60 min) não foi repetido neste build.
- **#24 e #27 com o Agent clássico corrigido (PR 29228) — PASSOU:** `JOB_CONFIG` Id 12 `Ativo=0` no Oracle, Workers net8 parados, 3 binários do build de 06/11 10:16 instalados (backup `Agent_backup_231026`, instalado confirmado igual ao backup antes de copiar). O serviço (iniciado pelo usuário) desassociou o fluxo 2228 (papel de 2 min) às 13:31:18: log de arquivo `DesassociarAutomatico` do `SHAREGUIZAO` e `LOG_APLICACAO` 37/45 e 47/45. O controle 2066/3 (passo sem tempo) não foi tocado em pelo menos 3 ciclos (13:31, 13:36, 13:41), com 0 linhas de erro. O cliente SQL Server do mesmo serviço não gerou nada. Ressalva: o log de arquivo só grava quando o Agent age, então os ciclos sem ação só se provam pela ausência de erro e pelo estado da tarefa.
- **Intercorrência:** o Worker BPM caiu às 11:40 com `ORA-50000 Connection request timed out` depois de uma partida de 2,5 min (lentidão do Oracle na primeira conexão, mesma que fez a 1ª requisição do Share levar 36 s). Reiniciado às 11:47, subiu em 1 s e não repetiu.
- **Reversão (após o usuário parar o serviço):** 3 binários e `ConfigAgent.xml` restaurados do backup, comparação por hash de todos os arquivos do backup: nenhuma diferença (14 arquivos de log novos). `JOB_CONFIG` Id 12 do Oracle devolvido a `Ativo=1`. Campo 543/1 restaurado (`[ds_usuario_corrente]`). Parâmetro 96 = 0 (Oracle, valor com que estava). Serviço `SmartShareAgent` `Stopped`, partida Automática. Workers net8 parados. Massa nova não removida: fluxos 2163 a 2228 (processos 542 e 543). Nenhum `DELETE`.
