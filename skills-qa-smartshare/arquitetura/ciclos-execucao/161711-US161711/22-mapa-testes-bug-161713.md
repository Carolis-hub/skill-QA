# Etapa 22 — mapa-testes — Bug #161713 (filho de #161711 Bugs Instaladores)

- **Skill e argumentos:** `/arquitetura-gerar-mapa-testes 161711` com um mapa por bug
- **Data:** 2026-11-09
- **Escreveu no Azure DevOps:** **Não.** Mapa só neste ciclo local (decisão do QA, mantida).
- **Aprovação:** instrução do QA (09/11): testar cada bug na sua branch específica. Aprovação da tabela e da publicação: **pendente**.
- **Fontes:** etapas 06 a 20, mapa da etapa 04 (reaproveitado e reorganizado), `Description` e `ReproSteps` do #161713, PR 30060 (`d4a98152`). Card `Análise` ausente (exceção autorizada em 09/11).

## Aprendizados consultados

Consulta realizada — nenhum aprendizado aplicável encontrado.

# Mapa de Testes — #161713 BPM: ExecutaSql não envenena o job

**Estratégia:** Transversal (resiliência e envenenamento de job). **Build de teste:** só a branch `bugfix/BUG161713-bpm-sql-job-not-poisoning` (PR 30060), sobre a `main` de `f708da1e`. **Origem:** R2 e R3 Transversal.
**Card de Teste:** #165195 | **Card de CR:** #165194 (Done)

## 1. Visão geral

Valida o ciclo retry → tratamento definitivo → envenenamento do job `ExecutaSql` e o bloqueio de reenfileiramento de pendência já envenenada. **Risco:** alto (falha real mascarada).

## 2. Fontes analisadas

`Description` e `ReproSteps` do #161713 (primárias); PR 30060: `AgentBpmService.ExecutarExecutaSql`, `DeveRelancarParaReagendar`, `TratarFalhaDefinitivaExecutaSql`, `AvancaPassoEscapeExecutaSql`, `ExecutaSqlSchedulerHandler` (técnica). Resultado de testes citado pelo dev (2048 passando) é declarado, não verificado.

## 3. Requisitos e regras

| Req | Regra |
|---|---|
| R2.1 | Falha de SQL com tentativa restante: retry, sem variável de erro, escape ou notificação |
| R2.2 | Tentativas esgotadas: grava variável de erro, loga, tenta o escape e notifica ocorrência se configurado |
| R2.3 | Escape ausente ou que falha: job envenenado (`Envenenado` e `JOB_DUMP`), nunca sucesso |
| R3 | Pendência com chave em `JOB_DUMP` não é reenfileirada |

## 4. Matriz de paridade

Não aplicável (o bug cita origem no clássico, mas não pede paridade; sem requisito Legado de teste).

## 5. Premissas, ambiguidades e ausências

- Premissa (QA): teste só na branch do PR 30060; a combinação com o PR 30457 (mesmo handler) não é coberta.
- DUV-01: valores de `MaxTentativas` e `PoliticaBackoff` no `JOB_CONFIG` do ExecutaSql desconhecidos.
- DUV-02: sem mecanismo descrito para forçar falha de SQL (sugestão a confirmar com o dev: SQL inválido na atividade) nem falha de `AvancarFluxo` do escape.
- Ambiguidade: "envenenar" é job em `JOB_DUMP` com status `Envenenado` (interpretação adotada: só quando o escape não avança).

## 6. Pré-requisitos gerais

Branch do PR 30060 em Scheduler e Worker; versão implantada a confirmar. SQL Server e Oracle. Acesso a `JOB_BPM`, `JOB_DUMP`, `JOB_CONFIG`, variáveis de erro do fluxo e logs. Processos com e sem passo de escape. Escritas em `JOB_*` exigem autorização.

## 7. Cobertura planejada

Dimensões: positivo, negativo, dados, regressão. Concorrência: `N/A — o bug não trata de execução simultânea`. Permissão: `N/A — job roda como serviço`.

## 8. Cenários (10)

### === FLUXO PRINCIPAL ===

