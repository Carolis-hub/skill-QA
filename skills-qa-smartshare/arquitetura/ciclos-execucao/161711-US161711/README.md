# Ciclo de QA — Task 161711 / US 161711

- **Task:** [161711] - Testes dos bugs dos instaladores
- **História:** [#161711](https://dev.azure.com/selbettidev/SmartShare%20Arquitetura/_workitems/edit/161711) — Bugs Instaladores
- **Projeto:** SmartShare Arquitetura | **Sprint:** Sprint 4 | **Tipo:** Product Backlog Item
- **QA:** guilherme.borges@selbetti.com.br

## Etapas

| # | Etapa | Data | Status | Escreveu no Azure DevOps? | Arquivo |
|---|---|---|---|---|---|
| 01 | analise-negocio | 2026-11-06 | Concluída — 14 filhos lidos; 5 bugs com correção em PR (#161716, #161713, #161712, #161714, #161839), #161715 sem implementação, #161717 fechado sem correção; prontidão: técnica COM RESSALVAS, mapa BLOQUEADA, execução BLOQUEADA | Não | [01-analise-negocio.md](01-analise-negocio.md) |
| 02 | analise-tecnica | 2026-11-06 | Bloqueada — sem card `Análise`; inventário de 6 PRs (todos Active) registrado como informativo | Não | [02-analise-tecnica.md](02-analise-tecnica.md) |

| 03 | analise-tecnica | 2026-11-06 | Concluída com exceção autorizada pelo QA (sem card `Análise`; fonte = bugs + diffs dos 6 PRs). Achados: PRs 30060 e 30457 conflitam (`ExecutaSqlSchedulerHandler`, `BpmSchedulerJob`); dois `ExisteJobAtivo` distintos (30104 e 30457); InicioFluxoRevisao, InicioDesassociarAutomatico e NotificaInicioComPublicacao são `// TODO` na `main`; build implantado NÃO VALIDADO | Não | [03-analise-tecnica.md](03-analise-tecnica.md) |

| 04 | mapa-testes | 2026-11-06 | Concluída (uso local) — 41 cenários, 9 categorias, 3 hipóteses (#30, #40, #41); **não publicado no Azure DevOps por decisão do QA**; execução bloqueada até haver build e mecanismos de falha | Não | [04-mapa-testes.md](04-mapa-testes.md) |

| 05 | execucao-testes (PR 30253 / #161839, Oracle) | 2026-11-06 | **Parcial** — #16 e 36a (cadeia longa, fluxo 2082) PASSOU COM RESSALVA (destinatário correto por SQL e log do Worker, aceito pelo QA; e-mail não chegou: `MailerException` Graph `Content-Type`); #26 INCONCLUSIVO (só a consulta); #17, #18, #19, #25, #27, #36 não executados. **UPDATE ativo a reverter:** processo 522 v1 passo 6, `ID_PERMISSAO_OBSERVACAO` 4 → 0 | Não | [05-execucao-testes.md](05-execucao-testes.md) |

| 06 a 12 | analise-negocio por bug (09/11) | 2026-11-09 | Concluída — uma análise por bug, reaproveitando a etapa 01 (PBI rev 20 e bugs sem mudança desde 06/11). #161712 [06], #161713 [07], #161714 [08], #161715 [09], #161716 [10], #161717 [11], #161839 [12]. Prontidão para execução: #161839 APTA COM RESSALVAS; #161712, #161713, #161714 e #161716 BLOQUEADA até haver build com o PR; #161715 e #161717 BLOQUEADA (sem implementação). Vínculo novo: #161715 relacionado ao PBI #165944 (New) | Não | [06](06-analise-negocio-bug-161712.md), [07](07-analise-negocio-bug-161713.md), [08](08-analise-negocio-bug-161714.md), [09](09-analise-negocio-bug-161715.md), [10](10-analise-negocio-bug-161716.md), [11](11-analise-negocio-bug-161717.md), [12](12-analise-negocio-bug-161839.md) |

| 13 | analise-tecnica (09/11) | 2026-11-09 | Bloqueada — sem card `Análise` no PBI; exceção da etapa 03 (06/11) não renovada nesta rodada | Não | [13-analise-tecnica.md](13-analise-tecnica.md) |

| 14 a 20 | analise-tecnica por bug (09/11) | 2026-11-09 | Concluída por exceção autorizada pelo QA em 09/11 (sem card `Análise`; fonte = bugs + diffs da etapa 03, PRs relidos só nos metadados). #161712 [14], #161713 [15], #161714 [16], #161715 [17, bloqueada, sem PR], #161716 [18], #161717 [19, bloqueada, sem alteração], #161839 [20]. Os 6 PRs seguem Active, commits iguais aos de 06/11, e **todos NÃO VALIDADO no ambiente**. PR 29631 (origem do `ExisteJobAtivo`) também Active. Conflito 30060 × 30457 mantido | Não | [14](14-analise-tecnica-bug-161712.md), [15](15-analise-tecnica-bug-161713.md), [16](16-analise-tecnica-bug-161714.md), [17](17-analise-tecnica-bug-161715.md), [18](18-analise-tecnica-bug-161716.md), [19](19-analise-tecnica-bug-161717.md), [20](20-analise-tecnica-bug-161839.md) |

| 21 a 25 | mapa-testes por bug (09/11) | 2026-11-09 | Concluída (uso local) — 5 mapas, 47 cenários, execução em branch isolada por PR (sem conflito 30060 × 30457 em execução). #161716 [21] 9 cenários, #161713 [22] 10, #161712 [23] 12, #161714 [24] 5, #161839 [25] 11. Hipóteses: #5 do 21, #10 do 22 e #10 do 23. **Não publicado no Azure DevOps** (decisão do QA da etapa 04, mantida); aprovação da tabela pendente. #161715 e #161717 sem mapa (sem implementação; o regressão do #161717 está no cenário 12 do mapa 23) | Não | [21](21-mapa-testes-bug-161716.md), [22](22-mapa-testes-bug-161713.md), [23](23-mapa-testes-bug-161712.md), [24](24-mapa-testes-bug-161714.md), [25](25-mapa-testes-bug-161839.md) |

| 00 | validacao-ambiente por bug (09/11) | 2026-11-09 | **BLOQUEADO nos 5 bugs.** SQL Server acessível por `sqlcmd` (leitura); Oracle pausado (sem credencial segura). Builds das branches não implantados (clones em `feature/US160823…`), sem Scheduler ou Worker rodando; massas e `JOB_CONFIG` pendentes (jobs 19, 22 e 28 inativos; job 20 sem linha; processos 481, 501 e 522 só no Oracle). Nenhuma escrita no banco | Não | [00-validacao-ambiente.md](00-validacao-ambiente.md) e `00-validacao-ambiente-bug-<id>.md` |

| 00b | preparacao-ambiente SQL Server (09/11) | 2026-11-09 | Parcial — 4 worktrees (`Temp/wt30104`, `wt30060`, `wt30457`, `wt30486`) e `wt30253` com Worker BPM e Scheduler compilados (0 erros) e conexão SQL Server; escritas autorizadas aplicadas (job 20, opção 4 no 1019 v3, baseline do job 28). Gate segue BLOQUEADO: Scheduler e Worker não iniciados, mock HTTP, falha com escape do #161713 (UPDATE do processo 5 v2 aguarda autorização), Agent clássico, Oracle | Não | [massa/MANIFESTO-massa.md](massa/MANIFESTO-massa.md) |

| 00c | validacao-ambiente ORACLE (09/11) | 2026-11-09 | **LIBERADO COM RESSALVA (QA aceitou em 09/11).** Massas criadas e lidas: 103 tarefas WS (processo 501, mock em `localhost:44303` via `WS_CONSULTA` 2), processos 561 e 581 (SQL, 581 com escape tipo 13), fluxo temporal 2385 elegível, job 20, parâmetro 96 = 0. Ressalva aceita: a conexão 1 é SQL Server de exemplo, então o passo SQL falha por conexão e os cenários que exigem a mensagem do SQL inválido ficam INCONCLUSIVO. IIS Express reiniciado após travamento do formulário do processo 442. Serviços e mock sobem na execução | Não | [00-validacao-ambiente-oracle.md](00-validacao-ambiente-oracle.md), [massa/MANIFESTO-massa.md](massa/MANIFESTO-massa.md) |

| 26 a 30 | execucao-testes por bug, ORACLE (09/11) | 2026-11-09 | **Concluída com pendências.** #161716 [26]: 1, 2, 4, 6 e 9 passaram (1, 2 e 6 com ressalva), 3 parcial, 5 e 7 não executados, 8 inconclusivo; 0 duplicados em 103 pendências. #161713 [27]: 3, 4 e 5 passaram; 1, 2 e 7 com ressalva; 6 e 10 não executados; 8 e 9 inconclusivos; observação ORA-01407 (processo sem título de fluxo no Oracle). #161712 [28]: 5 e 9 passaram; 1, 3 e 6 com ressalva; 2, 4, 7, 8, 11 e 12 inconclusivos; 10 não executado; 0 repetidas em 10 ciclos. #161714 [29]: 4 e 5 passaram, 1 a 3 não executados (hipótese). #161839 [30]: 1, 3, 5 e 10 (opção 3) passaram com ressalva; 2, 6 e 11 fora (clássico); 4, 7, 8 e 9 inconclusivos. Ambiente restaurado (`JOB_CONFIG` 13 jobs ativos; 522 v1 passo 6 observação 0). Consolidado em [31](31-execucao-testes-oracle-consolidado.md) | Não | [26](26-execucao-testes-161716-oracle.md), [27](27-execucao-testes-161713-oracle.md), [28](28-execucao-testes-161712-oracle.md), [29](29-execucao-testes-161714-oracle.md), [30](30-execucao-testes-161839-oracle.md) |

## Artefatos criados no Azure DevOps

| Artefato | Onde | Etapa |
|---|---|---|
| Nenhum (mapa mantido só no ciclo local; sem card "Criar Mapa de Teste" e sem comentário de hipóteses) | — | 04 |

## Aprendizados consultados ou registrados

| ID | Status | Relação com a etapa | Ação |
|---|---|---|---|
| — | — | Nenhum aprendizado aplicável | Consulta realizada; nenhum registro novo |

## Pendências

- ~~Card `Análise` ausente~~ — QA autorizou em 06/11 usar bugs e diffs como fonte (etapa 03). Card continua ausente no Azure DevOps.
- Os 6 PRs (30060, 30104, 30253, 30254, 30457, 30486) estão Active e **30060 × 30457 conflitam**: dev precisa resolver, ou o QA define o build de teste (PRs isolados ou integração).
- Dev: informar valores de `JOB_CONFIG` (`MaxTentativas`, `PoliticaBackoff`) e como forçar falha de SQL (#161713) e erro de AvancoTemporal (#161714); confirmar a assinatura de `ExisteJobAtivo` da PR 29631.
- Hipóteses do mapa (#30, #40, #41) não foram comunicadas ao dev/PO no Azure DevOps (publicação dispensada pelo QA).
- #161712: InicioFluxoRevisao, InicioDesassociarAutomatico e NotificaInicioComPublicacao são `// TODO` na `main` — fora do teste neste build.
- Decidir se #161715 (New, sem PR) e #161717 (fechado sem reprodução) entram no teste.
- Obter do dev o exemplo antes/depois do log do #161714.
- Cards de Teste #165195, #165205, #165559, #165998 e #166111 estão New e sem responsável.
- (09/11) PBI #165944 (NotifyWF: job por pendência e poisoning nas 5 notificações) está New, ligado ao #161715: decidir se o teste de notificação migra para ele.
- (09/11) Texto completo do #161715 lido só até o trecho de Observação; ler o restante quando o #165944 entrar em teste.
- (09/11) Estado dos 6 PRs e do 29631 reverificado: todos `Active`, mesmos commits de 06/11. Nenhum mesclado.
- (09/11) Bloqueantes de execução por bug: #161713 (valores de `JOB_CONFIG` e forma de forçar falha de SQL), #161714 (forma de forçar erro no AvancoTemporal e exemplo do log), #161716 (mock HTTP, massa de 101 fluxos, limite do Scheduler), #161712 (resultado esperado por job), #161839 clássico (Agent com o PR 30254).
- (09/11) Conflito 30060 × 30457 e dois `ExisteJobAtivo` distintos (30104 e 30457): QA definiu testar cada bug na sua branch isolada. Fica como risco residual a integração dos PRs (regressão pós-merge).
- (09/11) Mapas 21 a 25 **aprovados pelo QA em 09/11, só uso local (não publicar no Azure DevOps)**. Hipóteses (#5 do mapa 21, #10 do 22 e #10 do 23) não notificadas ao dev e PO.
