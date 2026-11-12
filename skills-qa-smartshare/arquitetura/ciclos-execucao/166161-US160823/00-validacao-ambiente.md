# Validação de ambiente — US #160823 / Mapa #161490 — Reteste Modo B do Bug #166161

**Status do gate:** LIBERADO PARA EXECUÇÃO — fase SQL Server (atualização de 10/11/2026 16:45, ver seção "Atualização"). Fase Oracle: gate próprio após a troca de banco. O texto abaixo é o estado antes da autorização.
**Ambiente:** local (máquina do QA), não produtivo. Share clássico `http://localhost:58149/SmartShare/` (IIS Express), net8 em Debug.
**Banco(s):** SQL Server (`NOTE-74VQ\SQLEXPRESS`, banco `ShareGuizao`, schema `dbo`, SQL Server 2019 Express) e Oracle (`SSHARE`, schema `SHAREGUIZAO`, Oracle 19c SE2).
**Build/commit:** PENDENTE. Clone net8 em `ab180c0f`, branch `feature/US160823-migracao-job-inicio-desassociar-automatico`, 1 commit atrás de `origin/...`. O fix é o commit `6b23a794` (Luis Bertucci, 09/11/2026, `FluxoService.cs`). Binários dos Workers e da API de 05/11/2026 17:04, anteriores ao fix.
**RUN_ID:** 20261110-166161-MODOB
**Escritas nesta validação:** nenhuma (somente leitura). Nenhum serviço subido, nenhuma troca de banco, nenhum `git pull`.
**Assinatura de contexto:** mapa #161490, `ChangedDate` 2026-11-04T14:46:40.833Z; ambiente local; build alvo `6b23a794`; SQL Server `NOTE-74VQ\SQLEXPRESS/ShareGuizao/dbo`; Oracle `SSHARE/SHAREGUIZAO`.
**Escopo (lista aprovada pelo QA em 10/11/2026):** #22 (valor nulo e vazio), #23, #1, #2, #17, #24, #25, #26, #27, nos dois bancos. Fora da lista: #16, #21, #4, #5.

## Resumo
| Dimensão | Status | Evidência | Pendência |
|---|---|---|---|
| MCP Azure DevOps | OK | Bug #166161, comentários e mapa #161490 lidos em 10/11 | nenhuma |
| Acesso SQL Server | OK (`ADAPTER_LOCAL`) | `sqlcmd -E` conectou: `ShareGuizao`, `dbo`, SQL Server 2019 | nenhuma |
| Acesso Oracle | OK (`ADAPTER_LOCAL`) | `sqlplus` conectou: `SHAREGUIZAO`, `SSHARE`, 19c. Credencial lida do arquivo de variáveis em tempo de execução, por stdin | nenhuma |
| Ambiente não produtivo | OK | máquina local; Oracle é o schema pessoal de QA (`Variveis de Ambiente`, seção 3) | nenhuma |
| Share clássico | OK | IIS Express (PID 18148) respondeu HTTP 403 na raiz `/SmartShare/` (processo vivo); `Web.config` com `System.Data.SqlClient` | login real só na execução |
| Build com o fix | **PENDENTE** | HEAD `ab180c0f`, remoto tem `6b23a794`; bin de 05/11 | PR-05 |
| Serviços net8 | PENDENTE | Scheduler e Worker BPM parados; API 8081 fora do ar | subir na execução (PR-06) |
| Troca de banco | PENDENTE | Share e Workers em SQL Server; `appsettings` da API em Oracle | PR-07 |
| Massas | PENDENTE | ver matriz | escritas não autorizadas (PR-08 a PR-12) |

