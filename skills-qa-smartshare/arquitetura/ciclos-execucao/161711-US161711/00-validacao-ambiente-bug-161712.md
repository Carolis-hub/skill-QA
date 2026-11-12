# Validação de ambiente — Bug #161712 (US #161711 Bugs Instaladores / Mapa local 23-mapa-testes-bug-161712.md)

**Status do gate:** BLOQUEADO
**Ambiente:** local (máquina do QA), não produtivo. Share clássico em IIS Express; net8 (API, Scheduler, Worker BPM) com `DBType = SQLServer` nos 3 `appsettings.json` (lido sem segredos)
**Banco(s):** SQL Server 2019 acessível (banco `ShareGuizao`, `sqlcmd` com autenticação do Windows, só leitura). Oracle: **PAUSADO** (sem credencial segura para `sqlplus`; pacote manual em `sql/00-validar-ambiente-oracle.sql`)
**Build/commit esperado:** `9816142b` (PR 30457, branch `bugfix/os161712-scheduler-duplicate-job-insert`)
**Build/commit encontrado:** clones `smartshare-net8` e `SmartShare` na branch `feature/US160823-migracao-job-inicio-desassociar-automatico`, com `appsettings.json` e `Web.config` modificados localmente. Nenhum Scheduler ou Worker em execução.
**RUN_ID:** 20261109-161711-161712
**Validade:** mapa local `23-mapa-testes-bug-161712.md` (etapas 21 a 25, aprovado só local em 09/11), ambiente local, SQL Server `ShareGuizao`. Expira se o build, o banco ou o mapa mudarem.

> Desvio registrado: a skill exige o card "Criar Mapa de Teste" no Azure DevOps; o QA aprovou os mapas só locais (etapa 04 e 09/11). O mapa local foi usado como fonte.

## Resumo
| Dimensão | Status | Evidência | Pendência |
|---|---|---|---|
| Mapa | OK (local) | arquivo `23-mapa-testes-bug-161712.md` | nenhum |
| Acesso SQL Server | OK | `sqlcmd -E` leu `DB_NAME`, usuário e versão (SQL Server 2019) | nenhum |
| Acesso Oracle | PAUSADO | `sqlplus` 12.2 existe; `TNS_ADMIN` com alias `orcl`; sem `QA_ORA_*` | credencial segura ou evidência manual |
| Build/branch | BLOQUEADO | branch remota `bugfix/os161712-scheduler-duplicate-job-insert` existe no commit esperado; working tree em outra branch | checkout, build e implantação da branch |
| Serviços | BLOQUEADO | sem Scheduler ou Worker BPM em execução | subir após o build |
| Schema (SQL Server) | OK | `JOB_BPM.Chave_Concorrencia` existe (usada pelo `ExisteJobAtivo` do PR) | nenhum |
| JOB_CONFIG dos jobs do bug | PENDENTE | job 8 AvancoTemporal ativo; 9 NotifyWf ativo; 18 ExcluiFluxo ativo; 32 EnviaAlertaFluxo ativo; 7 InicioTemporal ativo com `TimeZone_Id = NULL`; **22 InicioPublicacao `Ativo = 0`**; **ExecutaSql (19) `Ativo = 0`**; **ExecutaPassoAplicacao (job 20) sem linha em `JOB_CONFIG`** | ativar ou criar linhas exige `UPDATE` ou `INSERT` autorizados |
| TimeZone (cenário 8) | PENDENTE | maioria `America/Sao_Paulo`; precisa de um fuso diferente do servidor | decidir o valor de teste |
| Massa por job | EXISTENTE (a confirmar por cenário) | AvancoTemporal: processos 6 (5 fluxos), 9, 10, 1011; InicioTemporal: 1010 (69 fluxos), 1012, 1013, 1015, 1016; EnviaAlertaFluxo: 1018 (9 fluxos); ExcluiFluxoEmSolicitacao: 1024 (0 fluxos); NotifyWF: 1019 (5 fluxos); ExecutaPassoAplicacao: passos de aplicação nos processos 1, 2, 4, 5, 10 | confirmar versão publicada e estado dos fluxos de cada um; 1024 e 9 sem fluxo |
| E-mail (cenário 12) | PENDENTE | falha conhecida do Graph (`Content-Type`); QA aceita log do Worker | nenhum, se mantida a decisão |

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
- **Específico #161712:** job 20 inserido (Id 35). Falta ativar os jobs 22 e 19 na execução e confirmar a massa por cenário (processos listados acima; 1024 sem fluxo).

## Gate final — SQL Server (09/11)
**Status: BLOQUEADO (parcial)** por massa dos cenários 4, 5, 6 e 9 não confirmada por leitura.
- OK: build (`wt30457`, `9816142b`); job 20 inserido (Id 35); jobs 7, 8, 9, 18, 32 ativos; jobs 19 e 22 a ativar na execução; AvancoTemporal com o fluxo 900750.
- Não confirmado: InicioPublicacao (documento a publicar), NotifyScheduler (5 tipos de pendência), ExcluiFluxoEmSolicitacao (processo 1024 sem fluxo), ExecutaPassoAplicacao (fluxo com passo de aplicação), resultado esperado por job. Parte nasce de passos do cenário.
- Decisão do QA necessária: aceitar a massa criada nos passos do cenário, ou eu confirmar cada uma antes por leitura.
Assinatura de contexto: ambiente local SQL Server ShareGuizao (NOTE-74VQ\SQLEXPRESS), RUN_ID 20261109-161711, mapas locais 21 a 25 (aprovados só local em 09/11), parâmetro 96 = 0, manifesto massa/MANIFESTO-massa.md. Expira se o build, o banco, o mapa ou a massa mudarem.

## Decisão do QA (09/11) — gate atualizado
O QA aceitou que a massa de InicioPublicacao, NotifyScheduler, ExcluiFluxoEmSolicitacao e ExecutaPassoAplicacao seja criada nos passos do cenário, sem confirmação prévia por leitura.
**Status: LIBERADO PARA EXECUÇÃO (SQL Server)**, cenários 1 a 9, 11 e 12 do mapa 23; o cenário 10 é hipótese (não executa automaticamente). Condição aceita: se a massa de um cenário não puder ser criada na execução, o cenário fica **bloqueado** (não reprovado) e vai para o relatório.
