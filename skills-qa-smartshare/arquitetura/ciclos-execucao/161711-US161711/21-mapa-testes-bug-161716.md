# Etapa 21 — mapa-testes — Bug #161716 (filho de #161711 Bugs Instaladores)

- **Skill e argumentos:** `/arquitetura-gerar-mapa-testes 161711` com um mapa por bug
- **Data:** 2026-11-09
- **Escreveu no Azure DevOps:** **Não.** Mapa só neste ciclo local, como na etapa 04 (decisão do QA, mantida). Nenhum card "Criar Mapa de Teste" criado e nenhum comentário de hipóteses postado.
- **Aprovação:** instrução do QA (09/11): testar cada bug na sua branch específica, sem conflito entre PRs em execução. Aprovação da tabela e da publicação no Azure DevOps: **pendente**.
- **Fontes:** etapas 06 a 20 deste ciclo, mapa da etapa 04 (reaproveitado e reorganizado por bug), `ReproSteps` do #161716, PR 30104 (`e1396988`). Card `Análise` ausente (exceção autorizada em 09/11).

## Aprendizados consultados

Consulta realizada — nenhum aprendizado aplicável encontrado. `QA-KB-20261106-001` (troca de banco) só serve na execução e precisa ser revalidado no ambiente.

# Mapa de Testes — #161716 ExecutaWS: jobs duplicados com grandes quantidades de fluxos

**Estratégia:** Transversal (concorrência e idempotência de job). **Build de teste:** só a branch `bugfix/bug161716-executaws-duplicate-jobs` (PR 30104), sobre a `main` de `f708da1e`. **Origem dos requisitos:** R1 Transversal.
**Card de Teste:** #165205 | **Card de CR:** #165204 (Done)

## 1. Visão geral

Valida que o Scheduler não cria um segundo job do ExecutaWs para a mesma chave `fluxo/tarefa/passo` enquanto o primeiro está Agendado, Executando ou em FalhaParaRepetir, nem depois que a chave está em `JOB_DUMP`. **Risco:** alto (duplicação de chamadas a WebService externo).

## 2. Fontes analisadas

| Fonte | Papel |
|---|---|
| `ReproSteps` do #161716 | primária (101 fluxos, 100 jobs no 1º ciclo, 134 registros e 33 duplicados como linha de base) |
| PR 30104, `ExecutaWsSchedulerHandler.EnfileirarPendencias`, `JobBpmRepository.ExisteJobAtivo` | técnica |
| Histórico de defeitos | #161712 (mesma família, outro PR), #161717 não se relaciona |

## 3. Requisitos e regras

| Req | Regra |
|---|---|
| R1.1 | Com mais pendências que o limite de seleção, existe um job por chave enquanto o anterior está ativo |
| R1.2 | Ao fim de 101 tarefas: 101 sucessos em `JOB_DUMP`, 0 chaves repetidas |
| R1.3 | O 1º ciclo continua criando 100 jobs |
| R1.4 | Chave em `JOB_DUMP` não é reenfileirada; a chave de outra tarefa não é bloqueada |
| R1.5 (PR) | Erro em uma pendência é logado e o ciclo segue (extra do PR, não está no bug) |

## 4. Matriz de paridade

Não aplicável (sem requisito Legado).

## 5. Premissas, ambiguidades e ausências

- Premissa (QA): o teste roda só com a branch do PR 30104; efeitos de integração com 30060 e 30457 **não** são cobertos aqui.
- DUV-01: limite de seleção do Scheduler e intervalo do job 28 vêm do bug ("100" e "job 28"); onde configurar não consta.
- DUV-02: sem mecanismo descrito para forçar falha de enfileiramento de uma pendência (cenário 7).
- DUV-03: assinatura de `ExisteJobAtivo` do PR 29631 não lida; irrelevante para a branch isolada.

## 6. Pré-requisitos gerais

- Branch do PR 30104 instalada em Scheduler e Worker BPM; **versão implantada a confirmar**.
- SQL Server e Oracle; acesso a `JOB_BPM`, `JOB_DUMP`, `JOB_CONFIG` e logs do Scheduler e do Worker.
- Mock de endpoint HTTP 200 com JSON válido; massa de 101 fluxos com tarefa WebService elegível.
- Escritas diretas em `JOB_*` exigem autorização do dono do banco e limpeza ao final.

## 7. Cobertura planejada

Dimensões: positivo, negativo, dados, concorrência (hipótese), regressão. Permissão: `N/A — Scheduler roda como serviço; a correção não altera perfil, token ou escopo`.

## 8. Cenários (9)

### === FLUXO PRINCIPAL ===

