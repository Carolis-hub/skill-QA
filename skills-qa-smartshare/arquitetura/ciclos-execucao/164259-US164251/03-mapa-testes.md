# Etapa 3 — Mapa de Testes — #164251 [BUG] Ajustar regra de leitura de status no BPM

- **Skill:** `/gerar-mapa-testes-v3 164251`
- **Data:** 2026-10-26
- **Aprovado por:** Guilherme Henrique Correa Borges
- **Publicado em:** card "Criar Mapa de Teste" [#165040](https://dev.azure.com/selbettidev/SmartShare%20Arquitetura/_workitems/edit/165040) (criado nesta etapa, filho da US 164251, estado New)
- **Comentário na US 164251:** 3 hipóteses em aberto (#26, #27, #28) pedindo confirmação de dev/PO
- **Fontes:** critérios de aceite da US, Pontos de Impacto e Casos de Teste do card 164256, histórico de defeitos

## Pré-requisitos de execução
- Build da branch `bugfix/US164251-bpm-correcao-job-travando-execucao` (PR 29707 aberto).
- Autorização para escrita direta em `JOB_BPM`.
- Worker BPM ativo com o `JobConfig` do job ativo.
- Dados montados no fuso (`TimeZoneId`) do job.
- Acesso ao log do Worker.
- Se possível, SQL Server e Oracle.

Status: 1 Agendado · 2 Executando · 3 Sucesso · 4 FalhaParaRepetir · 5 Envenenado · 6 Cancelado.

## Histórico de defeitos considerado
- Geraram regressão: #157977, #156951, #159841, #160640.
- Desconsiderados (sem relação com a mudança): #163006, #158415, #158422, #158440 e demais da busca.

## Dimensões cobertas
Positivo, negativo, dados, concorrência e regressão. Permissão: N/A (rotina interna do Worker). Erros de integração: N/A (nenhuma fonte pede).

## Cenários

| # | Cenário | Ação | Resultado Esperado | Tipo | Técnica | Dimensão | Origem |
|---|---|---|---|---|---|---|---|
| | **=== FLUXO PRINCIPAL ===** | | | | | | |
| 1 | Item travado com Sucesso (3) é movido | No `JOB_BPM`, linha do EnviaAlertaFluxo (Job 32) com status 3, `Data_Atualizacao` há mais de 60 s e sem lock. Esperar o próximo ciclo | Linha sai do `JOB_BPM`; 1 registro no `JOB_DUMP` com `Id_Origem` = Id e status 3; log "estava travado com status final 3 e foi movido para JOB_DUMP" com Id e ChaveUnica | positivo | partição-equivalência | positivo | história / análise técnica |
| 2 | Item travado com Envenenado (5) é movido | Igual ao #1 com status 5 | Mesmo resultado do #1 com status 5 | positivo | partição-equivalência | positivo | história / análise técnica |
| 3 | Item travado com Cancelado (6) é movido | Igual ao #1 com status 6 | Mesmo resultado do #1 com status 6 | positivo | partição-equivalência | positivo | história / análise técnica |
| 4 | Agendamento volta a funcionar após a limpeza | Linha travada status 3 com a mesma `Chave_Unica` do agendamento fixo do EnviaAlertaFluxo. Esperar a limpeza e o ciclo do Scheduler | Scheduler insere o item novo; o Worker executa e finaliza normalmente | positivo | exploratório | positivo | história / análise técnica |
| 5 | Item travado não é reexecutado | No #1, conferir o efeito do job após a limpeza | Alerta não reenviado; sem "Iniciando processamento" para o Id movido | negativo | exploratório | negativo | história / histórico de defeitos (156951) |
| | **=== FLUXO ALTERNATIVO ===** | | | | | | |
| 6 | Limpeza vale para o ExecutaSql | Igual ao #1 no Job 19 | Mesmo resultado do #1 com Job ExecutaSql no log | positivo | partição-equivalência | positivo | história (CA4) / análise técnica |
| 7 | Limpeza vale para os demais jobs ativos | Repetir o #1 nos jobs 7, 8, 9, 18, 20 e 28 | Em cada job a linha é movida e o log registra o job correto | positivo | partição-equivalência | positivo | história (CA4) |
| | **=== VALIDAÇÕES DE CONDIÇÃO (status / tempo / lock) ===** | | | | | | |
| 8 | Item recém-finalizado (menos de 60 s) não é tratado como travado | Linha status 3 com `Data_Atualizacao` há ~20 s | Não é pega pela busca nova; só é movida depois dos 60 s | borda | valor-limite | negativo | análise técnica |
| 9 | Item logo acima do limite de 60 s é movido | Linha status 3 com `Data_Atualizacao` há ~70 s | Movida no ciclo seguinte | borda | valor-limite | positivo | análise técnica |
| 10 | Status final com lock válido não é movido | Linha status 3, mais de 60 s, `Lock_Expira_Em` no futuro | Não é movida enquanto o lock vale; depois de expirar, é movida | borda | tabela-decisão | negativo | análise técnica |
| 11 | Conteúdo do log ao mover | Nos #1 a #3, ler o log da limpeza | Job, Id, ChaveUnica e status final; informa que já tinha sido processado e foi movido | positivo | exploratório | positivo | história (CA3) |
| | **=== PERMISSÃO ===** | | | | | | |
| 12 | N/A | — | Rotina interna do Worker, sem usuário ou perfil | — | — | permissão | história |
| | **=== DADOS E CASOS DE BORDA ===** | | | | | | |
| 13 | Job sem itens travados e sem fila | Sem linhas do job no `JOB_BPM`; esperar o ciclo | Log "não possui itens ativos"; nada muda no `JOB_DUMP` | borda | partição-equivalência | dados | história (CA1) |
| 14 | Linha travada que já tem registro no dump | Linha status 3, mais de 60 s, Id já existente como `Id_Origem` no `JOB_DUMP` | Linha sai do `JOB_BPM`; 1 único registro no dump; log "ja tinha sido movido para JOB_DUMP" | borda | tabela-decisão | dados | análise técnica |
| | **=== CONCORRÊNCIA ===** | | | | | | |
| 15 | Duas instâncias pegam o mesmo item travado | 2 instâncias do Worker; 1 linha travada | 1 registro no dump; linha sai do `JOB_BPM`; nenhuma linha órfã | positivo | exploratório | concorrência | análise técnica |
| | **=== ERROS DE INTEGRAÇÃO / API ===** | | | | | | |
| 16 | N/A | — | Nenhuma fonte pede teste de falha de banco durante a movimentação | — | — | — | — |
| | **=== REGRESSÃO ===** | | | | | | |
| 17 | Item Agendado segue o caminho normal | Item status 1 no prazo | Processado normalmente e dump uma vez só | positivo | partição-equivalência | regressão | análise técnica |
| 18 | FalhaParaRepetir continua reprocessado | Item status 4 abaixo do limite | Reexecutado; não vai para o dump pela busca nova | positivo | partição-equivalência | regressão | análise técnica |
| 19 | Executando com lock válido não é tocado | Item status 2, lock no futuro | Nenhuma busca altera | negativo | tabela-decisão | regressão | análise técnica |
| 20 | Fim normal com sucesso gera 1 dump | Item real executado com sucesso | Sai do `JOB_BPM`, 1 dump status 3; sem log de "travado" | positivo | exploratório | regressão | análise técnica |
| 21 | Falha até esgotar tentativas vai para Envenenado | Forçar falha até `MaxTentativas` | FalhaParaRepetir nas tentativas, termina Envenenado com 1 dump e `Ultimo_Erro` | negativo | valor-limite | regressão | análise técnica / histórico (157977) |
| 22 | Exceção no handler não vira Sucesso | Exceção no envio do EnviaAlertaFluxo | Não fica status 3; vai para FalhaParaRepetir ou Envenenado | negativo | exploratório | regressão | histórico (157977) |
| 23 | NotifyWf executa mais de uma vez sem erro de lock | Vários itens NotifyWf em ciclos | Todos processados; sem erro de lock | positivo | exploratório | regressão | histórico (159841) |
| 24 | Execução paralela por instâncias funciona | Job com mais de 1 instância e vários itens | Cada item processado uma vez; sem dump duplicado | positivo | exploratório | regressão | histórico (160640) |
| 25 | ECM não muda de comportamento | Rotina ECM até o fim | 1 registro no dump como antes (insert do dump é compartilhado) | positivo | exploratório | regressão | análise técnica |
| | **=== CASOS DE BORDA / HIPÓTESES ===** | | | | | | |
| 26 | HIPOTESE: várias linhas travadas do mesmo job no mesmo ciclo | 3 linhas travadas (3, 5, 6) do mesmo job | VERIFICAR COM DEV/PO: esperado mover as 3 no mesmo ciclo | borda | valor-limite | dados | hipótese |
| 27 | HIPOTESE: status final com `Data_Atualizacao` nula | Linha status 3 com `Data_Atualizacao` = NULL | VERIFICAR COM DEV/PO: pela regra dos 60 s nunca seria pega | borda | partição-equivalência | dados | hipótese |
| 28 | HIPOTESE: texto do log "já movido" | Reproduzir o #14 sem concorrência | VERIFICAR COM DEV/PO: log diz "por outra execucao concorrente"; atende o CA3? | borda | exploratório | positivo | hipótese |
