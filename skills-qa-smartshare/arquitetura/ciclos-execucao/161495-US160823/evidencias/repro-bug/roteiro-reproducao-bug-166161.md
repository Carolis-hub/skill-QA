# Reprodução passo a passo do Bug #166161 (SQL Server, 06/11/2026)

Reprodução feita pela tela do Share clássico, com os Workers da branch `feature/US160823-migracao-job-inicio-desassociar-automatico` (commit `ab180c0f`). Banco: SQL Server `ShareGuizao` (`dbo`).

## Processo usado

- Processo **1031 "QA-161495 Formulario"** (SQL Server), versão publicada.
- Atividade (passo 3) **"F1 Papel 2min Form"**: executor = papel 2 (`id_tipo_executor = 1`), "Tempo total para desassociar" = 2 min.
- Formulário com o campo **3 "Usuario corrente (prop)"** — tipo de valor 5 (Propriedade do Processo), `ds_valor_inicial = NULL`.
- Equivalente ao processo 543 do Oracle, exportado em `../processo-543-QA-161495-Form2-export.zip` (anexo do Bug).

## Preparação (banco, uma vez)

Valores originais anotados para restaurar: campo 1031/3 = `[ds_usuario_corrente]`, `JOB_CONFIG` Id 12 `Ativo` = 0, parâmetro 96 = 1.

```sql
UPDATE CAMPO_FORMULARIO SET ds_valor_inicial = NULL WHERE cd_processo = 1031 AND cd_campo = 3;
UPDATE JOB_CONFIG SET Ativo = 1 WHERE id = 12;          -- lido na partida dos Workers
UPDATE PARAMETRO SET ds_valor = '0' WHERE cd_parametro = 96;  -- motor clássico (sem API do Engine)
```

Subir `SmartShareAgent_SchedulerWorker.exe` e `SmartShareAgent_BpmWorker.exe` (`bin\Debug\net8.0` do net8, `DBType` SQLServer).

## Passos

| # | Ação (pela tela) | Resultado | Evidência |
|---|---|---|---|
| 1 | Abrir `http://localhost:58149/SmartShare/index.aspx` e entrar como `root` | Portal "Olá Administrador" | `passo-01-login.png` |
| 2 | Iniciar o fluxo do processo 1031 (`Workflow/IniciaFluxo.aspx?CDPROC=1031`) às 21:20:54 | Fluxo **900749** criado; abre a tarefa "F1 Papel 2min Form" com o campo "Usuario corrente (prop)" **vazio** | `passo-02-fluxo-iniciado.png` |
| 3 | Deixar a tarefa associada ao root e esperar 2 min + ciclo do Scheduler (5 min) | 21:23:2x: Scheduler enfileira o job **60105** (`JOB_BPM`, módulo 1, job 34) com status 1 | consulta `JOB_BPM` abaixo |
| 4 | Esperar o ciclo do Worker BPM (21:25:44) | Job vai para status **4 (FalhaParaRepetir)**, 1 tentativa. Log do Worker: `System.NullReferenceException` em `FluxoService.AtualizarValoresCorrenteCampoFormularioDaTarefa` (`FluxoService.cs:7749`), chamada por `DesassociarFluxo` | `passo-04-log-worker-nullreference.png` |
| 5 | Voltar ao portal (Minhas Atividades) | A tarefa de 21:20 **continua** na lista do usuário (não foi desassociada) | `passo-05-tarefa-continua-associada.png` |

Consultas de conferência (SQL Server):

```sql
SELECT Id, Job_Status_Id, Qt_de_Tentativas, LEFT(Ultimo_Erro,120) FROM JOB_BPM WHERE Id = 60105;   -- 4, 1, NullReferenceException
SELECT cd_tarefa, cd_usuario, dt_termino FROM TAREFA WHERE cd_fluxo = 900749 AND cd_tarefa = 2;    -- cd_usuario = 1 (ainda associada)
```

Resultado esperado correto (sem o bug): job em status 3 e tarefa 2 desassociada (`cd_usuario` nulo).

## Causa

`item.ds_valor_inicial.ToLower()` com `ds_valor_inicial` nulo (`FluxoService.cs:7749`, também 8002). O clássico trata nulo como texto vazio.

## Observações

- A tela do Share não grava nulo (grava `[ds_usuario_solicitante]`); o nulo vem do `UPDATE` do passo de preparação. Origem real do nulo em produção não confirmada.
- Com o parâmetro 96 = 1 é preciso API + nginx; com 96 = 0 não. Ver `../como-reproduzir-bug-166161.md`.
- Passos 3 e 4 também mostram jobs de outras tarefas antigas do processo 1031 falhando pelo mesmo motivo (o campo ficou nulo para todas).

## Restauração (feita ao final)

Campo 1031/3 = `[ds_usuario_corrente]`, `Ativo` = 0, parâmetro 96 = 1; Workers parados. O fluxo 900749 e os jobs de teste ficaram no banco (nenhum DELETE).
