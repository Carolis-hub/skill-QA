-- US 164251 — RODADA ORACLE — montagem dos cenários com escrita (autorizada no chat em 2026-10-27)
-- Schema SHAREGUIZAO (QA pessoal, RDS ss-oracle-br-3). Chave_Unica sempre 'qa-us164251-ora-*' para rastrear e limpar.
-- Horários em LOCALTIMESTAMP (sessão -03:00), o mesmo relógio que o Worker usa (DateTime.Now). SYSDATE do RDS está em UTC: não usar.
-- Ciclos no Oracle: job 9/18/28 = 60 s, 19 = 30 s, 7 = 300 s, 8 = 900 s.
set serveroutput on linesize 200
declare
  v_agora timestamp(3) := localtimestamp;
  v_id number;
  procedure ins(p_cen varchar2, p_job number, p_st number, p_atu timestamp, p_lock raw, p_lockexp timestamp, p_tent number := 0) is
  begin
    insert into job_bpm (modulo, job, hash_argumentos, chave_unica, data_programada, job_status_id, qt_de_tentativas, ultimo_erro, chave_concorrencia, data_criacao, data_atualizacao, lock_id, lock_expira_em)
    values (1, p_job, '{"qa":"us164251-ora-'||p_cen||'"}', 'qa-us164251-ora-'||p_cen, v_agora - interval '10' minute, p_st, p_tent,
            case when p_st = 5 then 'qa: erro simulado' end, 'qa-us164251-ora-'||p_cen, v_agora - interval '10' minute, p_atu, p_lock, p_lockexp)
    returning id into v_id;
    dbms_output.put_line(rpad(p_cen,12)||' job '||lpad(p_job,2)||' st '||p_st||' Id '||v_id);
  end;
begin
  ins('c2-env',     9, 5, v_agora - interval '5' minute, null, null, 5);   -- #2 Envenenado travado
  ins('c8-recente', 9, 3, v_agora, null, null);                            -- #8/#9 recém-finalizado (<60 s), movido só depois de 60 s
  ins('c9-70s',    18, 3, v_agora - interval '70' second, null, null);     -- #9 logo acima de 60 s
  ins('c10-lock',   9, 3, v_agora - interval '5' minute, sys_guid(), v_agora + interval '3' minute); -- #10 lock válido 3 min
  ins('c14-dump',   9, 3, v_agora - interval '5' minute, null, null);      -- #14/#28 já tem dump
  insert into job_dump (modulo, job, id_origem, hash_argumentos, chave_unica, data_programada, job_status_id, qt_de_tentativas, ultimo_erro, chave_concorrencia, data_criacao, data_atualizacao, lock_id, lock_expira_em, data_dump)
  select modulo, job, id, hash_argumentos, chave_unica, data_programada, job_status_id, qt_de_tentativas, ultimo_erro, chave_concorrencia, data_criacao, data_atualizacao, null, null, v_agora
  from job_bpm where chave_unica = 'qa-us164251-ora-c14-dump';
  dbms_output.put_line('c14 pre-dump inserido: '||sql%rowcount);
  ins('c19-exec',  18, 2, v_agora - interval '5' minute, sys_guid(), v_agora + interval '1' day);   -- #19 Executando com lock válido
  ins('c6-sql',    19, 3, v_agora - interval '5' minute, null, null);      -- #6 ExecutaSql
  ins('c7-j8',      8, 3, v_agora - interval '5' minute, null, null);      -- #7 AvancoTemporal (ciclo 15 min)
  ins('c26-s3',    18, 3, v_agora - interval '5' minute, null, null);      -- #26 três no mesmo ciclo
  ins('c26-s5',    18, 5, v_agora - interval '5' minute, null, null, 5);
  ins('c26-s6',    18, 6, v_agora - interval '5' minute, null, null);
  ins('c27-null',   9, 3, null, null, null);                               -- #27 Data_Atualizacao nula
  commit;
  dbms_output.put_line('montado_em '||to_char(v_agora,'YYYY-MM-DD HH24:MI:SS.FF3'));
end;
/
