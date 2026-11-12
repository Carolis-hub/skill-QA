# Etapa 16 — analise-tecnica — Bug #161714 (filho de #161711 Bugs Instaladores)

- **Skill e argumentos:** `/arquitetura-analise-tecnica 161711` com uma análise por bug
- **Data:** 2026-11-09
- **Escreveu no Azure DevOps:** Não
- **Aprovação:** o QA autorizou em 09/11, no chat, usar bugs e diffs dos PRs como fonte no lugar do card `Análise` ausente. Exceção válida só para esta rodada.
- **Fontes:** `ReproSteps` do bug, PR 30486 (metadados relidos em 09/11) e diff lido na etapa 03 (06/11). Commit inalterado (`3ac5ea98`), PR `Active`.
- **Limite da fonte:** sem card `Análise`.

## Aprendizados consultados

Consulta realizada — nenhum aprendizado aplicável encontrado.

# Análise Técnica — Bug #161714 BPM: log de erro do AvancoTemporal mascara o erro

**Card de Análise:** nenhum (exceção autorizada) | **PR vinculado:** 30486 (`bugfix/US161714-correcao-log-erro-descricao`, Active, não mesclado)

## O que foi alterado

- Uma linha em `AvancoTemporalExecHandler.ProcessarFluxo`, no `catch`: `jr.Exception = ex;`. Os demais handlers do worker BPM (`ExecutaSql`, `ExecutaWs`, `NotifyWF`, `InicioTemporal` e outros) já faziam isso; o AvancoTemporal era o único sem. (PR 30486, lida no código em 06/11)

## Onde foi alterado (por camada)

| Camada | Alterado | Risco | Justificativa |
|---|---|---|---|
| Worker BPM | `AvancoTemporalExecHandler.ProcessarFluxo` | Baixo | Uma linha; preenche a exceção do `JobResult` para o log central |

## Dependências diretas

- O consumidor de `JobResult.Exception` no `BpmExecJob` (log de erro e envenenamento).

## Dependências indiretas

- O #161712 também altera o AvancoTemporal no Scheduler (enfileiramento); não no handler de execução.

## Funcionalidades, integrações e dados potencialmente impactados

- Conteúdo do log de erro do AvancoTemporal. Possível efeito em quem monitora esse log. Nenhum dado de negócio alterado.

## Discrepâncias entre análise do dev e o PR

### Dentro do escopo da US

1. O bug diz só "log não descreve o problema" e traz a branch; o diff mostra que o mecanismo era a exceção não repassada ao `JobResult`. A mensagem exata antes e depois **não está no bug nem no PR**. (lida no código)
2. Efeito colateral possível: ao preencher `jr.Exception`, o `BpmExecJob` pode passar a tratar a falha como erro de execução (retry e envenenamento) onde antes tratava de outra forma. **Lacuna:** o ramo de `BpmExecJob` que consome a exceção não foi relido nesta rodada.

### Fora do escopo da US

Nenhuma identificada.

## Casos de teste sugeridos pelo dev

Nenhum. Sugestões do dev, não validadas pelo QA: não há.

## Pré-requisitos técnicos de execução de teste

| Item | Situação |
|---|---|
| Build com o PR 30486 | **Bloqueante** |
| Forçar erro no AvancoTemporal (por exemplo, passo temporal com dado inválido) | Nenhum mecanismo descrito — **Informação não encontrada / necessita validação — bloqueante** |
| Onde ler o log (arquivo, tabela ou console do Worker) | Não descrito |

## Versão analisada x versão implantada

Esperado `3ac5ea98` (PR 30486); encontrado: não verificado; resultado **NÃO VALIDADO — BLOQUEANTE PARA EXECUÇÃO**.

## Informações ausentes

- Informação não encontrada / necessita validação: exemplo da mensagem de log antes e depois e a falha que a provoca.
