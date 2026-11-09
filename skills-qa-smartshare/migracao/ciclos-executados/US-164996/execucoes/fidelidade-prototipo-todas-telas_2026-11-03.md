# Fidelidade ao protótipo: todas as telas (listagem, formulário, modais) — 03/11/2026

Complementa `fidelidade-prototipo_2026-11-03.md`, que cobria só a modal "Opções do índice" (F1 a F21). Aqui o inventário é o do Figma inteiro ("Handoff" e "Handoff - Correções", 38 quadros). Dev: smartshare-analytics, branch 160212-tela-gerenciamento-indice, janela 1280×832, dados simulados em memória (Bug #165721). Nesta execução apliquei 7 índices simulados com os dados do protótipo para ver a listagem preenchida.

Limite: comparei por captura lado a lado, leitura do código e medição de estilo computado. Os componentes `nyx-*` têm Shadow DOM, então cor e raio internos seguem como "não verificados". Menu lateral e cabeçalho são do shell compartilhado e ficam fora da conta (ver "Observações").

## Inventário de quadros e situação

| Quadro do Figma | Comparado | Resultado |
|---|---|---|
| Gerenciamento de índice (listagem, e a versão "índice incluído (toast)") | Sim | Divergente (G1 a G9) |
| Gerenciamento de índice - empty state | Sim | Divergente (G1, G10) |
| Gerenciamento de índice - busca | Sim | Divergente (G1, G11) |
| Gerenciamento de índice - busca sem resultado | Sim | Divergente (G12) |
| Excluir (confirmação) | Sim | Divergente (G13) |
| Exclusão bloqueada (em processo / em uso) e Inativação bloqueada | Textos sim; visual só pelo código | Textos conformes; ícone igual ao da exclusão (G13) |
| Saída com alterações não salvas | Sim | Divergente (G14, G15) |
| Mensagens de sucesso e "índice incluído" | Sim | Divergente (G16, F21) |
| Novo índice - tipo Seleção e erros de validação | Parcial (topo do formulário e erro de Descrição) | Divergente (G17 a G20) |
| Opções do índice (7 quadros) | Sim, relatório anterior | F1 a F21 |
| Novo índice: Específico, Múltipla Seleção, Data, Números, valor inicial Data Atual, Data sem valor inicial, DI Consulta, conexão selecionada, descrição duplicada | **Não** | Pendente |
| Editar índice - em uso | **Não** | Pendente |
| Testar SQL (resultado, erro de conexão, sem conexão) | **Não** | Pendente |

Os pendentes exigem montar cada estado no dev (tipo de índice, conexão simulada, índice em uso). Não foram comparados, então não há afirmação sobre eles.

## Divergências novas

| Id | Tela | Protótipo | Dev | Evidência |
|---|---|---|---|---|
| G1 | Listagem, vazio e busca | Botão **Filtros** (ícone de funil, formato pílula) à esquerda da barra de ferramentas, nos três quadros | Não existe botão de filtro; a barra só tem "+" e lupa (`indice-management.component.html`, sem `nyx-filter`) | `11-listagem-figma.png`, `ev-164996-tela-listagem-dev.jpg` |
| G2 | Listagem | Ordem das ações da linha: Opções (lista), Editar (lápis), Excluir (lixeira) | Editar, Opções, Excluir | `20-indice-incluido-toast-figma.png` e `ev-164996-tela-listagem-dev.jpg` |
| G3 | Listagem | Ícones de ação de contorno (lápis e lixeira finos) | Lápis preenchido (sólido) | idem |
| G4 | Listagem | Ordenação padrão por **Código**, com seta de ordenação no cabeçalho do Código | Ordem alfabética por descrição; sem seta visível no cabeçalho | idem |
| G5 | Listagem | Coluna Código alinhada à esquerda | Código centralizado | idem |
| G6 | Listagem | Título da página com ícone de índice (grade) antes de "Gerenciamento de índices" | Chevron ">" entre "Configurações" e "Gerenciamento de índices" | `11-listagem-figma.png` |
| G7 | Listagem | Larguras de coluna do protótipo (Descrição e Tipo de índice mais largas; Ações estreita) | Larguras diferentes (Ações mais larga, Descrição mais estreita), observado pelo print; **tipografia e altura de linha não medidas** | idem |
| G8 | Listagem | Rodapé "Carregando mais índices…" com spinner ao carregar mais | **Não verificado** em tela (depende de mais de uma página); existe no código (`loadingMore`) | código |
| G9 | Listagem | Os 7 itens do protótipo incluem "Múltipla Seleção" e "Específico" no tipo de índice | No dev os rótulos vieram vazios para Múltipla Seleção ("-") com o dado que apliquei; **não conclusivo** (dado simulado por mim, tipo "multipla_selecao" pode não ser o código real) | — |
| G10 | Estado vazio | Barra com Filtros e só o "+" (sem lupa) | Barra com "+" e lupa | `12-listagem-vazio-figma.png`, `ev-164996-tela-listagem-vazia-dev.jpg` |
| G11 | Busca | Campo de busca com borda preta 1,5 px, ícone de lupa fino e **sem** botão de limpar | Lupa em negrito e botão "x" de limpar à direita | `13-listagem-busca-figma.png`, `ev-164996-tela-busca-sem-resultado-dev.jpg` |
| G12 | Busca sem resultado | O **cabeçalho da tabela continua visível** (Código, Descrição, Tipo de índice, Tipo de valor, Portal, Status, Ações) acima do ícone de lupa e da mensagem | Cabeçalho da tabela some; só a lupa e a mensagem | `14-listagem-busca-sem-resultado-figma.png`, `ev-164996-tela-busca-sem-resultado-dev.jpg` |
| G13 | Modais de exclusão (confirmação e bloqueios) | Ícone de **triângulo** vermelho com "!" | Ícone de **círculo** vermelho com "!" (`variant="danger"` do `nyx-modal`); modal centralizada na vertical, e no protótipo ela fica a 28 px do topo | `15-excluir-confirmacao-figma.png`, `ev-164996-tela-excluir-dev.jpg` |
| G14 | Saída sem salvar | Texto: "As alterações não foram salvas. Se você sair agora, precisará preencher as informações novamente." | "Você tem alterações não salvas. Se sair agora, elas serão perdidas." (`indiceForm.container.leaveModal.body`, `public/i18n/pt.json`) | `16-saida-nao-salva-figma.png`, `ev-164996-tela-saida-dev.jpg` |
| G15 | Saída sem salvar | Ícone de **círculo** laranja com "!" | Ícone de **triângulo** laranja (o contrário do que vale para a exclusão, G13) | idem |
| G16 | Toast do índice | "Índice **incluído** com sucesso." e "Índice **alterado** com sucesso." (e "excluído", que confere) | "Índice **criado** com sucesso." e "Índice **atualizado** com sucesso." (`indiceForm.container.messages.createSuccess` e `updateSuccess`) | `07-toasts.png`, `ev-164996-tela-toast-indice-dev.jpg` |
| G17 | Formulário | Rótulos Roboto 16 px / 18 px, peso Medium, cor `#353535` | Rótulos 14 px, peso 600, altura de linha `normal`, preto | `21-novo-indice-selecao-figma.png`, `ev-164996-tela-form-dev.jpg`; medido por estilo |
| G18 | Formulário | Campos (texto, lista) com altura 48 px | Altura 40 px | medido por estilo |
| G19 | Formulário | Rótulos dos interruptores ("Índice ativo", "Escolha única" e demais) 16 px / 18 px | 14 px | medido por estilo |
| G20 | Formulário | Rodapé: botões "Sair" e "Salvar" apenas com texto | "Salvar" com ícone de disquete; rodapé em faixa branca fixa | `ev-164996-tela-form-dev.jpg` |

## Conferido e conforme
- Textos da confirmação de exclusão (título e corpo) e dos bloqueios (exclusão em processo, exclusão em uso, inativação), vindos da simulação, batem com o protótipo; botão "Entendi".
- Estado vazio: texto "Nenhum índice cadastrado. Crie o seu primeiro índice clicando em + Novo índice" e botão "Novo índice" presentes.
- Estado de busca sem resultado: texto "Nenhum resultado encontrado para a busca ativa. Tente pesquisar por outros termos".
- Formulário (Informado): seções Configurações, Validação, Exibição, Lançamento e Integração; campo "Máscara para MFP" aparece como no protótipo de erros. Erro "Este campo é requerido" em Descrição existe; a cor do texto do erro é vermelha (divergência F17, já registrada).
- Modal de saída: botões "Voltar" e "Sair mesmo assim" (laranja) conferem.

## Observações (fora da conta; shell compartilhado)
- Menu lateral do dev tem "Dashboards", "Favoritos", "Portal de melhorias" e ordem diferente do protótipo (Início, Favoritos, Processos, Documentos, Dashboard, Configurações); o ícone do menu e o avatar (iniciais "AD" em vez de foto) também diferem. Largura do menu e altura do cabeçalho ficam em torno de 248/72 px no dev contra 275/76 px no protótipo (medido pelo print em escala). Não conto como defeito desta US; vale confirmar com o time de design se o protótipo do shell está desatualizado.
- O protótipo mostra o botão azul "Novo índice" no topo do menu lateral nos quadros de formulário; não existe no dev. Parece ser o botão de ação global do shell.
- Esc não fechou a modal de exclusão no teste (a modal só fechou pelo botão Cancelar). Não é diferença de protótipo; vale checar como regra de acessibilidade.

## Execução dos quadros pendentes (03/11/2026, segunda rodada)

Comparei 12 quadros que estavam pendentes. Estados montados na tela do dev (dados simulados, Bug #165721), **pela interface** sempre que o estado dependia de validação; atalhos no formulário só para chegar ao estado. Prints do protótipo: `mapas-teste\prototipo\23` a `35`. Prints do dev: `evidencias_2026-10-30\ev-164996-*` (form-especifico, form-multipla-selecao, form-data-sem-inicial, form-data-atual, form-numeros-erro, form-di-consulta-erros, form-conexao-selecionada, form-descricao-duplicada, editar-em-uso, testar-sql-*).

| Quadro do Figma | Resultado |
|---|---|
| Novo índice - tipo Específico (14259:5816) | **Conforme** em estrutura e textos: DI travado em "Específico", Identificador habilitado com texto "Informe o identificador do índice Específico (até 50 caracteres)." e contador 0/50, sem "Máscara para MFP", sem Integração |
| Novo índice - tipo Múltipla Seleção (14261:9246) | **Conforme**: DI travado, Identificador travado com "Disponível apenas para o tipo Específico.", sem Máscara |
| Novo índice - tipo de valor Data (14261:9757) | Conforme na estrutura (Outro / Data Atual e campo de data). Calendário nativo do navegador, já no Bug #165724 |
| Novo índice - valor inicial Data Atual (14289:7996) | **Divergente (H4)** |
| Novo índice - Data sem valor inicial (14289:8684) | **Conforme**: "Por favor, selecione uma data inicial." com borda vermelha ao salvar |
| Novo índice - tipo de valor Números (14289:9197) | **Conforme**: "Somente números" ao salvar com "12a"; Máscara visível |
| Novo índice - DI Consulta sem conexão e SQL (14289:7124) | **Divergente (H5)**; textos conferem |
| Novo índice - conexão selecionada (14261:10820) | **Conforme**: Modo de comparação "Parcial (LIKE)", SQL com 64/4000, Testar |
| Novo índice - descrição duplicada (14259:4729) | **Conforme**: "Já existe um índice com esta descrição." com borda vermelha |
| Editar índice - em uso (14261:10279) | **Conforme** nos pontos verificáveis: Tipo de índice e Tipo de valor travados, DI e Ordenação habilitados, Identificador travado, Máscara e quadro de ajuda presentes |
| Testar SQL - resultado (14262:6451) | **Divergente (H1)** |
| Testar SQL - erro de conexão (14262:6733) | **Divergente (H2)** |
| Testar SQL - sem conexão (14262:6856) | **Divergente (H3)** |

### Divergências novas

| Id | Tela | Protótipo | Dev | Evidência |
|---|---|---|---|---|
| H1 | Testar SQL - resultado | Modal a 80 px do topo; tabela sem borda externa (só linhas); paginação com setas cinza finas; botão fechar fino | Modal centralizada na vertical (topo em cerca de 128 px); tabela dentro de caixa com borda e cantos arredondados; setas da paginação pretas e em negrito; botão fechar em negrito | `24-testar-sql-resultado-figma.png`, `ev-164996-testar-sql-resultado-dev.jpg` |
| H2 | Testar SQL - erro de conexão | Ícone de **triângulo** vermelho com "!" no título; modal a 80 px do topo | Ícone de **círculo** vermelho; modal centralizada | `26-testar-sql-erro-conexao-figma.png`, `ev-164996-testar-sql-erro-conexao-dev.jpg` |
| H3 | Testar SQL - sem conexão | Ícone de **círculo** laranja com "!"; modal a 80 px do topo | Ícone de **triângulo** laranja; modal centralizada | `27-testar-sql-sem-conexao-figma.png`, `ev-164996-testar-sql-sem-conexao-dev.jpg` |
| H4 | Novo índice, Data, "Data Atual" marcado | O interruptor "Permitir edição durante o lançamento" fica **desligado e desabilitado** (cinza), além do campo de data desabilitado | Campo de data desabilitado, mas o interruptor segue **ligado e habilitado** | `31-novo-valor-inicial-data-atual-figma.png`, `ev-164996-form-data-atual-dev.jpg`. Pode ser regra (funcional): confirmar com o PO |
| H5 | Novo índice, DI Consulta, erro de Conexão | A lista Conexão fica com **borda vermelha** junto da mensagem | Mensagem aparece, mas a borda da lista Conexão continua cinza (o campo SQL fica vermelho) | `33-novo-di-consulta-sem-conexao-sql-figma.png`, `ev-164996-form-di-consulta-erros-dev.jpg` |

H2 e H3 seguem o mesmo padrão de G13 e G15 (ícone do modal trocado entre círculo e triângulo).

### Correções ao que escrevi antes
- **G9 retirada.** O valor do tipo Múltipla Seleção no dev é `multipla-selecao` (hífen); eu tinha injetado `multipla_selecao`, por isso o rótulo veio vazio. Não é defeito.
- Um salvamento sem data inicial (tipo Data, "Outro") que apareceu como sucesso foi artefato do meu atalho no formulário; pela interface o dev bloqueia e mostra a mensagem do protótipo (quadro conforme).

### Observações
- Ao salvar com erro, o dev mostra o aviso "Corrija os erros do formulário antes de salvar." Não encontrei esse texto na lista de toasts do protótipo (não verificado se o quadro o prevê).
- Em "Editar em uso", "Índice ativo" e os demais interruptores apareceram desligados porque o dado que montei não os trazia; não conta como divergência.
- A paginação e os valores do resultado do teste são simulados (CC-1001 a CC-1005, 23 linhas), idênticos ao protótipo por construção do mock.

## Pendências desta validação
1. Medir por estilo a listagem preenchida (altura de linha, padding, cores) como foi feito na modal de opções, e a tipografia dos quadros novos (rótulos G17 a G19 foram medidos só no formulário Informado).
2. Verificar o rodapé "Carregando mais índices…" (G8), que depende de mais de uma página.
3. Verificar o aviso "Corrija os erros do formulário antes de salvar." contra o quadro de toasts.

## Fechamento dos pendentes de fidelidade com a listagem real (03/11/2026, terceira rodada)
A listagem agora lê a API real (123 registros, 20 por página). Valores esperados lidos do Figma (`get_design_context` do quadro "nyx - table cloumns", 14096:5664, coluna Descrição) e medidos na tela (janela 1361 de largura, estilos computados). Evidência: `ev-164996-listagem-real-rolagem-dev.jpg`.

| Item | Esperado (protótipo) | Obtido (dev) | Resultado |
|---|---|---|---|
| Célula do corpo: tipografia | Roboto 14 px / 20 px, regular, preto | Roboto 14 px / 20 px, 400, preto | **Conforme** |
| Célula: padding e borda | padding 8/16, borda inferior 1 px `#d4d4d4` | padding 8/16, borda inferior 1 px `rgb(212,212,212)` | **Conforme** |
| Cabeçalho | Roboto 14 px / 16 px, peso 600, 48 px de altura | 14 px / 16 px, 600, 48 px | **Conforme** |
| Altura da linha | 48 px, texto em uma linha (`nowrap`) | 49 px com uma linha (dentro de 1 px); **56,5 a 57 px** quando o texto quebra, porque `white-space` é `normal` | **Divergente (G21)** |
| Largura das colunas (proporção, sem a coluna estreita inicial do desenho) | Código 8,3%, Descrição 21,3%, Tipo de índice 21,3%, Tipo de valor 21,3%, Portal 9,1%, Status 9,1%, Ações 9,5% | Código 7,5%, Descrição 34,6%, Tipo de índice 12,7%, Tipo de valor 13,4%, Portal 9,1%, Status 9,1%, Ações 13,6% | **Divergente (G7 medida)** |
| Rodapé "Carregando mais índices…" (G8) | Spinner e texto ao carregar mais | Ao rolar, a lista passou de 20 para 40 linhas, mas a carga é rápida demais para ver o rodapé; forçando `loadingMore`, o componente `nyx-table` (Shadow DOM) não desenhou nenhum elemento de carregamento | **Não verificável** (limite de Shadow DOM e velocidade) |
| Aviso "Corrija os erros do formulário antes de salvar." | O quadro de toasts do protótipo (`07-toasts.png`) só traz mensagens de sucesso (3 de índice e 5 de opção); o quadro de erros de validação não mostra toast | O dev exibe esse aviso (ícone laranja, fundo preto) ao salvar com erro | **Divergente (G22): elemento que o protótipo não prevê**; confirmar com o PO se é desejado |

G21: causa provável é a coluna Tipo de valor estreita (G7), que faz "Letras e Números" quebrar em duas linhas (77 células quebradas na primeira carga); corrigir a largura pode resolver as duas.

Dado legado: índices como "selec?o consulta teste" (189) aparecem com `?` também no Clássico (`TipoIndice.aspx`, busca por "consulta teste"), então é dado gravado assim no banco, não falha da nova tela.
