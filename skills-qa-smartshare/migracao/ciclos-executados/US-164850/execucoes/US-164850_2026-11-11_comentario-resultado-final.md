**Resultado final da execução do mapa de testes (#164888), US 164850 — Oracle e SQL Server**
Ambiente HMG, execução por API (US de BE), 09 a 11/11/2026. Dois bancos, como pedem o CA 98 e o cenário #46: Oracle (09 e 10/11) e SQL Server, base `share_carol` (10 e 11/11). Branch exata do build em execução não confirmada (o campo `st_em_uso` da US estava presente).

**Resumo (48 cenários)**
| Banco | Passou | Falhou | Não aplicável | Não executado |
|---|---|---|---|---|
| Oracle | 37 | 0 | 0 | 11 |
| SQL Server | 42 | 0 | 1 (#35) | 5 |
**Nenhum Bug aberto. Nenhuma diferença de comportamento entre os bancos** nos cenários executados nos dois, incluindo mensagens e logs.

**#46 (CA 98): Passou.** #23, #6, #18, #10 e #29 têm o mesmo resultado no Oracle e no SQL Server.

**Passou nos dois bancos:** #1 a #8, #10 a #26, #28 a #33, #36 a #39, #42, #45 e #46.
- Conferência no banco (SELECT em `INDICE_DOCUMENTO`, `INDICE`, `TIPO_INDICE`, `TIPO_DOCUMENTO_TIPO_INDICE` e `LOG_APLICACAO`, aplicação 19) nos dois bancos: propagação de status, exclusão, logs de Alteração e Exclusão, e **nenhum log para rejeição** (#22).
- Bloqueio por processo (etiqueta e Início com Publicação) com a lista em ordem alfabética, sem repetição (#12 a #20).
**Só no SQL Server (passou):** #43 (o Clássico lê e grava depois de alterar pela API), #34 (usuário não administrador: 403 em listagem, PUT e DELETE), #9 e #44 (o ECM não oferece tipo inativo na busca nem no lançamento e volta a oferecer ao reativar).

**Não aplicável / não executados**
- **#35 (SQL Server): não aplicável, por decisão da usuária.** Com a regra atual (só administrador gerencia índices, APR-013) não existe usuário que veja a listagem e não gerencie; o CA 96 não define esse caso.
- **Oracle, não executados:** #9, #44 (ECM-BE), #43 (Clássico), #34 e #35 (sem usuário sem permissão), #27, #40, #41, #47, #48 (hipóteses).
- **Hipóteses (nos dois bancos): #27, #40, #41, #47, #48.** A forma de provocar a falha não está descrita no card; #47 e #48 dependem da divergência entre o CA 67 e o D-01 do card sobre o `cd_documento`.

**Pontos para dev e PM decidirem (não são defeitos)**
1. **#20 — aguarda a PM.** A API aceita alterar só a descrição de tipo inativo e vinculado a processo (CA 55 lido literalmente: só bloqueia quando o `Ativo` muda). O Clássico bloqueia sempre que Ativo = 0 e há vínculo, e a decisão da PM de 21 e 22/10 diz "exatamente o comportamento do Clássico". Se a PM escolher o Clássico, o #20 vira Falhou e abre Bug de BE. Hoje: Passou conforme o CA 55, com ressalva.
2. Sem token, PUT e DELETE devolvem **403** (o mapa #33 diz 401; o CA 95 aceita 401/403). Só o token de usuário, sem o de acesso, dá 401.
3. Rejeições de negócio voltam como **HTTP 500** com mensagem legível (#39 pede "sem erro técnico").
4. As mensagens de bloqueio terminam com **ponto final**; o CA 55 e o CA 66 não escrevem, o Clássico e o código do dev têm.
5. **#17:** o mapa espera o texto do CA 72 (Figma, "inativar esse registro"), que é do FE; a API segue o CA 55 ("tornar inativo este registro"). Sugestão: corrigir o esperado do mapa.
6. **#26:** com o DI coerente com o tipo, a resposta é sempre "em uso". A API valida o DI antes de "em uso" quando o PUT chega com DI incompatível; o FE envia DI coerente, então fica só como informação.
7. **#45:** a parte "consultar a engine" é lacuna; nenhum endpoint da engine na branch lê o vínculo de tipo de índice.
8. **#38 e #39** foram executados com a mesma conta nas duas pontas (não houve duas sessões).
9. Achado fora do escopo da US: o ECM-BE responde **500** (`FormatException`, `AuthenticationFailureResult.cs:30`) em vez de 401 quando o token é inválido. Pré-existente; só registrado.

**Relatórios completos** (respostas brutas da API, SQL de conferência, matriz por cenário): `C:\skills-qualidade\ciclos-executados\US-164850\execucoes\US-164850_2026-11-09_execucao_oracle.md` e `US-164850_2026-11-10_execucao_sqlserver.md`.
