# Execução — Mapa #164888 — SQL Server (base share_carol) — PARCIAL

**Ambiente:** HMG, API net8 `http://localhost:8081/api/TipoIndice`, execução por HTTP (US de BE). **Banco:** SQL Server `172.16.0.185\desenvolvimento`, base `share_carol`, confirmado (troca por `webconfig.aspx`, APR-018, conexão provada pelo login do root e pela massa que só existe aqui).
**Credencial:** headers `Authorization` e `X-User-Authorization` colados pela usuária (usuário `unique_name=1`, administrador), não gravados.
**Códigos:** os tipos de índice têm códigos diferentes do Oracle (ver `validacoes-ambiente\US-164850_2026-11-10_sqlserver.md`): 78=livre, 79=livre exclusão, 80=livre concorrência, 81 a 85=doc (em uso, inativar, ativo, reativar, exclusão), 86=fk tipodoc, 87=seleção com opções, 88=seleção exclusão, 89=seleção sem valores, 90=múltipla, 91=inativo.
**Massa de documento:** tipo de documento 24 (índices 81 a 85) com documento publicado pela usuária; `GetOne` confirma `st_em_uso = 1` em 81 a 85.

## Resultados por cenário (API)
| # | Ação | Esperado | Obtido (SQL Server) | Oracle | Resultado |
|---|---|---|---|---|---|
| 1 | GetOne 81 (em INDICE_DOCUMENTO) | `st_em_uso = 1` | 1 | Passou | Passou |
| 2 | GetOne 87 (Seleção, 2 opções) | `st_em_uso = 1` | 1 (Opcoes total 2) | Passou | Passou |
| 3 | GetOne 78 (livre) | `st_em_uso = 0` | 0 | Passou | Passou |
| 4 | PUT 78: Tipo de índice 2→3, depois Tipo de valor 1→2 | aceita e grava | 200 e 200; GetOne confirma local=3 e valor=2. Restaurado para 2/1 (a 1ª tentativa de restaurar só o local deu 500 "Tipo de índice no DI não permitido", porque `id_tipo_local_di` precisa acompanhar o tipo: com local e DI juntos, 200) | Passou | Passou |
| 5 | PUT 81 só descrição | aceita; `st_em_uso` segue 1 | 200, descrição trocada e restaurada, `st_em_uso = 1` | Passou | Passou |
| 6 | PUT 82 `st_ativo` 1→0 (em documento) | aceita | 200; GetOne `st_ativo = 0`, `st_em_uso = 1`. Propagação em INDICE_DOCUMENTO: SELECT pendente | Passou (com SQL) | Passou na API; SQL pendente |
| 7 | PUT 83 só descrição | aceita, não toca INDICE_DOCUMENTO | 200, descrição restaurada, `st_ativo = 1` | Passou (ressalva) | Passou (ressalva: "não tocado" sem foto anterior; SQL pendente) |
| 8 | PUT 84 inativo→ativo | aceita e propaga | 84 inativado (preparação) e reativado: 200, GetOne `st_ativo = 1` | Passou | Passou na API; SQL pendente |
| 10 | DELETE 88 (Seleção com 2 opções, sem uso em processo) | exclui tipo e opções | 200 `cd_documento: null`; GetOne e Opcoes "Tipo de índice não encontrado." | Passou | Passou na API; SQL e log pendentes |
| 11 | log de alteração | LOG_APLICACAO 19 | depende do SELECT | Passou | Pendente (SQL) |
| 21 | DELETE 79 (livre, sem uso) | exclui | 200; GetOne "não encontrado" | Passou | Passou na API; SQL pendente |
| 23 | PUT 81 alterando Tipo de índice | rejeita, nada gravado | 500 "Tipo de índice e Tipo de valor não podem ser alterados, pois o índice está em uso."; GetOne igual | Passou | Passou |
| 24 | PUT 81 alterando Tipo de valor | idem | mesma mensagem; nada gravado | Passou | Passou |
| 25 | PUT 87 alterando tipo e depois valor | rejeita como o #23 | mesma mensagem nas duas | Passou | Passou |
| 26 | PUT 90 (Múltipla) alterando tipo e valor | rejeita (D-03) | alterar o valor: mensagem de "em uso". Alterar só `id_tipo_local` para 3: mesma mensagem de "em uso". Para 1 ou 2 com `id_tipo_local_di` = 4 a API responde antes "Tipo de índice no DI não permitido" (ordem das validações; o FE manda DI coerente) | Passou | Passou (ressalva: ordem das validações) |
| 28 | DELETE 85 (usado em documento) | "…está sendo utilizado"; nada excluído | 500 "Não foi possível excluir este registro, pois o mesmo está sendo utilizado."; GetOne 200 | Passou | Passou |
| 29 | DELETE 86 (FK em TIPO_DOCUMENTO_TIPO_INDICE) | FK vira mensagem de uso | mesma mensagem; GetOne 200 | Passou | Passou |
| 30 | DELETE 0 | "Tipo de índice não encontrado." | 500 com exatamente essa mensagem | Passou | Passou |
| 31 | DELETE 9999999 | idem | 500 com exatamente essa mensagem | Passou | Passou |
| 32 | rotas de exclusão múltipla | só individual | swagger do `:8081`: `DELETE /api/TipoIndice` por `cd_tipo_indice`; `Opcoes` por opção; sem lote | Passou | Passou |
| 33 | PUT e DELETE sem token | 401/403, nada executado | sem token: 403 nos dois; só o token de usuário: 401 nos dois; 78 intacto | Passou (obs. 1) | Passou (mesma observação: 403, não 401) |
| 36 | PUT 89 (Seleção sem valores, sem uso) alterando Tipo de índice | aceita | 200; GetOne `id_tipo_local = 2` | Passou | Passou |
| 37 | inativação do 82 mantém valores | valores preservados | GetOne `st_ativo = 0`; preservação em INDICE_DOCUMENTO depende do SELECT | Passou (com SQL) | Passou na API; SQL pendente |
| 38 | A salva (ord 11), B salva (ord 22) no 80 | prevalece o último | 200 e 200; GetOne ord = 22; restaurado | Passou (ressalva: mesma conta) | Passou (mesma ressalva) |
| 39 | A exclui 80; B exclui o mesmo | B: "não encontrado", sem erro técnico | A 200; B 500 "Tipo de índice não encontrado."; GetOne não encontrado | Passou (ressalva) | Passou (mesma ressalva: status 500 com mensagem de negócio) |
| 42 | PUT 78 com descrição `QA164850 aspas '" ; -- DROP` | grava literal | 200; GetOne devolve o texto idêntico; restaurado | Passou | Passou |

