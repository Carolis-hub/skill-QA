# Etapa 03 — analise-tecnica — #161711 Bugs Instaladores

- **Skill e argumentos:** `/arquitetura-analise-tecnica 161711` (nova rodada, após a etapa 02 bloqueada)
- **Data:** 2026-11-06
- **Escreveu no Azure DevOps:** Não
- **Aprovação:** o QA (guilherme.borges) autorizou em 06/11 usar o conteúdo dos bugs e os diffs dos PRs como fonte técnica, no lugar do card `Análise` ausente. Isso é uma exceção ao gate da esteira e vale só para este ciclo.
- **Fontes lidas:** `ReproSteps`/`Description` dos bugs #161712, #161713, #161714, #161716, #161839 e #161715; diffs dos PRs 30060, 30104, 30457, 30486, 30253 (net8, `git diff origin/main...origin/<branch>` no clone local, após `git fetch` somente leitura) e 30254 (clássico, contra `origin/master`); teste de merge com `git merge-tree` (não altera a árvore de trabalho).
- **Limite da fonte:** não há card `Análise`; nenhum campo `Custom.Pontosdeimpacto`/`Custom.CasodeTeste`. As seções abaixo vêm do que o dev escreveu em cada bug e do diff real. Onde nenhum dos dois sustenta a afirmação, está escrito como lacuna.

## Aprendizados consultados

Consulta realizada — nenhum aprendizado aplicável encontrado.

# Análise Técnica — #161711 Bugs Instaladores

**Card de Análise:** nenhum (exceção autorizada pelo QA)
**PRs vinculados:** 30060, 30104, 30457, 30486, 30253 (net8) e 30254 (clássico) — todos `Active`, nenhum mesclado

## O que foi alterado

**#161716 — PR 30104 (`e1396988`) — `ExecutaWsSchedulerHandler.EnfileirarPendencias`**
- Antes de `AddSql`, por pendência: (1) `jobDumpService.ExisteChaveUnica(chaveUnica)` e pula se já está na dump; (2) `jobBpmService.ExisteJobAtivo(chaveUnica, modulo, job, maxTentativas)` e pula se há job ativo.
- Novo `JobBpmRepository.ExisteJobAtivo`: `COUNT(1)` em `JOB_BPM` por `CHAVE_UNICA + MODULO + JOB`, status Agendado/Executando/FalhaParaRepetir e `QT_DE_TENTATIVAS < MaxTentativas`. Novo passthrough em `JobBpmService`, nova mensagem `AlreadyActive`, e `BpmSchedulerJob` passa `JobDumpService` e `config.MaxTentativas`.
- **Extra não pedido no bug:** cada pendência ganhou `try/catch`; erro de uma pendência é logado e o loop segue (antes a exceção interrompia o ciclo inteiro).

**#161713 — PR 30060 (`d4a98152`) — poisoning do ExecutaSql**
- `AgentBpmService.ExecutarExecutaSql` recebe `qtdeTentativas`, `maxTentativas`, `politicaBackoff`. No `catch`: `DeveRelancarParaReagendar` (usa `WorkerHelper.ClassificarErro` + `JobResiliencePolicy.CalcularFalha`); se a decisão é `Retry`, faz `throw;` sem tratar. Se não, chama `TratarFalhaDefinitivaExecutaSql` (grava variável de erro, loga, tenta passo de escape, notifica ocorrência se `NotificaOcorrencia`) e **só relança se o escape não avançou**.
- `AvancaPassoEscapeExecutaSql` passa a devolver `bool` (`false` sem passo de escape ou se `AvancarFluxo` falha).
- `ExecutaSqlExecHandler.Processar` e `BpmExecJob` repassam `JobConfig`; `ExecutaSqlSchedulerHandler.EnfileirarPendencias` ganha `JobDumpService` e pula chave já na dump; `Project.Core.Application.csproj` referencia `Common.Resilience`.
- Extra: correção de caractere acentuado na mensagem de `CultureNotFoundException` (codificação).

