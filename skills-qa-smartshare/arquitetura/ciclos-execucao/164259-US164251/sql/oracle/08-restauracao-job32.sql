-- US 164251 ORACLE — restauração do job 32 ao original (cron diário 00:00)
set serveroutput on
begin
  update job_config set schedule_type = 2, interval_ms = 0, cron_expression = '0 0 0 * * ?'
  where modulo = 1 and job = 32 and schedule_type = 1 and interval_ms = 60000;
  dbms_output.put_line('job32 restaurado: '||sql%rowcount||' em '||to_char(localtimestamp,'HH24:MI:SS.FF3'));
  commit;
end;
/
select job, ativo, schedule_type, interval_ms, cron_expression from job_config where modulo=1 and job=32;
