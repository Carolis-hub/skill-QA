# Etapa 09 — Execução de Testes — cenários de falha #18 e #21 — #164251

- **Skill:** `/executar-teste 164251`, continuação: cenários #18 e #21 (o #22 ficou pendente por decisão do usuário)
- **Data:** 2026-10-26 16:10–16:28
- **Escreveu no Azure DevOps?** Não
- **Escreveu no banco?** **Sim, com autorização explícita do usuário no chat** (Guilherme Henrique Correa Borges): 1 linha em `JOB_BPM` para cada cenário.
- **Ambiente:** SQL Server `NOTE-74VQ\SQLEXPRESS`, base `ShareGuizao` (QA local, não HMG). Worker BPM em console (PID 21788, branch do PR 29707, commit `d9784d80`).

## Regras de falha confirmadas no código (branch do PR 29707)
- `JobResiliencePolicy.CalcularFalha`: se a falha pede reagendamento e as tentativas ficam abaixo de `Max_Tentativas` (5), vira **FalhaParaRepetir (4)** com nova `Data_Programada`. Se não pede reagendamento, ou se chegou ao máximo, vira **Envenenado (5)** e vai para o dump.
- `WorkerHelper.ClassificarErro`: `JsonException`, `ArgumentException` e `OperationCanceledException` → sem reagendamento. Qualquer outra exceção → com reagendamento.
- `BackoffCalculator`: política 0 (Default) = **Linear**, 60 s × tentativa, limite de 1 h.

## Mudança de abordagem no #21 (decidida com o usuário)
O plano inicial era derrubar o SMTP com `work\notifywf_poison_front.js`. Foi descartado antes de mexer em qualquer configuração:
- `LOG_EMAIL` não tem nenhum envio nos últimos 30 dias, e o NotifyWf termina sempre em "Não existem notificação pendente". Ele nunca usa o SMTP neste ambiente, então nada falharia.
- A configuração atual (`EMAIL_CONFIGURACAO`) é OAuth 2.0 (tipo 3), sem servidor, porta, usuário nem senha. O `restore` do script não restaura servidor, login, senha nem SSL nesse caso, e deixaria `127.0.0.1:1` / `qa-notifywf` / `falha-controlada` gravados.

Alternativa usada: item do AvancoTemporal apontando para um fluxo inexistente (999999; o maior fluxo da base é 900558), que gera exceção genérica e portanto reagendamento.

## #18 — FalhaParaRepetir continua sendo reprocessado
- **Montagem:** `sql\13-montagem-c18.sql` às 16:17:31. Id **40842**, job 9 (NotifyWf), status **4**, 1 tentativa, `Data_Programada` vencida, passo `NotificarMensagemExcecaoAlcada` (`{"NotifyStep":8}`), chave própria `qa-us164251-c18-falha-para-repetir`.
- **Resultado** (`sql\14-acompanhamento-c18.txt`):
  - 16:18:02,618 `Iniciando processamento do Job NotifyWf. Id: 40842`
  - 16:18:02,703 `Job NotifyWf executado com sucesso. Id: 40842`
  - `JOB_DUMP`: status 3, 1 tentativa, `Ultimo_Erro` NULL, dump às 16:18:02,677
  - 0 linhas "travado" para o Id 40842

| # | Resultado | Evidência |
|---|---|---|
| 18 | **Passou** | O item em FalhaParaRepetir foi reexecutado pela fila normal no primeiro ciclo e terminou com sucesso. A busca nova não o tratou como travado |

## #21 — Falha até esgotar as tentativas termina em Envenenado
- **Montagem:** `sql\15-montagem-c21.sql` às 16:20:11. Id **40858**, job 8 (AvancoTemporal), status **1**, **3 tentativas**, `{"AvancoTemporalStep":2,"cd_fluxo":999999,"cd_tarefa":1,"cd_passo":1}`, chave `qa-us164251-c21-fluxo-inexistente`.
- **Linha do tempo** (`sql\16-acompanhamento-c21.txt` + log do Worker):

| Hora | Estado / evento |
|---|---|
| 16:20:12 | `JOB_BPM` status 1, 3 tentativas |
| 16:21:02 | Worker adquire: status 2 (Executando), lock até 16:22:02 |
| 16:21:22,99 | `ERROR` "Erro ao executar Job AvancoTemporal. Id: 40858 … Tentativas: 4, Status: FalhaParaRepetir" (`System.NullReferenceException`) |
| 16:21:28 | `JOB_BPM` status **4**, 4 tentativas, `Data_Programada` 16:25:22 (+240 s, backoff linear para a 4ª tentativa), `Ultimo_Erro` preenchido |
| 16:25:23 | Retry: status 2, lock até 16:26:23 |
| 16:25:40,04 | `ERROR` "… Tentativas: 5, Status: Envenenado" |
| 16:25:40 | Fora do `JOB_BPM`. `JOB_DUMP`: status **5**, 5 tentativas, `Ultimo_Erro` com a `NullReferenceException`, sem lock |

- A busca nova não tocou no item em nenhum momento: 0 linhas "travado" para o Id 40858. Ele foi para o dump pelo caminho normal (`gerarDump` do Envenenado).
- **Ciclos do job 8:** 16:20:02, 16:21:02, 16:21:22–23, **nenhum ciclo até 16:25:23**, 16:25:40, 16:26:40, 16:27:40. Depois do Envenenado, o job voltou ao intervalo de 60 s.

| # | Resultado | Evidência |
|---|---|---|
| 21 | **Passou** | FalhaParaRepetir na 4ª tentativa com retry em 240 s; Envenenado na 5ª, com 1 dump e `Ultimo_Erro` preenchido. A limpeza nova não interferiu |

## Observações para o dev (comportamento existente, fora do escopo desta US)
- **O retry pausa o job inteiro.** `ErroExecusao` chama `UpdateSchedule(BuildRetrySchedule(...))`, que troca o intervalo do gatilho Quartz **do job** pelo tempo de backoff. Durante o retry do 40858, o job 8 ficou 4 min sem ciclo. Nesse tempo, nenhum outro item do job 8 é processado, e **a limpeza de travados desse job também não roda**. Com o backoff crescendo até 1 h, um item em retry atrasa a limpeza na mesma proporção.
- **`NotifyStep` desconhecido vira Sucesso.** No `NotifyWFExecHandler`, um `NotifyStep` que não corresponde a nenhum passo cai direto em `jr.Sucesso = true`, sem executar nada.
- **Avanço de fluxo inexistente gera `NullReferenceException`** em vez de um erro de validação claro. Por isso o item é reagendado 4 vezes antes de virar Envenenado, quando poderia ir direto para Envenenado.

## Placar acumulado da execução (etapas 05 a 09)
- **Passou:** 15 (#2, #3, #4, #8, #9, #10, #11, #13, #14, #15, #17, #18, #19, #20, #21)
- **Passou parcial:** 4 (#1, #5, #7, #23)
- **Falhou:** 0
- **Não executado:** 4 (#6, #22, #24, #25)
- **Hipótese:** 3 (#26, #27, #28) · **N/A:** 2 (#12, #16)

## Dados deixados no ambiente
Linhas 40842 (`qa-us164251-c18-…`, status 3) e 40858 (`qa-us164251-c21-…`, status 5) no `JOB_DUMP`. Nenhuma linha de teste no `JOB_BPM`. Nenhuma alteração em `EMAIL_CONFIGURACAO` nem em `JOB_CONFIG`.
