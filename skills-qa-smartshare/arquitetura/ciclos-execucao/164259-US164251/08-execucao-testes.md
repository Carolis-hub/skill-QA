# Etapa 08 — Execução de Testes — cenário #4 (agendamento volta depois da limpeza) — #164251

- **Skill:** `/executar-teste 164251`, continuação: cenário #4
- **Data:** 2026-10-26 16:01–16:06
- **Escreveu no Azure DevOps?** Não
- **Escreveu no banco?** **Sim, com autorização explícita do usuário no chat** (Guilherme Henrique Correa Borges): 1 linha em `JOB_BPM`.
- **Ambiente:** SQL Server `NOTE-74VQ\SQLEXPRESS`, base `ShareGuizao` (QA local, não HMG).
- **Processos:**
  - Worker BPM em console (PID 21788, branch do PR 29707, commit `d9784d80`);
  - Scheduler em console apontando para o SQL Server (PID 36280, mesma branch, iniciado às 15:16:32 pelo usuário).

## Adaptação do cenário
- **Job usado:** o mapa pede o EnviaAlertaFluxo (job 32), mas ele só agenda à meia-noite (cron `0 0 0 * * ?`). Usei o **job 18 (ExcluiFluxoEmSolicitacao)**, que o Scheduler agenda com chave fixa `BPM|ExcluiFluxoEmSolicitacao` mais ou menos uma vez por minuto. O mecanismo é o mesmo do bug: o insert do Scheduler tem `NOT EXISTS` por `Modulo + Job + Chave_Unica`.
- **Item travado:** `sql\11-montagem-c4.sql`, rodado às 16:03:03, logo depois do ciclo do Worker, com a fila do job 18 vazia. Cria uma linha status 3 com a chave fixa, `Data_Atualizacao` 5 min atrás e `Hash_Argumentos` marcado com `qa-us164251-c4`. Só insere se a chave não estiver na fila. Gerou o Id **40777**.
- **Acompanhamento:** fila e dumps do job 18 a cada 5 s, em `sql\12-acompanhamento-c4.txt`. A coluna de dumps desse arquivo tem um filtro de tempo errado. A conferência dos dumps abaixo foi feita por consulta direta.

## Linha do tempo (banco + logs)
| Hora | Fonte | Evento |
|---|---|---|
| 16:03:02,62 | Worker | Executa o item real 40776 (fila do job 18 fica vazia) |
| 16:03:03,54 | Script | Cria o item travado **40777** (status 3, chave `BPM|ExcluiFluxoEmSolicitacao`) |
| 16:03:23,48 | Scheduler | Log diz "inserido com sucesso", mas **nenhum item foi criado**: 0 itens reais com essa chave criados entre 16:03:03 e 16:04:02. **O agendamento ficou travado pela linha, como no bug** |
| 16:04:02,65 | Worker | `Job ExcluiFluxoEmSolicitacao (Id: 40777, ChaveUnica: BPM|ExcluiFluxoEmSolicitacao) estava travado com status final 3 e foi movido para JOB_DUMP, por ja ter sido processado anteriormente.` Dump às 16:04:02,623, status 3 |
| 16:04:04,51 | Scheduler | **Cria o item real 40786** (status 1, `Hash_Argumentos` real) |
| 16:05:02,66 | Worker | `Iniciando processamento ... Id: 40786` |
| 16:05:02,72 | Worker | `executado com sucesso. Id: 40786`. Dump às 16:05:02,697, status 3, 0 tentativas |

Sem linhas ERROR no período.

## Resultado

| # | Cenário | Resultado | Evidência |
|---|---|---|---|
| 4 | Agendamento volta a funcionar depois da limpeza | **Passou** (em outro job) | Com o item travado, o Scheduler não criou nenhum item (bloqueio reproduzido). Depois que o Worker moveu o travado, o Scheduler criou o 40786 em 2 s e o Worker o executou no ciclo seguinte, sem erro. O mapa cita o EnviaAlertaFluxo; o teste usou o job 18, pelo mesmo mecanismo de chave fixa |

## Achado colateral para o dev (fora do escopo desta US)
**O Scheduler registra "inserido com sucesso para processamento" mesmo quando o insert não acontece** (o `NOT EXISTS` barrou a chave). Para o job 18, entre 15:16:30 e 16:01:44, o log tem **108** mensagens de "inserido com sucesso", mas só **45** itens foram criados de fato. No cenário, a tentativa das 16:03:23 foi barrada e mesmo assim saiu como sucesso. Isso esconde exatamente o travamento que a US 164251 corrige: quem lê o log do Scheduler não percebe que a chave está bloqueada.

## Placar acumulado da execução (etapas 05 a 08)
- **Passou:** 13 (#2, #3, #4, #8, #9, #10, #11, #13, #14, #15, #17, #19, #20)
- **Passou parcial:** 4 (#1, #5, #7, #23)
- **Falhou:** 0
- **Não executado:** 6 (#6, #18, #21, #22, #24, #25)
- **Hipótese:** 3 (#26, #27, #28) · **N/A:** 2 (#12, #16)

## Dados deixados no ambiente
Linha 40777 (marcada `qa-us164251-c4`) no `JOB_DUMP`, movida pelo Worker. Nenhuma linha de teste no `JOB_BPM`.
