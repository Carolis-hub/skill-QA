# Etapa 29 — execucao-testes — Bug #161714 (log do AvancoTemporal) — ORACLE

- **Skill e argumentos:** `/arquitetura-executar-teste` — "execução do gate ORACLE, o necessário antes da execução, eu autorizo fazer" (09/11/2026)
- **Mapa:** [24-mapa-testes-bug-161714.md](24-mapa-testes-bug-161714.md) (local, não publicado)
- **Build:** branch do PR 30486, commit `3ac5ea98`, worktree `Temp/wt30486` (só o **Worker BPM**; jobs já estavam em `JOB_BPM`)
- **Gate:** [00-validacao-ambiente-oracle.md](00-validacao-ambiente-oracle.md), LIBERADO COM RESSALVA
- **Status:** **PARCIAL** — cenários 4 e 5 executados; 1, 2 e 3 não executados por decisão do QA (hipótese)

## Preparação (com autorização)
| Ação | Escopo | Rollback |
|---|---|---|
| `DELETE FROM JOB_BPM WHERE JOB IN (9, 18, 32)` | 4 linhas residuais do Scheduler do #161712 (a autorização cobria 10; apaguei só as de risco) | o Scheduler recria no próximo ciclo |
| `appsettings.json` do Worker (bin do wt30486): `WorkflowWebServiceUrl` para `localhost:59999` | backup `appsettings.json.orig-8080` | restaurar o `.orig-8080` |
| Worker do PR 30486 subido | logs em `Log/JOB_BPM/<job>/` | encerrar o processo |

## Resultado por cenário
| # | Cenário | Resultado | Evidência |
|---|---|---|---|
| 1 | Log do AvancoTemporal traz o erro real | **NÃO EXECUTADO** | decisão do QA (09/11): hipóteses não são executadas; o mecanismo de exceção em `AvancarFluxo` não está definido pelo dev |
| 2 | Duas causas de erro diferentes | **NÃO EXECUTADO** | idem |
| 3 | Efeito sobre o status do job | **NÃO EXECUTADO** | idem (depende do cenário 1) |
| 4 | AvancoTemporal sem erro | **PASSOU** | Fluxo 2385 (processo 442 v4): job 37788 (`bpm:job:1:cd_fluxo=2385:cd_tarefa=2:AvancoTemporalStep:VerificarAvancoPrazoEstourado:`) iniciado e "executado com sucesso" no log; `JOB_DUMP` status 3, `Qt_de_Tentativas` 0; `TAREFA` 2 (passo 3) encerrada 15:46:06 e tarefa 3 (passo 9) criada; 0 linhas `ERROR` no log do AvancoTemporal |
| 5 | Outros handlers continuam logando | **PASSOU** | ExecutaSql: o Worker registrou `ExecutaSQL` com a exceção completa ("Erro ao executar o seguinte comando ... SQL Server inexistente ou acesso negado", fluxo 2407). ExecutaWs: "Erro ao executar a seguinte Consulta: Teste ... " (mock desligado), job 28 em `FalhaParaRepetir` com `Qt` 2. Ambos com mensagem e stack |

## Observações
- **Porta SOAP fechada não afeta o AvancoTemporal:** o fluxo 2385 avançou com `WorkflowWebServiceUrl` apontando para `59999`; o AvancoTemporal usa o motor direto, não o SOAP.
- Não houve exceção real em `AvancarFluxo` nesta rodada; o que o PR 30486 muda no log (cenário 1) **não foi verificado**.
