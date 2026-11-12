# Validação de ambiente — US #160818 / Mapa #161491

**Status do gate:** LIBERADO PARA EXECUÇÃO — ESCOPO AJUSTADO (decisão do usuário em 2026-11-11, ver "Atualização 8"). Fora do escopo liberado: CT-016 (Oracle), CT-019 e os cenários `HIPOTESE:` (execução automática restrita pelo mapa). CT-026/027/028/031 só rodam depois de definir o artifício de falha, com pausa e autorização de escrita específica no momento.
**Ambiente:** local não produtivo — banco pessoal de QA (SQL Server `NOTE-74VQ\SQLEXPRESS` / `ShareGuizao`; Oracle schema `SHAREGUIZAO`, serviço `SSHARE`)
**Banco(s):** ambos (Oracle + SQL Server) — o mapa exige os dois (CT-003, CT-032)
**Build/commit:** branch `feature/US160818-migracao-job-calculo-indicador`, HEAD `532fea37` (2026-11-05). Build dos Workers em execução **não confirmado** (sem `ExecutablePath`; sem como ligar o processo ao commit).
**RUN_ID:** 20261111-US160818-V01
**Validade do relatório:** mapa #161491, ChangedDate `2026-10-21T13:52:33.103Z`, ambiente local-nao-produtivo, banco/schema ShareGuizao + SHAREGUIZAO. Nenhuma massa foi criada nesta execução; nenhuma escrita em banco.

## Resumo
| Dimensão | Status | Evidência | Pendência |
|---|---|---|---|
| MCP Azure DevOps | OK | leitura de #160818, #161491, #161472 e filhos | — |
| Acesso SQL Server | OK (ADAPTER_LOCAL `sqlcmd`, read-only) | probe 2026-11-11: banco `ShareGuizao`, versão 15.0.2000.5, login Windows. MCP `mssql` tentado e falhou (`NOTE-74VQ:1433` sem conexão) | — |
| Acesso Oracle | OK (ADAPTER_LOCAL `sqlplus`, read-only) | probe 2026-11-11: schema `SHAREGUIZAO`, DB `SSHARE`, Oracle 19c SE2. Sem MCP Oracle na sessão | — |
| Ambiente/build | PENDENTE | Share web `http://localhost:58149/SmartShare/` **inacessível**; Workers net8 e `SmartShareAgent` clássico rodando desde 08:09, mas build/commit não comprovado | Subir o Share; comprovar que os Workers rodam o build com os PRs #29630/#29631 |
| Serviços/configuração | PENDENTE | net8 (API, Scheduler, Worker BPM) apontam para **Oracle**; SQL Server só validável por banco, não por execução net8 | Troca de banco documentada em QA-KB-20261106-001 antes de rodar no SQL Server |
| Massas | BLOQUEADO | ver matriz | feriados, calendário [CAL_QA], [PROC_SEMCAL], histórico sem término, [PROC_PAR]/[PROC_SUB] no Oracle |

