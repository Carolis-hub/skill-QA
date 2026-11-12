# Reteste Modo B — Bug #166161 — parcial SQL Server (10/11/2026)

**Build:** net8 `6b23a794` (fix), Worker BPM e Scheduler recompilados 10/11 16:41, subidos 16:44 (`Iniciando worker/Bpm dbo`).
**Banco:** SQL Server `NOTE-74VQ\SQLEXPRESS` / `ShareGuizao` / `dbo`. Parâmetro 96 = 0 (motor clássico para iniciar/avançar/cancelar fluxo).
**Massa:** processo 1031 v1 (passo 3, papel, 2 min), campo 3 tipo 5.
**Escritas autorizadas executadas:** W1 `JOB_CONFIG` 12 `Ativo` 0→1 (restaurado a 0 às ~17:06); W2 `CAMPO_FORMULARIO` 1031/1/3 `NULL` (16:52:35) e `''` (16:57:57), restaurado a `[ds_usuario_corrente]` (17:04); W4 lock de linha em `TAREFA` (900795/2 das 16:56:15 a 16:57:25; 900796/2 das 17:01:35 a 17:03:10), sem alterar dado, `ROLLBACK`.

| # | Resultado (SQL Server) | Evidência |
|---|---|---|
| 1 | PASSOU | fluxo 900786, tarefa 2: Worker 16:51:56 "Tarefa desassociada"; `cd_usuario` e `dt_inicio` nulos; `cd_responsavel=2`, `id_tipo_responsavel=2` |
| 2 | PASSOU | `OPCAO_TAREFA` +1 (16:51:56); `LOG_APLICACAO` 53963 (37/45) e 53964 (47/45) |
| 3 (log) | PASSOU | linhas "Tarefa desassociada. Fluxo: N \| Tarefa: 2." no log do Worker |
| 17 | PASSOU | `CAMPO_VALOR_TAREFA` do 900786/2 campo 3: "Papel Responsável Papel Default" → "Papel Responsável Papel Principal dos Processos" |
| 22 nulo (observação investigativa, condição criada por `UPDATE`) | PASSOU com o fix | 900792, 900793, 900794 desassociados no ciclo 16:56:55 (sem `NullReferenceException`; antes: `FalhaParaRepetir` em 05/11 e 06/11); cada um com 1 `OPCAO_TAREFA` e 2 logs |
| 22 vazio (`''`) | PASSOU | 900797 e 900798 desassociados 17:02:26 |
| 22 isolamento | PASSOU | com o 900796 travado, 900797 e 900798 foram processados em seguida (17:02:26.06 a .13) |
| 23 | PASSOU | 900796: ciclo 17:01:55; lock; `ERROR Erro na execução. Fluxo: 900796 \| Tarefa: 2.` 17:02:26; job 60882 `FalhaParaRepetir` (tentativa 1); nova tentativa 17:03:26 com sucesso; 1 `OPCAO_TAREFA`; sem duplicidade. Primeira tentativa (900795, lock de 70 s) não gerou erro: o lock soltou 29,4 s após o início, antes do timeout de 30 s |
| 25 | PASSOU COM RESSALVA | avançar: fluxo 900787, log 53952 "ExecutaTarefa.aspx - Avançar"; cancelar: fluxo 900788, log 53956 "cancelado ... pelo Engine Clássico". Ressalva: motor clássico (parâmetro 96 = 0), não a API net8 |
| 26 | PASSOU COM RESSALVA | jobs `AvancoTemporal`, `ExcluiFluxoEmSolicitacao`, `ExecutaPassoAplicacao`, `InicioTemporal`, `NotifyWf` rodaram. Único `ERROR` fora do #23: `AvancoTemporal` job 60752 (fluxo 900776, passo 17) `Envenenado` após 5 tentativas, resíduo da US 161711; Scheduler sem `ERROR` |
| 24, 27 | NÃO EXECUTADOS (pendente) | exigem iniciar o Agent clássico (serviços Windows parados; `SmartShareAgent.exe` 3.88.0.26296 de 23/10, sem PR 29228). Aguarda OK do QA |

Fluxos que não são meus e apareceram no período: 900789 a 900791 (processos 1015 a 1017, criados por job de início agendado às 16:51:55).
