# Etapa 04 — mapa-testes — #161711 Bugs Instaladores

- **Skill e argumentos:** `/arquitetura-gerar-mapa-testes 161711`
- **Data:** 2026-11-06
- **Escreveu no Azure DevOps:** **Não.** Por decisão do QA (guilherme.borges), o mapa fica só neste ciclo local. Nenhum card "Criar Mapa de Teste" foi criado, nenhum comentário de hipóteses foi postado na história e o `LOG-ACOES.md` não foi alterado (ele registra só escritas no Azure DevOps).
- **Aprovação:** QA aprovou a tabela de 41 cenários com a instrução de usá-la localmente.
- **Fontes lidas:** etapas 01, 02 e 03 deste ciclo; bugs #161712, #161713, #161714, #161716, #161717, #161839; diffs dos PRs 30060, 30104, 30457, 30486, 30253 e 30254.
- **Exceção de gate:** sem card `Análise` (fonte = bugs + diffs, autorizado pelo QA na etapa 03).

## Aprendizados consultados

Consulta realizada — nenhum aprendizado aplicável encontrado. `QA-KB-20261106-001` (troca de banco local) será útil só na execução, e precisa ser revalidado no ambiente.

# Mapa de Testes — Correção dos bugs de instaladores (Scheduler, Worker BPM e NotifyWF)

**Estratégia:** Transversal (concorrência e resiliência de jobs) para #161716, #161713, #161712 e #161714. Legado + Novo para #161839 (o clássico tem o mesmo defeito; PR 30254).
**Origem dos requisitos:** ver tabela 3.

## 1. Visão geral

