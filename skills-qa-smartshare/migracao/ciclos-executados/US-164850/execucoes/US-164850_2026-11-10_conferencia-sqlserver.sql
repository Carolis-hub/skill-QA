-- US 164850 - conferência no SQL Server (base share_carol). Somente SELECT.
-- Códigos do SQL Server (diferentes do Oracle): 82 = doc inativar (#6, #37), 83 = doc ativo (#7), 84 = doc reativar (#8),
-- 88 = selecao exclusao (#10, excluído), 79 = livre exclusao (#21, excluído), 80 = livre concorrencia (#39, excluído),
-- 78 = livre (#4, #42), 81 = doc em uso (#5), 85 = doc exclusao (#28), 86 = fk tipodoc (#29).

-- #6 e #37 (tipo 82 inativado): esperado st_ativo = 0 em todos
SELECT st_ativo, COUNT(*) AS qtd FROM INDICE_DOCUMENTO WHERE cd_tipo_indice = 82 GROUP BY st_ativo;
-- #8 (tipo 84 reativado): esperado st_ativo = 1 em todos
SELECT st_ativo, COUNT(*) AS qtd FROM INDICE_DOCUMENTO WHERE cd_tipo_indice = 84 GROUP BY st_ativo;
-- #7 (tipo 83 só descrição): esperado st_ativo = 1 e a mesma contagem de antes
SELECT st_ativo, COUNT(*) AS qtd FROM INDICE_DOCUMENTO WHERE cd_tipo_indice = 83 GROUP BY st_ativo;
-- #10 (88 excluído): esperado 0 e 0
SELECT COUNT(*) AS indice_88 FROM INDICE WHERE cd_tipo_indice = 88;
SELECT COUNT(*) AS tipo_88 FROM TIPO_INDICE WHERE cd_tipo_indice = 88;
-- #21 e #39 (79 e 80 excluídos): esperado 0
SELECT COUNT(*) AS tipo_79_80 FROM TIPO_INDICE WHERE cd_tipo_indice IN (79, 80);
-- #29 (86 segue com FK em TIPO_DOCUMENTO_TIPO_INDICE): esperado 1
SELECT COUNT(*) AS fk_86 FROM TIPO_DOCUMENTO_TIPO_INDICE WHERE cd_tipo_indice = 86;
-- #11, #6, #10, #21, #39: logs de hoje (aplicação 19; ação 2 = Alteração, ação 3 = Exclusão)
SELECT cd_log_aplicacao, cd_chave, cd_tipo_acao, dt_acao, LEFT(CAST(ds_conteudo AS VARCHAR(MAX)), 80) AS inicio
  FROM LOG_APLICACAO
 WHERE cd_tipo_aplicacao = 19 AND cd_chave IN (78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90)
   AND dt_acao >= CAST(GETDATE() AS DATE)
 ORDER BY dt_acao;
-- Esperado: logs de Alteração para os PUT válidos (78, 81, 82, 83, 84, 89, 80), Exclusão de 79, 80 e 88 (ação 3),
-- e NENHUM log para as rejeições (#23 a #26 em 81, 87, 90; #28 em 85; #29 em 86; #30 e #31).