| # | Cenário | Ação | Resultado Esperado | Tipo | Técnica | Dimensão | Origem | Camada | Componente |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Retry quando ainda há tentativa | Forçar falha de SQL com `QtdeTentativas` < `MaxTentativas` | Job reagendado (`FalhaParaRepetir`); variável de erro não gravada; sem escape; sem ocorrência | positivo | transição-de-estado | positivo | história | Worker BPM | `AgentBpmService.DeveRelancarParaReagendar` |
| 2 | Esgotada, escape avança | Falha com tentativas esgotadas e escape configurado | Variável de erro gravada, erro logado, fluxo avança pelo escape, ocorrência notificada se `NotificaOcorrencia`; job não envenenado | positivo | tabela-decisão | positivo | história | Worker BPM | `TratarFalhaDefinitivaExecutaSql` |
| 3 | Esgotada, sem passo de escape | Idem, sem passo de escape | Job `Envenenado` com registro em `JOB_DUMP`; erro logado; não termina como sucesso | negativo | tabela-decisão | negativo | história | Worker BPM | `AvancaPassoEscapeExecutaSql` retorna `false` |
| 4 | Esgotada, escape falha ao avançar | Idem, forçando falha de `AvancarFluxo` | Job `Envenenado` e `JOB_DUMP` preenchido; log "Erro ao avançar para o passo de escape" | negativo | tabela-decisão | negativo | análise técnica/PR | Worker BPM | `AvancaPassoEscapeExecutaSql` |
| 5 | Pendência envenenada não volta à fila | Chave do ExecutaSql já em `JOB_DUMP`; aguardar ciclos | Nenhum job novo em `JOB_BPM`; log "já foi processado" | negativo | partição-equivalência | negativo | história | Scheduler | `ExecutaSqlSchedulerHandler` |

### === FLUXO ALTERNATIVO ===

| # | Cenário | Ação | Resultado Esperado | Tipo | Técnica | Dimensão | Origem | Camada | Componente |
|---|---|---|---|---|---|---|---|---|---|
| 6 | Duas políticas de backoff | Repetir o cenário 1 com cada `PoliticaBackoff` configurada | Reagendamento com a data da política | positivo | pairwise (política × banco) | positivo | análise técnica/PR | Worker BPM | `JobResiliencePolicy.CalcularFalha` |

### === VALIDACOES DE CAMPOS ===

| # | Cenário | Ação | Resultado Esperado | Tipo | Técnica | Dimensão | Origem | Camada | Componente |
|---|---|---|---|---|---|---|---|---|---|
| 7 | Limite de tentativas | Com `MaxTentativas = N`, falhar com `QtdeTentativas` = N−1 e N | N−1: reagenda. N: tratamento definitivo (escape ou envenena) | borda | valor-limite | negativo | história | Worker BPM | `ExecutarExecutaSql` |

### === DADOS E CASOS DE BORDA ===

| # | Cenário | Ação | Resultado Esperado | Tipo | Técnica | Dimensão | Origem | Camada | Componente |
|---|---|---|---|---|---|---|---|---|---|
| 8 | Banco SQL Server e Oracle | Rodar 1, 3 e 5 nos dois bancos | Mesmos resultados | positivo | pairwise (banco × cenário) | positivo | Transversal | Banco | `JobDumpService`, `ExecutaSqlSchedulerHandler` |

### === REGRESSAO ===

| # | Cenário | Ação | Resultado Esperado | Tipo | Técnica | Dimensão | Origem | Camada | Componente |
|---|---|---|---|---|---|---|---|---|---|
| 9 | ExecutaSql sem erro | Executar SQL válido | Sucesso na 1ª tentativa; sem retry, escape ou ocorrência | positivo | partição-equivalência | regressão | análise técnica/PR | Worker BPM | `ExecutarExecutaSql` |

### === CASOS DE BORDA / HIPOTESES ===

| # | Cenário | Ação | Resultado Esperado | Tipo | Técnica | Dimensão | Origem | Camada | Componente |
|---|---|---|---|---|---|---|---|---|---|
| 10 | HIPOTESE: erro não reagendável com tentativas sobrando | Erro que `ClassificarErro` marca como não reagendável, com tentativas sobrando | Esperado: tratamento definitivo sem retry; `CalcularFalha` não lida | borda | tabela-decisão | negativo | hipótese | Worker BPM | `WorkerHelper.ClassificarErro` |

## 9. Passo a passo

**1.** 1. O executor deve configurar uma atividade ExecutaSql com SQL inválido `[SQL_INVALIDO]` e confirmar `MaxTentativas` > 1 em `JOB_CONFIG`. 2. O sistema deve listar a pendência. 3. O executor deve iniciar o fluxo e aguardar a 1ª execução. 4. O sistema deve registrar o erro e mudar o job para `FalhaParaRepetir` com `QtdeTentativas` = 1. 5. O executor deve consultar as variáveis de erro do fluxo e o log. 6. O sistema deve mostrar variável de erro não gravada, fluxo parado no passo e nenhuma ocorrência notificada.

