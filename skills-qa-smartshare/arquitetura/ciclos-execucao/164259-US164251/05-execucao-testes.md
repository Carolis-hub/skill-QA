# Etapa 05 — Execução de Testes — #164251 [BUG] Ajustar regra de leitura de status no BPM

- **Skill:** `/executar-teste 164251` (Modo A; terceira tentativa, a primeira que passou do Step 0)
- **Data:** 2026-10-26 15:05–15:20
- **Escreveu no Azure DevOps?** Não
- **Escreveu no banco?** Não. Só `SELECT`, com login integrado do Windows (`SELBETTI\guilherme.borges`), sem uso de senha.
- **Triagem revisada por:** Guilherme Henrique Correa Borges
- **Status:** Parcial — 9 cenários com evidência, 14 não executados, 3 hipóteses, 2 N/A.

## Ambiente
- **Não é o HMG.** É o ambiente local de QA indicado pelo usuário: SQL Server `NOTE-74VQ\SQLEXPRESS`, base `ShareGuizao`, cliente `GuizaoLocal`.
- **Worker BPM com a correção:** console em `D:\SmartShare-HUB\smartshare-hub\smartshare-net8`, branch `bugfix/US164251-bpm-correcao-job-travando-execucao`, HEAD `d9784d80` (merge do PR 29965 sobre o 29707), build Debug 3.87.4.26259 de 2026-10-26 14:34, `DBType = SQLServer`, iniciado às 14:34:59.
- **Outros processos na máquina (não interferem no SQL Server):** serviços `SmartShareAgent_BPM_Borges` e `SmartShareAgent_Scheduler_Borges` (versão instalada, sem a correção) apontam para **Oracle**; `SmartShareAgent` legado também está rodando.
- **Não há Scheduler apontando para o SQL Server**, nem segunda instância do Worker BPM, nem Worker ECM rodando.
- **Log:** `...\Project.Agent.Worker.Bpm\bin\Debug\net8.0\Log\JOB_BPM\<Job>\20261026_<Job>.log` (NLog, JSON por linha).
- **JOB_CONFIG (Modulo 1):** ativos = 7 (300 s), 8, 9, 18 (60 s), 32 (cron `0 0 0 * * ?`, uma vez por dia à meia-noite). Inativos = 16, 19, 22, 25, 28, 33, 34. **Job 20 (ExecutaPassoAplicacao) não tem linha no JOB_CONFIG.** Max_Paralelo = 1 em todos os ativos. TimeZone_Id = America/Sao_Paulo (job 7: NULL).

