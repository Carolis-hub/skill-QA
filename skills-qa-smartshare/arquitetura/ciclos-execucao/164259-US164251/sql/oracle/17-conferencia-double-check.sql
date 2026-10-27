-- US 164251 ORACLE — conferência das ressalvas do double-check (leitura)
set linesize 200
col chave_unica format a40
select id_origem, job, job_status_id st, qt_de_tentativas tent, chave_unica, count(*) over (partition by id_origem, job) qt from job_dump where id_origem in (29975, 29979, 30006) order by id_origem;