## Pré-requisitos do ambiente
| ID | Cenários | Pré-requisito | Fonte | Evidência | Status | Pendência/ação |
|---|---|---|---|---|---|---|
| PR-01 | todos | MCP Azure DevOps | ferramenta | leitura de #166161, #161490 | OK | — |
| PR-02 | todos | Acesso a SQL Server e Oracle | `sqlcmd`, `sqlplus` | probes read-only em 10/11 | OK | — |
| PR-03 | todos | Ambiente não produtivo | máquina local, schema pessoal | host local; schema `SHAREGUIZAO` do QA | OK | — |
| PR-04 | todos | Fix `6b23a794` está na branch remota | `git cat-file`, `git branch -a --contains` | `origin/feature/US160823-...` contém o commit; diff: `?.ToLower() ?? string.Empty` em `FluxoService.cs` (~7749 e ~8002) | OK | — |
| PR-05 | todos | Clone local e binários com o fix | git, `bin\Debug\net8.0` | HEAD `ab180c0f`, 1 commit atrás; `Project.Core.Application.dll` de 05/11 17:04 | **PENDENTE** | `git pull --ff-only` (só traz `FluxoService.cs`; os 3 `appsettings.json` locais modificados não conflitam), `dotnet build` dos Workers (SDK 10.0.403 presente). Liberação: HEAD = `6b23a794` e DLL com data nova |
| PR-06 | #1, #2, #16, #17, #22, #23, #26 | Scheduler e Worker BPM no ar, logs acessíveis | processos, logs | nenhum `Project.*`/`SmartShareAgent*` em execução | **PENDENTE** | subir na execução após PR-05; serviços Windows `SmartShareAgent*` seguem parados (clássico só no #24/#27) |
| PR-07 | todos | Banco do Share, API e Workers coerentes por fase | `Web.config`, `appsettings.json` | Share e Scheduler/Worker em `SQLServer/dbo`; API em `Oracle/SHAREGUIZAO` | **PENDENTE** | Fase SQL Server: API não é necessária (parâmetro 96 = 0). Fase Oracle: troca por `webconfig.aspx` + 3 `appsettings.json` (`QA-KB-20261106-001`, direção SQL→Oracle executada em 06/11); alteração de configuração local, pede OK |
| PR-08 | todos | `JOB_CONFIG` Id 12 (Módulo 1, Job 34, 300000 ms, Max_Paralelo 1) ativo | leitura | SQL Server: `Ativo=0`; Oracle: `Ativo=1` | **PENDENTE** (SQL Server) | `UPDATE` autorizado (W1); Oracle já ativo |
| PR-09 | #25 e fluxos | Parâmetro 96 (nova API do Engine) | leitura | `0` nos dois bancos | OK | `0` mantém o motor clássico; fluxo inicia sem API 8081. Sem escrita |
| PR-10 | #1, #2, #16, #17, #26 | Processo com passo de papel, tempo de desassociar 2 min e campos tipo 5 | leitura | SQL Server: processo 1031 v1, passo 3, `vl_tempo_total_desassociar=2`, `id_tempo_desassociar=0` (min), executor 2; campos 3 `[ds_usuario_corrente]` e 4 `[ds_email_corrente]`. Oracle: processos 542 v1 (campos 3 e 4) e 543 v1 (campo 1 `[ds_usuario_corrente]`, passo 3, 2 min, executor 2) | OK | fluxos nascem pela tela durante a execução (não são massa prévia) |
| PR-11 | #1, #17 | Papel executor 2 com usuário associável | leitura | `PAPEL_USUARIO`: papel 2 com 1 usuário nos dois bancos; `root` existe nos dois | OK | `qa.usuario2` não existe no SQL Server; os cenários da lista não o usam |
| PR-12 | #22 | Campo tipo 5 com `ds_valor_inicial` nulo e vazio | leitura | valores atuais restaurados (não nulos): SQL Server 1031/1/3; Oracle 543/1/1 | **PENDENTE** | `UPDATE` autorizado (W2, W3). Condição só existe por `UPDATE` (a tela grava `[ds_usuario_solicitante]`, comentário do Bug de 06/11): registrar como `HIPOTESE:` e observação investigativa |
| PR-13 | #23 | Mecanismo de falha reagendável limpa | execução anterior (`04-execucao-testes.md` #22/#23) | SQL Server: lock de linha em `TAREFA` gera "Erro na execução" após ~30 s e `FalhaParaRepetir` (passou em 05/11). Oracle: lock sem timeout, Worker espera 88 s e trava o lote; nulo era o outro mecanismo e agora está corrigido | **PENDENTE** | SQL Server: transação com lock na linha da tarefa (sem alterar dado), pede OK (W4). Oracle: não há mecanismo comprovado; decisão do QA (ver abaixo) |
| PR-14 | #24, #27 | Agent clássico com o fix do PR 29228 (JOIN por `cd_passo`) | `D:\Instalação Share\Agent` | `SmartShareAgent.exe` 3.88.0.26296, 23/10, igual ao backup `Agent_backup_231026`: sem o PR 29228 | **PENDENTE** | decisão do QA: usar o instalado com ressalva (como no #27 de 05/11) ou compilar o build do PR 29228 |
| PR-15 | #26 | Logs do Worker e Scheduler legíveis | `NLOG` | mesmos logs usados em 05/11; leitura de `ERROR` na janela da rodada | OK | janela da rodada fixada na execução |
| PR-16 | #25 | Login no Share (`root`) e fluxo Cancelar/Concluir | arquivo de variáveis | usuário existe nos dois bancos; Share vivo | OK | login real só na execução |

