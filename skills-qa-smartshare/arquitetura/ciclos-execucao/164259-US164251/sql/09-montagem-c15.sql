-- US 164251 — cenário #15 (duas instâncias do Worker disputando os mesmos itens travados)
-- Ambiente: NOTE-74VQ\SQLEXPRESS / ShareGuizao (QA local). Autorizado pelo usuário no chat em 2026-10-26.
-- 30 linhas do job 8 (AvancoTemporal), status 3, paradas há 5 min, sem lock.
-- Status final: o Worker nunca executa essas linhas, só move para o JOB_DUMP.
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @agora datetime = GETDATE();
BEGIN TRAN;
;WITH n AS (SELECT TOP (30) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i FROM sys.all_objects)
INSERT INTO JOB_BPM (Modulo, Job, Hash_Argumentos, Chave_Unica, Data_Programada, Job_Status_Id, Qt_de_Tentativas, Ultimo_Erro, Chave_Concorrencia, Data_Criacao, Data_Atualizacao, Lock_Id, Lock_Expira_Em)
SELECT 1, 8, '{"qa":"us164251-c15"}', 'qa-us164251-c15-' + RIGHT('00' + CAST(i AS varchar(2)), 2), DATEADD(MINUTE,-10,@agora), 3, 0, NULL, 'qa-us164251-c15', DATEADD(MINUTE,-10,@agora), DATEADD(MINUTE,-5,@agora), NULL, NULL
FROM n;
COMMIT;
SELECT COUNT(*) AS criadas, MIN(Id) AS de, MAX(Id) AS ate, CONVERT(varchar(23), @agora, 121) AS montado_em
FROM JOB_BPM WHERE Chave_Unica LIKE 'qa-us164251-c15-%';
