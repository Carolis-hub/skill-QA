-- US 164251 ORACLE — #24/#18 e item 30010 (job 32 interrompido) — leitura
set linesize 250 pagesize 100
col chave_unica format a42
select id_origem, job_status_id st, qt_de_tentativas tent, chave_unica, count(*) over (partition by id_origem) qt_dump from job_dump where chave_unica like 'qa-us164251-ora-c24%' or chave_unica like 'qa-us164251-ora-c18%' order by id_origem;
select id, job, job_status_id st, qt_de_tentativas tent, chave_unica, to_char(data_atualizacao,'HH24:MI:SS.FF3') atu, rawtohex(lock_id) lock_id, to_char(lock_expira_em,'HH24:MI:SS') lock_exp from job_bpm order by id;
