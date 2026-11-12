# Etapa 06 — analise-negocio — Bug #161712 (filho de #161711 Bugs Instaladores)

- **Skill e argumentos:** `/arquitetura-analise-negocio` com `#161711` e pedido de uma análise por bug
- **Data:** 2026-11-09
- **Escreveu no Azure DevOps:** Não
- **Aprovação:** não aplicável (etapa somente leitura)
- **Fontes lidas:** Bug #161712 (rev 36, `ReproSteps`, relações), PBI #161711 (rev 20), Análise #161472 (busca), PBI #165944 (busca), análise consolidada `01-analise-negocio.md`. Comentários: nenhum (`System.CommentCount = 0`).

## Aprendizados consultados

Consulta realizada — nenhum aprendizado aplicável encontrado (`QA-KB-20261105-001` e `QA-KB-20261106-001` não tratam de duplicidade de jobs).

# Análise de Negócio — Bug #161712 [BUG/DISCUSSÃO][AgentWorkers] - Scheduler - Várias tentativas de inserir um mesmo JOB

**Projeto:** SmartShare Arquitetura | **Tipo:** Bug | **Status:** Done (06/11, tag "CR feito") | **Sprint:** Sprint 4 | **Responsável:** Vinicius Medeiros dos Santos | **Severidade:** 3 - Medium | **PR:** 30457 (Active) | **Card de Teste:** #165998 (New, sem responsável) | **Card de CR:** não existe

## Objetivo da alteração

Evitar que o Scheduler enfileire de novo um job que já está ativo (agendado, executando ou aguardando nova tentativa) e decidir, job a job, quando também é preciso bloquear job já concluído/envenenado (dump). O bug nasceu do caso do #161716 (ExecutaWS) e foi estendido para os demais jobs do Scheduler. (ReproSteps, "Descrição")

## Comportamentos esperados (contratos verificáveis)

- Quando um job do Scheduler ainda estiver ativo, o Scheduler não deve criar outro com a mesma chave. A checagem `ExisteJobAtivo` vale para: AvancoTemporalScheduler, ExecutaPassoAplicacao, ExecutaSqlScheduler, InicioPublicacao, NotificaInicioComPublicacao, os 5 métodos do NotifySchedulerHandler, ExcluiFluxoEmSolicitacao, EnviaAlertaFluxo, InicioFluxoRevisao e InicioDesassociarAutomatico. (ReproSteps)
- InicioTemporalScheduler não precisa de `ExisteJobAtivo` na prática (já atualiza a data da última verificação ao agendar). Exceção: falha parcial em que o job é agendado e a atualização da data falha; nesse caso a checagem serve de reforço. (ReproSteps)
- Jobs que repetem por natureza ou têm chave fixa (InicioPublicacao, NotificaInicioComPublicacao, InicioTemporal, ExcluiFluxoEmSolicitacao, EnviaAlertaFluxo, NotifyScheduler alertas e exceção de alçada) não devem usar a checagem de dump, para não ficarem bloqueados para sempre. (ReproSteps)
- ExecutaSqlScheduler: valida a dump (`ExisteChaveUnica`, PR 30060) e também `ExisteJobAtivo`. ExecutaPassoAplicacao e InicioFluxoRevisao já validam a dump e ganham `ExisteJobAtivo`. (ReproSteps)
- Nos jobs alterados, `GetDataAtual` deve respeitar o timezone. (ReproSteps, OBS final)

## Regras explícitas

- `ExisteChaveUnica` (dump) responde "este job já foi concluído ou envenenado alguma vez?". `ExisteJobAtivo` responde "já existe um igual em andamento?". (ReproSteps)
- AvancoTemporal não precisa da dump porque a query de origem deixa de devolver o item depois que o fluxo avança. (ReproSteps)
- ExecutaWsScheduler (PR 30104) e CalculoIndicador (PR 29631) estão fora deste bug: já tratados em outros PRs. (ReproSteps)
- A decisão de usar a dump em cada método do NotifyScheduler fica para o #161715, "item por item". (ReproSteps, OBS destacada)

## Regras implícitas

- IMPLÍCITA: a validação do bug é por job. São cerca de 11 jobs, cada um com a sua combinação de checagens (só `ExisteJobAtivo`, ou `ExisteJobAtivo` mais dump). Raciocínio: o texto separa os jobs com justificativas diferentes.
- IMPLÍCITA: depois que o job ativo termina (sucesso ou envenenado), um item novo e legítimo do mesmo tipo continua podendo ser enfileirado. Raciocínio: o texto rejeita a dump justamente porque bloquearia itens novos.

## Condições e exceções

- Jobs de chave fixa/recorrentes: só `ExisteJobAtivo`.
- Jobs por item (ExecutaSql, ExecutaPassoAplicacao, InicioFluxoRevisao): dump mais `ExisteJobAtivo`.
- InicioTemporal: `ExisteJobAtivo` só como reforço para falha parcial.
- Banco: Oracle e SQL Server (o produto roda nos dois; o bug não cita).

## Dependências

- PR 29631 (origem do `ExisteJobAtivo`, ligada à análise #161472 de CalculoIndicador, `JobBpmService.ExisteJobAtivo` marcado como `[CRIAR]` lá) ainda aberto, segundo #161716 e #161712.
- PR 30060 (#161713) e PR 30457 (#161712) alteram o mesmo handler `ExecutaSqlSchedulerHandler` (conflito já registrado na etapa 03 do ciclo).
- #161715 / PBI #165944 (NotifyWF) decidem a dump nos métodos de notificação.

## Informações ausentes

- Informação não encontrada / necessita validação: resultado observável esperado por job (por exemplo, número de linhas em `JOB_BPM` após N ciclos) e para a validação de timezone (`GetDataAtual`).
- Informação não encontrada / necessita validação: se InicioTemporal deve ser exigido ou opcional no teste.
- Informação não encontrada / necessita validação: InicioFluxoRevisao, InicioDesassociarAutomatico e NotificaInicioComPublicacao constam como `// TODO` na `main` (etapa 03 do ciclo); confirmar se o bug os cobre agora ou depois.

## Ambiguidades

- "ExisteJobAtivo como reforço" em InicioTemporal: o texto diz "na prática não precisa" e depois "vale usar". Interpretação adotada: opcional, não é critério de aceite.
- "Bug/Discussão": o título mistura correção e discussão de regra; a regra por job está só no texto do ReproSteps.

## Riscos identificados

- Aplicar a dump em job recorrente bloqueia o job para sempre (maior risco de regressão).
- Aplicar só `ExisteJobAtivo` em job por item deixa passar reenfileiramento de item já envenenado.
- Conflito com o PR 30060 no mesmo handler.
- PR 30457 Active, ainda não mesclado.

## Prontidão para as próximas etapas

| Gate | Resultado |
|---|---|
| Prontidão para análise técnica | **APTA COM RESSALVAS** — falta o resultado esperado por job |
| Prontidão para geração do mapa | **APTA COM RESSALVAS** — mapa local já existe (etapa 04); ajustar com o resultado esperado por job |
| Prontidão para execução | **BLOQUEADA até haver build com o PR 30457** (estado do PR não foi reverificado nesta rodada) |

## Pendências

- Resultado esperado por job e escopo de timezone.
- Build de teste com PR 30457 (e decisão sobre o conflito com PR 30060).
