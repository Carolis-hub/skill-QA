# Etapa 11 — Execução de Testes — #22 e #1 no EnviaAlertaFluxo (job 32) — #164251

- **Skill:** `/executar-teste 164251`, continuação: #22 (com envio real de alertas) e conclusão do #1 no job 32
- **Data:** 2026-10-26 17:00–17:10
- **Escreveu no Azure DevOps?** Não
- **Escreveu no banco?** **Sim, com autorização explícita do usuário no chat** (Guilherme Henrique Correa Borges), **inclusive para o envio real dos alertas**: 1 linha em `JOB_BPM` e mudança temporária do horário do job 32 no `JOB_CONFIG`, já restaurada.
- **Ambiente:** SQL Server `NOTE-74VQ\SQLEXPRESS`, base `ShareGuizao` (QA local, não HMG). Worker BPM em console (branch do PR 29707, commit `d9784d80`).

## Regra confirmada pelo PO (informada pelo usuário no chat, 2026-10-26)
O EnviaAlertaFluxo **continua gravando Sucesso quando o envio de e-mail falha**, até a regra ser mapeada e corrigida em todos os casos. Isso bate com o código da branch e da `main` (`catch` → `jr.Sucesso = true`, com o comentário "Mantendo a regra do clássico…").

**Ajuste necessário no mapa (card #165040):** o resultado esperado do #22 ("o job não fica com status 3") está desatualizado. Pela regra vigente, o esperado é "o job fica com status 3 (Sucesso), sem retry, e o erro aparece só no conteúdo do log".

## Execução
1. **Estado antes** (`sql\21-estado-antes-c22.txt`): job 32 com cron `0 0 0 * * ?`; fila com 6686 (Cancelado, travado desde 19/08) e 39820 (Agendado desde 22/09); `LOG_EMAIL` com 224 registros (último em 14/09); **16 alertas de fluxo vencidos**.
2. **Montagem e mudança de horário** (`sql\22-c22-alteracao-job32.sql`, 17:02:09): item **41047** (job 32, status 3, travado, chave `qa-us164251-c1-enviaalerta-sucesso`) e job 32 com `Schedule_Type = 1`, `Interval_Ms = 60000`.
3. **Reinício:** o Worker foi reiniciado às ~17:02:20 para ler o `JOB_CONFIG`.
4. **Acompanhamento** (`sql\24-acompanhamento-c22.txt`, `sql\25-envios-c22*.txt`):

| Hora | Evento |
|---|---|
| 17:02:55,35 | `Job EnviaAlertaFluxo (Id: 6686, ChaveUnica: BPM|EnviaAlertaFluxo|cliente=GuizaoLocal) estava travado com status final 6 e foi movido para JOB_DUMP…` |
| 17:02:55,91 | `Job EnviaAlertaFluxo (Id: 41047, ChaveUnica: qa-us164251-c1-enviaalerta-sucesso) estava travado com status final 3 e foi movido para JOB_DUMP…` |
| 17:02:56,79 | Início da execução do item real **39820** |
| 17:03:24,63 | Conteúdo do log: **42 envios** "Alerta de Fluxo enviado com sucesso" (7 alertas × 6 destinatários), 0 erros |
| 17:03:24,65 | `Job EnviaAlertaFluxo executado com sucesso. Id: 39820` (dump status 3, 0 tentativas) |
| 17:03:54,89 | Execução do item **41058**, criado pelo Scheduler depois que a chave ficou livre |
| 17:04:16,04 | **30 envios** (5 alertas × 6 destinatários), 0 erros. **Repetiu alertas já enviados 1 minuto antes** (ver achado 1) |
| 17:04:16,15 | `executado com sucesso. Id: 41058` (dump status 3) |
| 17:04:54,83 | `não possui itens ativos para execução` |
| 17:05:51 | **Cron restaurado** (`sql\23-c22-restauracao-job32.sql`) e Worker reiniciado, para interromper os reenvios. Nenhuma execução do job 32 depois de 17:04:55 |

- **Destinatários** (6, todos de QA ou do usuário): `borgesqa@gmail.com`, `guilherme.borges@selbetti.com.br`, `qa.ct02@local.test`, `qa.ct13@local.test`, `qa.ct14@local.test`, `qa.ct16@local.test`. **Total: 72 envios.** O usuário recebeu, por exemplo, "[QA NOVO] Alerta individual - fluxo 900550" (`evidencias\c22-email-alerta-fluxo-900550.png`).
- **`FLUXO_ALERTA`:** 9 alertas com `dt_ultimo_alerta` atualizado. 3 passaram a ter próximo alerta no futuro (131/3, 134/4, 900550/8). Os demais **continuam vencidos**.
- **0 linhas `ERROR`** e 0 "Erro ao enviar".

## Resultados

| # | Cenário | Resultado | Evidência |
|---|---|---|---|
| 1 | Travado com Sucesso (3) é movido — no EnviaAlertaFluxo | **Passou** (antes: parcial) | Id 41047 no job 32: movido no primeiro ciclo, 1 dump status 3, log com Id e ChaveUnica |
| 3 | Travado com Cancelado (6) — no job 32 | Passou (reforço) | O item real 6686, travado desde 19/08, foi movido no primeiro ciclo do job 32 |
| 22 | Exceção no EnviaAlertaFluxo | **Não executado** — a falha não ocorreu | Os 72 envios foram aceitos; nenhuma exceção. Com o e-mail funcionando, provocar falha exigiria mexer na configuração OAuth (`EMAIL_CONFIGURACAO`), o que não foi feito. Pela regra do PO, o esperado numa falha é Sucesso, o mesmo status que os dois jobs tiveram aqui. O caminho de falha segue sem evidência |

## Achados para o dev (comportamento existente, fora do escopo desta US)
1. **Alertas vencidos são reenviados a cada execução até alcançar a data atual.** Depois de enviar, o próximo alerta é calculado a partir do `dt_proximo_alerta` antigo + periodicidade (`ultimoEnvio = dRowLinha.dt_proximo_alerta`), e não a partir de agora. Um alerta diário vencido desde agosto continua vencido depois do envio e é reenviado na próxima execução. Com o cron diário, isso vira **um reenvio por dia até alcançar a data**. Neste teste, com o job a cada minuto, o fluxo 130/alerta 3 foi enviado duas vezes em 1 minuto. Com o cron restaurado, os **13 alertas ainda vencidos voltam a ser enviados à 00:00** (item 41064 já na fila).
2. **`LOG_EMAIL` não é gravado pelo Agent novo:** 72 envios registrados no log do Worker e `LOG_EMAIL` continua com 224 registros.
3. **`<br>` literal no corpo do e-mail** ("Teste do EnviaAlertaFluxoExecHandler.<br>Código do fluxo: 900550"): a quebra de linha não é interpretada como HTML.
4. **Envios para `@local.test` registrados como sucesso:** domínio reservado, que não recebe e-mail. O usuário informou ter recebido **60 e-mails** na caixa `guilherme.borges@selbetti.com.br`. A conta fecha com 12 alertas destinados a ele + 48 prováveis avisos de não entrega dos 4 endereços `qa.ct*@local.test` × 12 (os alertas saem pela caixa dele via OAuth e as devoluções voltam para o remetente). **Hipótese a confirmar** olhando os 48 e-mails. Se confirmada, o "enviado com sucesso" do log significa só "aceito pelo servidor", não "entregue": uma falha de entrega nunca aparece no Worker, o que reforça a regra do PO (Sucesso mesmo com falha).

## Placar acumulado da execução (etapas 05 a 11)
- **Passou:** 18 (#1, #2, #3, #4, #6, #8, #9, #10, #11, #13, #14, #15, #17, #18, #19, #20, #21, #24)
- **Passou parcial:** 3 (#5, #7, #23)
- **Falhou:** 0
- **Não executado:** 2 (#22: a falha de envio não ocorreu e o resultado esperado do mapa precisa ser atualizado pela regra do PO; #25: Worker ECM sem configuração)
- **Hipótese:** 3 (#26, #27, #28) · **N/A:** 2 (#12, #16)

## Estado deixado no ambiente
- `JOB_CONFIG` do job 32 restaurado (cron `0 0 0 * * ?`).
- Worker BPM rodando como processo iniciado por esta sessão.
- **Na fila:** item 41064 (EnviaAlertaFluxo, Agendado), que roda à 00:00 e vai reenviar os alertas ainda vencidos.
- **No `JOB_DUMP`:** 6686, 41047, 39820 e 41058.
- **`FLUXO_ALERTA` alterado pelo próprio handler** (datas de último e próximo alerta de 9 registros). O estado anterior está em `sql\21-estado-antes-c22.txt`.

## Atualização em 2026-10-27 06:56 — Worker parado depois da meia-noite
O usuário pediu para parar o Worker BPM da sessão antes da 00:00, mas o pedido só chegou às 06:55. O job 32 já tinha rodado:
- **00:00:17:** o item 41064 executou e foi para o `JOB_DUMP` com status 3. O log `20261027_EnviaAlertaFluxo.log` mostra **30 envios** (5 alertas × 6 destinatários: fluxos 130/3, 135/3, 900549/3, 133/4 e 900550/7), com 0 erros. Isso confirma o achado 1: o reenvio diário de alertas vencidos aconteceu como previsto.
- Depois da execução, `FLUXO_ALERTA` continua com **13 alertas vencidos**, o mesmo número de antes. Mais uma prova de que o envio não faz a data alcançar o dia atual.
- **00:00:19:** o Scheduler criou o item **42310** (job 32, Agendado), que vai rodar na próxima 00:00 em que houver um Worker BPM no ar.
- **06:56:** o Worker BPM da sessão (tarefa `bp2fs38kc`) foi encerrado, e não sobrou nenhum processo `BpmWorker` rodando. Quem sobe o Worker de novo é o usuário.

## Atualização em 2026-10-27 — #25 removido do mapa
O usuário removeu o cenário #25 do mapa #165040. Motivo: **nenhuma rotina de ECM foi migrada para o Agent novo**, então o Worker ECM não funciona e o cenário não teria como passar. O #25 sai do placar e não conta como falha nem como pendência desta US.

## Atualização em 2026-10-27 — #22 ajustado no mapa
Com aprovação do usuário, a linha do #22 no card #165040 foi alterada (revisão 4 → 5, só essa linha mudou):
- **Cenário:** de "Exceção no handler não vira Sucesso" para "Exceção no envio do alerta mantém o job como Sucesso (regra do PO)".
- **Resultado esperado:** de "O job não fica com status 3; segue para FalhaParaRepetir ou Envenenado" para "Regra vigente confirmada pelo PO em 2026-10-26: o job fica com status 3 (Sucesso), sem retry, e vai uma única vez para a JOB_DUMP; a falha de envio aparece só no conteúdo do log do job. A regra se mantém até ser mapeada e corrigida em todos os casos em que acontece."
- **Origem:** passou a incluir "regra do PO".

O #22 continua **não executado**: o caminho de falha de envio ainda não tem evidência.

**Placar final da rodada 1 (27 cenários):** 18 passou, 3 passou parcial (#5, #7, #23), 0 falhou, 1 não executado (#22), 3 hipóteses (#26–#28), 2 N/A (#12, #16).
