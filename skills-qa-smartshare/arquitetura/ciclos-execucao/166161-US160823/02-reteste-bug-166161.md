# Etapa 02 — reteste-bug-166161 — #160823 Rotina - Inicio Desassociar Automático

- **Skill e argumentos:** `/arquitetura-executar-teste #166161 - Teste da correção do bug` (Modo B, reteste seletivo pós-bug)
- **Data:** 2026-11-10 (execução entre 16:44 e 17:15)
- **Escreveu no Azure DevOps?** Não (nenhum comentário no Bug nem anexo foram gravados; aguardam aprovação)
- **Aprovou:** QA (`guilherme.borges`): lista seletiva, autorização de pull/rebuild, W1 a W4, troca para Oracle e "Desativar e restaurar" os jobs 9, 18, 19 e 32 no Oracle
- **Fontes:** Bug #166161 (ReproSteps e 4 comentários), mapa #161490, commit `6b23a794` (diff lido), `00-validacao-ambiente.md` deste ciclo, ciclo `161495-US160823`

# Execução — Mapa de Testes #161490 Mapa de testes

**Status:** PARCIAL (SQL Server e Oracle executados; #24 e #27 não executados)
**Ambiente:** local do QA, não produtivo. Share `http://localhost:58149/`, net8 em Debug, parâmetro 96 = 0 (motor clássico). SQL Server `NOTE-74VQ\SQLEXPRESS/ShareGuizao/dbo` e Oracle `SSHARE/SHAREGUIZAO`.
**História relacionada:** #160823 Rotina - Inicio Desassociar Automático
**Modo:** Reteste Seletivo Pós-Bug — Bug #166161, fix analisado: commit `6b23a794` (Luis Bertucci, 09/11/2026, `FluxoService.cs`: `item.ds_valor_inicial?.ToLower() ?? string.Empty` nas linhas ~7749 e ~8002)
**Cenários selecionados:** #22 (origem); adicionados pela heurística: #23 (mesma categoria), #1, #2, #17 (fluxo que passa pelo método corrigido), #24 a #27 (regressão do mapa). Fora da lista: #16, #21, #4, #5.

## Resumo
- Executados: 9 cenários (#24 e #27 fora)
- PASSOU: #1, #2, #22 (SQL Server e Oracle), #23 (SQL Server), #17 (SQL Server)
- PASSOU COM RESSALVA: #17 (Oracle), #25, #26
- FALHOU: 0
- BLOQUEADO: 0
- INCONCLUSIVO: #23 no Oracle (sem mecanismo de falha limpa)
- HIPÓTESE NÃO VALIDADA: #22 nulo é condição criada por `UPDATE` (a tela grava `[ds_usuario_solicitante]`), registrada como observação investigativa
- NÃO EXECUTADO: #24 e #27 (exigem subir o Agent clássico; aguardam OK do QA)

## Pré-requisitos do ambiente
Ver `00-validacao-ambiente.md` (PR-01 a PR-17, atualizações de 10/11). Todos `OK` ou autorizados antes da execução. Fase SQL Server liberada às 16:45; fase Oracle após a troca de banco e a desativação dos jobs residuais.

## Detalhe por step
| # | Banco | Ação | Esperado | Obtido | Resultado | Evidência |
|---|---|---|---|---|---|---|
| 22 nulo | SQL Server | campo 1031/1/3 = `NULL`; 3 fluxos (900792 a 900794) vencidos; ciclo do Worker | tarefas desassociadas como no clássico, sem exceção | 3 desassociados às 16:56:56, 0 `ERROR`; 1 `OPCAO_TAREFA` e 2 logs (37/45, 47/45) por fluxo | PASSOU (observação investigativa) | log do Worker `20261110_InicioDesassociarAutomatico.log`; consultas de `TAREFA`, `OPCAO_TAREFA`, `LOG_APLICACAO` |
| 22 vazio | SQL Server | campo = `''`; fluxos 900797 e 900798 | idem | desassociados 17:02:26 | PASSOU | idem |
| 22 isolamento | SQL Server | fluxo 900796 travado; 900797 e 900798 no mesmo ciclo | demais processadas | processadas 17:02:26.06 a .13 | PASSOU | log do Worker |
| 22 nulo | Oracle | campo 543/1/1 = `NULL`; fluxos 2483 a 2485 | idem | desassociados 17:14:36 a 17:14:37, 0 `ERROR`; 1 `OPCAO_TAREFA` e 2 logs por fluxo | PASSOU (observação investigativa) | log do Worker; consultas Oracle. Oracle grava `''` como `NULL`: o caso vazio é o mesmo estado |
| 23 | SQL Server | lock de linha em `TAREFA` do fluxo 900796 (17:01:35 a 17:03:10); ciclo 17:01:55 | falha reagendável com `cd_fluxo` e `cd_tarefa` no log | `ERROR Erro na execução. Fluxo: 900796 \| Tarefa: 2.` 17:02:26; job 60882 `FalhaParaRepetir` (tentativa 1); nova tentativa 17:03:26 com sucesso; 1 `OPCAO_TAREFA`, sem duplicidade | PASSOU | log do Worker; saída do script de lock. Tentativa anterior (900795, lock de 70 s) descartada: lock soltou 29,4 s após o início, antes do timeout de 30 s, sem erro |
| 23 | Oracle | sem mecanismo de falha limpa (nulo corrigido; lock sem timeout trava o lote, observado em 05/11) | — | não executado | INCONCLUSIVO | `04-execucao-testes.md` do ciclo 161495 (tentativas de 05/11) |
| 1 | SQL Server | fluxo 900786, prazo 2 min vencido | tarefa desassociada | Worker 16:51:56 "Tarefa desassociada"; `cd_usuario`/`dt_inicio` nulos; `cd_responsavel=2`, `id_tipo_responsavel=2` | PASSOU | log do Worker; `TAREFA` |
| 1 | Oracle | fluxos 2482 a 2485 | idem | Worker 17:14:36; campos nulos, `cd_responsavel=2`, `id_tipo_responsavel=2` | PASSOU | idem |
| 2 | SQL Server | verificar efeitos em `TAREFA`, `OPCAO_TAREFA`, `LOG_APLICACAO` | `OPCAO_TAREFA` +1, 2 linhas de log | 900786: `OPCAO_TAREFA` +1 (16:51:56); logs 53963 (37/45) e 53964 (47/45) | PASSOU | consultas |
| 2 | Oracle | idem | idem | 2482 a 2485: 1 `OPCAO_TAREFA` e 2 logs cada | PASSOU | consultas |
| 17 | SQL Server | campo 3 (tipo 5) antes e depois | "usuário corrente" atualizado | 900786/2 campo 3: "Papel Responsável Papel Default" para "Papel Responsável Papel Principal dos Processos"; campo 4 mantido | PASSOU | `CAMPO_VALOR_TAREFA` |
| 17 | Oracle | idem (estado final) | idem | 2482/2 campo 3: "Papel Responsavel Papel Principal dos Processos"; campo 4 mantido | PASSOU COM RESSALVA | valor "antes" não foi lido no Oracle (ver divergências) |
| 25 | SQL Server | avançar (Concluir) e cancelar fluxo pela tela | sem regressão | avançar 900787: log 53952 "ExecutaTarefa.aspx - Avançar"; cancelar 900788: log 53956 "cancelado ... pelo Engine Clássico" | PASSOU COM RESSALVA | `LOG_APLICACAO`; ressalva: motor clássico (parâmetro 96 = 0), não a API net8 |
| 25 | Oracle | idem | idem | avançar 2486: logs 6012, 6013, 6014; cancelar 2487: log 6018 | PASSOU COM RESSALVA | idem |
| 26 | SQL Server | observar `ERROR` e jobs BPM na janela | sem interferência | jobs `AvancoTemporal`, `ExcluiFluxoEmSolicitacao`, `ExecutaPassoAplicacao`, `InicioTemporal`, `NotifyWf` rodaram; 0 `ERROR` do Scheduler; `ERROR` do Worker só os 2 do #23 e um `AvancoTemporal` job 60752 `Envenenado` (fluxo 900776, resíduo da US 161711, 16:46:56) | PASSOU COM RESSALVA | logs do Worker e Scheduler |
| 26 | Oracle | idem | idem | 0 `ERROR` desde 17:09; jobs 9, 18, 19 e 32 desativados na rodada (UPDATE autorizado), então não foram observados | PASSOU COM RESSALVA | logs do Worker |
| 24, 27 | ambos | exigem o Agent clássico | — | não executados | NÃO EXECUTADO | ver pendências |

Fluxos fora dos cenários: 900789 a 900791 (SQL Server; criados por job de início agendado, processos 1015 a 1017) e 2242, 2412 e 2413 (Oracle; fluxos antigos já elegíveis, desassociados no mesmo ciclo).

## Steps que pararam por ação de alto risco
Nenhum. O cancelar do #25 atingiu só fluxos de teste criados na rodada (900788 e 2487).

## Steps não executados (necessitam decisão humana)
- #24 e #27: precisam do Agent clássico (serviços Windows parados; `SmartShareAgent.exe` 3.88.0.26296 de 23/10, sem o fix do PR 29228). Aguardam OK do QA para subi-lo.
- #23 no Oracle: sem mecanismo; decisão do QA (aceita pela premissa registrada) é `INCONCLUSIVO`.

## Pendências e instruções para retomada
1. **#24 e #27.** Não executados porque o Agent clássico está parado e o instalado não tem o PR 29228. O QA precisa autorizar subir o Agent clássico (ou compilar o build do PR 29228). Retomar com `/arquitetura-executar-teste #166161 - Teste da correção do bug`; liberação: OK do QA e Agent clássico em execução.
2. **#23 no Oracle.** Sem mecanismo de falha limpa. Precisa de um mecanismo indicado pelo dev (o lock no Oracle não tem timeout). Liberação: mecanismo documentado.
3. **#17 e #22 no Oracle:** ressalvas do double-check (ver abaixo).
4. **Estado do ambiente:** Share, API, Scheduler e Worker ficaram apontados para Oracle (`SHAREGUIZAO`). Backups do estado SQL Server no scratchpad da sessão (`bak-sqlserver`; não versionado). Para voltar ao SQL Server: `QA-KB-20261106-001`.
5. **Comentário no Bug #166161 e anexo ao card Teste:** não gravados; aguardam aprovação do QA.

## Divergências do double-check
Sub-agente Sonnet independente, só sobre a evidência textual (nenhum screenshot nesta rodada).

| # | Classificação original | Sugestão do sub-agente | Motivo |
|---|---|---|---|
| 17 (Oracle) | PASSOU | PASSOU COM RESSALVA | o valor "antes" do campo 3 não foi lido no Oracle; só há o estado final |
| 22 | PASSOU (nos dois bancos) | PASSOU parcial: SQL PASSOU, Oracle PASSOU COM RESSALVA | isolamento provado só no SQL Server; no Oracle "vazio" e "nulo" são o mesmo estado; nulo só por `UPDATE` |

Os demais vereditos foram `CONFIRMADO`. Observações do sub-agente: #23 e #26 e #25 devem constar como lacunas de cobertura (falha induzida por lock, e não pelo erro de negócio; jobs desativados no Oracle; motor clássico no #25); não há log do `NullReferenceException` antes do fix no mesmo ambiente e massa desta rodada (a evidência anterior está em `04-execucao-testes.md` e nos comentários do Bug). A decisão sobre as duas divergências é do QA; as classificações originais foram mantidas na tabela acima, exceto o #17 no Oracle, que já está registrado como PASSOU COM RESSALVA.

## Estado restaurado ao fim
SQL Server: `JOB_CONFIG` 12 `Ativo=0`; `CAMPO_FORMULARIO` 1031/1/3 `[ds_usuario_corrente]`; lock com `ROLLBACK`. Oracle: `CAMPO_FORMULARIO` 543/1/1 `[ds_usuario_corrente]`; `JOB_CONFIG` Ids 8, 28, 29 e 24 `Ativo=1`; Id 12 `Ativo=1` (como estava). Worker BPM e Scheduler parados.
