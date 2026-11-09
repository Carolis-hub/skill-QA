# Roteiro de teste para o dev — US #164847 Listagem e busca de tipos de índice (BE)

Origem: critérios de aceite da US (rev 18) e card Análise #164862. Preparado pelo QA em 2026-10-26.
Objetivo: o dev executar estes cenários na branch `feature/164847-listagem-indice` e devolver o resultado e as respostas da seção 1.

## 1. Perguntas ao dev (necessárias para fechar o teste)
| # | Pergunta | Por que importa |
|---|---|---|
| 1 | Qual é o endpoint, o método e o formato de requisição e resposta? Nomes dos parâmetros (ponto de partida, tamanho do lote, busca, coluna e direção de ordenação) e dos campos de retorno (itens, total, `hasMore`). | Sem isso os cenários abaixo não têm chamada concreta. |
| 2 | Qual é o tamanho máximo do lote? | Cenário T10. |
| 3 | Lote com tamanho 0, negativo ou não numérico: recusa ou assume 20? | Cenário T10. |
| 4 | Busca com mais de 40 caracteres: qual código HTTP e qual mensagem? | Cenário T5. |
| 5 | Ordenação por Tipo de índice, Tipo de valor, Portal e Status: pelo rótulo ou pelo código interno? | Cenário T3. |
| 6 | A busca ignora acentos ("indice" encontra "Índice")? | Cenário T4. |
| 7 | A listagem inclui registros inativos (`st_ativo = 0`)? | Cenário T2. |
| 8 | Como forçar o erro técnico no ambiente de teste (banco indisponível)? | Cenário T14. |
| 9 | Qual ambiente tem a branch implantada, em SQL Server e em Oracle? | Cenário T13. |

## 2. Massa de dados necessária
- Tipos "Contrato" e "Contrato Social".
- Tipos com nomes `O'Brien`, `100%` e `a_b`.
- Um tipo com `id_tipo_local` ou `id_tipo_valor` fora do domínio (texto vazio esperado, sem erro).
- Tipos ativos e inativos, com Portal ativo e inativo.
- Pelo menos 45 tipos, para ter 3 lotes de 20; para o CA 100, milhares.
- Dois ambientes: SQL Server e Oracle.

## 3. Cenários
| ID | CA | Passos | Resultado esperado |
|---|---|---|---|
| T1 | 5, 10 | Listar sem parâmetros | No máximo 20 itens, por Código crescente, com total e `hasMore`. |
| T2 | 4 | Conferir os campos de um item | Código, Descrição, Tipo de índice, Tipo de valor, Portal e Status. |
| T3 | 5, 10b | Ordenar por cada coluna, crescente e decrescente | Ordem correta; empates desempatados por Código. |
| T4 | 6 | Buscar "contrato" | Retorna "Contrato" e "Contrato Social", sem diferenciar maiúsculas e minúsculas. |
| T5 | 6 | Buscar com 40 caracteres, depois com 41 | 40: aceita. 41: recusa (código e mensagem conforme pergunta 4). |
| T6 | 7, 97 | Buscar `O'Brien`, `%` e `_` | Sem erro. `%` e `_` são literais: só retornam tipos que contenham esse caractere. |
| T7 | 8 | Buscar texto inexistente | Lista vazia e total 0. |
| T8 | 9 | Base sem tipos de índice | Lista vazia e total 0, sem erro. |
| T9 | 10, 10b | Pedir lotes seguidos até o fim | Nenhum registro repetido nem pulado; o último lote vem com `hasMore = false`. |
| T9b | 10b | Entre dois lotes, incluir e excluir um registro e pedir o lote seguinte | Sem repetição nem salto a partir do mesmo ponto de partida. |
| T10 | 10 | Pedir lote acima do máximo; depois tamanho 0 e negativo | Acima do máximo: limitado ao máximo. 0 e negativo: conforme pergunta 3. |
| T11 | 10c | Com lista parcialmente carregada, mudar a busca; depois a ordenação | Volta ao primeiro lote com o novo critério e o total recalculado. |
| T12 | 95, 96 | Chamar sem login; depois com usuário sem permissão | 401 sem login; 403 sem permissão. A operação não é executada. |
| T13 | 98 | Repetir T1, T3, T4 e T9 em SQL Server e em Oracle | Resultados idênticos nos dois bancos. |
| T14 | 99 | Forçar erro técnico (banco indisponível) | Mensagem padronizada, sem SQL, stack trace ou string de conexão; detalhe no log da aplicação. |
| T15 | 100 | Com milhares de tipos, listar e buscar | Resposta por lote no servidor, filtro no banco, sem carregar a tabela inteira. Registrar o tempo. |
| T16 | análise do dev | Listar tipo com `id_tipo_local` ou `id_tipo_valor` desconhecido | Texto vazio na coluna, sem erro. |

## 4. Resultado (o dev preenche)
| ID | Passou / Falhou | Evidência (resposta, log ou observação) |
|---|---|---|
| T1 | | |
