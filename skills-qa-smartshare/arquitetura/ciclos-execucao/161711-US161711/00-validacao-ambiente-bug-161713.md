# Validação de ambiente — Bug #161713 (US #161711 Bugs Instaladores / Mapa local 22-mapa-testes-bug-161713.md)

**Status do gate:** BLOQUEADO
**Ambiente:** local (máquina do QA), não produtivo. Share clássico em IIS Express; net8 (API, Scheduler, Worker BPM) com `DBType = SQLServer` nos 3 `appsettings.json` (lido sem segredos)
**Banco(s):** SQL Server 2019 acessível (banco `ShareGuizao`, `sqlcmd` com autenticação do Windows, só leitura). Oracle: **PAUSADO** (sem credencial segura para `sqlplus`; pacote manual em `sql/00-validar-ambiente-oracle.sql`)
**Build/commit esperado:** `d4a98152` (PR 30060, branch `bugfix/BUG161713-bpm-sql-job-not-poisoning`)
**Build/commit encontrado:** clones `smartshare-net8` e `SmartShare` na branch `feature/US160823-migracao-job-inicio-desassociar-automatico`, com `appsettings.json` e `Web.config` modificados localmente. Nenhum Scheduler ou Worker em execução.
**RUN_ID:** 20261109-161711-161713
**Validade:** mapa local `22-mapa-testes-bug-161713.md` (etapas 21 a 25, aprovado só local em 09/11), ambiente local, SQL Server `ShareGuizao`. Expira se o build, o banco ou o mapa mudarem.

> Desvio registrado: a skill exige o card "Criar Mapa de Teste" no Azure DevOps; o QA aprovou os mapas só locais (etapa 04 e 09/11). O mapa local foi usado como fonte.

## Resumo
| Dimensão | Status | Evidência | Pendência |
|---|---|---|---|
| Mapa | OK (local) | arquivo `22-mapa-testes-bug-161713.md` | nenhum |
| Acesso SQL Server | OK | `sqlcmd -E` leu `DB_NAME`, usuário e versão (SQL Server 2019) | nenhum |
| Acesso Oracle | PAUSADO | `sqlplus` 12.2 existe; `TNS_ADMIN` com alias `orcl`; sem `QA_ORA_*` | credencial segura ou evidência manual |
| Build/branch | BLOQUEADO | branch remota `bugfix/BUG161713-bpm-sql-job-not-poisoning` existe no commit esperado; working tree em outra branch | checkout, build e implantação da branch |
| Serviços | BLOQUEADO | sem Scheduler ou Worker BPM em execução | subir após o build |
| Schema (SQL Server) | OK | `JOB_BPM`, `JOB_DUMP`, `JOB_CONFIG`, `PASSO_USUARIO` existem | nenhum |
| JOB_CONFIG do ExecutaSql (job 19, módulo 1) | PENDENTE | `Max_Tentativas = 2`, `Politica_Backoff = 0`, **`Ativo = 0`**, `Interval_Ms = 10000`, `Batch_Size = 10` | ativação exige `UPDATE` autorizado; `Max_Tentativas = 2` limita os cenários 1 e 7 (precisa de N−1 e N); só uma política de backoff configurada (o cenário 6 pede duas) |
| Massa: processo com atividade SQL (com e sem passo de escape) | PENDENTE | processos com `PASSO_BD` no SQL Server: 4, 5, 8, 10, 23 (e 22, consulta Oracle); falta confirmar qual tem passo de escape configurado e qual não tem (`PASSO_BD.st_avanca_atividade` e `PASSO_SEQUENCIA`) | mapear por leitura; se faltar uma variante, criar |
| Mecanismo de falha de SQL | PENDENTE | proposta: SQL inválido na atividade; falha de `AvancarFluxo` do escape sem mecanismo | dev confirmar |
| Ajuste de `Qt_de_Tentativas` para chegar à última tentativa | PENDENTE | exige `UPDATE` em `JOB_BPM` | autorização específica |

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
- **Específico #161713:** sem escape e com falha natural no SQL Server: processos 4, 5 (v1), 10 e 1022 têm o passo 52 `SELECT 1, 2 FROM DUAL` (não existe `DUAL` no SQL Server), sem passo de escape filho. Com escape: o passo 101 de 4, 5, 10 e 1022 tem o escape 103 (tipo 13), mas o SQL `Select 1, 2` é válido e não falha. **Pendente:** UPDATE do SQL do passo 101 do processo 5 v2 (passo 52 da v2 já é válido) para um SQL inválido, com rollback para `Select 1, 2`; aguarda autorização específica. `Max_Tentativas` do job 19 é 2.
- **Atualização:** UPDATE autorizado e aplicado em 09/11: processo 5 v2, passo 101, SQL inválido (`SELECT * FROM TABELA_QA_INEXISTENTE_161713`). Variante **com escape** que falha: processo 5 v2 (passo 52 válido, passo 101 falha, escape 103). Variante **sem escape** que falha: passo 52 de processo 4, 5 v1, 10 ou 1022 (`FROM DUAL`). Falta iniciar um fluxo em cada e ativar o job 19 na execução.

## Gate final — SQL Server (09/11)
**Status: LIBERADO PARA EXECUÇÃO (SQL Server)**, cenários 1 a 9 do mapa 22; o cenário 10 é hipótese (não executa automaticamente).
- Build: worktree `Temp/wt30060` (`d4a98152`), Worker BPM e Scheduler compilados, conexão SQL Server.
- Massa: sem escape que falha (passo 52 `FROM DUAL` em 4, 5 v1, 10 e 1022); com escape que falha (processo 5 v2, passo 101 inválido, escape 103). Processo 9 não é massa deste bug.
- Configuração: job 19 (Id 33) com `Max_Tentativas = 2`; ativar na execução. Ajuste de `Qt_de_Tentativas` em `JOB_BPM` (cenários 2, 3, 4, 7) exige `UPDATE` com autorização específica na hora.
- Na execução: iniciar um fluxo por variante (`IniciaFluxo.aspx?CDPROC=<processo>`), com o parâmetro 96 em 0.
Assinatura de contexto: ambiente local SQL Server ShareGuizao (NOTE-74VQ\SQLEXPRESS), RUN_ID 20261109-161711, mapas locais 21 a 25 (aprovados só local em 09/11), parâmetro 96 = 0, manifesto massa/MANIFESTO-massa.md. Expira se o build, o banco, o mapa ou a massa mudarem.
