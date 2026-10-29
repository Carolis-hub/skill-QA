# Pendências da Feature #158043 por criticidade e impacto — 2026-10-28

Complementa o `relatorio-pendencias_2026-10-28.md` (lista completa por US). Aqui os pendentes estão ordenados pelo risco para a liberação.
**Critério:** impacto se o comportamento estiver errado em produção (perda ou vazamento de dados, bloqueio de uso, quebra por banco/cliente, objetivo da Feature não comprovado), amplitude (quem é afetado) e o quanto a pendência é cobertura central da US. A classificação é minha, a partir dos resultados dos testes; ajuste conforme o seu conhecimento do cliente.

Totais: 53 cenários pendentes nas 8 US executadas, mais 27 da #162232 (adiada) e 27 da #157525 (fora da liberação).

## CRÍTICO (tratar antes da liberação)

| # | Pendência | Por que é crítico | Destrava com |
|---|---|---|---|
| 1 | **Objetivo de performance não comprovado:** #157526 #27 e #159598 #25 (tempo até a 1ª página em Finalizados com grande volume, CA11) | A Feature se chama "Performance BPM"; nenhum cenário mediu tempo antes/depois. Sem isso não há evidência do ganho prometido | Build anterior + volume de Finalizados + critério numérico do PO |
| 2 | **Exclusão de usuário com filtro salvo:** #157654 #16, #17, #18 | Se o registro em FILTRO_USUARIO_TELA não for removido (ou houver violação de chave), a exclusão de usuários no SmartShare clássico pode falhar. Afeta administração de todos os clientes | Usuários descartáveis + sua autorização + banco para conferir |
| 3 | **Banco Oracle e criação das tabelas:** #157654 #19 e #21, #160196 #21 (Bug #160816 já ocorreu em Oracle) | Erro de conversão em Oracle quebrava Minhas tarefas para quem tem filtro salvo. Clientes Oracle ficariam sem a tela principal | Acesso ao banco/ambiente Oracle |
| 4 | **Brecha de controle de acesso na impressão em lote:** #154487 #20 (+ #14 log de erro, #10 lado positivo, #19 anexo não-PDF) | O coração da US é não imprimir/baixar o que não é permitido. A chamada direta ao endpoint ainda não foi testada | Postman/curl com token, usuário com papel Fiscal |
| 5 | **Exclusão em massa que alcança itens fora da pasta:** achado do #157656 #25 e #157657 (com "Selecionar todos" e "Pesquisar em: Todas as pastas" o filtro retornou 1194 documentos do repositório) | Risco de exclusão acima do esperado (Bug legado #162695). Não é cenário pendente, é um achado sem decisão | Decisão dev/PO: escopo do "Selecionar todos" com filtro |

## ALTO

| # | Pendência | Por que | Destrava com |
|---|---|---|---|
| 6 | **Isolamento do filtro entre usuários no BPM:** #157654 #13, #14, #15; #160196 #15 | Privacidade/consistência: filtro de um usuário não pode aparecer para outro. Só foi observado entre dois usuários no ECM | 2º usuário logado; Postman/token para #14/#15 |
| 7 | **Lista de pastas sumindo com filtro salvo (ECM):** #157656 #11 e #12 | Com filtro salvo, o usuário não vê pastas nem navega em subpastas até limpar o filtro (o que apaga o salvo). Impacto de uso diário | Decisão dev/PO sobre o esperado |
| 8 | **Falha de consulta sem erro na área de conteúdo nem retry:** #157526 #21/#22 (severidade baixa, defeito não gerado); **lazy loading que não se recupera após falha de lote:** #159598 #20 | A tela mostra "Não há tarefas em andamento." quando houve erro e a lista fica travada até recarregar. Há toast genérico, que você considerou aceitável | Sua decisão (gerar ou não o defeito); confirmação dev/PO do #20 |
| 9 | **Consistência dos dados paginados:** #159598 #16 (itens duplicados e contagem × banco, SQL Server e Oracle), #17 (ordenação igual à anterior) | Item duplicado ou ausente em lista de tarefas afeta o trabalho do usuário. Só a soma na tela foi conferida (803 = 803) | Banco; build anterior |
| 10 | **Regressão do Bug #161879:** #159598 #14 e #21 (poucos grupos, sem barra de rolagem: o lazy loading não dispara) | Bug já ocorrido; sem a massa não dá para garantir que não voltou | Massa com poucos grupos e página pequena |
| 11 | **Regressão geral da Feature:** #162232 (27 cenários, adiada) | É a regressão que amarra Performance BPM + Manter Filtro BPM/ECM | Sua decisão de quando executar |
| 12 | **Itens por página padrão 25 (CA6 e mapa pedem 10) e overlay de loading cobrindo cabeçalho e título (CA1):** #157526 #4/#6/#1 com ressalva | Desvio do critério de aceite, ainda sem confirmação se é intencional | Confirmação dev/PO |

## MÉDIO

| # | Pendência | Por que |
|---|---|---|
| 13 | Persistência no banco: #157656 #2 e #19, #157654 (registros únicos em FILTRO_USUARIO_TELA) | Só foi deduzido pela API; "um registro, sem duplicar" não confirmado no banco |
| 14 | Sessão nova real (logout e login): #160196 #4, #157656 #4 (este já feito) | Só recarga da página na #160196 |
| 15 | Ações dos cards em itens de lotes carregados: #159598 #23, #157526 #24 | Regressão de ações (detalhar, executar, cancelar fluxo) |
| 16 | Fluxo normal com filtro salvo no ECM: #157656 #22 | Regressão de criar, editar e revisar documento com filtro ativo |
| 17 | Hipóteses de comportamento: #157657 #22/#23, #157656 #10/#14/#16/#17/#21, #157654 #11/#20, #160196 #17 | Sem esperado definido; viram teste quando houver regra |
| 18 | Mobile: #159598 #24 (app mobile), #157526 #26 (traduções) | Cobertura parcial |

## BAIXO

| # | Pendência |
|---|---|
| 19 | Tooltip: #157524 #11 (agrupamentos), #13, #18, #20, #22, #23; nome do processo truncado sem tooltip (a confirmar); #12 decidido sem defeito |
| 20 | Cor do hover da paginação: #157526 #25, #159598 #22 (não conclusivo) |
| 21 | #154487 #17 (comparação com versão anterior), #19, #14 (log de erro) |
| 22 | Limpeza da massa de teste no HMG e usuário dedicado de teste |

## Fora do escopo desta liberação
- **#157525** (menu lateral em dois níveis): não desenvolvida; 27 cenários bloqueados.

## Sugestão de ordem de ataque
1. Resolver as dependências que destravam mais itens críticos: **acesso ao banco (Oracle/SQL Server)**, **segundo usuário** e **Postman/token**.
2. Decisões dev/PO que não custam teste: #5 (escopo do "Selecionar todos"), #7 (pastas com filtro), #8 e #12.
3. Medir performance (#1) com a build anterior e o volume de Finalizados.
4. Executar a #162232 por último, com tudo acima resolvido.
