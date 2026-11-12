# Etapa 02 — Análise Técnica — #160823 Rotina - Inicio Desassociar Automático

- **Skill:** `/arquitetura-analise-tecnica 160823`
- **Data:** 2026-11-04 11:45
- **Escreveu no Azure DevOps:** não (somente leitura)
- **Aprovação:** N/A
- **Fontes lidas:** história #160823; cards filhos (#161471 Análise, #161476 Analise Review — ignorado, #161481 Desenvolvimento, #161485 Code Review, #161490 Mapa, #161495 Teste); PR 29228 (repo SmartShare) e PR 29340 (repo smartshare-net8) — metadados e lista de arquivos. Diff linha a linha não lido.

## Aprendizados consultados

Consulta realizada — nenhum aprendizado aplicável encontrado. (base vazia)

---

# Análise Técnica — #160823 Rotina - Inicio Desassociar Automático

**Card de Análise:** #161471 (Done, última alteração 2026-10-09; campos `Pontosdeimpacto` e `CasodeTeste` preenchidos)
**Branch (card):** `feature/US160823-migracao-job-inicio-desassociar-automatico`
**PR vinculado:**
- PR 29228 — repo `SmartShare` (clássico), `feature/...` → `master`, 3 arquivos. Estado da API: `status=1` (Active), `mergeStatus=3`.
- PR 29340 — repo `smartshare-net8`, `feature/...` → `main`, 40 arquivos. Estado da API: `status=1` (Active), `mergeStatus=3`.

> O campo `status` da API indica PR ativo (não concluído). Os cards Desenvolvimento e Code Review estão Done. Merge efetivo: **NÃO VALIDADO**.

## O que foi alterado (origem: análise do dev; PR 29340; PR 29228)
- Novo job `InicioDesassociarAutomatico` (`EJobBpm=34`, JOB_CONFIG Id=12, Módulo 1=BPM, `Ativo=0`, intervalo 300000 ms, `Max_Paralelo=1`) — análise do dev.
- Scheduler: `BpmSchedulerJob.InicioDesassociarAutomatico` (stub implementado), `InicioDesassociarAutomaticoHandler` (novo), `InicioDesassociarAutomaticoHelper.PrazoExpirou` (novo, compartilhado Scheduler/Worker), `AgentBpmService`, `TarefaService`, `TarefaRepository.ListarPendenciasInicioDesassociarAutomatico` (novo), `InicioDesassociarAutomaticoPendenciaVM` (novo) — análise do dev; PR 29340.
- Worker BPM: `BpmExecJob.InicioDesassociarAutomatico` (stub implementado), `InicioDesassociarAutomaticoExecHandler` (novo), `WorkerHelper.GetHashArgumentos` (novo ramo), `FluxoService.DesassociarFluxo` (novo, reaproveita `AtualizarValoresCorrenteCampoFormularioDaTarefa` e `GrantLock`), `VersaoAnexoLiberacaoService/Repository.ApagarPorFluxoEUsuario` (novo) — análise do dev; PR 29340.
- Scripts de config SQL Server e Oracle — PR 29228: `/0.1 PreCarga.sql`, `/Database/Oracle/0.4 PreCarga.sql`.
- Clássico: `SmartShareAgent/DesassociaTarefa.cs` — PR 29228 (alteração **não descrita** no card; ver Discrepâncias).
- Correção pós-migração (histórico do card): JOIN com `PASSO_USUARIO` passou a incluir `AND PU.cd_passo = T.cd_passo` em `TarefaRepository.cs`. O dev registra que o bug existe também no legado e que não há teste automatizado para essa regra (gap).

## Onde foi alterado (por camada)

