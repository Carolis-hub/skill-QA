-- Somente leitura. Rodar em cliente Oracle autorizado, ambiente NAO produtivo (schema do teste).
-- Devolver a saida completa (arquivo ou captura) com data/hora.
SELECT SYS_CONTEXT('USERENV','CURRENT_SCHEMA') schema_efetivo, SYS_CONTEXT('USERENV','DB_NAME') banco, SYSDATE agora FROM dual;
SELECT banner FROM v$version WHERE ROWNUM = 1;
SELECT table_name FROM user_tables WHERE table_name IN ('JOB_BPM','JOB_DUMP','JOB_CONFIG','CAMINHO_FLUXO','TAREFA','PASSO_USUARIO','OBSERVACAO_TAREFA','FLUXO','PROCESSO','TAREFA_NOTIFICACAO','PASSO_USUARIO_NOTIFICACAO','LOG_EMAIL') ORDER BY 1;
SELECT column_name FROM user_tab_columns WHERE table_name='JOB_BPM' ORDER BY column_id;
SELECT id, modulo, job, max_tentativas, politica_backoff, schedule_type, interval_ms, timezone_id, ativo FROM job_config ORDER BY id;
SELECT job_status_id, COUNT(*) qtd FROM job_bpm GROUP BY job_status_id ORDER BY 1;
SELECT COUNT(*) total_dump FROM job_dump;
SELECT cd_processo, cd_versao_processo, cd_passo, id_permissao_observacao FROM passo_usuario WHERE id_permissao_observacao = 4;
SELECT cd_processo, cd_versao_processo, cd_passo, id_permissao_observacao FROM passo_usuario WHERE cd_processo = 522 AND cd_versao_processo = 1 AND cd_passo = 6;
SELECT cd_processo, COUNT(*) fluxos FROM fluxo WHERE cd_processo IN (481,501,522) GROUP BY cd_processo;
