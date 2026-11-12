# Etapa 31 — execucao-testes — consolidado ORACLE da US #161711 (Bugs Instaladores)

- **Skill e argumentos:** `/arquitetura-executar-teste` — "execução do gate ORACLE, o necessário antes da execução, eu autorizo fazer" (09/11/2026)
- **Ambiente:** local do QA (não produtivo), Share em IIS Express (`localhost:58149`), Oracle `SHAREGUIZAO`, cada bug na sua branch/worktree
- **Gate:** [00-validacao-ambiente-oracle.md](00-validacao-ambiente-oracle.md), LIBERADO COM RESSALVA (aceito pelo QA: o passo SQL falha por conexão, não por SQL inválido)
- **Status:** **PARCIAL** (5 bugs executados; ver pendências)

## Resumo por bug
| Bug | PR | Relatório | PASSOU | PASSOU COM RESSALVA | INCONCLUSIVO | NÃO EXECUTADO / FORA |
|---|---|---|---|---|---|---|
| #161716 | 30104 | [26](26-execucao-testes-161716-oracle.md) | 4, 9 | 1, 2, 6 | 8, (3 parcial) | 5, 7 |
| #161713 | 30060 | [27](27-execucao-testes-161713-oracle.md) | 3, 4, 5 | 1, 2, 6, 7 | 8, 9 | 10 |
| #161712 | 30457 | [28](28-execucao-testes-161712-oracle.md) | 5, 9 | 1, 2, 3, 4, 6, 7, 8, 11, 12 | — | 10 |
| #161714 | 30486 | [29](29-execucao-testes-161714-oracle.md) | 4, 5 | — | — | 1, 2, 3 (hipótese) |
| #161839 | 30253 | [30](30-execucao-testes-161839-oracle.md) | — | 1, 3, 4, 5, 7, 8, 10 (só opção 3) | 9 | 2, 6, 11 (clássico) |

Nenhum cenário foi classificado `FALHOU`. Nenhum Bug foi criado.

