# Execução — Mapa de Testes #164888 Mapa de teste

**Ambiente:** HMG (front http://localhost:4000/smartshare/home; API net8 http://localhost:8081/api, execução por HTTP: US de BE)
**Banco:** Oracle (confirmado pela usuária em 2026-11-09) — pendente: SQL Server (novo chat, #46)
**História relacionada:** #164850 Migração tela de gerenciamento | Gerenciamento de índice (BE) | Alteração, inativação e exclusão
**Modo:** A (mapa completo) · **Data:** 2026-11-09 · **Executado por:** Claude, com triagem da usuária
**Credencial:** JWT de acesso + JWT Share4 (usuário `unique_name=1`, administrador) colados pela usuária; não gravados. Mesma conta nas duas pontas da concorrência (#38, #39).
**Build:** `GetOne` devolve `st_em_uso` (campo novo da US, CA52); o `:8081` roda código com a US. Branch exata do `:8081` NÃO confirmada (clone local está em `feature/164848-gerenciamento-indice`). `lida-no-codigo` (swagger do `:8081`) + `vista-na-API`.

## Resumo
- **Passou:** 26 (19 pela API + 7 depois da conferência no Oracle, rodada pela usuária; #7 com ressalva)
- **Falhou:** 0
- **Não executado:** 22 (detalhe abaixo)
- Validação **parcial**: faltam o SQL Server, a massa de processo, os usuários sem permissão, o ECM-BE e o Clássico.
- Atualização da conferência no banco: ver a seção "Conferência no Oracle (resultado)".

## Detalhe por cenário executado
| # | Categoria | Ação | Esperado | Obtido | Resultado | Evidência |
|---|---|---|---|---|---|---|
| 1 | Fluxo principal | GetOne do tipo 1288 (em INDICE_DOCUMENTO) | `st_em_uso = 1` | `st_em_uso = 1` | Passou | GET `/api/TipoIndice/GetOne?cd_tipo_indice=1288` 200 |
| 2 | Fluxo principal | GetOne 1281 (Seleção com 2 opções, sem documento) | `st_em_uso = 1` | `st_em_uso = 1` (Opcoes: 2 itens) | Passou | GetOne 200; `Opcoes` total 2 |
| 3 | Fluxo principal | GetOne 1280 (livre) | `st_em_uso = 0` | `st_em_uso = 0` | Passou | GetOne 200 |
| 4 | Fluxo principal | PUT 1280: Tipo de índice 2→3 e depois Tipo de valor 1→2 | aceita e grava | 200; GetOne confirma `id_tipo_local=3`, depois `id_tipo_valor=2`. Restaurado ao original (2 / 1) | Passou | PUT 200 + GetOne antes/depois |
| 5 | Fluxo principal | PUT 1288 só descrição | aceita e grava | 200; descrição alterada, `st_em_uso` segue 1; restaurada | Passou | PUT 200 + GetOne |
| 23 | Validação | PUT 1288 alterando Tipo de índice | rejeita, nada gravado | `statusCode 500`, "Tipo de índice e Tipo de valor não podem ser alterados, pois o índice está em uso."; GetOne igual ao anterior | Passou | PUT 500 + GetOne |
| 24 | Validação | PUT 1288 alterando Tipo de valor | rejeita, nada gravado | mesma mensagem; nada gravado | Passou | PUT 500 + GetOne |
| 25 | Validação | PUT 1281 (Seleção com valores) alterando tipo e depois valor | rejeita como o #23 | mesma mensagem nas duas chamadas; nada gravado | Passou | PUT 500 ×2 + GetOne |
| 26 | Validação | PUT 1284 (Múltipla Seleção com opções) alterando tipo e depois valor | rejeita (D-03) | mesma mensagem nas duas chamadas; nada gravado | Passou | PUT 500 ×2 + GetOne |
| 28 | Validação | DELETE 1292 (usado em documento) | "…está sendo utilizado"; nada excluído | 500 "Não foi possível excluir este registro, pois o mesmo está sendo utilizado."; GetOne ainda 200 | Passou | DELETE 500 + GetOne |
| 29 | Validação | DELETE 1293 (FK em TIPO_DOCUMENTO_TIPO_INDICE) | FK vira mensagem de uso, rollback | mesma mensagem; GetOne ainda 200 | Passou | DELETE 500 + GetOne |
| 30 | Validação | DELETE código 0 | "Tipo de índice não encontrado." | 500 com exatamente essa mensagem | Passou | DELETE 500 |
| 31 | Validação | DELETE código 9999999 | "Tipo de índice não encontrado." | 500 com exatamente essa mensagem | Passou | DELETE 500 |
| 32 | Validação | procurar rota de exclusão múltipla | só a exclusão individual | swagger: `DELETE /api/TipoIndice` só com `cd_tipo_indice`; `DELETE /api/TipoIndice/Opcoes` é por opção; nenhuma rota em lote | Passou | `lida-no-codigo` (swagger `:8081/swagger/v1/swagger.json`) |
| 33 | Permissão | PUT e DELETE sem token | "401, nada executado" (CA95: 401/403) | PUT e DELETE sem token: **403**; só com o token de usuário (sem o de acesso): 401; 1280 intacto | Passou (ver observação 1) | PUT 403, DELETE 403, GetOne igual |
| 36 | Dados/borda | PUT 1283 (Seleção sem valores, sem uso) alterando Tipo de índice 1→2 | aceita | 200; GetOne confirma `id_tipo_local=2` (1283 ficou como Informado) | Passou | PUT 200 + GetOne |
| 38 | Concorrência | A salva (conc A, ord 11), depois B salva (conc B, ord 22) no 1286 | prevalece o último, sem aviso | 200 nas duas; GetOne final = conc B / 22; restaurado antes do #39 | Passou (ressalva: mesma conta) | PUT 200 ×2 + GetOne |
| 39 | Concorrência | A exclui 1286; B exclui o mesmo | B: "Tipo de índice não encontrado.", sem erro técnico | A: 200; B: 500 com essa mensagem (sem SQL nem stack) | Passou (ressalva: mesma conta) | DELETE 200 / 500 |
| 42 | Erros/API | PUT 1280 com descrição `QA164850 aspas '" ; -- DROP` | grava o texto literal | 200; GetOne devolve o texto idêntico; restaurado | Passou | PUT 200 + GetOne |

## Conferência no Oracle (resultado, informado pela usuária em 2026-11-09)
A usuária rodou `US-164850_2026-11-09_conferencia-oracle.sql` e colou o retorno. Blocos 0 a 6: "todos passaram" (declaração da usuária, sem os valores brutos no chat). Bloco 7 (log) e bloco 8 (contagem) colados na íntegra e conferidos abaixo.

| # | Resultado | Evidência no retorno |
|---|---|---|
| 6 | Passou | blocos 1/0 da usuária; log 819095: Alteração do 1289 com `st_ativo: 0` (aplicação 19, ação 2); 1 só log de Alteração (bloco 8) |
| 7 | Passou (ressalva) | bloco 3 passou (1290 ativo, mesma contagem); 1290 tem só 2 logs de Alteração (819093/819094, os dois PUT de descrição, `st_ativo: 1`). "Não tocado" não tem foto anterior para comparar |
| 8 | Passou | bloco 2 passou; log 819096: Alteração do 1291 com `st_ativo: 1` |
| 10 | Passou | bloco 4 passou (INDICE e TIPO_INDICE do 1282 com 0); log 819097: Exclusão do 1282 (ação 3) |
| 11 | Passou | logs de Alteração (ação 2, aplicação 19, chave = código) com `ds_conteudo` trazendo código, descrição e os campos do tipo (ex.: 819082 a 819089 do 1280) |
| 21 | Passou | bloco 5 passou; log 819098: Exclusão do 1285 |
| 37 | Passou | bloco 1 passou (valores do 1289 preservados com `st_ativo = 0`) |
| 39 (reforço) | segue Passou (ressalva mesma conta) | 1286 tem 1 só log de Exclusão (819099): a segunda tentativa não gerou log |

Conferência do log contra o esperado (bloco 8): 1280 = 5 Alterações (#4 ×2 + restauração, #42 ×2); 1283 = 1; 1286 = 3 Alterações + 1 Exclusão; 1288 = 2; 1289 = 1; 1290 = 2; 1291 = 2 (uma é a inativação feita na preparação do ambiente, 819078, e a outra é o #8); 1282 e 1285 = 1 Exclusão cada. **Nenhum log de rejeição:** 1281 e 1284 (#25, #26), 1292 e 1293 (#28, #29) e as tentativas #23/#24 do 1288 só têm a Inclusão original.
Isso não fecha o #22, que exige rejeição por **vínculo de processo** (sem massa); a ausência de log nas demais rejeições é evidência complementar.

## Executados na API, conferência no banco pendente (concluída acima)
| # | O que a API fez | O que falta provar no Oracle |
|---|---|---|
| 6 | PUT 1289 `st_ativo` 1→0: 200, GetOne `st_ativo = 0`, `st_em_uso = 1` | `INDICE_DOCUMENTO.st_ativo = 0` em todos os registros do tipo e log de Alteração |
| 7 | PUT 1290 só descrição, Ativo igual: 200; restaurada | `INDICE_DOCUMENTO` do 1290 não foi tocado |
| 8 | PUT 1291 `st_ativo` 0→1: 200, GetOne `st_ativo = 1` | `INDICE_DOCUMENTO.st_ativo = 1` propagado |
| 10 | DELETE 1282 (Seleção, 2 opções): 200 (`cd_documento: null`); GetOne e Opcoes agora "Tipo de índice não encontrado." | linhas de `INDICE` apagadas e log de Exclusão (aplicação 19) |
| 11 | PUT válidos executados (#4/#42) | `LOG_APLICACAO` aplicação 19, ação 2, chave = código do tipo |
| 21 | DELETE 1285 (Informado): 200; GetOne "não encontrado" | `INDICE` não tocado e log de Exclusão |
| 37 | inativação do 1289 feita no #6 | valores do 1289 continuam em `INDICE_DOCUMENTO` com `st_ativo = 0` |

### SQL para a usuária rodar no Oracle (somente SELECT)
Nomes de coluna de `LOG_APLICACAO` lidos em `Project.Core.Infraestructure/Entities/LogAplicacao.cs`. Os nomes de colunas de `INDICE_DOCUMENTO` e `INDICE` seguem o texto da US/mapa (`cd_tipo_indice`, `st_ativo`); ajustar se diferirem no esquema.

```sql
-- #6 e #37 (tipo 1289 inativado): esperado st_ativo = 0 em todos
SELECT st_ativo, COUNT(*) FROM INDICE_DOCUMENTO WHERE cd_tipo_indice = 1289 GROUP BY st_ativo;
-- #8 (tipo 1291 reativado): esperado st_ativo = 1 em todos
SELECT st_ativo, COUNT(*) FROM INDICE_DOCUMENTO WHERE cd_tipo_indice = 1291 GROUP BY st_ativo;
-- #7 (tipo 1290 só descrição): esperado st_ativo = 1 e mesma contagem de antes
SELECT st_ativo, COUNT(*) FROM INDICE_DOCUMENTO WHERE cd_tipo_indice = 1290 GROUP BY st_ativo;
-- #10 (1282 excluído): esperado 0 e 0
SELECT COUNT(*) FROM INDICE WHERE cd_tipo_indice = 1282;
SELECT COUNT(*) FROM TIPO_INDICE WHERE cd_tipo_indice = 1282;
-- #21 (1285 excluído): esperado 0
SELECT COUNT(*) FROM TIPO_INDICE WHERE cd_tipo_indice = 1285;
-- #11, #6, #10, #21: logs de hoje (aplicação 19; ação 2 = Alteração, ação 3 = Exclusão)
SELECT cd_log_aplicacao, cd_chave, cd_tipo_acao, dt_acao, ds_conteudo
  FROM LOG_APLICACAO
 WHERE cd_tipo_aplicacao = 19 AND cd_chave IN (1280, 1282, 1285, 1286, 1288, 1289, 1290, 1291)
   AND dt_acao >= TRUNC(SYSDATE)
 ORDER BY dt_acao;
```
O esperado do log do #6 (aplicação 19, ação 2, chave 1289) e do #10/#21 (ação 3, chaves 1282 e 1285). Deve haver log também para os PUT válidos de 1280, 1286 e 1288/1290 e nenhum log para as rejeições (#23 a #26, #28, #29, #30, #31).

## Não executados
| # | Motivo | Categoria da regra |
|---|---|---|
| 12 a 20, 22, 45 | Sem processo com etiqueta (`PASSO_USUARIO_TPDOC_ETIQUETA`) ou Início com Publicação (`INICIO_PUB_TPIND`) usando um tipo de teste; a tela não cria essa massa (relatório do `/validar-ambiente`) | 1 (dado de teste ausente) |
| 34, 35 | Falta o token de um usuário sem permissão; o login do `qa.publicador.us164850` não concluiu e o portal não autentica (nginx `:8080` em 502) | 1 (credencial ausente) |
| 9, 44 | ECM-BE sem URL nem token disponíveis; a única API respondendo além do net8 é o `smartshare-core` (`:55113`) | 2 (ambiente) |
| 43 | Clássico inacessível: `http://localhost:8080/smartshare/` 403 e nginx `:8080` em 502 | 2 (ambiente) |
| 27, 40, 41 | HIPÓTESE (forma de provocar a falha não descrita no card), Step 3 | hipótese não validada |
| 47, 48 | HIPÓTESE (CA 67 × card D-01 sobre `cd_documento`), Step 3; sem tipo com `cd_documento` | hipótese não validada |
| 46 | Só o Oracle nesta execução (parcial: #23, #10 e #29 Oracle OK; #6 aguarda SQL; #18 sem massa). SQL Server fica para novo chat (Step 5.5) | 2 (ambiente: 2º banco em outro chat) |

## Atualização 2026-11-10 — massa de processo e cenários #12 e #17
Massa configurada pela usuária: processo **14840 ("processo claude")**, versão 1, passo 3, etiqueta com tipo de documento 3541 e índice **1290 "QA164850 doc ativo"** (linha informada: `PASSO_USUARIO_TPDOC_ETIQUETA 14840 | 1 | 3 | 3541 | 1290 | 1 | 1`; os demais processos da tabela, 9524, são anteriores e usam outros índices). Execução por API com tokens novos (usuário Share4 `unique_name=1`).

| # | Categoria | Ação | Esperado | Obtido | Resultado | Evidência |
|---|---|---|---|---|---|---|
| 12 | Fluxo alternativo | PUT 1290 `st_ativo` 1→0 (vinculado à etiqueta do processo 14840) | rejeita com "Não foi possível tornar inativo este registro, pois o mesmo está sendo utilizado no(s) seguinte(s) processo(s): lista"; nada gravado | 500: "Não foi possível tornar inativo este registro, pois o mesmo está sendo utilizado no(s) seguinte(s) processo(s): processo claude."; GetOne depois: `st_ativo = 1` | Passou | PUT 500 + GetOne antes e depois |
| 17 | Fluxo alternativo | mesma chamada do #12 | (mapa) texto do CA 72 (Figma): "Não foi possível inativar esse registro…"; o Clássico e o CA 55 usam "tornar inativo este registro"; confirmar com a PM qual vale | a API devolve o texto do CA 55/Clássico, não o do Figma (comparação exata abaixo) | Passou conforme o CA 55 (ressalva: ponto final); o texto do CA 72 é do FE, divergência do mapa | PUT 500 + comparação de strings |

**Evidência exata do #17 (2026-11-10, 12:50 UTC, resposta bruta da API `PUT /api/TipoIndice`, tipo 1290):**
```
HTTP 500 {"statusCode":500,"result":null,"errors":[{"code":"ERROR","message":"Não foi possível tornar inativo este registro, pois o mesmo está sendo utilizado no(s) seguinte(s) processo(s): processo claude."}]}
```
Comparação caractere a caractere (processo = "processo claude"):
| Fonte | Texto |
|---|---|
| Obtido | `Não foi possível tornar inativo este registro, pois o mesmo está sendo utilizado no(s) seguinte(s) processo(s): processo claude.` |
| CA 55 (US, coluna ENTÃO) | `Não foi possível tornar inativo este registro, pois o mesmo está sendo utilizado no(s) seguinte(s) processo(s): **lista**` — "mesmo comportamento do Clássico" |
| CA 72 (US) | `Não foi possível inativar esse registro, pois o mesmo está sendo utilizado no(s) seguinte(s) processo(s): lista` — "que o FE exibe com o texto do Figma … a regra de bloqueio continua nos critérios 55, 66 e 68" |
| Clássico | `TipoIndice.aspx.cs:695`: `"Não foi possível tornar inativo este registro, pois o mesmo está sendo utilizado no(s) seguinte(s) processo(s): <b>" + processo + "</b>."` |
| Código do dev (branch `feature/164850-index-type-update-delete`) | `Services/TipoIndice/TipoIndiceRules.cs:66`, mesma frase terminada em `{processos}.`; teste `TipoIndiceRulesTests.cs:617` espera o ponto final |

Resultado da comparação: obtido == CA 55 + "." → **true**; obtido == CA 55 sem o ponto → false; obtido == CA 72 (com ou sem ponto) → false.

Análise do #17 (`/analise-falha`, resumida): a API cumpre o CA 55 palavra por palavra. A única diferença é o ponto final, que o CA 55 não escreve mas o Clássico e o código do dev têm (e o CA 55 pede o mesmo comportamento do Clássico). O texto do CA 72 é do FE; o mapa de uma US de BE esperar esse texto é defeito do mapa (APR-014). Recomendações: (1) corrigir o esperado do #17 para o texto do CA 55; (2) dev/PM confirmam o ponto final. Não gera Bug.

DELETE confirmado pela usuária em 2026-11-10 (12:54 UTC), tipo 1290 (vinculado à etiqueta do processo 14840 e com documento em `INDICE_DOCUMENTO`, `st_em_uso = 1`):

| # | Categoria | Ação | Esperado | Obtido | Resultado | Evidência |
|---|---|---|---|---|---|---|
| 18 | Fluxo alternativo | DELETE 1290 | rejeita com "Não foi possível excluir este registro, pois o mesmo está sendo utilizado no(s) seguinte(s) processo(s): lista", sem repetir processo; nada excluído | `HTTP 500 {"statusCode":500,"result":null,"errors":[{"code":"ERROR","message":"Não foi possível excluir este registro, pois o mesmo está sendo utilizado no(s) seguinte(s) processo(s): processo claude."}]}`; GetOne depois: 200, tipo existe | Passou (ressalva: ponto final, igual ao #17) | DELETE 500 + GetOne |
| 19 | Fluxo alternativo | DELETE 1290 (vinculado a processo e com documentos) | prevalece a mensagem com lista de processos (CA 66 sobre CA 68) | mesma resposta do #18: mensagem com a lista, não a de "está sendo utilizado" sem lista; o tipo tem documento (`st_em_uso = 1`) | Passou | DELETE 500 + GetOne `st_em_uso = 1` |
| 22 | Fluxo alternativo | tentar inativar (PUT 12:34 e 12:50 UTC) e excluir (DELETE 12:54 UTC) o 1290 | nada em `LOG_APLICACAO` (19) para as tentativas | API rejeitou as três; conferência do log depende do Oracle (SQL abaixo) | Pendente de SQL | PUT 500 ×2, DELETE 500 |

SQL do #22 (SELECT, rodar no Oracle; esperado: só os 2 logs de Alteração do #7, 819093 e 819094, e nenhum com horário de hoje depois deles):
```sql
SELECT cd_log_aplicacao, cd_chave, cd_tipo_acao, dt_acao, SUBSTR(ds_conteudo, 1, 80) AS inicio
  FROM LOG_APLICACAO
 WHERE cd_tipo_aplicacao = 19 AND cd_chave = 1290
   AND dt_acao >= TRUNC(SYSDATE) - 1
 ORDER BY dt_acao;
```
Seguem sem massa: #13, #14, #15, #16, #20, #45.

## Atualização 2026-11-10 (13:33 UTC) — Início com Publicação no processo 14840
A usuária editou o processo 14840 (editor de fluxo, símbolo "Início com Publicação"). O retorno de `INICIO_PUB_TPIND` ainda não foi enviado; os resultados abaixo dependem dessa confirmação para fechar #14 e #20.

| # | Ação | Esperado | Obtido | Resultado |
|---|---|---|---|---|
| 13 | PUT 1291 `st_ativo` 1→0 | rejeita com a lista de processos; nada gravado | 500 "Não foi possível tornar inativo este registro, pois o mesmo está sendo utilizado no(s) seguinte(s) processo(s): processo claude."; GetOne depois: `st_ativo = 1`. O 1291 não está em etiqueta (só o 1290 está na tabela informada), logo o bloqueio vem do Início com Publicação | Passou (ressalva: ponto final, como #17) |
| 14 | PUT 1290 `st_ativo` 1→0 | o processo aparece uma só vez na lista | 500 com "…processo(s): processo claude." (uma ocorrência); GetOne depois: `st_ativo = 1` | Resultado da API conforme; falta confirmar por SELECT que o 1290 está também em `INICIO_PUB_TPIND` do 14840 (a etiqueta já estava) |
| 20 | PUT 1289 (inativo) só descrição, Ativo igual | aceita (CA 55: bloqueia só quando Ativo muda); o Clássico diverge | 200, descrição gravada (restaurada em seguida); `st_ativo = 0` mantido | Pendente: só vale se o 1289 estiver vinculado a processo (etiqueta ou Início com Publicação); falta o SELECT |

**Retorno dos SELECTs (usuária, 2026-11-10):**
- `INICIO_PUB_TPIND`: `761 | 1291` → o Início com Publicação 761 do processo 14840 tem só o índice chave **1291**. Confirma que o bloqueio do #13 vem do Início com Publicação.
- `PASSO_USUARIO_TPDOC_ETIQUETA` do 14840: `versão 1 e 2 | passo 3 | tipo doc 3541 | índice 1290`.

Consequência:
- **#13: Passou** (vínculo confirmado por tabela).
- **#14: não satisfeito.** O 1290 está só na etiqueta; não está em `INICIO_PUB_TPIND`. O resultado do PUT (processo uma só vez) vale como evidência de etiqueta, mas **não** cobre "mesmo processo nas duas origens". Falta incluir o 1290 como índice chave do Início 761 (ou o 1291 na etiqueta).
- **#20: não satisfeito.** O 1289 não aparece em nenhuma das duas tabelas, então o PUT aceito não prova a regra do CA 55 para tipo inativo **e vinculado**. Falta vincular o 1289.

#45 depende de um DELETE do 1291 (rejeição esperada) e da parte "consultar a engine"; aguarda confirmação da usuária.

SELECTs para fechar #14 e #20 (Oracle):
```sql
SELECT cd_inicio_publicacao, cd_tipo_indice_chave FROM INICIO_PUB_TPIND
 WHERE cd_inicio_publicacao IN (SELECT cd_inicio_publicacao FROM INICIO_PUBLICACAO WHERE cd_processo = 14840);
SELECT cd_processo, cd_versao_processo, cd_passo, cd_tipo_documento, cd_tipo_indice FROM PASSO_USUARIO_TPDOC_ETIQUETA WHERE cd_processo = 14840;
```

## Cenário adicional proposto (#49) — Gerar Etiqueta mostra os tipos de documento (pedido da usuária, 2026-11-10)
Origem: a tela `Workflow/Etiqueta/GerarEtiqueta.aspx` (print da usuária) apareceu com "Não existem Anexos para serem adicionados a caixa!". **Ainda não existe no mapa #164888** e não foi executado.

| Campo | Conteúdo |
|---|---|
| # | 49 (proposto) |
| Categoria | === REGRESSÃO === |
| Cenário | Gerar Etiqueta lista os tipos de documento do índice chave configurado |
| Pré-requisitos | [AMBIENTE] build com a US #164850 implantado<br>[AMBIENTE] Clássico acessível<br>[DADOS] processo 14840 com etiqueta no passo 3 (tipo de documento 3541, índice chave 1290), com fluxo iniciado e a tarefa do passo 3 aberta<br>[DADOS] pelo menos um documento do tipo 3541 anexado ao fluxo, com valor preenchido no índice 1290 |
| Ação | Abrir a tarefa do passo 3 e acessar "Gerar Etiqueta" |
| Resultado esperado | A lista "Selecione os Tipos de Documentos" mostra uma linha por anexo no formato "<tipo de documento> - <valor do índice chave>" (ex.: "QA164850 tipo doc com indices - <valor do 1290>"), com "Selecionar Todos" e os botões "Salvar Etiqueta" e "Salvar e Gerar Etiqueta" habilitados; a mensagem "Não existem Anexos…" não aparece |
| Tipo / Técnica / Dimensão | positivo / exploratório / regressão |
| Origem | PI (etiqueta usa o índice 1290; usada no #12), pedido da usuária |

Por que a lista apareceu vazia (`lida-no-codigo`, `EtiquetaDAL.BuscarTiposDocumentosPendenteCaixa`): a lista só traz anexos do **fluxo** da tarefa cujo documento é de um tipo configurado na etiqueta **daquele passo** e que tenha **valor** em `INDICE_DOCUMENTO` para o índice chave (INNER JOIN), e que ainda não esteja em uma caixa (`ANEXO_ETIQUETA`). Sem fluxo iniciado, sem documento anexado, ou documento sem valor no índice 1290, a lista fica vazia. A consulta não filtra `st_ativo`.
Relação com a US: ela não altera essa tela; o cenário só garante que o vínculo de etiqueta montado para #12 a #19 funciona no Clássico depois das mudanças. Falha dele não é defeito da US sem análise (Step 4.2, item 9).

## Observações (não são falhas)
1. **Sem token a API devolve 403**, não 401, em PUT e DELETE. O CA95 aceita "401/403"; o mapa #33 diz só "401". Só o token de usuário, sem o de acesso, devolve 401. Decisão da PM/dev se o texto do mapa deve aceitar 403.
2. **Rejeição de negócio devolve HTTP 500** com `errors[0].message` legível (#23 a #26, #28 a #31, #39). É a convenção do `ReturnResponse` do projeto (também observada na US 164849), mas o #39 diz "sem erro técnico": a mensagem é de negócio, o status é 500. Registrar para o dev.
3. **Massa consumida:** 1282, 1285 e 1286 foram excluídos (cenários #10, #21, #39); 1283 ficou como Informado (#36). Demais tipos restaurados ao estado original (descrição, ordenação, tipos), exceto 1289 (inativo, #6) e 1291 (ativo, #8), que servem à conferência no banco.
4. Os tipos 1288, 1290, 1292, 1293 continuam no ambiente.

## Valores alterados e restaurados (Step 3.6 / 4.4)
Todos os registros alterados são massa criada pela `/validar-ambiente` para esta US (não são dados preexistentes do ambiente). Estado original conhecido por `GetOne` antes de cada PUT e restaurado: 1280, 1286, 1288, 1290. Não restaurados de propósito: 1289 (inativo), 1291 (reativado), 1283 (Informado). Nenhum campo sensível.

## Análise de falha
Nenhum cenário `Falhou`; `/analise-falha` e `/gerar-defeito` não se aplicam. As observações 1 e 2 são pontos a confirmar com dev/PM, sem evidência de defeito contra a US.

## Divergências do double-check
Sub-agente independente (só leitura do relatório). Confirmou 29 linhas e divergiu em 8. A classificação original foi mantida; a decisão é da usuária.

| # | Classificação original | Sugestão do sub-agente | Motivo |
|---|---|---|---|
| 33 | Passou | Passou parcial / a decidir pela PM ou dev | O mapa diz "401"; obtido 403 sem token (CA95 aceita 401/403). Desvio do texto do mapa, não defeito |
| 38 | Passou (mesma conta) | Parcial | Duas chamadas sequenciais com a mesma conta só mostram "último grava"; não houve duas sessões nem requisições simultâneas |
| 39 | Passou (mesma conta) | Parcial | Mesma limitação do #38; o mapa pede "sem erro técnico" e o obtido é HTTP 500 com mensagem de negócio (observação 2) |
| 4 | Passou | Passou com ressalva | "Grava" provado só pelo `GetOne`; log de Alteração fica no #11 |
| 36 | Passou | Passou com ressalva | "Sem valores" vem da massa descrita; `Opcoes` do 1283 não foi conferido antes do PUT |
| 27, 40, 41, 47, 48 | Não executado (hipótese) | motivo não é uma das 3 razões | São lacunas de especificação (forma de provocar a falha; CA 67 × D-01). Registro como `lacuna`, não como bloqueio |
| 46 | Não executado, categoria 1 | categoria 2 (ambiente) | O SQL Server fica para outro chat; é execução parcial, não dado ausente. Corrigido no quadro acima |

Se as sugestões forem aceitas, os Passou firmes caem de 19 para 16 (#33 a decidir, #38 e #39 parciais).

## Divergências da KB
Nenhuma divergência identificada (KB do produto não consultada: `C:\project personal\smartshare-kb` não existe nesta máquina; execução por API com base no card, no mapa e no swagger).

## Atualização 2026-11-10 (14:16 UTC) — vínculo do Início 761 feito pelo Claude (root, autorizado pela usuária)
- Pasta do processo no portal: 4260 ("local"). Processo 14840 estava na versão 2 (publicada, 10/11/2026 10:05) e não podia ser editada. "Revisar Processo" criou a **versão 3 (rascunho)**, copiada da 2.
- Editor de fluxo da v3: o símbolo "Início com Publicação" (célula 9) já tinha o índice chave **1291**; foram adicionadas duas linhas, **1290** e **1289**. A janela respondeu "Configurações armazenadas com sucesso!".
- **A versão 3 NÃO foi liberada** (continua rascunho; o portal mostra "Liberar Processo"). A decisão de liberar ou descartar é da usuária.
- Efeito colateral: o login do `root` no Clássico pelo Claude pode ter derrubado a sessão do `root` da usuária; depois disso a API net8 passou a devolver 401 com os tokens colados antes. #14, #20 e a repetição do #13 aguardam headers novos.

## Atualização 2026-11-10 (17:15 UTC) — #13, #14 e #20 com o Início 761 (v3) completo
Tokens novos (usuária). Início 761 da v3 do 14840 com os índices chave 1291, 1290 e 1289 (janela: "Configurações armazenadas com sucesso!").

| # | Ação | Esperado | Obtido | Resultado |
|---|---|---|---|---|
| 13 | PUT 1291 `st_ativo` 1→0 | rejeita com a lista de processos; nada gravado | 500 "…utilizado no(s) seguinte(s) processo(s): processo claude."; GetOne `st_ativo = 1` antes e depois | Passou (ressalva: ponto final) |
| 14 | PUT 1290 `st_ativo` 1→0 (1290 está na etiqueta e no Início do mesmo processo) | o processo aparece uma só vez; nada gravado | 500 com "…processo(s): processo claude." (uma ocorrência); GetOne `st_ativo = 1` | Passou (a prova de que o 1290 está em `INICIO_PUB_TPIND` vem da tela do Clássico; SELECT de confirmação opcional) |
| 20 | PUT 1289 (inativo, vinculado ao Início) só descrição, Ativo igual | aceita (CA 55: bloqueia só quando Ativo muda); o Clássico diverge (bloqueia sempre que Ativo = 0); confirmar com a PM | 200, descrição gravada e restaurada; `st_ativo = 0` mantido | Passou conforme o CA 55; divergência do Clássico segue para a PM (sem Bug); SELECT de `INICIO_PUB_TPIND` confirma o vínculo do 1289 |

Resumo geral após esta rodada: 26 + #12, #13, #14, #17, #18, #19, #20 = **33 Passou**, 0 Falhou. Pendentes: #22 (SELECT de log), #45 (DELETE do 1291 e "consultar a engine"), #15 e #16 (processos novos), #49 (proposto), #34/#35, #9/#43/#44, hipóteses, #46 (SQL Server).

## Atualização 2026-11-10 (17:17 UTC) — #45 (DELETE confirmado pela usuária)
| # | Ação | Esperado | Obtido | Resultado |
|---|---|---|---|---|
| 45 | DELETE 1291 (índice chave do Início com Publicação 761 do processo 14840) e consultar a engine | exclusão bloqueada; sem vínculo, o tipo excluído deixa de existir | `HTTP 500 {"statusCode":500,"result":null,"errors":[{"code":"ERROR","message":"Não foi possível excluir este registro, pois o mesmo está sendo utilizado no(s) seguinte(s) processo(s): processo claude."}]}`; GetOne depois: 200, `st_ativo = 1`, tipo preservado. "Sem vínculo o tipo some": já provado nos #10, #21 e #39 (GetOne "Tipo de índice não encontrado." após o DELETE) | Passou na parte de bloqueio; **"consultar a engine" = lacuna**: na branch `feature/164850-index-type-update-delete` só `TipoIndiceRepository.cs` lê `INICIO_PUB_TPIND`; nenhum endpoint da engine (`/api/v1/Engine/*`, `FluxoService`) consulta o vínculo de tipo de índice, então não há como exercitar essa metade (lacuna não vira critério de aceite) |

Total após #45: **34 Passou**, 0 Falhou. Pendentes: #22 (SELECT de log), #15 e #16 (processos novos), #49 (proposto), #34/#35, #9/#43/#44, hipóteses, #46 (SQL Server).

## Atualização 2026-11-10 — #22 (SELECT de log informado pela usuária)
Retorno do SELECT de `LOG_APLICACAO` (aplicação 19, `cd_chave = 1290`, desde ontem):
```
819061 | 1290 | ação 1 | 09/11/26 | Inclusão de Tipo de Índice - cd_tipo_indice: 1290 …   (preparação do ambiente)
819093 | 1290 | ação 2 | 09/11/26 | Alteração de Tipo de Índice - cd_tipo_indice: 1290 …   (#7, 1º PUT de descrição)
819094 | 1290 | ação 2 | 09/11/26 | Alteração de Tipo de Índice - cd_tipo_indice: 1290 …   (#7, restauração da descrição)
```
| # | Ação | Esperado | Obtido | Resultado |
|---|---|---|---|---|
| 22 | tentar inativar (PUT 10/11 12:34, 12:50 e 17:15 UTC) e excluir (DELETE 10/11 12:54 UTC) o 1290 vinculado a processo | nada em `LOG_APLICACAO` (19) para as tentativas | só aparecem a Inclusão da preparação e as 2 Alterações do #7 (09/11); **nenhum log de 10/11** para o 1290, apesar de 3 PUT e 1 DELETE rejeitados | Passou |

Total: **35 Passou**, 0 Falhou. Pendentes: #15 e #16 (processos novos), #49 (proposto), #34/#35, #9/#43/#44, hipóteses #27/#40/#41/#47/#48, #46 (SQL Server).

## Atualização 2026-11-10 (17:55 UTC) — processos para #15 e #16 (importados pelo Claude, root autorizado)
- Exportado `PRO_14840.zip` (versão 2) do processo 14840 e importado 3 vezes como "Arquivo Externo" na pasta 4260 ("local"): **Compras TI**, **Compras**, **Almoxarifado**, nesta ordem. Mapeamento usado na importação: ícone Gerenciamento, tipo de documento 3541, diretório "Diretório Padrão", documento "romano - simples - azure" (280), pasta "ECM - Claude"; vínculo Geral e papéis Default.
- A lista da pasta 4260 mostra os 3 processos novos. O log da importação confirma os anexos do tipo 3541. O vínculo dos novos processos com os índices (etiqueta 1290 e Início 1291, vindos do XML) ainda **não foi provado**: depende do `PUT` na API ou do SELECT de `PASSO_USUARIO_TPDOC_ETIQUETA`.
- Efeito colateral repetido: o login do root derrubou os tokens da usuária (API 401). #15 e #16 aguardam headers novos.

## Atualização 2026-11-10 (18:01 UTC) — #15 e #16 não executáveis ainda: as cópias não ficaram vinculadas
Tokens novos da usuária. `PUT` de `st_ativo` 1→0:
- Índice **1290**: `HTTP 500 … no(s) seguinte(s) processo(s): processo claude.` (só o processo original).
- Índice **1291**: idem, só "processo claude".
Os 3 processos importados (Compras TI, Compras, Almoxarifado) **não aparecem** em nenhuma das duas mensagens, logo a importação não trouxe a etiqueta nem o Início com Publicação (ou ficaram em estado que o bloqueio não conta). Nada foi gravado (1290 e 1291 continuam ativos).
Pendente: SELECT de `PASSO_USUARIO_TPDOC_ETIQUETA` / `INICIO_PUB_TPIND` para os 3 processos, e configurar a etiqueta (tipo 3541 + índice) em cada cópia; #15 e #16 seguem NAO EXECUTADO até lá.

## Atualização 2026-11-10 (18:50 UTC) — vínculo configurado nas 3 cópias (Claude, root autorizado)
SELECT da usuária (etiqueta): só o 14840 (versões 1, 2 e 3) tem o 1290; os processos 14860 "Compras TI", 14861 "Compras" e 14862 "Almoxarifado" não tinham etiqueta nem Início (o SELECT de `INICIO_PUB_TPIND` só trouxe 781 e 761, ambos do "processo claude"; também existe um "processo claude" 14700 sem vínculo).
Feito em cada cópia: "Revisar Processo" (cria a versão 2, rascunho) e, em `InicioPublicacao.aspx?cdA=9&cdV=2&cdP=<proc>`: tipo de documento 3541, índice chave **1290 "QA164850 doc ativo"**, periodicidade 1 (campo obrigatório), salvar. Resposta em cada uma: "Configurações armazenadas com sucesso!" (com o aviso de que o tipo de documento já inicia o "processo claude").
Versões 2 das cópias continuam em **rascunho** (não liberadas). O login do root derrubou de novo os tokens da usuária: #15 e #16 aguardam headers novos.

## Atualização 2026-11-10 (19:14 UTC) — #15 e #16 executados
Tokens novos da usuária. Massa: processos 14860 "Compras TI", 14861 "Compras", 14862 "Almoxarifado" (criados nessa ordem; Início 781/… com o 1290 nas versões 2 em rascunho) e 14840 "processo claude" (etiqueta + Início, 1290).
Resposta bruta do `PUT` de `st_ativo` 1→0 no 1290 (nada gravado; GetOne depois: `st_ativo = 1`):
```
HTTP 500 {"statusCode":500,"result":null,"errors":[{"code":"ERROR","message":"Não foi possível tornar inativo este registro, pois o mesmo está sendo utilizado no(s) seguinte(s) processo(s): Almoxarifado, Compras, Compras TI, processo claude."}]}
```
| # | Esperado | Obtido | Resultado |
|---|---|---|---|
| 15 | os dois processos "Compras" e "Compras TI" aparecem na lista (o Clássico omitiria "Compras" pela deduplicação com `Contains()`) | a lista traz "Compras" **e** "Compras TI" | Passou (ressalva: ponto final) |
| 16 | lista em ordem alfabética, sem repetição (o Clássico usa a ordem do banco) | Almoxarifado, Compras, Compras TI, processo claude, em ordem alfabética, sem repetir o "processo claude" apesar de ele estar em 3 versões e nas duas origens. A ordem de `cd_processo` seria 14840, 14860, 14861, 14862 (processo claude, Compras TI, Compras, Almoxarifado), logo a ordenação é da API | Passou |
Observação: o bloqueio enxergou as versões 2 em **rascunho** das cópias; não foi preciso liberá-las.

Total: **37 Passou**, 0 Falhou. Não executados (11): #9, #44 (ECM-BE), #43 (Clássico/regressão), #34, #35 (usuário sem permissão), #27, #40, #41, #47, #48 (hipóteses), #46 (SQL Server). Cenário proposto #49 só no relatório.

## Consolidação do banco Oracle (Step 5.5) — 2026-11-10
**Banco concluído: Oracle.** Todos os 48 cenários têm resultado neste banco: **37 Passou, 0 Falhou, 0 bloqueado por defeito, 11 não executados com motivo** (#9, #44, #43, #34, #35, #27, #40, #41, #47, #48, #46).
**Banco pendente: SQL Server (base share_carol).** A US exige os dois bancos (CA 98 e #46): **todos** os cenários devem ser executados de novo no SQL Server, em um novo chat, depois de `/validar-ambiente 164850` confirmar o banco e a base. Esta execução não troca o banco (regra da skill). Pendências conhecidas do SQL Server (relatório 2026-11-09_1720): limite de licença impediu criar o Claude-adm e os usuários de teste; senha do usuário do banco SQL Server ainda como `<preencher>` no `ambiente-teste.local.md`; a massa (tipos 1280 a 1293, processos 14840 e cópias) existe só no Oracle e precisa ser recriada.
Texto do novo chat: `/task 164850 - execução-testes 164850 - SQL Server`.
