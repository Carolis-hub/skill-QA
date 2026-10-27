# Etapa 2 — Análise Técnica — #164251 [BUG] Ajustar regra de leitura de status no BPM

- **Skill:** `/analise-tecnica 164251` (somente leitura)
- **Data:** 2026-10-26
- **Card de Análise:** #164256 (Done)
- **PRs:** #29965 (vinculado à US, concluído com merge na branch do #29707) e **#29707** (correção principal, **aberto** de `bugfix/US164251-bpm-correcao-job-travando-execucao` para `main`). Repositório `smartshare-net8`, projeto SHARE-4.
- **Fontes lidas:** campos `Pontos de impacto` e `Caso de teste` do card 164256; metadados e arquivos alterados dos dois PRs; conteúdo dos arquivos no commit `d9784d80` (`BpmExecJob.cs`, `JobLogMessages.cs`, `JobBpmService.cs`, `JobBpmRepository.cs`, `JobDumpRepository.cs`, `DBTranslator.cs`, `EJobStatus.cs`, `EJobBpm.cs`).

> O PR 29707 não está vinculado à US; foi encontrado pela descrição do 29965.

## O que foi alterado
- **Busca nova de itens travados** (`JobBpmRepository.GetJobsTravados`): linhas do `JOB_BPM` do mesmo módulo e job com `Job_Status_Id IN (3, 5, 6)`, `Data_Atualizacao` com mais de 60 s (fixo, `SEGUNDOS_MINIMOS_PARA_CONSIDERAR_TRAVADO`) e sem lock válido.
- **Claim antes de mover** (`ClaimJobTravado`): grava `Lock_Id`/`Lock_Expira_Em` (60 s) para duas instâncias do Worker não pegarem o mesmo item. SQL em `DBTranslator.cs` (SQL Server e Oracle).
- **Rotina de limpeza** (`BpmExecJob.MoverJobsTravadosParaDump`): roda em `GetListaJobsAtivos`, antes da busca normal da fila, em todo ciclo. Faz claim, chama `JobDumpService.Add`, sempre chama `Remove`, e loga `StuckItemFound` ou `StuckItemAlreadyDumped`.
- **Insert idempotente no dump** (`JobDumpRepository.Add`, PR 29965): só insere se não existir registro com o mesmo `Id_Origem + Modulo + Job`; devolve `bool`.
- **Mensagens de log novas** (`JobLogMessages.cs`): `StuckItemFound`, `StuckItemAlreadyDumped`, `StuckItemMoveError`.
- **Fuso no erro** (PR 29965): `ErroExecusao` passa a usar o fuso do job (`GetDataAtual(TimeZoneId)`).

Status (`EJobStatus`): 1 Agendado, 2 Executando, 3 Sucesso, 4 FalhaParaRepetir, 5 Envenenado, 6 Cancelado.

## Onde foi alterado (por camada)
| Camada | Alterado | Risco | Justificativa |
|---|---|---|---|
| Worker BPM (`Project.Agent.Worker.Bpm`) | `BpmExecJob.cs` | **Alto** | Roda em todo ciclo dos 8 jobs ativos do BPM |
| Serviço (`Project.Core.Application`) | `JobBpmService`, `JobDumpService` | Médio | Repassa ao repositório; assinatura do `Add` mudou |
| Banco/SQL (`Infraestructure` + `DBTranslator`) | `JobBpmRepository`, `JobDumpRepository`, `DBTranslator` | **Alto** | SQL novo em SQL Server e Oracle, não executado em nenhum dos dois segundo o PR; sem teste automatizado |
| Log (`Worker.Core`) | `JobLogMessages.cs` | Baixo | Só texto, mas atende o CA3 |
| Front-end / API | não | — | Sem tela; verificação por banco e log |

## Dependências diretas
- `GetListaJobsAtivos` → `MoverJobsTravadosParaDump` → `GetJobsTravados` / `ClaimJobTravado` / `JobDumpService.Add` / `JobBpmService.Remove`.
- `JobBpmRepository.Remove` só apaga se já existir registro no `JOB_DUMP` para aquele `Id_Origem + Modulo + Job`.
- `GerarDump` (fim normal de execução) usa o mesmo `JobDumpService.Add`, agora idempotente.

