# Etapa 25 — mapa-testes — Bug #161839 (filho de #161711 Bugs Instaladores)

- **Skill e argumentos:** `/arquitetura-gerar-mapa-testes 161711` com um mapa por bug
- **Data:** 2026-11-09
- **Escreveu no Azure DevOps:** **Não.** Mapa só neste ciclo local (decisão do QA, mantida).
- **Aprovação:** instrução do QA (09/11): testar cada bug na sua branch específica. Aprovação da tabela e da publicação: **pendente**.
- **Fontes:** etapas 05 e 06 a 20, `ReproSteps` do #161839, PRs 30253 (net8, `bfaf8358`) e 30254 (clássico, `4b3535e7`). Card `Análise` ausente (exceção autorizada em 09/11).

## Aprendizados consultados

Consulta realizada — nenhum aprendizado aplicável encontrado.

# Mapa de Testes — #161839 NotifyWF: observação "executor da tarefa anterior" não notifica

**Estratégia:** Legado + Novo (paridade). **Build de teste:** branch `bugfix/bug161839-previous-task-executor-notification` no net8 (PR 30253, base `main` `f708da1e`) e no clássico (PR 30254, base `master` `5a4ab683`).
**Card de Teste:** #165559 | **Card de CR:** não existe

## 1. Visão geral

Valida que, com a observação configurada como "Visualização e Inclusão pelo executor notificando executor da tarefa anterior", o executor da tarefa anterior recebe a notificação, nos dois produtos, sem notificar a pessoa errada. A execução parcial da etapa 05 (Oracle, PR 30253) já cobriu parte dos cenários: ver `05-execucao-testes.md`. **Risco:** médio-alto (notificação para pessoa errada).

## 2. Fontes analisadas

`ReproSteps` do #161839 (primária, com roteiro de validação); PR 30253 (`CaminhoFluxoRepository.GetUsuarioNotificaObservacaoExecutorTarefaAnterior`) e PR 30254 (`SmartShareAgent/NotifyWF.cs`, `NotificaObservacao` case 4).

## 3. Requisitos e regras

| Req | Origem | Regra |
|---|---|---|
| R6.1 | Legado + Novo | O executor da tarefa anterior recebe a notificação em fluxo de 2 a 3 tarefas |
| R6.2 | Legado + Novo | Tarefa anterior de papel ou comitê: notifica quem concluiu |
| R6.3 | Legado + Novo | Tarefa anterior automática: nenhuma notificação nessa opção; fluxo segue |
| R6.4 | Legado + Novo | Dois fluxos com os mesmos números de tarefa: cada um notifica só o seu executor anterior |
| R6.5 | declarado fora de escopo | Em ramos paralelos só o último executor é notificado; registrar o observado |

## 4. Matriz de paridade

| Item | Clássico | net8 | Esperado |
|---|---|---|---|
| Junção do executor anterior | `SmartShareAgent/NotifyWF.cs:NotificaObservacao` case 4 (PR 30254) | `CaminhoFluxoRepository.cs:GetUsuarioNotificaObservacaoExecutorTarefaAnterior` (PR 30253) | Mesmo destinatário nos dois |

Back-to-back: cenário 1 × 2, mesmo fluxo e massa. Evidência lida só nos diffs; o clássico instalado não foi inspecionado.

## 5. Premissas, ambiguidades e ausências

- DUV-01: tarefa anterior automática no clássico não foi conferida linha a linha (lacuna do próprio bug).
- DUV-02: e-mail do ambiente falha no Graph (`MailerException`); o QA aceitou o log do Worker como evidência na etapa 05.
- DUV-03: Agent clássico com o PR 30254 não está disponível.
- Ambiguidade: título sugere "sempre notifica"; o roteiro diz que tarefa anterior automática não notifica (vale o roteiro).

## 6. Pré-requisitos gerais

Build net8 da branch do PR 30253 e Agent clássico da branch do PR 30254; versões implantadas a confirmar. SQL Server e Oracle. Processo com a opção de observação (a etapa 05 usou o processo 522 v1, passo 6, com UPDATE ativo a reverter). E-mail ou log do Worker como evidência.

## 7. Cobertura planejada