**#161712 — PR 30457 (`9816142b`) — `ExisteJobAtivo` nos jobs do Scheduler**
- Novo `ExisteJobAtivo(chaveConcorrencia, maxTentativas)` em `JobBpmService`/`JobBpmRepository` (consulta `JOB_BPM` por `Chave_Concorrencia`, status Agendado/Executando/FalhaParaRepetir, `Qt_de_Tentativas < Max`; usa a transação do contexto). **Assinatura diferente da do PR 30104** (que filtra por `CHAVE_UNICA`, módulo e job).
- Checagem aplicada em: AvancoTemporal (6 pontos: VerificarAvanco tempo/prazo, anexos iguais reprovados, ValidarAnexo, lote), ExecutaPassoAplicacao, ExecutaSql, InicioPublicacao, NotifyScheduler (os 5 métodos), `BpmSchedulerJob` (InicioTemporal, ExcluiFluxoEmSolicitacao, EnviaAlertaFluxo).
- Timezone: `GetDataAtual()` trocado por `GetDataAtual(config.TimeZoneId)` em todos esses pontos. (A sobrecarga `GetDataAtual(string)` já existe na `main`.)
- Assinaturas dos handlers ganharam `timeZoneId` e `maxTentativas`.

**#161714 — PR 30486 (`3ac5ea98`)**
- Uma linha em `AvancoTemporalExecHandler.ProcessarFluxo`, no `catch`: `jr.Exception = ex;`. Os demais handlers do worker BPM já faziam isso (`ExecutaSql`, `ExecutaWs`, `NotifyWF`, `InicioTemporal` etc.); o AvancoTemporal era o único sem.

**#161839 — PRs 30253 (net8, `bfaf8358`) e 30254 (clássico, `4b3535e7`)**
- net8: `CaminhoFluxoRepository.GetUsuarioNotificaObservacaoExecutorTarefaAnterior` — troca a junção de três `CAMINHO_FLUXO` por junção direta `CAMINHO_FLUXO CF` + `TAREFA`, mantendo `cd_fluxo` nas duas pontas.
- Clássico: `SmartShareAgent/NotifyWF.cs`, `NotificaObservacao`, `case 4` — mesma troca no SQL inline. O PR também reordena `using`s (sem efeito de comportamento).

## Onde foi alterado (por camada)

| Camada | Alterado | Risco | Justificativa |
|---|---|---|---|
| Scheduler (enfileiramento) | `ExecutaWs`, `ExecutaSql`, `ExecutaPassoAplicacao`, `InicioPublicacao`, `AvancoTemporal`, `NotifyScheduler`, `BpmSchedulerJob` | **Alto** | Três PRs mexem nos mesmos arquivos; erro de integração para ou duplica jobs de todo o BPM. Job recorrente com checagem errada trava para sempre |
| Worker BPM (execução) | `ExecutaSqlExecHandler`, `BpmExecJob`, `AvancoTemporalExecHandler` | Médio | Muda retry/envenenamento do ExecutaSql; AvancoTemporal só ganha log |
| Serviço/domínio | `AgentBpmService` (ExecutaSql), `JobBpmService` | Médio | Fluxo de erro do ExecutaSql reescrito; dois `ExisteJobAtivo` com assinaturas distintas |
| Banco/repositório | `JobBpmRepository.ExisteJobAtivo` (2 versões), `CaminhoFluxoRepository` | Médio | SQL novo em Oracle e SQL Server (`RetNRowsSqlServer`/`RetNRowsOracle` só na versão do 30457; a do 30104 usa `COUNT(1)`); consulta de executor anterior agora retorna mais linhas |
| Notificação (net8 + clássico) | `GetUsuarioNotificaObservacaoExecutorTarefaAnterior`, `NotifyWF.cs` case 4 | Médio | Notifica pessoa errada se a junção cruzar fluxos; hoje o consumo pega só o último executor da lista |
| Build/dependência | `Project.Core.Application.csproj` → `Common.Resilience` | Baixo | Nova referência de projeto |

## Dependências diretas

