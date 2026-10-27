# Relatório de Execução de Testes — US 164251

**[BUG] Ajustar regra de leitura de status no BPM**

| | |
|---|---|
| Task | 164259 — Testes do card de bugs 164251 |
| História | 164251 (SmartShare Arquitetura, Sprint 4), responsável Vinicius Medeiros dos Santos |
| Mapa de testes | Card "Criar Mapa de Teste" #165040 (27 cenários depois da remoção do #25) |
| QA | Guilherme Henrique Correa Borges |
| Período | 2026-10-26 a 2026-10-27 |
| Rodada | 1 — validação funcional |
| Ambiente | **QA local, não HMG**: SQL Server `NOTE-74VQ\SQLEXPRESS`, base `ShareGuizao` |
| Versão testada | smartshare-net8, branch `bugfix/US164251-bpm-correcao-job-travando-execucao`, commit `d9784d80` (PR 29707 + ajustes do PR 29965) |
| Componentes | Worker BPM (`Project.Agent.Worker.Bpm`) em console; WorkerScheduler em console; Worker ECM em console (sem rotina migrada) |

---

## 1. Resultado geral

| Resultado | Qtd | Cenários |
|---|---|---|
| Passou | **20** | #1, #2, #3, #4, #6, #8, #9, #10, #11, #13, #14, #15, #17, #18, #19, #20, #21, #24, #26, #28 |
| Passou parcial | **3** | #5, #7, #23 |
| Falhou | **1** | #27 (contra um esperado inferido do Agent legado; análise de falha: defeito **NÃO** por enquanto) |
| Não executado | **1** | #22 (a falha de envio não ocorreu) |
| N/A | **2** | #12 (permissão), #16 (integração) |
| Removido do mapa | — | #25 (ECM), removido pelo QA porque nenhuma rotina de ECM foi migrada para o Agent novo |

