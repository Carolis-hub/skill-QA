# Etapa 03 — Mapa de testes — #160823 Rotina - Inicio Desassociar Automático

- **Skill:** `/arquitetura-gerar-mapa-testes 160823`
- **Data:** 2026-11-04 11:45
- **Escreveu no Azure DevOps:** sim
- **Aprovado por:** Guilherme Henrique Correa Borges (publicação e sobrescrita confirmadas no chat)
- **Fontes lidas:** história #160823; cards #161471 (Análise), #161490 (mapa); PRs 29228 e 29340 (lista de arquivos); relatórios 01 e 02 do ciclo. Busca de bugs: 0 resultados.

## Aprendizados consultados

Consulta realizada — nenhum aprendizado aplicável encontrado. (base vazia)

## Resultado

- Card **#161490** (Criar Mapa de Teste, estado Done) atualizado: descrição anterior **substituída** (rev 4 → 5).
- Comentário de hipóteses na história #160823 (rev 6 → 7).
- Mapa: 30 cenários em 9 categorias. Hipóteses: #15, #28, #29, #30. Bloqueados: #21 (duas instâncias) e #22 (forçar erro).
- Releitura do card após a publicação: 30 cenários, 9 categorias e tabela HTML presentes, sem truncamento.

## Tabela aprovada (resumo)

| # | Cenário | Técnica | Dimensão |
|---|---|---|---|
| 1 | Desassocia tarefa vencida | transição-de-estado | positivo |
| 2 | Efeitos de dados da desassociação | partição-equivalência | dados |
| 3 | Log do serviço com fluxo e tarefa | exploratório | positivo |
| 4 | Rotina na listagem da configuração | partição-equivalência | positivo |
| 5 | Dentro do prazo não é alterada | valor-limite | negativo |
| 6 | Limite do prazo | valor-limite | dados |
| 7 | Tarefa sem usuário | partição-equivalência | dados |
| 8 | Tarefa concluída | partição-equivalência | dados |
| 9 | Reassociada volta a ser avaliada | transição-de-estado | regressão |
| 10 | Unidades de tempo | partição-equivalência | positivo |
| 11 | Ativar/desativar alterna novo e clássico | tabela-decisão | positivo |
| 12 | Passo sem tempo | partição-equivalência | negativo |
| 13 | JOIN por cd_passo | tabela-decisão | regressão |
| 14 | Executor tipo usuário | partição-equivalência | negativo |
| 15 | HIPOTESE: perfil sem acesso à configuração | partição-equivalência | permissão |
| 16 | Tarefa muda entre agendamento e execução | transição-de-estado | dados |
| 17 | Campos de formulário corrente | partição-equivalência | dados |
| 18 | Liberação de anexo | tabela-decisão | dados |
| 19 | Configuração SQL Server e Oracle | pairwise | dados |
| 20 | Bancos x cenários | pairwise | dados |
| 21 | Duas instâncias não duplicam (BLOQUEADO) | transição-de-estado | concorrência |
| 22 | Erro numa tarefa não trava as outras (BLOQUEADO) | tabela-decisão | negativo |
| 23 | Falha reagendável | transição-de-estado | negativo |
| 24 | Paridade back-to-back | back-to-back | regressão |
| 25 | AvancarFluxo e CancelarFluxo | partição-equivalência | regressão |
| 26 | Outros jobs BPM | exploratório | regressão |
| 27 | Clássico inalterado com rotina desativada | back-to-back | regressão |
| 28 | HIPOTESE: periodicidade e reinício | transição-de-estado | dados |
| 29 | HIPOTESE: cd_executor nulo ou zero | partição-equivalência | dados |
| 30 | HIPOTESE: log sem dado sensível | exploratório | negativo |

## Correção pós-publicação (2026-11-04 11:50, rev 5 → 6)

- Cenário #21, passo 2: texto corrigido para "O sistema deve listar como elegível a mesma tarefa vencida nas duas instâncias".
- Seções renumeradas (Rastreabilidade = 9, Riscos residuais = 10, Itens bloqueados = 11, Resumo = 12).

## Pendências do mapa publicado

- O mapa não traz SQL de preparação/verificação nem dados reais (marcadores apenas); o card #161471 não os fornece.
- Evidências do legado vêm do card Análise; o código do clássico não foi relido.
