-- US 164251 ORACLE — #24 (12 itens NotifyWf com Max_Paralelo=2), #18 (FalhaParaRepetir) e #21 (fluxo inexistente até Envenenado).
-- Autorizado no chat em 2026-10-27. Mesmo desenho da rodada SQL (sql\19, 13, 15).
set serveroutput on linesize 200
select max(cd_fluxo) max_fluxo, sum(case when cd_fluxo = 999999 then 1 else 0 end) existe_999999 from fluxo;
declare v_agora timestamp(3) := localtimestamp; v_id number;
begin
  for i in 1..12 loop
    insert into job_bpm (modulo, job, hash_argumentos, chave_unica, data_programada, job_status_id, qt_de_tentativas, chave_concorrencia, data_criacao, data_atualizacao)
    values (1, 9, '{"NotifyStep":8}', 'qa-us164251-ora-c24-'||lpad(i,2,'0'), v_agora - interval '1' minute, 1, 0, 'qa-us164251-ora-c24-'||lpad(i,2,'0'), v_agora, v_agora)
    returning id into v_id;
    dbms_output.put_line('c24-'||lpad(i,2,'0')||' Id '||v_id);
  end loop;
  insert into job_bpm (modulo, job, hash_argumentos, chave_unica, data_programada, job_status_id, qt_de_tentativas, ultimo_erro, chave_concorrencia, data_criacao, data_atualizacao)
  values (1, 9, '{"NotifyStep":8}', 'qa-us164251-ora-c18-falha-para-repetir', v_agora - interval '1' minute, 4, 1, 'qa: falha anterior simulada', 'qa-us164251-ora-c18', v_agora - interval '5' minute, v_agora - interval '2' minute)
  returning id into v_id;
  dbms_output.put_line('c18 Id '||v_id);
  insert into job_bpm (modulo, job, hash_argumentos, chave_unica, data_programada, job_status_id, qt_de_tentativas, chave_concorrencia, data_criacao, data_atualizacao)
  values (1, 8, '{"AvancoTemporalStep":2,"cd_fluxo":999999,"cd_tarefa":1,"cd_passo":1}', 'qa-us164251-ora-c21-fluxo-inexistente', v_agora - interval '1' minute, 1, 3, 'qa-us164251-ora-c21', v_agora - interval '2' minute, v_agora - interval '2' minute)
  returning id into v_id;
  dbms_output.put_line('c21 Id '||v_id);
  commit;
  dbms_output.put_line('montado_em '||to_char(v_agora,'HH24:MI:SS.FF3'));
end;
/