## Resumo
- Cenários com evidência: 9
- Passou: 5 (#3, #11, #13, #17, #20)
- Passou parcial: 4 (#1, #5, #23 — reclassificados após o double-check; #7 — parcial desde a classificação original)
- Falhou: 0
- Não executado: 14
- Hipótese (não executa): 3 (#26, #27, #28)
- N/A: 2 (#12, #16)

## Evidência principal
Ao subir (14:35:02,987 a 14:35:03,410), o Worker corrigido moveu para o `JOB_DUMP` **17 itens travados** que estavam parados havia 46 a 89 dias:
- **Ids:** 2964, 4014, 2942, 2979, 4015, 2951, 4130, 4036, 3829, 4131, 4098, 3832, 4159, 4160, 24355, 24417, 24418.
- **Por status:** 1 com status 3 (Id 2942, job 8) e 16 com status 6 (jobs 7, 8 e 9). Nenhum com status 5.
- **Conferência por consulta:**
  - 0 desses Ids ainda no `JOB_BPM`;
  - 0 Id_Origem com mais de 1 registro no `JOB_DUMP`;
  - 0 dumps com `Lock_Id`/`Lock_Expira_Em` preenchidos.
- **Conferência no log:**
  - cada um dos 17 Ids tem exatamente 1 linha "estava travado com status final S e foi movido para JOB_DUMP, por ja ter sido processado anteriormente";
  - o status S do log é igual ao status gravado no dump nos 17 Ids;
  - 0 linhas "Iniciando processamento" para esses Ids.
- **Exemplo do log:** `Job AvancoTemporal (Id: 2942, ChaveUnica: bpm:job:1:cd_fluxo=40:cd_tarefa=2:AvancoTemporalStep:VerificarAvancoPrazoEstourado:) estava travado com status final 3 e foi movido para JOB_DUMP, por ja ter sido processado anteriormente.`

**Fluxo normal no mesmo ciclo:** 5 itens novos (Ids 39902–39905 do job 9 e 39907 do job 18) executaram e foram para o dump.
- No log: 1 "Iniciando processamento", 1 "executado com sucesso" e 0 "travado" cada.
- No banco: status 3 e 1 dump cada.

**Depois da subida:**
- Nenhum dump novo entre 14:35:04 e 15:05.
- "não possui itens ativos" foi logado 32x (AvancoTemporal), 31x (ExcluiFluxoEmSolicitacao), 7x (InicioTemporal) e 31x (NotifyWf).
- 0 linhas de nível ERROR no dia.
- 0 mensagens "ja tinha sido movido" ou "Erro ao mover".

**Ainda no `JOB_BPM` com status final:** Id 6686 (job 32, status 6, desde 2026-08-19, chave `BPM|EnviaAlertaFluxo|cliente=GuizaoLocal`). O job 32 só roda à meia-noite. É o próximo candidato natural a ser movido, às 00:00 de 2026-10-27.

## Detalhe por cenário
| # | Categoria | Cenário | Resultado | Evidência / motivo |
|---|---|---|---|---|
| 1 | Fluxo principal | Travado com Sucesso (3) é movido | **Passou parcial** | Id 2942, job 8: saiu do `JOB_BPM`, 1 dump status 3, log com Id e ChaveUnica. O mapa pede o job 32 (EnviaAlertaFluxo), que não rodou (cron 00:00) |
| 2 | Fluxo principal | Travado com Envenenado (5) é movido | Não executado | Nenhum item status 5 no ambiente; montar exige escrita em `JOB_BPM` |
| 3 | Fluxo principal | Travado com Cancelado (6) é movido | **Passou** | 16 itens, jobs 7, 8 e 9; mesmas conferências do #1 |
| 4 | Fluxo principal | Agendamento volta depois da limpeza | Não executado | Não há Scheduler apontando para o SQL Server (o serviço aponta para Oracle); o job 32 roda só à meia-noite; reproduzir a chave exige escrita |
| 5 | Fluxo principal | Item travado não é reexecutado | **Passou parcial** | 0 "Iniciando processamento" para os 17 Ids. O efeito de negócio repetido (prazo, notificação, exclusão) não foi conferido |
| 6 | Fluxo alternativo | Limpeza no ExecutaSql (19) | Não executado | Job 19 inativo e sem item travado; ativar e montar exige escrita |
| 7 | Fluxo alternativo | Limpeza nos demais jobs | **Passou** (parcial) | Confirmado nos jobs 7, 8 e 9. Job 18 sem item travado; job 28 inativo; job 20 sem `JOB_CONFIG` |
| 8 | Validação | Recém-finalizado (<60 s) não é travado | Não executado | Exige linha status 3 com menos de 60 s no momento da limpeza (escrita) |
| 9 | Validação | Logo acima de 60 s é movido | Não executado | Os itens estavam parados havia dias; o limite de ~70 s exige escrita |
| 10 | Validação | Status final com lock válido não é movido | Não executado | Exige escrita de lock |
| 11 | Validação | Conteúdo do log ao mover | **Passou** | 17 linhas com job, Id, ChaveUnica e status final; status do log = status do dump |
| 12 | Permissão | — | N/A | Rotina interna |
| 13 | Dados | Job sem itens travados nem fila | **Passou** | "não possui itens ativos" nos 4 jobs; nenhum dump novo; 0 ERROR |
| 14 | Dados | Linha travada que já tem registro no dump | Não executado | Exige escrita para montar o caso |
| 15 | Concorrência | Duas instâncias no mesmo item | Não executado | Só há 1 instância do Worker no SQL Server; exige subir uma segunda e montar o item |
| 16 | Integração | — | N/A | Nenhuma fonte pede |
| 17 | Regressão | Agendado segue o caminho normal | **Passou** | Ids 39902–39905 e 39907 |
| 18 | Regressão | FalhaParaRepetir continua com retry | Não executado | Nenhum item status 4; exige provocar falha |
| 19 | Regressão | Executando com lock válido não é tocado | Não executado | Nenhum item status 2 com lock; exige escrita |
| 20 | Regressão | Fim normal com sucesso gera 1 dump | **Passou** | Mesmos 5 Ids: 1 dump status 3, sem log de travado |
| 21 | Regressão | Falha até esgotar vai para Envenenado | Não executado | Exige provocar falha até `Max_Tentativas` |
| 22 | Regressão | Exceção no handler não vira Sucesso | Não executado | Exige provocar exceção no envio (há scripts `notifywf_poison_front.js` e `mailer_front_*.js` com ações break/restore; não foram usados sem autorização) |
| 23 | Regressão | NotifyWf executa mais de uma vez sem erro de lock | **Passou parcial** | 4 itens do job 9 processados no primeiro ciclo; os 31 ciclos seguintes estavam vazios e sem ERROR; não houve busca específica por mensagem de lock |
| 24 | Regressão | Execução paralela por instâncias | Não executado | `Max_Paralelo` = 1 em todos os jobs ativos; exige mudar configuração |
| 25 | Regressão | ECM não muda | Não executado | Não há Worker ECM rodando |
| 26–28 | Hipóteses | — | Não executado | Aguardam dev/PO |

## Divergências do double-check (sub-agente independente)
| # | Classificação original | Sugestão do sub-agente | Motivo |
|---|---|---|---|
| 1 | Passou (job 8) | Passou parcial | O comportamento foi confirmado em outro job; o alvo pedido (job 32, EnviaAlertaFluxo) não foi exercitado |
| 5 | Passou | Passou parcial | A ausência de reexecução foi provada pelo log; o efeito de negócio (prazo, notificação, exclusão repetidos) não foi conferido |
| 23 | Passou | Passou parcial | Os 4 itens foram processados no primeiro ciclo; os 31 ciclos seguintes não tinham item; não houve busca específica por mensagem de lock |

Confirmadas pelo double-check: #2, #3, #7 (com correção do motivo: job 20 sem `JOB_CONFIG`), #8, #11, #13, #17, #20. As ressalvas de #3 e #11 (status do log × status do dump) foram resolvidas depois: o status bate nos 17 Ids.

**Decisão sobre as divergências:** em 2026-10-26, Guilherme Henrique Correa Borges aceitou as 3 sugestões. #1, #5 e #23 passaram a **Passou parcial** no resumo e na tabela de cenários.

## Achados para o dev (não são falha da US)
- **Job 20 (ExecutaPassoAplicacao) não tem linha no `JOB_CONFIG`** deste ambiente, então nunca roda aqui e a limpeza não é exercitada nele.
- **Job 32 tem item Cancelado parado desde 19/08 (Id 6686).** Com cron diário, um item travado nesse job só é limpo à meia-noite. Para jobs de cron diário, o atraso da limpeza pode chegar a 24 h.

## Pendências
1. **Rechecar depois da 00:00 de 2026-10-27** se o Id 6686 (job 32, Cancelado) foi movido. Cobre o #1/#3 no EnviaAlertaFluxo sem escrita.
2. **Execução assistida dos 14 não executados:** SQL de montagem rodado por quem tem autorização, mais um Scheduler e uma segunda instância do Worker apontando para o SQL Server, conforme o cenário.
3. **Completar os parciais:** #1 (rechecar o job 32 depois da 00:00, item 1), #5 (conferir o efeito de negócio dos itens movidos) e #23 (gerar mais de um item do NotifyWf em ciclos diferentes e buscar mensagem de lock).
4. **Rodada em HMG:** pela convenção da skill, a rodada funcional é no HMG; esta foi no ambiente local de QA.
