# Etapa 15 — analise-tecnica — Bug #161713 (filho de #161711 Bugs Instaladores)

- **Skill e argumentos:** `/arquitetura-analise-tecnica 161711` com uma análise por bug
- **Data:** 2026-11-09
- **Escreveu no Azure DevOps:** Não
- **Aprovação:** o QA autorizou em 09/11, no chat, usar bugs e diffs dos PRs como fonte no lugar do card `Análise` ausente. Exceção válida só para esta rodada.
- **Fontes:** `Description` e `ReproSteps` do bug, PR 30060 (metadados relidos em 09/11) e diff lido na etapa 03 (06/11). Commit do PR inalterado (`d4a98152`), PR `Active`, alvo `f708da1e`.
- **Limite da fonte:** sem card `Análise`.

## Aprendizados consultados

Consulta realizada — nenhum aprendizado aplicável encontrado.

# Análise Técnica — Bug #161713 BPM: ExecutaSql não envenena o job

**Card de Análise:** nenhum (exceção autorizada) | **PR vinculado:** 30060 (`bugfix/BUG161713-bpm-sql-job-not-poisoning`, Active, não mesclado)

## O que foi alterado

- `AgentBpmService.ExecutarExecutaSql` recebe `qtdeTentativas`, `maxTentativas` e `politicaBackoff`. No `catch`: `DeveRelancarParaReagendar` (usa `WorkerHelper.ClassificarErro` e `JobResiliencePolicy.CalcularFalha`); se a decisão é `Retry`, faz `throw;` sem tratar. Senão chama `TratarFalhaDefinitivaExecutaSql` (grava variável de erro, loga, tenta o passo de escape, notifica ocorrência se `NotificaOcorrencia`) e **só relança se o escape não avançou**. (PR 30060)
- `AvancaPassoEscapeExecutaSql` passa a devolver `bool` (`false` sem passo de escape ou se `AvancarFluxo` falha). (PR 30060)
- `ExecutaSqlExecHandler.Processar` e `BpmExecJob` repassam `JobConfig`. `ExecutaSqlSchedulerHandler.EnfileirarPendencias` ganha `JobDumpService` e pula chave já na dump. `Project.Core.Application.csproj` referencia `Common.Resilience`. (PR 30060)
- Extra: correção de acentuação na mensagem de `CultureNotFoundException`. (PR 30060)

## Onde foi alterado (por camada)

| Camada | Alterado | Risco | Justificativa |
|---|---|---|---|
| Worker BPM | `ExecutaSqlExecHandler`, `BpmExecJob` | Médio | Muda o retry e o envenenamento do ExecutaSql |
| Serviço/domínio | `AgentBpmService` | Médio | Fluxo de erro reescrito: `throw;` condicional e tratamento definitivo separado |
| Scheduler | `ExecutaSqlSchedulerHandler` | **Alto** | Mesmo arquivo do PR 30457 (conflito) |
| Build | `Project.Core.Application.csproj` → `Common.Resilience` | Baixo | Nova referência de projeto |

## Dependências diretas

- `JobResiliencePolicy.CalcularFalha`, `WorkerHelper.ClassificarErro`, `JobDumpService.ExisteChaveUnica`, `JobConfig` (`MaxTentativas`, `PoliticaBackoff`).
- `BpmExecJob.ErroExecusao` (grava `JobStatusId = Envenenado` e a dump): o `throw;` do escape que não avança depende dele para envenenar.

## Dependências indiretas

- `NotificaOcorrencia` e o passo de escape do fluxo; handler `ExecutaSqlExecHandler` (catch externo seta `jr.Reagendar`).

## Funcionalidades, integrações e dados potencialmente impactados

- Retry e envenenamento do ExecutaSql; avanço pelo passo de escape; notificação de ocorrência. Banco: `JOB_BPM`, `JOB_DUMP`. Variáveis de erro do fluxo agora só na última tentativa.

## Discrepâncias entre análise do dev e o PR

### Dentro do escopo da US

1. **Conflito com o PR 30457** em `ExecutaSqlSchedulerHandler.cs` (assinatura de `EnfileirarPendencias`) e em `BpmSchedulerJob.cs` (chamada do ExecutaSql). (lida no código, 06/11)
2. A `Description` (plano) e o `ReproSteps` (entrega) diferem: o plano previa `AvancaPassoEscapeExecutaSql` sinalizando reagendar; a entrega separa `DeveRelancarParaReagendar` e `TratarFalhaDefinitivaExecutaSql`. O `ReproSteps` (entrega) coincide com o diff.
3. Resultado de testes citado pelo dev (2048 passando, 2 falhas pré-existentes em `Usuario*Tests`) é declarado pelo dev, não verificado.

### Fora do escopo da US

Correção de acentuação em `CultureNotFoundException`: sem efeito de comportamento; risco baixo; sem impacto no gate.

## Casos de teste sugeridos pelo dev

Cobertura declarada: ramos retry e envenenado, retorno `bool` de `AvancaPassoEscapeExecutaSql`, 80% nas áreas alteradas. Sugestões do dev, não validadas pelo QA.

## Pré-requisitos técnicos de execução de teste

| Item | Situação |
|---|---|
| Build com o PR 30060 | **Bloqueante** (conflito com 30457) |
| `MaxTentativas` e `PoliticaBackoff` do job ExecutaSql | Valores não verificados no banco — **bloqueante** |
| Forçar falha de SQL (por exemplo SQL inválido na atividade) | Nenhum mecanismo descrito — **Informação não encontrada / necessita validação — bloqueante** |
| Fluxo com e sem passo de escape configurado | Massa a montar |

## Versão analisada x versão implantada

Esperado `d4a98152` (PR 30060); encontrado: não verificado; resultado **NÃO VALIDADO — BLOQUEANTE PARA EXECUÇÃO**.

## Informações ausentes

- Informação não encontrada / necessita validação: valores de `JOB_CONFIG` e meio de provocar a falha.
