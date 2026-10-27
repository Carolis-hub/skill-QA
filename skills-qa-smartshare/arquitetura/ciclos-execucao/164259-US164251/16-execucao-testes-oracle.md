# Etapa 16 — Execução de Testes (ORACLE) — #164251 [BUG] Ajustar regra de leitura de status no BPM

- **Skill:** `/executar-teste 164251`, Modo A. Rodada **Oracle**; a rodada SQL Server são as etapas 05 a 13.
- **Data:** 2026-10-27 08:36–09:03
- **Escreveu no Azure DevOps?** Não
- **Escreveu no banco?** Sim, no Oracle `SHAREGUIZAO` (QA pessoal), com autorização no chat em 2026-10-27:
  - subir o Worker BPM e o Scheduler;
  - montar linhas `qa-us164251-ora-*` em `JOB_BPM`/`JOB_DUMP`, com limpeza;
  - alterar o `JOB_CONFIG` por um tempo e restaurar;
  - subir a 2ª instância;
  - rodar o job 32 com envio real de alertas.
- **Decisões do QA (Guilherme Henrique Correa Borges):** versão `d9784d80`, a mesma da rodada SQL. Escrita em Worker, `JOB_BPM` e `JOB_CONFIG` liberada. Job 32 com envio real liberado.
- **Fontes:**
  - card #165040, revisão 6 (27 cenários; #25 removido);
  - US #164251;
  - `smartshare-net8`: `JobBpmRepository.GetJobsTravados`/`ClaimJobTravado`, `DBTranslator.OracleClaimJobTravado`/`OracleGetJobs`, `BpmExecJob.MoverJobsTravadosParaDump`, `EnviaAlertaFluxoExecHandler`;
  - variáveis de ambiente do Oracle: `arquitetura\Variveis de Ambiente` (credencial não registrada aqui).

## Ambiente

- **Banco:** Oracle, schema `SHAREGUIZAO`, RDS `ss-oracle-br-3` (serviço `SSHARE`). Não é HMG.
  - **Fuso:** o `SYSDATE` do RDS está em **UTC**, e a sessão e o Worker usam -03:00. Por isso as montagens usaram `LOCALTIMESTAMP`, o mesmo relógio do `DateTime.Now` do Worker.
- **Worker BPM:** console, branch `bugfix/US164251-bpm-correcao-job-travando-execucao`, commit `d9784d80`. Foi o mesmo build da rodada SQL; só o `appsettings.json` do `bin` foi trocado pelo da branch (`DBType = Oracle`) e restaurado no fim.
  - Log em `evidencias\oracle\worker1-log` (instância 1) e `evidencias\oracle\worker2-log` (instância 2).
  - O remoto tem um commit mais novo (`b89ad1dc`, merge da main com o handler InicioPublicacao). A lógica da correção não muda nele.
- **Scheduler:** console, mesmo commit, Oracle, log em `evidencias\oracle\scheduler-log`.
- **Serviços instalados** (`SmartShareAgent_BPM_Borges`, `SmartShareAgent_Scheduler_Borges`, `SmartShareAgent`): **parados** durante toda a rodada, sem concorrer.
- **`JOB_CONFIG` no Oracle é diferente do SQL:**
  - os **12 jobs estão ativos**: 7, 8, 9, 16, 18, 19, 22, 25, 28, 32, 33, 34;
  - o job 8 cicla a cada **15 min**; o 19 a cada 30 s; 9, 18 e 28 a cada 60 s; o 7 a cada 5 min; o 32 no cron 00:00;
  - o job 20 não tem `JOB_CONFIG`.
- **E-mail no Oracle:** `EMAIL_CONFIGURACAO` com autenticação tipo 3, remetente `guilherme.borges@selbetti.com.brrrrr` e sem SMTP. Não foi alterado; a falha de envio do #22 aconteceu sozinha.
- **Estado antes:** `sql\oracle\00-estado-antes-saida.txt`. Itens travados reais: 7663 (job 7, st 6), 9583 e 9591 (job 28, st 6). Agendados: 16142 (job 32), 29967/29968 (job 9), 29969 (job 18).

## Resumo

| Resultado | Qtd | Cenários |
|---|---|---|
| Passou | **20** | #1, #2, #3, #4, #6, #8, #10, #11, #13, #14, #15, #17, #18, #19, #20, #21, #22, #23, #24, #26 |
| Passou parcial | **3** | #5, #7, #9 (reclassificado pelo double-check) |
| Passou com observação (referência: legado) | **1** | #28 |
| Falhou | **1** | #27 (mesmo resultado do SQL, contra um esperado inferido do legado; a análise de falha da etapa 14 vale aqui: defeito NÃO por enquanto) |
| Não executado | **0** | — |
| N/A | **2** | #12, #16 |

