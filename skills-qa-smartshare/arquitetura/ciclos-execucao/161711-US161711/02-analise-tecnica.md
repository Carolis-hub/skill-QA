# Etapa 02 — analise-tecnica — #161711 Bugs Instaladores

- **Skill e argumentos:** `/arquitetura-analise-tecnica 161711`
- **Data:** 2026-11-06
- **Escreveu no Azure DevOps:** Não
- **Status da etapa:** **Bloqueada — sem card `Análise`**
- **Fontes lidas:** PBI #161711 e filhos (tipo e estado de cada um); metadados e lista de arquivos dos PRs 30060, 30104, 30253, 30254, 30457, 30486. Diffs não lidos.

## Aprendizados consultados

Consulta realizada — nenhum aprendizado aplicável encontrado.

# Análise Técnica — #161711 Bugs Instaladores

⏸️ **Análise técnica ainda não disponível.** O PBI #161711 não possui um card filho do tipo `Análise` preenchido pelo dev. Esta etapa depende desse insumo; o dev precisa registrar a análise técnica no Azure DevOps antes de rodar `/arquitetura-analise-tecnica` novamente.

O fluxo de Arquitetura não deve seguir para `/arquitetura-gerar-mapa-testes` enquanto o card estiver ausente ou vazio.

## Por que bloqueou