## Dependências indiretas
- **WorkerScheduler**: insert de agendamento com `NOT EXISTS` por `Modulo + Job + Chave_Unica` (não alterado); destrava porque a linha some.
- **Retry (`FalhaParaRepetir`)**: `DataProgramada` do retry e reagendamento do Quartz passam a usar o fuso do job.

## Funcionalidades potencialmente impactadas
- Os 8 jobs BPM que passam por `GetListaJobsAtivos`: InicioTemporal (7), AvancoTemporal (8), NotifyWf (9), ExcluiFluxoEmSolicitacao (18), ExecutaSql (19), ExecutaPassoAplicacao (20), ExecutaWs (28), EnviaAlertaFluxo (32).
- Jobs vazios (`// TODO`) não chamam a limpeza: CalculoIndicador, InicioPublicacao, NotificaInicioComPublicacao, InicioFluxoRevisao, InicioDesassociarAutomatico.
- Fim normal de execução e retry de falha.

## Dados potencialmente impactados
- `JOB_BPM`: linhas com status 3, 5 ou 6 paradas há mais de 60 s são removidas.
- `JOB_DUMP`: no máximo 1 registro por `Id_Origem + Modulo + Job`; `Lock_Id` e `Lock_Expira_Em` gravados como NULL.
- `Data_Atualizacao` das falhas no fuso do job.

## Discrepâncias entre análise do dev e o PR (dentro do escopo)
- Card cita `AddIfNotExists` e `ExisteIdOrigem`; o PR 29965 removeu os dois e trocou por `Add` idempotente.
- Ajuste de fuso no `ErroExecusao` não está no card.
- `Lock_Id`/`Lock_Expira_Em` NULL no dump não está no card.
- Possível efeito no ECM: `JobDumpRepository.Add` aceita `EJobModulo.ECM`; contradiz o caso 10 do dev ("ECM não muda"). Necessita validação.
- Fora do escopo: nenhum arquivo.

## Casos de teste sugeridos pelo dev (card 164256, não validados pelo QA)
1. Item travado com Sucesso (mais de 60 s) → sai do `JOB_BPM`, entra no `JOB_DUMP`, log com id, chave e status.
2. Mesmo caso com Envenenado.
3. Mesmo caso com Cancelado.
4. Item recém-finalizado (menos de 60 s) não é pego pela busca nova.
5. Agendamento novo aceito depois da limpeza (reproduz o caso da 164251).
6. Item Agendado normal não é afetado.
7. Item FalhaParaRepetir continua com retry.
8. Item Executando com lock válido não é tocado.
9. Duas instâncias do Worker: 1 registro só no `JOB_DUMP`, linha sai do `JOB_BPM`.
10. A regra vale para outros jobs (ex.: ExecutaSql).
11. ECM sem mudança de comportamento.

Montagem segundo o dev: inserir ou alterar a linha no `JOB_BPM` (status e `Data_Atualizacao`), rodar o ciclo do job e conferir `JOB_BPM`, `JOB_DUMP` e o log. Não há tela.

## Pré-requisitos técnicos de execução de teste
- Build com a correção (PR 29707 aberto). **Bloqueante.**
- Escrita direta no banco com autorização. **Bloqueante.**
- Definição de SQL Server e/ou Oracle.
- Worker BPM ativo (`StAtivo = true`) e `JobConfig.Ativo = true`; intervalo do Quartz de cada job.
- Dados montados no fuso (`TimeZoneId`) do job.
- Duas instâncias do Worker para o caso 9.
- Acesso ao log do Worker BPM.
- Sem mecanismo conhecido para reproduzir falha do `Add`/`Remove` (`StuckItemMoveError`).

## Informações ausentes
- O ECM usa `JobDumpRepository.Add`?
- Quando o PR 29707 vai para a `main` e se o teste roda antes ou depois do merge.
- O texto de `StuckItemAlreadyDumped` ("por outra execução concorrente") também aparece sem concorrência; atende o CA3?
- Janela de 60 s × intervalo do job: item recém-finalizado e não movido espera alguns ciclos.
