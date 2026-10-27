-- US 164251 ORACLE — #4 acompanhamento (leitura): itens do job 18 com a chave fixa, criados desde 08:46
set linesize 250 pagesize 100
col chave_unica format a35
select 'BPM' origem, id, null id_origem, job_status_id st, chave_unica, to_char(data_criacao,'HH24:MI:SS.FF3') criado, to_char(data_atualizacao,'HH24:MI:SS.FF3') atu, null dump from job_bpm where job=18 and chave_unica='BPM|ExcluiFluxoEmSolicitacao'
union all
select 'DUMP', id, id_origem, job_status_id, chave_unica, to_char(data_criacao,'HH24:MI:SS.FF3'), to_char(data_atualizacao,'HH24:MI:SS.FF3'), to_char(data_dump,'HH24:MI:SS.FF3') from job_dump where job=18 and chave_unica='BPM|ExcluiFluxoEmSolicitacao' and data_dump >= timestamp '2026-10-27 08:40:00'
order by 2;
