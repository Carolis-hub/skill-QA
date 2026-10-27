-- US 164251 — cenário #4: item travado com a mesma Chave_Unica do agendamento fixo do job 18 (ExcluiFluxoEmSolicitacao).
-- Reproduz o bug original: com essa linha no JOB_BPM, o Scheduler não consegue inserir um item novo (NOT EXISTS por Modulo+Job+Chave_Unica).
-- Esperado com a correção: o Worker move a linha para o JOB_DUMP, o Scheduler volta a inserir e o item novo é executado.
-- Hash_Argumentos leva a marca qa-us164251-c4 para rastrear; o Scheduler só compara Chave_Unica.
-- Só insere se não houver item com a chave na fila (evita duplicar com um item real do Scheduler).
-- Ambiente: NOTE-74VQ\SQLEXPRESS / ShareGuizao (QA local). Autorizado pelo usuário no chat em 2026-10-26.
SET NOCOUNT ON;
DECLARE @agora datetime = GETDATE();
INSERT INTO JOB_BPM (Modulo, Job, Hash_Argumentos, Chave_Unica, Data_Programada, Job_Status_Id, Qt_de_Tentativas, Ultimo_Erro, Chave_Concorrencia, Data_Criacao, Data_Atualizacao, Lock_Id, Lock_Expira_Em)
SELECT 1, 18, '{"job":"ExcluiFluxoEmSolicitacao","qa":"us164251-c4"}', 'BPM|ExcluiFluxoEmSolicitacao', DATEADD(MINUTE,-10,@agora), 3, 0, NULL, 'BPM|ExcluiFluxoEmSolicitacao', DATEADD(MINUTE,-10,@agora), DATEADD(MINUTE,-5,@agora), NULL, NULL
WHERE NOT EXISTS (SELECT 1 FROM JOB_BPM WHERE Modulo = 1 AND Job = 18 AND Chave_Unica = 'BPM|ExcluiFluxoEmSolicitacao');
SELECT @@ROWCOUNT AS inseridas, CAST(SCOPE_IDENTITY() AS bigint) AS Id, CONVERT(varchar(23), @agora, 121) AS montado_em;