Tipos dos 14 filhos: 7 `Bug`/`Outros` (#161712, #161713, #161714, #161715, #161716, #161717, #161839), 2 `Code Review` (#165194, #165204), 5 `Teste` (#165195, #165205, #165559, #165998, #166111). **Nenhum é do tipo `Análise`.**

- #161715 foi `Análise` e hoje é `Outros` (estado New); o histórico "Copied from Repro Steps when changed from Bug to Análise" está na descrição. Não é do tipo exigido e os campos `Custom.Pontosdeimpacto` e `Custom.CasodeTeste` não vieram preenchidos. Também descreve uma correção **não implementada**.
- Os bugs corrigidos trazem a causa raiz e a correção dentro do próprio `ReproSteps`/`Description` (#161713, #161716, #161839, #161712). Isso é útil, mas não substitui o card `Análise` combinado com o time e não traz "pontos de impacto" nem "casos de teste" nos campos próprios.

## Inventário de PRs (informativo, fora do gate)

Isto não é a análise técnica. É o fato bruto que a skill de mapa vai precisar quando o gate abrir.

| Bug | PR | Repositório / destino | Estado | Arquivos alterados (lista do PR) |
|---|---|---|---|---|
| #161713 | 30060 `bugfix/BUG161713-bpm-sql-job-not-poisoning` | net8 → `main` | Active | `ExecutaSqlExecHandler.cs`, `BpmExecJob.cs`, `Project.Core.Application.csproj`, `BpmSchedulerJob.cs`, `AgentBpmService.cs`, `ExecutaSqlSchedulerHandler.cs` |
| #161716 | 30104 `bugfix/bug161716-executaws-duplicate-jobs` | net8 → `main` | Active | `JobLogMessages.cs`, `ExecutaWsSchedulerHandler.cs`, `JobBpmRepository.cs`, `JobBpmService.cs`, `BpmSchedulerJob.cs` |
| #161712 | 30457 `bugfix/os161712-scheduler-duplicate-job-insert` | net8 → `main` | Active | `JobLogMessages.cs`, `AvancoTemporalSchedulerHandler.cs`, `ExecutaPassoAplicacaoHandler.cs`, `ExecutaSqlSchedulerHandler.cs`, `NotifySchedulerHandler.cs`, `InicioPublicacaoHandler.cs`, `BpmSchedulerJob.cs`, `JobBpmService.cs`, `JobBpmRepository.cs` |
| #161714 | 30486 `bugfix/US161714-correcao-log-erro-descricao` | net8 → `main` | Active | `AvancoTemporalExecHandler.cs` |
| #161839 | 30253 `bugfix/bug161839-previous-task-executor-notification` | net8 → `main` | Active | `CaminhoFluxoRepository.cs` |
| #161839 | 30254 mesma branch | SmartShare clássico → `master` | Active | `SmartShareAgent/NotifyWF.cs` |

Fatos do inventário (lidos no Azure DevOps):
- Todos os PRs têm `status = 1` (Active). O `lastMergeCommit` que a API mostra ("Merge pull request N ...") é o merge de teste do PR, não uma integração na `main`.
- Os cinco PRs do net8 foram criados contra o mesmo commit da `main` (`f708da1e`).
- Os PRs 30060, 30104 e 30457 alteram `BpmSchedulerJob.cs`. Os PRs 30060 e 30457 alteram `ExecutaSqlSchedulerHandler.cs`. Os PRs 30104 e 30457 alteram `JobBpmService.cs`, `JobBpmRepository.cs` e `JobLogMessages.cs`.
- Só 30486 e 30253 têm aprovação registrada (voto 10 do próprio autor); os demais não têm revisor no PR. Os cards de CR #165194 e #165204 estão Done.

## Discrepâncias visíveis sem ler código

- **#161712 lista mais jobs do que os arquivos do PR 30457 mostram.** Citados no bug como "precisa de ExisteJobAtivo": InicioTemporalScheduler, NotificaInicioComPublicacao, ExcluiFluxoEmSolicitacao, EnviaAlertaFluxo, InicioFluxoRevisao e InicioDesassociarAutomatico. Os arquivos do PR trazem handlers de AvancoTemporal, ExecutaPassoAplicacao, ExecutaSql, Notify e InicioPublicacao, mais `BpmSchedulerJob.cs`. Não dá para saber, só pela lista, se os demais estão em `BpmSchedulerJob.cs` ou ficaram sem ajuste. **Lacuna: precisa do diff ou do card `Análise`.** A checagem de timezone (`GetDataAtual`) também não aparece nos nomes de arquivos.
- **#161713** informa no `ReproSteps` que o PR é o 30060, e o `ExecutaSqlSchedulerHandler.cs` aparece também no 30457 (#161712). Dois PRs editam o mesmo handler: risco de conflito de merge.
- **#161716** diz "validar também a tabela DUMP" na correção; o PR 30104 não altera `JobDumpService`. Se o `ExisteChaveUnica` já existia no handler, pode estar certo. **Lacuna.**
- **#161839** aplica a correção em dois repositórios. O PR do clássico é uma alteração do **clássico instalado**, que não é de desenvolvimento neste ciclo; a mudança do clássico foi vista só pela lista de arquivos (`NotifyWF.cs`).
- Itens fora do escopo declarado: nenhum arquivo fora do escopo dos bugs foi identificado pela lista de arquivos. Os diffs não foram lidos.

## Versão analisada x versão implantada

| Bug | Esperado | Encontrado | Forma de verificação | Resultado |
|---|---|---|---|---|
| #161713 | commit `d4a98152` (branch do PR 30060) | não verificado | — | **NÃO VALIDADO — BLOQUEANTE PARA EXECUÇÃO** |
| #161716 | commit `e1396988` (PR 30104) | não verificado | — | **NÃO VALIDADO — BLOQUEANTE PARA EXECUÇÃO** |
| #161712 | commit `9816142b` (PR 30457) | não verificado | — | **NÃO VALIDADO — BLOQUEANTE PARA EXECUÇÃO** |
| #161714 | commit `3ac5ea98` (PR 30486) | não verificado | — | **NÃO VALIDADO — BLOQUEANTE PARA EXECUÇÃO** |
| #161839 net8 | commit `bfaf8358` (PR 30253) | não verificado | — | **NÃO VALIDADO — BLOQUEANTE PARA EXECUÇÃO** |
| #161839 clássico | commit `4b3535e7` (PR 30254) | não verificado | — | **NÃO VALIDADO — BLOQUEANTE PARA EXECUÇÃO** |

## Pré-requisitos técnicos de execução de teste

Informação não encontrada / necessita validação — bloqueante para `/arquitetura-executar-teste`:
- Qual build/branch o ambiente de teste deve rodar, já que os PRs não foram mesclados, e se deve ser **um build combinado** dos cinco PRs do net8 (arquivos em comum) ou um por PR.
- Valores de `MaxTentativas` e `PoliticaBackoff` de `JOB_CONFIG` para observar retry e envenenamento (#161713).
- Limite de seleção do Scheduler (100 pendências), intervalo do ciclo e como configurar o job 28 (#161716).
- Mecanismo para forçar falha de SQL no ExecutaSql e para forçar erro no AvancoTemporal (#161713, #161714).
- Massa para #161839: fluxo com 2 e 3 tarefas, tarefa anterior de papel/comitê e automática, dois fluxos com os mesmos números de tarefa, em Oracle e SQL Server.

## Informações ausentes

- Informação não encontrada / necessita validação: card `Análise` do dev (campos `Custom.Pontosdeimpacto` e `Custom.CasodeTeste`) para o PBI #161711, ou decisão do time de usar o `ReproSteps` de cada bug como fonte técnica.
- Informação não encontrada / necessita validação: diffs dos PRs, não lidos nesta etapa por falta do card.
- Informação não encontrada / necessita validação: se o PR 29631 (origem do `ExisteJobAtivo`) entra antes, depois ou nunca; e o que acontece com o método duplicado nos PRs 30104 e 30457.

## Próximo passo

Decisão necessária do QA: aguardar o card `Análise` (caminho oficial) ou autorizar explicitamente usar o conteúdo de cada bug e os diffs dos PRs como fonte técnica, o que muda a regra do gate.
