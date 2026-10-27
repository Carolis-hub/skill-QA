-- US 164251 ORACLE — restauração do job 9 (Max_Paralelo 2 -> 1)
set serveroutput on
begin
  update job_config set max_paralelo = 1 where modulo = 1 and job = 9 and max_paralelo = 2;
  dbms_output.put_line('job9 restaurado: '||sql%rowcount||' em '||to_char(localtimestamp,'HH24:MI:SS.FF3'));
  commit;
end;
/
select job, ativo, max_paralelo, schedule_type, interval_ms, cron_expression from job_config where modulo=1 order by job;
