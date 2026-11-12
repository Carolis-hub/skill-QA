# Etapa 24 — mapa-testes — Bug #161714 (filho de #161711 Bugs Instaladores)

- **Skill e argumentos:** `/arquitetura-gerar-mapa-testes 161711` com um mapa por bug
- **Data:** 2026-11-09
- **Escreveu no Azure DevOps:** **Não.** Mapa só neste ciclo local (decisão do QA, mantida).
- **Aprovação:** instrução do QA (09/11): testar cada bug na sua branch específica. Aprovação da tabela e da publicação: **pendente**.
- **Fontes:** etapas 06 a 20, `ReproSteps` do #161714, PR 30486 (`3ac5ea98`). Card `Análise` ausente (exceção autorizada em 09/11).

## Aprendizados consultados

Consulta realizada — nenhum aprendizado aplicável encontrado.

# Mapa de Testes — #161714 BPM: log de erro do AvancoTemporal mascara o erro

**Estratégia:** Transversal (observabilidade). **Build de teste:** só a branch `bugfix/US161714-correcao-log-erro-descricao` (PR 30486), sobre a `main` de `f708da1e`.
**Card de Teste:** #166111 | **Card de CR:** não existe

## 1. Visão geral

Valida que, quando o AvancoTemporal falha, o erro real aparece no log. O bug não define a mensagem esperada; o PR muda uma linha (`jr.Exception = ex;` em `AvancoTemporalExecHandler.ProcessarFluxo`). **Risco:** médio-baixo; o risco principal é efeito colateral no tratamento da exceção pelo `BpmExecJob`.

## 2. Fontes analisadas

`ReproSteps` do #161714 (primária, só a descrição e a branch); PR 30486 (técnica). Sem critérios de aceite escritos.

## 3. Requisitos e regras

| Req | Regra |
|---|---|
| R5 | Falha no AvancoTemporal registra o erro real no log (padrão dos demais handlers do worker BPM) |

## 4. Matriz de paridade

Não aplicável.

## 5. Premissas, ambiguidades e ausências

- DUV-01: mensagem de log esperada não definida; os cenários verificam só que a exceção original (tipo e mensagem) aparece.
- DUV-02: sem mecanismo para forçar erro no AvancoTemporal.
- DUV-03: onde ler o log (arquivo, tabela ou console do Worker) não descrito.
- Lacuna: o ramo do `BpmExecJob` que consome `JobResult.Exception` não foi relido; o efeito no status do job (retry, envenenamento) vira cenário exploratório (#3).

## 6. Pré-requisitos gerais

Branch do PR 30486 em Scheduler e Worker; versão implantada a confirmar. Acesso ao log do Worker e a `JOB_BPM`. Um fluxo com passo temporal elegível ao AvancoTemporal.

## 7. Cobertura planejada

Dimensões: positivo, negativo, regressão. Concorrência `N/A — correção de log`. Permissão `N/A — job de serviço`. Banco: `N/A — a mudança não altera SQL`.

## 8. Cenários (5)

### === FLUXO PRINCIPAL ===

| # | Cenário | Ação | Resultado Esperado | Tipo | Técnica | Dimensão | Origem | Camada | Componente |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Log do AvancoTemporal traz o erro real | Forçar exceção em `AvancarFluxo` num job AvancoTemporal e ler o log do Worker | Log registra a exceção original (tipo, mensagem, stack) e não só mensagem genérica | positivo | exploratório | positivo | história | Worker BPM | `AvancoTemporalExecHandler.ProcessarFluxo` (`jr.Exception`) |

### === DADOS E CASOS DE BORDA ===

| # | Cenário | Ação | Resultado Esperado | Tipo | Técnica | Dimensão | Origem | Camada | Componente |
|---|---|---|---|---|---|---|---|---|---|
| 2 | Duas causas de erro diferentes | Forçar dois tipos de erro distintos | O log distingue as duas causas pelo texto da exceção | negativo | partição-equivalência | dados | análise técnica/PR | Worker BPM | `ProcessarFluxo` |
| 3 | Efeito sobre o status do job | Repetir o cenário 1 e observar `JOB_BPM` e `JOB_DUMP` | Registrar o observado: retry, `Envenenado` ou sucesso. Sem regra escrita para comparar | borda | exploratório | negativo | análise técnica/PR | Worker BPM | `BpmExecJob` (consumo de `jr.Exception`) |

### === REGRESSAO ===

| # | Cenário | Ação | Resultado Esperado | Tipo | Técnica | Dimensão | Origem | Camada | Componente |
|---|---|---|---|---|---|---|---|---|---|
| 4 | AvancoTemporal sem erro | Fluxo com passo temporal elegível, sem falha | Fluxo avança; nenhuma exceção no log | positivo | partição-equivalência | regressão | análise técnica/PR | Worker BPM | `ProcessarFluxo` |
| 5 | Outros handlers continuam logando | Forçar falha no ExecutaSql ou no ExecutaWs | Log registra a exceção como antes | positivo | partição-equivalência | regressão | análise técnica/PR | Worker BPM | handlers do worker BPM |

## 9. Passo a passo

**1.** 1. O executor deve preparar um fluxo com passo temporal elegível e provocar exceção em `AvancarFluxo` `[MECANISMO A DEFINIR PELO DEV]`. 2. O sistema deve selecionar o fluxo no AvancoTemporal. 3. O executor deve aguardar a execução e abrir `[LOCAL DO LOG]`. 4. O sistema deve registrar a exceção original com tipo, mensagem e stack trace.

**2.** 1. O executor deve repetir o cenário 1 com a causa `[A]` e depois com a causa `[B]`. 2. O sistema deve registrar duas entradas de log. 3. O executor deve comparar o texto. 4. O sistema deve mostrar mensagens que identificam cada causa.

**3.** 1. O executor deve repetir o cenário 1 e anotar `JobStatusId` em `JOB_BPM` após cada execução. 2. O sistema deve registrar o status resultante (retry, `Envenenado` ou sucesso). 3. O executor deve consultar `JOB_DUMP`. 4. O sistema deve apresentar o estado a registrar como observado.

**4.** 1. O executor deve preparar um fluxo elegível sem falha e aguardar o ciclo. 2. O sistema deve avançar o fluxo. 3. O executor deve ler o log. 4. O sistema deve mostrar ausência de exceção.

**5.** 1. O executor deve forçar uma falha de SQL no ExecutaSql (ou erro no ExecutaWs) `[MECANISMO]`. 2. O sistema deve registrar o erro. 3. O executor deve ler o log. 4. O sistema deve mostrar a exceção como antes da mudança.

## 10. Rastreabilidade

| Req | Cenários |
|---|---|
| R5 | 1, 2, 3 |
| Regressão | 4, 5 |

## 11. Cobertura de riscos

| Risco | Cenários |
|---|---|
| Erro continua mascarado (P1) | 1, 2 |
| Efeito colateral no status do job (P1) | 3 |
| Regressão em outros handlers (P2) | 4, 5 |

**Riscos residuais:** sem exemplo antes/depois do log, "claro" é julgamento do QA; a combinação com o PR 30457 (AvancoTemporal no Scheduler) não é exercitada.

## 12. Itens bloqueados

| Cenários | Motivo |
|---|---|
| todos | build com a branch do PR 30486 e versão implantada não confirmados |
| 1, 2, 3, 5 | mecanismo para forçar erro no AvancoTemporal e exemplo do log esperado |

## 13. Resumo

5 cenários: 3 positivos, 1 negativo, 1 borda. 0 hipóteses. Automação: Não (depende de leitura de log e de falha provocada); Parcial para 4.
