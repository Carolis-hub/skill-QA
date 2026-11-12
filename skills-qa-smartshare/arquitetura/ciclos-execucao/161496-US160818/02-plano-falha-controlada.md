# Plano — falha controlada (Opção A) — US #160818 / CT-026, 027, 028, 031

**Status:** EXECUTADO e REVERTIDO em 2026-11-11 (autorizado pelo usuário). Resultado em `01-execucao-testes.md`.
**Banco:** Oracle `SHAREGUIZAO` (usuário `SHAREGUIZAO`, tem `CREATE TRIGGER`). SQL Server fica na outra sessão.
**RUN_ID:** 20261111-US160818-V01 (mesmo da rodada). **Classificação:** falha provocada por artifício (trigger). Divergência causada só pelo trigger não é defeito do produto (observação investigativa).

## Premissas lidas no código
- Item com erro: `try/catch (Exception)` por item, rollback do item, `_deuErro = true`, `LogError(ex, ..., cd_fluxo, cd_tarefa)` (`CalculoIndicadorService.cs:465-470`).
- Semeadura: 4 `TransferirParaIndicador` em sequência; erro propaga (`throw`) e aborta a execução (`CalculoIndicadorService.cs:106-109`; `FluxoIndicadorRepository.cs:254-258`). A 3ª é `INSERT INTO FLUXO_INDICADOR ... SELECT ... FROM FLUXO WHERE cd_fluxo NOT IN (SELECT cd_fluxo FROM FLUXO_INDICADOR)`.
- Gravação por item na região "Tarefa em execução": `UPDATE TAREFA_INDICADOR` (`TarefaIndicadorRepository.cs:103`).
- Triggers existentes nas 4 tabelas de indicador (`TRG_TAREFA_INDICADOR`, `TRG_FLUXO_INDICADOR`, `TRG_HISTORICO_TAREFA_INDICADOR`, `TRG_HISTORICO_FLUXO_INDICADOR`): **não serão alterados**; os novos têm nome próprio.

## Fase 1 — CT-026, 027, 031 (erro por item)
Massa: fluxos de teste 2522 e 2523 (tarefa 2 em andamento, normais) e **2527 (tarefa 2) = alvo da falha**. Mais as demais tarefas em andamento do ambiente.

| # | Escrita | Detalhe | Rollback |
|---|---|---|---|
| A1 | `CREATE OR REPLACE TRIGGER QA160818_FALHA_TI BEFORE UPDATE ON TAREFA_INDICADOR FOR EACH ROW WHEN (NEW.CD_FLUXO = 2527) BEGIN RAISE_APPLICATION_ERROR(-20999, 'QA US160818 falha provocada CT-026'); END;` | DDL; só o fluxo 2527; nenhum dado alterado | `DROP TRIGGER QA160818_FALHA_TI` |

Execução: snapshot de `TAREFA_INDICADOR` (2522, 2523, 2527) → subir Scheduler + Worker net8 (`ATIVO=1`, clássico pula) → esperar 1 ciclo concluído → parar → conferir.
Esperado:
- CT-026: net8 recalcula 2522 e 2523 (valores sobem); 2527 inalterado (rollback do item); outras tarefas processadas; `DeuErro`.
- CT-027: log traz erro completo (tipo, mensagem `ORA-20999 ... QA US160818`, stack, `cd_fluxo=2527`, `cd_tarefa=2`).
- CT-031: logs dos outros jobs (`InicioPublicacao`, `ExecutaSql`, `ExecutaPassoAplicacao`) seguem no mesmo período, sem erro desses jobs.
Reversão da fase 1: `DROP TRIGGER QA160818_FALHA_TI` + conferir `all_triggers` (devem restar só os 4 `TRG_*` originais).