Dimensões: positivo, negativo, dados, regressão. Concorrência `N/A — a correção é uma consulta`. Permissão: coberta pelo cenário de papel e comitê (#3).

## 8. Cenários (11)

### === FLUXO PRINCIPAL ===

| # | Cenário | Ação | Resultado Esperado | Tipo | Técnica | Dimensão | Origem | Camada | Componente |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Executor anterior recebe e-mail (net8) | Atividade com a opção, fluxo de 2–3 tarefas, incluir observação | Executor da tarefa anterior recebe o e-mail (antes não recebia) | positivo | partição-equivalência | positivo | história | net8 / Notificação | `CaminhoFluxoRepository.GetUsuarioNotificaObservacaoExecutorTarefaAnterior` |
| 2 | Mesma regra no clássico | Repetir 1 no clássico com o Agent do PR 30254 | Executor anterior recebe o e-mail; mesmo destinatário do cenário 1 | positivo | back-to-back | positivo | análise técnica/PR | Clássico | `NotifyWF.NotificaObservacao` case 4 |

### === FLUXO ALTERNATIVO ===

| # | Cenário | Ação | Resultado Esperado | Tipo | Técnica | Dimensão | Origem | Camada | Componente |
|---|---|---|---|---|---|---|---|---|---|
| 3 | Tarefa anterior de papel ou comitê | Tarefa anterior executada por usuário que pertence a papel ou comitê; incluir observação | Recebe quem concluiu a tarefa (`TAREFA.cd_usuario`) | positivo | partição-equivalência | positivo | história | Notificação | `CaminhoFluxoRepository` |
| 4 | Tarefa anterior automática | Tarefa anterior SQL, WS, e-mail ou condição; incluir observação | Nenhuma notificação nessa opção; observação processada; fluxo segue sem erro | borda | partição-equivalência | dados | história | Notificação | `NotifyWFExecHandler` |

### === DADOS E CASOS DE BORDA ===

| # | Cenário | Ação | Resultado Esperado | Tipo | Técnica | Dimensão | Origem | Camada | Componente |
|---|---|---|---|---|---|---|---|---|---|
| 5 | Isolamento entre fluxos (net8) | Dois fluxos com os mesmos `cd_tarefa` e executores anteriores distintos; observação em cada | Cada fluxo notifica só o seu executor anterior | negativo | tabela-decisão | dados | história | Notificação | `CaminhoFluxoRepository` (`cd_fluxo` nas duas pontas) |
| 6 | Isolamento entre fluxos (clássico) | Idem no clássico | Cada fluxo notifica só o seu executor | negativo | tabela-decisão | dados | análise técnica/PR | Clássico | `NotifyWF.cs` case 4 |
| 7 | Executor anterior com `cd_usuario` nulo ou 0 | Tarefa anterior sem usuário; observação | Sem erro; observação marcada como processada | borda | partição-equivalência | dados | história | Notificação | `NotifyWFExecHandler` |
| 8 | Ramos paralelos | Fluxo com 2 ramos paralelos antes da tarefa; observação | Sem erro; hoje só o último executor da lista é notificado (fora de escopo); registrar o observado | borda | exploratório | dados | análise técnica/PR | Notificação | `NotifyWFExecHandler.cs:982` |

### === ERROS DE INTEGRACAO / API ===

| # | Cenário | Ação | Resultado Esperado | Tipo | Técnica | Dimensão | Origem | Camada | Componente |
|---|---|---|---|---|---|---|---|---|---|
| 9 | Banco SQL Server e Oracle | Rodar 1, 3, 4 e 5 nos dois bancos | Mesmos resultados | positivo | pairwise (banco × cenário) | positivo | Transversal | Banco | `CaminhoFluxoRepository` |

### === REGRESSAO ===

| # | Cenário | Ação | Resultado Esperado | Tipo | Técnica | Dimensão | Origem | Camada | Componente |
|---|---|---|---|---|---|---|---|---|---|
| 10 | Outras opções de observação | Testar participante, solicitante e participantes anteriores | Continuam notificando | positivo | partição-equivalência | regressão | história | Notificação | `TarefaRepository` (613–648) |
| 11 | Clássico: demais opções de observação | Testar as outras opções (case 1 a 3) no clássico | Continuam notificando | positivo | partição-equivalência | regressão | análise técnica/PR | Clássico | `NotifyWF.NotificaObservacao` |

## 9. Passo a passo

**1.** 1. O usuário deve configurar a atividade `[ATIVIDADE]` com a observação "Visualização e Inclusão pelo executor notificando executor da tarefa anterior" e publicar o processo. 2. O sistema deve salvar a configuração. 3. O usuário deve abrir uma solicitação e avançar até a atividade, executando a tarefa anterior com o usuário `[U1]`. 4. O sistema deve abrir a atividade configurada. 5. O executor da atividade deve incluir uma observação. 6. O sistema deve enviar e-mail a `[U1]` (ou registrar o envio no log do Worker, se o e-mail do ambiente falhar).

**2.** 1. O usuário deve repetir o roteiro do cenário 1 no clássico com o Agent do PR 30254 e a mesma massa. 2. O sistema deve notificar o mesmo usuário `[U1]`.

**3.** 1. O usuário deve fazer a tarefa anterior ser atribuída a um papel ou comitê e concluída por `[U2]`. 2. O sistema deve registrar `[U2]` em `TAREFA.cd_usuario`. 3. O executor da atividade deve incluir uma observação. 4. O sistema deve notificar `[U2]`.

**4.** 1. O usuário deve usar tarefa anterior automática (SQL, WS, e-mail ou condição). 2. O sistema deve avançar o fluxo. 3. O executor deve incluir uma observação na atividade seguinte. 4. O sistema deve processar a observação sem enviar notificação nessa opção e sem erro.

**5 e 6.** 1. O usuário deve criar dois fluxos do mesmo processo com executores anteriores `[U1]` e `[U3]`. 2. O sistema deve ter `cd_tarefa` iguais e `cd_fluxo` diferentes. 3. O executor deve incluir uma observação em cada fluxo. 4. O sistema deve notificar `[U1]` no primeiro e `[U3]` no segundo, sem cruzar. (Repetir no clássico para o 6.)

**7.** 1. O usuário deve usar tarefa anterior sem usuário (`cd_usuario` nulo ou 0). 2. O sistema deve concluir a tarefa. 3. O executor deve incluir uma observação. 4. O sistema deve marcar a observação como processada, sem erro.

**8.** 1. O usuário deve montar fluxo com 2 ramos paralelos antes da atividade, com executores `[U4]` e `[U5]`. 2. O sistema deve ligar os dois ramos à atividade. 3. O executor deve incluir uma observação. 4. O sistema deve notificar apenas um dos dois (registrar quem, como observado, sem tratar como bug).

**9.** 1. O executor deve trocar o banco (conforme `QA-KB-20261106-001`, a revalidar) e repetir 1, 3, 4 e 5. 2. O sistema deve produzir os mesmos resultados nos dois bancos.

**10 e 11.** 1. O usuário deve configurar uma observação com cada outra opção `[OPÇÃO]` e incluir uma observação. 2. O sistema deve notificar o destinatário daquela opção, como antes da mudança. (Repetir no clássico para o 11.)

## 10. Rastreabilidade

| Req | Cenários |
|---|---|
| R6.1 | 1, 2, 9 |
| R6.2 | 3 |
| R6.3 | 4, 7 |
| R6.4 | 5, 6 |
| R6.5 | 8 |
| Regressão | 10, 11 |

## 11. Cobertura de riscos

| Risco | Cenários |
|---|---|
| Notificação para pessoa errada (P1) | 1 a 8 |
| Diferença net8 × clássico (P1) | 2, 6, 11 |
| Diferença Oracle × SQL Server (P1) | 9 |

**Riscos residuais:** o clássico instalado não foi inspecionado; só o último executor é notificado em ramos paralelos (fora de escopo).

## 12. Itens bloqueados

| Cenários | Motivo |
|---|---|
| 1 a 11 | builds das duas branches e versões implantadas não confirmados (a etapa 05 rodou parcialmente com a branch do PR 30253 no Oracle) |
| 2, 6, 11 | Agent clássico com o fix do PR 30254 não disponível |
| 1, 3, 4, 5, 7, 8, 10 | e-mail do ambiente falha no Graph; aceitar log do Worker como evidência (decisão do QA na etapa 05) |

Estado da etapa 05 (informativo): 1 e 3 passaram com ressalva; 7 (equivalente a #26) inconclusivo; 4, 5, 8 e 10 não executados.

## 13. Resumo

11 cenários: 6 positivos, 3 negativos (contando 5 e 6), 2 borda. 0 hipóteses. Automação: Parcial para 5 e 6 (SQL do executor anterior); Não para os demais (depende de e-mail e de fluxo montado pela tela).
