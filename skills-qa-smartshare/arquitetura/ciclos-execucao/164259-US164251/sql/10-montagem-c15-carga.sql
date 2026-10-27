-- US 164251 — cenário #15, segunda tentativa: 600 itens travados para forçar sobreposição das duas instâncias.
-- A instância 1 roda o ciclo no segundo :02 e a instância 2 no :12. Com ~29 itens/s, a instância 1 leva ~20 s
-- para varrer 600 itens, e a instância 2 entra na mesma lista no meio da varredura.
-- Ambiente: NOTE-74VQ\SQLEXPRESS / ShareGuizao (QA local). Status 3: o Worker só move para o JOB_DUMP, nunca executa.
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @agora datetime = GETDATE();
BEGIN TRAN;
;WITH n AS (SELECT TOP (600) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i FROM sys.all_objects a CROSS JOIN sys.all_objects b)
INSERT INTO JOB_BPM (Modulo, Job, Hash_Argumentos, Chave_Unica, Data_Programada, Job_Status_Id, Qt_de_Tentativas, Ultimo_Erro, Chave_Concorrencia, Data_Criacao, Data_Atualizacao, Lock_Id, Lock_Expira_Em)
SELECT 1, 8, '{"qa":"us164251-c15b"}', 'qa-us164251-c15b-' + RIGHT('000' + CAST(i AS varchar(3)), 3), DATEADD(MINUTE,-10,@agora), 3, 0, NULL, 'qa-us164251-c15b', DATEADD(MINUTE,-10,@agora), DATEADD(MINUTE,-5,@agora), NULL, NULL
FROM n;
COMMIT;
SELECT COUNT(*) AS criadas, MIN(Id) AS de, MAX(Id) AS ate, CONVERT(varchar(23), @agora, 121) AS montado_em
FROM JOB_BPM WHERE Chave_Unica LIKE 'qa-us164251-c15b-%';
