-- US 164251 — cenários #6 e #24: alteração temporária do JOB_CONFIG (autorizada pelo usuário no chat em 2026-10-26).
-- Valores originais (lidos antes da alteração, também salvos em 17-jobconfig-backup.txt):
--   job 9  (NotifyWf):   Ativo=1, Max_Paralelo=1
--   job 19 (ExecutaSql): Ativo=0, Max_Paralelo=2
-- Restauração em 20-jobconfig-restauracao.sql.
-- Ativar o job 19 é seguro neste ambiente: a consulta de pendências de ExecutaSql retorna 0 (nenhum SQL real seria executado).
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRAN;
UPDATE JOB_CONFIG SET Ativo = 1 WHERE Modulo = 1 AND Job = 19 AND Ativo = 0;
SELECT @@ROWCOUNT AS job19_ativado;
UPDATE JOB_CONFIG SET Max_Paralelo = 2 WHERE Modulo = 1 AND Job = 9 AND Max_Paralelo = 1;
SELECT @@ROWCOUNT AS job9_paralelo_2;
COMMIT;
SELECT Job, Ativo, Max_Paralelo, Interval_Ms FROM JOB_CONFIG WHERE Modulo = 1 AND Job IN (9, 19) ORDER BY Job;
