# Validação de ambiente — Bug #161714 (US #161711 Bugs Instaladores / Mapa local 24-mapa-testes-bug-161714.md)

**Status do gate:** BLOQUEADO
**Ambiente:** local (máquina do QA), não produtivo. Share clássico em IIS Express; net8 (API, Scheduler, Worker BPM) com `DBType = SQLServer` nos 3 `appsettings.json` (lido sem segredos)
**Banco(s):** SQL Server 2019 acessível (banco `ShareGuizao`, `sqlcmd` com autenticação do Windows, só leitura). Oracle: **PAUSADO** (sem credencial segura para `sqlplus`; pacote manual em `sql/00-validar-ambiente-oracle.sql`)
**Build/commit esperado:** `3ac5ea98` (PR 30486, branch `bugfix/US161714-correcao-log-erro-descricao`)
**Build/commit encontrado:** clones `smartshare-net8` e `SmartShare` na branch `feature/US160823-migracao-job-inicio-desassociar-automatico`, com `appsettings.json` e `Web.config` modificados localmente. Nenhum Scheduler ou Worker em execução.
**RUN_ID:** 20261109-161711-161714
**Validade:** mapa local `24-mapa-testes-bug-161714.md` (etapas 21 a 25, aprovado só local em 09/11), ambiente local, SQL Server `ShareGuizao`. Expira se o build, o banco ou o mapa mudarem.

> Desvio registrado: a skill exige o card "Criar Mapa de Teste" no Azure DevOps; o QA aprovou os mapas só locais (etapa 04 e 09/11). O mapa local foi usado como fonte.

## Resumo
| Dimensão | Status | Evidência | Pendência |
|---|---|---|---|
| Mapa | OK (local) | arquivo `24-mapa-testes-bug-161714.md` | nenhum |
| Acesso SQL Server | OK | `sqlcmd -E` leu `DB_NAME`, usuário e versão (SQL Server 2019) | nenhum |
| Acesso Oracle | PAUSADO | `sqlplus` 12.2 existe; `TNS_ADMIN` com alias `orcl`; sem `QA_ORA_*` | credencial segura ou evidência manual |
| Build/branch | BLOQUEADO | branch remota `bugfix/US161714-correcao-log-erro-descricao` existe no commit esperado; working tree em outra branch | checkout, build e implantação da branch |
| Serviços | BLOQUEADO | sem Scheduler ou Worker BPM em execução | subir após o build |
| Schema (SQL Server) | OK | `JOB_BPM`, `JOB_DUMP`, `JOB_CONFIG` existem | nenhum |
| JOB_CONFIG do AvancoTemporal (job 8, módulo 1) | OK | `Ativo = 1`, `Max_Tentativas = 5`, `Interval_Ms = 60000` | nenhum |
| Massa: fluxo com passo temporal elegível | EXISTENTE (a confirmar) | processos com `PASSO_TEMPO`: 4, 5, 6 (5 fluxos), 9, 10, 1011 | confirmar um fluxo com tarefa elegível ao AvancoTemporal |
| Mecanismo para forçar erro no AvancoTemporal | AUSENTE | não descrito | dev informar |
| Local do log do Worker | PENDENTE | log do Worker BPM em `logs-bpm` (visto na etapa 05); caminho da rodada a confirmar | confirmar |
| Exemplo do log antes e depois | AUSENTE | não está no bug nem no PR | dev informar |

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
- **Específico #161714:** sem mecanismo para forçar erro no AvancoTemporal e sem exemplo do log; processo 6 tem 5 fluxos (confirmar tarefa elegível).

## Gate final — SQL Server (09/11)
**Status: LIBERADO PARA EXECUÇÃO (SQL Server)**, cenários 1 a 5 do mapa 24, com a ressalva do exemplo do log.
- Build: worktree `Temp/wt30486` (`3ac5ea98`), Worker BPM e Scheduler compilados, conexão SQL Server.
- Massa: fluxo 900750 (processo 9 v3), tarefa 2 no passo 4 com `dt_prazo` 11:37:35 vencido. **Confirmado por leitura:** a consulta `GetAvancoTemporalPrazo` do repositório devolve (fluxo 900750, tarefa 2, passo 17), então o Scheduler enfileira o job 8.
- Mecanismo de falha (procedimento): com o Worker parado, o Scheduler enfileira o job 8; concluir ou cancelar o fluxo 900750 pela tela; subir o Worker do PR. **Será provado na execução.**
- Ressalva: sem exemplo do log antes e depois; os cenários verificam só que a exceção original aparece.
Assinatura de contexto: ambiente local SQL Server ShareGuizao (NOTE-74VQ\SQLEXPRESS), RUN_ID 20261109-161711, mapas locais 21 a 25 (aprovados só local em 09/11), parâmetro 96 = 0, manifesto massa/MANIFESTO-massa.md. Expira se o build, o banco, o mapa ou a massa mudarem.
