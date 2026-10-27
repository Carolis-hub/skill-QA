-- US 164251 — cenários #22 e #1 (job 32, EnviaAlertaFluxo). Autorizado pelo usuário no chat em 2026-10-26,
-- ciente de que o job vai enviar alertas reais (16 alertas de fluxo vencidos) com a configuração de e-mail atual.
-- Original do job 32: Schedule_Type=2, Interval_Ms=0, Cron_Expression='0 0 0 * * ?' (restauração em 23-c22-restauracao-job32.sql).
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @agora datetime = GETDATE();
BEGIN TRAN;
-- #1: item travado com Sucesso (3) no EnviaAlertaFluxo, chave própria para não bloquear o agendamento real.
INSERT INTO JOB_BPM (Modulo, Job, Hash_Argumentos, Chave_Unica, Data_Programada, Job_Status_Id, Qt_de_Tentativas, Ultimo_Erro, Chave_Concorrencia, Data_Criacao, Data_Atualizacao, Lock_Id, Lock_Expira_Em)
VALUES (1, 32, '{"job":"EnviaAlertaFluxo","qa":"us164251-c1"}', 'qa-us164251-c1-enviaalerta-sucesso', DATEADD(MINUTE,-10,@agora), 3, 0, NULL, 'qa-us164251-c1', DATEADD(MINUTE,-10,@agora), DATEADD(MINUTE,-5,@agora), NULL, NULL);
SELECT CAST(SCOPE_IDENTITY() AS bigint) AS id_c1;
-- #22: job 32 passa a rodar a cada 60 s.
UPDATE JOB_CONFIG SET Schedule_Type = 1, Interval_Ms = 60000, Cron_Expression = NULL
WHERE Modulo = 1 AND Job = 32 AND Schedule_Type = 2 AND Cron_Expression = '0 0 0 * * ?';
SELECT @@ROWCOUNT AS job32_alterado;
COMMIT;
SELECT Job, Ativo, Schedule_Type, Interval_Ms, Cron_Expression FROM JOB_CONFIG WHERE Modulo = 1 AND Job = 32;
