# Ciclo de QA — Task 161496 / US 160818

- **Task:** [160818] - Testes Rotina - Calculo Indicador (card de teste #161496; card do mapa #161491)
- **História:** [#160818](https://dev.azure.com/selbettidev/_workitems/edit/160818) — Rotina - Calculo Indicador
- **Projeto:** SmartShare Arquitetura | **Sprint:** 4 | **Tipo:** migração de rotina (Agent clássico para Agent net8)
- **QA:** guilherme.borges

## Etapas

| # | Etapa | Data | Status | Escreveu no Azure DevOps? | Arquivo |
|---|---|---|---|---|---|
| 00 | validar-ambiente | 2026-11-11 | Concluída (liberado, escopo ajustado) | Não | `00-validacao-ambiente.md` |
| 01 | execucao-testes (Oracle) | 2026-11-11 | Parcial — SQL Server em outra sessão; CT-001 passou na API, CT-003 parcial, CT-029 a esclarecer | Sim (anexo no #161496) | `01-execucao-testes.md` |
| 02 | plano-falha-controlada | 2026-11-11 | Executado e revertido (CT-026/027/028/031) | Não | `02-plano-falha-controlada.md` |
| 03 | analise-falha | 2026-11-11 | Concluída: 4 achados, nenhum com evidência para defeito (1 INCONCLUSIVO, 3 NÃO) | Não | `03-analise-falha.md` |
| 04 | execucao-testes (SQL Server) | 2026-11-11 e 2026-11-12 | Parcial — CT-004 a 017, 021 a 023, 026 a 028 e 031 passaram; CT-011 (soma), CT-016 e CT-017 destravados em 12/11 com o processo 1039 criado pela tela; HIPOTESE do mapa não executados | Sim (anexo `relatorio-execucao-sqlserver-US160818.md` no #161496, 12/11) | `04-execucao-testes-sqlserver.md` |

Evidências brutas: `evidencias/` (arquivos `sql-*.txt` são da rodada SQL Server).

## Artefatos criados no Azure DevOps

| Artefato | Onde | Etapa |
|---|---|---|
| Anexo `relatorio-execucao-oracle-US160818.md` | Card de teste #161496 | 01 |
| Anexo `relatorio-execucao-sqlserver-US160818.md` | Card de teste #161496 | 04 |

## Aprendizados consultados ou registrados

| ID | Status | Relação com a etapa | Ação |
|---|---|---|---|
| QA-KB-20261106-001 | validado | troca de banco local (SQL Server para Oracle) | consultado |
| QA-KB-20261111-001 | validado | feriado usa ano 1904 | registrado |
| QA-KB-20261111-002 | validado | excluir fluxos de teste pela tela | registrado |
| QA-KB-20261111-003 | validado | falha controlada com trigger e retry do job | registrado |
| QA-KB-20261111-004 | validado | binário net8 desatualizado | registrado |
| QA-KB-20261112-001 | validado | Worker BPM lê JOB_CONFIG na partida; JOB_BPM pendente; processo com SubProcesso pela tela | registrado |

## Pendências

- CT-001: listagem confirmada na API (`GET /api/JobConfig`); falta abrir a tela `job-config` do `smartshare-analytics` (login Share 4) e a decisão do PM-05 sobre o que a tela permite.
- RF-05: aguardar PM-02/PM-03 sobre onde e como armazenar o tempo de execução.
- Lado SQL Server: rodada feita em 11/11 e complementada em 12/11 (CT-011 soma, CT-016, CT-017 com o processo 1039). Pendências dessa rodada: cancelar o fluxo 900812 (aberto) por "Minhas Solicitações", decidir se Share e net8 voltam ao Oracle, e a decisão do PM-08 (muda o esperado de CT-016 e CT-017).
- Dev: confirmar se o retry do ciclo inteiro por erro de um item é intencional; RF-05 (duração do processo não registrada como valor); CT-001 (tela de configuração a identificar).
- Cenários `HIPOTESE:` do mapa não executados (CT-002, 018, 019, 020, 024, 025, 030): decisão do PM/dev.
- Segurança: rotacionar as senhas que apareceram na saída da sessão (root de teste, SQL Server, Oracle, `qa.usuario2`, `qa.usuario3`).