## Achados de configuração
- Rotina = `EJobBpm.CalculoIndicador = 16` (`Project.Core.Infraestructure/Enums/EJobBpm.cs`). "Chave de ativação" ([CHAVE_ATIVACAO_ROTINA], DEV-01) = `JOB_CONFIG` Id 9 (Modulo 1, Job 16), coluna `Ativo`; intervalo = `Interval_Ms` (`[INTERVALO_JOB]`). Origem: código + banco; DEV-01/DEV-05 seguem sem resposta formal no mapa.
- SQL Server: `JOB_CONFIG` Id 9 `Ativo=0`, `Interval_Ms=600000`. `JOB_CONFIG_PADRAO` Id 9 `Ativo=1`.
- Oracle: `JOB_CONFIG` Id 9 `Ativo=1`, `Interval_Ms=60000`. Clássico e net8 podem estar calculando ao mesmo tempo; os dois Workers estão em execução. `TAREFA_INDICADOR`=0 e `FLUXO_INDICADOR`=0 no Oracle apesar de 832 tarefas e do job ativo: **o net8 nunca calculou aqui** (ou o build rodando não tem o job).
- [LOG_DIR_AGENT_NET8]: NLog `logDir = NLOG_LOGROOT` (ou `LogsRoot`), arquivo `<logDir>/<Modulo>/<Job>/yyyyMMdd_<Job>.log`. Valor efetivo da máquina **não confirmado**.
- [MECANISMO_DISPARO] (CT-021), [MECANISMO_FALHA] (CT-026/028): sem resposta no mapa; lock é via `JOB_BPM`/`Lock_Expira_Em` (análise #161472). `JOB_BPM` com Job 16: 0 linhas nos dois bancos.

## Matriz de massas
Cenários CT-001 a CT-032. Resumo por requisito de massa (a mesma massa vale para vários cenários).

| Cenário(s) | Banco | Requisito de massa | Verificação | Resultado | IDs/quantidade | Evidência |
|---|---|---|---|---|---|---|
| CT-007, 008, 009, 010, 011, 012, 013, 014, 015, 016, 017, 019, 020 | SQL Server | [CAL_QA]: 1 período seg–sex 08:00–18:00 | `CALENDARIO`/`PERIODO` | INCOMPATÍVEL | cd_calendario 1 "Calendário Padrão": período 1 seg–sex 08–18; período 2 sábado 08–12 | só existe 1 calendário; sábado entra no cálculo |
| idem | Oracle | [CAL_QA] | `CALENDARIO`/`PERIODO` | INCOMPATÍVEL | cd_calendario 1: seg–sex **10:00–18:00**; sábado 08:45–09:45 | horário diferente do exigido e do SQL Server (CT-032 exige massa comparável) |
| CT-010 | SQL Server / Oracle | [FERIADO_GERAL] (`cd_calendario=0`) e [FERIADO_CAL] | `DATA_DESTAQUE` | AUSENTE | 0 linhas nos dois | — |
| CT-019 | SQL Server / Oracle | [PROC_SEMCAL] (processo publicado com `cd_calendario` nulo) | `PROCESSO` agrupado por `cd_calendario` | AUSENTE | todos os processos têm cd_calendario=1 (SQL 36, Oracle 18) | — |
| CT-014 | SQL Server / Oracle | tarefa concluída com `dt_termino` nulo no histórico | `HISTORICO_TAREFA` | AUSENTE | 0 e 0 | requer UPDATE (SQL-SEMNULO) |
| CT-011, 017, 018 | SQL Server | [PROC_PAR] não classificado | `CONTROLE_PASSO_PARALELO` | NÃO VALIDADA | 351 linhas, 28 processos; falta identificar um processo ainda não classificado | exige processo novo publicado |
| CT-011, 017, 018 | Oracle | [PROC_PAR] | `CONTROLE_PASSO_PARALELO` | AUSENTE/NÃO VALIDADA | 0 linhas (nenhum processo classificado); não foi verificado se algum processo tem passo Paralelo | — |
| CT-016 | SQL Server | [PROC_SUB] (`id_tipo_passo=8`) | `PASSO` | EXISTENTE, NÃO CONFIRMADA | 4 processos com SubProcesso; ainda sem checar histórico nas regiões exigidas | — |
| CT-016 | Oracle | [PROC_SUB] | `PASSO` | AUSENTE | 0 processos | — |
| CT-012, 013 | SQL Server / Oracle | [PROC_PRAZO] com e sem `dt_prazo` | `TAREFA.dt_prazo` | NÃO VALIDADA | 4 (SQL) e 11 (Oracle) tarefas com prazo; processo e vínculo com a meta não conferidos | — |
| CT-001, 002, 003 | ambos | [USR_ADMIN], [USR_1], usuário sem permissão | `USUARIO` | NÃO VALIDADA | SQL 52 usuários; Oracle 3 (root, qa.usuario2, qa.usuario3, todos Administrador) | CT-002 precisa de usuário **sem** acesso à tela: não existe no Oracle |
| CT-004 a 006, 021 a 025, 029, 030 | ambos | pendência de cálculo, massa grande, 2 instâncias | `TAREFA`/`TAREFA_INDICADOR` | PARCIAL | SQL: 999 tarefas, 999 indicadores, 0 pendentes (tudo calculado); Oracle: 832 tarefas, 0 indicadores, 832 pendentes | SQL Server precisa de pendência nova; volume para CT-022/030 indefinido ([QTD_TAREFAS]) |
| CT-021 | ambos | 2 instâncias do net8 | — | NÃO VALIDADA | 1 Scheduler e 1 Worker BPM por banco | [MECANISMO_DISPARO] indefinido |
| CT-026, 028 | ambos | artifício de falha | — | NÃO VALIDADA | — | [MECANISMO_FALHA] (DEV-04/07) indefinido |
| CT-006, 029 | ambos | diretório de log net8 | — | PENDENTE | `NLOG_LOGROOT`/`LogsRoot` não lido | — |
| CT-001 a 003, 032 | — | Share web acessível | HTTP `:58149` | BLOQUEADO | sem resposta | — |

## Massas criadas nesta execução
Autorização do usuário em 2026-11-11: itens 1 a 5 do plano de escritas, nos dois bancos. Executados só os itens 1 e 2. Os itens 3, 4 e 5 **não foram executados**: faltam a data dos feriados (3 e 4) e um fluxo de teste com tarefa concluída (5), dados que a autorização não trouxe e que não devem ser inventados.

| RUN_ID | Banco | Objeto | Operação autorizada | IDs/chaves | Quantidade | Verificação | Limpeza/rollback |
|---|---|---|---|---|---:|---|---|
| 20261111-US160818-V01 | SQL Server `ShareGuizao` | `CALENDARIO` | INSERT `CAL_QA`, `st_principal=0`, `vl_hora_util=10` | `cd_calendario=5` | 1 | releitura OK | `DELETE FROM CALENDARIO WHERE cd_calendario=5` (após o período) |
| 20261111-US160818-V01 | SQL Server `ShareGuizao` | `PERIODO` | INSERT seg–sex 08:00–18:00 | `cd_periodo=3`, `cd_calendario=5` | 1 | releitura OK | `DELETE FROM PERIODO WHERE cd_periodo=3` |
| 20261111-US160818-V01 | Oracle `SHAREGUIZAO` | `CALENDARIO` | INSERT `CAL_QA`, `st_principal=0`, `vl_hora_util=10` | `CD_CALENDARIO=3` (trigger + `SEQ_CALENDARIO`) | 1 | releitura OK | `DELETE FROM CALENDARIO WHERE cd_calendario=3` (após o período) |
| 20261111-US160818-V01 | Oracle `SHAREGUIZAO` | `PERIODO` | INSERT seg–sex 08:00–18:00 | `CD_PERIODO=101`, `CD_CALENDARIO=3` | 1 | releitura OK | `DELETE FROM PERIODO WHERE cd_periodo=101` |

**Complemento (mesma data, após o usuário dizer "você pode criar esses dados"):** itens 3, 4 e 5 executados com dados escolhidos por QA, dentro da autorização 1 a 5. Primeira tentativa no SQL Server falhou por formato de data (idioma pt-BR), transação desfeita sem gravar; refeita com `yyyymmdd`.

| RUN_ID | Banco | Objeto | Operação | IDs/chaves | Qtd | Verificação | Rollback |
|---|---|---|---|---|---:|---|---|
| 20261111-US160818-V01 | SQL Server | `DATA_DESTAQUE` | INSERT [FERIADO_GERAL] 2026-11-16, `st_feriado=1`, `cd_calendario=0` | `cd_data_destaque=2` | 1 | releitura OK | DELETE pelo id |
| 20261111-US160818-V01 | SQL Server | `DATA_DESTAQUE` | INSERT [FERIADO_CAL] 2026-11-17, `cd_calendario=5` | `cd_data_destaque=3` | 1 | releitura OK | DELETE pelo id |
| 20261111-US160818-V01 | Oracle | `DATA_DESTAQUE` | INSERT [FERIADO_GERAL] 2026-11-16, `cd_calendario=0` | `CD_DATA_DESTAQUE=101` | 1 | releitura OK | DELETE pelo id |
| 20261111-US160818-V01 | Oracle | `DATA_DESTAQUE` | INSERT [FERIADO_CAL] 2026-11-17, `cd_calendario=3` | `CD_DATA_DESTAQUE=102` | 1 | releitura OK | DELETE pelo id |
| 20261111-US160818-V01 | SQL Server | `HISTORICO_TAREFA` | UPDATE `dt_termino=NULL` (CT-014) | `cd_fluxo=900787`, `cd_tarefa=2` | 1 | `HT_SEMTERM`=1 | `UPDATE ... SET dt_termino='2026-11-10 16:48:27.000' WHERE cd_fluxo=900787 AND cd_tarefa=2` |
| 20261111-US160818-V01 | Oracle | `HISTORICO_TAREFA` | UPDATE `dt_termino=NULL` (CT-014) | `cd_fluxo=2486`, `cd_tarefa=2` | 1 | `HT_SEMTERM`=1 | `UPDATE ... SET dt_termino=to_date('2026-11-10 17:11:25','YYYY-MM-DD HH24:MI:SS') WHERE cd_fluxo=2486 AND cd_tarefa=2` |

Ressalvas: (a) os fluxos 900787/2486 são de ciclos QA anteriores (US 160823), já concluídos, 0 tarefas abertas, sem indicador; alterar o histórico pode afetar a evidência desses ciclos até o rollback. (b) Os dois feriados são geral/calendário **globais**: o feriado geral (`cd_calendario=0`) vale para todos os calendários e altera o cálculo de qualquer tarefa que cruze 2026-11-16 nestes bancos. (c) Com o job 16 ativo no Oracle e o Worker rodando, o net8 pode corrigir o `dt_termino` do item 5 antes do teste; reler antes de executar o CT-014. (d) CT-014 segue `HIPOTESE:`.

**Atualização do status:** [FERIADO_GERAL], [FERIADO_CAL] e a massa do CT-014 passam a `CRIADA E CONFIRMADA` nos dois bancos. [CAL_QA] idem. Gate segue **BLOQUEADO** (ver pendências 1, 2, 5 [processos], 7, 8 e 9).

Resultado: `CALENDARIO`=2 e `PERIODO`=3 nos dois bancos. `Calendário Padrão` (cd_calendario 1) intocado. Nenhum DELETE, nenhuma alteração de `JOB_CONFIG`. O `CAL_QA` ainda não está vinculado a nenhum processo (isso é feito no Desenho do Processo, com o Share no ar).

**Atualização do status (pós-escrita):** o requisito [CAL_QA] passa a `CRIADA E CONFIRMADA` nos dois bancos. Gate continua **BLOQUEADO** pelas demais pendências (itens 1, 2, 4 a 9 da lista acima, mais as datas de feriado e o fluxo do CT-014).

## Atualização 2 (2026-11-11, após o usuário informar que o Share está no ar e pedir lacunas pelo clássico)

**Ambiente**
- Share web `http://localhost:58149/SmartShare/index.aspx` responde (tela de login). Raiz `/SmartShare/` devolve 403.14 (esperado, sem documento padrão).
- Serviços Windows `SmartShareAgent`, `SmartShareAgent_BPM_Borges`, `SmartShareAgent_Scheduler_Borges` (instalados em `D:\Instalação Share\...`) estão **parados**. Não foram iniciados.
- Binários do repo `bin\Debug\net8.0` (Scheduler e Worker BPM) compilados em 2026-11-10 16:41–16:42, pós-HEAD `532fea37`. `Project.Core.Application.dll`, `Project.Core.Infraestructure.dll` e `SmartShareAgent_BpmWorker.dll` contêm símbolos `CalculoIndicador` (grep binário). `appsettings.json` do `bin`: `DBType=Oracle`, schema `SHAREGUIZAO`.
- **Worker BPM iniciado** (PID 30856) a partir de `bin\Debug\net8.0`. Log do build local: `bin\Debug\net8.0\Log\yyyyMMdd_BpmWorker.log` (valor de [LOG_DIR_AGENT_NET8] para este build; `LogsRoot` não está configurado, o NLog cai em `Log\` ao lado do exe). Linhas: "Iniciando worker/Bpm SHAREGUIZAO" e "Finalizado worker/Bpm SHAREGUIZAO" (10:51–10:52), sem ERROR.
- **Scheduler NÃO foi iniciado** de propósito: ele enfileira o job 16 e o Worker o calcularia agora no Oracle (`JOB_CONFIG` Id 9 `Ativo=1`), consumindo as 832 pendências e possivelmente corrigindo o `dt_termino` nulo do CT-014 antes do teste. Subir só na execução. Observação: o Worker BPM executa também itens pendentes de outros jobs (`JOB_BPM`: Oracle jobs 9, 18, 19; SQL Server jobs 9, 18, 19, 32).
- Estado inicial de `STATUS_AGENT` 16: `st_executando=0` nos dois bancos.

**Lacunas resolvidas pelo Agent clássico (`lida-no-codigo`)**
| Marcador | Regra do clássico | Fonte |
|---|---|---|
| [CHAVE_ATIVACAO_ROTINA] (DEV-01) | O clássico pula o cliente quando `JOB_CONFIG` (Modulo=1, Job=16) tem `Ativo` verdadeiro; ativar no net8 = `Ativo=1`, voltar ao clássico = `Ativo=0` | `SmartShareAgent/Agent.cs:899` e `UsarNovoAgent` (`Agent.cs:1855`) |
| [INTERVALO_JOB] (DEV-05) | Clássico: `VlTempoCalculaIndicadores`, padrão 600000 ms (10 min), `Timer` com disparo imediato; net8: `JOB_CONFIG.Interval_Ms` (Oracle 60000, SQL Server 600000) | `ConfigAgentDAL.cs:139`, `Agent.cs:156` |
| Só 1 cálculo por vez (CT-021/022, RF-03) | Duas camadas: flag em memória `_flagCalculaIndicadores` (mesma instância) e `UPDATE STATUS_AGENT ... WHERE cd_status_agent=16 AND (st_executando <> 1 OR hash_id = <hash>)` (entre instâncias); libera com `DesassociarTask` ao fim | `Agent.cs:888`, `AssumeTaskDisponivel` (`Agent.cs:1480`), `DesassociarTask` (`Agent.cs:1506`) |
| Execução ignorada gera log? (CT-025, PM-07) | **Não**: o clássico apenas não executa, sem log | `Agent.cs:888-902` |
| Erro logado (RF-06, CT-026/027) | `Log.GravaLogErro(ex, "CalculoIndicador", cliente)` por cliente; erro dentro da BLL vira exceção via `DeuErro` | `Agent.cs:911-918` |
| Trava após queda do processo (CT-024, DEV-03) | No clássico o `DesassociarTask` só roda no fluxo normal; queda no meio deixa `st_executando=1` com o `hash_id` da instância morta. Comportamento do net8 (lease `Lock_Expira_Em`) é diferente: **divergência a observar**, não regra herdada | `Agent.cs:902-920` |
| [MECANISMO_DISPARO] (CT-021) | Subir uma 2ª instância do Worker BPM no mesmo banco (ou forçar `JOB_BPM`/lock); cada instância tem seu `hash_id` | derivado de `Agent.cs:1491` |

Ainda sem fonte: [MECANISMO_FALHA]/[MECANISMO_FALHA_SEMEADURA] (como provocar erro numa tarefa e numa das 4 transações), [QTD_TAREFAS] (volume-limite do CT-030), [CAMINHO_TELA_CONFIG] (CT-001) e DEV-08 (scripts do PR #29630). Continuam lacunas declaradas; não viram critério de aceite.

**Atualização 3 — login liberado pelo usuário ("Liberar leitura") e início dos processos (Oracle):**
- Login `root` feito no Share (portal "Olá Administrador", licença "Oracle"). A senha foi lida do arquivo de variáveis e aplicada por script temporário, já apagado. Obs.: a ferramenta do navegador ecoou o código do script na saída da sessão; recomenda-se **trocar a senha de teste do `root` deste ambiente local** (e não reutilizá-la em outro lugar).
- Calendário `CAL_QA` aparece na lista da tela de processo (Oracle, cd 3), confirmando que o Share está no Oracle.
- Criado pela tela (`Workflow/processo.aspx?tpAcao=novo&cdPasta=5`): **processo 641 "QA-160818 PROC_CALC"** (Oracle), `cd_calendario=3` (CAL_QA), vínculo "Geral", papel principal/administrador "Papel Default", versão 1, `id_status=1` (**rascunho, ainda sem fluxo desenhado e não liberado**). Rollback: "Cancelar Criação" na tela do processo ou remoção pelo Share.
- Campos obrigatórios descobertos: Vínculo, Papel Principal e Papel Administrador (lookups preenchidos via os callbacks `ssZomPerfil_callBack` etc., equivalentes ao popup). O submit gera erro JS de UpdatePanel, mas grava no servidor.
- Desenhador (`Workflow/processogeral.aspx`, `frameFluxo` = `visualizaFluxograma.aspx`) abre; falta desenhar 2 atividades em sequência e liberar.
- Processos existentes reaproveitáveis por leitura: Oracle 621 "QA-161711 Ramos paralelos" (publicado, `cd_calendario=1`) serve de base para [PROC_PAR] se confirmado que tem Paralelo com junção; SQL Server tem 4 processos com SubProcesso (Oracle: 0). Todos usam o calendário padrão (1), não o CAL_QA.

**Atualização 4 — reuso de processos existentes (decisão do usuário: "Reusar existentes"):**

| Marcador | Oracle | SQL Server |
|---|---|---|
| [PROC_CALC] | 541 "QA-161495 Unidades" (3 atividades, publicado) | 1030 "QA-161495 Unidades" (3 atividades, publicado) |
| [PROC_PAR] | 621 "QA-161711 Ramos paralelos" (passo Paralelo `10x2`, `CONTROLE_PASSO_PARALELO`=0: **não classificado**) | 10 "Teste Agent BPM - Avanco Temporal" (`10x2`, CPP=0, sem fluxos); processos 1038/1023 já classificados (CPP>0), não servem |
| [PROC_SUB] | **nenhum** (0 processos com `id_tipo_passo=8`) | 10 (tem `8x1`; também 5 e 1022, mas com CPP>0) |
| [PROC_PRAZO] | usar [PROC_CALC] com SQL-PRAZO (permitido pelo mapa quando o campo não grava direto) | idem |
| [PROC_SEMCAL] | **nenhum** — a tela de processo só oferece calendários (sem opção vazia), não dá para criar processo sem calendário pela UI | idem |

Calendário `CAL_QA` aplicado pela tela "Editar Processo" (`btnEditar`), conferido no banco: **Oracle** 541 → cal 3, 621 → cal 3 (ambos continuam `id_status=3`, versão 1). **SQL Server:** 1030 e 10 **ainda em cal 1**; editar pela tela exige trocar o Share para SQL Server (`config/webconfig.aspx`), que pede a senha do SQL Server. O executor do Playwright não permite ler a senha do arquivo sem que ela apareça na saída da sessão (a ferramenta ecoa o código); a troca ficou **não executada** (nenhum arquivo de config alterado; backups em `scratchpad\bkp-config`). Worker BPM (PID 30856) parado por mim antes da tentativa de troca.
O processo 641 "QA-160818 PROC_CALC" (Oracle, rascunho, sem fluxo) ficou sem uso; pode ser descartado ("Cancelar Criação") sem impacto.
Lacunas que seguem: [PROC_SUB] no Oracle e [PROC_SEMCAL] nos dois bancos (CT-016 no Oracle e CT-019): sem massa; CT-019 é `HIPOTESE:`.

**Atualização 5 — UPDATE autorizado pelo usuário ("UPDATE por SQL"), SQL Server `ShareGuizao`, RUN_ID 20261111-US160818-V01:**

| Objeto | Operação | Antes | Depois | Verificação | Rollback |
|---|---|---|---|---|---|
| `PROCESSO` cd_processo 1030, versão 1 (publicado) | `cd_calendario` 1 → 5 (`CAL_QA`) | 1 | 5 | releitura OK | `UPDATE PROCESSO SET cd_calendario=1 WHERE cd_processo=1030 AND cd_versao_processo=1` |
| `PROCESSO` cd_processo 10, versão 1 (publicado) | `cd_calendario` 1 → 5 (`CAL_QA`) | 1 | 5 | releitura OK | `UPDATE PROCESSO SET cd_calendario=1 WHERE cd_processo=10 AND cd_versao_processo=1` |

Execução em transação, guarda de 2 linhas, filtro por processo/versão/status publicado. Sem DELETE. Fluxos já existentes mantêm o calendário antigo; só fluxos **novos** destes processos herdam `CAL_QA`.

**Estado de massa por marcador após as atualizações 1 a 5**
| Marcador | Oracle | SQL Server |
|---|---|---|
| [CAL_QA] | CRIADA E CONFIRMADA (cd 3) | CRIADA E CONFIRMADA (cd 5) |
| [FERIADO_GERAL]/[FERIADO_CAL] | CRIADA E CONFIRMADA | CRIADA E CONFIRMADA |
| [PROC_CALC] | 541 em CAL_QA, CONFIRMADA | 1030 em CAL_QA, CONFIRMADA |
| [PROC_PAR] | 621 em CAL_QA, CPP=0 (não classificado), CONFIRMADA | 10 em CAL_QA, CPP=0, CONFIRMADA |
| [PROC_PRAZO] | via SQL-PRAZO sobre 541 (pendente de autorização no momento do teste) | via SQL-PRAZO sobre 1030 |
| [PROC_SUB] | **AUSENTE** | 10 (`8x1`), existente |
| [PROC_SEMCAL] | **AUSENTE** (hipótese CT-019) | **AUSENTE** |
| histórico sem término (CT-014) | criada (fluxo 2486/2) | criada (fluxo 900787/2) |

**Gate continua BLOQUEADO.** Pendências restantes: (1) [PROC_SUB] no Oracle (CT-016, P2) e [PROC_SEMCAL] (CT-019, P3, hipótese) sem massa; como a regra da skill não libera rodada parcial, é preciso massa ou decisão do responsável de retirar/rebaixar esses cenários; (2) Scheduler do net8 ainda não iniciado (de propósito) e Worker BPM parado; (3) troca do Share/net8 para SQL Server (QA-KB-20261106-001) só na execução do lado SQL Server; (4) marcadores do mapa sem fonte: [MECANISMO_FALHA]/[MECANISMO_FALHA_SEMEADURA], [QTD_TAREFAS], [CAMINHO_TELA_CONFIG], DEV-08; (5) PROC_PRAZO e PROC_PAR exigem fluxo novo e SQL-PRAZO durante a execução (escrita a autorizar no momento).

**Atualização 6 — tentativa de "Criar massa" para [PROC_SUB] (Oracle) e [PROC_SEMCAL] (nenhuma escrita feita):**
- **[PROC_SEMCAL] é impossível no schema atual:** `PROCESSO.cd_calendario` é `NOT NULL` nos dois bancos (SQL Server `is_nullable=0`; Oracle `NULLABLE=N`) e `FLUXO.cd_calendario` não tem nulos. Um processo "sem calendário vinculado" (premissa do CT-019 e do [PROC_SEMCAL]) não pode existir; a tela também não oferece opção vazia. Achado `lida-no-codigo`/banco: CT-019 deve ser reformulado pelo autor do mapa (ex.: calendário **sem períodos**) ou retirado. Não criei massa alternativa por inferência.
- **[PROC_SUB] no Oracle:** o desenhador do fluxograma (`processogeral.aspx` + `visualizaFluxograma.aspx`) **não renderiza** no navegador automatizado (área em branco; provável componente legado), então não dá para criar o passo SubProcesso pela tela. Caminho viável: **Exportar Xml** do processo 10 no SQL Server (passo 98 "Sub-Processo", `PASSO_PROCESSO.cd_sub_processo=3`) e **Importar** no Oracle (aba "Importar" de `processo.aspx`), mas exige o Share apontando para SQL Server (senha do SQL Server na tela) ou que o responsável faça a exportação e entregue o zip. Cópia por INSERT entre bancos não proposta (muitas tabelas, condição artificial).
- Nada foi gravado nesta etapa. Estado das massas inalterado em relação à Atualização 5.

**Atualização 7 — redução de escopo decidida pelo usuário ("Retirar do escopo", 2026-11-11):**
- **Fora desta rodada:** CT-019 (premissa impossível: `PROCESSO.cd_calendario` NOT NULL) e CT-016 **no Oracle** (sem massa [PROC_SUB]). CT-016 continua no escopo no SQL Server (processo 10, passo 98).
- **Reavaliação após o corte.** Massa de banco: todos os requisitos aplicáveis estão `CRIADA E CONFIRMADA`/`EXISTENTE E CONFIRMADA` nos dois bancos (CAL_QA, feriados, [PROC_CALC], [PROC_PAR], histórico sem término; [PROC_PRAZO] via SQL-PRAZO no momento do teste). Os cenários `HIPOTESE:` restantes (CT-002, 018, 020, 024, 025, 030) seguem sob a restrição de execução automática do mapa e não entram como requisito de gate.
- **Ainda sem fonte (impedem a rodada completa):**
  1. **[MECANISMO_FALHA] / [MECANISMO_FALHA_SEMEADURA]** (CT-026, 027, 028 e 031, que reusa o erro do CT-026). `CalculoIndicadorService` trata erro por item com transação própria e `LogError` por região (`CalculoIndicadorService.cs:223-469`), mas nenhuma fonte diz qual dado faz um item lançar exceção nem como derrubar 1 das 4 transações de semeadura (`TransferirParaIndicador`, linhas 106-109). Definir um artifício por tentativa-e-erro seria condição artificial e exige nova escrita autorizada no momento do teste.
  2. **[CAMINHO_TELA_CONFIG]** (CT-001; CT-002 é hipótese) e **DEV-08** (conteúdo dos scripts do PR #29630, CT-003): sem resposta; o executor descobre/pergunta ao dev no início da rodada.
- **Ações de execução (não são pendência de ambiente):** subir o Scheduler e o Worker BPM do `bin\Debug\net8.0` na hora do PA-NOVO (o Scheduler consome a pendência do Oracle assim que sobe); trocar Share/net8 para SQL Server (QA-KB-20261106-001) antes do lado SQL Server; PA-CLASS exige o serviço `SmartShareAgent` clássico (parado hoje).
- **Segurança:** a senha de teste do `root` apareceu na saída da sessão; recomenda-se trocá-la.

**Atualização 8 — gate emitido (2026-11-11, após "Definir na execução").**
- **Releitura final por leitura (SQL Server e Oracle), contexto igual ao do relatório:** `CAL_QA` (SQL cd 5 / Oracle cd 3) com 1 período seg–sex 08:00–18:00; feriados 2026-11-16 (geral, cal 0) e 2026-11-17 (CAL_QA) presentes; processos 1030 e 10 (SQL) e 541 e 621 (Oracle) publicados, versão 1, calendário CAL_QA; `CONTROLE_PASSO_PARALELO` do 10 e do 621 = 0 (não classificados); `HISTORICO_TAREFA` sem término: SQL fluxo 900787/tarefa 2, Oracle fluxo 2486/tarefa 2; `STATUS_AGENT` 16 `st_executando=0`; `JOB_CONFIG` Id 9: SQL `Ativo=0`/600000 ms, Oracle `Ativo=1`/60000 ms; Oracle `TAREFA_INDICADOR`=0. Mapa #161491 `ChangedDate` 2026-10-21T13:52:33.103Z (inalterado). Nenhum processo `SmartShareAgent*` rodando.
- **Desvio declarado da regra da skill:** a skill só libera sem pendência. O usuário escolheu liberar com escopo ajustado e definir o mecanismo de falha na execução; isto vale **só** para CT-026/027/028/031, que ficam fora da liberação até que o artifício seja definido e autorizado (pausa e novo `/arquitetura-validar-ambiente` ou autorização específica no momento). Não vale para outros cenários.
- **Condições para o executor:** (1) CT-001: descobrir o caminho da tela de configuração; CT-003: obter do dev o conteúdo dos scripts do PR #29630 (DEV-08) — sem isso, `INCONCLUSIVO`; (2) subir Scheduler e Worker BPM do `bin\Debug\net8.0` (Oracle) na hora do PA-NOVO; antes do lado SQL Server trocar o Share/net8 (QA-KB-20261106-001) e reler `JOB_CONFIG` Id 9; (3) SQL-PRAZO e qualquer ajuste de datas por SQL (CT-008, 009, 012, 013) exigem autorização de UPDATE no momento; (4) para PA-CLASS subir o serviço `SmartShareAgent` clássico e usar `JOB_CONFIG` Id 9 `Ativo=0` para o cliente; (5) o Worker BPM também executa itens pendentes de outros jobs em `JOB_BPM` (Oracle: jobs 9, 18, 19; SQL Server: 9, 18, 19, 32); (6) o Scheduler consome a pendência do Oracle assim que sobe e pode corrigir o `dt_termino` nulo do CT-014 antes do teste: reler `HISTORICO_TAREFA` antes de executar o CT-014; (7) fluxos antigos mantêm o calendário anterior: iniciar fluxos **novos** em 541/621/1030/10.
- **Rollbacks e limpeza** (nada apagado): ver as tabelas de escritas acima. Processo 641 (rascunho Oracle) pode ser descartado.
- **Assinatura de contexto:** mapa 161491 | ChangedDate 2026-10-21T13:52:33.103Z | ambiente local-nao-produtivo | commit 532fea37 (binários `bin\Debug\net8.0` de 2026-11-10 16:41-16:42 com `CalculoIndicador`) | SQL Server NOTE-74VQ\SQLEXPRESS/ShareGuizao | Oracle SHAREGUIZAO/SSHARE | RUN_ID 20261111-US160818-V01.

**Bloqueio desta etapa (anterior ao login):** login no Share (`root`) e processos de teste pela tela. O classificador de permissões negou ler a senha de teste do `root` do arquivo de variáveis para digitá-la na tela (credencial). O arquivo registra `SS_TEST_PASSWORD` como "fornecido em tempo de execução" para o `root`. Sem login não dá para criar [PROC_CALC], [PROC_PAR], [PROC_PRAZO], [PROC_SEMCAL], [PROC_SUB] pela tela nem fazer a troca de banco (`webconfig.aspx`, que também pede senha). Nenhuma tentativa de contornar.

## Hipóteses (mapa) e validade funcional da massa
CT-002, 018, 019, 020, 024, 025 e 030 seguem `HIPOTESE:`. Criar a massa de CT-019 ([PROC_SEMCAL]), CT-014 (histórico sem término por UPDATE) e CT-008/009 (datas ajustadas por SQL) é condição artificial: o mapa já prevê o ajuste por SQL (SQL-SEMNULO, "ajustar datas por SQL"), mas **não há caminho suportado pelo produto confirmado para CT-014** (o clássico corrige antes do cálculo; como o dado nasce nulo na prática é lacuna). Mantém restrição de execução automática dos cenários hipótese.

## Pendências bloqueantes
1. **Share web fora do ar** (`localhost:58149`): subir o IIS Express/Share. Necessário para cadastros (Calendário, Data Destaque, Desenho do Processo), CT-001/002/003 e CT-032.
2. **Build não comprovado**: confirmar que `SmartShareAgent_BpmWorker` e `SmartShareAgent_SchedulerWorker` rodam o commit `532fea37` (HEAD da branch da US, PRs #29630/#29631). Indício contrário: Oracle com job 16 ativo e 0 indicadores.
3. **Calendário [CAL_QA]** incompatível nos dois bancos, e com valores diferentes entre eles. Decisão: criar `CAL_QA` novo (seg–sex 08:00–18:00, sem sábado) em ambos e vincular a processos de teste, ou ajustar o calendário padrão (UPDATE em dado preexistente, exige autorização separada).
4. **Feriados** (Data Destaque): criar [FERIADO_GERAL] (`cd_calendario=0`) e [FERIADO_CAL] nos dois bancos, em data dentro do intervalo de teste.
5. **Processos de teste**: [PROC_CALC], [PROC_PAR], [PROC_PRAZO], [PROC_SEMCAL] e, no Oracle, [PROC_SUB]. Criar pelo Desenho do Processo (Share web, depende do item 1) ou indicar processos existentes equivalentes.
6. **Histórico sem término** (CT-014): UPDATE em `HISTORICO_TAREFA` nos dois bancos; exige autorização específica e confirmação de que é válido para a hipótese.
7. **Usuário sem acesso à tela de configuração** (CT-002): não existe no Oracle; pelo mapa é hipótese, confirmar necessidade.
8. **Lacunas do mapa que impedem execução** (não são massa de banco): [MECANISMO_DISPARO] (CT-021), [MECANISMO_FALHA]/[MECANISMO_FALHA_SEMEADURA] (CT-026/028), [QTD_TAREFAS] (CT-030), [CAMINHO_TELA_CONFIG] (CT-001), DEV-08 (scripts do PR #29630, CT-003), valor real de `[LOG_DIR_AGENT_NET8]`. Responsáveis: dev (Vinicius Medeiros dos Santos) e PM.
9. **Banco ativo do net8**: hoje Oracle. Para rodar no SQL Server seguir QA-KB-20261106-001 (troca em 4 passos, direção Oracle→SQL Server ainda não executada por QA). Estado inicial de `JOB_CONFIG` Id 9 também difere (Oracle `Ativo=1`/60 s; SQL Server `Ativo=0`/600 s) e o mapa exige estado comparável (CT-032).

## Solicitação de autorização (nada executado)
Escritas só depois de um "sim" explícito, listando ambiente, banco e quantidade. Proposta mínima, **a confirmar antes de qualquer escrita**:
- Pelo Share web (preferido, sem SQL direto): criar `CAL_QA`, 2 feriados, 4–5 processos de teste. Dependem do item 1.
- Por SQL (somente se o Share não puder): INSERT em `DATA_DESTAQUE` (2 linhas por banco) e UPDATE `HISTORICO_TAREFA.dt_termino=NULL` em 1 tarefa de teste por banco (CT-014), com filtro `cd_fluxo`/`cd_tarefa` do fluxo de teste, rollback pelo valor original gravado antes.
- Nenhum DELETE e nenhuma alteração de `JOB_CONFIG` proposta.

## Aprendizados consultados
| ID | Status | Relação com a atividade | Uso ou ressalva |
|---|---|---|---|
| QA-KB-20261106-001 | validado | troca de banco local; valores de `JOB_CONFIG` por banco | usado como procedimento; estados de `JOB_CONFIG` revalidados hoje (diferem do registro de 06/11 para o job 12, não é o job desta US) |
| QA-KB-20261105-001 | candidato | NullReference no net8 vs clássico | ressalva, não aplicada |

## Decisão
**BLOQUEADO.** Retomar quando: (a) Share web acessível e build dos Workers comprovado; (b) calendário [CAL_QA], feriados e processos de teste existirem e forem confirmados por leitura nos dois bancos (ou o usuário autorizar a criação por escrito); (c) o dev/PM responder os marcadores de execução do item 8 que bloqueiam os cenários envolvidos. Rodar `/arquitetura-validar-ambiente #160818` de novo depois. Como a skill exige rodada completa, não há liberação parcial.

**Assinatura de contexto:** mapa 161491 | ChangedDate 2026-10-21T13:52:33.103Z | ambiente local-nao-produtivo | commit 532fea37 (branch, não comprovado no runtime) | SQL Server ShareGuizao, Oracle SHAREGUIZAO.

## Atualização 9 — rodada SQL Server (2026-11-12, RUN_ID 20261111-US160818-V02)

**Status do gate desta rodada:** BLOQUEADO (aguardando autorizações de escrita e a troca do banco do Share/net8). Nenhum cenário iniciado. Nenhuma escrita feita nesta atualização.

**Contexto:** mapa #161491 (ChangedDate 2026-10-21T13:52:33.103Z), local não produtivo, SQL Server `NOTE-74VQ\SQLEXPRESS` / `ShareGuizao` (ADAPTER_LOCAL `sqlcmd -E`, probe de leitura OK), branch `feature/US160818-migracao-job-calculo-indicador` HEAD `532fea37`, `SmartShareAgent_BpmWorker.dll` compilado 2026-11-11 11:47.

### Releitura por leitura (SQL Server)
| Requisito | Resultado | Evidência |
|---|---|---|
| [CAL_QA] | EXISTENTE E CONFIRMADA | `CALENDARIO` cd 5, `PERIODO` cd 3 seg–sex 08:00–18:00 |
| [FERIADO_GERAL]/[FERIADO_CAL] | INCOMPATÍVEL | `DATA_DESTAQUE` cd 2 (cal 0) e cd 3 (cal 5) com ano **2026** (2026-11-16 e 2026-11-17); o código só casa feriado no ano 1904 (QA-KB-20261111-001) |
| [PROC_CALC] | EXISTENTE E CONFIRMADA | processo 1030 v1, `cd_calendario=5`, `id_status=3`; já tem 3 fluxos e 9 tarefas |
| [PROC_PAR] / [PROC_SUB] | EXISTENTE E CONFIRMADA | processo 10 v1, `cd_calendario=5`, `id_status=3`, `CONTROLE_PASSO_PARALELO`=0, 0 fluxos (fluxo novo precisa ser criado pela tela) |
| Histórico sem término (CT-014) | INCOMPATÍVEL | `HISTORICO_TAREFA` 900787/2 voltou a `dt_termino`=2026-11-10 16:48:27: o Agent clássico corrigiu (serviço `SmartShareAgent` Running) |
| `JOB_CONFIG` Id 9 | OK (estado inicial) | `Ativo=0`, `Interval_Ms=600000`; `STATUS_AGENT` 16 `st_executando=0`, última verificação 15:49 (clássico calculando a cada 10 min) |
| Banco ativo do Share e do net8 | PENDENTE | `appsettings.json` da API `DBType=Oracle`; `Web.config` `System.Data.OracleClient`. Rodar no SQL Server exige a troca (QA-KB-20261106-001, direção Oracle→SQL Server, nunca executada por QA) |
| Serviços | PENDENTE | `SmartShareAgent` clássico Running (calcula no SQL Server enquanto `Ativo=0`); `SmartShareAgent_BPM_Borges` e `SmartShareAgent_Scheduler_Borges` Stopped; Share web `:58149` responde 200 |

### Escritas necessárias (solicitação ao usuário, nada executado)
1. SQL Server `ShareGuizao`, `DATA_DESTAQUE`: UPDATE `dt_destaque` das linhas `cd_data_destaque` 2 → 1904-11-16 e 3 → 1904-11-17 (2 linhas). Rollback: voltar para 2026-11-16/17 ou DELETE das duas linhas ao fim.
2. SQL Server, `HISTORICO_TAREFA`: UPDATE `dt_termino=NULL` em `cd_fluxo=900787, cd_tarefa=2` (1 linha), imediatamente antes do CT-014, depois de parar o clássico para ele não corrigir antes do net8. Rollback: `dt_termino='2026-11-10 16:48:27'`.
3. SQL Server, `JOB_CONFIG` Id 9: UPDATE `Ativo` 0 → 1 (PA-NOVO) e `Interval_Ms` 600000 → 60000 (comparável ao Oracle e para o CT-006/022), com volta a 0/600000 ao fim.
4. SQL Server, `TAREFA`: SQL-PRAZO (`dt_prazo`) e ajuste de datas dos fluxos de teste (CT-008, 009, 012, 013), só nos fluxos criados pelo QA nesta rodada.
5. SQL Server, `CONTROLE_PASSO_PARALELO` do processo 10: DELETE das linhas criadas pela rotina, para reexecutar o CT-011 (como no Oracle).
6. Trigger temporário em `TAREFA_INDICADOR` e `FLUXO_INDICADOR` (T-SQL `THROW`/`RAISERROR`) mais DELETE de 1 linha de `FLUXO_INDICADOR`, para CT-026/027/028/031 (equivalente SQL Server do QA-KB-20261111-003). Remoção ao fim.

### Ações fora do banco (dependem do usuário)
- Trocar o Share/net8 para SQL Server em `config/webconfig.aspx` (pede senha do SQL Server e do `root`): o executor não lê senha do arquivo de variáveis sem ela aparecer na saída da sessão; o usuário faz a troca ou autoriza o método.
- Parar o serviço `SmartShareAgent` clássico durante o PA-NOVO (exige elevação).

### Decisão
**BLOQUEADO.** Libera quando: (a) autorizações 1 a 6 concedidas e feriados 1904 e histórico sem término recriados e relidos; (b) Share/net8 apontando para o SQL Server (log do Worker "Iniciando worker/Bpm dbo"); (c) `SmartShareAgent` clássico parado no PA-NOVO.
**Assinatura de contexto:** mapa 161491 | 2026-10-21T13:52:33.103Z | local-nao-produtivo | commit 532fea37 | SQL Server ShareGuizao | RUN_ID 20261111-US160818-V02.

## Atualização 10 — troca para SQL Server feita e gate emitido (2026-11-12, RUN_ID 20261111-US160818-V02)

Autorização do usuário: escritas 1 a 6 da Atualização 9, no SQL Server `ShareGuizao` local, com rollback ao fim; troca do banco feita pelo executor.

**Escrita executada:** `DATA_DESTAQUE` cd 2 → 1904-11-16 (geral, cal 0) e cd 3 → 1904-11-17 (cal 5), 2 linhas, transação com guarda de 1 linha por UPDATE, releitura OK. Rollback: voltar para 2026-11-16/17 ou DELETE dos dois ids.
**Troca de banco (QA-KB-20261106-001, direção Oracle → SQL Server, primeira vez por QA):** `webconfig.aspx` salvo ("Configurações Salvas com Sucesso!"); `Web.config` `ProviderName=System.Data.SqlClient`; `appsettings.json` da API, do Scheduler e do Worker BPM (fonte e `bin\Debug\net8.0`) com `DBType=SQLServer`, `Schema=dbo`; login do Share mostra "licenciado para QA - Guilherme" sem o texto "Oracle". Backups do estado Oracle em `scratchpad\bkp-config-sql` (sessão, não versionado). Senhas foram coladas pela área de transferência e a área foi limpa; nenhuma senha gravada neste relatório.
**Ambiente:** Playwright liberado (encerrado o Chrome do perfil `ms-playwright-mcp` com autorização do usuário). Serviços net8 ainda parados; `SmartShareAgent` clássico Running.

**Estado de massa (SQL Server):** [CAL_QA] OK; feriados CRIADA E CONFIRMADA (1904); [PROC_CALC] 1030 e [PROC_PAR]/[PROC_SUB] 10 em CAL_QA, publicados; `CONTROLE_PASSO_PARALELO` do 10 = 0. Histórico sem término (CT-014) e fluxos novos nos processos 1030/10 são criados **no momento do teste** (o clássico corrige o `dt_termino` antes do net8 se estiver calculando): ver condições abaixo.
**Condições para o executor:** (1) `JOB_CONFIG` Id 9 `Ativo=1` (net8 calcula, clássico pula) para o PA-NOVO e `Ativo=0` para o PA-CLASS; `Interval_Ms` 60000 só durante a rodada; (2) recompilar/subir Scheduler e Worker BPM só depois de reler `JOB_CONFIG`; (3) UPDATE `HISTORICO_TAREFA` 900787/2 só imediatamente antes do CT-014; (4) fluxos novos pela tela do Share no SQL Server; (5) reverter tudo ao fim (feriados, `JOB_CONFIG`, histórico, `CONTROLE_PASSO_PARALELO`, triggers) e voltar o Share/net8 ao Oracle se o usuário pedir.
**Status do gate:** LIBERADO PARA EXECUÇÃO (escopo SQL Server; CT-019 e CT-016-Oracle fora; `HIPOTESE:` do mapa sob restrição de execução automática).
**Assinatura de contexto:** mapa 161491 | 2026-10-21T13:52:33.103Z | local-nao-produtivo | commit 532fea37 | SQL Server NOTE-74VQ\SQLEXPRESS/ShareGuizao (Share e net8 em SQL Server) | RUN_ID 20261111-US160818-V02.
