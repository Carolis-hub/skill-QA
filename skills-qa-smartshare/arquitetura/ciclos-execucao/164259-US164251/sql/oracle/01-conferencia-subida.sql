-- US 164251 ORACLE — conferência após a subida do Worker (leitura)
set linesize 300 pagesize 200
col chave_unica format a55
select id, job, job_status_id st, chave_unica from job_bpm order by id;
select d.id, d.id_origem, d.modulo, d.job, d.job_status_id st, d.chave_unica, rawtohex(d.lock_id) lock_id, to_char(d.lock_expira_em,'HH24:MI:SS') lock_exp, to_char(d.data_dump,'YYYY-MM-DD HH24:MI:SS.FF3') data_dump
from job_dump d where d.id_origem in (7663,9583,9591,29967,29968,29969) order by d.id_origem, d.job;
select id_origem, modulo, job, count(*) qt from job_dump group by id_origem, modulo, job having count(*)>1;
select count(*) dump_total, max(id) dump_max_id from job_dump;
