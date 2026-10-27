-- US 164251 ORACLE — #1/#22 acompanhamento (leitura)
set linesize 250 pagesize 100
col chave_unica format a42
col ultimo_erro format a60
select 'BPM' o, id, null id_origem, job_status_id st, qt_de_tentativas tent, chave_unica, to_char(data_atualizacao,'HH24:MI:SS.FF3') atu, null dump, dbms_lob.substr(ultimo_erro,60,1) ultimo_erro from job_bpm where job=32
union all
select 'DUMP', id, id_origem, job_status_id, qt_de_tentativas, chave_unica, to_char(data_atualizacao,'HH24:MI:SS.FF3'), to_char(data_dump,'HH24:MI:SS.FF3'), dbms_lob.substr(ultimo_erro,60,1) from job_dump where job=32 and data_dump >= timestamp '2026-10-27 08:40:00'
order by 2;
select id_origem, count(*) from job_dump where id_origem in (16142, 30002) and job=32 group by id_origem;
select cd_fluxo_alerta, to_char(dt_ultimo_alerta,'YYYY-MM-DD HH24:MI:SS') ultimo, to_char(dt_proximo_alerta,'YYYY-MM-DD HH24:MI:SS') proximo from fluxo_alerta where dt_ultimo_alerta >= timestamp '2026-10-27 00:00:00' or dt_proximo_alerta >= timestamp '2026-10-27 00:00:00' order by 1;
select count(*) log_email_depois, max(cd_log_email) max_cd from log_email;
