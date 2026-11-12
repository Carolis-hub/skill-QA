# Validação de ambiente — Bug #161716 (US #161711 Bugs Instaladores / Mapa local 21-mapa-testes-bug-161716.md)

**Status do gate:** BLOQUEADO
**Ambiente:** local (máquina do QA), não produtivo. Share clássico em IIS Express; net8 (API, Scheduler, Worker BPM) com `DBType = SQLServer` nos 3 `appsettings.json` (lido sem segredos)
**Banco(s):** SQL Server 2019 acessível (banco `ShareGuizao`, `sqlcmd` com autenticação do Windows, só leitura). Oracle: **PAUSADO** (sem credencial segura para `sqlplus`; pacote manual em `sql/00-validar-ambiente-oracle.sql`)
**Build/commit esperado:** `e1396988` (PR 30104, branch `bugfix/bug161716-executaws-duplicate-jobs`)
**Build/commit encontrado:** clones `smartshare-net8` e `SmartShare` na branch `feature/US160823-migracao-job-inicio-desassociar-automatico`, com `appsettings.json` e `Web.config` modificados localmente. Nenhum Scheduler ou Worker em execução.
**RUN_ID:** 20261109-161711-161716
**Validade:** mapa local `21-mapa-testes-bug-161716.md` (etapas 21 a 25, aprovado só local em 09/11), ambiente local, SQL Server `ShareGuizao`. Expira se o build, o banco ou o mapa mudarem.

> Desvio registrado: a skill exige o card "Criar Mapa de Teste" no Azure DevOps; o QA aprovou os mapas só locais (etapa 04 e 09/11). O mapa local foi usado como fonte.

## Resumo
| Dimensão | Status | Evidência | Pendência |
|---|---|---|---|
| Mapa | OK (local) | arquivo `21-mapa-testes-bug-161716.md` | nenhum |
| Acesso SQL Server | OK | `sqlcmd -E` leu `DB_NAME`, usuário e versão (SQL Server 2019) | nenhum |
| Acesso Oracle | PAUSADO | `sqlplus` 12.2 existe; `TNS_ADMIN` com alias `orcl`; sem `QA_ORA_*` | credencial segura ou evidência manual |
| Build/branch | BLOQUEADO | branch remota `bugfix/bug161716-executaws-duplicate-jobs` existe no commit esperado; working tree em outra branch | checkout, build e implantação da branch |
| Serviços | BLOQUEADO | sem Scheduler ou Worker BPM em execução | subir após o build |
| Schema (SQL Server) | OK | `JOB_BPM`, `JOB_DUMP`, `JOB_CONFIG` existem; `JOB_BPM` tem `Chave_Unica` e `Chave_Concorrencia` | nenhum |
| JOB_CONFIG do ExecutaWs (job 28, módulo 1) | PENDENTE | `Max_Tentativas = 5`, `Politica_Backoff = 0`, `Interval_Ms = 1000`, **`Ativo = 0`** | ativar o job exige `UPDATE` autorizado |
| Mock HTTP 200 JSON | AUSENTE | não encontrado | subir o mock |
| Massa: 101 fluxos com tarefa WebService | EXISTENTE (a confirmar) | processo 1027 "Processo de envenenamento WS": passo 3 (WebService, `cd_consulta = 1`) com 138 tarefas abertas e 0 concluídas (138 ≥ 101) | confirmar o endpoint da consulta 1 (mock HTTP) |
| Baseline de `JOB_BPM` | ATENÇÃO | 22 jobs do job 28 em status 1 (Agendado) já na fila; 1 job 32 em status 1; 1 job 34 em status 4. `JOB_DUMP`: 37.328 linhas | limpar ou aceitar o baseline; apagar exige `DELETE` autorizado |
| Mecanismo de falha de enfileiramento (cenário 7) | AUSENTE | não descrito | dev informar |

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
- **Específico #161716:** falta o mock HTTP e a consulta 1 (endpoint) apontando para ele; falta ativar o job 28 na execução; mecanismo de falha de enfileiramento (cenário 7) ainda sem definição.

## Gate final — SQL Server (09/11)
**Status: LIBERADO PARA EXECUÇÃO (SQL Server)**, para os cenários 1 a 6, 8 e 9 do mapa 21. Cenário 7 fora da rodada (decisão do QA).
- Build: worktree `Temp/wt30104` (`e1396988`), Worker BPM e Scheduler compilados, conexão SQL Server. Versão confirmada de novo pelo log de partida ao subir os serviços.
- Massa: processo 1027, passo 3 (WebService, consulta 1) com 138 tarefas abertas; baseline de `JOB_BPM` do job 28 limpo (22 linhas apagadas, backup em `massa/`).
- Mock: `ferramentas/mock_ws_44303.py`, testado; `WS_CONSULTA` 1 já aponta para ele.
- Na execução (passos do cenário, anunciados antes): ativar o job 28 (`sql/ativar-reverter-jobs.sql`), subir o mock e os serviços da branch.
- Oracle: gate próprio, depois da troca de banco.
Assinatura de contexto: ambiente local SQL Server ShareGuizao (NOTE-74VQ\SQLEXPRESS), RUN_ID 20261109-161711, mapas locais 21 a 25 (aprovados só local em 09/11), parâmetro 96 = 0, manifesto massa/MANIFESTO-massa.md. Expira se o build, o banco, o mapa ou a massa mudarem.