## Matriz de massas
| Cenário | Banco | Requisito de massa | Resultado | IDs | Evidência |
|---|---|---|---|---|---|
| #1, #2 | SQL Server | passo de papel, 2 min, executor 2 | EXISTENTE E CONFIRMADA | processo 1031 v1 passo 3 | PR-10 |
| #1, #2 | Oracle | idem | EXISTENTE E CONFIRMADA | processo 543 v1 passo 3 | PR-10 |
| #17 | SQL Server | campos tipo 5 `[ds_usuario_corrente]`/`[ds_email_corrente]` | EXISTENTE E CONFIRMADA (criados por `INSERT` autorizado em ciclo anterior; sem caminho pela tela: **hipótese herdada**) | 1031 v1 campos 3 e 4 | PR-10 |
| #17 | Oracle | idem | EXISTENTE E CONFIRMADA (idem) | 542 v1 campos 3 e 4 | PR-10 |
| #22 nulo | SQL Server | campo 3 do 1031 com `NULL` | AUSENTE (hoje não nulo) | 1031/1/3 | PR-12 |
| #22 vazio | SQL Server | mesmo campo com `''` | AUSENTE | 1031/1/3 | PR-12 |
| #22 nulo e vazio | Oracle | campo 1 do 543 com `NULL` (Oracle grava `''` como `NULL`: os dois casos são o mesmo estado) | AUSENTE | 543/1/1 | PR-12 |
| #23 | SQL Server | lock de linha em `TAREFA` do fluxo | AUSENTE (criado na execução) | — | PR-13 |
| #23 | Oracle | falha reagendável | NÃO VALIDADA (sem mecanismo) | — | PR-13 |
| #24, #27 | ambos | Agent clássico com PR 29228 | NÃO VALIDADA | `Agent` 23/10 | PR-14 |
| #25, #26 | ambos | sem massa própria | NÃO APLICÁVEL (usam fluxos e logs da rodada) | — | — |