**Comparação com o SQL Server:** o comportamento foi o mesmo em todos os cenários. No Oracle, **#22 foi executado** (no SQL ficou não executado, porque o envio não falhou). **#1 passou no job 32**, onde no SQL só passou depois da meia-noite. **#7 ganhou os jobs 28 e 32.** O SQL específico do Oracle (`OracleClaimJobTravado` com `RAW` para o `Lock_Id`, `NUMTODSINTERVAL` e `OracleGetJobs`) funcionou sem erro: 615 claims e movimentações, 0 `StuckItemMoveError`.

## Detalhe por cenário

| # | Categoria | Cenário | Resultado | Evidência |
|---|---|---|---|---|
| 1 | Fluxo principal | Travado com Sucesso (3) é movido (job 32) | **Passou** | Id 30002 (`qa-us164251-ora-c1`): movido às 08:51:31 no 1º ciclo do job 32; 1 dump st 3; log com Id e ChaveUnica (`sql\oracle\07-...-saida.txt`) |
| 2 | Fluxo principal | Travado com Envenenado (5) | **Passou** | Id 29975: movido às 08:42:12 (1º ciclo do job 9); log "status final 5"; dump st 5 |
| 3 | Fluxo principal | Travado com Cancelado (6) | **Passou** | Itens **reais** 7663 (job 7) e 9583/9591 (job 28) movidos às 08:40:13, na subida; dumps st 6 (`01-conferencia-subida-saida.txt`) |
| 4 | Fluxo principal | Agendamento volta depois da limpeza | **Passou** (job 18) | O item real 29993, com a chave fixa `BPM\|ExcluiFluxoEmSolicitacao`, virou st 3 às 08:47:52. De 08:47:52 a 08:49:12 o Scheduler logou "inserido com sucesso" 8 vezes sem inserir nada. Limpeza às 08:49:12,70; item novo 29998 criado às 08:49:13,63 e executado às 08:50:12 (`05-acompanhamento-c4-saida.txt`) |
| 5 | Fluxo principal | Item travado não é reexecutado | **Passou parcial** | 615 Ids movidos, **0** com "Iniciando processamento". O efeito de negócio repetido não foi conferido (o #1 usou uma linha QA, sem alerta real por trás) |
| 6 | Fluxo alternativo | Limpeza no ExecutaSql (19) | **Passou** | Id 29981 movido às 08:41:42 |
| 7 | Fluxo alternativo | Limpeza nos demais jobs | **Passou parcial** | Confirmado nos jobs 7, 8 (Id 29982, às 08:51:31), 9, 18, 19, 28 e 32. O job 20 não tem `JOB_CONFIG` no Oracle |
| 8 | Validação | Recém-finalizado (<60 s) não é travado | **Passou** | Id 29976 (atualizado às 08:41:39,578): ficou no ciclo das 08:42:12 (~33 s) e foi movido no das 08:43:12 (~93 s) |
| 9 | Validação | Logo acima de 60 s é movido | **Passou parcial** | Id 29977 movido no 1º ciclo (08:42:12), mas com ~103 s; a borda de ~70 s não foi exercida (double-check aceito). No SQL foram ~102 s |
| 10 | Validação | Status final com lock válido não é movido | **Passou** | Id 29978, com lock até 08:44:39,578: ficou nos ciclos de 08:42, 08:43 e 08:44 e foi movido às 08:45:12 |
| 11 | Validação | Conteúdo do log | **Passou** | Todas as linhas têm job, Id, ChaveUnica e status final, e o status bate com o do dump |
| 12 | Permissão | — | N/A | Rotina interna |
| 13 | Dados | Job sem itens | **Passou** | "não possui itens ativos" nos jobs 7, 8, 9, 18, 19 e 28, sem erro |
| 14 | Dados | Linha travada que já tem dump | **Passou** | Id 29979 removido; log "ja tinha sido movido para JOB_DUMP por outra execucao concorrente"; continua 1 único dump |
| 15 | Concorrência | Duas instâncias | **Passou** | 600 linhas (Ids 30040–30639, job 18). Instância 1: 350, de 08:57:28 a 08:58:06; instância 2: 250, de 08:57:38 a 08:58:06. Disputa real de ~28 s; 600 dumps distintos, 0 duplicados, 0 faltando, 0 com lock, 0 erros (`13-acompanhamento-c15-saida.txt`) |
| 16 | Integração | — | N/A | Nenhuma fonte pede |
| 17 | Regressão | Agendado segue o caminho normal | **Passou** | 29967, 29968, 29969 e os itens criados pelo Scheduler: "Iniciando" e "executado com sucesso", 1 dump st 3 |
| 18 | Regressão | FalhaParaRepetir continua com retry | **Passou** | Id 30029 (st 4, tent 1) reexecutado com sucesso às 08:55:28; 1 dump st 3; não foi tratado como travado |
| 19 | Regressão | Executando com lock válido não é tocado | **Passou** | Id 29980 sem nenhuma menção no log de 08:41 a 09:02 e ainda st 2 com o lock na limpeza |
| 20 | Regressão | Fim normal gera 1 dump | **Passou** | Mesmos itens do #17, sem log de travado |
| 21 | Regressão | Falha até esgotar vai para Envenenado | **Passou** | Id 30030 (fluxo inexistente 999999): às 08:56:39 (instância 2) tent 4, FalhaParaRepetir, retry às 09:00:39; às 09:01:49 (instância 1) tent 5, Envenenado; 1 dump st 5 com `Ultimo_Erro` (NullReferenceException) |
| 22 | Regressão | Exceção no envio do alerta mantém Sucesso (regra do PO) | **Passou** | 2 execuções do job 32 (16142 às 08:51:32–08:52:14 e 30006 às 08:52:30–08:53:06). Foram **19 e 16 tentativas de envio, todas com `MailerException` (BadRequest, "Content-Type header")**, e 0 enviados. Os dois jobs terminaram "executado com sucesso": st 3, tent 0, sem retry, 1 dump cada; a falha aparece só no conteúdo do log |
| 23 | Regressão | NotifyWf executa mais de uma vez sem erro de lock | **Passou** | Itens do NotifyWf adquiridos e executados em 16 ciclos (08:40–09:01), inclusive com 2 instâncias; nenhuma execução duplicada; 0 erros de lock |
| 24 | Regressão | Execução paralela por instâncias | **Passou** | Job 9 com `Max_Paralelo = 2`: 12 itens (30017–30028), 4 na instância 1 e 8 na 2; cada um com 1 "Iniciando", 1 "executado com sucesso" e 1 dump |
| 26 | Hipótese (ref. legado) | 3 travadas no mesmo ciclo | **Passou** | 29983/29984/29985 (st 3/5/6, job 18) movidos às 08:42:12,52–,72 |
| 27 | Hipótese (ref. legado) | Status final com `Data_Atualizacao` nula | **Falhou** | Id 29986 (job 9) não foi movido em ~20 ciclos; removido pela limpeza. A causa é a mesma do SQL: `Data_Atualizacao <= :Limite` com NULL nunca é verdadeiro (etapa 14) |
| 28 | Hipótese (ref. legado) | Texto do log "já movido" | **Passou com observação** | Visto no #14: o log diz "por outra execucao concorrente" sem concorrência |

## Divergências do double-check

Sub-agente independente (general-purpose), só com leitura da evidência: **24 CONFIRMADO, 1 DIVERGENTE**.

| # | Classificação original | Sugestão do sub-agente | Motivo |
|---|---|---|---|
| 9 | Passou | Passou parcial | No primeiro ciclo que pegou a linha ela já tinha ~103 s. A borda de ~70 s pedida pelo mapa não foi exercida; só ficou provado que acima de 60 s a linha é movida. (No SQL o #9 foi aceito como Passou com ~102 s.) |

**Decisão (2026-10-27):** Guilherme Henrique Correa Borges aceitou a sugestão. O #9 passa a **Passou parcial** na rodada Oracle; o resumo e a tabela de cenários já estão atualizados.

Ressalvas do sub-agente resolvidas por leitura (`sql\oracle\17-conferencia-double-check-saida.txt`):
- dump do 29975 com st 5 (#2);
- 1 único dump do 29979 (#14);
- dump do 30006 com st 3, tent 0, 1 registro (#22).

Observação aceita no #24: "instância 1/2" é o slot de paralelismo dentro do mesmo processo.

## Ocorrências

- **Job 32 interrompido:** uma 3ª execução (Id 30010) começou às 08:53:30, antes do restart que aplicou a restauração do cron, e foi encerrada no meio pelo restart das 08:54:04.
  - O item ficou **st 2 com o lock vencido às 08:54:30** no `JOB_BPM`.
  - É um item real do job 32. Na próxima execução do job 32 com um Worker no ar (cron 00:00), ele é adquirido de novo e o EnviaAlertaFluxo roda; com o e-mail atual, as tentativas vão falhar.
  - Não foi removido.
- **#21:** a 1ª falha foi da instância 2, que reprogramou o próprio gatilho para o retry e foi encerrada depois. A instância 1 só pegaria o item no ciclo normal do job 8 (15 min), por isso foi reiniciada para disparar o job 8.
- **Datas do `FLUXO_ALERTA`:** atualizadas pelo handler mesmo com todos os envios falhando. O próximo alerta foi calculado a partir da data antiga (ex.: 25/09 → 26/09), então os alertas continuam vencidos. É o mesmo achado de reenvio do SQL; aqui ele vira nova tentativa a cada execução.

## Achados novos (Oracle)

1. **Com o e-mail quebrado, o alerta é "consumido" sem entrega.** O job fica Sucesso (regra do PO) e o `FLUXO_ALERTA` é atualizado mesmo com 0 envios. Isso confirma a regra, mas deixa o alerta sem rastro de falha fora do log.
2. **Idempotência por `Id_Origem + Modulo + Job` foi necessária.** O `JOB_DUMP` do Oracle já tinha `Id_Origem = 7663` no **job 18** (dump de 21/09). O item 7663 do **job 7** foi movido corretamente, com dump novo. Se a chave fosse só `Id_Origem`, o log diria "já movido" e o dump do job 7 não seria criado.
3. **Dumps duplicados anteriores à correção:** os Ids de origem 2931–2941 (job 9) têm 2 dumps cada, de 10 a 15/09. Não foram gerados nesta rodada.
4. **O retry fica preso à instância que falhou** (complementa o achado 6 do SQL): se ela cair, o retry espera o ciclo normal do job, que no job 8 do Oracle é de 15 min.
5. **O `SYSDATE` do RDS está em UTC.** O Worker não é afetado, porque usa `DateTime.Now`, mas script manual ou consulta de QA precisa usar `LOCALTIMESTAMP`.

Os achados do SQL que se repetiram aqui: o Scheduler loga "inserido com sucesso" sem inserir; o `LOG_EMAIL` não é gravado (732 antes e depois); o texto "por outra execucao concorrente"; o job 20 sem `JOB_CONFIG`; o retry reprograma o gatilho do job.

## Estado deixado no ambiente (Oracle SHAREGUIZAO)

- `JOB_CONFIG` igual ao original: job 32 com cron `0 0 0 * * ?` (restaurado às 08:53:29) e job 9 com `Max_Paralelo = 1` (restaurado às 08:58:52). Conferido em `14-restauracao-c24-saida.txt`.
- **0 linhas `qa-us164251-ora-*` no `JOB_BPM`**: #19 e #27 removidos às 09:02:45. **625 dumps** `qa-us164251-ora-*` ficam no `JOB_DUMP` como evidência.
- `JOB_BPM` com 3 itens Agendados reais criados pelo Scheduler no último ciclo antes de ser encerrado (09:02:52): 30663/30664 (job 9) e 30665 (job 18). **O 30010** (job 32, st 2, lock vencido; ver Ocorrências) **foi removido às 09:12:22 por decisão do QA** (`sql\oracle\18-remocao-30010-saida.txt`), sem dump.
- `FLUXO_ALERTA` com as datas de último e próximo alerta alteradas pelo handler. Estado anterior em `06-c1-c22-job32-saida.txt`.
- `EMAIL_CONFIGURACAO` sem alteração.
- Efeitos reais dos jobs: o Scheduler criou e o Worker executou o InicioTemporal do processo 441 (chave `bpm:job:1:cd_processo=441`), além de itens do NotifyWf e do ExcluiFluxoEmSolicitacao.
- **Worker BPM e Scheduler encerrados às 09:02:58**; nenhum processo `SmartShareAgent*` rodando. O `appsettings.json` dos dois `bin` voltou a `SQLServer` (o original). O `appsettings.json` da **fonte** continua em Oracle, como o usuário deixou.

## Pendências

1. ~~**30010 (job 32, st 2):** decidir se fica para o cron ou se é removido~~: removido em 2026-10-27 09:12, por decisão do QA.
2. **#27:** mesma pendência do SQL (etapa 14): o dev confirmar o tratamento de `Data_Atualizacao` nula, ou o PO responder a hipótese.
3. **#5 e #7:** efeito de negócio dos itens movidos; job 20 sem `JOB_CONFIG`.
4. **Rodada no HMG** (SQL Server e Oracle) e Rodada 2 (`/homologar-release`).

## Arquivos

- SQL e saídas: `sql\oracle\00` a `16` (`*.sql` e `*-saida.txt`)
- Logs: `evidencias\oracle\worker1-log`, `worker2-log`, `scheduler-log`, mais o stdout/stderr de cada processo
