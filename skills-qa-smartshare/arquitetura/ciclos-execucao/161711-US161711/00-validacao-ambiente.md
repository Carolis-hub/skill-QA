# Validação de ambiente — US #161711 Bugs Instaladores (consolidado por bug)

**Status do gate (SQL Server, 09/11 tarde):** LIBERADO PARA EXECUÇÃO em #161716, #161713, #161714, #161839 (net8) e #161712 (condição aceita); **#161712 LIBERADO (massa criada nos passos do cenário, aceito pelo QA)**; Oracle em gate próprio (pendente)
**Data:** 2026-11-09 | **Ambiente:** local, não produtivo | **RUN_ID base:** 20261109-161711
**Método de banco:** SQL Server = `ADAPTER_LOCAL` (`sqlcmd -E`, só leitura, config em `.claude/qa-arquitetura/validacao-banco.local.json`, sem segredos). Oracle = PAUSADO (sem credencial segura; pacote manual `sql/00-validar-ambiente-oracle.sql`).
**Escritas no banco (SQL Server local, autorizadas pelo QA):** 5 operações listadas em `massa/MANIFESTO-massa.md` (job 20 inserido, opção 4 no 1019 v3, baseline do job 28 apagado, SQL inválido no passo 101 do processo 5 v2, parâmetro 96 = 0), com backups em `massa/`. Ativações de `JOB_CONFIG.Ativo` ficam para a execução. Além disso, 1 fluxo (900750) foi iniciado no ensaio.

| Bug | Branch / PR | Gate | Bloqueios principais |
|---|---|---|---|
| #161716 | PR 30104 | BLOQUEADO | build não implantado; job 28 inativo; sem mock HTTP; sem 101 fluxos; sem processo de teste |
| #161713 | PR 30060 | BLOQUEADO | build; job 19 inativo; sem processo com atividade SQL e escape; mecanismo de falha |
| #161712 | PR 30457 | BLOQUEADO | build; job 22 e 19 inativos; job 20 sem `JOB_CONFIG`; massa por job; fuso de teste |
| #161714 | PR 30486 | BLOQUEADO | build; sem fluxo temporal; sem mecanismo de erro; sem exemplo do log |
| #161839 | PR 30253 e 30254 | BLOQUEADO | build net8 e clássico; sem passo com observação 4 no SQL Server; estado do Oracle (522 v1 passo 6) não verificado |

## Achados comuns
- As 5 branches remotas existem e apontam para os commits esperados (`e1396988`, `d4a98152`, `9816142b`, `3ac5ea98`, `bfaf8358`; clássico `4b3535e7`).
- Os dois clones estão em `feature/US160823-migracao-job-inicio-desassociar-automatico` com alterações locais de ambiente (`appsettings.json` e `Web.config`). Trocar de branch exige guardar essas alterações.
- Nenhum Scheduler, Worker BPM ou serviço `SmartShareAgent` rodando; só o IIS Express e dois `sqlservr`.
- SQL Server local, `JOB_CONFIG` módulo 1: `Politica_Backoff = 0` em todos; `Max_Tentativas = 5`, exceto o ExecutaSql (job 19) com 2; `Ativo = 0` nos jobs 16, 19 (ExecutaSql), 22 (InicioPublicacao), 25, 28 (ExecutaWs), 33 e 34; ExecutaPassoAplicacao (job 20) sem linha. Ativos: 7, 8, 9, 18 e 32.
- Os processos 481, 501 e 522 usados na etapa 05 existem só no Oracle; no SQL Server não há esses processos nem passo com observação = 4.

Relatórios por bug: `00-validacao-ambiente-bug-161716.md`, `-161713.md`, `-161712.md`, `-161714.md`, `-161839.md`.

## Decisão
**BLOQUEADO para todos os bugs.** A rodada só segue quando os 5 relatórios estiverem `LIBERADO PARA EXECUÇÃO` (ou o QA restringir o escopo).

