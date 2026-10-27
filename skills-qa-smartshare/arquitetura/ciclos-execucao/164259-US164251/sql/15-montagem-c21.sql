-- US 164251 — cenário #21: falha até esgotar as tentativas termina em Envenenado.
-- Job 8 (AvancoTemporal), item Agendado apontando para o fluxo inexistente 999999 (maior fluxo da base: 900558).
-- Começa com 3 tentativas (Max_Tentativas = 5, backoff linear 60 s × tentativa):
--   falha 1 -> 4 tentativas, FalhaParaRepetir, retry em 240 s; falha 2 -> 5 tentativas -> Envenenado + JOB_DUMP.
-- Ambiente: NOTE-74VQ\SQLEXPRESS / ShareGuizao (QA local). Autorizado pelo usuário no chat em 2026-10-26.
SET NOCOUNT ON;
DECLARE @agora datetime = GETDATE();
INSERT INTO JOB_BPM (Modulo, Job, Hash_Argumentos, Chave_Unica, Data_Programada, Job_Status_Id, Qt_de_Tentativas, Ultimo_Erro, Chave_Concorrencia, Data_Criacao, Data_Atualizacao, Lock_Id, Lock_Expira_Em)
VALUES (1, 8, '{"AvancoTemporalStep":2,"cd_fluxo":999999,"cd_tarefa":1,"cd_passo":1}', 'qa-us164251-c21-fluxo-inexistente', DATEADD(MINUTE,-1,@agora), 1, 3, NULL, 'qa-us164251-c21', DATEADD(MINUTE,-2,@agora), DATEADD(MINUTE,-2,@agora), NULL, NULL);
SELECT CAST(SCOPE_IDENTITY() AS bigint) AS Id, CONVERT(varchar(23), @agora, 121) AS montado_em;
