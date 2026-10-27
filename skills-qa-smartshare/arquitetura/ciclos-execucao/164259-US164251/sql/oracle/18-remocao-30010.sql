-- US 164251 ORACLE — remove o item real 30010 (job 32, st 2, lock vencido), deixado pela execução do job 32 que o restart interrompeu.
-- Autorizado pelo QA no chat em 2026-10-27. Só remove se ainda estiver no mesmo estado. Não cria dump.
set serveroutput on linesize 200
col chave_unica format a30
select id, job, job_status_id st, chave_unica, to_char(data_atualizacao,'YYYY-MM-DD HH24:MI:SS') atu, rawtohex(lock_id) lock_id, to_char(lock_expira_em,'YYYY-MM-DD HH24:MI:SS') lock_exp from job_bpm where id = 30010;
begin
  delete from job_bpm where id = 30010 and modulo = 1 and job = 32 and job_status_id = 2 and chave_unica = 'BPM|EnviaAlertaFluxo' and lock_expira_em < localtimestamp;
  dbms_output.put_line('removidas: '||sql%rowcount||' em '||to_char(localtimestamp,'YYYY-MM-DD HH24:MI:SS.FF3'));
  commit;
end;
/
select count(*) restante_30010 from job_bpm where id = 30010;
select id, job, job_status_id st, chave_unica from job_bpm order by id;