## Conferência no SQL Server (retorno colado pela usuária em 2026-11-11)
| # | Consulta | Esperado | Retorno | Resultado |
|---|---|---|---|---|
| 6 e 37 | INDICE_DOCUMENTO do tipo 82 por `st_ativo` | só `st_ativo = 0` | `0 | 1` (1 registro, inativo) | Passou (SQL Server) |
| 8 | INDICE_DOCUMENTO do tipo 84 | só `st_ativo = 1` | `1 | 1` | Passou |
| 7 | INDICE_DOCUMENTO do tipo 83 | `st_ativo = 1`, mesma contagem (1 documento) | `1 | 1` | Passou (ressalva: sem foto anterior para "não tocado") |
| 10 | INDICE e TIPO_INDICE do 88 | 0 e 0 | `0` e `0` | Passou |
| 21 e 39 | TIPO_INDICE 79 e 80 | 0 | `0` | Passou |
| 29 | TIPO_DOCUMENTO_TIPO_INDICE do 86 | 1 (FK preservada) | `1` | Passou |
| 11 (logs) | LOG_APLICACAO aplicação 19, filtro `dt_acao >= hoje` | logs de Alteração/Exclusão | primeira consulta vazia (a data virou, filtro excluía 10/11); refeita com o filtro de ontem, retorno abaixo | ver linha seguinte |
| 11 (logs, refeito) | LOG_APLICACAO 19, desde 10/11 | Alteração (ação 2) por PUT válido, Exclusão (ação 3), nenhum log de rejeição | Inclusões 1640463 a 1640475 (78 a 90, preparação). Alterações: 78 ×6 (#4a, #4b, #42 ×2, restaurações ×2); 81 ×2 (#5); 89 ×1 (#36); 82 ×1 (#6); 83 ×2 (#7); 84 ×4 (inativar, reativar, inativar, reativar); 80 ×3 (#38 A, B, restauração). Exclusões: 88 (#10), 79 (#21), 80 ×1 (#39: a segunda tentativa não gerou log). **Nenhum log** para 85, 86, 87 e 90 além da Inclusão (rejeições #23 a #26, #28, #29), nem para o 81 nas rejeições. A tentativa de restaurar só `id_tipo_local` do 78 (500) também não gerou log | **Passou** (#11; reforço de #6, #10, #21, #39) |

## #43 — Clássico depois de alterar pela API (2026-11-11, Playwright, root)
| # | Ação | Esperado | Obtido | Resultado |
|---|---|---|---|---|
| 43 | PUT pela API no tipo 78 (descrição "QA164850 livre 43 API", ordenação 77, 200); abrir `Gerenciamento/TipoIndice.aspx`, detalhar o 78 e salvar | O Clássico lê e grava as mesmas colunas sem erro | A listagem mostra o 78 com a descrição nova; o detalhe traz descrição, Tipo de índice 2, DI 2, Tipo de valor 1 e ordenação 77 (os valores gravados pela API). Salvar no Clássico (descrição e ordenação de volta para "QA164850 livre" e 255) respondeu "Alteração realizada com sucesso". Isso também restaurou o 78 | **Passou** (ressalva: a releitura do 78 pela API não foi feita, porque o login do root derrubou os tokens) |

Nota de método: o login do front novo só aceita digitação tecla a tecla (`browser_type` com `slowly`); `fill` deixa a senha "obrigatória". O navegador embutido do Claude não conseguiu logar; o Playwright conseguiu.

## Consolidação final (2026-11-11) — matriz Oracle x SQL Server
Decisão da usuária (2026-11-11): **pular os cenários que envolvem processo** (#12 a #20, #22 e #45) neste banco. Ficam `NAO EXECUTADO` por decisão da usuária, não por defeito.

**Totais SQL Server (base share_carol): 27 Passou, 0 Falhou, 21 não executados** (11 de processo por decisão da usuária; #34 e #35 licença; #9 e #44 ECM-BE; #27, #40, #41, #47 e #48 hipóteses; #46 parcial).
**Totais Oracle (relatório 2026-11-09): 37 Passou, 0 Falhou, 11 não executados.**
Nenhuma diferença de comportamento entre os bancos nos 27 cenários executados nos dois (#43 só existe no SQL Server).

| # | Cenário (resumo) | Oracle | SQL Server |
|---|---|---|---|
| 1 | Leitura de tipo em uso (`st_em_uso = 1`) | Passou | Passou |
| 2 | Leitura de Seleção com valores | Passou | Passou |
| 3 | Leitura de tipo livre | Passou | Passou |
| 4 | Alterar tipo livre (tipo e valor) | Passou | Passou |
| 5 | Alterar só a descrição de tipo em uso | Passou | Passou |
| 6 | Inativar sem vínculo, usado em documentos | Passou | Passou (API + SQL) |
| 7 | Salvar sem mudar Ativo | Passou (ressalva) | Passou (ressalva: sem foto anterior) |
| 8 | Reativar | Passou | Passou (API + SQL) |
| 9 | Tipo inativo some do lançamento/busca (ECM) | Não executado (ECM-BE) | Não executado (ECM-BE sem URL/token) |
| 10 | Excluir Seleção com opções | Passou | Passou (API + SQL + log) |
| 11 | Log de Alteração | Passou | Passou (SQL: logs de 10/11) |
| 12 | Inativar com etiqueta | Passou | Não executado (processo, pulado pela usuária) |
| 13 | Inativar com Início com Publicação | Passou | Não executado (processo, pulado) |
| 14 | Mesmo processo nas duas origens | Passou | Não executado (processo, pulado) |
| 15 | Nomes parecidos de processo | Passou | Não executado (processo, pulado) |
| 16 | Ordem da lista de processos | Passou | Não executado (processo, pulado) |
| 17 | Texto da inativação bloqueada | Passou (texto do CA 55) | Não executado (processo, pulado) |
| 18 | Excluir com vínculo | Passou | Não executado (processo, pulado) |
| 19 | Vínculo e documentos juntos | Passou | Não executado (processo, pulado) |
| 20 | Inativo e vinculado, outro campo | Passou | Não executado (processo, pulado) |
| 21 | Excluir tipo não Seleção sem vínculo | Passou | Passou (API + SQL) |
| 22 | Rejeição não gera log | Passou | Não executado (processo, pulado) |
| 23 | Em uso: alterar Tipo de índice | Passou | Passou |
| 24 | Em uso: alterar Tipo de valor | Passou | Passou |
| 25 | Seleção com valores, sem documento | Passou | Passou |
| 26 | Múltipla Seleção com opções | Passou | Passou (ressalva: ordem das validações, DI antes do "em uso") |
| 27 | Atomicidade na inativação (HIPÓTESE) | Não executado | Não executado (lacuna) |
| 28 | Excluir usado em documento | Passou | Passou |
| 29 | Excluir com FK em TIPO_DOCUMENTO_TIPO_INDICE | Passou | Passou (API + SQL) |
| 30 | Excluir código 0 | Passou | Passou |
| 31 | Excluir código inexistente | Passou | Passou |
| 32 | Sem exclusão em lote | Passou | Passou |
| 33 | Sem sessão (PUT e DELETE) | Passou (403, obs.) | Passou (403 sem token; 401 só com token de usuário) |
| 34 | Sem permissão no menu de Configurações | Não executado | Não executado (licença: sem usuário de teste) |
| 35 | Sem permissão de gerenciar índices | Não executado | Não executado (licença: sem usuário de teste) |
| 36 | Seleção sem valores e sem uso | Passou | Passou |
| 37 | Valores dos documentos após inativar | Passou | Passou (API + SQL) |
| 38 | Alteração concorrente | Passou (mesma conta) | Passou (mesma conta) |
| 39 | Exclusão de tipo já excluído | Passou (mesma conta) | Passou (mesma conta; SQL + log) |
| 40 | Falha técnica no PUT (HIPÓTESE) | Não executado | Não executado (lacuna) |
| 41 | Erro de banco não FK no DELETE (HIPÓTESE) | Não executado | Não executado (lacuna) |
| 42 | SQL parametrizado | Passou | Passou |
| 43 | Clássico depois de alterar pela API | Não executado | Passou (Playwright, root) |
| 44 | ECM após reativar | Não executado (ECM-BE) | Não executado (ECM-BE) |
| 45 | Início com Publicação (engine net8) | Passou (bloqueio; engine = lacuna) | Não executado (processo, pulado) |
| 46 | SQL Server e Oracle (23, 6, 18, 10, 29 nos dois bancos) | — | **Parcial: #23, #6, #10 e #29 Passou nos dois bancos; #18 só no Oracle (exige processo, pulado)** |
| 47 | Exclusão de tipo com cd_documento (HIPÓTESE) | Não executado | Não executado (lacuna CA 67 x D-01) |
| 48 | Log do documento excluído (HIPÓTESE) | Não executado | Não executado (lacuna) |

**#46 (CA 98):** 4 dos 5 cenários nomeados no mapa têm o mesmo resultado nos dois bancos (#23, #6, #10, #29, inclusive as mensagens e os logs). O #18 não foi repetido no SQL Server porque depende de processo. Conclusão: **paridade provada para #23, #6, #10 e #29; #18 pendente**. O CA 98 fica **parcialmente atendido** até o #18 rodar no SQL Server.

## Atualização da matriz (2026-11-11, depois de montar o processo)
Os cenários **#12 a #20 e #45** (linhas "Não executado (processo, pulado)" acima) foram executados e **Passaram** no SQL Server, com o mesmo resultado do Oracle (ver a seção "Cenários de processo"). O **#22** aguarda o SELECT de log. O **#46** passa a **Passou**: #23, #6, #18, #10 e #29 têm o mesmo resultado nos dois bancos.
**Totais SQL Server atualizados: 37 Passou, 0 Falhou, 11 não executados** (#22 pendente de SQL; #34 e #35 licença; #9 e #44 ECM-BE; #27, #40, #41, #47 e #48 hipóteses). Oracle: 37 Passou, 0 Falhou, 11 não executados.

## Estado final da massa no SQL Server
- Tipos de índice: 78 (livre, restaurado; descrição e ordenação restauradas pelo Clássico), 81 (restaurado), 83 (restaurado), 82 (inativo, #6), 84 (ativo, #8), 85, 86, 87, 89 (Informado, #36), 90, 91 mantidos. Excluídos pelos cenários: 79, 80 e 88.
- Tipos de documento 24 e 25 e o documento publicado no 24 permanecem.
- Nada de processo foi criado no SQL Server.
- Banco do ambiente: **continua em SQL Server (share_carol)**. Para voltar ao Oracle, seguir o APR-018 ao contrário.

## Cenários de processo (2026-11-11) — executados depois de a usuária pedir para montar o processo
Massa: processo 89 "processo claude" (liberado) e cópias "Compras TI", "Compras" e "Almoxarifado" (ver relatório de validação). Tokens capturados pelo Claude do DevTools (Playwright, endpoint `GET api/api/TipoIndice`), lidos de arquivo temporário já apagado, sem aparecer no chat.
Resposta bruta (PUT `st_ativo` 1→0 no tipo 83 e no 84; nada gravado; GetOne depois: `st_ativo = 1`):
```
HTTP 500 ... "Não foi possível tornar inativo este registro, pois o mesmo está sendo utilizado no(s) seguinte(s) processo(s): Almoxarifado, Compras, Compras TI, processo claude."
```
| # | Ação | Esperado | Obtido | Resultado |
|---|---|---|---|---|
| 12 | PUT 83 inativar (etiqueta do 89) | rejeita com lista; nada gravado | 500 com a mensagem acima; `st_ativo = 1` | Passou (ressalva: ponto final, igual ao Oracle) |
| 13 | PUT 84 inativar (Início com Publicação) | rejeita com lista | 500 com a mesma mensagem; `st_ativo = 1` | Passou (ressalva: ponto final) |
| 14 | 83 está na etiqueta **e** no Início do mesmo processo | o processo aparece uma só vez | "processo claude" aparece uma vez, apesar das duas origens | Passou |
| 15 | "Compras" e "Compras TI" | os dois aparecem | lista traz "Compras" e "Compras TI" | Passou |
| 16 | ordem da lista | alfabética, sem repetição | Almoxarifado, Compras, Compras TI, processo claude | Passou |
| 17 | texto da inativação bloqueada | texto do CA 55 (o do CA 72 é do FE) | "Não foi possível tornar inativo este registro, ..." | Passou conforme o CA 55 (ressalva: ponto final; texto do CA 72 é do FE, divergência do mapa) |
| 18 | DELETE 83 (vinculado) | rejeita com lista, sem repetir; nada excluído | 500 "Não foi possível excluir este registro, pois o mesmo está sendo utilizado no(s) seguinte(s) processo(s): Almoxarifado, Compras, Compras TI, processo claude."; GetOne 200 | Passou (ressalva: ponto final) |
| 19 | DELETE 83 (vinculado e com documentos, `st_em_uso = 1`) | prevalece a mensagem com a lista | mesma resposta do #18 | Passou |
| 20 | PUT 82 (inativo, vinculado ao Início) só descrição, Ativo igual | aceita (CA 55) | 200; `st_ativo = 0` mantido; descrição restaurada | Passou conforme o CA 55 (divergência do Clássico segue para a PM) |
| 45 | DELETE 84 (índice chave do Início com Publicação) | exclusão bloqueada | 500 com a lista; GetOne 200, `st_ativo = 1` | Passou na parte de bloqueio; "consultar a engine" = lacuna, como no Oracle |
| 22 | tentativas rejeitadas não geram log | nada em LOG_APLICACAO (19) | API rejeitou todas; falta o SELECT de log | **Pendente (SQL)** |

**Prova de que as cópias herdaram o vínculo:** a lista de processos nas rejeições traz os quatro processos (a cópia por "Processo Existente" levou o Início e a etiqueta).

**#46 (CA 98) fechado:** #23, #6, #18, #10 e #29 têm o mesmo resultado no Oracle e no SQL Server. Paridade provada para os cinco.

SQL do #22 (somente SELECT, SQL Server):
```sql
SELECT cd_log_aplicacao, cd_chave, cd_tipo_acao, dt_acao, LEFT(CAST(ds_conteudo AS VARCHAR(MAX)), 80) AS inicio
  FROM LOG_APLICACAO
 WHERE cd_tipo_aplicacao = 19 AND cd_chave IN (82, 83, 84)
   AND dt_acao >= DATEADD(DAY, -1, CAST(GETDATE() AS DATE))
 ORDER BY dt_acao;
-- Esperado: 83 e 84 só com Inclusão e as Alterações do dia 10/11 (#7 e #8); nenhum log de 11/11 para 83 e 84 (as tentativas rejeitadas de hoje).
-- 82: Inclusão, a Alteração do #6 (10/11) e 2 Alterações do #20 (11/11, descrição e restauração), pois o PUT do #20 foi aceito.
```

## #22 — SELECT de log (retorno colado pela usuária em 2026-11-11)
| Tipo | Logs retornados | Leitura |
|---|---|---|
| 83 | Inclusão (10/11 17:03) e 2 Alterações (10/11 17:39, os 2 PUT do #7) | **nenhum log de 11/11**, apesar de 1 PUT e 1 DELETE rejeitados hoje (#12, #18, #19) |
| 84 | Inclusão e 4 Alterações (10/11 17:39: inativar e reativar, duas vezes, #8) | **nenhum log de 11/11**, apesar de 1 PUT e 1 DELETE rejeitados hoje (#13, #45) |
| 82 | Inclusão, 1 Alteração (10/11, #6) e 2 Alterações (11/11 08:58:50) | as 2 de 11/11 são do #20 (PUT aceito e a restauração): esperado |

**#22: Passou** no SQL Server. Rejeição não gera log (mesmo resultado do Oracle).

**Totais finais SQL Server: 38 Passou, 0 Falhou, 10 não executados** (#34 e #35 licença; #9 e #44 ECM-BE; #27, #40, #41, #47 e #48 hipóteses; #46 foi marcado como Passou na atualização acima). Oracle: 37 Passou, 0 Falhou, 11 não executados.
Diferenças entre os bancos: nenhuma nos cenários executados nos dois.

## #34 e #35 — usuários informados pela usuária (2026-11-11, SQL Server)
Credenciais passadas no chat, não gravadas. Tokens obtidos pelo `POST coreApi/api/v1/Usuario/autenticar` (resposta traz `token` = X-User-Authorization e `tokenApi` = Authorization); nada impresso. Alvo: tipo 85 ("doc exclusao", em uso: o DELETE, se permitido, ainda seria rejeitado por uso).
| # | Usuário | Perfil lido na autenticação | Ação | Esperado | Obtido | Resultado |
|---|---|---|---|---|---|---|
| 34 | `carol3` (cd 11, leitor) | `idTipoUsuario = 3` (não administrador), área 366, papel 13 | GET listagem, GET GetOne 85, PUT 85, DELETE 85 | 403, nada executado | **403 nos quatro**; GetOne do root depois: 85 intacto | **Passou** |
| 35 | `caroline.oliveira9` (cd 33) | `idTipoUsuario = 1` (**administrador**), área 293, papel 7 | GET listagem, GET GetOne 85, PUT 85 (só descrição), DELETE 85 | 403 | GET 200, GetOne 200, **PUT 200**, DELETE 500 "…está sendo utilizado" | **Não aplicável: pré-requisito não atendido** |
Leitura do #35: esse usuário é administrador (`idTipoUsuario = 1`), que pelo APR-013 é a regra de "permissão de gerenciar índices" no net8. O PUT 200 é o comportamento correto para quem tem permissão, não um defeito. O cenário exige um usuário **autenticado, com acesso à listagem e sem permissão de gerenciar índices**; hoje, com a regra "só administrador", o `carol3` (não admin) já leva 403 até na listagem, então a combinação "lista mas não gerencia" **não existe**. Isso é **lacuna** (a US/CA 96 não define o que dá acesso à listagem sem gerenciar) e vira pergunta para a PM/dev.
Efeito colateral: o PUT do #35 trocou a descrição do 85 para "QA164850 doc exclusao #35"; **restaurada** para "QA164850 doc exclusao" (PUT 200).

## Decisão da usuária sobre o #35 (2026-11-11)
**#35 = Não aplicável**, por decisão da usuária. Motivo registrado: com a regra atual (APR-013: só administrador gerencia índices; o `carol3`, não administrador, já leva 403 na listagem), não existe usuário "com acesso à listagem e sem permissão de gerenciar"; o `caroline.oliveira9` é administrador. O CA 96 não define o que dá acesso só à listagem (lacuna, sem Bug).
**Totais SQL Server finais: 40 Passou (inclui #46 e #34), 0 Falhou, 1 Não aplicável (#35), 7 não executados** (#9 e #44 ECM-BE; #27, #40, #41, #47 e #48 hipóteses). Soma: 48. (Os totais anteriores desta página, 37 e 38, não contavam #46, #34 e #35.)

## #9 e #44 — ECM-BE (2026-11-11, `http://localhost:44311/`, subido pela usuária)
Auth do ECM (`SessionAuthenticationFilter`): `Authorization: Bearer <token>` com o `token` do `autenticar` do core (root); o `tokenApi` não serve (500). A porta 44341 que a usuária citou antes era o BPM-BE. Chamadas somente de leitura no ECM; as alterações de estado foram pela API net8 no tipo **85** ("QA164850 doc exclusao", associado ao tipo de documento 24, sem vínculo de processo).
Como o ECM decide (`lida-no-codigo`): busca avançada `POST api/v1/tipoindice` (`TipoIndiceController.List` → `ListarIndicesBuscaAvancada`); lançamento `GET api/v1/tipodocumento/{cd}?stPostDocument=true` (`Tipo_DocumentoBLL.cs:182`: só `StAtivo && StFixoLancamento`).
| Etapa | Busca `POST tipoindice [24]` (`cdTipoIndice`) | Lançamento `GET tipodocumento/24?stPostDocument=true` |
|---|---|---|
| 85 ativo (e, para o lançamento, com `st_fixo_lancamento = 1`) | 81,82,83,84,85 | [85] |
| **#9** PUT net8 `st_ativo` 1→0 no 85 (200) | **81,82,83,84** (85 sumiu) | **[]** (85 sumiu) |
| **#44** PUT net8 `st_ativo` 0→1 no 85 (200) | **81,82,83,84,85** (85 voltou) | **[85]** (85 voltou) |
Antes do teste, com o 82 inativo (e associado ao tipo 24), a busca já omitia o 82: confirmação adicional do #9.
| # | Esperado | Obtido | Resultado |
|---|---|---|---|
| 9 | tipo inativo não é oferecido no lançamento nem na busca (CA 58) | 85 inativo ausente nos dois | **Passou** |
| 44 | ao reativar, o tipo volta a ser oferecido (CA 57 e 58) | 85 reativado presente nos dois | **Passou** |
Efeitos na massa: `st_fixo_lancamento` do 85 voltou a 0 (restaurado); 85 ficou ativo. **O 82 ficou ATIVO** (em uma tentativa inicial reativei o 82 e não deu para inativar de novo: ele é índice chave do Início com Publicação do processo 89, então a inativação é bloqueada pela regra do #13). Não afeta os resultados anteriores; o #6, #37 e #20 já tinham sido executados com o 82 inativo.

**Totais SQL Server finais: 42 Passou (inclui #9, #44, #46, #34), 0 Falhou, 1 Não aplicável (#35), 5 não executados** (hipóteses #27, #40, #41, #47 e #48). Soma: 48.

## #26 — repetição com o DI compatível (2026-11-11, SQL Server, tipo 90)
Regra de compatibilidade lida no código (`TipoIndiceRules.cs:70`, `DiPermitidoPorTipo`): Seleção(1) aceita DI 1 ou 2; Informado(2) aceita DI 2 ou Consulta; Específico(3) só DI 3; Múltipla Seleção(4) só DI 4.
PUT no 90 (Múltipla Seleção, `st_em_uso = 1` pelas 2 opções), enviando o DI compatível com o tipo novo:
| Alteração | Resposta |
|---|---|
| tipo 4→1, DI 1 | 500 "Tipo de índice e Tipo de valor não podem ser alterados, pois o índice está em uso." |
| tipo 4→1, DI 2 | idem |
| tipo 4→2, DI 2 | idem |
| tipo 4→3, DI 3 | idem |
| valor 1→2 e 1→3 (DI 4) | idem |
`GetOne` depois: igual ao de antes (tipo 4, valor 1, DI 4). **Conclusão:** com o DI coerente, a mensagem é sempre a de "em uso"; a mensagem de DI do primeiro teste vinha só de eu ter alterado o tipo sem acompanhar o DI. A ordem das validações (DI antes de "em uso") continua existindo no código, mas não aparece para o front, que envia o DI coerente. **#26: Passou, sem ressalva funcional** (a observação de ordem fica como informação para o dev).

## Ainda sem execução neste banco
| # | Motivo |
|---|---|
| 12 a 20, 22, 45 | Processo com etiqueta e Início com Publicação ainda não existe no SQL Server (massa a recriar no Clássico). |
| 34, 35 | Sem usuário sem permissão: o limite de licença do SQL Server impede criar usuários; Claude-adm só existe no Oracle. |
| 9, 44 | ECM-BE sem URL/token. |
| 43 | Clássico: `TipoIndice.aspx` é acessível agora no painel; execução pendente de decisão. |
| 27, 40, 41, 47, 48 | HIPÓTESE no mapa (lacuna de especificação). |
| 46 | Consolidação Oracle x SQL Server (este relatório vira a matriz ao final). |

## SQL de conferência
`US-164850_2026-11-10_conferencia-sqlserver.sql` (mesma pasta). Somente SELECT, para a usuária rodar no SQL Server e colar o retorno.

## Observações
- Sem alteração de comportamento entre os bancos nos 28 cenários de API executados.
- A ordem das validações no #26 (DI antes do "em uso") não aparece nos cenários do Oracle; o FE envia DI coerente, então não é defeito evidente.
- Massa consumida: 79, 80 e 88 excluídos; 89 ficou como Informado (#36); 82 inativo (#6); 84 ativo; 78, 81 e 83 restaurados.
