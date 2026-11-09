# Pacote de evidências — double-check US #163012 (execução 2026-10-26)

Pasta de screenshots: `C:\skills-qualidade\ciclos-executados\US-163012\execucoes\evidencias_2026-10-26\` (arquivos `ev-163012-cNN-*.png`).
Ambiente: SmartShare 4.13.10 (HMG, localhost), usuário administrador. Nenhum cenário foi reexecutado por você: só avalie se a evidência sustenta a classificação.

| # | Esperado (resumo) | Obtido (evidência) | Classificação | Screenshot |
|---|---|---|---|---|
| 1 | Card "Gerenciamento de parâmetros" abre a listagem; breadcrumb Configurações > Gerenciamento de parâmetro | Clique no card levou a /workspace/management/parametro; breadcrumb "Configurações > Gerenciamento de parâmetro" (snapshot) | Passou | c01-02-listagem |
| 2 | Colunas Código, Descrição, Ações só com Editar; ordenada por Código | Colunas Código/Descrição/Ações; 50 botões Editar, 0 checkbox, 0 botão excluir; primeira linha 1, última 65 (ASC) | Passou | c01-02-listagem |
| 3 | Duas cliques no cabeçalho Código alternam crescente/decrescente | 1º clique: primeiro=111 (OrderByType=DESC); 2º clique: primeiro=1 (ASC). Requisições confirmam | Passou | (rede: sem screenshot) |
| 4 | Lazy loading de 50 em 50, sem duplicar, indicador de carregamento, fim indicado, sem nova chamada ao esgotar, sem paginação | Após rolar: 94 linhas, 94 únicas; 2 chamadas (PageIndex=0 e 1); 0 chamadas ao rolar de novo; texto final "Todos os parâmetros foram carregados."; sem paginação. Indicador de carregamento NÃO capturado (resposta local muito rápida) | Passou (ressalva) | c04-fim-lista |
| 5 | Pesquisa por parte da descrição filtra; limpar volta à lista completa | "senha" → 5 resultados, todos contêm "senha" (req ds_parametro=senha); limpar → 50 linhas | Passou | c05-pesquisa-senha |
| 6 | Tooltips "Pesquisar" e "Editar" | Botões têm atributo title="Pesquisar" e title="Editar" (tooltip nativo; não aparece em screenshot headless) | Passou | c06-tooltip-pesquisar |
| 7 | Edição do parâmetro 1: Código e Descrição desabilitados; um só campo Valor preenchido; sem "Valor atual" | Código/Descrição disabled; Valor="3"; 0 ocorrências de "Valor atual" | Passou | c07-edicao-param1 |
| 8 | Salvar envia só cd_parametro e ds_valor, grava, volta à listagem, toast "Parâmetro salvo com sucesso."; reabrir mostra novo valor | PUT body {"cd_parametro":1,"ds_valor":"4"}; URL voltou a /parametro; toast "Parâmetro salvo com sucesso." (captado na reexecução de restauração para "3"); reaberto mostrou 4 | Passou | c08-toast |
| 9 | Sensível: "Valor atual" somente leitura e "Valor" vazio | Parâmetros 10, 109, 107: input "Valor atual" readOnly=true; "Valor" vazio; texto "Deixe em branco para manter o valor atual." | Passou | sens-p10 |
| 10 | Valor atual com uma bolinha por caractere | Parâmetro 10: 7 bolinhas, qt_caracteres_valor=7; 109: 64 bolinhas, qt=64 | Passou | sens-p10, sens-p109 |
| 11 | Salvar novo valor sensível: gravado; reabrir com Valor vazio e bolinhas do novo tamanho | Parâmetro 107: PUT ds_valor="Teste#11"; toast exibido; reaberto: Valor vazio, Valor atual 8 bolinhas | Passou | c11-toast |
| 12 | Salvar sem digitar mantém o valor gravado | Parâmetro 107 (com 8 caracteres): PUT ds_valor=""; volta à listagem; reaberto: 8 bolinhas | Passou | (sem screenshot) |
| 13 | Busca/ordenação reinicia a lista do início; blocos seguintes respeitam filtro e ordenação | Com 2 blocos carregados, ao ordenar: nova chamada PageIndex=0 DESC, 50 linhas, scrollTop=0; ao rolar: PageIndex=1 DESC. Pesquisa já mostrada em #5 (PageIndex=0 + ds_parametro) | Passou | (rede) |
| 14 | Sair sem alteração volta à listagem sem modal | URL → /parametro; modal ausente | Passou | (sem screenshot) |
| 15 | Alterar e sair pelo botão Sair, breadcrumb e menu lateral abre modal "Sair sem salvar" (Voltar / Sair mesmo assim) | Os 3 pontos abriram o modal (botão Sair, breadcrumb "Gerenciamento de parâmetro", item "Configurações" do menu lateral). Texto: "Sair sem salvar / As alterações não foram salvas..." | Passou | c15-modal-sair, c15-modal-menu |
| 16 | Voltar permanece na edição com os dados | Modal fechou, URL inalterada, valor "3X" mantido | Passou | (sem screenshot) |
| 17 | Sair mesmo assim descarta e volta | Pelo menu: foi a /management/configuracoes; reaberto: valor "3" (alteração não gravada) | Passou | c17-sair-mesmo-assim |
| 18 | Esc equivale a Voltar; foco preso no modal; foco volta ao elemento de origem | Esc (2 tentativas, com e sem Tab antes): modal permanece aberto (atributo open=true), URL e valor inalterados. Tab circula só entre botões do modal (preso). Após Voltar, foco voltou ao botão de origem | Falhou | c18-esc-nao-fecha, c18-apos-esc |
| 19 | Alterações, criação e exclusão no Clássico refletem na listagem do Share 4 | Parâmetro de teste 9901 criado no Clássico: Share 4 passou a 95 e listou 9901; alterado no Clássico (valor y): Share 4 GetOne mostrou y; excluído no Clássico: Share 4 voltou a 94 sem 9901 | Passou | c19-share4-reflete-criacao, -alteracao, -exclusao |
| 21 | Sem "Novo parâmetro" nem fluxo de cadastro (lista, edição, botão lateral) | Botões na lista: Configurações, Pesquisar, Ordenar, Editar; na edição: Salvar, Sair; menu lateral sem criação. Estado vazio não observado (ver #35) | Passou | c01-02-listagem |
| 22 | Sem excluir, checkbox, lote, modal "Excluir parâmetro" | 0 checkbox; nenhum botão excluir | Passou | c01-02-listagem |
| 23 | Obrigatório vazio: erro inline e nenhuma requisição | Parâmetro 1: erro "Informe o valor"; 0 PUT | Passou | c23-obrigatorio-vazio |
| 24 | Cada parâmetro aplica a própria regra (obrigatório erra, opcional grava vazio) | Parâmetro 1 mostrou erro (#23); parâmetro 111 gravou vazio sem erro (#43) | Passou | c23, c43 |
| 25 | 2000 caracteres aceitos e gravados | Digitados 2000; PUT enviado; reaberto: 2000 caracteres gravados | Passou | (sem screenshot) |
| 26 | 2001 caracteres: tela informa limite e impede envio | Mensagem "O valor deve ter no máximo 2000 caracteres"; clique em Salvar não gerou PUT | Passou | c26-2001 |
| 27 | Campo multilinha acomoda texto com quebras de linha e grava íntegro | O campo Valor é um <input> de linha única (maxlength nulo); Enter não quebra linha; "linha1"+Enter+"linha2" resultou em "linha1linha2"; via preenchimento de texto com \n o valor voltou "linha1 linha2 linha3" após salvar (quebras perdidas) | Falhou | c27-campo-linha-unica |
| 28 | Duplo clique em Salvar: um só envio | dblclick → 1 PUT | Passou | (sem screenshot) |
| 29 | Sensível: texto visível ao digitar, sem botão mostrar/ocultar | Valor digitado "abc123XYZ" em input type=text; 0 botões de mostrar/ocultar | Passou | c29-digitacao-visivel |
| 33 | Sensível sem valor: "Valor atual" vazio, sem bolinhas/ícone/"-" | Parâmetro 107 inicial: Valor atual="" (qt 0) | Passou | sens-p107 |
| 34 | Pesquisa sem resultado: "Nenhum resultado encontrado." | Termo "zzzxyz123": texto "Nenhum resultado encontrado." | Passou | c34-sem-resultado |
| 36 | Parâmetro excluído no Clássico enquanto aberto no Share 4: erro de não encontrado e não recria | Edição de 9901 aberta no Share 4; 9901 excluído no Clássico; Salvar → PUT 500 "Parâmetro não encontrado."; tela: "Não foi possível salvar: o parâmetro não existe mais. Ele pode ter sido excluído no SmartShare Clássico."; permaneceu na edição; lista seguiu com 94 | Passou | c36-share4-salvar-excluido |
| 37 | Resposta de rede só traz quantidade de caracteres; console sem o valor | GetOne de 10/109/107: ds_valor=null e qt_caracteres_valor=7/64/0; console sem valores | Passou | (rede) |
| 43 | Parâmetro 111: limpar e salvar grava vazio sem erro | PUT {"cd_parametro":111,"ds_valor":""}; toast; reaberto vazio; valor original restaurado | Passou | c43-param111-vazio |
| 45 | Clássico continua com Listar/Detalhar/Incluir/Excluir | No Clássico: Listar (95 registros), Detalhar (alterado com sucesso), Incluir ("Registro incluído com sucesso"), Excluir ("Exclusão realizada com sucesso") | Passou | c19-classico-* |
| 46 | Demais cards do hub seguem abrindo | 6 cards (Mailer, papel, perfis, conexão, usuário, notificação): rotas abrem, listas com 50/50/12/50/16 linhas, sem respostas 4xx de API | Passou | c46-* |
| 50 | Pós-salvar sensível: volta à listagem; reabrir: Valor vazio e máscara do novo tamanho | Parâmetro 107: salvo "NovoValor50": URL → /parametro; reaberto: Valor vazio, 11 bolinhas | Passou | c50-reaberto |
| 52 | GET /parametro, GetOne e PUT enviam X-User-Authorization | Os três pedidos mostraram cabeçalho x-user-authorization | Passou | (rede) |
| 53 | Nenhuma rota/botão/formulário de cadastro; nenhum POST | Rotas /novo, /incluir, /cadastro, /criar, /editar sem id redirecionam para /workspace/; 0 POST /api/parametro | Passou | (rede) |

## Não executados (para conferir se o motivo é válido)
| # | Motivo |
|---|---|
| 20 | Protótipo Figma exige login (tela "Cadastre-se ou faça login"); sem credencial |
| 30 | Autopreenchimento do navegador: só foi verificado autocomplete="off" nos campos; o comportamento do navegador com credenciais salvas não é verificável aqui |
| 31, 32 | Falta usuário sem a permissão de acesso do Clássico (criação de usuário falha com erro 500 ORA-00907 do servidor); só o root disponível |
| 38 | Falta segundo administrador (mesma razão) |
| 35, 39, 40, 41, 42, 47, 48, 49, 51 | Cenários marcados HIPOTESE no mapa (fora de escopo por definição) |
| 44 | Exige gravar valor no parâmetro 109 (Token Autentique), cujo valor atual não pode ser restaurado; a usuária decidiu não gravar nele (usar só o 107) |
