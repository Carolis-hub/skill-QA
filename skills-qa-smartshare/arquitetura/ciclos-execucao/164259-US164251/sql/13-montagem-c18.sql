-- US 164251 — cenário #18: item em FalhaParaRepetir (4) dentro do limite de tentativas continua sendo reprocessado
-- e não é tratado como travado pela busca nova.
-- Job 9 (NotifyWf), passo NotificarMensagemExcecaoAlcada (NotifyStep 8), o mesmo que o Scheduler agenda a cada minuto.
-- Chave própria (qa-us164251-c18) para não bloquear o agendamento real.
-- Ambiente: NOTE-74VQ\SQLEXPRESS / ShareGuizao (QA local). Autorizado pelo usuário no chat em 2026-10-26.
SET NOCOUNT ON;
DECLARE @agora datetime = GETDATE();
INSERT INTO JOB_BPM (Modulo, Job, Hash_Argumentos, Chave_Unica, Data_Programada, Job_Status_Id, Qt_de_Tentativas, Ultimo_Erro, Chave_Concorrencia, Data_Criacao, Data_Atualizacao, Lock_Id, Lock_Expira_Em)
VALUES (1, 9, '{"NotifyStep":8}', 'qa-us164251-c18-falha-para-repetir', DATEADD(MINUTE,-1,@agora), 4, 1, 'qa: falha anterior simulada', 'qa-us164251-c18', DATEADD(MINUTE,-5,@agora), DATEADD(MINUTE,-2,@agora), NULL, NULL);
SELECT CAST(SCOPE_IDENTITY() AS bigint) AS Id, CONVERT(varchar(23), @agora, 121) AS montado_em;
