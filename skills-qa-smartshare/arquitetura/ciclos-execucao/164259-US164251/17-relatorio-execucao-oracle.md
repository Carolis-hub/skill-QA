# Relatório de Execução de Testes — US 164251 — **ORACLE**

**[BUG] Ajustar regra de leitura de status no BPM**

> Relatório da **rodada em Oracle**. A rodada em SQL Server tem relatório próprio, `US164251-relatorio-execucao-testes.md`, já anexado a esta task.

| | |
|---|---|
| Task | 164259 — Testes do card de bugs 164251 |
| História | 164251 (SmartShare Arquitetura, Sprint 4), responsável Vinicius Medeiros dos Santos |
| Mapa de testes | Card "Criar Mapa de Teste" #165040, revisão 6 (27 cenários; #25 removido) |
| QA | Guilherme Henrique Correa Borges |
| Data | 2026-10-27, de 08:36 a 09:12 |
| Rodada | 1 — validação funcional |
| Ambiente | **QA local, não HMG**: Oracle, schema `SHAREGUIZAO` (RDS `ss-oracle-br-3`, serviço `SSHARE`) |
| Versão testada | smartshare-net8, branch `bugfix/US164251-bpm-correcao-job-travando-execucao`, commit `d9784d80`, a mesma da rodada SQL Server |
| Componentes | Worker BPM (`Project.Agent.Worker.Bpm`) e WorkerScheduler, em console com `DBType = Oracle` |

---

## 1. Resultado geral

| Resultado | Qtd | Cenários |
|---|---|---|
| Passou | **20** | #1, #2, #3, #4, #6, #8, #10, #11, #13, #14, #15, #17, #18, #19, #20, #21, #22, #23, #24, #26 |
| Passou parcial | **3** | #5, #7, #9 |
| Passou com observação | **1** | #28 (referência: Agent legado) |
| Falhou | **1** | #27 (contra um esperado inferido do Agent legado; análise de falha: defeito **NÃO** por enquanto) |
| Não executado | **0** | — |
| N/A | **2** | #12 (permissão), #16 (integração) |

**Conclusão:** no Oracle a correção cumpre os critérios de aceite, com o mesmo comportamento da rodada SQL Server.

- Itens travados com status final (3, 5 e 6) são movidos para o `JOB_DUMP` sem reexecução e com log (CA2, CA3), em todos os jobs exercitados (CA4).
- Não houve regressão nos fluxos normal, de retry, de envenenamento, de paralelismo e de concorrência entre instâncias (CA1).
- O SQL específico do Oracle funcionou sem erro em 615 movimentações, com 0 `StuckItemMoveError`:
  - `OracleClaimJobTravado`, com `Lock_Id` em `RAW` e `NUMTODSINTERVAL`;
  - a busca de travados;
  - a fila (`OracleGetJobs`).
