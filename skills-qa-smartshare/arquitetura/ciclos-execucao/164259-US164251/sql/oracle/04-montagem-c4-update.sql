-- US 164251 ORACLE — #4 (2ª tentativa): o Scheduler reinsere a chave fixa em segundos, então o item real
-- Agendado do job 18 com a chave fixa vira "Sucesso não movido para o dump" (o caso do bug). Autorizado no chat.
set serveroutput on linesize 200
declare v_agora timestamp(3) := localtimestamp; v_id number;
begin
  update job_bpm set job_status_id = 3, data_atualizacao = v_agora, lock_id = null, lock_expira_em = null
  where modulo=1 and job=18 and chave_unica='BPM|ExcluiFluxoEmSolicitacao' and job_status_id = 1 and (lock_expira_em is null or lock_expira_em < v_agora)
  returning id into v_id;
  dbms_output.put_line('linhas: '||sql%rowcount||' Id '||v_id||' em '||to_char(v_agora,'HH24:MI:SS.FF3'));
  commit;
end;
/
col chave_unica format a40
select id, job_status_id st, chave_unica, to_char(data_atualizacao,'HH24:MI:SS.FF3') atu from job_bpm where job=18 order by id;