Valida a correção de 5 bugs com PR (#161716, #161713, #161712, #161714, #161839). Cards de Teste filhos: #165205 (#161716), #165195 (#161713), #165998 (#161712), #166111 (#161714), #165559 (#161839).
Fora de teste: #161715 (sem implementação), #161717 (fechado sem correção; entra só como regressão #39).
**Risco geral:** alto. Cinco PRs mexem no Scheduler, e 30060 × 30457 conflitam.

## 2. Fontes analisadas

| Fonte | Papel |
|---|---|
| `ReproSteps`/`Description` dos bugs | fonte primária (critérios e comportamento esperado) |
| PRs 30060 (`d4a98152`), 30104 (`e1396988`), 30457 (`9816142b`), 30486 (`3ac5ea98`), 30253 (`bfaf8358`), 30254 (`4b3535e7`) | fonte técnica (diff real) |
| Card `Análise` | **ausente** (exceção autorizada) |
| Histórico de defeitos | busca achou só os irmãos #161712, #161713, #161714; #161717 vem do PBI |

## 3. Requisitos e regras

| Req | Origem | Regra |
|---|---|---|
| R1 (#161716) | Transversal | Pendência relida em ciclo curto não gera 2º job com a mesma chave. 101 fluxos: 100 no 1º ciclo, 101 sucessos em `JOB_DUMP`, 0 duplicados |
| R2 (#161713) | Transversal | Falha de SQL com tentativa restante: retry sem tratamento. Esgotada: trata (variável de erro, escape, ocorrência). Escape não avança: envenena |
| R3 (#161713) | Transversal | Pendência cuja chave está em `JOB_DUMP` não é reenfileirada no ExecutaSql |
| R4 (#161712) | Transversal | Jobs do Scheduler checam `ExisteJobAtivo`; jobs recorrentes ou de chave fixa não usam dump; timezone respeitado |
| R5 (#161714) | Transversal | Falha no AvancoTemporal registra o erro real no log |
| R6 (#161839) | Legado + Novo | Observação "executor da tarefa anterior" notifica quem concluiu a tarefa anterior; isolamento por fluxo; tarefa anterior automática não notifica |

## 4. Matriz de paridade (somente #161839)

| Item | Clássico | net8 | Resultado esperado |
|---|---|---|---|
| Junção do executor anterior | `SmartShareAgent/NotifyWF.cs:NotificaObservacao` case 4 (PR 30254) | `CaminhoFluxoRepository.cs:GetUsuarioNotificaObservacaoExecutorTarefaAnterior` (PR 30253) | Mesmo destinatário nos dois |

Back-to-back: cenário #16 × #17, mesmo fluxo e massa. Evidência lida só no diff dos PRs; o clássico instalado não foi inspecionado.

## 5. Premissas, ambiguidades e ausências

- DUV-01: #161714 não define a mensagem de log esperada. #15 verifica só que a exceção original aparece.
- DUV-02: valores de `MaxTentativas`, `PoliticaBackoff` e `TimeZoneId` do `JOB_CONFIG` desconhecidos.
- DUV-03: sem mecanismo para forçar falha de SQL (#161713), erro de AvancoTemporal (#161714) e falha de enfileiramento (#161716).
- DUV-04: assinatura de `ExisteJobAtivo` da PR 29631 não lida; 30104 e 30457 têm duas versões diferentes.
- Premissa: build de teste integra os 5 PRs do net8 com o conflito 30060 × 30457 resolvido; senão cada PR é testado isolado e #35 não vale.
- Premissa: `ExisteJobAtivo` do 30457 filtra só por `Chave_Concorrencia` (sem módulo/job); as chaves incluem o nome do job.

## 6. Pré-requisitos gerais

- Build: branches dos PRs (ou build integrado) instalado em Scheduler e Worker BPM; **versão implantada a confirmar antes de executar**.
- Bancos: SQL Server e Oracle (cenários #33 e #34); troca conforme `QA-KB-20261106-001`, a revalidar.
- Acesso a `JOB_BPM`, `JOB_DUMP`, `JOB_CONFIG`, `CAMINHO_FLUXO`, `TAREFA` e aos logs do Scheduler e do Worker.
- Mock de endpoint HTTP 200 com JSON válido (#1, #31).
- Processo BPM com atividades de teste e e-mail de destino válido (#16 a #19, #25 a #27, #36, #39).
- Agent clássico com o fix do PR 30254 (#17).
- Escritas (INSERT/UPDATE/DELETE em `JOB_*`) exigem autorização do dono do banco; limpeza ao final.

## 7. Cobertura planejada

Dimensões: positivo, negativo, dados, concorrência, regressão aplicáveis. Permissão: `N/A — jobs rodam como serviço; nenhuma correção altera perfil`. Técnicas usadas: valor-limite, tabela-decisão, partição-equivalência, transição-de-estado, pairwise, exploratório.

## 8. Cenários (41)

### === FLUXO PRINCIPAL ===

| # | Cenário | Ação | Resultado Esperado | Tipo | Técnica | Dimensão | Origem | Camada | Componente |
|---|---|---|---|---|---|---|---|---|---|
| 1 | #161716 101 fluxos WS sem duplicar job | Criar 101 fluxos com tarefa WebService elegível, job 28 em intervalo curto, mock HTTP 200, subir Scheduler e Worker BPM, aguardar as 101 tarefas | 1º ciclo cria 100 jobs; no fim `JOB_DUMP` tem 101 sucessos para 101 fluxos, 0 chaves `fluxo/tarefa/passo` repetidas (defeito: 134 registros, 33 duplicados) | positivo | valor-limite | positivo | história (#161716) | Scheduler/Worker | `ExecutaWsSchedulerHandler.EnfileirarPendencias` |
| 2 | #161716 pendência relida é ignorada com log | Com 1 job ativo (Agendado/Executando) para a chave, aguardar novo ciclo e ler o log do Scheduler | Nenhum 2º `JOB_BPM` para a chave; log `AlreadyActive` | positivo | partição-equivalência | positivo | análise técnica/PR (30104) | Scheduler | `JobBpmRepository.ExisteJobAtivo` (30104) |
| 3 | #161713 retry quando ainda há tentativa | Forçar falha de SQL no ExecutaSql com `QtdeTentativas` < `MaxTentativas` | Job reagendado (`FalhaParaRepetir`); variável de erro do fluxo não gravada; sem passo de escape; sem ocorrência | positivo | transição-de-estado | positivo | história (#161713) | Worker BPM | `AgentBpmService.DeveRelancarParaReagendar` |
| 4 | #161713 tentativas esgotadas, escape avança | Forçar falha de SQL com tentativas esgotadas e passo de escape configurado | Variável de erro gravada, erro logado, fluxo avança pelo escape, ocorrência notificada se `NotificaOcorrencia`; job não é envenenado | positivo | tabela-decisão | positivo | história (#161713) | Worker BPM | `AgentBpmService.TratarFalhaDefinitivaExecutaSql` |
| 5 | #161713 esgotadas, sem passo de escape | Idem, processo sem passo de escape | Job envenenado (`Envenenado`), registro em `JOB_DUMP`, erro logado; não termina como sucesso | negativo | tabela-decisão | negativo | história (#161713) | Worker BPM | `AvancaPassoEscapeExecutaSql` retorna `false` |
| 6 | #161713 esgotadas, escape falha ao avançar | Idem, forçando falha de `AvancarFluxo` do escape | Job envenenado e `JOB_DUMP` preenchido; log "Erro ao avançar para o passo de escape" | negativo | tabela-decisão | negativo | análise técnica/PR (30060) | Worker BPM | `AvancaPassoEscapeExecutaSql` |
| 7 | #161713 pendência envenenada não volta à fila | Com a chave do ExecutaSql já em `JOB_DUMP`, aguardar ciclos do Scheduler | Nenhum job novo em `JOB_BPM`; log "já foi processado" | negativo | partição-equivalência | negativo | história (#161713) | Scheduler | `ExecutaSqlSchedulerHandler` |
| 8 | #161712 AvancoTemporal não duplica | Para cada ponto (tempo, prazo, anexos iguais reprovados, valida anexo, lote) manter 1 job ativo e rodar vários ciclos | 1 job por chave; log `SkippedJobAtivo` | positivo | partição-equivalência | positivo | história (#161712) | Scheduler | `AvancoTemporalSchedulerHandler` |
| 9 | #161712 ExecutaPassoAplicacao não duplica | Idem, com job ativo | 1 job por chave; dump continua validado | positivo | partição-equivalência | positivo | história (#161712) | Scheduler | `ExecutaPassoAplicacaoHandler` |
| 10 | #161712 ExecutaSql e InicioPublicacao não duplicam | Idem, para os dois jobs | 1 job por chave `BPM\|ExecutaSql\|fluxo\|tarefa` e `BPM\|InicioPublicacao\|processo\|versao` | positivo | partição-equivalência | positivo | história (#161712) | Scheduler | `ExecutaSqlSchedulerHandler`, `InicioPublicacaoHandler` |
| 11 | #161712 NotifyScheduler pendência (3 tipos) | Gerar pendência de mensagem nova, observação e tarefa com job ativo | 1 job por fluxo+tarefa em cada tipo | positivo | partição-equivalência | positivo | história (#161712) | Scheduler | `NotifySchedulerHandler.NotificarMensagemNovo/NotificaObservacao/NotificaTarefa` |
| 12 | #161712 NotifyScheduler alertas e exceção de alçada | Com job ativo de chave fixa, rodar ciclos | 1 job `NotificarAlertas` e 1 `NotificarMensagemExcecaoAlcada` ativos | positivo | partição-equivalência | positivo | história (#161712) | Scheduler | `NotifySchedulerHandler` |
| 13 | #161712 ExcluiFluxoEmSolicitacao, EnviaAlertaFluxo e InicioTemporal | Idem, 3 jobs | Sem duplicar; InicioTemporal pula job quando já ativo | positivo | partição-equivalência | positivo | história (#161712) | Scheduler | `BpmSchedulerJob` |
| 14 | #161712 job recorrente volta após terminar | Concluir o job ativo de chave fixa (ex.: `EnviaAlertaFluxo`) e aguardar o ciclo seguinte | Novo job é criado no ciclo seguinte; recorrente não fica bloqueado | positivo | transição-de-estado | positivo | história (#161712) | Scheduler | `ExisteJobAtivo` (30457) |
| 15 | #161714 log do AvancoTemporal traz o erro real | Forçar exceção em `AvancarFluxo` num job AvancoTemporal e ler o log do Worker | Log registra a exceção original (tipo, mensagem, stack) e não só mensagem genérica; mesmo padrão de ExecutaSql | positivo | exploratório | positivo | história (#161714) | Worker BPM | `AvancoTemporalExecHandler.ProcessarFluxo` (`jr.Exception`) |
| 16 | #161839 executor anterior recebe e-mail | Atividade com "Visualização e Inclusão pelo executor notificando executor da tarefa anterior", fluxo de 2–3 tarefas, incluir observação | Executor da tarefa anterior recebe o e-mail (antes não recebia) | positivo | partição-equivalência | positivo | história (#161839) | net8 / Notificação | `CaminhoFluxoRepository.GetUsuarioNotificaObservacaoExecutorTarefaAnterior` |
| 17 | #161839 mesma regra no clássico | Repetir 16 no SmartShare clássico com o Agent do PR 30254 | Executor anterior recebe o e-mail | positivo | partição-equivalência | positivo | análise técnica/PR (30254) | Clássico | `NotifyWF.NotificaObservacao` case 4 |

### === FLUXO ALTERNATIVO ===

| # | Cenário | Ação | Resultado Esperado | Tipo | Técnica | Dimensão | Origem | Camada | Componente |
|---|---|---|---|---|---|---|---|---|---|
| 18 | #161839 tarefa anterior de papel/comitê | Tarefa anterior executada por usuário que pertence a papel/comitê; incluir observação | Recebe quem concluiu a tarefa (`TAREFA.cd_usuario`) | positivo | partição-equivalência | positivo | história (#161839) | Notificação | `CaminhoFluxoRepository` |
| 19 | #161839 tarefa anterior automática | Tarefa anterior SQL, WS, e-mail ou condição; incluir observação | Nenhuma notificação nessa opção; observação processada; fluxo segue sem erro | borda | partição-equivalência | dados | história (#161839) | Notificação | `NotifyWFExecHandler` (1006–1036) |
| 20 | #161713 duas políticas de backoff | Repetir cenário 3 com cada `PoliticaBackoff` configurada | Reagendamento com a data da política | positivo | pairwise (política × banco) | positivo | análise técnica/PR (30060) | Worker BPM | `JobResiliencePolicy.CalcularFalha` |

### === VALIDACOES DE CAMPOS ===

| # | Cenário | Ação | Resultado Esperado | Tipo | Técnica | Dimensão | Origem | Camada | Componente |
|---|---|---|---|---|---|---|---|---|---|
| 21 | #161713 limite de tentativas | Com `MaxTentativas = N`, rodar falhas com `QtdeTentativas` = N−1 e N | N−1: reagenda. N: tratamento definitivo (escape ou envenena) | borda | valor-limite | negativo | história (#161713) | Worker BPM | `ExecutarExecutaSql` (3 parâmetros) |
| 22 | #161712 timezone configurado | Configurar `TimeZoneId` diferente do servidor e agendar job | `DataProgramada` e `DataCriacao` do job respeitam o fuso configurado | positivo | partição-equivalência | dados | história (#161712) | Scheduler | `JobConfigService.GetDataAtual(timeZoneId)` |
| 23 | #161716 limite 99/100/101 pendências | Rodar com 99, 100 e 101 tarefas | 99 e 100: um job por tarefa no 1º ciclo; 101: 100 no 1º e o restante nos ciclos seguintes, sem duplicar | borda | valor-limite | dados | história (#161716) | Scheduler | `ExecutaWsSchedulerHandler` |

### === PERMISSAO ===

| # | Cenário | Ação | Resultado Esperado | Tipo | Técnica | Dimensão | Origem | Camada | Componente |
|---|---|---|---|---|---|---|---|---|---|
| 24 | Permissão | N/A — os jobs rodam como serviço; nenhuma das 5 correções altera perfil, token ou escopo | N/A | borda | partição-equivalência | N/A | — | — | — |

### === DADOS E CASOS DE BORDA ===

| # | Cenário | Ação | Resultado Esperado | Tipo | Técnica | Dimensão | Origem | Camada | Componente |
|---|---|---|---|---|---|---|---|---|---|
| 25 | #161839 isolamento entre fluxos | Dois fluxos com os mesmos `cd_tarefa`, executores anteriores distintos; observação em cada | Cada fluxo notifica só o seu executor anterior | negativo | tabela-decisão | dados | história (#161839) | Notificação | `CaminhoFluxoRepository` (`cd_fluxo` nas duas pontas) |
| 26 | #161839 executor anterior com `cd_usuario` nulo/0 | Tarefa anterior sem usuário (automática); observação | Sem erro; observação marcada como processada | borda | partição-equivalência | dados | história (#161839) | Notificação | `NotifyWFExecHandler` |
| 27 | #161839 ramos paralelos | Fluxo com 2 ramos paralelos antes da tarefa; observação | Sem erro; hoje só o último executor da lista é notificado (declarado fora de escopo); registrar o observado | borda | exploratório | dados | análise técnica/PR (#161839) | Notificação | `NotifyWFExecHandler.cs:982` |
| 28 | #161716 chave já na dump bloqueia só a mesma chave | Chave `fluxo/tarefa/passo` já em `JOB_DUMP` + pendência nova de outra tarefa | Pendência repetida é ignorada com log; a nova recebe job | negativo | partição-equivalência | negativo | história (#161716) | Scheduler | `JobDumpService.ExisteChaveUnica` |
| 29 | #161712 jobs `// TODO` não agendam | Rodar ciclos e consultar `JOB_BPM` | Nenhum job `InicioFluxoRevisao`, `InicioDesassociarAutomatico` ou `NotificaInicioComPublicacao` criado | borda | partição-equivalência | dados | análise técnica/PR | Scheduler | `EnqueueJobSchedulerQuartz` (comentados) |

### === CONCORRENCIA ===

| # | Cenário | Ação | Resultado Esperado | Tipo | Técnica | Dimensão | Origem | Camada | Componente |
|---|---|---|---|---|---|---|---|---|---|
| 30 | HIPOTESE: duas instâncias do Scheduler | Subir 2 Schedulers no mesmo banco com 101 fluxos WS | Sem job duplicado; se houver, registrar (checagem e insert não são atômicos; requisito não declarado) | negativo | exploratório | concorrência | hipótese | Scheduler | `ExisteJobAtivo` + `AddSql` |

### === ERROS DE INTEGRACAO / API ===

| # | Cenário | Ação | Resultado Esperado | Tipo | Técnica | Dimensão | Origem | Camada | Componente |
|---|---|---|---|---|---|---|---|---|---|
| 31 | #161716 endpoint WS fora do ar | Mock retornando 500/timeout com 101 fluxos | Jobs em `FalhaParaRepetir` não são recriados; ao esgotar, envenena | negativo | transição-de-estado | negativo | história (#161716) | Worker/Scheduler | `ExecutaWsHandler`, `ExisteJobAtivo` |
| 32 | #161716 falha ao enfileirar 1 pendência | Provocar erro de banco numa pendência do lote (mecanismo a definir pelo dev) | Erro logado; demais pendências enfileiradas | negativo | partição-equivalência | negativo | análise técnica/PR (30104) | Scheduler | `try/catch` do `EnfileirarPendencias` |
| 33 | Banco SQL Server | Rodar 1, 3, 5, 14 e 16 em SQL Server | Mesmos resultados; `ExisteJobAtivo` retorna correto | positivo | pairwise (banco × cenário) | positivo | Transversal | Banco | `JobBpmRepository.ExisteJobAtivo`, `CaminhoFluxoRepository` |
| 34 | Banco Oracle | Idem em Oracle | Mesmos resultados do SQL Server | positivo | pairwise (banco × cenário) | positivo | Transversal | Banco | idem |
| 35 | Build integrado compila e roda | Resolver 30060 × 30457 e subir Scheduler+Worker | Compila; um ciclo completo sem exceção; ExecutaSql com dump e job ativo | positivo | exploratório | regressão | análise técnica/PR | Build | `ExecutaSqlSchedulerHandler`, `BpmSchedulerJob` |

### === REGRESSAO ===

| # | Cenário | Ação | Resultado Esperado | Tipo | Técnica | Dimensão | Origem | Camada | Componente |
|---|---|---|---|---|---|---|---|---|---|
| 36 | #161839 outras opções de observação | Testar as demais opções (participante, solicitante, participantes anteriores) | Continuam notificando | positivo | partição-equivalência | regressão | história (#161839) | Notificação | `TarefaRepository` (613–648) |
| 37 | #161713 ExecutaSql sem erro | Executar SQL válido | Sucesso na 1ª tentativa; sem retry, escape ou ocorrência | positivo | partição-equivalência | regressão | análise técnica/PR (30060) | Worker BPM | `ExecutarExecutaSql` |
| 38 | InicioTemporal por frequência | Frequência diária, semanal e mensal na hora certa | Gera 1 job por ocorrência | positivo | tabela-decisão | regressão | análise técnica/PR (30457) | Scheduler | `InicioTemporalSchedulerHandler.GerarJob` |
| 39 | #161717 EnviaAlertaFluxo vários alertas no mesmo período | Configurar 2+ alertas no mesmo período e rodar | Todos os e-mails chegam; o job não é suprimido pelo `ExisteJobAtivo` | positivo | partição-equivalência | regressão | histórico de defeitos (#161717) | Scheduler/Notificação | `BpmSchedulerJob.EnviaAlertaFluxo` |

### === CASOS DE BORDA / HIPOTESES ===

| # | Cenário | Ação | Resultado Esperado | Tipo | Técnica | Dimensão | Origem | Camada | Componente |
|---|---|---|---|---|---|---|---|---|---|
| 40 | HIPOTESE: job no limite de tentativas | `FalhaParaRepetir` com `Qt_de_Tentativas` = `MaxTentativas`; rodar ciclo | Esperado: sem job duplicado; a SQL do 30457 não o conta como ativo | borda | valor-limite | concorrência | hipótese | Scheduler | `Qt_de_Tentativas < Max` |
| 41 | HIPOTESE: erro não reagendável | Erro que `ClassificarErro` marca como não reagendável, com tentativas sobrando | Esperado: tratamento definitivo sem retry; `CalcularFalha` não lida | borda | tabela-decisão | negativo | hipótese | Worker BPM | `WorkerHelper.ClassificarErro` |

Os passos alternados (ação do ator / `O sistema deve...`) de cada cenário serão detalhados na execução, ao rodar `/arquitetura-executar-teste`.

## 9. Cenários exploratórios

#15, #27, #30 e #35 (objetivo: confirmar comportamento ainda sem regra escrita; evidência: log e consulta a `JOB_BPM`/`JOB_DUMP`).

## 10. Matriz de rastreabilidade

| Req | Cenários |
|---|---|
| R1 (#161716) | 1, 2, 23, 28, 31, 32 |
| R2 (#161713) | 3, 4, 5, 6, 20, 21, 37, 41 |
| R3 (#161713) | 7 |
| R4 (#161712) | 8–14, 22, 29, 30, 38, 39, 40 |
| R5 (#161714) | 15 |
| R6 (#161839) | 16–19, 25–27, 36 |
| Transversal | 33, 34, 35 |

## 11. Cobertura de riscos

| Risco | Cenários |
|---|---|
| Duplicação de job (P0) | 1, 2, 8–13, 23, 30, 40 |
| Job recorrente bloqueado para sempre (P0) | 14, 39 |
| Falha mascarada / sem envenenar (P0) | 3–7, 21 |
| Conflito entre PRs (P0) | 35 |
| Notificação para a pessoa errada (P1) | 16–19, 25–27 |
| Diferença Oracle × SQL Server (P1) | 33, 34 |

**Riscos residuais:** a PR 29631 não foi lida (assinatura de `ExisteJobAtivo`); a SQL do Oracle só foi lida no código, não executada; comportamento de erro não reagendável (#41) e borda do limite (#40) sem evidência.

## 12. Itens bloqueados

| Cenários | Motivo |
|---|---|
| todos | build com as correções e versão implantada não confirmados; PRs Active |
| 3, 5, 6, 20, 21, 41 | falta mecanismo para forçar falha de SQL e valores de `MaxTentativas`/`PoliticaBackoff` |
| 15 | falta mecanismo para forçar erro no AvancoTemporal |
| 17 | falta Agent clássico com o fix do PR 30254 |
| 32 | falta mecanismo para falha de enfileiramento |
| 35 | conflito 30060 × 30457 a resolver |

Fora de teste: #161715, InicioFluxoRevisao, InicioDesassociarAutomatico, NotificaInicioComPublicacao.

## 13. Resumo

41 cenários em 9 categorias: 24 positivos, 8 negativos, 9 borda. 3 hipóteses (#30, #40, #41). Automação sugerida: Sim para #1, #2, #7, #21 e #28 (SQL de verificação em `JOB_BPM`/`JOB_DUMP`); Parcial para #8–#14; Não para #15, #27, #30 e #35.

## Pendências

- Nada publicado no Azure DevOps (decisão do QA). As 3 hipóteses não foram notificadas ao dev/PO na história.
- Para executar: definir o build, confirmar a versão implantada e obter os mecanismos de falha.
