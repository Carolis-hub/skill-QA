# Ciclo de QA — Task 161495 / US 160823

- **Task:** [161495] - Testes da US 160823 (Validação das skills da arquitetura)
- **História:** [#160823](https://dev.azure.com/selbettidev/SmartShare%20Arquitetura/_workitems/edit/160823) — Rotina - Inicio Desassociar Automático
- **Projeto:** SmartShare Arquitetura | **Sprint:** Sprint 4 | **Tipo:** Product Backlog Item
- **QA:** guilherme.borges@selbetti.com.br

## Etapas

| # | Etapa | Data | Status | Escreveu no Azure DevOps? | Arquivo |
|---|---|---|---|---|---|
| 01 | analise-negocio | 2026-11-04 | Concluída | Não | [01-analise-negocio.md](01-analise-negocio.md) |
| 02 | analise-tecnica | 2026-11-04 | Parcial — build implantado não validado; mudança em `DesassociaTarefa.cs` (clássico) sem descrição no card | Não | [02-analise-tecnica.md](02-analise-tecnica.md) |
| 03 | mapa-testes | 2026-11-04 | Concluída — 30 cenários; #21 e #22 bloqueados | Sim | [03-mapa-testes.md](03-mapa-testes.md) |
| 04 | execucao-testes | 2026-11-04/05 | **Parcial** — Oracle (atualizado em 06/11 com o build novo): 18 passou, 7 com ressalva, **1 falhou (#22: NullReferenceException com valor inicial nulo)**, 0 inconclusivo. **SQL Server (05/11 e 06/11): 19 passou, 6 com ressalva (inclui #27), 1 falhou (#22 com valor nulo, igual ao Oracle); #24 passou com o build do PR 29228 em 06/11** (#20, #22 e #23 incluídos). #24, #27 e metade clássica do #11 executados em SQL Server (ressalva: build instalado do clássico sem o fix do PR 29228); 4 hipóteses não executadas. Relatório não anexado ao card Teste. | Não | [04-execucao-testes.md](04-execucao-testes.md) |
| 05 | analise-falha | 2026-11-05 | Concluida: #22 Oracle, veredito SIM (NullReferenceException com ds_valor_inicial nulo em FluxoService.cs:7742; o classico nao falha); defeito nao criado, aguarda aprovacao | Nao | [05-analise-falha.md](05-analise-falha.md) |
| 06 | defeito-166161 | 2026-11-05 | Concluida: Bug #166161 criado (cenario #22), filho da US 160823, com screenshot do log do Worker anexado | Sim | [06-defeito-166161.md](06-defeito-166161.md) |

## Artefatos criados no Azure DevOps

| Artefato | Onde | Etapa |
|---|---|---|
| Mapa de testes (descrição substituída) | Card [#161490](https://dev.azure.com/selbettidev/SmartShare%20Arquitetura/_workitems/edit/161490) | 03 |
| Comentário com 4 hipóteses | História #160823 (rev 7) | 03 |
| Bug [#166161](https://dev.azure.com/selbettidev/SmartShare%20Arquitetura/_workitems/edit/166161) (NullReferenceException, cenário #22), filho da #160823, com anexo | Azure DevOps | 06 |

## Aprendizados consultados ou registrados

| ID | Status | Relação com a etapa | Ação |
|---|---|---|---|
| — | — | Nenhum aprendizado aplicável | Consulta realizada; base vazia |

## Pendências

- Critérios de aceite estão no card Análise #161471 (descrição e CasodeTeste); a história #160823 segue sem AC próprio.
- ~~O que mudou em `DesassociaTarefa.cs`~~ — resolvido na etapa 04: o diff mostra só a inclusão de `AND PU.cd_passo = T.cd_passo` no JOIN e a remoção de dois `using`.
- Confirmar se os PRs 29228 e 29340 foram concluídos (API retornou `status=1`). O build testado é o do clone local no commit `ae01cc40`.
- Dev: Oracle sem timeout de comando (lote parou 88 s com linha bloqueada e travou com valor inicial nulo); SQL Server aborta em 30 s e segue. Avaliar `CommandTimeout` no Oracle.
- SQL Server: parâmetro 96 (nova API do Engine) estava 1 e foi para 0; `JOB_CONFIG` Id 12 `Ativo` ficou 1 (era 0); `JOB_CONFIG_PADRAO` Id 12 está com `Ativo=1` (script manda 0).
- Agent clássico instalado (23/10) não contém o fix do PR 29228. Com o build do PR (06/11) o #24 passou em SQL. Dev: a branch do PR parte de base mais antiga (VersaoAgent 3.84.4 contra 3.88.0 da master); integrar a master. Repetir #24/#27 em Oracle.
- Usuário de teste `qa.usuario2` registrado em `Variveis de Ambiente`, seção 4.1.
- Dev: valor `[ds_usuario_corrente]` no início do fluxo vem do papel 1 (motor clássico) e, após a desassociação, do papel executor real (net8) — confirmar o esperado.
- Dev: o Scheduler loga "inserido com sucesso" a cada 10 s para a mesma chave enquanto o Worker não roda (o `JOB_BPM` mantém 1 linha). Confirmar se é o desejado.
- Aguardar confirmação de dev/PO para as hipóteses #15, #28, #29, #30 (não executadas por decisão do usuário).
- Bug #166161 criado para o #22; time define severidade final e correcao. Frequencia real do valor nulo pela tela ainda nao confirmada.
- 06/11: rodada SQL com o build novo do net8 (#16, #21, #22 isolamento, #23 passaram; #21 com ressalva: sem PID no log). #4 front não executado (precisa proxy mesma-origem). Double-check Sonnet feito. Teste na tela: o campo tipo 5 salvo sem valor grava [ds_usuario_solicitante], não NULL; origem de NULL real em produção não confirmada (comentário do Bug corrigido). Pendente só no Oracle: #24/#27, #20 entre bancos, #22 e #23 com o build novo.
- **Relatório final anexado ao card #160823 em 06/11/2026** (`relatorio-final-161495-US160823.md`, 7875 bytes, confirmado por leitura). Não foi anexado ao card Teste.
- **Retomar quando o Bug #166161 for corrigido** (combinado com o usuário): recompilar o net8 e reexecutar o #22 com valor nulo e vazio em Oracle e SQL Server; regressão #1, #2, #16, #17, #21 e #23 nos dois bancos; complementar #4 (front), #5 e #25 no Oracle e `AvancarFluxo` pela API. Passo a passo da troca de banco: `aprendizados/entradas/QA-KB-20261106-001.md`.
