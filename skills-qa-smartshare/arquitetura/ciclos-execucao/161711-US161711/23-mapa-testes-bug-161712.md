# Etapa 23 — mapa-testes — Bug #161712 (filho de #161711 Bugs Instaladores)

- **Skill e argumentos:** `/arquitetura-gerar-mapa-testes 161711` com um mapa por bug
- **Data:** 2026-11-09
- **Escreveu no Azure DevOps:** **Não.** Mapa só neste ciclo local (decisão do QA, mantida).
- **Aprovação:** instrução do QA (09/11): testar cada bug na sua branch específica. Aprovação da tabela e da publicação: **pendente**.
- **Fontes:** etapas 06 a 20, mapa da etapa 04 (reaproveitado e reorganizado), `ReproSteps` do #161712, PR 30457 (`9816142b`). Card `Análise` ausente (exceção autorizada em 09/11). Cenário de regressão do #161717 incluído aqui (#161717 está fechado sem correção).

## Aprendizados consultados

Consulta realizada — nenhum aprendizado aplicável encontrado.

# Mapa de Testes — #161712 Scheduler: várias tentativas de inserir um mesmo JOB

**Estratégia:** Transversal (idempotência dos jobs do Scheduler). **Build de teste:** só a branch `bugfix/os161712-scheduler-duplicate-job-insert` (PR 30457), sobre a `main` de `f708da1e`. Nesta branch o ExecutaSql tem só `ExisteJobAtivo` (a checagem de dump é do PR 30060, fora do build) e o ExecutaWs não é alterado (é do PR 30104).
**Card de Teste:** #165998 | **Card de CR:** não existe

## 1. Visão geral

Valida que cada job do Scheduler listado no bug não é enfileirado de novo enquanto há job ativo para a mesma chave, que jobs recorrentes voltam a rodar depois de concluídos e que a data usa o timezone configurado. **Risco:** alto (job duplicado ou recorrente travado).

## 2. Fontes analisadas

`ReproSteps` do #161712 (primária); PR 30457: `ExisteJobAtivo`, handlers do Scheduler, `BpmSchedulerJob` (técnica). Defeito relacionado: #161717 (regressão do EnviaAlertaFluxo).

## 3. Requisitos e regras

| Req | Regra |
|---|---|
| R4.1 | Os jobs listados checam `ExisteJobAtivo` e não duplicam enquanto há job Agendado, Executando ou FalhaParaRepetir |
| R4.2 | Jobs recorrentes ou de chave fixa não usam dump e voltam a ser criados depois de concluídos |
| R4.3 | `GetDataAtual(TimeZoneId)` nos jobs alterados |
| R4.4 | InicioFluxoRevisao, InicioDesassociarAutomatico e NotificaInicioComPublicacao são `// TODO` na `main`: fora do teste |

## 4. Matriz de paridade

Não aplicável.

## 5. Premissas, ambiguidades e ausências

- Premissa (QA): teste só na branch do PR 30457; ExecutaWs e a dump do ExecutaSql não existem nesse build.
- DUV-01: resultado esperado por job (número de linhas em `JOB_BPM` após N ciclos) não está no bug; adotado "1 job ativo por chave".
- DUV-02: valores de `TimeZoneId` e `MaxTentativas` em `JOB_CONFIG` desconhecidos.
- DUV-03: InicioTemporal: "ExisteJobAtivo como reforço" opcional; cobrir sem tratar como critério de aceite.

## 6. Pré-requisitos gerais

Branch do PR 30457 em Scheduler e Worker; versão implantada a confirmar. SQL Server e Oracle. Acesso a `JOB_BPM` e logs. Massa para cada job (documento, fluxo, tarefa, mensagem, observação, alerta). Mock de e-mail ou SMTP para os jobs de notificação.

## 7. Cobertura planejada

Dimensões: positivo, negativo, dados, regressão; concorrência por hipótese. Permissão: `N/A — job roda como serviço`.

## 8. Cenários (12)

### === FLUXO PRINCIPAL ===

