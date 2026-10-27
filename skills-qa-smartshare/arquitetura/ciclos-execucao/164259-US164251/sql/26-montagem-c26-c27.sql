-- US 164251 — montagem dos cenários #26 e #27 (hipóteses, referência: Agent legado — etapa 12)
-- Ambiente: NOTE-74VQ\SQLEXPRESS / ShareGuizao (QA local). NÃO rodar em HMG/produção.
-- Todas as linhas têm Chave_Unica iniciando com 'qa-us164251-' para rastrear e limpar.

SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRAN;

DECLARE @agora datetime = GETDATE();
DECLARE @ids TABLE (cenario varchar(10), Id bigint);

-- #26 Três linhas travadas do MESMO job (8, AvancoTemporal, ciclo de 60 s), status 3, 5 e 6,
-- paradas há 5 min e sem lock. Esperado (legado): as 3 movidas no mesmo ciclo.
INSERT INTO JOB_BPM (Modulo, Job, Hash_Argumentos, Chave_Unica, Data_Programada, Job_Status_Id, Qt_de_Tentativas, Ultimo_Erro, Chave_Concorrencia, Data_Criacao, Data_Atualizacao, Lock_Id, Lock_Expira_Em)
OUTPUT '#26-s3', inserted.Id INTO @ids
VALUES (1, 8, '{"qa":"us164251-c26-s3"}', 'qa-us164251-c26-sucesso', DATEADD(MINUTE,-10,@agora), 3, 0, NULL, 'qa-us164251-c26-s3', DATEADD(MINUTE,-10,@agora), DATEADD(MINUTE,-5,@agora), NULL, NULL);

INSERT INTO JOB_BPM (Modulo, Job, Hash_Argumentos, Chave_Unica, Data_Programada, Job_Status_Id, Qt_de_Tentativas, Ultimo_Erro, Chave_Concorrencia, Data_Criacao, Data_Atualizacao, Lock_Id, Lock_Expira_Em)
OUTPUT '#26-s5', inserted.Id INTO @ids
VALUES (1, 8, '{"qa":"us164251-c26-s5"}', 'qa-us164251-c26-envenenado', DATEADD(MINUTE,-10,@agora), 5, 5, 'qa: erro simulado', 'qa-us164251-c26-s5', DATEADD(MINUTE,-10,@agora), DATEADD(MINUTE,-5,@agora), NULL, NULL);

INSERT INTO JOB_BPM (Modulo, Job, Hash_Argumentos, Chave_Unica, Data_Programada, Job_Status_Id, Qt_de_Tentativas, Ultimo_Erro, Chave_Concorrencia, Data_Criacao, Data_Atualizacao, Lock_Id, Lock_Expira_Em)
OUTPUT '#26-s6', inserted.Id INTO @ids
VALUES (1, 8, '{"qa":"us164251-c26-s6"}', 'qa-us164251-c26-cancelado', DATEADD(MINUTE,-10,@agora), 6, 0, NULL, 'qa-us164251-c26-s6', DATEADD(MINUTE,-10,@agora), DATEADD(MINUTE,-5,@agora), NULL, NULL);

-- #27 Status final (3) com Data_Atualizacao NULL, sem lock, no job 9 (NotifyWf, ciclo de 60 s).
-- Esperado (inferido do legado): não travar para sempre -> ser movida. Provável pelo código novo: nunca é pega.
INSERT INTO JOB_BPM (Modulo, Job, Hash_Argumentos, Chave_Unica, Data_Programada, Job_Status_Id, Qt_de_Tentativas, Ultimo_Erro, Chave_Concorrencia, Data_Criacao, Data_Atualizacao, Lock_Id, Lock_Expira_Em)
OUTPUT '#27', inserted.Id INTO @ids
VALUES (1, 9, '{"qa":"us164251-c27"}', 'qa-us164251-c27-data-nula', DATEADD(MINUTE,-10,@agora), 3, 0, NULL, 'qa-us164251-c27', DATEADD(MINUTE,-10,@agora), NULL, NULL, NULL);

COMMIT;

SELECT i.cenario, i.Id, @agora AS montado_em FROM @ids i ORDER BY i.Id;
