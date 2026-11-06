# Execução — Mapa de Testes #164883 Mapa de teste (US 164848, validação do BE via API)

**Ambiente:** HMG (http://localhost:8080/smartshare/), banco Oracle (leitura de string vazia como NULL), mesmo banco no Clássico e na net8 (total de 149 tipos nos dois, antes do cenário #7).
**História relacionada:** #164848 Migração tela de gerenciamento | Gerenciamento de índice (BE) | Cadastro do tipo de índice
**Modo:** A (mapa completo), escopo reduzido ao BE, a pedido da usuária, depois que o gate de dado simulado (Step 0.5) parou a execução pela tela. Bug #166156 aberto para o Salvar do front.
**Como foi executado:** chamadas diretas `POST /api/api/TipoIndice` e `GET .../GetOne` com a sessão do `Claude-adm` (token de cliente + token de usuário capturados da própria tela, não gravados aqui). Nada foi feito pela tela de Novo índice.
**Rastreabilidade:** classificação por evidência de API (status HTTP, mensagem e leitura de volta pelo GetOne); log de aplicação e banco não consultados (sem acesso).

## Resumo
- Executados: 36
- Passou: 36 (8 com ressalva, ver "Ressalvas"; 11 divergentes no double-check)
- Falhou: 0 (#38 reclassificado como Passou em 2026-11-05, por decisão da usuária: CA 95 aceita 401/403)
- Não executado: 29

## Detalhe por cenário
| # | Cenário | Obtido | Resultado |
|---|---|---|---|
| 1 | Inclusão válida (Informado) | 200, cd 1120, GetOne confere | Passou* (log aplicação 19 não verificado) |
| 2 | Inclusão só com Descrição | 200, cd 1121, todos os padrões do CA 16 conferem | Passou |
| 3 | Específico + Identificador 50 | 200, cd 1122, DI=3 | Passou |
| 4 | Múltipla Seleção | 200, cd 1123, DI=4 | Passou |
| 6 | Criado no Share 4, aberto no Clássico | Clássico lista os registros e abre o Detalhar do 1136 com os valores gravados | Passou |
| 7 | Criado no Clássico, aberto no Share 4 | Clássico criou o cd 1144; a API lê sem erro | Passou* (só leitura; alterar no Share 4 sem endpoint) |
| 15 | Descrição vazia | 3 variações → 500 "Descrição: Este campo é requerido." | Passou (mensagem com prefixo "Descrição:") |
| 16 | Limite da Descrição | 50 ok (cd 1124); 51 rejeita | Passou |
| 17 | Limite do Identificador | 50 ok (cd 1122); 51 rejeita | Passou |
| 18 | Limite da regex | 500 ok (cd 1125); 501 rejeita | Passou |
| 19 | Limite da máscara | 150 ok (cd 1126); 151 rejeita | Passou |
| 20 | Domínio Tipo de índice | 1–4 aceitos; 0 e 5 rejeitados | Passou |
| 21 | Domínio Tipo de valor | 1–3 aceitos; 0 e 4 rejeitados | Passou |
| 22 | Domínio DI | 0 e 6 rejeitados | Passou |
| 23 | Ordenação 1 e 255 | cd 1127 e 1128 | Passou |
| 24 | Ordenação 0 e 256 | rejeita com a mensagem do CA 17 | Passou |
| 25 | Ordenação vazia, 10.5, abc | rejeita com a mensagem do CA 17 | Passou |
| 26 | Tipo × DI permitidos | 6 combinações aceitas (cd 1129–1131, 1120, 1122, 1123) | Passou |
| 27 | Tipo × DI proibidos | 4 rejeitadas | Passou |
| 28 | Escolha Única fora de Seleção | Informado com 1 grava 0 (cd 1132); Seleção com 1 grava 1 (cd 1140) | Passou |
| 29 | Identificador fora de Específico | "abc" não gravado (cd 1133; Oracle lê vazio como NULL) | Passou |
| 30 | Regex válida | 500 chars gravados (cd 1125) | Passou |
| 31 | Regex inválida "(" | 500 "Expressão regular inválida."; nada gravado | Passou* (log) |
| 32 | Máscara MFP válida | 150 chars gravados (cd 1126) | Passou |
| 33 | Máscara com Tipo de valor Data | gravada vazia (cd 1134) | Passou |
| 34 | Máscara com tipo ≠ Informado | gravada vazia (cd 1135) | Passou |
| 35 | Flags de exibição | A (cd 1136) e B (cd 1137) persistem; `st_portal_cliente=1` não persiste (ambiente sem Portal) | Passou* |
| 37 | Portal do cliente sem Portal | `st_portal_cliente` fica 0; `Lookups.possuiPortal=false` | Passou |
| 38 | Sem sessão válida | sem headers → 403; Bearer inválido → 403 (esperado 401) | Passou (reclassificado; CA 95 aceita 401/403) |
| 39 | Sem permissão no menu: incluir | publicador (tipo 2) → 403 | Passou* (alterar sem endpoint) |
| 40 | Sem permissão de gerenciar: incluir | publicador → 403; nada gravado | Passou* (o usuário também não acessa a listagem) |
| 45 | Texto com aspas e SQL | gravado literal (cd 1138) | Passou |
| 47 | Duas inclusões simultâneas | cd 1142 e 1143 | Passou* (logs não verificados) |
| 48 | Rejeição não grava nem loga | 23 rejeições, total 125 → 125 | Passou* (log) |
| 53 | Detalhe do Clássico | abre sem erro (cd 1136) | Passou |
| 60* | HIPOTESE: descrição duplicada | bloqueia com "Já existe um índice com esta descrição." (também sem diferenciar maiúsculas) | Observação, não classificado |

(*) ver "Ressalvas".

## Ressalvas e achados
- **HTTP 500 para validação de negócio:** todas as rejeições devolvem 500 (o CA 99 só trata erro técnico). Sugiro confirmar com o dev se deveria ser 400.
- **#38 (era Falhou, reclassificado como Passou):** sem sessão e com token inválido o backend responde 403, não 401. Causa lida no código (`Share4UserAuthorizationMiddleware.cs:51-57`, lida-no-codigo): para rotas de gerenciamento (inclui `/TipoIndice`), se não houver claims Share4 válidas ou o papel não for "1" (Administrador), responde 403; o 401 só sai quando as claims são válidas mas o token não está ativo (linhas 45-49). Comportamento deliberado, não do gateway. O CA 95 da US aceita "401/403"; o mapa (#38) foi mais específico ("401"). Conclusão: não há evidência para Bug; recomendação de reclassificar o #38 como Passou (decisão da usuária) ou, se a PM quiser 401 para "sem sessão", abrir melhoria. O 401 do token inativo não foi exercitado.
- **#39 e #40 não se distinguem:** o mesmo trecho do middleware devolve 403 a qualquer usuário não administrador (confirma a regra do APR-013, tipo Administrador), então a barreira de menu e a de "gerenciar" são a mesma no BE.
- **Mensagem do CA 11:** vem como "Descrição: Este campo é requerido." (CA diz "Este campo é requerido").
- **Oracle:** string vazia é lida de volta como NULL (POST devolve ""). Equivale ao "vazio" esperado, mas vale registrar.
- **Sem endpoint de alteração:** `TipoIndiceController.cs` (lida-no-codigo) só tem GET, GetOne, Lookups e POST. Os cenários de alteração dependem disso e ficam NAO EXECUTADO (decisão do dev/PO: lacuna da US ou escopo de outra US).
- **Log e banco:** LOG_APLICACAO e leitura direta do banco não estão acessíveis; todo "log" do esperado ficou sem verificação.

## Steps não executados
| # | Motivo |
|---|---|
| 5, 9, 10, 11, 12, 13, 41, 42, 44, 59 | Exigem alteração; sem endpoint de alteração no controller (e, nos #5/#9–#13/#42/#44/#59, dado legado específico não localizado) |
| 8, 55 | Lançamento de documento com o índice novo, não executado: sem tipo de documento vinculado ao índice criado; vínculo exige tela do Clássico |
| 14 | Só de tela; o front usa dado simulado (Bug #166156) |
| 36, 57 | Ambiente sem módulo Portal (`possuiPortal=false`) |
| 43, 46 | Exigem leitura do banco / LOG_APLICACAO (sem acesso) |
| 49, 50, 60–65 | HIPOTESE no mapa (os CAs 18/19, 20, 21, 64 já trazem decisão da PM: reclassificar) |
| 51, 52 | Banco do ambiente é Oracle; SQL Server indisponível; repetição no Oracle depende do #51 |
| 54, 56, 58 | Indexador DI, MFP e busca: dependem de telas de outros módulos, não tentadas |

## Registros de teste criados no HMG (não excluídos)
Códigos 1120 a 1144 (descrição iniciando com "QA164848", mais o 1138 "O'Brien'; DROP TABLE x--"). A exclusão é do escopo da BE 04; remover manualmente, se desejado.

## Valores alterados e restaurados
Nenhum valor existente foi alterado.

## Divergências da KB
Nenhuma identificada (KB não consultada para esta execução via API).

## Divergências do double-check
Double-check por subagente independente (só releu a evidência). Classificações originais mantidas; a usuária decide. CONFIRMADO: 24 dos 35 executados (#2–4, #15–21, #23–30, #32–34, #37, #38, #45). DIVERGENTE:

| # | Classificação original | Sugestão do subagente | Motivo |
|---|---|---|---|
| 1 | Passou* | Parcial | Log de Inclusão (aplicação 19) não comprovado |
| 22 | Passou | Parcial | DI 1–5 comprovados só pelas combinações do #26/#27, não como casos próprios |
| 31 | Passou* | Parcial | "Sem log" não comprovado |
| 35 | Passou* | Parcial | `st_portal_cliente=1` não persistiu; justificativa (sem Portal) plausível mas não comprovada para o valor 1 |
| 40 | Passou* | Parcial | Usuário também sem acesso à listagem: o 403 pode vir da barreira de menu, não da permissão de gerenciar |
| 39 | Passou* | Parcial | Só "incluir" testado; "alterar" sem endpoint |
| 47 | Passou* | Parcial | Logs dos 2 registros não comprovados |
| 48 | Passou* | Parcial | "Não loga" não comprovado |
| 6 | Passou | Parcial | Detalhar mostrado só para 1 registro (1136); os demais inferidos |
| 53 | Passou | Parcial | Valores 0/0/2 vieram da API, a tela do Clássico só "abriu sem erro"; nulos no banco não verificados |
| 7 | Passou* | Parcial | Alterar no Share 4 não executado (sem PUT) |

Leitura: as divergências são de parte do esperado sem evidência (log, alteração, amostragem), coerentes com as ressalvas já registradas. Na prática, os 11 cenários acima devem ser lidos como "Parcial" até haver acesso ao LOG_APLICACAO e a um endpoint de alteração.

## Complemento (2026-11-05, segunda rodada: cenários que ainda não tinham sido tentados)

| # | Resultado | Evidência |
|---|---|---|
| 43 | **Passou*** | Registro cd 1121 (criado só com Descrição, sem enviar Portal, Portal cliente e DI): o Detalhar do Clássico abre sem erro com Portal marcado, Portal do cliente desmarcado e DI Informado; a API devolve 1/0/2 (não nulos). *Banco não consultado diretamente. Print: `.playwright-mcp\classico-detalhe-1121.png` |
| 8 | NAO EXECUTADO (ambiente) | Tentado: criei o índice cd 1145 (regex `^[0-9]{3}$`, máscara `000`) e o associei ao tipo de documento 100 pelo Clássico; o lançamento não abriu: `Portal/LancamentoDocumentos.aspx` e `Gerenciamento/Publicacao.aspx` caem em `Controle/Erro.aspx` para o publicador, e o front de ECM do Share 4 (`/ecm`) responde 502 (já registrado em `/validar-ambiente`) |
| 55 | NAO EXECUTADO (ambiente) | Mesmo bloqueio do #8 (precisa do lançamento para ver regex e máscara aplicadas) |
| 54, 56, 58 | NAO EXECUTADO (ambiente) | Dependem de Indexador DI, MFP e busca de documentos, que passam pelas mesmas telas de lançamento/consulta bloqueadas. Não abri essas telas; confirmar com a usuária se há outro caminho (ex.: Indexador DI por outro link) |

**Dados criados nesta rodada:** índice cd 1145 (total de registros de teste: 1120 a 1145). **Alteração desfeita:** a associação do índice 1145 ao tipo de documento 100 foi removida e confirmada (lista voltou a 20 índices).

## Reavaliação com o mapa ajustado (card #164883 rev 8, 59 cenários, só API e dados)

A numeração mudou (cenários de tela e lançamento saíram). Mapeamento do que já foi executado e o que continua pendente.

**Já cobertos (Passou pela API):** #1*, #2, #3, #4, #13–#33 (29* e 33* com ressalva), #35, #43, #45*, #46*. (* log de aplicação não verificado.)

**Pendências**

| Pendência | Cenários | Situação |
|---|---|---|
| **Sem endpoint de alteração** (`PUT` e `PATCH /api/api/TipoIndice` → 405; `PUT /TipoIndice/1120` → 404; confirmado com sessão admin no HMG) | #5, #8, #9, #10, #11, #12 (parte salvar), #39, #40, #53; partes de #7 e #37 | Bloqueio do build: os cenários de alteração do mapa não têm o que chamar. Decisão do dev/PO (lacuna da US ou outra US) |
| **Sem leitura do banco/LOG_APLICACAO** | #6, #41, #44, #51, #52 (parte banco); parte de log em #1, #29, #45, #46 | Provados só pela API/Clássico (proxy). Precisa de credencial somente leitura da base do app |
| **SQL Server** | #49, #50 | Ambiente é Oracle |
| **Módulo Portal** | #34 | `possuiPortal=false` |
| **Hipóteses** (decisão dev/PO, e #47/#48 sem mecanismo de falha) | #47, #48, #54–#59 | Não executados por regra. Observado no HMG: #54 bloqueia; #55 Seleção com 1 grava 1 |
| **Dado legado inexistente** (varridos os 125 tipos legados via GetOne) | #12 (regex inválida), #11 (escolha ≠ 0 fora de Seleção), #40 (comparação nula), #42 (identificador/máscara indevidos) | Nenhum registro legado nesse estado; criar exigiria escrita no banco |
| **Dado legado existente, mas sem endpoint para alterar** | #5 (35 tipos com Conexão/SQL/Valor inicial/Comparação; ex.: 101, 102, 103), #53 (6 tipos Data com Fixo e Desabilitado: 122, 184, 306, 482, 840, 860), #8/#10 (9 tipos Informado com Conexão e SQL: 123, 124, 181, 185, 580, 700, 720, 740) | Dado ok; falta o endpoint |

**Divergências do mapa novo contra o obtido**
- **#38** espera "Listagem devolve 200; inclusão bloqueada". Obtido: o publicador (tipo 2) recebe **403 também na listagem**. O `Share4UserAuthorizationMiddleware.cs:51-57` bloqueia todas as rotas de gerenciamento para quem não é Administrador, então o pré-requisito "com acesso à listagem e sem permissão de gerenciar" não existe no BE. Pelo texto do mapa: **Falhou** (ou ajustar o mapa/US).
- **#36** continua pedindo "401"; obtido 403. Reclassificado como Passou por decisão da usuária (CA 95 aceita 401/403); sugiro ajustar o texto do mapa para "401/403".
- **#52** executado agora (cd 1160): `id_tipo_local_di`, regex, máscara, `st_busca`, `st_ordenacao_busca`, `vl_ordenacao` e `st_portal` voltaram como enviados; `st_portal_cliente=1` voltou 0 (ambiente sem Portal). Resultado: **Passou*** com a ressalva do Portal e sem conferência no banco. `st_portal`, `st_portal_cliente` e `id_tipo_local_di` são numéricos e não nulos (API).
- O mapa ainda diz "Sem PR vinculado"; a US agora tem PRs (30113–30117, 30119, 30336) e commits.

Registros de teste: cd 1120 a 1145 e 1160.

## Massa legada criada pelo Clássico (tentativa a pedido da usuária)

Objetivo: gerar pelo Clássico os estados que o POST do BE impede (#11, #12, #40, #42 do mapa rev 8).

| Caso | Resultado | Evidência |
|---|---|---|
| #12 regex inválida gravada | **Criado** (cd 1161, `ds_expressao_regular = "("`). O Clássico aceitou ("Inclusão realizada com sucesso") porque não valida a sintaxe. `GET GetOne/1161` devolve 200 sem erro | API; Clássico `TipoIndice.aspx` (Informado, valor Data, Data Atual) |
| #42 máscara fora de contexto | **Não reproduzível**: com valor Data, o Clássico descarta a máscara (cd 1161 ficou com máscara nula); ao trocar o tipo de Informado para Seleção no Detalhar (cd 1162), a máscara `999` também foi limpa. Identificador só é editável em Específico | API (cd 1161, 1162) |
| #11 escolha ≠ 0 fora de Seleção | **Não reproduzível pela tela**: o formulário do Clássico não tem o campo "Escolha Única" (st_escolha_multipla) | Formulário de inclusão e Detalhar |
| #40 id_tipo_comparacao nulo | **Indistinguível pela API**: os registros do Clássico (cd 1144, 1161, 1162) voltam com `id_tipo_comparacao = 0`; a API lê NULL como 0, então só o banco mostra se é nulo | API |

Registros criados nesta etapa: cd 1161 (regex inválida) e 1162 (Seleção, sem máscara). Total de registros de teste: 1120 a 1145, 1160 a 1162.
Para #11, #40 e #42 continua valendo o SQL de escrita (dev/DBA) e, para salvar, o endpoint de alteração.

## Análise de falha (/analise-falha, 2026-11-05) — veredito: NÃO abrir defeito para os 3 pontos

| Ponto | Veredito | Base |
|---|---|---|
| (1) Sem endpoint de alteração (PUT/PATCH → 405) | **NÃO** | A alteração (`PUT /api/TipoIndice`) é escopo da US 164850 / BE 04 (Análise #164859; mapa #164888 "Alteração, inativação e exclusão"), não da US 164848. O mapa #164883 tem cenários de alteração que dependem do build da BE 04 (lida-no-card). |
| (2) #38: listagem 403 para não administrador | **NÃO** | Decisão do dev registrada no mapa #164886 (CA94/CA96): permissão = ser administrador; não administrador recebe 403, inclusive na consulta; CA95: sem login ou token inválido = 403, sessão encerrada = 401. Coerente com `Share4UserAuthorizationMiddleware.cs:51-57`. Aplicado APR-010 e APR-013. Ajustar o texto de #36 e #38 do mapa #164883. |
| (3) HTTP 500 para validação de negócio | **NÃO** | Convenção global da API: `HttpResult` (Common.Api) devolve 500 sempre que há erros; o CA 99 só trata falha técnica e a US não define status para validação. Possível melhoria transversal, fora desta US. |

Histórico: Bug #165721 (Done) já tratou dado simulado no front do Gerenciamento de índices e dizia que criar/alterar/excluir ainda estavam em memória; o #166156 (aberto hoje) pode ser regressão ou continuação dele. Citar o #165721 no #166156.

## Correção e massa do #11 (2026-11-06)

**Correção:** a afirmação anterior de que o Clássico não tem o campo "Escolha Única" estava errada. O campo existe (`WebApplication/Gerenciamento/TipoIndiceForm.ascx:146-153`, `cbEscolhaUnica`, marcado por padrão) e a linha `Tr2` só fica visível com Tipo de índice = Seleção, depois do postback da troca de tipo (`TipoIndiceForm.ascx.cs:683-703`). A inclusão grava o checkbox só se a linha está visível (`TipoIndice.aspx.cs:586-589`); a alteração grava o checkbox sempre, mesmo oculto (`TipoIndice.aspx.cs:713`).

**Caso #11 criado pelo Clássico (cd 1180, "QA164848 L3 selecao escolha unica"):**
1. Incluir Seleção com "Escolha Única" marcada (grava `st_escolha_multipla = 1`).
2. Detalhar, trocar o Tipo de índice para Informado (a linha some) e Salvar ("Alteração realizada com sucesso").
3. `GET GetOne/1180` devolve 200 com `id_tipo_local = 2` (Informado) e `st_escolha_multipla = 1`: estado legado "não Seleção com escolha ≠ 0" reproduzido.

Pendente do #11: a parte "alterar sem mudar o Tipo → grava 0" depende do endpoint de alteração (US 164850). #40 e #42 seguem sem massa pelo Clássico.
Registros de teste: cd 1120 a 1145, 1160 a 1162 e 1180.

## Cenário #42 reproduzido pelo Clássico em outra base (SQL), 2026-11-06

Contexto: a usuária logou no Clássico em outra base (SQL, 19 tipos de índice, códigos 1 a 10 na primeira página) e pediu para reproduzir o #42 nela. Não é a base do HMG/Oracle dos demais testes.

| Etapa | Resultado | Evidência |
|---|---|---|
| Estado "tipo com Identificador e Máscara indevidos" | **Criado** (cd 20, "QA164848 U1 selecao mascara ident", tipo Seleção). Incluir Seleção; máscara (linha oculta por CSS) preenchida com `999` e identificador (desabilitado) liberado e preenchido com `ident indevido` pelo DOM; "Inclusão realizada com sucesso" | Clássico `TipoIndice.aspx` |
| Gravação confirmada | O Detalhar do cd 20 devolve tipo 1 (Seleção), máscara `999` e identificador `ident indevido`: o servidor do Clássico não valida tipo × máscara × identificador (`TipoIndice.aspx.cs`, `INSERT` usa `Mascara` e `strIdentificador` sem checar o tipo) | Leitura dos campos do Detalhar |
| Consultar o tipo pela API (esperado 200 sem erro) | **Não executado**: a tela do Share 4 (`/workspace/management/indice`) redireciona para o login nessa sessão; a sessão do Clássico não vale para a API do Share 4 e não tenho as credenciais desse usuário | Navegação |

Nota: esse estado foi criado pelo caminho forçado (edição do DOM), não pelo uso normal da tela. Registro de teste: cd 20 nessa base.

**Atualização (2026-11-06) — consulta via API do #42 na base SQL: não executável.** Com a usuária logada no Share 4 nessa base, `GET /api/api/TipoIndice` respondeu **401 Unauthorized** (3 tentativas na tela) e a tela voltou ao login. Pelo `Share4UserAuthorizationMiddleware.cs:45-49`, 401 sai quando o token não está ativo para o usuário na base que a API usa; indício de que a API net8 não atende a base SQL desse usuário (lido no código; a base da API não foi confirmada). O estado do #42 existe (cd 20, base SQL), mas a consulta pela API só é possível na base do HMG/Oracle.

## #49 / #50 (SQL Server × Oracle) — análise de ambiente e do código (2026-11-06)

**Execução: NAO EXECUTADO (ambiente).** A API net8 usa **uma base por instância**, definida em `ConnectionStrings:DBType` e `Schema` (`Project.Core.Api/Configurations/ApiConfig.cs:18`, `Project.Core.Infraestructure/Context/DbContextCore.cs:31-32`); o `appsettings.json` versionado traz `DBType = "Oracle"`. Não há seleção de base por usuário ou tenant (o tenant só aparece no Mailer). O HMG da API é Oracle; na base SQL em que a usuária logou no Clássico, `GET /api/api/TipoIndice` respondeu 401 (token não ativo para a base da API). Para executar o #49 é preciso uma instância da API com `DBType = SqlServer` apontando para o SQL Server (configuração de infra/dev).

**Revisão estática (lida-no-codigo, não substitui o teste):**
- Chave gerada na inclusão: `TipoIndiceExtension.cs:282` usa `dbtrans.GetIdentity("CD_TIPO_INDICE")`; o `DBTranslator.cs:322-332` devolve `RETURNING ... INTO :param` no Oracle e `SELECT CAST(SCOPE_IDENTITY() AS INT)` no SQL Server.
- Parâmetros: SQL com parâmetros nomeados; o `DBTranslator` troca `@` por `:` no Oracle.
- Busca: `TipoIndiceExtension.cs:176-207` escapa `[` no `LIKE` só no SQL Server (`isSqlServer`).
- Cenário #49 ("incluir e alterar") inclui alteração, que não existe nesta US (BE 04).
Pendente para fechar #49/#50: instância da API em SQL Server, cd gerado conferido e a mesma sequência de passos no Oracle.

**Atualização (2026-11-06) — #49/#50 encerrados sem execução.** Com o localhost apontando para o SQL e a usuária logada no Share 4, o `autenticar` do Core respondeu 200, mas `GET /api/api/TipoIndice` respondeu 401 e `validar-token` 401: a API net8 não reconhece o token nessa base (`Share4UserAuthorizationMiddleware.cs:45-49`). Indício de que a API net8 ainda está em `DBType = Oracle` enquanto o Core está no SQL (não confirmado). Para retomar: API net8 com `DBType = SqlServer` e string de conexão do SQL Server, reiniciada, e novo login de administrador no Share 4.

## Rodada na base SQL Server (2026-11-06) — #49, #50, #42 e observação das hipóteses

Condição: localhost apontando para a base SQL; sessão de administrador do Share 4 fornecida pela usuária; `GET /api/api/TipoIndice` → 200 com 20 tipos (a API net8 passou a atender o SQL). Chamadas diretas `POST /api/api/TipoIndice` + `GET GetOne` (mesmo método da rodada Oracle). Registros de teste criados: cd 21 a 49 ("QA164848 S…" e "O'Brien'; DROP TABLE x--"), além do cd 20.

| Cenário | Resultado | Evidência |
|---|---|---|
| #49 SQL Server (incluir) | **Passou*** (*alterar: sem endpoint) | Inclusões 200 com chave sequencial correta (cd 21 a 49, `SCOPE_IDENTITY` via `DBTranslator.cs:322-332`); leitura de volta confere nos 29 casos |
| #50 Oracle idêntico ao SQL Server | **Passou** (comparação com a rodada Oracle) | 21 rejeições com as mesmas mensagens; 29 inclusões com os mesmos valores; mesmo 403 sem sessão; mesmo `possuiPortal=false`; total inalterado nas rejeições (20 → 20) |
| #42 consulta de tipo com identificador/máscara indevidos | **Passou** (na base SQL) | `GetOne/20` → 200, `ds_mascara = 999`, `ds_identificador = ident indevido`, tipo Seleção |
| #1–#4, #13–#33, #35, #43, #45, #52 na base SQL | Mesmo resultado do Oracle | #45: cd 48 e 49; #52: cd 46 (`st_portal_cliente=1` voltou 0, sem Portal) |

**Diferença Oracle × SQL Server:** campos de texto vazios (`ds_identificador`, `ds_mascara`, `ds_expressao_regular`, `ds_valor_inicial_lancamento`) voltam como `""` no SQL Server e como `null` no Oracle. Equivalem a "vazio" do CA 23/27, mas o FE deve tratar os dois.

**Hipóteses observadas (decisão do dev/PO; não são Passou/Falhou):**
- #54 descrição duplicada: bloqueia ("Já existe um índice com esta descrição."), inclusive com maiúsculas diferentes.
- #55 `st_escolha_multipla` em Seleção: grava como enviado (1 → 1; 0 → 0).
- #56 DI divergente: Específico com DI=1 grava DI=3 e Múltipla com DI=1 grava DI=4 (não rejeita; vale o CA 19).
- #58 regex catastrófica `(a+)+$`: aceita no salvar (200 em 128 ms); a validação só compila a expressão, e o tempo limite de 2 s só atua se ela for executada (no lançamento).
- #59 máscara com símbolos fora do conjunto (`XX@@`): aceita e gravada.
- #57 troca Seleção↔Específico: depende de alteração (sem endpoint).

## Execução dos itens #5, #9, #10, #11, #12, #13, #41, #42, #44, #59 (2026-11-06, base SQL)

| # | Resultado | Evidência |
|---|---|---|
| 5 Alteração preserva campos | **NAO EXECUTADO** (sem endpoint) | `PUT /api/api/TipoIndice` e `PATCH` → 405; `PUT /TipoIndice/{cd}`, `POST /TipoIndice/Update` e `/Alterar` → 404 (sessão admin, base SQL); swagger 404 |
| 9 Troca Seleção→Informado | **NAO EXECUTADO** (sem endpoint) | idem |
| 10 Troca Informado→Múltipla Seleção | **NAO EXECUTADO** (sem endpoint) | idem |
| 11 Alteração de não Seleção com escolha ≠ 0 | **Parcial**: massa criada, consulta passou; alterar não executado | cd 51 criado pelo Clássico (Seleção com Escolha Única, trocado para Informado): `GetOne/51` → 200, `id_tipo_local = 2`, `st_escolha_multipla = 1`. A parte "grava 0" exige alteração |
| 12 Legado com regex inválida | **Passou*** (*salvar via POST; sem endpoint de alteração) | cd 50 criado pelo Clássico com regex `(`: `GetOne/50` → 200 sem erro; novo `POST` com a mesma regex → 500 "Expressão regular inválida." |
| 13 Descrição vazia | **Passou** (Oracle e SQL) | `POST` sem descrição → 500 "Descrição: Este campo é requerido."; total inalterado (20 → 20 na base SQL) |
| 41 Campos obrigatórios nunca nulos | **NAO EXECUTADO** (banco) | Sem leitura da base que a API usa. Proxy pela API: cd 22 (só descrição) → `st_portal = 1`, `st_portal_cliente = 0`, `id_tipo_local_di = 2`. A base `share_claudeqa` do arquivo de configuração tem 0 `TIPO_INDICE` (não é a base do app); listar outros bancos foi bloqueado pelo sistema (exploração de credencial) |
| 42 Legado com identificador/máscara indevidos | **Passou** (base SQL) | `GetOne/20` → 200 com máscara `999` e identificador `ident indevido` em tipo Seleção |
| 44 Log estruturado | **NAO EXECUTADO** (log) | Exige `LOG_APLICACAO` (aplicação 19); sem acesso à base do app |
| 59 HIPOTESE máscara fora do conjunto | **Observado** (não classificado) | `POST` com `XX@@` → 200, máscara gravada; alterar não executável |

Registros de teste criados nesta etapa (base SQL): cd 50 e 51.

**#41 — Campos obrigatórios nunca nulos: Passou (base SQL, `share_carol`).** Consulta rodada pela usuária no SSMS (`172.16.0.185\desenvolvimento`); resultado informado no chat (não lido por mim): `TIPO_INDICE` cd 22 ("QA164848 S C2 defaults", criado só com a descrição) → `ST_PORTAL = 1`, `ST_PORTAL_CLIENTE = 0`, `ID_TIPO_LOCAL_DI = 2`; contagem de tipos de teste com algum desses campos nulo = 0. Bate com a leitura pela API e com o CA 16. Pendentes com leitura do banco: #44 (LOG_APLICACAO), #40, #46, #6 e #51.

**#44 — Log estruturado: Passou (base SQL).** Linha de `LOG_APLICACAO` informada pela usuária (consulta rodada no SSMS; não lida por mim): `cd_log_aplicacao 1640362`, `cd_usuario 1`, `cd_chave 21`, `dt_acao 2026-11-06 09:59:56`, `cd_tipo_acao 1` (Inclusão), `cd_tipo_aplicacao 19`, `ds_conteudo` = "Inclusão de Tipo de Índice - cd_tipo_indice: 21, ds_tipo_indice: QA164848 SC1 Informado, id_tipo_local: 2, id_tipo_valor: 1, id_tipo_local_di: 2, vl_ordenacao: 255, st_ativo: 1, st_busca: 1, st_portal: 1, st_portal_cliente: 0, …": texto estruturado em pares campo/valor, sem HTML, para o tipo 21 criado pela API.
Efeito no #1: o log de Inclusão (aplicação 19) existe para o cd 21; "na mesma transação" não é provável por consulta (o código usa a mesma transação, mas não foi observado). #1 passa a **Passou** com essa ressalva.
Correção: a descrição dos tipos da rodada SQL é "QA164848 SC1 …" (prefixo "QA164848 S" + "C1 …"), e não "QA164848 S C1", como escrevi na nota do #41.

**#46 — Rejeição não grava nem loga: Passou (base SQL).** Contagem informada pela usuária (SSMS): 33 linhas de `LOG_APLICACAO` com aplicação 19 em 2026-11-06. Conferência: 29 inclusões válidas pela API (cd 21 a 49) + 3 inclusões pelo Clássico (cd 20, 50 e 51) + 1 alteração pelo Clássico (cd 51) = 33. As 21 rejeições (descrição, limites, domínios, ordenação, DI, regex) e as 2 tentativas de duplicidade não geraram log. (Premissa: não houve outra atividade da aplicação 19 nessa base no dia; o total fecha exatamente.)

**#40 — comparação nula: NÃO reproduzível pelo Clássico (correção da leitura anterior).** Consulta da usuária (SSMS): `ID_TIPO_COMPARACAO` dos tipos criados pelo Clássico (cd 20, 50 e 51) = **0**, e não NULL. A leitura do código ("grava NULL quando Comparação vazio", `TipoIndice.aspx.cs`) estava incompleta: a opção "Selecione" do `ddlComparacao` carrega o valor 0, e o Clássico grava 0. Portanto não há massa com `id_tipo_comparacao` nulo criada pelo Clássico; o estado só existiria em dado antigo ou por SQL de escrita. #40 segue **NAO EXECUTADO** (sem dado nulo na base). Observação: a API lê 0 para esses tipos sem erro (GetOne 200), mas isso não exercita o NULL.

**#6, #51 e #52 (parte banco) — Passou (base SQL, `share_carol`).** Resultado do `SELECT` rodado pela usuária no SSMS (não lido por mim), colunas na ordem pedida:
- cd 21 "QA164848 SC1 Informado": tipo 2, valor 1, DI 2, ordenação 255, ativo 1, busca 1, portal 1, portal cliente 0, ord. busca 0, escolha 0, fixo 0, desabilita 0, comparação 0; regex, máscara, identificador e valor inicial vazios (`''`); conexão e SQL NULL.
- cd 22 "QA164848 SC2 defaults": idêntico ao cd 21 (valores padrão do CA 16).
- cd 46 "QA164848 SC27 colunas": tipo 2, valor 1, DI **5**, ordenação **7**, ativo 1, busca **0**, portal **0**, portal cliente **0** (enviado 1, gravado 0 por não haver Portal), ord. busca **1**, regex `^[A-Z]{2}[0-9]+$`, máscara `SS000`; demais colunas como nos outros.
Tudo igual ao que a API devolveu e ao esperado do mapa; vazios são `''` (SQL Server). #51: `st_portal`, `st_portal_cliente` e `id_tipo_local_di` numéricos e não nulos nos três registros e nenhum nulo nos tipos de teste (#41). DDL versionado (`1 - Estrutura.sql`, tabela `TIPO_INDICE`): `st_portal` e `st_portal_cliente` são `tinyint NOT NULL`; `id_tipo_local_di` é `tinyint` **anulável**, ou seja, o não nulo vem do BE (CA 16), não do banco. O resultado da consulta de tipos de coluna (`INFORMATION_SCHEMA`) não foi enviado; usei o DDL versionado.

**#51 — confirmação do tipo das colunas (INFORMATION_SCHEMA, `share_carol`, informado pela usuária):** `st_portal` tinyint NOT NULL; `st_portal_cliente` tinyint NOT NULL; `id_tipo_local_di` tinyint **NULL permitido**. Contagem de tipos de teste com algum desses campos nulo = 0. Confirma o DDL versionado: o banco aceita NULL em `id_tipo_local_di`, e o valor não nulo vem do BE (CA 16). #51 fechado como **Passou**.

## #47 e #48 executados (2026-11-06, base SQL)
Mecanismo: enviar valores que o BE não valida e que o banco recusa. `POST` com `id_tipo_comparacao = 99999` e `POST` com `cd_conexao = 999999` → 500 com `errors: ["Não foi possível concluir a operação. Tente novamente ou contate o suporte."]` (`TipoIndiceController.cs`, `MsgErroTecnico`); sem SQL, stack trace ou string de conexão na resposta. Total de tipos inalterado (51 → 51): tipo não gravado (rollback). Pendente: contagem de `LOG_APLICACAO` aplicação 19 do dia continua 33 (rollback do log) e o detalhe técnico no log de aplicação do servidor.

## Cenários de alteração executados (2026-11-06, base SQL, build da US 164850 com `PUT`)
Pré-condição: API recompilada e reiniciada com o branch `origin/feature/164850-index-type-update-delete`; `PUT`/`DELETE /api/api/TipoIndice` respondem (500 "Tipo de índice não encontrado." para código inexistente). Esse branch não contém a US 164848 (verificado com `git merge-base`); as inclusões continuaram com as mesmas regras (rejeição de descrição vazia, tipo 5 e DI 5 com as mesmas mensagens).
| # | Resultado | Evidência |
|---|---|---|
| 5 | **Falhou conforme o mapa** (decisão dev/PO) | `PUT` só com descrição zera Conexão, SQL e Valor inicial; comparação cai para 0. Reenviando os 4 campos o `PUT` os preserva (cd 58). `ApplyDefaults` usa só o payload para conexão, SQL, valor inicial, regex, máscara e identificador |
| 53 | Passou* | Flags Fixo/Desabilitado preservados (cd 59) com o valor inicial reenviado; sem ele, 500 "Por favor, selecione uma data inicial." |
| 8, 9, 10 | Passou | Trocas de tipo descartam conexão, SQL, valor inicial, máscara e comparação; DI conforme o tipo (cd 60, 62, 61) |
| 11 | Passou | cd 51: escolha 1 → 0 no `PUT` sem mudar o tipo |
| 12 | Passou | `PUT` com regex `(` → 500 "Expressão regular inválida."; consulta antes do `PUT` com 200 |
| 7 | Passou | Tipo do Clássico (cd 51) alterado sem erro |
| 57 | Observado | Seleção↔Específico permitido, identificador limpo na volta |
Efeito colateral: o primeiro `PUT` de teste no cd 50 (só descrição) zerou a regex legada `(` do cd 50; o #12 foi refeito com um tipo novo. Registros de teste novos (base SQL): cd 52 a 64. Pendente de conferência no banco: contagem de `LOG_APLICACAO` aplicação 19 do dia por ação (esperado: 40 inclusões e 11 alterações).

## Contagem de logs após as alterações (2026-11-06, base SQL)
Consulta da usuária: `LOG_APLICACAO`, aplicação 19, hoje, por `CD_TIPO_ACAO`: **ação 1 (Inclusão) = 43; ação 2 (Alteração) = 11**.
Conferência: inclusões = 32 (antes: 29 pela API + 3 pelo Clássico) + 11 criadas depois (cd 54, 55, 56, 57 e 58 a 64) = 43. Alterações = 1 (Clássico, cd 51) + 10 `PUT` com 200 (cd 51, 50, 58 duas vezes, 59, 60, 61, 62, 63, 64) = 11. Os `PUT` rejeitados (sem descrição, regex inválida, valor inicial ausente) e as inclusões rejeitadas não geraram log. Correção: o "40 inclusões" que eu havia estimado esquecera 3 tipos criados na primeira tentativa (cd 54, 55, 56). Confirma o log de Alteração (ação 2) do `PUT` e reforça o #46.

## Análise de falha do #5 (/analise-falha, 2026-11-06) — veredito: NÃO abrir defeito
Esperado (mapa #164883, CA 2): `PUT` só com a descrição mantém Conexão, SQL, Valor inicial e Modo de comparação. Obtido: voltam NULL/0; reenviando os 4 campos são preservados (cd 58). Base: Análise #164859 (dev): "grava todos os campos editáveis em transação"; `TipoIndiceRules.ApplyDefaults` e `CamposAlteracao` (branch da 164850) tratam esses campos como editáveis vindos do payload; o CA 2 da US 164848 fala em "o payload preserva", ou seja, responsabilidade do FE (e o novo formulário já exibe Conexão, SQL e Valor inicial). A US 164850 não tem critério de preservação de campos omitidos. Aplicado APR-010 (decisão do dev prevalece). Sem Bug anterior relacionado (os #151450/#151100 são do #53). Falta: confirmação do dev/PO se o BE deve preservar campos omitidos; ajuste do texto do mapa (#5: "reenviando os campos") ou teste pelo FE quando o Salvar estiver integrado (Bug #166156).

## Revisão da análise de falha do #5 (2026-11-06) — veredito revisado: SIM (evidência suficiente para defeito)
A usuária apontou que o obtido diverge do critério de aceite. Reavaliado: o CA 2 diz que os campos que a tela não exibe (Conexão, SQL, Valor inicial, Modo de comparação) devem ser preservados "sem zerá-los" na alteração; o mapa o registra como "Preservar campos não enviados no payload" e o cenário #5 é verificável por API. Obtido: o `PUT` que não envia esses campos os zera (cd 58). Reforços: (a) `ApplyDefaults` já recai no valor atual para tipo, DI, ordenação, flags e comparação, mas não para os quatro campos do CA 2 (omissão provável do dev); (b) a comparação também se perde por efeito de `Normalize` quando a conexão fica nula; (c) o APR-010 foi aplicado em excesso: a Análise #164859 é silenciosa sobre campos omitidos, não decide nem cobre essa lacuna, então não sobrepõe o CA 2 literal. Critérios do veredito SIM atendidos: esperado claro, obtido comprovado (GetOne antes/depois), passos reproduzíveis, não é hipótese. Reprodução: criar tipo Informado com conexão permitida (cd_conexao 2), `ds_sql`, `ds_valor_inicial_lancamento` e comparação 1; `PUT {cd_tipo_indice, ds_tipo_indice}`; `GET GetOne` mostra os quatro campos zerados. Próximo passo possível: `/gerar-defeito` (só com confirmação da usuária). A mesma causa faz o #53 ser rejeitado quando o valor inicial é omitido.

## #34 executado (2026-11-06, base SQL, API com Portal ligado)
Como o ambiente passa a ter Portal: a API lê a chave de configuração `Portal` (`TipoIndiceService.PortalConfigKey`, `_config.GetValue("Portal", false)`); o Clássico lê `Application["Portal"]` do `appSettings` `Portal` (`Global.asax:35`). Não existe tela de módulo ou licença. Foi criado `appsettings.Development.json` com `{ "Portal": true }` no clone que a API usa (`C:\projetos_selbetti\smartshare-net8\src\3 - Core\Project.Core.Api\`), arquivo novo não rastreado, e a API foi reiniciada pela usuária (a primeira tentativa, no clone do hub, não valeu: a API roda do clone `C:\projetos_selbetti`).
Resultado: `GET Lookups` → `possuiPortal = true`; `POST` com `st_portal_cliente = 1` (cd 65) → `GetOne` devolve 1 e `st_portal = 1`; flags com Portal (cd 66) persistem; `st_portal_cliente = 0` (cd 67) → 0. **#34 Passou.** O #33 passa sem ressalva. Para o #35 voltar a valer é preciso apagar o arquivo e reiniciar a API (ou aceitar o resultado anterior, já registrado).

## Reclassificações por decisão da usuária (2026-11-06)
- **#40:** "Não executável": depende exclusivamente de `INSERT`/`UPDATE` direto no banco (regra: itens que só se produzem com escrita direta no banco ficam como não executáveis; BE e Clássico gravam `id_tipo_comparacao` = 0).
- **#37 e #39:** "Não aplicável" (o BE tem uma barreira única de administrador; sem distinção entre permissão de menu e de gerenciar).
Placar: 48 Passou, 1 Falhou conforme o mapa (#5, Bug #166233), 1 divergência do mapa (#38), 2 Não aplicável (#37, #39), 1 Não executável (#40), 6 hipóteses observadas (#54 a #59) = 59.
