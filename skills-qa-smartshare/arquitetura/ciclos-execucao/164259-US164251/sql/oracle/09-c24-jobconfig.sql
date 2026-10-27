-- US 164251 ORACLE — #24: job 9 com Max_Paralelo = 2 (original 1; restauração em 12-restauracao-c24.sql)
set serveroutput on
begin
  update job_config set max_paralelo = 2 where modulo = 1 and job = 9 and max_paralelo = 1;
  dbms_output.put_line('job9 alterado: '||sql%rowcount||' em '||to_char(localtimestamp,'HH24:MI:SS.FF3'));
  commit;
end;
/
select job, ativo, max_paralelo, interval_ms from job_config where modulo=1 and job in (9,32);
