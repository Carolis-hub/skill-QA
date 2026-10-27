# Ciclo de QA — Task 164259 / US 164251

- **Task:** [164259] - Testes do card de bugs 164251 (tipo Teste, estado Committed)
- **História:** [#164251](https://dev.azure.com/selbettidev/SmartShare%20Arquitetura/_workitems/edit/164251) — [BUG] Ajustar regra de leitura de status no BPM
- **Projeto:** SmartShare Arquitetura | **Sprint:** Sprint 4 | **Tipo:** Product Backlog Item
- **Responsável pela US:** Vinicius Medeiros dos Santos
- **QA:** Guilherme Henrique Correa Borges
- **Código:** repositório `smartshare-net8` (projeto SHARE-4), PRs 29707 (correção principal, aberto para `main`) e 29965 (ajustes de code review, concluído)

## Etapas

| # | Etapa | Data | Status | Escreveu no Azure DevOps? | Arquivo |
|---|---|---|---|---|---|
| 0 | Preparação do ambiente (MCP Azure DevOps) | 2026-10-26 | Concluída | Não | (abaixo) |
| 1 | `/analise-negocio 164251` | 2026-10-26 | Concluída | Não | [01-analise-negocio.md](01-analise-negocio.md) |
| 2 | `/analise-tecnica 164251` | 2026-10-26 | Concluída | Não | [02-analise-tecnica.md](02-analise-tecnica.md) |
| 3 | `/gerar-mapa-testes-v3 164251` | 2026-10-26 | Concluída | Sim | [03-mapa-testes.md](03-mapa-testes.md) |
| 4 | `/executar-teste 164251` | 2026-10-26 | Bloqueada — MCP azure-devops sem conexão e MCP de navegador inexistente | Não | [04-execucao-testes.md](04-execucao-testes.md) |
| 5 | `/executar-teste 164251` | 2026-10-26 | Parcial — 5 passou, 4 passou parcial, 0 falhou, 14 não executados (ambiente local ShareGuizao, só leitura) | Não | [05-execucao-testes.md](05-execucao-testes.md) |
| 6 | `/executar-teste 164251` (cenários com escrita) | 2026-10-26 | Concluída — #2, #8, #9, #10, #14, #19 passaram. Acumulado: 11 passou, 4 parcial, 0 falhou, 8 não executados | Não (escreveu no banco local com autorização) | [06-execucao-testes.md](06-execucao-testes.md) |
| 7 | `/executar-teste 164251` (#15 concorrência) | 2026-10-26 | Concluída — #15 passou (2 instâncias, 600 itens, disputa real de ~6,6 s, 0 duplicados). Acumulado: 12 passou, 4 parcial, 0 falhou, 7 não executados | Não (escreveu no banco local com autorização) | [07-execucao-testes.md](07-execucao-testes.md) |
| 8 | `/executar-teste 164251` (#4 agendamento) | 2026-10-26 | Concluída — #4 passou no job 18 (bloqueio do Scheduler reproduzido e liberado pela limpeza). Acumulado: 13 passou, 4 parcial, 0 falhou, 6 não executados | Não (escreveu no banco local com autorização) | [08-execucao-testes.md](08-execucao-testes.md) |
| 9 | `/executar-teste 164251` (#18 e #21 falha) | 2026-10-26 | Concluída — #18 e #21 passaram (#21 via fluxo inexistente; plano do SMTP descartado). Acumulado: 15 passou, 4 parcial, 0 falhou, 4 não executados | Não (escreveu no banco local com autorização) | [09-execucao-testes.md](09-execucao-testes.md) |
| 10 | `/executar-teste 164251` (#6, #24, #22, #25) | 2026-10-26 | Parcial — #6 e #24 passaram (JOB_CONFIG alterado e restaurado). #22 não executado (conflito com regra documentada no código e risco de e-mail real). #25 não executado (Worker ECM sem configuração). Acumulado: 17 passou, 4 parcial, 0 falhou, 2 não executados | Não (escreveu no banco local com autorização) | [10-execucao-testes.md](10-execucao-testes.md) |
| 11 | `/executar-teste 164251` (#22 e #1 no job 32) | 2026-10-26 | Parcial — #1 passou no EnviaAlertaFluxo. #22 não executado: os 72 envios reais foram aceitos e a falha não ocorreu. Regra do PO: Sucesso mesmo com falha de envio; o mapa precisa ser ajustado. Achado: reenvio de alertas vencidos a cada execução. Acumulado: 18 passou, 3 parcial, 0 falhou, 2 não executados | Não (escreveu no banco local com autorização; 72 e-mails reais enviados a endereços de QA) | [11-execucao-testes.md](11-execucao-testes.md) |
| 12 | Hipóteses #26–#28 comparadas com o Agent legado (PO de férias) | 2026-10-27 | Concluída — referência adotada: #26 move as 3 no mesmo ciclo; #27 não pode travar para sempre (inferido, resultado provável Falhou); #28 Passou com observação de redação | Não | [12-hipoteses-legado.md](12-hipoteses-legado.md) |
| 13 | `/executar-teste 164251` (#26 e #27) | 2026-10-27 | Concluída — #26 passou (3 linhas movidas no mesmo ciclo). **#27 falhou**: linha com `Data_Atualizacao` nula não é movida em nenhum ciclo. Placar final: 20 passou, 3 parcial, 1 falhou, 1 não executado | Não (escreveu no banco local com autorização) | [13-execucao-testes.md](13-execucao-testes.md) |
| 14 | `/analise-falha` (#27) | 2026-10-27 | Concluída — veredito **NÃO**: obtido comprovado e reprodutível, mas o esperado é hipótese inferida do legado e não há caminho conhecido que grave `Data_Atualizacao` nula. Causa lida no código: `Data_Atualizacao <= @Limite` em `GetJobsTravados`/`ClaimJobTravado` | Não | [14-analise-falha.md](14-analise-falha.md) |
| 15 | Relatório de execução (fim da rodada 1) | 2026-10-27 | Concluída — rodada 1 encerrada: 20 passou, 3 parcial, 1 falhou (#27), 1 não executado (#22), 2 N/A. Relatório e análise de falha anexados à task 164259 | Sim (2 anexos na task 164259) | [15-relatorio-execucao.md](15-relatorio-execucao.md) |
| 16 | `/executar-teste 164251` — **rodada Oracle** (SHAREGUIZAO, commit d9784d80) | 2026-10-27 | Concluída — 20 passou, 3 parcial (#5, #7, #9 — reclassificado pelo double-check), 1 passou com observação (#28), 1 falhou (#27, igual ao SQL), 0 não executado, 2 N/A. #22 executado: falha de envio real, job em Sucesso. 625 dumps QA de evidência; JOB_CONFIG restaurado; Worker e Scheduler encerrados | Não (escreveu no Oracle com autorização) | [16-execucao-testes-oracle.md](16-execucao-testes-oracle.md) |
| 17 | Relatório de execução — **rodada Oracle** | 2026-10-27 | Concluída — relatório anexado à task 164259 como `US164251-relatorio-execucao-testes-ORACLE.md`, com comentário identificando a rodada Oracle | Sim (1 anexo na task 164259) | [17-relatorio-execucao-oracle.md](17-relatorio-execucao-oracle.md) |

## Artefatos criados no Azure DevOps

| Artefato | Onde | Etapa |
|---|---|---|
| Card "Criar Mapa de Teste" [#165040](https://dev.azure.com/selbettidev/SmartShare%20Arquitetura/_workitems/edit/165040) com o mapa na Descrição | Filho da US 164251 | 3 |
| Comentário com as 3 hipóteses em aberto (#26, #27, #28) | Discussão da US 164251 | 3 |
| Ajuste do #22 (nome, resultado esperado pela regra do PO e origem) no card #165040, revisão 5 | Descrição do card #165040 | 11 |
| Anexos `US164251-relatorio-execucao-testes.md` e `US164251-analise-falha-c27.md` (conferidos por MD5 depois do upload) | Task 164259 | 15 |
| Anexo `US164251-relatorio-execucao-testes-ORACLE.md` (relatório da rodada Oracle; 13.464 bytes, mesmo tamanho do arquivo local) | Task 164259 | 17 |

## Etapa 0 — Preparação do ambiente

Necessária porque o MCP do Azure DevOps não estava configurado.

- Servidor `azure-devops` (`@azure-devops/mcp` 2.11.0, organização `selbettidev`, autenticação por PAT, domínios core, repositories, work-items, wiki e search) configurado na raiz de `~/.claude.json`.
- Variável de ambiente de usuário `PERSONAL_ACCESS_TOKEN` = base64 de `:<PAT>`. O valor não é registrado aqui.
- Cache do `npx` refeito: o primeiro download do pacote ficou incompleto (faltavam arquivos `.mjs` do `@azure/msal-node`).
- Lição: no comando de gravar a variável, o token só é colado no prompt `PAT:`; não se edita o nome da variável dentro do comando. Um token exposto em print deve ser regenerado.

## Pendências para a execução (etapa 4)

1. Build da branch `bugfix/US164251-bpm-correcao-job-travando-execucao` no ambiente de teste (PR 29707 ainda não está na `main`).
2. Autorização para escrita direta em `JOB_BPM` (quem executa, qual ambiente, qual banco).
3. Definir se roda em SQL Server, Oracle ou os dois (o SQL novo não foi executado em nenhum dos dois, segundo o PR).
4. Worker BPM ativo com o `JobConfig` dos jobs ativo; saber o intervalo do Quartz de cada job e o `TimeZoneId`.
5. Possibilidade de subir 2 instâncias do Worker (cenário #15).
6. Acesso ao log do Worker BPM.
7. Resposta de dev/PO às hipóteses #26, #27 e #28. Com o PO de férias, os testes seguem pelo Agent legado (etapa 12). A pergunta continua no card da US para a volta dele. Executados na etapa 13: #26 passou, **#27 falhou** (rodar `/analise-falha` antes de abrir defeito), #28 passou com observação.
8. ~~Reconectar o MCP `azure-devops`~~ (resolvido na etapa 5: servidor passou a iniciar com `node` direto).
9. Rechecar após 00:00 de 2026-10-27 se o Id 6686 (job 32, Cancelado) foi movido para o `JOB_DUMP` (cobre #1/#3 no EnviaAlertaFluxo).
10. ~~Execução dos cenários que exigiam escrita~~ (etapa 6: #2, #8, #9, #10, #14, #19 passaram). #15 na etapa 7, #4 na etapa 8, #18 e #21 na etapa 9, #6 e #24 na etapa 10 (todos passaram). Restam 2: #22 (executado com envio real na etapa 11, mas nenhum envio falhou. O PO confirmou que o job fica Sucesso mesmo com falha de envio, até a regra ser corrigida em todos os casos. ~~Atualizar o resultado esperado do #22 no mapa #165040~~, feito em 2026-10-27, revisão 5 do card) e ~~#25~~ (removido do mapa pelo usuário em 2026-10-27: nenhuma rotina de ECM foi migrada ainda, então o Worker ECM não funciona). **Placar final: 18 passou, 3 parcial, 0 falhou, 1 não executado (#22).**
11. ~~Decisão sobre as 3 divergências do double-check~~ (aceitas: #1, #5 e #23 viraram Passou parcial). Completar esses parciais: job 32 depois da 00:00 (#1), efeito de negócio dos itens movidos (#5), NotifyWf em ciclos diferentes (#23).
12. Rodada funcional no HMG (a etapa 5 foi no ambiente local de QA). ~~Rodada em Oracle~~: feita no Oracle local SHAREGUIZAO na etapa 16, com o mesmo comportamento do SQL; o HMG continua pendente para os dois bancos.
15. ~~**Oracle (etapa 16):**~~ **Resolvido em 2026-10-27 09:12: o 30010 foi removido do `JOB_BPM` por decisão do QA (`sql\oracle\18`).** Era o item real 30010 (job 32, st 2, lock vencido) ficou no `JOB_BPM` depois que um restart interrompeu a 3ª execução do job 32. Decidir se fica para o cron 00:00 (vai tentar os alertas de novo, e o envio está quebrado no Oracle) ou se é removido.
16. **Achados do Oracle para o dev (etapa 16):** alerta "consumido" sem entrega quando o envio falha (o `FLUXO_ALERTA` é atualizado com 0 envios); o retry fica preso à instância que falhou; dumps duplicados antigos (Id de origem 2931–2941, job 9, setembro); o `SYSDATE` do RDS está em UTC.
13. Avisar o dev: job 20 sem `JOB_CONFIG` no ambiente local; atraso de até 24 h na limpeza de jobs de cron diário; Scheduler loga "inserido com sucesso" mesmo quando o `NOT EXISTS` barra a chave (108 mensagens × 45 inserções reais no job 18), o que esconde o travamento (etapa 8); o retry reprograma o gatilho Quartz do job inteiro e pausa a limpeza daquele job durante o backoff; `NotifyStep` desconhecido vira Sucesso; avanço de fluxo inexistente dá `NullReferenceException` (etapa 9); alertas vencidos são reenviados a cada execução porque o próximo alerta é calculado a partir da data antiga (confirmado à 00:00 de 27/10: 30 reenvios e 13 alertas ainda vencidos depois); `LOG_EMAIL` não é gravado pelo Agent novo; `<br>` literal no corpo do alerta (etapa 11).
14. **#27 (análise de falha, etapa 14): veredito NÃO.** Para virar defeito, falta: (a) o dev confirmar se algum caminho grava `JOB_BPM.Data_Atualizacao` nula e se a busca deve tratar o nulo; ou (b) o PO responder a hipótese #27 na volta. Opcional: contar as linhas com data nula em HMG ou em base de cliente, com autorização.
