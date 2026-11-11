-- US 164850 / mapa #164888 — conferência no Oracle (HMG), SOMENTE SELECT.
-- Colunas confirmadas no código: INDICE_DOCUMENTO.cd_tipo_indice e ds_valor (SmartShare clássico, TipoIndice/IndiceDocumento);
-- LOG_APLICACAO (CD_LOG_APLICACAO, CD_USUARIO, CD_CHAVE, DT_ACAO, DS_CONTEUDO, CD_TIPO_APLICACAO, CD_TIPO_ACAO) em Project.Core.Infraestructure/Entities/LogAplicacao.cs.
-- INDICE_DOCUMENTO.st_ativo vem do texto da US (CA56/CA57); se o Oracle acusar coluna inexistente, me envie o erro.

-- ===== 0. Estado dos tipos de teste (1289 e 1291 devem estar como a API deixou) =====
SELECT cd_tipo_indice, ds_tipo_indice, st_ativo
  FROM TIPO_INDICE
 WHERE cd_tipo_indice IN (1280, 1281, 1282, 1283, 1284, 1285, 1286, 1287, 1288, 1289, 1290, 1291, 1292, 1293)
 ORDER BY cd_tipo_indice;
-- esperado: 1282, 1285 e 1286 NÃO aparecem; 1289 st_ativo = 0; 1291 st_ativo = 1; 1290 st_ativo = 1.

-- ===== 1. #6 e #37 (1289 inativado) =====
SELECT st_ativo, COUNT(*) AS qtd FROM INDICE_DOCUMENTO WHERE cd_tipo_indice = 1289 GROUP BY st_ativo;
-- esperado: uma só linha com st_ativo = 0 e qtd >= 1 (valores preservados, #37).
SELECT cd_tipo_indice, ds_valor, st_ativo FROM INDICE_DOCUMENTO WHERE cd_tipo_indice = 1289;
-- esperado (#37): ds_valor do documento publicado continua preenchido.

-- ===== 2. #8 (1291 reativado) =====
SELECT st_ativo, COUNT(*) AS qtd FROM INDICE_DOCUMENTO WHERE cd_tipo_indice = 1291 GROUP BY st_ativo;
-- esperado: uma só linha com st_ativo = 1.

-- ===== 3. #7 (1290, só descrição, Ativo igual) =====
SELECT st_ativo, COUNT(*) AS qtd FROM INDICE_DOCUMENTO WHERE cd_tipo_indice = 1290 GROUP BY st_ativo;
-- esperado: st_ativo = 1 e mesma qtd do documento publicado (1). Como não há "antes" gravado,
-- a conferência de "não tocado" vem do log: o #3 abaixo não deve mostrar efeito em INDICE_DOCUMENTO.

-- ===== 4. #10 (1282 excluído: INDICE e TIPO_INDICE) =====
SELECT COUNT(*) AS qtd_indice FROM INDICE WHERE cd_tipo_indice = 1282;       -- esperado 0
SELECT COUNT(*) AS qtd_tipo   FROM TIPO_INDICE WHERE cd_tipo_indice = 1282;   -- esperado 0

-- ===== 5. #21 (1285 excluído; INDICE não tocado) =====
SELECT COUNT(*) AS qtd_tipo   FROM TIPO_INDICE WHERE cd_tipo_indice = 1285;   -- esperado 0
SELECT COUNT(*) AS qtd_indice FROM INDICE WHERE cd_tipo_indice = 1285;        -- esperado 0 (tipo Informado nunca teve valores)

-- ===== 6. #39 (1286 excluído uma vez) =====
SELECT COUNT(*) AS qtd_tipo FROM TIPO_INDICE WHERE cd_tipo_indice = 1286;     -- esperado 0

-- ===== 7. #11, #6, #10, #21: log de hoje (aplicação 19; ação 2 = Alteração, ação 3 = Exclusão) =====
SELECT cd_log_aplicacao, cd_usuario, cd_chave, cd_tipo_acao, dt_acao, ds_conteudo
  FROM LOG_APLICACAO
 WHERE cd_tipo_aplicacao = 19
   AND cd_chave IN (1280, 1281, 1282, 1283, 1284, 1285, 1286, 1288, 1289, 1290, 1291, 1292, 1293)
   AND dt_acao >= TRUNC(SYSDATE)
 ORDER BY dt_acao, cd_log_aplicacao;
-- esperado:
--   ação 2 (Alteração): 1280 (vários PUT: #4 e #42), 1283 (#36), 1286 (#38, 3 PUT), 1288 (#5, 2 PUT), 1289 (#6), 1290 (#7, 2 PUT), 1291 (#8);
--   ação 3 (Exclusão): 1282 (#10), 1285 (#21), 1286 (#39, uma só, a segunda tentativa não gera log);
--   NENHUM log para 1281 e 1284 (#25, #26 rejeitados), 1292 (#28) e 1293 (#29), nem para 1288 nas tentativas #23 e #24;
--   ds_conteudo de #11 com os campos do tipo (código e detalhe), sem valor sensível.

-- ===== 8. Atalho: quantidade de logs por tipo e ação =====
SELECT cd_chave, cd_tipo_acao, COUNT(*) AS qtd
  FROM LOG_APLICACAO
 WHERE cd_tipo_aplicacao = 19
   AND cd_chave BETWEEN 1280 AND 1293
   AND dt_acao >= TRUNC(SYSDATE)
 GROUP BY cd_chave, cd_tipo_acao
 ORDER BY cd_chave, cd_tipo_acao;