## Preparação feita (resumo; detalhe em cada relatório)
- `UPDATE JOB_CONFIG` por bug para isolar o job testado (estado original em `massa/backup-job_config-oracle-antes-execucao.txt`).
- `UPDATE JOB_BPM SET QT_DE_TENTATIVAS = 4` em 3 linhas de fluxos de teste (#161713) e `UPDATE` de status do job 32, desfeito.
- `DELETE FROM JOB_BPM` de 4 linhas residuais (jobs 9, 18, 32).
- Mock HTTP `ferramentas/mock_ws_44303.py` (ajustado para devolver `args.teste`); `appsettings.json` do Worker apontado para `58149` nos worktrees e **restaurado** ao fim.
- Processos de teste: 561, 581 (título do fluxo preenchido), 601 (não liberado, sobra); fluxos 2282 em diante.

## Observações para o dev/PO (não são `FALHOU`)
1. **#161713, Oracle:** processo sem "Título do Fluxo" faz o avanço pelo escape falhar com `ORA-01407` (`FLUXO.DS_FLUXO` NULL). Com o título, o escape funcionou.
2. **PR 30457 × 30104/30060:** chaves em `JOB_DUMP` voltam à fila no 30457 (`ExisteJobAtivo` diferente). Relevante para a integração dos PRs.
3. **PR 30457:** log "inserido com sucesso" para `ExecutaWs` (120×) com 3 linhas na tabela; handler não alterado pelo PR.
4. **Formulário do processo 442** (`FormularioPadrao20.aspx`) travou o Share (IIS Express reiniciado com autorização do QA); causa não lida.
5. **Conexão 1** do Oracle é um SQL Server de exemplo (`servidor`/`banco`); `PERFIL_CONEXAO` estava vazio e foi preenchido (autorizado).

> **Atualização (09/11, 2ª rodada do #161839, com `qa.usuario2` e `qa.usuario3`):** os cenários 3, 5 e 10 (opção 3) passaram com ressalva; o double-check abaixo foi feito antes desta rodada e não os cobre. `JOB_CONFIG` restaurado (13 jobs ativos).

> **3ª rodada (10/11, massa dos inconclusivos, com autorização):** #161713/6 e #161712/7, 8 e 12 passaram com ressalva (detalhe nos relatórios 27 e 28); #161712/4 ficou parcial (só o tipo tarefa). Escritas autorizadas e revertidas: `DELETE JOB_BPM` job 28 e 9 (8 linhas); `UPDATE JOB_CONFIG` isolando jobs; `POLITICA_BACKOFF` do job 19 (1, 2, depois 0); `CRON_EXPRESSION` do job 32 (`0 * * * * ?`, depois `0 0 0 * * ?`); `TIMEZONE_ID` do job 9 (`Asia/Tokyo`, depois `America/Sao_Paulo`); 13 jobs ativos. Fluxos criados: 2416 a 2420 (processo 561, `IniciaFluxo` cria 1 fluxo a cada abertura da URL) e 2421 (processo 1, parado na tarefa 4). **Ambiente:** as DLLs `NLog*` e `Microsoft.Extensions.Hosting.WindowsServices` sumiram dos `bin` de todos os worktrees; reconstruí só o `bin` do 30457 (os outros precisam de build antes de nova execução). Playwright caiu e os itens de tela ficaram para depois: versão do 501 com observação 4 (#161839 4 e 7), processo com ramos paralelos (#161839 8), avanço do fluxo 2421 até o passo 55 (#161712 2).

> **3ª rodada, continuação (10/11, itens de tela):** #161712/2 e #161839/4 e 7 passaram com ressalva. Massa criada pela tela: revisão v2 do processo 501 (liberada; observação 4 no passo 5 gravada por `UPDATE` autorizado no rascunho, porque o editor gráfico da v2 abre vazio), fluxos 2422 (acidental) e 2423 (501) e fluxo 2421 do processo 1 avançado até o passo 55. `JOB_CONFIG` restaurado (13 jobs ativos); mock encerrado; `appsettings.json` do Worker do 30253 restaurado. **#161839/8 (ramos paralelos) também passou com ressalva (exploratório):** processo novo 621 desenhado no editor e liberado; fluxo 2442 com B1 (`qa.usuario2`) e B2 (`qa.usuario3`); o Worker notificou só `qa.usuario2`. Executores e opção 4 do 621 gravados por `UPDATE` autorizado (a tela "Detalhes" dava erro ao salvar). Pendentes: #161712/4 (observação e mensagem nova), #161712/11 (`FREQUENCIA_INICIO` do processo 441 só fica elegível depois das 08:30 de cada dia ou com `UPDATE` de `DT_ULTIMA_VERIFICACAO`), #161713/9 (conexão alcançável) e todos os cenários SQL Server.

## Divergências do double-check (sub-agente independente, só leitura; não sobrescrevem a classificação original)
| Relatório / # | Original | Sugestão do sub-agente | Motivo |
|---|---|---|---|
| 26 / 1 | PASSOU COM RESSALVA | INCONCLUSIVO | 103 pendências (não 101); primeiros ciclos falharam por ambiente; "sem linha repetida" nesse período sem consulta citada; ambiente com mock e 58149 |
| 26 / 3 | PARCIAL | INCONCLUSIVO | "PARCIAL" não é classificação das regras; 99 e 100 não executados |
| 26 / 9 | PASSOU | PASSOU COM RESSALVA | mock e porta alterada |
| 27 / 2 | PASSOU COM RESSALVA | INCONCLUSIVO | `Qt_de_Tentativas` forçado por `UPDATE`; variável de erro e ocorrência não verificadas; falha por conexão |
| 27 / 3 | PASSOU | PASSOU COM RESSALVA | `UPDATE` de tentativas e falha por conexão |
| 27 / 4 | PASSOU | PASSOU COM RESSALVA | falha acidental por massa incompleta (ORA-01407) |
| 27 / 7 | PASSOU COM RESSALVA | INCONCLUSIVO | depende do `UPDATE` e só tem falha por conexão |
| 28 / 1, 3, 6 | PASSOU COM RESSALVA | INCONCLUSIVO (6: ou ressalva para 2 de 3) | cobertura parcial: variantes sem massa |
| 28 / 9 | PASSOU | PASSOU COM RESSALVA | ausência em `JOB_BPM` sem prova de pendência elegível para os jobs `// TODO` |
| 29 / 4 e 5 | PASSOU | PASSOU COM RESSALVA | URL do Worker adulterada, mock desligado; o PR muda o log de erro e isso não foi exercido |
| 30 / 1 | PASSOU COM RESSALVA | INCONCLUSIVO | executor anterior e destinatário são o `root`; a evidência não discrimina o comportamento do PR |

Decisão pendente do QA sobre cada divergência (nenhuma foi aplicada).

## Pendências e instruções para retomada
1. **Restauração do ambiente: FEITA (09/11, autorizada pelo QA).** `UPDATE JOB_CONFIG SET ATIVO = 1 WHERE MODULO = 1 AND ATIVO = 0` (12 linhas; 13 jobs ativos, como no início) e `UPDATE PASSO_USUARIO SET ID_PERMISSAO_OBSERVACAO = 0` no processo 522 v1, passo 6 (1 linha; lido: 0).
2. **Fluxos de teste abertos** (2403–2405, 2407, 2408, 2411 etc.) e processo 601: cancelar/excluir pela tela se o QA quiser limpar.
3. **Massa que faltou para os inconclusivos:** conexão 1 alcançável (#161713 cenários 8 e 9), usuários extras e ramos paralelos (#161839), alertas e agenda temporal (#161712), mecanismo de exceção em `AvancarFluxo` (#161714), reativação do SQL Server (cenário "dois bancos" de todos os bugs).
4. **Anexo ao card `Teste`:** não anexado; aguarda aprovação explícita do QA.
5. Retomar com `/arquitetura-executar-teste` e os mesmos argumentos para repetir os pendentes.


## SQL Server (10/11/2026)
Rodada completa no SQL Server local nos 5 bugs, relatório [32](32-execucao-testes-sqlserver.md): 0 FALHOU. Inconclusivo: #161713/4 (sem mecanismo para o escape falhar no SQL Server); o #161839/8 passou com ressalva depois de desenhar o processo 1038 (só um executor é notificado: B2 no SQL Server, B1 no Oracle). O cenário "SQL Server e Oracle" passou com ressalva nos 3 bugs que o tinham. Pendentes: #161713/9 no Oracle (conexão Oracle tipo 4).