## Autorizações de escrita solicitadas (nada executado)
| ID | Banco | Objeto | Operação | Filtro | Linhas | Finalidade | Rollback |
|---|---|---|---|---|---:|---|---|
| W1 | SQL Server | `JOB_CONFIG` | `UPDATE Ativo = 1` | `Id = 12` | 1 | ativar a rotina para o Worker processar | `Ativo = 0` ao fim (valor original) |
| W2 | SQL Server | `CAMPO_FORMULARIO` | `UPDATE ds_valor_inicial = NULL`, depois `= ''` | `cd_processo=1031 AND cd_versao_processo=1 AND cd_campo=3` | 1 | #22: reproduzir a condição do Bug com o fix | `= '[ds_usuario_corrente]'` ao fim |
| W3 | Oracle | `CAMPO_FORMULARIO` | `UPDATE ds_valor_inicial = NULL` | `cd_processo=543 AND cd_versao_processo=1 AND cd_campo=1` | 1 | #22 (nulo = vazio no Oracle) | `= '[ds_usuario_corrente]'` ao fim |
| W4 | SQL Server | `TAREFA` | lock de linha por transação aberta (nenhum dado alterado) | tarefa do fluxo de teste | 1 | #23: forçar falha reagendável | `ROLLBACK` da transação |

Sem `DELETE`. `JOB_CONFIG` do Oracle já está `Ativo=1`. Parâmetro 96 não muda.

## Decisões do QA (abertas)
1. **OK para `git pull --ff-only` e rebuild dos Workers** (PR-05). Altera só o clone local.
2. **OK para a troca de banco para Oracle na 2ª fase** (PR-07), no fim da fase SQL Server.
3. **#23 no Oracle:** não há mecanismo de falha limpa (nulo corrigido, lock sem timeout trava o lote). Opções: (a) o dev indica um mecanismo no Oracle; (b) registrar `INCONCLUSIVO` com a tentativa já feita em 05/11.
4. **#24/#27:** usar o Agent clássico instalado (sem PR 29228, com ressalva) ou compilar o build do PR 29228.

## Pendências bloqueantes
- PR-05, PR-06, PR-07, PR-08, PR-12, PR-13 e PR-14, descritas acima. Condição de liberação: build em `6b23a794` confirmado, W1 a W4 autorizadas, decisões 3 e 4 tomadas, e fase atual com Share, Workers e `JOB_CONFIG` alinhados ao mesmo banco.

## Decisão
**PAUSADO.** Não executar nenhum cenário até o QA autorizar as escritas e confirmar as decisões. Depois disso, aplicar o PR-05, reconferir por leitura e emitir `LIBERADO PARA EXECUÇÃO` para a fase SQL Server; repetir o gate para a fase Oracle após a troca de banco.

## Atualização — 10/11/2026 (QA autorizou "tudo": pull, rebuild, W1 a W4 e troca para Oracle)

**Status do gate (fase SQL Server): LIBERADO PARA EXECUÇÃO.**

| ID | Status | Evidência |
|---|---|---|
| PR-05 | OK | `git pull --ff-only`: `ab180c0f` para `6b23a794` (só `FluxoService.cs`, 4 inserções, 2 remoções). `dotnet build` de Worker BPM e Scheduler com êxito; `Project.Core.Application.dll` de 10/11 16:41; `appsettings.json` das `bin` com `DBType=SQLServer` |
| PR-06 | OK (a subir na execução) | executáveis `SmartShareAgent_BpmWorker.exe` e `SmartShareAgent_SchedulerWorker.exe` presentes em `bin\Debug\net8.0` |
| PR-07 | OK para SQL Server | Share, Scheduler e Worker em `SQLServer/dbo`; API não usada (parâmetro 96 = 0) |
| PR-08 | OK | **W1 executado**: `UPDATE JOB_CONFIG SET Ativo=1 WHERE Id=12 AND Ativo=0`, 1 linha; releitura `Ativo=1`. Restaurar para `0` ao fim |
| PR-12 | AUTORIZADO, aplicado no passo do #22 | W2 (SQL Server) e W3 (Oracle) executam imediatamente antes do #22 em cada fase, com restauração ao fim |
| PR-13 | AUTORIZADO, aplicado no passo do #23 | W4 (lock de linha, sem alterar dado) só no SQL Server. Oracle: premissa do QA (não escolhida explicitamente): `INCONCLUSIVO` com a tentativa de 05/11 |
| PR-14 | Premissa | Agent clássico instalado (23/10, sem PR 29228) com ressalva; QA não escolheu explicitamente |

