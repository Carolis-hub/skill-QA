-- US 164251 — restauração do job 32 (EnviaAlertaFluxo) para o cron original da meia-noite.
SET NOCOUNT ON;
UPDATE JOB_CONFIG SET Schedule_Type = 2, Interval_Ms = 0, Cron_Expression = '0 0 0 * * ?' WHERE Modulo = 1 AND Job = 32;
SELECT Job, Ativo, Schedule_Type, Interval_Ms, Cron_Expression FROM JOB_CONFIG WHERE Modulo = 1 AND Job = 32;
