# Validação de ambiente — Bug #161839 (US #161711 Bugs Instaladores / Mapa local 25-mapa-testes-bug-161839.md)

**Status do gate:** BLOQUEADO
**Ambiente:** local (máquina do QA), não produtivo. Share clássico em IIS Express; net8 (API, Scheduler, Worker BPM) com `DBType = SQLServer` nos 3 `appsettings.json` (lido sem segredos)
**Banco(s):** SQL Server 2019 acessível (banco `ShareGuizao`, `sqlcmd` com autenticação do Windows, só leitura). Oracle: **PAUSADO** (sem credencial segura para `sqlplus`; pacote manual em `sql/00-validar-ambiente-oracle.sql`)
**Build/commit esperado:** `bfaf8358` (PR 30253, net8) e `4b3535e7` (PR 30254, clássico); branch `bugfix/bug161839-previous-task-executor-notification` nos dois
**Build/commit encontrado:** clones `smartshare-net8` e `SmartShare` na branch `feature/US160823-migracao-job-inicio-desassociar-automatico`, com `appsettings.json` e `Web.config` modificados localmente. Nenhum Scheduler ou Worker em execução.
**RUN_ID:** 20261109-161711-161839
**Validade:** mapa local `25-mapa-testes-bug-161839.md` (etapas 21 a 25, aprovado só local em 09/11), ambiente local, SQL Server `ShareGuizao`. Expira se o build, o banco ou o mapa mudarem.

> Desvio registrado: a skill exige o card "Criar Mapa de Teste" no Azure DevOps; o QA aprovou os mapas só locais (etapa 04 e 09/11). O mapa local foi usado como fonte.

## Resumo
| Dimensão | Status | Evidência | Pendência |
|---|---|---|---|
| Mapa | OK (local) | arquivo `25-mapa-testes-bug-161839.md` | nenhum |
| Acesso SQL Server | OK | `sqlcmd -E` leu `DB_NAME`, usuário e versão (SQL Server 2019) | nenhum |
| Acesso Oracle | PAUSADO | `sqlplus` 12.2 existe; `TNS_ADMIN` com alias `orcl`; sem `QA_ORA_*` | credencial segura ou evidência manual |
| Build/branch | BLOQUEADO | branch remota `bugfix/bug161839-previous-task-executor-notification` existe no commit esperado; working tree em outra branch | checkout, build e implantação da branch |
| Serviços | BLOQUEADO | sem Scheduler ou Worker BPM em execução | subir após o build |
| Schema (SQL Server) | OK | `CAMINHO_FLUXO`, `TAREFA`, `OBSERVACAO_TAREFA`, `PASSO_USUARIO` existem | nenhum |
| JOB_CONFIG do NotifyWf (job 9, módulo 1) | OK | `Ativo = 1`, `Max_Tentativas = 5` | nenhum |
| Massa: passo com observação = opção 4 | AUSENTE | `PASSO_USUARIO` sem passo com `id_permissao_observacao = 4`; o processo 1019 "QA - Notifica Observação" tem o passo 4 com opção 2 (v1) e 3 (v2 e v3), 5 fluxos | `UPDATE` autorizado em uma versão do 1019 (a etapa 05 fez isso no Oracle) ou criar pela tela |
| Massa: processos de teste da etapa 05 (481 e 522) | NÃO NECESSÁRIO | existem só no Oracle; no SQL Server o 1019 cumpre o papel | nenhum |
| Estado a restaurar no Oracle | NÃO VERIFICADO | etapa 05 deixou `ID_PERMISSAO_OBSERVACAO` = 4 no processo 522 v1, passo 6 | confirmar por leitura no Oracle e reverter com autorização |
| Agent clássico com PR 30254 | AUSENTE | clone do clássico em outra branch; serviço `SmartShareAgent` não validado | build e instalação |
| E-mail | PENDENTE | falha conhecida do Graph (`Content-Type`); QA aceita log do Worker | nenhum, se mantida a decisão |
| Troca de banco | INFORMATIVO | ambiente em SQL Server; Oracle exige a troca de `QA-KB-20261106-001` (revalidar) | decidir a ordem dos bancos |

## Massas criadas nesta execução
Nenhuma. Nenhuma escrita foi feita (a criação exige autorização específica por operação).

## Pendências bloqueantes
- Build: fazer checkout, build e implantação da branch do PR, sem perder as alterações locais de `appsettings.json` e `Web.config` (guardar antes).
- Oracle: fornecer credencial por variável segura (`QA_ORA_USER`, `QA_ORA_PASSWORD`, `QA_ORA_CONNECT`) ou devolver a saída de `sql/00-validar-ambiente-oracle.sql`.
- Massas e configuração listadas acima (cada `INSERT` ou `UPDATE` precisa de autorização com ambiente, objeto, valores, quantidade e rollback).

## Decisão
**BLOQUEADO.** Retomar quando: build da branch implantado e confirmado, todas as massas existirem e forem lidas, e o Oracle estiver validado (ou o QA decidir restringir a rodada ao SQL Server).

## Atualização da preparação (09/11, depois da autorização do QA)
- **Build:** worktree da branch criado e `Project.Agent.Worker.Bpm` e `Project.Agent.Worker.Scheduler` compilados com 0 erros (em `Temp/wt<PR>`); `appsettings.json` do projeto e do `bin` com o bloco de conexão do SQL Server (`DBType = SQLServer`). Falta iniciar Scheduler e Worker e conferir a versão pelo log de partida.
- **Massas e configuração aplicadas:** ver `massa/MANIFESTO-massa.md` (job 20 inserido, opção 4 no processo 1019 v3, baseline do job 28 limpo). Ativação de jobs por bug: `sql/ativar-reverter-jobs.sql`, aplicada na hora da execução.
- **Gate continua BLOQUEADO** até: Scheduler e Worker iniciados com a versão confirmada, itens específicos deste bug abaixo e Oracle validado (ou escopo restrito ao SQL Server).
- **Específico #161839:** opção 4 aplicada no processo 1019 v3 passo 4. Falta Agent clássico com o PR 30254 e o estado do Oracle (522 v1 passo 6) continua não verificado.
- **Decisão do QA (09/11):** cenários do clássico (2, 6 e 11) fora da rodada; Agent clássico do PR 30254 não é mais requisito do gate.

## Gate final — SQL Server (09/11)
**Status: LIBERADO PARA EXECUÇÃO (SQL Server, só net8)**, cenários 1, 3, 4, 5, 7, 8, 9 e 10 do mapa 25. Clássico (2, 6 e 11) fora da rodada.
- Build: worktree `Temp/wt30253` (`bfaf8358`), Worker BPM e Scheduler recompilados, conexão SQL Server (cópia Oracle em `.oracle.bak`).
- Massa: processo 1019 v3, passo 4 com observação = opção 4 (era 3; backup em `massa/`); 5 fluxos. Cenários com tarefa automática, dois fluxos e ramos paralelos exigem fluxos próprios, a iniciar na execução.
- E-mail: falha do Graph conhecida; o QA aceita o log do Worker como evidência.
Assinatura de contexto: ambiente local SQL Server ShareGuizao (NOTE-74VQ\SQLEXPRESS), RUN_ID 20261109-161711, mapas locais 21 a 25 (aprovados só local em 09/11), parâmetro 96 = 0, manifesto massa/MANIFESTO-massa.md. Expira se o build, o banco, o mapa ou a massa mudarem.