**Conclusão:** a correção cumpre os critérios de aceite. Itens travados com status final (3, 5, 6) são movidos para o `JOB_DUMP` sem reexecução, com log (CA2, CA3), em todos os jobs exercitados (CA4). Também não houve regressão nos fluxos normal, de retry, de envenenamento, de paralelismo e de concorrência entre instâncias (CA1). A única falha (#27) é uma borda de dados (data de atualização nula) sem caminho conhecido de ocorrência e sem regra confirmada. Ficou registrada como achado para o dev, sem defeito aberto.

---

## 2. Resultado por cenário

| # | Cenário | Resultado | Evidência principal | Etapa |
|---|---|---|---|---|
| 1 | Travado com Sucesso (3) é movido | **Passou** | No job 8 (itens reais) e no job 32 (Id 41047, `qa-us164251-c1`): movido no primeiro ciclo, 1 dump status 3, log com Id e ChaveUnica | 05, 11 |
| 2 | Travado com Envenenado (5) é movido | **Passou** | Id 40046: movido no primeiro ciclo, 1 dump status 5, log "status final 5" | 06 |
| 3 | Travado com Cancelado (6) é movido | **Passou** | 16 itens reais travados (jobs 7, 8 e 9) e o item real 6686 do job 32 (travado desde 19/08) movidos | 05, 11 |
| 4 | Agendamento volta depois da limpeza | **Passou** (job 18) | Bloqueio do Scheduler reproduzido com chave fixa; depois da limpeza o Scheduler criou o item 40786 em 2 s e o Worker o executou | 08 |
| 5 | Item travado não é reexecutado | **Passou parcial** | 0 "Iniciando processamento" para os Ids movidos. O efeito de negócio repetido (prazo, notificação, exclusão) não foi conferido | 05 |
| 6 | Limpeza no ExecutaSql (19) | **Passou** | Job 19 ativado por um tempo; item movido no primeiro ciclo, com log e 1 dump | 10 |
| 7 | Limpeza nos demais jobs | **Passou parcial** | Confirmado nos jobs 7, 8, 9 e 18. Job 20 sem `JOB_CONFIG` no ambiente; job 28 inativo | 05, 08 |
| 8 | Recém-finalizado (<60 s) não é travado | **Passou** | Com ~42 s a linha continuou no `JOB_BPM`; movida no ciclo seguinte | 06 |
| 9 | Logo acima de 60 s é movido | **Passou** | Id 40047 movido com ~102 s | 06 |
| 10 | Status final com lock válido não é movido | **Passou** | Ficou 3 ciclos enquanto o lock valia; movido no primeiro ciclo depois do vencimento | 06 |
| 11 | Conteúdo do log ao mover | **Passou** | Log com job, Id, ChaveUnica e status final; o status do log é igual ao do dump | 05 |
| 12 | Permissão | N/A | Rotina interna, sem usuário | — |
| 13 | Job sem itens travados nem fila | **Passou** | "não possui itens ativos para execução"; nenhum dump novo; 0 ERROR | 05 |
| 14 | Linha travada que já tem dump | **Passou** | Linha removida do `JOB_BPM`, continua 1 único dump (ver observação do #28) | 06 |
| 15 | Duas instâncias no mesmo item travado | **Passou** | 2ª instância do Worker; disputa real de ~6,6 s sobre 600 itens (435/165 por instância); 0 duplicados, 0 órfãos, 0 erros | 07 |
| 16 | Integração | N/A | Nenhuma fonte pede | — |
| 17 | Agendado segue o caminho normal | **Passou** | Ids 39902–39905 e 39907 processados normalmente | 05 |
| 18 | FalhaParaRepetir continua com retry | **Passou** | Id 40842 (status 4) reexecutado pela fila normal, terminou com sucesso | 09 |
| 19 | Executando com lock válido não é tocado | **Passou** | Id 40050 intacto em 5 ciclos | 06 |
| 20 | Fim normal gera 1 dump | **Passou** | 1 dump status 3 por item, sem log de travado | 05 |
| 21 | Falha até esgotar vai para Envenenado | **Passou** | Id 40858 (fluxo inexistente 999999): FalhaParaRepetir na 4ª tentativa (retry em 240 s), Envenenado na 5ª, 1 dump, `Ultimo_Erro` preenchido | 09 |
| 22 | Exceção no envio do alerta mantém Sucesso (regra do PO) | **Não executado** | Job 32 rodado com envio real: 72 e-mails aceitos, nenhuma falha de envio. O caminho de exceção segue sem evidência | 11 |
| 23 | NotifyWf executa mais de uma vez sem erro de lock | **Passou parcial** | Itens processados sem ERROR; faltou gerar itens espalhados em ciclos diferentes | 05 |
| 24 | Execução paralela por instâncias | **Passou** | Job 9 com `Max_Paralelo = 2`: 12 itens alternados entre as instâncias 1 e 2, sem execução ou dump duplicado | 10 |
| 25 | ECM | **Removido** | Nenhuma rotina de ECM migrada; o Worker ECM não funciona | — |
| 26 | Várias linhas travadas no mesmo ciclo | **Passou** | Ids 43786–43788 (job 8, status 3/5/6) movidos juntos em 130 ms, 1 dump cada | 13 |
| 27 | Status final com `Data_Atualizacao` nula | **Falhou** | Id 43789 (job 9) não foi movido em 3+ ciclos. Ver seção 5 | 13, 14 |
| 28 | Texto do log "já movido" | **Passou** (referência: legado) | Visto no #14. O legado não registra nada nesse caso. Observação de redação para o dev | 06, 12 |

---

## 3. Decisões tomadas durante a rodada

1. **Regra do PO para o EnviaAlertaFluxo (2026-10-26):** o job continua com status **Sucesso quando o envio de e-mail falha**, até a regra ser mapeada e corrigida em todos os casos. Isso bate com o código (`catch` → `Sucesso = true`, "regra do clássico"). O resultado esperado do #22 foi atualizado no card #165040 (revisão 5).
2. **#25 removido do mapa (2026-10-27):** nenhuma rotina de ECM foi migrada para o Agent novo, então o Worker ECM não funciona e o cenário não teria como passar.
3. **Hipóteses #26–#28 com o Agent legado como referência (2026-10-27):** o PO está de férias. A pergunta continua no comentário da US 164251 e, até a resposta, o esperado vem do Agent legado (`SmartShareAgent/Agent.cs`):
   - o legado não tem fila por item: a trava é por rotina (`STATUS_AGENT`);
   - a trava é liberada quando o dono deixa de estar ativo, sem olhar data;
   - cada ciclo processa todo o pendente, sem limite;
   - não grava log quando recupera uma trava.
   Se o PO divergir na volta, o #26, o #27 e o #28 são reavaliados.
4. **Escrita no banco local e alterações de ambiente autorizadas pelo QA no chat, ação por ação:**
   - linhas de teste em `JOB_BPM`/`JOB_DUMP`, todas com a chave `qa-us164251-*`;
   - mudanças temporárias no `JOB_CONFIG` (job 19 ativo, job 9 com `Max_Paralelo = 2`, job 32 a cada 60 s), todas restauradas;
   - segunda instância do Worker;
   - **envio real de alertas** no #22.

---

## 4. Ocorrências durante a execução

- **Primeira tentativa bloqueada (etapa 4):** MCP do Azure DevOps sem conexão. Resolvido trocando a inicialização do servidor MCP para `node` direto.
- **#15:** a 1ª tentativa, com 30 itens, não teve sobreposição porque a 2ª instância demorou ~10 s para subir. Repetido com 600 itens, com disputa real.
- **#21:** o plano de quebrar o SMTP foi descartado antes de executar: o NotifyWf não envia e-mail nesse ambiente e o script de restauração não devolveria a configuração OAuth. A falha foi provocada com um avanço temporal de fluxo inexistente (999999).
- **#22, envio real de alertas:**
  - 2 execuções do job 32 (17:02 e 17:03 de 26/10) enviaram **72 e-mails** para 6 endereços de QA/do QA.
  - A 2ª execução **reenviou alertas** já enviados, por isso o horário do job foi restaurado antes do previsto (17:05:51).
  - O QA recebeu 60 e-mails na própria caixa. A conta provável é 12 alertas + 48 avisos de não entrega para endereços `@local.test`, ainda a confirmar.
- **Meia-noite de 27/10:** o Worker da sessão ainda estava rodando. O job 32 reenviou **30 alertas** (5 alertas × 6 destinatários), e 13 alertas continuam vencidos. O Worker foi parado às 06:56. O item 42310 (EnviaAlertaFluxo) ficou na fila para a próxima meia-noite em que houver Worker BPM no ar.
- **Worker BPM do QA (PID 21788):** foi encerrado para aplicar as mudanças de `JOB_CONFIG`. A partir daí o Worker passou a ser subido e encerrado pela sessão. O Scheduler e o Worker ECM do QA não foram tocados.

---

## 5. Falha e análise — #27

- **Obtido:** uma linha com status 3, `Data_Atualizacao = NULL` e sem lock nunca é movida.
- **Causa (lida no código):** `GetJobsTravados` e `ClaimJobTravado` filtram por `Data_Atualizacao <= agora − 60 s`, e comparar com NULL nunca é verdadeiro. Se uma linha assim tiver a chave fixa do agendamento, o bug original volta.
- **Veredito da análise de falha: NÃO abrir defeito por enquanto.**
  - O esperado é hipótese, inferida do legado.
  - Não há caminho conhecido que grave a data nula: todo código do Agent novo preenche o campo, nenhum outro sistema grava em `JOB_BPM` e o ambiente tem 0 linhas nulas.
  - A coluna, porém, aceita nulo no SQL Server e no Oracle.
- **Para virar defeito:** o dev confirmar que existe um caminho que grava nulo ou que a busca deve tratar o nulo, ou o PO confirmar a hipótese. Detalhe completo no anexo `14-analise-falha.md`.

---

## 6. Achados para o dev (fora do escopo desta US)

1. **Alertas vencidos são reenviados a cada execução do EnviaAlertaFluxo** até a data alcançar o dia atual. O próximo alerta é calculado a partir do `dt_proximo_alerta` antigo, e não a partir de agora. Confirmado à meia-noite de 27/10: 30 reenvios, 13 alertas ainda vencidos.
2. **`LOG_EMAIL` não é gravado pelo Agent novo** (72 envios e a tabela continuou com 224 registros).
3. **`<br>` literal no corpo do e-mail de alerta.**
4. **"Enviado com sucesso" significa só "aceito pelo servidor":** envios para domínio inexistente (`@local.test`) são registrados como sucesso.
5. **O Scheduler loga "inserido com sucesso" mesmo quando não insere** (108 mensagens × 45 inserções reais no job 18). Isso esconde o travamento.
6. **O retry reprograma o gatilho Quartz do job inteiro** e pausa a limpeza daquele job durante o backoff (job 8 ficou 4 min sem ciclo).
7. **`NotifyStep` desconhecido vira Sucesso.**
8. **Avanço de fluxo inexistente dá `NullReferenceException`.**
9. **Job 20 sem `JOB_CONFIG`** no ambiente local.
10. **Atraso de até 24 h na limpeza** de jobs de cron diário (a limpeza só roda no ciclo do próprio job).
11. **Texto do log "já movido"** diz "por outra execucao concorrente" mesmo sem concorrência (#28).
12. **#27:** data de atualização nula nunca é tratada como travada (ver seção 5).

---

## 7. Pendências

| Pendência | Quem destrava |
|---|---|
| #22: provocar falha real de envio para ter evidência do caminho de exceção | QA + dev (como quebrar e restaurar a configuração de e-mail) |
| #5: conferir o efeito de negócio dos itens movidos | QA |
| #7: jobs 20 (sem `JOB_CONFIG`) e 28 (inativo) | Dev / QA |
| #23: itens do NotifyWf espalhados em ciclos diferentes | QA |
| #27: confirmar se a data nula ocorre e como tratar | Dev; PO na volta |
| Hipóteses #26–#28: resposta do PO no comentário da US 164251 | PO |
| **Rodada no HMG**, incluindo **Oracle** (o mapa recomenda os dois bancos; só SQL Server foi testado) | QA, depois do deploy da branch |
| Rodada 2 (`/homologar-release`) | QA |

---

## 8. Estado deixado no ambiente (ShareGuizao)

- `JOB_CONFIG` igual ao original: job 32 com cron `0 0 0 * * ?`, job 19 com `Ativo = 0`, job 9 com `Max_Paralelo = 1`.
- 0 linhas `qa-us164251-*` no `JOB_BPM`. Os dumps dos cenários ficaram no `JOB_DUMP` como evidência.
- `FLUXO_ALERTA` com as datas de último e próximo alerta alteradas pelo próprio handler (estado anterior em `sql\21-estado-antes-c22.txt`).
- Nenhum Worker BPM rodando. Scheduler e Worker ECM do QA rodando, sem alteração.

---

## 9. Rastreabilidade

- **Registro completo do ciclo:** `ciclos-execucao\164259-US164251\` (etapas 01 a 15, scripts e saídas em `sql\`, evidências em `evidencias\`).
- **Log de governança:** `arquitetura\log\LOG-ACOES.md` (linhas de 2026-10-26 13:22 a 2026-10-27).
- **Artefatos no Azure DevOps:**
  - mapa #165040;
  - comentário com as hipóteses na US 164251;
  - este relatório e a análise de falha, anexados à task 164259.
