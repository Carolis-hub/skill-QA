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