| Camada | Alterado | Risco | Justificativa |
|---|---|---|---|
| Banco / config | JOB_CONFIG e JOB_CONFIG_PADRAO (Id=12) em SQL Server e Oracle; `Ativo=0` | Médio | Dois dialetos; Seeder (`JobConfigSeeder.cs:258-263`) gera entrada ativa para clientes migrados |
| Repositório | `TarefaRepository.ListarPendenciasInicioDesassociarAutomatico` (JOIN de 3 tabelas); `VersaoAnexoLiberacaoRepository.ApagarPorFluxoEUsuario` | Alto | Define elegibilidade; já teve bug (falta `cd_passo`); DELETE de liberação de anexo |
| Serviço/domínio | `FluxoService.DesassociarFluxo` (transação, auditoria, atualização de TAREFA, log); `InicioDesassociarAutomaticoHelper.PrazoExpirou` | Alto | Escrita em TAREFA/OPCAO_TAREFA/LOG; compartilha helpers com `AvancarFluxo`/`CancelarFluxo` |
| Scheduler | Handler, `BpmSchedulerJob` | Médio | Decide elegibilidade; chaveUnica recorrente (não usar `ExisteChaveUnica`) |
| Worker BPM | Handler, `BpmExecJob`, `WorkerHelper` | Médio | Reconfirma elegibilidade; erro por item não deve abortar o lote |
| Clássico (Agent) | `DesassociaTarefa.cs` | Médio | Mudança não descrita no card; coexistência legado/novo (`UsarNovoAgent(BPM,34)`) |
| Front-end / relatórios | Nenhuma alteração identificada | — | Listagem na tela de configuração: **Informação não encontrada / necessita validação** (não há arquivo de front no PR; depende de como a lista é montada) |

## Dependências diretas
- `FluxoService.AtualizarValoresCorrenteCampoFormularioDaTarefa` (privado, também usado por `AvancarFluxo`) e `GrantLock` — análise do dev.
- `TarefaService` → `TarefaRepository`; `AgentBpmService` → `TarefaService` — análise do dev.
- `LogAplicacaoService.InsertLog` (segundo log, `ETipoAcao.DesassociarFluxo=45`, `ETipoAplicacao.GerenciamentoDeCampoDeFormulario=47`) — análise do dev.
- `JobConfigService` / JOB_CONFIG para ativar a rotina — análise do dev.

## Dependências indiretas
- `AvancarFluxo` e `CancelarFluxo` (compartilham helpers com o novo método) — regressão a conferir (análise do dev).
- Clássico: lock distribuído `STATUS_AGENT` (`cd_status_agent=34`) e `UsarNovoAgent(BPM,34)` — análise do dev (legado).
- Outros jobs BPM no mesmo Scheduler/Worker — "erros aqui não impactam outros jobs" é item a verificar (análise do dev).

## Funcionalidades potencialmente impactadas
- Associação/reassociação de tarefas por usuário; avanço e cancelamento de fluxo; histórico/auditoria da tarefa (OPCAO_TAREFA); campos de formulário de usuário/área/e-mail/ramal corrente; liberação de anexo.

## Integrações potencialmente impactadas
- Execução paralela com o Agent clássico (alternância por `JOB_CONFIG.Ativo`).
- Seeder de migração de cliente para net8.

## Dados potencialmente impactados
- TAREFA (`cd_usuario`, `dt_inicio`, `cd_responsavel`, `id_tipo_responsavel`), OPCAO_TAREFA, VERSAO_ANEXO_LIBERACAO, LOG_APLICACAO (dois registros por desassociação), JOB_BPM, JOB_CONFIG, JOB_CONFIG_PADRAO.

## Discrepâncias entre análise do dev e o PR

### Dentro do escopo da US (provável — necessita validação do dev)
- `Selbetti.Net8.sln`, `InicioDesassociarAutomaticoEnfileiramentoAdapter.cs`, `InicioDesassociarAutomaticoExecucaoAdapter.cs`, interfaces `IInicioDesassociarAutomatico*`, `AssemblyInfo.cs` (WorkerScheduler), `JobArgs.cs`, `BpmEnqueueJobExecQuartz.cs`, `EnqueueJobSchedulerQuartz.cs`: não citados no card. Parecem fiação do job (adapters, DI, Quartz, args). Os adapters/interfaces divergem do desenho do card, que não os menciona.
- Projetos de teste e documentos de story (`stories/Story-23-...`): sem impacto funcional.