| # | Cenário | Ação | Resultado Esperado | Tipo | Técnica | Dimensão | Origem | Camada | Componente |
|---|---|---|---|---|---|---|---|---|---|
| 1 | AvancoTemporal não duplica | Para cada ponto (tempo, prazo, anexos iguais reprovados, valida anexo, lote) manter 1 job ativo e rodar vários ciclos | 1 job por chave; log `SkippedJobAtivo` | positivo | partição-equivalência | positivo | história | Scheduler | `AvancoTemporalSchedulerHandler` |
| 2 | ExecutaPassoAplicacao não duplica | Idem, com job ativo | 1 job por chave | positivo | partição-equivalência | positivo | história | Scheduler | `ExecutaPassoAplicacaoHandler` |
| 3 | ExecutaSql e InicioPublicacao não duplicam | Idem, para os dois jobs | 1 job por chave `BPM\|ExecutaSql\|fluxo\|tarefa` e `BPM\|InicioPublicacao\|processo\|versao` | positivo | partição-equivalência | positivo | história | Scheduler | `ExecutaSqlSchedulerHandler`, `InicioPublicacaoHandler` |
| 4 | NotifyScheduler pendência (3 tipos) | Gerar pendência de mensagem nova, observação e tarefa com job ativo | 1 job por fluxo+tarefa em cada tipo | positivo | partição-equivalência | positivo | história | Scheduler | `NotifySchedulerHandler` |
| 5 | NotifyScheduler alertas e exceção de alçada | Com job ativo de chave fixa, rodar ciclos | 1 job `NotificarAlertas` e 1 `NotificarMensagemExcecaoAlcada` ativos | positivo | partição-equivalência | positivo | história | Scheduler | `NotifySchedulerHandler` |
| 6 | ExcluiFluxoEmSolicitacao, EnviaAlertaFluxo e InicioTemporal | Idem, 3 jobs | Sem duplicar; InicioTemporal pula quando já ativo | positivo | partição-equivalência | positivo | história | Scheduler | `BpmSchedulerJob` |

### === FLUXO ALTERNATIVO ===

| # | Cenário | Ação | Resultado Esperado | Tipo | Técnica | Dimensão | Origem | Camada | Componente |
|---|---|---|---|---|---|---|---|---|---|
| 7 | Job recorrente volta após terminar | Concluir o job ativo de chave fixa (ex.: `EnviaAlertaFluxo`) e aguardar o ciclo seguinte | Novo job criado; recorrente não fica bloqueado | positivo | transição-de-estado | positivo | história | Scheduler | `ExisteJobAtivo` |

### === VALIDACOES DE CAMPOS ===

| # | Cenário | Ação | Resultado Esperado | Tipo | Técnica | Dimensão | Origem | Camada | Componente |
|---|---|---|---|---|---|---|---|---|---|
| 8 | Timezone configurado | `TimeZoneId` diferente do servidor e agendar job | `DataProgramada` e `DataCriacao` respeitam o fuso | positivo | partição-equivalência | dados | história | Scheduler | `GetDataAtual(timeZoneId)` |

### === DADOS E CASOS DE BORDA ===

| # | Cenário | Ação | Resultado Esperado | Tipo | Técnica | Dimensão | Origem | Camada | Componente |
|---|---|---|---|---|---|---|---|---|---|
| 9 | Jobs `// TODO` não agendam | Rodar ciclos e consultar `JOB_BPM` | Nenhum job `InicioFluxoRevisao`, `InicioDesassociarAutomatico` ou `NotificaInicioComPublicacao` | borda | partição-equivalência | dados | análise técnica/PR | Scheduler | `EnqueueJobSchedulerQuartz` |
| 10 | HIPOTESE: job no limite de tentativas | `FalhaParaRepetir` com `Qt_de_Tentativas` = `MaxTentativas`; rodar ciclo | Esperado: sem duplicata; a SQL do PR não o conta como ativo | borda | valor-limite | concorrência | hipótese | Scheduler | `Qt_de_Tentativas < Max` |

### === REGRESSAO ===

