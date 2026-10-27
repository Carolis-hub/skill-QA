-- US 164251 — restauração do JOB_CONFIG alterado em 17-jobconfig-alteracao.sql.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRAN;
UPDATE JOB_CONFIG SET Ativo = 0 WHERE Modulo = 1 AND Job = 19;
UPDATE JOB_CONFIG SET Max_Paralelo = 1 WHERE Modulo = 1 AND Job = 9;
COMMIT;
SELECT Job, Ativo, Max_Paralelo, Interval_Ms FROM JOB_CONFIG WHERE Modulo = 1 AND Job IN (9, 19) ORDER BY Job;
