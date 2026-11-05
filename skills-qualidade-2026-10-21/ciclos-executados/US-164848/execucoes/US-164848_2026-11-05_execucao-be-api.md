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
