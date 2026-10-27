-- US 164251 ORACLE — #1 e #22 no job 32 (EnviaAlertaFluxo). Envio real autorizado no chat em 2026-10-27.
-- EMAIL_CONFIGURACAO do Oracle NÃO é alterada (remetente '...brrrrr', tipo 3, sem SMTP): a falha de envio deve ocorrer sozinha.
-- Original do job 32: Schedule_Type=2, Interval_Ms=0, Cron='0 0 0 * * ?' (restauração em 07-restauracao-job32.sql).
set serveroutput on linesize 250 pagesize 100
select cd_fluxo_alerta, to_char(dt_ultimo_alerta,'YYYY-MM-DD HH24:MI:SS') ultimo, to_char(dt_proximo_alerta,'YYYY-MM-DD HH24:MI:SS') proximo from fluxo_alerta order by 1;
select count(*) log_email_antes, max(cd_log_email) max_cd from log_email;
declare v_agora timestamp(3) := localtimestamp; v_id number;
begin
  insert into job_bpm (modulo, job, hash_argumentos, chave_unica, data_programada, job_status_id, qt_de_tentativas, chave_concorrencia, data_criacao, data_atualizacao)
  values (1, 32, '{"job":"EnviaAlertaFluxo","qa":"us164251-ora-c1"}', 'qa-us164251-ora-c1-enviaalerta-sucesso', v_agora - interval '10' minute, 3, 0, 'qa-us164251-ora-c1', v_agora - interval '10' minute, v_agora - interval '5' minute)
  returning id into v_id;
  dbms_output.put_line('c1 Id '||v_id);
  update job_config set schedule_type = 1, interval_ms = 60000, cron_expression = null
  where modulo = 1 and job = 32 and schedule_type = 2 and cron_expression = '0 0 0 * * ?';
  dbms_output.put_line('job32 alterado: '||sql%rowcount||' em '||to_char(v_agora,'HH24:MI:SS.FF3'));
  commit;
end;
/
select job, ativo, schedule_type, interval_ms, cron_expression from job_config where modulo=1 and job=32;
