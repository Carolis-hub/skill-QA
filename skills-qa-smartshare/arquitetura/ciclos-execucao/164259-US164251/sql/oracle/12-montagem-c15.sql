-- US 164251 ORACLE — #15: 600 linhas travadas (status 3, >60 s, sem lock) no job 18, com 2 instâncias do Worker ativas
-- (instância 1 cicla no segundo :28, instância 2 no :38). Autorizado no chat em 2026-10-27.
set serveroutput on
declare v_agora timestamp(3) := localtimestamp; v_min number; v_max number;
begin
  for i in 1..600 loop
    insert into job_bpm (modulo, job, hash_argumentos, chave_unica, data_programada, job_status_id, qt_de_tentativas, chave_concorrencia, data_criacao, data_atualizacao)
    values (1, 18, '{"qa":"us164251-ora-c15"}', 'qa-us164251-ora-c15-'||lpad(i,3,'0'), v_agora - interval '10' minute, 3, 0, 'qa-us164251-ora-c15', v_agora - interval '10' minute, v_agora - interval '5' minute);
  end loop;
  commit;
  select min(id), max(id) into v_min, v_max from job_bpm where chave_unica like 'qa-us164251-ora-c15-%';
  dbms_output.put_line('c15: 600 linhas, Ids '||v_min||'-'||v_max||' montado_em '||to_char(v_agora,'HH24:MI:SS.FF3'));
end;
/