| # | Cenário | Ação | Resultado Esperado | Tipo | Técnica | Dimensão | Origem | Camada | Componente |
|---|---|---|---|---|---|---|---|---|---|
| 1 | 101 fluxos WS sem duplicar job | Criar 101 fluxos com tarefa WebService elegível, job 28 em intervalo curto, mock HTTP 200; subir Scheduler e Worker; aguardar as 101 tarefas | 1º ciclo cria 100 jobs; no fim `JOB_DUMP` tem 101 sucessos para 101 fluxos e 0 chaves repetidas (defeito: 134 e 33 duplicados) | positivo | valor-limite | positivo | história | Scheduler/Worker | `ExecutaWsSchedulerHandler.EnfileirarPendencias` |
| 2 | Pendência relida é ignorada com log | Manter 1 job ativo para a chave e aguardar novo ciclo | Nenhum 2º `JOB_BPM` para a chave; log `AlreadyActive` | positivo | partição-equivalência | positivo | análise técnica/PR | Scheduler | `JobBpmRepository.ExisteJobAtivo` |

### === FLUXO ALTERNATIVO ===

| # | Cenário | Ação | Resultado Esperado | Tipo | Técnica | Dimensão | Origem | Camada | Componente |
|---|---|---|---|---|---|---|---|---|---|
| 3 | Limite 99/100/101 pendências | Rodar com 99, 100 e 101 tarefas | 99 e 100: um job por tarefa no 1º ciclo; 101: 100 no 1º e 1 nos seguintes, sem duplicar | borda | valor-limite | dados | história | Scheduler | `ExecutaWsSchedulerHandler` |

### === DADOS E CASOS DE BORDA ===

| # | Cenário | Ação | Resultado Esperado | Tipo | Técnica | Dimensão | Origem | Camada | Componente |
|---|---|---|---|---|---|---|---|---|---|
| 4 | Chave na dump bloqueia só a mesma chave | Chave `fluxo/tarefa/passo` já em `JOB_DUMP` e uma pendência nova de outra tarefa | A repetida é ignorada com log; a nova recebe job | negativo | partição-equivalência | negativo | história | Scheduler | `JobDumpService.ExisteChaveUnica` |

### === CONCORRENCIA ===

| # | Cenário | Ação | Resultado Esperado | Tipo | Técnica | Dimensão | Origem | Camada | Componente |
|---|---|---|---|---|---|---|---|---|---|
| 5 | HIPOTESE: duas instâncias do Scheduler | 2 Schedulers no mesmo banco com 101 fluxos WS | Esperado: sem duplicata; se houver, registrar (checagem e insert não são atômicos; requisito não declarado) | negativo | exploratório | concorrência | hipótese | Scheduler | `ExisteJobAtivo` + `AddSql` |

### === ERROS DE INTEGRACAO / API ===

| # | Cenário | Ação | Resultado Esperado | Tipo | Técnica | Dimensão | Origem | Camada | Componente |
|---|---|---|---|---|---|---|---|---|---|
| 6 | Endpoint WS fora do ar | Mock com 500 ou timeout, 101 fluxos | Jobs em `FalhaParaRepetir` não são recriados; ao esgotar, envenena | negativo | transição-de-estado | negativo | história | Worker/Scheduler | `ExecutaWsHandler`, `ExisteJobAtivo` |
| 7 | Falha ao enfileirar 1 pendência | Provocar erro de banco numa pendência do lote (mecanismo a definir pelo dev) | Erro logado; demais pendências enfileiradas | negativo | partição-equivalência | negativo | análise técnica/PR | Scheduler | `try/catch` de `EnfileirarPendencias` |
| 8 | Banco SQL Server e Oracle | Rodar 1, 2 e 4 nos dois bancos | Mesmos resultados; `ExisteJobAtivo` correto | positivo | pairwise (banco × cenário) | positivo | Transversal | Banco | `JobBpmRepository.ExisteJobAtivo` |

### === REGRESSAO ===

| # | Cenário | Ação | Resultado Esperado | Tipo | Técnica | Dimensão | Origem | Camada | Componente |
|---|---|---|---|---|---|---|---|---|---|
| 9 | 1 fluxo WS segue funcionando | Criar 1 fluxo com tarefa WebService e rodar um ciclo | 1 job criado, executado com sucesso, 1 registro em `JOB_DUMP`, fluxo avança | positivo | partição-equivalência | regressão | análise técnica/PR | Scheduler/Worker | `ExecutaWsSchedulerHandler` |

## 9. Passo a passo