**Massas criadas nesta validação:** nenhuma linha nova; só o `UPDATE` de configuração W1 (reversível).
**Limpeza/restauração planejada:** `JOB_CONFIG` Id 12 `Ativo=0` (SQL Server); `CAMPO_FORMULARIO` 1031/1/3 e 543/1/1 para `[ds_usuario_corrente]`; `ROLLBACK` do lock.
**Troca para Oracle:** autorizada; executa no fim da fase SQL Server, seguida de novo gate Oracle.

## Atualização Oracle — 10/11/2026 17:10 (gate PAUSADO)

**Troca de banco feita (autorizada pelo QA):** `webconfig.aspx` salvo com "Configurações Salvas com Sucesso!" (Provider `System.Data.OracleClient`, Caminho Virtual `/smartshare/`); `Web.config` do clássico em `OracleClient` e `appsettings.json` da API reescrito (`DBType=Oracle`, `Schema=SHAREGUIZAO`). Bloco `ConnectionStrings` da API copiado para `appsettings.json` (fonte e `bin\Debug\net8.0`) do Scheduler e do Worker BPM (`DBType=Oracle`). Backups do estado SQL Server em `scratchpad\bak-sqlserver` (Web.config e 3 appsettings). Workers parados.

**Leitura Oracle (17:08):** `JOB_CONFIG` 12 `Ativo=1`; parâmetro 96 = 0; campos tipo 5 de 542 (3 e 4) e 543 (1) com valores normais; 2 tarefas antigas elegíveis (processos 542/543).

**Pendência bloqueante (PR-17):** a fila `JOB_BPM` do Oracle tem resíduos de outra US que o Worker vai processar ao subir: `NotifyWf` (jobs 9: NotificaTarefa dos fluxos 2411, 2414, 2415, NotificarAlertas, NotificarMensagemExcecaoAlcada), `ExecutaSql` (job 19: fluxos 2417 a 2420, passo 5), `ExcluiFluxoEmSolicitacao` (18) e `EnviaAlertaFluxo` (32). Subir o Worker consumiria essa massa e poderia enviar notificações. Decisão do QA: (a) subir assim mesmo; (b) autorizar `UPDATE JOB_CONFIG SET Ativo=0` para os jobs 9, 18, 19 e 32 durante a rodada, com restauração; (c) outra.

## Atualização Oracle — 10/11/2026 17:20 (gate fase Oracle: LIBERADO COM AUTORIZAÇÕES; rodada executada)

- **PR-17 resolvido:** QA escolheu "Desativar e restaurar". `UPDATE JOB_CONFIG SET Ativo=0` nos jobs 9, 18, 19 e 32 (Ids 8, 28, 29 e 24, todos `Ativo=1` antes), 4 linhas, conferido por leitura. Restaurados a `Ativo=1` ao fim (conferido).
- **W3 executado:** `CAMPO_FORMULARIO` 543/1/1 `ds_valor_inicial` para `NULL`; restaurado a `[ds_usuario_corrente]` ao fim (conferido). `JOB_CONFIG` Id 12 já estava `Ativo=1` (sem escrita).
- **Serviços:** Worker BPM e Scheduler no Oracle (`Iniciando worker/Bpm SHAREGUIZAO`, 0 erros), parados ao fim.
- **Estado final do ambiente:** Share, API, Scheduler e Worker apontam para Oracle (`SHAREGUIZAO`); backups do estado SQL Server no scratchpad (`bak-sqlserver`). SQL Server restaurado: `JOB_CONFIG` 12 `Ativo=0`, campo 1031/1/3 `[ds_usuario_corrente]`.
- **Observação:** o relógio do servidor Oracle (`SYSDATE`) está 3 h à frente da máquina; as datas gravadas pela aplicação seguem a hora local.
