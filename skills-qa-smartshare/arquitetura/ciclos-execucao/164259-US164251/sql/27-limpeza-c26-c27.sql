-- US 164251 — limpeza dos cenários #26 e #27 (NOTE-74VQ\SQLEXPRESS / ShareGuizao)
-- Remove do JOB_BPM qualquer linha qa-us164251-c26/c27 que tenha sobrado (esperado: a do #27, se não foi movida).
-- Linhas que o Worker moveu para o JOB_DUMP ficam lá como evidência, como nas etapas anteriores.
SET NOCOUNT ON;
DELETE FROM JOB_BPM WHERE Modulo = 1 AND (Chave_Unica LIKE 'qa-us164251-c26-%' OR Chave_Unica LIKE 'qa-us164251-c27-%');
SELECT @@ROWCOUNT AS linhas_removidas;
SELECT 'restante_qa_no_JOB_BPM' AS item, COUNT(*) AS qtd FROM JOB_BPM WHERE Chave_Unica LIKE 'qa-us164251-%';
