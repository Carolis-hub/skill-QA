-- US 164251 — rodada ORACLE — estado antes (somente leitura)
set linesize 300 pagesize 500
col cron_expression format a18
col timezone_id format a20
col chave_unica format a60
select to_char(systimestamp,'YYYY-MM-DD HH24:MI:SS.FF3 TZH:TZM') agora_db from dual;
select id, job, ativo, max_paralelo, max_tentativas, lease_segundos, schedule_type, interval_ms, cron_expression, timezone_id, batch_size from job_config where modulo=1 order by job;
select id, job, job_status_id st, qt_de_tentativas tent, chave_unica, to_char(data_programada,'YYYY-MM-DD HH24:MI:SS') prog, to_char(data_atualizacao,'YYYY-MM-DD HH24:MI:SS') atu, rawtohex(lock_id) lock_id, to_char(lock_expira_em,'YYYY-MM-DD HH24:MI:SS') lock_exp from job_bpm order by id;
select count(*) dump_total, max(id) dump_max_id, to_char(max(data_dump),'YYYY-MM-DD HH24:MI:SS') ult_dump from job_dump;
select id_origem, modulo, job, count(*) from job_dump where id_origem in (7663,9583,9591,16142,29967,29968,29969) group by id_origem, modulo, job;
