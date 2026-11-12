# Etapa 27 — execucao-testes — Bug #161713 (ExecutaSql não envenena o job) — ORACLE

- **Skill e argumentos:** `/arquitetura-executar-teste` — "execução do gate ORACLE, o necessário antes da execução, eu autorizo fazer" (09/11/2026)
- **Mapa:** [22-mapa-testes-bug-161713.md](22-mapa-testes-bug-161713.md) (local, não publicado)
- **Build:** branch do PR 30060, commit `d4a98152`, worktree `Temp/wt30060` (Scheduler + Worker BPM, net8, Oracle `SHAREGUIZAO`)
- **Gate:** [00-validacao-ambiente-oracle.md](00-validacao-ambiente-oracle.md), LIBERADO COM RESSALVA (a falha do passo SQL é por conexão, aceito pelo QA)
- **Status:** **CONCLUÍDA COM PENDÊNCIAS**

## Preparação (com autorização)
| Ação | Escopo | Rollback |
|---|---|---|
| `UPDATE JOB_CONFIG`: job 28 `ATIVO` 0, job 19 `ATIVO` 1 | 2 linhas | inverso (backup em `massa/backup-job_config-oracle-antes-execucao.txt`) |
| `UPDATE JOB_BPM SET QT_DE_TENTATIVAS = 4` | linhas 37785 (fluxo 2408), 37786 (fluxo 2409), 37787 (fluxo 2410); só fluxos de teste | linhas saem de `JOB_BPM` ao terminar |
| Processo 581: preencher "Título do Fluxo" pela tela | massa; ver observação ORA-01407 | apagar o título |
| `appsettings.json` do Worker (bin do wt30060) `8080` para `58149` | sem nginx 8080 nesta máquina | restaurar `appsettings.json.orig-8080` |
| Fluxos criados | 2407 e 2408 (processo 561, sem escape), 2409 e 2410 (processo 581, com escape) | cancelar/excluir pela tela |

## Resultado por cenário
| # | Cenário | Resultado | Evidência |
|---|---|---|---|
| 1 | Retry quando ainda há tentativa | **PASSOU COM RESSALVA** | Fluxo 2407 (561): 1ª execução falhou (`OleDbException`: "SQL Server inexistente ou acesso negado", pela conexão 1), job foi para `FalhaParaRepetir` com `Qt_de_Tentativas` = 1 e subiu 2, 3, 4 nos ciclos seguintes; tarefa seguiu aberta no passo 5. Ressalva: a falha é por conexão, não por SQL inválido; variável de erro e ocorrência não foram consultadas |
| 2 | Esgotada, escape avança | **PASSOU COM RESSALVA** | Fluxo 2410 (581) com `Qt_de_Tentativas` = 4: o job avançou pelo escape. `TAREFA` 3 no passo 16 encerrada 15:22:37, fluxo concluído (foi para `HISTORICO_FLUXO`/`HISTORICO_TAREFA`), `JOB_DUMP` com status **3 (Sucesso)**, **não** Envenenado. Ressalva: variável de erro e `NotificaOcorrencia` não verificadas (sem configuração para isso nesta massa) |
| 3 | Esgotada, sem passo de escape | **PASSOU** | Fluxo 2408 (561) com `Qt_de_Tentativas` = 4: `JOB_BPM` zerou e `JOB_DUMP` recebeu o job com status **5 (Envenenado)**, `Qt_de_Tentativas` = 5; erro logado; tarefa segue aberta no passo 5 (não terminou como sucesso) |
| 4 | Esgotada, escape falha ao avançar | **PASSOU (falha real, não provocada)** | Fluxo 2409 (581): o escape tentou avançar e falhou com `ORA-01407` (`FLUXO.DS_FLUXO` para NULL, porque o processo 581 estava sem "Título do Fluxo"). Log: "Erro ao avançar para o passo de escape do ExecutaSQL" e "Não avançou para o passo de escape". Job **Envenenado** com linha em `JOB_DUMP` (id 37786, `Qt` 5); tarefa aberta no passo 10 |
| 5 | Pendência envenenada não volta à fila | **PASSOU** | Sem `INSERT`: as chaves 2407, 2408 e 2409 já estavam em `JOB_DUMP` (envenenadas, cenários 1, 3 e 4) com as tarefas abertas. O Scheduler registrou 71 vezes para cada chave: "não agendado. ChaveUnica ... foi localizada na tabela JOB_DUMP, job já foi processado anteriormente"; `JOB_BPM` ficou com 0 linhas dessas chaves |
| 6 | Duas políticas de backoff | **PASSOU COM RESSALVA** | 2ª rodada (10/11), com `UPDATE JOB_CONFIG.POLITICA_BACKOFF` do job 19 autorizado (rollback para 0, feito). Política 1 (`FixedDelay`, fluxos 2416 a 2419): `DATA_PROGRAMADA` menos `DATA_ATUALIZACAO` = 60 s em todas as tentativas (17:07:16→17:08:16, 17:08:36→17:09:36, 17:10:13→17:11:13, 17:11:48→17:12:48). Política 2 (`Exponential`, fluxo 2420, job 37941): 60 s (qt 1), 120 s (qt 2), 240 s (qt 3) e 480 s (qt 4), conforme `BackoffCalculator` (60 s × 2^(n-1)). Política 0 (Linear) observada na 1ª rodada. Os 4 jobs da política 1 foram envenenados no limite (`JOB_DUMP` status 5, `Qt` 5). Ressalva: a falha é por conexão, não por SQL inválido. O job 37941 ficou em `JOB_BPM` (status 4, qt 4) |
| 7 | Limite de tentativas | **PASSOU COM RESSALVA** | N = 5. Fluxo 2407: tentativas 1 a 4 reagendaram (`FalhaParaRepetir`); na 5ª foi **Envenenado** (`JOB_DUMP`, `Qt` 5). Fluxos 2408 e 2410 partiram de `Qt` = 4 e foram direto ao tratamento definitivo (envenenado/escape). Ressalva: só com falha por conexão |
| 8 | SQL Server e Oracle | **INCONCLUSIVO** | só Oracle nesta rodada (gate do SQL Server expirou) |
| 9 | ExecutaSql sem erro | **INCONCLUSIVO** | a conexão 1 é um SQL Server de exemplo; um SQL válido também falharia por conexão |
| 10 | HIPOTESE: erro não reagendável | **NÃO EXECUTADO** | hipótese; mecanismo não definido |

## Observações investigativas (não são resultado de cenário)
- **ORA-01407 no escape (Oracle, processo sem título de fluxo).** `Título do Fluxo` vazio vira NULL no Oracle e o `UPDATE` de `DS_FLUXO` no avanço pelo escape falha. Pode ser limitação do Oracle com a massa (título obrigatório na prática) ou lacuna do produto. Com o título preenchido o escape funcionou (cenário 2). Registrar para o dev/PO, **não** como `FALHOU`.
- Falha do passo SQL por conexão em vez de SQL inválido (decisão do QA).
