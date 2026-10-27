-- US 164251 — montagem dos cenários que exigem escrita
-- Ambiente: NOTE-74VQ\SQLEXPRESS / ShareGuizao (QA local). NÃO rodar em HMG/produção.
-- Todas as linhas criadas têm Chave_Unica iniciando com 'qa-us164251-' para rastrear e limpar.
-- Jobs usados: 8 (AvancoTemporal) e 9 (NotifyWf), ativos com ciclo de 60 s.
-- Linhas com status final (3/5) nunca são executadas pelo Worker: ele só move para o JOB_DUMP.

SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRAN;

DECLARE @agora datetime = GETDATE();
DECLARE @ids TABLE (cenario varchar(10), Id bigint);

-- #2 Item travado com Envenenado (5), parado há 5 min, sem lock -> deve ser movido no próximo ciclo do job 8
INSERT INTO JOB_BPM (Modulo, Job, Hash_Argumentos, Chave_Unica, Data_Programada, Job_Status_Id, Qt_de_Tentativas, Ultimo_Erro, Chave_Concorrencia, Data_Criacao, Data_Atualizacao, Lock_Id, Lock_Expira_Em)
OUTPUT '#2', inserted.Id INTO @ids
VALUES (1, 8, '{"qa":"us164251-c2"}', 'qa-us164251-c2-envenenado', DATEADD(MINUTE,-10,@agora), 5, 5, 'qa: erro simulado', 'qa-us164251-c2', DATEADD(MINUTE,-10,@agora), DATEADD(MINUTE,-5,@agora), NULL, NULL);

-- #8/#9 Item recém-finalizado com Sucesso (3): Data_Atualizacao = agora.
-- Esperado: ignorado nos ciclos com menos de 60 s; movido no primeiro ciclo depois de 60 s.
INSERT INTO JOB_BPM (Modulo, Job, Hash_Argumentos, Chave_Unica, Data_Programada, Job_Status_Id, Qt_de_Tentativas, Ultimo_Erro, Chave_Concorrencia, Data_Criacao, Data_Atualizacao, Lock_Id, Lock_Expira_Em)
OUTPUT '#8/#9', inserted.Id INTO @ids
VALUES (1, 9, '{"qa":"us164251-c8"}', 'qa-us164251-c8-recem-finalizado', @agora, 3, 0, NULL, 'qa-us164251-c8', @agora, @agora, NULL, NULL);

-- #10 Status final (3) parado há 5 min, mas com lock válido por mais 3 min.
-- Esperado: não é movido enquanto o lock vale; movido no primeiro ciclo depois de Lock_Expira_Em.
INSERT INTO JOB_BPM (Modulo, Job, Hash_Argumentos, Chave_Unica, Data_Programada, Job_Status_Id, Qt_de_Tentativas, Ultimo_Erro, Chave_Concorrencia, Data_Criacao, Data_Atualizacao, Lock_Id, Lock_Expira_Em)
OUTPUT '#10', inserted.Id INTO @ids
VALUES (1, 8, '{"qa":"us164251-c10"}', 'qa-us164251-c10-lock-valido', DATEADD(MINUTE,-10,@agora), 3, 0, NULL, 'qa-us164251-c10', DATEADD(MINUTE,-10,@agora), DATEADD(MINUTE,-5,@agora), NEWID(), DATEADD(MINUTE,3,@agora));

-- #14 Linha travada (3) que JÁ tem registro no JOB_DUMP (mesmo Id_Origem/Modulo/Job).
-- Esperado: a linha sai do JOB_BPM, continua 1 único dump, log "ja tinha sido movido para JOB_DUMP".
INSERT INTO JOB_BPM (Modulo, Job, Hash_Argumentos, Chave_Unica, Data_Programada, Job_Status_Id, Qt_de_Tentativas, Ultimo_Erro, Chave_Concorrencia, Data_Criacao, Data_Atualizacao, Lock_Id, Lock_Expira_Em)
OUTPUT '#14', inserted.Id INTO @ids
VALUES (1, 9, '{"qa":"us164251-c14"}', 'qa-us164251-c14-ja-no-dump', DATEADD(MINUTE,-10,@agora), 3, 0, NULL, 'qa-us164251-c14', DATEADD(MINUTE,-10,@agora), DATEADD(MINUTE,-5,@agora), NULL, NULL);

INSERT INTO JOB_DUMP (Modulo, Job, Id_Origem, Hash_Argumentos, Chave_Unica, Data_Programada, Job_Status_Id, Qt_de_Tentativas, Ultimo_Erro, Chave_Concorrencia, Data_Criacao, Data_Atualizacao, Lock_Id, Lock_Expira_Em, Data_Dump)
SELECT b.Modulo, b.Job, b.Id, b.Hash_Argumentos, b.Chave_Unica, b.Data_Programada, b.Job_Status_Id, b.Qt_de_Tentativas, b.Ultimo_Erro, b.Chave_Concorrencia, b.Data_Criacao, b.Data_Atualizacao, NULL, NULL, @agora
FROM JOB_BPM b JOIN @ids i ON i.Id = b.Id AND i.cenario = '#14';

-- #19 Item Executando (2) com lock válido por 1 dia -> nenhuma das buscas deve tocá-lo.
-- Lock longo para o Worker NÃO executar o item; removido no script de limpeza depois da conferência.
INSERT INTO JOB_BPM (Modulo, Job, Hash_Argumentos, Chave_Unica, Data_Programada, Job_Status_Id, Qt_de_Tentativas, Ultimo_Erro, Chave_Concorrencia, Data_Criacao, Data_Atualizacao, Lock_Id, Lock_Expira_Em)
OUTPUT '#19', inserted.Id INTO @ids
VALUES (1, 8, '{"qa":"us164251-c19"}', 'qa-us164251-c19-executando', DATEADD(MINUTE,-10,@agora), 2, 0, NULL, 'qa-us164251-c19', DATEADD(MINUTE,-10,@agora), DATEADD(MINUTE,-5,@agora), NEWID(), DATEADD(DAY,1,@agora));

COMMIT;

SELECT i.cenario, i.Id, @agora AS montado_em FROM @ids i ORDER BY i.Id;