| # | Cenário | Ação | Resultado Esperado | Tipo | Técnica | Dimensão | Origem | Camada | Componente |
|---|---|---|---|---|---|---|---|---|---|
| 11 | InicioTemporal por frequência | Frequência diária, semanal e mensal na hora certa | 1 job por ocorrência | positivo | tabela-decisão | regressão | análise técnica/PR | Scheduler | `InicioTemporalSchedulerHandler.GerarJob` |
| 12 | EnviaAlertaFluxo com vários alertas no mesmo período (defeito #161717) | 2+ alertas no mesmo período e rodar | Todos os e-mails chegam; o job não é suprimido pelo `ExisteJobAtivo` | positivo | partição-equivalência | regressão | histórico de defeitos | Scheduler/Notificação | `BpmSchedulerJob.EnviaAlertaFluxo` |

### === CONCORRENCIA ===

N/A neste bug além da hipótese #10: o bug não trata de duas instâncias do Scheduler.

## 9. Passo a passo

**1 a 3, 4, 5, 6 (padrão).** 1. O executor deve gerar a condição de pendência do job `[JOB]` (por exemplo, fluxo com tarefa elegível) e manter 1 job da chave `[CHAVE]` Agendado ou Executando. 2. O sistema deve ter 1 linha ativa em `JOB_BPM` para a chave. 3. O executor deve aguardar 3 ciclos do Scheduler e ler o log. 4. O sistema deve registrar `SkippedJobAtivo` (ou equivalente) e manter 1 linha ativa para a chave. 5. O executor deve consultar `SELECT CHAVE_CONCORRENCIA, COUNT(*) FROM JOB_BPM WHERE JOB_STATUS_ID IN (Agendado, Executando, FalhaParaRepetir) GROUP BY CHAVE_CONCORRENCIA HAVING COUNT(*) > 1`. 6. O sistema deve retornar 0 linhas. Repetir para cada job das linhas 1 a 6 da tabela.

**7.** 1. O executor deve ter 1 job `EnviaAlertaFluxo` ativo e deixá-lo concluir. 2. O sistema deve marcar o job concluído. 3. O executor deve aguardar o ciclo seguinte. 4. O sistema deve criar novo job `EnviaAlertaFluxo` (recorrência preservada).

**8.** 1. O executor deve configurar `TimeZoneId` `[FUSO]` diferente do servidor em `JOB_CONFIG` e gerar um job. 2. O sistema deve criar o job. 3. O executor deve consultar `DataProgramada` e `DataCriacao`. 4. O sistema deve mostrar horários no fuso `[FUSO]`.

**9.** 1. O executor deve rodar 3 ciclos com a branch. 2. O sistema deve completar os ciclos sem erro. 3. O executor deve consultar `JOB_BPM` por esses 3 jobs. 4. O sistema deve retornar 0 linhas.

**10.** 1. O executor deve levar um job a `FalhaParaRepetir` com `Qt_de_Tentativas` = `MaxTentativas` `[AJUSTE COM AUTORIZAÇÃO]`. 2. O sistema deve manter o job nesse estado. 3. O executor deve rodar um ciclo. 4. O sistema deve apresentar o comportamento a registrar como observado (esperado: sem duplicata).

**11.** 1. O executor deve configurar processos InicioTemporal com frequência diária, semanal e mensal e aguardar a hora. 2. O sistema deve gerar 1 job por ocorrência. 3. O executor deve conferir `JOB_BPM`. 4. O sistema deve mostrar 1 job por ocorrência e nenhum duplicado.

**12.** 1. O executor deve configurar 2 alertas no mesmo período para o mesmo fluxo e tarefa e rodar o Scheduler. 2. O sistema deve criar os jobs de alerta. 3. O executor deve aguardar o envio e checar a caixa de destino ou o log do Worker. 4. O sistema deve entregar todos os e-mails (se o e-mail do ambiente falhar, aceitar o log do Worker como evidência, como na etapa 05).

## 10. Rastreabilidade

| Req | Cenários |
|---|---|
| R4.1 | 1 a 6, 10 |
| R4.2 | 7, 12 |
| R4.3 | 8 |
| R4.4 | 9 |
| Regressão | 11, 12 |

## 11. Cobertura de riscos

| Risco | Cenários |
|---|---|
| Duplicação de job (P0) | 1 a 6, 10 |
| Job recorrente bloqueado para sempre (P0) | 7, 12 |
| Diferença Oracle × SQL Server (P1) | cobrir repetindo 1, 3, 7 nos dois bancos (execução) |

**Riscos residuais:** a combinação com 30060 (dump + job ativo no ExecutaSql) e com 30104 (outro `ExisteJobAtivo`) não é exercitada; recomenda-se regressão após a integração.

## 12. Itens bloqueados

| Cenários | Motivo |
|---|---|
| todos | build com a branch do PR 30457 e versão implantada não confirmados |
| 1 a 6, 10 | resultado esperado por job (DUV-01) a confirmar com o dev |
| 8 | valores de `TimeZoneId` do ambiente |
| 12 | e-mail do ambiente falha no Graph (aceito log do Worker) |

Fora de teste: InicioFluxoRevisao, InicioDesassociarAutomatico, NotificaInicioComPublicacao.

## 13. Resumo

12 cenários: 10 positivos, 2 borda. 1 hipótese (#10). Automação: Sim para a consulta de duplicados dos cenários 1 a 6; Parcial para 7 e 11; Não para 10 e 12.
