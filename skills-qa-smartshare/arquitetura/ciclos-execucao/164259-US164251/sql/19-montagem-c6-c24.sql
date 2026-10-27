-- US 164251 — montagem dos cenários #6 e #24 (autorizada pelo usuário no chat em 2026-10-26).
-- #6: item travado (status 3, 5 min) no job 19 (ExecutaSql) -> deve ser movido para o JOB_DUMP.
-- #24: 12 itens Agendados no job 9 (NotifyWf, passo 8 NotificarMensagemExcecaoAlcada, sem efeito colateral),
--      cada um com chave e chave de concorrência próprias, para as 2 instâncias do job 9 disputarem.
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @agora datetime = GETDATE();
BEGIN TRAN;
INSERT INTO JOB_BPM (Modulo, Job, Hash_Argumentos, Chave_Unica, Data_Programada, Job_Status_Id, Qt_de_Tentativas, Ultimo_Erro, Chave_Concorrencia, Data_Criacao, Data_Atualizacao, Lock_Id, Lock_Expira_Em)
VALUES (1, 19, '{"qa":"us164251-c6"}', 'qa-us164251-c6-executasql-travado', DATEADD(MINUTE,-10,@agora), 3, 0, NULL, 'qa-us164251-c6', DATEADD(MINUTE,-10,@agora), DATEADD(MINUTE,-5,@agora), NULL, NULL);
;WITH n AS (SELECT TOP (12) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i FROM sys.all_objects)
INSERT INTO JOB_BPM (Modulo, Job, Hash_Argumentos, Chave_Unica, Data_Programada, Job_Status_Id, Qt_de_Tentativas, Ultimo_Erro, Chave_Concorrencia, Data_Criacao, Data_Atualizacao, Lock_Id, Lock_Expira_Em)
SELECT 1, 9, '{"NotifyStep":8}', 'qa-us164251-c24-' + RIGHT('0' + CAST(i AS varchar(2)), 2), DATEADD(MINUTE,-1,@agora), 1, 0, NULL, 'qa-us164251-c24-' + RIGHT('0' + CAST(i AS varchar(2)), 2), @agora, @agora, NULL, NULL
FROM n;
COMMIT;
SELECT Job, COUNT(*) AS criadas, MIN(Id) AS de, MAX(Id) AS ate FROM JOB_BPM WHERE Chave_Unica LIKE 'qa-us164251-c6-%' OR Chave_Unica LIKE 'qa-us164251-c24-%' GROUP BY Job;
