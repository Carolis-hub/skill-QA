-- US 164251 ORACLE — #4: reproduz o bug no job 18 (chave fixa do agendamento), autorizado no chat.
-- Linha status 3 com a MESMA Chave_Unica do Scheduler e Data_Atualizacao = agora (sobrevive a 1 ciclo do Worker),
-- para o Scheduler ficar bloqueado pelo NOT EXISTS até a limpeza. Marcação QA no Hash_Argumentos.
set serveroutput on linesize 200
col chave_unica format a40
select id, job_status_id st, chave_unica, to_char(data_atualizacao,'HH24:MI:SS.FF3') atu from job_bpm where job=18 order by id;
declare v_agora timestamp(3) := localtimestamp; v_n number; v_id number;
begin
  select count(*) into v_n from job_bpm where modulo=1 and job=18 and chave_unica='BPM|ExcluiFluxoEmSolicitacao';
  if v_n = 0 then
    insert into job_bpm (modulo, job, hash_argumentos, chave_unica, data_programada, job_status_id, qt_de_tentativas, chave_concorrencia, data_criacao, data_atualizacao)
    values (1, 18, '{"job":"ExcluiFluxoEmSolicitacao","qa":"us164251-ora-c4"}', 'BPM|ExcluiFluxoEmSolicitacao', v_agora - interval '1' minute, 3, 0, 'BPM|ExcluiFluxoEmSolicitacao', v_agora - interval '1' minute, v_agora)
    returning id into v_id;
    commit;
    dbms_output.put_line('c4 Id '||v_id||' montado_em '||to_char(v_agora,'HH24:MI:SS.FF3'));
  else
    dbms_output.put_line('ja existe linha com a chave fixa: '||v_n||' - nada inserido');
  end if;
end;
/
