-- US 164251 ORACLE — #15 conferência (leitura)
select count(*) bpm_restantes from job_bpm where chave_unica like 'qa-us164251-ora-c15-%';
select count(*) dumps, count(distinct id_origem) ids_distintos, min(id_origem), max(id_origem) from job_dump where chave_unica like 'qa-us164251-ora-c15-%';
select count(*) id_origem_duplicado from (select id_origem from job_dump where chave_unica like 'qa-us164251-ora-c15-%' group by id_origem, modulo, job having count(*)>1);
select count(*) dumps_com_lock from job_dump where chave_unica like 'qa-us164251-ora-c15-%' and (lock_id is not null or lock_expira_em is not null);
select count(*) faltando from (select level+30039 id from dual connect by level<=600) x where not exists (select 1 from job_dump d where d.id_origem=x.id and d.job=18);
