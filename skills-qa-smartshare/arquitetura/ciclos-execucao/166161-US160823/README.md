# Ciclo de QA — Task 166161 / US 160823

- **Task:** [166161] - Teste correção de bug
- **História:** [#160823](https://dev.azure.com/selbettidev/SmartShare%20Arquitetura/_workitems/edit/160823) — Rotina - Inicio Desassociar Automático
- **Bug retestado:** [#166161](https://dev.azure.com/selbettidev/SmartShare%20Arquitetura/_workitems/edit/166161) (`Done`, fix no commit `6b23a794`)
- **Projeto:** SmartShare Arquitetura | **Sprint:** Sprint 4 | **Tipo:** Product Backlog Item
- **QA:** guilherme.borges@selbetti.com.br
- Ciclo anterior desta história: `../161495-US160823`

## Etapas

| # | Etapa | Data | Status | Escreveu no Azure DevOps? | Arquivo |
|---|---|---|---|---|---|
| 00 | validacao-ambiente | 2026-11-10 | SQL Server e Oracle liberados com autorizações; Workers e jobs residuais tratados | Não | [00-validacao-ambiente.md](00-validacao-ambiente.md) |
| 01 | reteste-bug-166161-parcial-sqlserver | 2026-11-10 | Notas parciais da fase SQL Server (substituídas pela etapa 02) | Não | [01-reteste-bug-166161-parcial-sqlserver.md](01-reteste-bug-166161-parcial-sqlserver.md) |
| 02 | reteste-bug-166161 | 2026-11-10 | **Parcial**: #22 (nulo e vazio), #1, #2 passaram nos dois bancos; #23 passou no SQL Server (Oracle inconclusivo); #17 passou (SQL) e com ressalva (Oracle); #25 e #26 com ressalva; #24 e #27 não executados | Não | [02-reteste-bug-166161.md](02-reteste-bug-166161.md) |

## Artefatos criados no Azure DevOps

Nenhum. Aguardam aprovação do QA: comentário `Reteste (Modo B)` no Bug #166161 e anexo do relatório ao card Teste.

## Aprendizados consultados ou registrados

| ID | Status | Relação com a etapa | Ação |
|---|---|---|---|
| QA-KB-20261106-001 | validado | troca de banco SQL Server para Oracle | usado; direção SQL para Oracle repetida por `webconfig.aspx` em 10/11 |
| QA-KB-20261105-001 | candidato | NullReferenceException com coluna anulável | usado; fix confirmado no #22 |

## Pendências

- #24 e #27 não executados: exigem subir o Agent clássico (parado; instalado de 23/10, sem PR 29228). Aguarda OK do QA.
- #23 no Oracle sem mecanismo de falha limpa (lock sem timeout). Aguarda indicação do dev.
- Ressalvas: #17 no Oracle (sem valor "antes"), #25 (motor clássico), #26 (jobs 9, 18, 19 e 32 desativados no Oracle durante a rodada).
- Ambiente local ficou apontado para Oracle. Backups do estado SQL Server no scratchpad da sessão.
- Bug #166161: comentário `Reteste (Modo B)` e anexo do relatório ao card Teste pendentes de aprovação.
