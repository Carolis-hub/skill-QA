-- US 164251 ORACLE — limpeza: remove do JOB_BPM as linhas QA que o Worker não move por regra (#19 Executando com lock de 1 dia; #27 Data_Atualizacao nula).
-- Os dumps qa-us164251-ora-* ficam no JOB_DUMP como evidência. O item real 30010 (job 32, status 2, lock vencido) NÃO é tocado.
set serveroutput on linesize 200
col chave_unica format a45
select id, job, job_status_id st, chave_unica, to_char(data_atualizacao,'YYYY-MM-DD HH24:MI:SS') atu, to_char(lock_expira_em,'YYYY-MM-DD HH24:MI:SS') lock_exp from job_bpm where id in (29980, 29986);
begin
  delete from job_bpm where id in (29980, 29986) and chave_unica in ('qa-us164251-ora-c19-exec','qa-us164251-ora-c27-null');
  dbms_output.put_line('removidas: '||sql%rowcount||' em '||to_char(localtimestamp,'HH24:MI:SS.FF3'));
  commit;
end;
/
select count(*) bpm_qa_restantes from job_bpm where chave_unica like 'qa-us164251-ora-%' or hash_argumentos like '%us164251-ora%';
select count(*) dumps_qa from job_dump where chave_unica like 'qa-us164251-ora-%' or hash_argumentos like '%us164251-ora%';
select id, job, job_status_id st, chave_unica, to_char(data_atualizacao,'HH24:MI:SS') atu, to_char(lock_expira_em,'HH24:MI:SS') lock_exp from job_bpm order by id;
