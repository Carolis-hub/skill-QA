-- US 164251 ORACLE — #21 conferência (leitura)
set linesize 250
col ultimo_erro format a120
select 'BPM' o, count(*) qt from job_bpm where id=30030 union all select 'DUMP', count(*) from job_dump where id_origem=30030 and job=8;
select id_origem, job_status_id st, qt_de_tentativas tent, to_char(data_dump,'HH24:MI:SS.FF3') dump, dbms_lob.substr(ultimo_erro,120,1) ultimo_erro from job_dump where id_origem=30030;