**2.** 1. O executor deve usar processo com passo de escape e fazer `QtdeTentativas` = `MaxTentativas` − 1 `[AJUSTE EM JOB_BPM COM AUTORIZAÇÃO]`. 2. O sistema deve manter o job pronto para a última tentativa. 3. O executor deve aguardar a execução com SQL ainda inválido. 4. O sistema deve gravar a variável de erro, logar, avançar o fluxo pelo escape e notificar ocorrência se `NotificaOcorrencia`. 5. O executor deve consultar o status do job. 6. O sistema deve mostrar o job concluído, sem `Envenenado`.

**3.** 1. O executor deve usar processo sem passo de escape e levar o job à última tentativa. 2. O sistema deve manter o job apto. 3. O executor deve aguardar a execução com SQL inválido. 4. O sistema deve registrar o erro e relançar a exceção. 5. O executor deve consultar `JOB_BPM` e `JOB_DUMP`. 6. O sistema deve mostrar `JobStatusId = Envenenado` e linha em `JOB_DUMP`.

**4.** 1. O executor deve usar processo com escape e provocar falha de `AvancarFluxo` no escape `[MECANISMO A DEFINIR]`. 2. O sistema deve levar o job à última tentativa. 3. O executor deve aguardar a execução. 4. O sistema deve logar "Erro ao avançar para o passo de escape". 5. O executor deve consultar `JOB_DUMP`. 6. O sistema deve mostrar o job `Envenenado` com dump.

**5.** 1. O executor deve inserir (com autorização) a chave do ExecutaSql em `JOB_DUMP` e manter a pendência elegível. 2. O sistema deve manter a pendência na consulta do Scheduler. 3. O executor deve aguardar 3 ciclos. 4. O sistema deve registrar "já foi processado" e não criar linha em `JOB_BPM`. 5. O executor deve remover a linha inserida. 6. O sistema deve voltar ao estado inicial.

**6.** 1. O executor deve configurar `PoliticaBackoff` `[A]` e executar o cenário 1. 2. O sistema deve reagendar com a data de `[A]`. 3. O executor deve repetir com `[B]`. 4. O sistema deve reagendar com a data de `[B]`.

**7.** 1. O executor deve fixar `MaxTentativas = N` e falhar com `QtdeTentativas` = N−1. 2. O sistema deve reagendar. 3. O executor deve falhar com `QtdeTentativas` = N. 4. O sistema deve executar o tratamento definitivo (escape ou envenenamento).

**8.** 1. O executor deve trocar o banco (conforme `QA-KB-20261106-001`, a revalidar) e repetir 1, 3 e 5. 2. O sistema deve produzir os mesmos resultados nos dois bancos.

**9.** 1. O executor deve configurar ExecutaSql com SQL válido e iniciar o fluxo. 2. O sistema deve executar na 1ª tentativa. 3. O executor deve consultar o job e as variáveis de erro. 4. O sistema deve mostrar sucesso, sem retry, escape ou ocorrência.

**10.** 1. O executor deve provocar um erro classificado como não reagendável, com tentativas sobrando `[MECANISMO A DEFINIR]`. 2. O sistema deve registrar o erro. 3. O executor deve consultar o job. 4. O sistema deve ter ido ao tratamento definitivo sem retry (comportamento a registrar como observado).

## 10. Rastreabilidade

| Req | Cenários |
|---|---|
| R2.1 | 1, 6, 7, 10 |
| R2.2 | 2, 7 |
| R2.3 | 3, 4 |
| R3 | 5 |
| Transversal | 8, 9 |

## 11. Cobertura de riscos

| Risco | Cenários |
|---|---|
| Falha mascarada, job nunca envenena (P0) | 1 a 4, 7 |
| Retry com efeitos de negócio duplicados (P1) | 1, 6 |
| Diferença Oracle × SQL Server (P1) | 8 |

**Riscos residuais:** conflito com o PR 30457 no mesmo handler não é exercitado; #10 sem evidência de regra.

## 12. Itens bloqueados

| Cenários | Motivo |
|---|---|
| todos | build com a branch do PR 30060 e versão implantada não confirmados |
| 1, 2, 3, 4, 6, 7, 10 | valores de `MaxTentativas` e `PoliticaBackoff`, e mecanismo para forçar falha de SQL e de escape |

## 13. Resumo

10 cenários: 5 positivos, 4 negativos, 1 borda (contando o #10 como borda). 1 hipótese (#10). Automação: Sim para 5 e 7 (SQL de verificação); Parcial para 1 a 4; Não para 10.
