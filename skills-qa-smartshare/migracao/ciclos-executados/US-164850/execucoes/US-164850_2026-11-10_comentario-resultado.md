**Resultado da execução do mapa de testes (#164888), US 164850**
Ambiente HMG, banco Oracle, execução por API (US de BE), 09 e 10/11/2026. Branch exata do build em execução não confirmada (o campo `st_em_uso` da US estava presente).

**Resumo:** 37 Passou, 0 Falhou, 11 não executados. Nenhum Bug aberto. Validação **parcial** (faltam SQL Server, ECM-BE, Clássico e usuário sem permissão).

**Passou (37)**
- Leitura e alteração: #1 a #5, #36, #38, #42.
- Inativar e reativar, com conferência no banco (propagação em `INDICE_DOCUMENTO` e log da aplicação 19): #6, #7, #8, #11, #37.
- Exclusão, com conferência no banco: #10, #21, #28, #29, #30, #31, #32, #39.
- Bloqueios por vínculo com processo (etiqueta e Início com Publicação), com a lista de processos: #12 a #20, #22, #45.
- Listas de processos: #15 (os dois nomes aparecem) e #16 (ordem alfabética, sem repetição).
- Tipo/valor travados em uso: #23 a #26.
- Permissão: #33.

**Não executados (11)**
- #9, #44: smartshare-ecm-be sem URL e token disponíveis. #43: Clássico para regressão.
- #34, #35: sem usuário sem permissão (o login do `qa.publicador.us164850` não concluiu).
- #27, #40, #41, #47, #48: hipóteses (forma de provocar a falha não descrita; CA 67 x card D-01 sobre o `cd_documento`).
- #46: SQL Server fica para outra rodada.

**Pontos para dev e PM decidirem (não são defeitos)**
1. Sem token, PUT e DELETE devolvem **403**; o mapa #33 diz 401 (o CA 95 aceita 401/403).
2. Rejeições de negócio voltam como **HTTP 500** com mensagem legível (#39 pede "sem erro técnico").
3. Mensagens de bloqueio terminam com **ponto final**; o CA 55 e o CA 66 não escrevem o ponto, o Clássico e o código do dev têm.
4. **#17:** o mapa espera o texto do CA 72 (Figma, "inativar esse registro"), mas esse texto é do FE; a API segue o CA 55 ("tornar inativo este registro"). Sugestão: corrigir o esperado do mapa.
5. **#20:** a API aceita alterar só a descrição de tipo inativo e vinculado (CA 55); o Clássico bloqueia sempre que Ativo = 0. Confirmar com a PM.
6. **#45:** a metade "consultar a engine" ficou como lacuna; nenhum endpoint da engine na branch lê o vínculo de tipo de índice.
7. **#38 e #39** foram executados com a mesma conta nas duas pontas (não houve duas sessões).

Relatório completo com as respostas brutas da API: `C:\skills-qualidade\ciclos-executados\US-164850\execucoes\US-164850_2026-11-09_execucao_oracle.md`.