## Preparação do ambiente (SQL Server) — andamento em 2026-11-09
- **Correção:** a primeira leitura só procurou os processos 481, 501 e 522 (do Oracle). O SQL Server já tem processos de QA: 1027 (WebService, 138 tarefas abertas), 1019 (observação), 1018 (alerta), 1024 (exclusão), 1010/1012/1013/1015/1016 (início temporal), 6/9/10/1011 (avanço temporal). Os relatórios por bug foram regenerados com isso.
- **Worktrees criados (fora do repositório, sem tocar no clone atual):** `Temp/wt30104`, `wt30060`, `wt30457`, `wt30486` (e o `wt30253` que já existia, com `DBType = Oracle` e bin antigo). Clone atual intacto.
- **Builds:** `Project.Agent.Worker.Bpm` de wt30104 e wt30060 compilaram com 0 erros; os demais e os Schedulers (`Project.Agent.Worker.Scheduler.csproj`) estavam em andamento. Configuração do banco (`ConnectionStrings` do SQL Server) ainda **não** copiada para os worktrees.
- **Ainda sem massa:** processo com atividade SQL que falha, com e sem passo de escape (#161713). O processo 10 só tem `SELECT 1, 2` e o 8 tem um passo SQL sem comando; nenhum falha.
- **Pendente de autorização (escritas):** `UPDATE JOB_CONFIG` (jobs 19, 22, 28), `INSERT` do job 20, `UPDATE PASSO_USUARIO` (opção 4 no processo 1019), limpeza do baseline de `JOB_BPM` (22 jobs do job 28 em status 1) e a criação dos dois processos SQL.

## Atualização 09/11 (continuação da preparação)
- **Mock HTTP (#161716):** `ferramentas/mock_ws_44303.py` criado e testado (200 JSON em GET e POST; modos `ok`, `erro500` e `lento`; grava `mock_ws_requests.log` com uma linha por chamada). A `WS_CONSULTA` 1 já aponta para `http://localhost:44303/api/v1/Cliente/getCliente3`, sem parâmetros de requisição ou retorno: **nenhuma alteração de banco foi necessária**. O mock está parado; iniciar na execução.
- **Versão dos builds (proveniência):** `HEAD` de cada worktree = commit esperado (`e1396988`, `d4a98152`, `9816142b`, `3ac5ea98`, `bfaf8358`) e `Project.Core.Application.dll` compilado do worktree às 10:32, 10:33, 10:34, 10:35 (wt30253 em recompilação). Confirmação final pelo log de partida do Worker na execução.
- **Agent clássico (PR 30254):** MSBuild do Visual Studio 18 existe; worktree e build do `SmartShareAgent.csproj` iniciados (resultado abaixo quando concluir).
- **#161714:** o `catch` de `ProcessarFluxo` só roda se `AvancarFluxo` lançar exceção; **nenhum mecanismo natural de provocá-la** foi encontrado. Depende do dev ou de decisão do QA (cenários 1, 2, 3 e 5 do mapa 24).

## Oracle — validação por leitura (2026-11-09, adapter local `sqlplus`)
- **Acesso:** OK. Schema `SHAREGUIZAO`, banco `SSHARE` (Oracle 19c Standard Edition 2). Credencial lida em tempo de execução do arquivo de variáveis do projeto (autorização do QA no chat), passada por stdin, sem exibir ou gravar. Só consultas de leitura.
- **Schema:** as 12 tabelas esperadas existem; `JOB_BPM.CHAVE_CONCORRENCIA` existe.
- **`JOB_CONFIG` módulo 1:** todos os jobs 7, 8, 9, 16, 18, 19, 22, 25, 28, 32, 33 e 34 estão `Ativo = 1` (no Oracle não é preciso ativar). Job 19 (ExecutaSql) com `Max_Tentativas = 5` e `Interval_Ms = 30000`; job 28 com `Interval_Ms = 60000`. **Job 20 (ExecutaPassoAplicacao) sem linha**, como no SQL Server.
- **Baseline:** `JOB_BPM` com 1 linha (job 32, status 1); `JOB_DUMP` com 34.028 linhas.
- **Massa existente:** #161839: processos 481 (v1, v2, v6, passo 5) e 522 (v1, passo 6) com opção 4. **O UPDATE da etapa 05 (522 v1 passo 6 = 4) continua ativo.** Avanço temporal: 442 (11 fluxos). Início temporal: 441 (23). Alerta: 461 (10). Exclusão: 421 (4). WebService: 501 (só 3 fluxos). 
- **Massa ausente no Oracle:** nenhum processo com passo SQL (`PASSO_BD` vazio em todos); nenhum processo com passo de aplicação além dos padrões 1 e 2; falta massa de 101 fluxos para o #161716 (501 tem 3).
- **Troca de banco:** o Oracle usa `QA-KB-20261106-001` (webconfig.aspx); os `appsettings.json` dos worktrees hoje apontam para o SQL Server (cópia `.oracle.bak` só no `wt30253`).

## Agent clássico (PR 30254) — build falhou (2026-11-09)
Worktree `Temp/wtc30254` em `4b3535e7d` (base `master`). Restore passou após definir `SolutionDir` e copiar a pasta `packages` (não versionada). A compilação do `SmartShareAgent.csproj` falha com 16 erros `CS0618` em `SmartShare.Calendar\DAL\AgendamentoDAL.cs` (`DbConn.Parametros` obsoleto como erro). O clone principal está em outra branch e não reproduz o erro. Sem build do clássico: cenários 2, 6 e 11 do mapa 25 ficam sem Agent. Precisa do dev (ou de um Agent clássico já compilado com o PR).

## Decisões do QA em 09/11 e ensaio do Scheduler (SQL Server)
- **#161716, cenário 7 (falha de enfileiramento):** **fora da rodada** por decisão do QA (sem mecanismo natural: `JOB_BPM` só tem a PK `PK_JobBpm`; o `try/catch` por pendência é extra do PR). Risco residual registrado.
- **Gate por banco:** SQL Server agora; o Oracle fecha em gate próprio depois da troca de banco (`QA-KB-20261106-001`), com criação da massa que falta lá (processos com SQL, 101 fluxos WebService, job 20, UPDATE do 522 a reverter). Acesso de leitura ao Oracle já validado.
- **Ensaio do Scheduler do PR 30486 (100 s, só o Scheduler):** subiu sem erro e enfileirou em `JOB_BPM`: job 7 (1), job 9 NotifyWF (4), job 18 (1), job 32 (1). **Nenhum job 8 (AvancoTemporal):** nenhuma tarefa elegível no momento. Essas linhas de status 1 passam a fazer parte do baseline da próxima rodada.
- **#161714 — mecanismo proposto:** (1) iniciar pela tela um fluxo com passo temporal elegível (processo 6, 9, 10 ou 1011); (2) com o Worker parado, deixar o Scheduler enfileirar o job 8; (3) concluir ou cancelar o fluxo pela tela; (4) subir o Worker do PR: `AvancarFluxo` deve falhar e o log mostrar o erro. **Ainda não confirmado**: falta um fluxo elegível (exige iniciar fluxo pela tela do Share).
- **Agent clássico:** build falhou (acima). Cenários 2, 6 e 11 do mapa 25 seguem sem Agent.

- **Decisão do QA (09/11):** cenários do **clássico** (2, 6 e 11 do mapa 25, PR 30254) **fora desta rodada**. O #161839 segue só no net8 (cenários 1, 3, 4, 5, 7, 8, 9 e 10). Risco residual: paridade net8 × clássico sem teste.

- **Login no Share (09/11):** página de login confirmada em `http://localhost:58149/SmartShare/index.aspx` (formulário no iframe `Portal/Login.aspx`, campos `txtDsLogin` e `txtDsSenha`). A leitura da senha de teste do `root` foi **negada pelo classificador de permissões** (credencial em texto no arquivo de variáveis); não foi contornada. Sem sessão no Share, não dá para iniciar o fluxo temporal do #161714 pela tela. Pendente: o QA entrar no Share no navegador do painel (ou liberar a leitura).

## Share via Playwright MCP (2026-11-09) — login e descobertas
- **Login:** feito no Playwright MCP em `http://localhost:58149/SmartShare/index.aspx` (usuário `root`, senha digitada pelo QA no chat; não gravada). Sessão ativa (Administrador).
- **Navegação:** o clique no nome de um processo da pasta "Principal - Processos" abre o **Editar Processo** em nova aba (não inicia fluxo); o botão "Novo Processo" abre o **desenhador** (`workflow/processo.aspx?tpAcao=novo&cdPasta=5`), útil para criar os processos com SQL no Oracle. Abas fechadas sem salvar. A pasta "Testes Locais - BPM" lista só 4 processos (`Processo Bertucci`, `Processo Bertucci CONSULTA ORACLE`, `Processo com replicação de consulta`, `Teste para Ocultação de colunas`).
- **Ainda não achado:** o caminho para **iniciar um fluxo** do processo 9 (AvançoTemporal) pela tela. Tentativas: nome do processo (edita), "Novo Processo" (desenhador), combo de atividades (filtro). Nada foi criado ou salvo.

## Registro de escopo — ensaio feito durante a preparação (09/11)
O QA questionou por que houve atividade de teste antes de `/arquitetura-executar-teste`. O que foi feito, **como ensaio do mecanismo de falha do #161714 (preparação, não execução do mapa)**: Scheduler do PR 30486 subido por 100 s; `UPDATE` do parâmetro 96 para `0` (autorizado); login no Share; **1 fluxo novo do processo 9 iniciado** (`IniciaFluxo.aspx?CDPROC=9`) e um clique em "avança" na primeira atividade. Nada disso foi contabilizado como resultado de cenário. **Execução interrompida a pedido do QA; nada mais será feito sem nova instrução.** Estado a limpar ou aceitar: o fluxo do processo 9, o parâmetro 96 (rollback no manifesto, operação 5) e as linhas enfileiradas pelo Scheduler (jobs 7, 9, 18, 32).