### Fora do escopo da US / a confirmar
- `SmartShareAgent/DesassociaTarefa.cs` (PR 29228, clássico): o card descreve só o comportamento do legado e não diz o que foi alterado nele. **Risco potencial:** mudar o legado pode alterar o comportamento de clientes que ainda usam o Agent clássico. **Revisão necessária:** sim (diff não lido). **Impacto no gate:** pode bloquear a homologação se a alteração mudar o comportamento do clássico. A skill de revisão de branch/PR do time de dev não está disponível aqui.
- `BpmEnqueueJobExecQuartz.cs` e `EnqueueJobSchedulerQuartz.cs`: arquivos genéricos de enfileiramento, compartilhados com outros jobs. **Risco potencial:** regressão em outros jobs BPM. **Revisão necessária:** sim.

## Casos de teste sugeridos pelo dev (card #161471 — não validados pelo QA)
1. Tarefa associada há mais tempo que o configurado é desassociada (usuário zerado, registro no histórico, log com fluxo e tarefa).
2. Tarefa dentro do prazo não é alterada.
3. Tarefa sem usuário associado não é afetada.
4. Tarefa concluída não é afetada.
5. Passo sem "Tempo total para desassociar" nunca gera desassociação.
6. Tarefa reassociada volta a ser avaliada e é desassociada de novo.
7. Erro numa tarefa não trava as demais; erro fica no log.
8. Ativar/desativar a rotina controla quem executa (novo Agent × clássico).
9. Duas instâncias não duplicam a desassociação nem o histórico.
10. Configuração salva corretamente em SQL Server e Oracle.

Cenário no clássico (dev, lido no código e não executado): aba Avançado da Atividade, campo "Tempo total para desassociar" (`AtividadeAvancadaForm.ascx:137-160`, `Atividade.aspx.cs:5197-5198`). Host de referência: SmartShareWeb. No host WebApplication o salvamento não grava o campo — não testar lá.

## Pré-requisitos técnicos de execução de teste
- Configuração: JOB_CONFIG Id=12 existe com `Ativo=0` por padrão; ativação por cliente na tela de configuração (listagem). Valor padrão do intervalo 300000 ms (5 min). Origem: card.
- Cenário: processo com Atividade de executor **papel** e "Tempo total para desassociar" preenchido, criado no host **SmartShareWeb**. Origem: card.
- Bancos: SQL Server e Oracle.
- **Informação não encontrada / necessita validação — bloqueante para /arquitetura-executar-teste:** mecanismo para forçar erro numa tarefa (caso 7) em ambiente de teste.
- **Informação não encontrada / necessita validação — bloqueante para /arquitetura-executar-teste:** como subir duas instâncias do serviço (caso 9) e como observar a duplicação.
- **Informação não encontrada / necessita validação — bloqueante para /arquitetura-executar-teste:** build/branch implantado no ambiente de teste.
- Versão analisada × implantada: esperado = branch `feature/US160823-migracao-job-inicio-desassociar-automatico` (net8 commit de origem `c7c8388…`; clássico `4b2b504…`); encontrado = ambiente não consultado; verificação = nenhuma realizada; resultado = **NÃO VALIDADO** — **BLOQUEANTE PARA EXECUÇÃO**, pois o código pode divergir do PR.

## Informações ausentes
- Informação não encontrada / necessita validação: o que mudou em `SmartShareAgent/DesassociaTarefa.cs` no PR 29228.
- Informação não encontrada / necessita validação: se os PRs 29228 e 29340 foram concluídos (a API retornou `status=1`, Active).
- Informação não encontrada / necessita validação: como a rotina chega à listagem da tela de configuração (não há arquivo de front no PR; depende de dado de JOB_CONFIG ou de enum).
- Informação não encontrada / necessita validação: a correção do JOIN com `cd_passo` e o gap de teste Oracle (registrados no histórico do card) — confirmar se a correção está nos commits dos PRs.
- Informação não encontrada / necessita validação: ambiente e versão onde o teste será executado.
