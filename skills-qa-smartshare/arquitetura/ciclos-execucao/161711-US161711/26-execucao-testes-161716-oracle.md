# Etapa 26 — execucao-testes — Bug #161716 (ExecutaWs, jobs duplicados) — ORACLE

- **Skill e argumentos:** `/arquitetura-executar-teste` — "execução do gate ORACLE, o necessário antes da execução, eu autorizo fazer" (09/11/2026)
- **Mapa:** [21-mapa-testes-bug-161716.md](21-mapa-testes-bug-161716.md) (local, não publicado)
- **Build:** branch do PR 30104, commit `e1396988`, worktree `Temp/wt30104` (Scheduler + Worker BPM, net8, Oracle `SHAREGUIZAO`)
- **Gate:** [00-validacao-ambiente-oracle.md](00-validacao-ambiente-oracle.md), LIBERADO COM RESSALVA (aceite do QA)
- **Status:** **CONCLUÍDA COM PENDÊNCIAS** — cenários 1, 2, 6 e 9 passaram (com ressalvas), 4 passou, 3 parcial; 5 (hipótese) e 7 (sem mecanismo) não executados; 8 inconclusivo (só Oracle). Serviços e mock encerrados ao fim.

## Preparação feita nesta rodada (com autorização)
| Ação | Escopo | Rollback |
|---|---|---|
| `UPDATE JOB_CONFIG SET ATIVO = 0 WHERE MODULO = 1 AND JOB <> 28` | 12 linhas; só o job 28 ativo | `ATIVO = 1` nos mesmos jobs (backup: `massa/backup-job_config-oracle-antes-execucao.txt`) |
| Mock HTTP `ferramentas/mock_ws_44303.py` na 44303 | log em `mock_ws_requests.log` | encerrar o processo |
| Mock ajustado para devolver `args.teste` | a consulta WS do Oracle exige o parâmetro de retorno `args.teste` | — |
| `appsettings.json` do Worker (`bin` do wt30104): `localhost:8080` para `localhost:58149` | sem nginx 8080 nesta máquina; backup `appsettings.json.orig-8080` | restaurar o `.orig-8080` |
| Scheduler e Worker do PR 30104 subidos | logs em `Log/JOB_BPM/ExecutaWs/` de cada projeto | encerrar os processos |

## Resultado por cenário
| # | Cenário | Resultado | Evidência |
|---|---|---|---|
| 1 | 101 fluxos WS sem duplicar job | **PASSOU COM RESSALVA** | 103 pendências (não 101). 1º ciclo do Scheduler: **100 linhas** em `JOB_BPM` (job 28, status 1), lido no Oracle e no log (`100` mensagens "inserido com sucesso"). Ao fim: `JOB_DUMP` com **103 sucessos, 103 chaves distintas, 0 chaves repetidas**; tarefas abertas no passo 11 = 0; `JOB_BPM` sem job 28. As 3 pendências além do limite de 100 entraram quando abriu vaga, sem duplicar. Ressalva: os primeiros ciclos falharam por ambiente (mock sem `args.teste`, depois endpoint SOAP 8080 inexistente) e foram reprocessados com sucesso depois dos ajustes; `JOB_BPM` não ganhou linha repetida nesse período |
| 2 | Pendência relida é ignorada com log | **PASSOU COM RESSALVA** | Com os 100 jobs ativos e o Worker parado, o Scheduler rodou ciclos a cada ~10 s e, em cada um, registrou "Job ExecutaWs não agendado: já existe uma execução pendente ou em andamento para a ChaveUnica ..."; `JOB_BPM` ficou em 100. Ressalva: a mensagem real não contém o literal `AlreadyActive` do mapa; o comportamento é o mesmo |
| 9 | 1 fluxo WS segue funcionando | **PASSOU** | Fluxo 2402: tarefa 3 (passo 11) concluída 14:50:13, tarefa 4 (passo 5) criada; 1 linha em `JOB_DUMP`; `JOB_BPM` vazio |
| 3 | Limite 99/100/101 | **PARCIAL (101+ observado)** | Com 103 pendências: 100 no 1º ciclo e o restante nos seguintes, sem duplicar. 99 e 100 não executados (massa consumida; recriar exige novos fluxos) |
| 4 | Chave na dump bloqueia só a mesma chave | **PASSOU** | Sem `INSERT` (autorizado, mas desnecessário): as chaves dos fluxos 2403, 2404 e 2405 já estavam em `JOB_DUMP` (Envenenado, cenário 6) com as tarefas ainda abertas. O Scheduler registrou, para cada uma, "não agendado. ChaveUnica ... foi localizada na tabela JOB_DUMP" e `JOB_BPM` ficou com 0 linhas dessas chaves. Fluxo novo 2406 (chave B, mock ok): job criado, concluído (`JOB_DUMP` status 3), tarefa 3 fechada 15:11:42 e tarefa 4 aberta |
| 5 | HIPOTESE: duas instâncias do Scheduler | **NÃO EXECUTADO** (hipótese) | restrição do mapa |
| 6 | Endpoint WS fora do ar | **PASSOU COM RESSALVA** | Mock em 500 e 3 fluxos novos (2403, 2404, 2405; desvio: 3 em vez de 101). `JOB_BPM` ficou em **3 linhas** durante toda a espera (status 4, `Qt_de_Tentativas` subindo 1 a 4, ciclos de ~10 s do Scheduler), sem recriar job. Ao esgotar as 5 tentativas (~16 min) os 3 jobs saíram de `JOB_BPM` e entraram em `JOB_DUMP` com status **5 (Envenenado)**, 1 linha por chave, 0 repetidas; as 3 tarefas seguem abertas no passo 11. Ressalva: leitura de log por consulta, 3 fluxos, não 101. Observação já feita antes com 100 linhas em FalhaParaRepetir (cenário 1) também não gerou duplicata |
| 7 | Falha ao enfileirar 1 pendência | **NÃO EXECUTADO** | mecanismo não definido pelo dev (DUV-02) |
| 8 | SQL Server e Oracle | **INCONCLUSIVO** | só Oracle nesta rodada; o gate do SQL Server expirou |

## Desvios e riscos registrados
- 103 pendências em vez de 101.
- Ajustes de ambiente acima (mock, 58149) não são do PR.
- O defeito original (134 registros, 33 duplicados) não ocorreu nesta branch: 0 duplicados.