- `JobResiliencePolicy.CalcularFalha` e `WorkerHelper.ClassificarErro` (decisão Retry/Envenenado do #161713).
- `JobDumpService.ExisteChaveUnica` (#161713, #161716).
- `BpmExecJob.ErroExecusao` (grava `JobStatusId = Envenenado` e dump) — o `throw;` do #161713 depende dele para envenenar.
- `JobConfig` (`MaxTentativas`, `PoliticaBackoff`, `TimeZoneId`) como parâmetros nos handlers.
- `NotifyWFExecHandler.cs` (laço que consome a lista de executores) para o #161839.

## Dependências indiretas

- Todos os jobs do Scheduler passam por `BpmSchedulerJob`: qualquer mudança em assinatura de handler quebra a compilação do conjunto.
- Notificações do NotifyWF dependem do `ExisteJobAtivo` do #161712 e, para poisoning, do #161715 (não implementado).

## Funcionalidades potencialmente impactadas

- Todos os jobs do Scheduler listados acima: criação de job por ciclo, agora condicionada a `ExisteJobAtivo`.
- Retry e envenenamento do ExecutaSql; avanço pelo passo de escape.
- Notificação de observação "executor da tarefa anterior".
- Log do AvancoTemporal.

## Integrações potencialmente impactadas

- Banco Oracle e SQL Server (`JOB_BPM`, `JOB_DUMP`, `CAMINHO_FLUXO`, `TAREFA`).
- Envio de e-mail das notificações (#161839).
- Endpoint WebService externo do ExecutaWs (volume de chamadas muda se a duplicação some).
- Clássico (Agent instalado) para o #161839.

## Dados potencialmente impactados

- `JOB_BPM` (menos linhas duplicadas) e `JOB_DUMP` (101 registros em vez de 134 no cenário do #161716).
- Variáveis de erro do fluxo no ExecutaSql (agora só na última tentativa).

## Discrepâncias entre análise do dev e o PR

### Dentro do escopo da US

1. **PRs 30060 e 30457 conflitam.** `git merge-tree` acusa conflito de conteúdo em `ExecutaSqlSchedulerHandler.cs` (os dois alteram a assinatura de `EnfileirarPendencias`: 30060 adiciona `jobDumpService`, 30457 adiciona `timeZoneId` e `maxTentativas`) e em `BpmSchedulerJob.cs` (a chamada de `ExecutaSql`). Os pares 30060+30104, 30104+30457, 30060+30486, 30457+30486 e 30253+30457 mesclam sem conflito textual. (lida no código)
2. **Dois `ExisteJobAtivo` diferentes** (30104: chave única + módulo + job; 30457: chave de concorrência). Mesclam sem conflito textual, mas são sobrecargas com semântica distinta; o #161716 diz que o método deveria ser portado "do mesmo jeito genérico" da PR 29631 para evitar conflito, e a PR 29631 não foi lida. **Lacuna:** qual assinatura é a da PR 29631.
3. **#161712 pede ajuste em InicioFluxoRevisao, InicioDesassociarAutomatico e NotificaInicioComPublicacao, mas os três são `// TODO` na `main` e estão comentados em `EnqueueJobSchedulerQuartz`** (não rodam). Não há o que testar para esses três neste build. (lida no código; `InicioDesassociarAutomatico` é a migração da US 160823, em outro branch)
4. **#161712 diz que ExecutaWs "não necessita de ajustes, já aplicado no PR 30104"** — consistente com o diff: o 30457 não toca `ExecutaWsSchedulerHandler`.
5. **ExecutaSql terá duas checagens se os dois PRs forem integrados** (dump do 30060 e job ativo do 30457). O resultado depende de como o conflito for resolvido. **Lacuna:** nenhum PR combinado existe.
6. **#161716 pede "validar existe na dump"** — o PR 30104 faz essa checagem antes do `ExisteJobAtivo`. O alerta do próprio bug ("confirmar se ChaveUnica pode bloquear um reagendamento novo") continua válido: chave com `passo` na dump bloqueia o reagendamento da mesma `fluxo/tarefa/passo` para sempre.
7. **`try/catch` por pendência no 30104** não está descrito no bug (muda o comportamento de erro: a falha vira log e o ciclo continua).
8. **Borda do `ExisteJobAtivo` do 30457:** a condição `Qt_de_Tentativas < Max` faz um job em `FalhaParaRepetir` já no limite de tentativas deixar de contar como ativo; nesse intervalo o Scheduler pode criar outro. (lida no código; impacto real não medido)

### Fora do escopo da US

- Reordenação de `using` no PR clássico 30254 e correção de acentuação em 30060: sem efeito de comportamento. Risco potencial baixo; sem impacto no gate. A revisão de branch/PR fica com o time de Dev (a skill de revisão de PR não está neste ciclo).

## Casos de teste sugeridos pelo dev

**#161839** (roteiro do bug):
1. Fluxo de 2–3 tarefas com a opção "Visualização e Inclusão pelo executor notificando executor da tarefa anterior": o executor anterior recebe o e-mail.
2. Tarefa anterior atribuída a papel/comitê: recebe quem concluiu a tarefa.
3. Tarefa anterior automática (SQL, WS, e-mail, condição): nenhuma notificação nessa opção; fluxo e demais notificações seguem.
4. Dois fluxos com os mesmos números de tarefa: cada fluxo notifica só o seu executor anterior.
5. Compatibilidade Oracle e SQL Server.

**#161716** (passos do bug): 101 fluxos com tarefa WebService, job 28 em intervalo curto, mock HTTP 200, 1º ciclo cria 100 jobs, comparar `JOB_DUMP` com fluxos distintos; agrupar por `fluxo/tarefa/passo`. Esperado: 101 registros, 0 duplicados.

**#161713** (cobertura declarada pelo dev): ramos retry e envenenado e retorno `bool` de `AvancaPassoEscapeExecutaSql`, 80% nas áreas alteradas. Resultado informado pelo dev: build 0 erros, 2048 testes passando, 2 falhas pré-existentes em `Usuario*Tests`. (declarado pelo dev, não verificado)

Sem casos sugeridos pelo dev: #161712, #161714.

Sugestões do dev, não validadas pelo QA.

## Pré-requisitos técnicos de execução de teste

| Item | Encontrado | Situação |
|---|---|---|
| Build a testar | Cada PR parte do mesmo commit da `main` (`f708da1e`); 30060 e 30457 conflitam | **Bloqueante:** definir branch de teste (PRs isolados ou integração) |
| `MaxTentativas`, `PoliticaBackoff`, `TimeZoneId` | Lidos de `JobConfig` (por job) | Valores no banco não verificados — **bloqueante para #161713** |
| Forçar falha do ExecutaSql | Nenhum mecanismo descrito | **Informação não encontrada — bloqueante para #161713** |
| Forçar erro no AvancoTemporal | Nenhum mecanismo descrito | **Informação não encontrada — bloqueante para #161714** |
| Limite de seleção do Scheduler e intervalo do job 28 | "100" e "job 28" no bug; onde configurar não consta | Validar antes de rodar #161716 |
| Mock HTTP 200 JSON | Descrito no bug | Precisa subir |
| Massa de observação | Roteiro no bug | Precisa montar (2–3 tarefas, papel/comitê, automática, 2 fluxos) |
| Oracle e SQL Server | Bug cita os dois | Rodar nos dois; ver aprendizado `QA-KB-20261106-001` (troca de banco), a revalidar |
| Agent clássico com o fix do PR 30254 | PR Active | **Bloqueante para #161839 no clássico** |

## Versão analisada x versão implantada

| Bug | Esperado | Encontrado | Verificação | Resultado |
|---|---|---|---|---|
| #161713 | `d4a98152` (30060) | não verificado | — | NÃO VALIDADO — BLOQUEANTE PARA EXECUÇÃO |
| #161716 | `e1396988` (30104) | não verificado | — | NÃO VALIDADO — BLOQUEANTE PARA EXECUÇÃO |
| #161712 | `9816142b` (30457) | não verificado | — | NÃO VALIDADO — BLOQUEANTE PARA EXECUÇÃO |
| #161714 | `3ac5ea98` (30486) | não verificado | — | NÃO VALIDADO — BLOQUEANTE PARA EXECUÇÃO |
| #161839 net8 | `bfaf8358` (30253) | não verificado | — | NÃO VALIDADO — BLOQUEANTE PARA EXECUÇÃO |
| #161839 clássico | `4b3535e7` (30254) | não verificado | — | NÃO VALIDADO — BLOQUEANTE PARA EXECUÇÃO |

Os commits esperados batem com o tip da branch no remoto (conferido no `git fetch`). O que roda no ambiente de teste ainda precisa ser confirmado.

## Informações ausentes

- Informação não encontrada / necessita validação: assinatura de `ExisteJobAtivo` na PR 29631 e se ela entra antes dos PRs 30104/30457.
- Informação não encontrada / necessita validação: qual resolução do conflito 30060 × 30457 será adotada e quem a faz.
- Informação não encontrada / necessita validação: valores de `JOB_CONFIG` (`MaxTentativas`, `PoliticaBackoff`) e como provocar falha de SQL e erro de AvancoTemporal em teste.
- Informação não encontrada / necessita validação: mensagem de log antes/depois do #161714; só se sabe que `Exception` passa a ser preenchida no `JobResult`.
- Informação não encontrada / necessita validação: #161715 não está implementado; o NotifyWF continua sem poisoning.

## Próximo passo

Gate liberado só por exceção do QA. Para `/arquitetura-gerar-mapa-testes 161711` ainda precisam ser resolvidos: build de teste (conflito 30060 × 30457), card de Teste por bug e os pré-requisitos bloqueantes acima.