## Fase 2 — CT-028 (falha na semeadura)
| # | Escrita | Detalhe | Rollback |
|---|---|---|---|
| B1 | Backup da linha e `DELETE FROM FLUXO_INDICADOR WHERE CD_FLUXO = 2528` | 1 linha, fluxo de teste (CT-013). Faz a 3ª semeadura tentar reinserir | `INSERT` da linha guardada (valores salvos antes), ou deixar o net8 recriar após o `DROP` e conferir contra o backup |
| B2 | `CREATE OR REPLACE TRIGGER QA160818_FALHA_FI BEFORE INSERT ON FLUXO_INDICADOR FOR EACH ROW WHEN (NEW.CD_FLUXO = 2528) BEGIN RAISE_APPLICATION_ERROR(-20998, 'QA US160818 falha provocada CT-028'); END;` | DDL; só o fluxo 2528 | `DROP TRIGGER QA160818_FALHA_FI` |

Esperado: execução abortada inteira, erro completo no log, nenhuma região de cálculo executada nesse ciclo (sem linha `Qtd1..Qtd5`; `dt_ultimaverificacao`/`vl_tempototal` das tarefas em andamento inalterados). Observação: as semeaduras 1 e 2 já terão commitado (transações separadas).
Reversão da fase 2: `DROP TRIGGER QA160818_FALHA_FI`, restaurar a linha de `FLUXO_INDICADOR` do 2528, conferir `all_triggers`.

## Reversão final do ambiente (Oracle) — o que a rodada criou ou mudou
Conferir cada item por leitura antes e depois. Itens de ② precisam de decisão sua.

① Reverter sempre (mudei por SQL ou por tela, com valor original guardado):
1. Triggers `QA160818_FALHA_TI` e `QA160818_FALHA_FI`: `DROP`.
2. `FLUXO_INDICADOR` do 2528: restaurada (fase 2).
3. `JOB_CONFIG` Id 9: já em `ATIVO=1` (original); reconferir no fim.
4. Workers net8 parados (`SmartShareAgent_BpmWorker`, `SmartShareAgent_SchedulerWorker` do repo); `STATUS_AGENT` 16 com `st_executando=0`.
5. `HISTORICO_TAREFA` 2486/2: já com `dt_termino` original (2026-11-10 17:11:25).

② Criado por mim nesta rodada, a remover para voltar ao estado de antes (confirmar):
6. `DATA_DESTAQUE` 101 e 102 (hoje 1904-11-03/04): `DELETE` pelo id.
7. `CONTROLE_PASSO_PARALELO` do processo 621: hoje 8 linhas recriadas pelo cálculo; antes da rodada eram 0 (não classificado). `DELETE` devolve o estado original; o próximo ciclo normal do net8 reclassifica sozinho.
8. `PROCESSO` 541 e 621 (versão 1): `cd_calendario` 3 → 1 (valor original). Reverter **antes** de apagar o `CAL_QA`.
9. `PERIODO` 101 e `CALENDARIO` 3 (`CAL_QA`): `DELETE` depois do item 8.
10. Processo 641 "QA-160818 PROC_CALC" (rascunho, sem fluxo): descartar pela tela ("Cancelar Criação").
11. Fluxos de teste 2522–2531 (criados pela tela): excluir pelo Share ("Excluir fluxo") ou deixar. Apagar por SQL em muitas tabelas é arriscado; recomendo a tela, ou manter como massa de teste documentada.

③ Não reverto (efeito normal do job, não é massa minha): `TAREFA_INDICADOR`/`FLUXO_INDICADOR` das outras ~290 tarefas em andamento, `STATUS_AGENT`, `JOB_BPM`, arquivos de log, binários do Scheduler/Worker recompilados (estavam desatualizados).

④ Fora do Oracle / fora do meu escopo: SQL Server (outra sessão: `CAL_QA` cd 5, `PERIODO` 3, feriados 2 e 3, processos 1030 e 10, `HISTORICO_TAREFA` 900787/2); serviço `SmartShareAgent` clássico (você decide se para); rotação das senhas que apareceram na saída (root de teste, SQL Server, Oracle, `qa.usuario2`, `qa.usuario3`).

## Autorizações pedidas
- Fase 1: A1 (CREATE + DROP do trigger no SHAREGUIZAO).
- Fase 2: B1 (DELETE de 1 linha de `FLUXO_INDICADOR`, com backup) e B2 (CREATE + DROP do trigger).
- Reversão final: itens 6, 7, 8, 9 (DELETE/UPDATE na massa de teste), mais a decisão sobre 10 e 11.