**1.** 1. O executor deve criar 101 fluxos com tarefa WebService elegível e configurar o job 28 em intervalo curto `[INTERVALO]`. 2. O sistema deve listar 101 pendências para o ExecutaWs. 3. O executor deve subir o mock HTTP 200 e iniciar Scheduler e Worker. 4. O sistema deve criar exatamente 100 linhas em `JOB_BPM` no 1º ciclo. 5. O executor deve aguardar as 101 tarefas e rodar `SELECT CHAVE_UNICA, COUNT(*) FROM JOB_DUMP GROUP BY CHAVE_UNICA HAVING COUNT(*) > 1`. 6. O sistema deve retornar 0 linhas e 101 sucessos distintos em `JOB_DUMP`.

**2.** 1. O executor deve manter 1 job da chave `[CHAVE]` Agendado ou Executando. 2. O sistema deve manter 1 linha ativa em `JOB_BPM` para a chave. 3. O executor deve aguardar o próximo ciclo e ler o log do Scheduler. 4. O sistema deve registrar `AlreadyActive` e não inserir outra linha para a chave.

**3.** 1. O executor deve repetir o cenário 1 com 99 tarefas. 2. O sistema deve criar 99 jobs no 1º ciclo e 0 duplicados no fim. 3. O executor deve repetir com 100 e com 101. 4. O sistema deve criar 100 jobs no 1º ciclo e, com 101, o restante nos ciclos seguintes sem duplicar.

**4.** 1. O executor deve inserir (com autorização) a chave `[CHAVE_A]` em `JOB_DUMP` e gerar uma pendência da mesma chave e outra da tarefa `[CHAVE_B]`. 2. O sistema deve listar as duas pendências. 3. O executor deve aguardar um ciclo. 4. O sistema deve ignorar `[CHAVE_A]` com log e criar job para `[CHAVE_B]`. 5. O executor deve remover a linha inserida. 6. O sistema deve voltar ao estado inicial (restauração).

**5.** 1. O executor deve subir 2 Schedulers no mesmo banco com 101 fluxos WS. 2. O sistema deve processar pendências nas duas instâncias. 3. O executor deve consultar duplicados em `JOB_BPM` e `JOB_DUMP` pela chave. 4. O sistema deve apresentar 0 duplicados; qualquer duplicado é registrado como observação, não como bug, até confirmação de requisito.

**6.** 1. O executor deve configurar o mock para retornar 500 (ou timeout) e rodar 101 fluxos. 2. O sistema deve registrar falha e colocar os jobs em `FalhaParaRepetir`. 3. O executor deve aguardar novos ciclos do Scheduler. 4. O sistema deve manter 1 job por chave (sem criar novos) e, esgotadas as tentativas, marcar `Envenenado` com registro em `JOB_DUMP`.

**7.** 1. O executor deve provocar erro de banco ao enfileirar 1 pendência do lote `[MECANISMO A DEFINIR PELO DEV]`. 2. O sistema deve logar o erro dessa pendência. 3. O executor deve consultar `JOB_BPM` após o ciclo. 4. O sistema deve ter enfileirado as demais pendências do lote.

**8.** 1. O executor deve trocar o banco (conforme `QA-KB-20261106-001`, a revalidar) e repetir 1, 2 e 4. 2. O sistema deve produzir os mesmos resultados no SQL Server e no Oracle.

**9.** 1. O executor deve criar 1 fluxo com tarefa WebService e subir o mock HTTP 200. 2. O sistema deve criar 1 job no ciclo. 3. O executor deve aguardar a conclusão. 4. O sistema deve ter 1 registro em `JOB_DUMP` com sucesso e o fluxo avançado.

## 10. Rastreabilidade

| Req | Cenários |
|---|---|
| R1.1, R1.3 | 1, 2, 3 |
| R1.2 | 1, 6 |
| R1.4 | 4 |
| R1.5 | 7 |
| Transversal | 5, 8, 9 |

## 11. Cobertura de riscos

| Risco | Cenários |
|---|---|
| Duplicação de job (P0) | 1, 2, 3, 5 |
| Reagendamento legítimo bloqueado pela dump (P0) | 4, 6 |
| Diferença Oracle × SQL Server (P1) | 8 |

**Riscos residuais:** efeitos da combinação com os PRs 30457 e 30060 (dois `ExisteJobAtivo` diferentes) não são cobertos por esta execução isolada; recomenda-se regressão após a integração.

## 12. Itens bloqueados

| Cenários | Motivo |
|---|---|
| todos | build com a branch do PR 30104 e versão implantada não confirmados |
| 1, 3, 6 | mock HTTP e massa de 101 fluxos |
| 7 | mecanismo para forçar falha de enfileiramento |

## 13. Resumo

9 cenários: 5 positivos, 3 negativos, 1 borda. 1 hipótese (#5). Automação: Sim para 1, 2, 3, 4 (SQL de verificação em `JOB_BPM` e `JOB_DUMP`); Não para 5 e 7.
