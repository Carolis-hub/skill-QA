# Etapa 18 — analise-tecnica — Bug #161716 (filho de #161711 Bugs Instaladores)

- **Skill e argumentos:** `/arquitetura-analise-tecnica 161711` com uma análise por bug
- **Data:** 2026-11-09
- **Escreveu no Azure DevOps:** Não
- **Aprovação:** o QA autorizou em 09/11, no chat, usar bugs e diffs dos PRs como fonte no lugar do card `Análise` ausente. Exceção válida só para esta rodada.
- **Fontes:** `ReproSteps` do bug, PR 30104 (metadados relidos em 09/11) e diff lido na etapa 03 (06/11). Commit inalterado (`e1396988`), PR `Active`.
- **Limite da fonte:** sem card `Análise`.

## Aprendizados consultados

Consulta realizada — nenhum aprendizado aplicável encontrado.

# Análise Técnica — Bug #161716 ExecutaWS: jobs duplicados com grandes quantidades de fluxos

**Card de Análise:** nenhum (exceção autorizada) | **PR vinculado:** 30104 (`bugfix/bug161716-executaws-duplicate-jobs`, Active, não mesclado)

## O que foi alterado

- `ExecutaWsSchedulerHandler.EnfileirarPendencias`: antes de `AddSql`, por pendência, (1) `jobDumpService.ExisteChaveUnica(chaveUnica)` e pula se já está na dump; (2) `jobBpmService.ExisteJobAtivo(chaveUnica, modulo, job, maxTentativas)` e pula se há job ativo. (PR 30104)
- Novo `JobBpmRepository.ExisteJobAtivo`: `COUNT(1)` em `JOB_BPM` por `CHAVE_UNICA + MODULO + JOB`, status Agendado, Executando e FalhaParaRepetir, e `QT_DE_TENTATIVAS < MaxTentativas`. Passthrough em `JobBpmService`, nova mensagem `AlreadyActive`, e `BpmSchedulerJob` passa `JobDumpService` e `config.MaxTentativas`. (PR 30104)
- **Extra não pedido no bug:** `try/catch` por pendência; o erro de uma pendência é logado e o loop segue (antes a exceção interrompia o ciclo inteiro). (PR 30104)

## Onde foi alterado (por camada)

| Camada | Alterado | Risco | Justificativa |
|---|---|---|---|
| Scheduler | `ExecutaWsSchedulerHandler`, `BpmSchedulerJob` | Médio | Mesmo `BpmSchedulerJob` dos PRs 30060 e 30457 (sem conflito textual com 30104) |
| Serviço/domínio | `JobBpmService` | Médio | Segundo `ExisteJobAtivo` do conjunto |
| Repositório/banco | `JobBpmRepository` | Médio | `COUNT(1)` em `JOB_BPM`; versão do 30104 não usa `RetNRowsSqlServer`/`RetNRowsOracle` |

## Dependências diretas

- `JobDumpService.ExisteChaveUnica`, `JobBpmService`, `JobConfig.MaxTentativas`, `BpmSchedulerJob`.

## Dependências indiretas

- PR 29631 (CalculoIndicador): citado como origem do método; no Azure DevOps ele aparece `Active`, não mesclado, em 09/11.
- Endpoint WebService externo do ExecutaWs (menos chamadas se a duplicação sumir).

## Funcionalidades, integrações e dados potencialmente impactados

- Criação de jobs do ExecutaWs por ciclo. Banco Oracle e SQL Server (`JOB_BPM`, `JOB_DUMP`). No cenário do bug, `JOB_DUMP` deve ter 101 registros em vez de 134.

## Discrepâncias entre análise do dev e o PR

### Dentro do escopo da US

1. **Dois `ExisteJobAtivo` diferentes** (este por chave única, módulo e job; o do PR 30457 por chave de concorrência). Mesclam sem conflito textual, com semântica distinta. **Lacuna:** a assinatura do PR 29631 (que o bug manda seguir) não foi lida.
2. **Alerta do próprio bug** ("confirmar se ChaveUnica pode bloquear um reagendamento novo") continua válido: chave com `passo` na dump bloqueia o reagendamento da mesma `fluxo/tarefa/passo` para sempre.
3. **`try/catch` por pendência** não está descrito no bug e muda o comportamento de erro (a falha vira log e o ciclo segue).

### Fora do escopo da US

Nenhuma identificada.

## Casos de teste sugeridos pelo dev

Passos do bug: 101 fluxos com tarefa WebService, job 28 em intervalo curto, mock HTTP 200 com JSON válido, 1º ciclo cria 100 jobs, comparar `JOB_DUMP` com os fluxos distintos e agrupar por `fluxo/tarefa/passo`. Esperado: 101 registros, 0 duplicados. Sugestões do dev, não validadas pelo QA.

## Pré-requisitos técnicos de execução de teste

| Item | Situação |
|---|---|
| Build com o PR 30104 | **Bloqueante** |
| Limite de seleção do Scheduler e intervalo do job 28 | "100" e "job 28" no bug; onde configurar não consta — validar antes de rodar |
| Mock HTTP 200 JSON | Descrito no bug; precisa subir |
| Massa de 101 fluxos com tarefa WebService | Precisa montar |

## Versão analisada x versão implantada

Esperado `e1396988` (PR 30104); encontrado: não verificado; resultado **NÃO VALIDADO — BLOQUEANTE PARA EXECUÇÃO**.

## Informações ausentes

- Informação não encontrada / necessita validação: assinatura de `ExisteJobAtivo` do PR 29631 e a ordem de integração.
