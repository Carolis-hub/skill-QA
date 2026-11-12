# Etapa 14 — analise-tecnica — Bug #161712 (filho de #161711 Bugs Instaladores)

- **Skill e argumentos:** `/arquitetura-analise-tecnica 161711` com uma análise por bug
- **Data:** 2026-11-09
- **Escreveu no Azure DevOps:** Não
- **Aprovação:** o QA (guilherme.borges) autorizou em 09/11, no chat, usar bugs e diffs dos PRs como fonte no lugar do card `Análise` ausente. Exceção válida só para esta rodada.
- **Fontes:** `ReproSteps` do bug, PR 30457 (metadados relidos em 09/11) e o diff lido na etapa 03 (06/11, `git diff origin/main...origin/<branch>`). O diff não foi relido: o commit do PR é o mesmo (`9816142b`), o alvo continua `f708da1e` e o PR segue `Active` com `mergeStatus` 3 (sem conflito com a `main` isolado).
- **Limite da fonte:** sem card `Análise`; sem `Custom.Pontosdeimpacto` e `Custom.CasodeTeste`.

## Aprendizados consultados

Consulta realizada — nenhum aprendizado aplicável encontrado.

# Análise Técnica — Bug #161712 Scheduler: várias tentativas de inserir um mesmo JOB

**Card de Análise:** nenhum (exceção autorizada) | **PR vinculado:** 30457 (`bugfix/os161712-scheduler-duplicate-job-insert`, Active, não mesclado)

## O que foi alterado

- Novo `ExisteJobAtivo(chaveConcorrencia, maxTentativas)` em `JobBpmService` e `JobBpmRepository`: consulta `JOB_BPM` por `Chave_Concorrencia`, status Agendado, Executando e FalhaParaRepetir, com `Qt_de_Tentativas < Max`, usando a transação do contexto. (PR 30457)
- Checagem aplicada em: AvancoTemporal (6 pontos: VerificarAvanco tempo e prazo, anexos iguais reprovados, ValidarAnexo, lote), ExecutaPassoAplicacao, ExecutaSql, InicioPublicacao, NotifyScheduler (5 métodos) e, em `BpmSchedulerJob`, InicioTemporal, ExcluiFluxoEmSolicitacao e EnviaAlertaFluxo. (PR 30457)
- `GetDataAtual()` trocado por `GetDataAtual(config.TimeZoneId)` nesses pontos; a sobrecarga já existe na `main`. As assinaturas dos handlers ganharam `timeZoneId` e `maxTentativas`. (PR 30457)

## Onde foi alterado (por camada)

| Camada | Alterado | Risco | Justificativa |
|---|---|---|---|
| Scheduler | handlers dos jobs listados e `BpmSchedulerJob` | **Alto** | Mesmos arquivos de 30060 e 30104; mudança de assinatura quebra a compilação do conjunto |
| Serviço/domínio | `JobBpmService.ExisteJobAtivo` | Médio | Assinatura diferente da do PR 30104 |
| Repositório/banco | `JobBpmRepository.ExisteJobAtivo` | Médio | SQL novo em Oracle e SQL Server (usa `RetNRowsSqlServer`/`RetNRowsOracle`) |

## Dependências diretas

- `JobBpmService`, `JobBpmRepository`, `JobConfig` (`MaxTentativas`, `TimeZoneId`), `BpmSchedulerJob`.

## Dependências indiretas

- Todos os jobs do Scheduler passam por `BpmSchedulerJob`; as notificações do NotifyWF dependem deste método e do #161715 para o poisoning.

## Funcionalidades, integrações e dados potencialmente impactados

- Criação de job por ciclo em cerca de 11 jobs do Scheduler. Banco Oracle e SQL Server. Linhas de `JOB_BPM` (menos duplicadas).

## Discrepâncias entre análise do dev e o PR

### Dentro do escopo da US

1. **Conflito com o PR 30060** em `ExecutaSqlSchedulerHandler.cs` e `BpmSchedulerJob.cs` (`git merge-tree` da etapa 03). Os demais pares mesclam sem conflito textual. (lida no código, 06/11)
2. **Dois `ExisteJobAtivo` distintos** (este por chave de concorrência; o do PR 30104 por chave única, módulo e job). Mesclam sem conflito textual, mas com semântica diferente.
3. **InicioFluxoRevisao, InicioDesassociarAutomatico e NotificaInicioComPublicacao** são `// TODO` na `main` e estão comentados em `EnqueueJobSchedulerQuartz`; o PR não os cobre e não há o que testar neles neste build.
4. **Borda:** a condição `Qt_de_Tentativas < Max` faz um job em `FalhaParaRepetir` já no limite deixar de contar como ativo; nesse intervalo o Scheduler pode criar outro. Impacto real não medido.
5. **ExecutaSql** teria duas checagens (dump do 30060 e job ativo deste PR) se os dois forem integrados; depende de como o conflito for resolvido.

### Fora do escopo da US

Nenhuma identificada neste bug.

## Casos de teste sugeridos pelo dev

Nenhum no bug. Sugestões do dev, não validadas pelo QA: não há.

## Pré-requisitos técnicos de execução de teste

| Item | Situação |
|---|---|
| Build com o PR 30457 (e definição sobre o conflito com 30060) | **Bloqueante** |
| `TimeZoneId` e `MaxTentativas` em `JOB_CONFIG` por job | Valores não verificados no banco |
| Como observar duplicidade (consulta em `JOB_BPM` por chave) | Não descrito no bug; a definir |

## Versão analisada x versão implantada

Esperado `9816142b` (PR 30457); encontrado: não verificado; resultado **NÃO VALIDADO — BLOQUEANTE PARA EXECUÇÃO**.

## Informações ausentes

- Informação não encontrada / necessita validação: resultado esperado por job e escopo da validação de timezone.
- Informação não encontrada / necessita validação: resolução do conflito 30060 × 30457 e quem a faz.
