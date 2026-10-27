-- US 164251 — limpeza depois da conferência (NOTE-74VQ\SQLEXPRESS / ShareGuizao)
-- Remove do JOB_BPM só a linha do #19 (Executando com lock de 1 dia), que o Worker nunca vai mover sozinho.
-- As demais linhas qa-us164251-* terminam no JOB_DUMP pelo próprio Worker; elas ficam lá como evidência.
SET NOCOUNT ON;
DELETE FROM JOB_BPM WHERE Modulo = 1 AND Chave_Unica = 'qa-us164251-c19-executando' AND Job_Status_Id = 2;
SELECT @@ROWCOUNT AS linhas_removidas;
SELECT 'restante_qa_no_JOB_BPM' AS item, COUNT(*) AS qtd FROM JOB_BPM WHERE Chave_Unica LIKE 'qa-us164251-%';