- A única falha (#27) é a mesma do SQL Server: uma borda de dados sem caminho conhecido de ocorrência e sem regra confirmada.

### Comparação com a rodada SQL Server

| # | SQL Server | Oracle | Motivo |
|---|---|---|---|
| 1 | Passou | Passou | No Oracle o cenário rodou direto no job 32, sem esperar a meia-noite |
| 7 | Parcial | Parcial | No Oracle cobriu mais jobs (7, 8, 9, 18, 19, 28, 32); o job 20 continua sem `JOB_CONFIG` |
| 9 | Passou | **Parcial** | Pego com ~103 s; a borda de ~70 s não foi exercida (sugestão do double-check, aceita pelo QA). No SQL foram ~102 s |
| 22 | Não executado | **Passou** | O e-mail do Oracle está quebrado, então a falha de envio aconteceu de verdade |
| 23 | Parcial | **Passou** | Itens do NotifyWf em 16 ciclos seguidos, inclusive com 2 instâncias |
| 28 | Passou | Passou com observação | Mesma observação de redação do log |
| Demais | — | — | Mesmo resultado nos dois bancos |

---

## 2. Resultado por cenário

| # | Cenário | Resultado | Evidência principal |
|---|---|---|---|
| 1 | Travado com Sucesso (3) é movido | **Passou** | Id 30002 (job 32, `qa-us164251-ora-c1`): movido às 08:51:31 no 1º ciclo; 1 dump st 3; log com Id e ChaveUnica |
| 2 | Travado com Envenenado (5) é movido | **Passou** | Id 29975 (job 9): movido às 08:42:12 no 1º ciclo; 1 dump st 5, tent 5; log "status final 5" |
| 3 | Travado com Cancelado (6) é movido | **Passou** | Itens **reais** 7663 (job 7) e 9583/9591 (job 28) movidos às 08:40:13, logo na subida do Worker; dumps st 6 |
| 4 | Agendamento volta depois da limpeza | **Passou** (job 18) | O item real 29993, com a chave fixa `BPM\|ExcluiFluxoEmSolicitacao`, virou st 3 às 08:47:52. O Scheduler ficou bloqueado até 08:49:12: logou "inserido com sucesso" 8 vezes sem inserir nada. Depois da limpeza (08:49:12,70), criou o item 29998 em 1 s, e ele foi executado às 08:50:12 |
| 5 | Item travado não é reexecutado | **Passou parcial** | 615 Ids movidos, 0 com "Iniciando processamento". O efeito de negócio repetido não foi conferido |
| 6 | Limpeza no ExecutaSql (19) | **Passou** | Id 29981 movido às 08:41:42 |
| 7 | Limpeza nos demais jobs | **Passou parcial** | Confirmada nos jobs 7, 8, 9, 18, 19, 28 e 32. O job 20 não tem `JOB_CONFIG` no Oracle |
| 8 | Recém-finalizado (<60 s) não é travado | **Passou** | Id 29976 ficou no ciclo de 08:42:12 (~33 s) e foi movido no de 08:43:12 (~93 s) |
| 9 | Logo acima de 60 s é movido | **Passou parcial** | Id 29977 movido no 1º ciclo, mas já com ~103 s; a borda de ~70 s não foi exercida |
| 10 | Status final com lock válido não é movido | **Passou** | Id 29978, com lock até 08:44:39: ficou nos ciclos de 08:42, 08:43 e 08:44 e foi movido às 08:45:12 |
| 11 | Conteúdo do log ao mover | **Passou** | Job, Id, ChaveUnica e status final; o status do log é igual ao do dump |
| 12 | Permissão | N/A | Rotina interna, sem usuário |
| 13 | Job sem itens travados nem fila | **Passou** | "não possui itens ativos para execução" nos jobs 7, 8, 9, 18, 19 e 28, sem erro |
| 14 | Linha travada que já tem dump | **Passou** | Id 29979 removido do `JOB_BPM`, continua com 1 único dump; log "ja tinha sido movido" |
| 15 | Duas instâncias no mesmo item travado | **Passou** | 600 linhas (Ids 30040–30639, job 18). Instância 1 moveu 350 e instância 2 moveu 250, com disputa real de ~28 s (08:57:38–08:58:06). Ficaram 600 dumps distintos: 0 duplicados, 0 faltando, 0 com lock, 0 erros |
| 16 | Integração | N/A | Nenhuma fonte pede |
| 17 | Agendado segue o caminho normal | **Passou** | 29967, 29968, 29969 e os itens criados pelo Scheduler foram executados, com 1 dump st 3 cada |
| 18 | FalhaParaRepetir continua com retry | **Passou** | Id 30029 (st 4, tent 1) reexecutado com sucesso; 1 dump st 3; não foi tratado como travado |
| 19 | Executando com lock válido não é tocado | **Passou** | Id 29980 sem nenhuma menção no log de 08:41 a 09:02; continuou st 2 com lock |
| 20 | Fim normal gera 1 dump | **Passou** | 1 dump st 3 por item, sem log de travado |
| 21 | Falha até esgotar vai para Envenenado | **Passou** | Id 30030 (fluxo inexistente 999999): FalhaParaRepetir na tent 4 (retry em 240 s), Envenenado na tent 5. 1 dump st 5 com `Ultimo_Erro` |
| 22 | Exceção no envio do alerta mantém Sucesso (regra do PO) | **Passou** | 2 execuções do job 32 (Ids 16142 e 30006) com 19 e 16 tentativas de envio, **todas com `MailerException`**, e 0 enviados. Os dois jobs terminaram "executado com sucesso": st 3, tent 0, sem retry, 1 dump cada. A falha aparece só no conteúdo do log |
| 23 | NotifyWf executa mais de uma vez sem erro de lock | **Passou** | Itens adquiridos e executados em 16 ciclos (08:40–09:01), sem execução duplicada e sem erro de lock |
| 24 | Execução paralela por instâncias | **Passou** | Job 9 com `Max_Paralelo = 2`: 12 itens, 4 na instância 1 e 8 na 2. Cada um teve 1 execução e 1 dump |
| 25 | ECM | **Removido** | Removido do mapa: nenhuma rotina de ECM foi migrada |
| 26 | Várias linhas travadas no mesmo ciclo | **Passou** | Ids 29983–29985 (st 3/5/6, job 18) movidos juntos em 0,2 s |
| 27 | Status final com `Data_Atualizacao` nula | **Falhou** | Id 29986 (job 9) não foi movido em ~20 ciclos. Ver seção 5 |
| 28 | Texto do log "já movido" | **Passou com observação** | O log diz "por outra execucao concorrente" mesmo sem concorrência |

---

## 3. Decisões tomadas durante a rodada

1. **Versão:** `d9784d80`, o mesmo commit da rodada SQL Server, para comparar as duas rodadas. O remoto tem um commit mais novo (`b89ad1dc`, merge da main com o handler InicioPublicacao), mas a lógica da correção não muda nele.
2. **Escrita no Oracle, autorizada pelo QA no chat:**
   - subir o Worker BPM e o Scheduler;
   - montar linhas `qa-us164251-ora-*` em `JOB_BPM`/`JOB_DUMP`, com limpeza;
   - alterar o `JOB_CONFIG` por um tempo: job 32 a cada 60 s e job 9 com `Max_Paralelo = 2`, os dois restaurados;
   - subir a 2ª instância do Worker.
3. **Job 32 com envio real autorizado.** A configuração de e-mail **não foi alterada**; a falha de envio já existia no Oracle.
4. **#9 reclassificado para Passou parcial**, aceitando a sugestão do double-check independente.
5. **Item 30010 removido** por decisão do QA (ver seção 4).

---

## 4. Ocorrências durante a execução

- **#4:** o Scheduler reinsere a chave fixa em segundos, então a 1ª tentativa de montar a linha travada não achou janela livre. O cenário foi reproduzido transformando o item real Agendado 29993 em "Sucesso não movido para o dump", que é exatamente o caso do bug.
- **#21:** a 1ª falha foi da 2ª instância, que reprogramou o próprio gatilho para o retry e depois foi encerrada. No Oracle o job 8 cicla a cada 15 min, por isso a instância 1 foi reiniciada para disparar o job 8.
- **Job 32 interrompido:** uma 3ª execução (Id 30010) começou às 08:53:30, antes do restart que aplicou a restauração do cron, e foi interrompida por esse restart. O item ficou com status 2 e lock vencido e foi **removido às 09:12:22** por decisão do QA, para não disparar os alertas de novo no próximo cron.
- **E-mail:** nenhum alerta foi enviado. Nas 35 tentativas houve 35 erros e 0 linhas "enviado com sucesso".

---

## 5. Falha — #27

- **Obtido:** uma linha com status 3, `Data_Atualizacao = NULL` e sem lock nunca é movida. É o mesmo resultado da rodada SQL Server.
- **Causa (lida no código):** a busca e o claim filtram por `Data_Atualizacao <= :Limite`, e comparar com NULL nunca é verdadeiro.
- **Veredito da análise de falha:** **NÃO abrir defeito por enquanto.** O esperado é uma hipótese inferida do legado, e não há caminho conhecido que grave a data nula.
- **Para virar defeito:** o dev confirmar um caminho que grava nulo ou que a busca deve tratar o nulo, ou o PO confirmar a hipótese.

---

## 6. Achados para o dev (fora do escopo desta US)

**Novos nesta rodada:**
1. **Alerta "consumido" sem entrega.** Com o envio falhando, o job fica Sucesso (regra do PO) e o `FLUXO_ALERTA` é atualizado mesmo com 0 envios. A falha só fica registrada no log.
2. **O retry fica preso à instância que falhou.** Se ela cair, o retry espera o ciclo normal do job, que no job 8 do Oracle é de 15 min.
3. **A idempotência do dump por `Id_Origem + Modulo + Job` foi necessária.** O `JOB_DUMP` já tinha `Id_Origem = 7663` no job 18, e o item 7663 do job 7 foi movido corretamente.
4. **Dumps duplicados anteriores à correção:** os Ids de origem 2931–2941 (job 9) têm 2 dumps cada, de 10 a 15/09.
5. **O `SYSDATE` do RDS está em UTC.** O Worker usa `DateTime.Now` e não é afetado, mas scripts manuais precisam usar `LOCALTIMESTAMP`.
6. **No Oracle o e-mail de alerta está quebrado:** remetente `...@selbetti.com.brrrrr`, autenticação tipo 3, erro BadRequest "Content-Type header".

**Que se repetiram do SQL Server:**
- alertas vencidos voltam a ser tentados a cada execução, porque o próximo alerta é calculado a partir da data antiga;
- o Scheduler loga "inserido com sucesso" mesmo quando não insere;
- o `LOG_EMAIL` não é gravado;
- o retry reprograma o gatilho do job inteiro;
- o job 20 não tem `JOB_CONFIG`;
- avanço de fluxo inexistente dá `NullReferenceException`;
- o texto "por outra execucao concorrente" aparece sem concorrência.

---

## 7. Double-check independente

Um sub-agente revisou a evidência só com leitura e confirmou **24** classificações. Divergiu em **1**: o #9, de Passou para Passou parcial, sugestão aceita pelo QA. As ressalvas dele sobre #2, #14 e #22 foram resolvidas por consulta de leitura.

---

## 8. Pendências

| Pendência | Quem destrava |
|---|---|
| #27: confirmar se a data nula ocorre e como tratar | Dev; PO na volta |
| #5: conferir o efeito de negócio dos itens movidos | QA |
| #7: job 20 sem `JOB_CONFIG` | Dev / QA |
| #9: exercitar a borda de ~70 s com montagem sincronizada ao ciclo | QA (opcional) |
| E-mail de alerta quebrado no Oracle local (`EMAIL_CONFIGURACAO`) | QA, se quiser alertas nesse ambiente |
| **Rodada no HMG** (SQL Server e Oracle) | QA, depois do deploy da branch |
| Rodada 2 (`/homologar-release`) | QA |

---

## 9. Estado deixado no ambiente (Oracle SHAREGUIZAO)

- `JOB_CONFIG` igual ao original: job 32 com cron `0 0 0 * * ?` e job 9 com `Max_Paralelo = 1`.
- 0 linhas `qa-us164251-ora-*` no `JOB_BPM`. Os **625 dumps** `qa-us164251-ora-*` ficaram no `JOB_DUMP` como evidência.
- Item 30010 removido. No `JOB_BPM` sobram só 3 itens Agendados reais, criados pelo Scheduler no último ciclo antes de ser encerrado.
- `FLUXO_ALERTA` com datas alteradas pelo handler. `EMAIL_CONFIGURACAO` sem alteração.
- Worker BPM e Scheduler encerrados; nenhum processo do Agent rodando. O `appsettings.json` dos `bin` voltou para SQL Server.

---

## 10. Rastreabilidade

- **Registro completo da rodada:** `ciclos-execucao\164259-US164251\16-execucao-testes-oracle.md`.
- **Scripts e saídas:** `sql\oracle\00` a `18`.
- **Logs:** `evidencias\oracle\` (worker1, worker2, scheduler).
- **Log de governança:** `arquitetura\log\LOG-ACOES.md`, linhas de 2026-10-27 09:05 a 09:12.
- **Azure DevOps:** mapa #165040; relatório SQL Server e análise de falha do #27 já anexados à task 164259; este relatório anexado à mesma task.
