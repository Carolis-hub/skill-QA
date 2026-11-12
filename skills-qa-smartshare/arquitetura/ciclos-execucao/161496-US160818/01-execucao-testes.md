# Execução — Mapa de Testes #161491 Rotina - Calculo Indicador (US #160818)

Evidências brutas em `evidencias/` (mesma pasta). Plano e reversão da falha controlada: `02-plano-falha-controlada.md`.

**Status:** CONCLUÍDO NO ORACLE (rodada 1) — SQL Server fica em outra sessão. Resultado: ver 'Resumo' e 'Cenários não executados'. Double-check independente (subagent Sonnet) feito; achados confirmados corrigidos (CT-010, CT-004/005, CT-014, CT-011 classificação, CT-029).
**Ambiente:** local não produtivo — Share `http://localhost:58149/SmartShare/` + net8 (`bin\Debug\net8.0`, commit `532fea37`) no Oracle `SHAREGUIZAO`. Rodada 1 (funcional local).
**Gate:** `00-validacao-ambiente.md` LIBERADO PARA EXECUÇÃO (escopo ajustado). Autorizações S1–S4 e W1–W5 concedidas pelo usuário em 2026-11-11.
**Método de comparação (PA-COMPARA adaptado):** sem snapshot/restore. net8 calculou primeiro; resultados congelados em `scratchpad\snapshot-net8-oracle-congelado.txt`; indicadores dos fluxos de teste (2522–2529) e CPP 621/10 apagados (W3); o **clássico** foi executado pela página do Share `Workflow/CalculoIndicador.aspx` (mesma BLL `CalculoIndicadorBLL.CalculaIndicadores`), resultado em `scratchpad\resultado-classico-oracle-pagina.txt`. Valores de tarefas em andamento foram normalizados pelo intervalo entre os dois cálculos (120 s, 11:57:13 → 11:59:13).

## Resumo (Oracle, rodada 1)

| Resultado | Cenários |
|---|---|
| PASSOU (inclui paridade net8 × clássico) | CT-004, 005, 006, 007, 008, 009, 010, 011, 012, 014, 015, 017, 022, 023 |
| PASSOU com falha provocada (trigger temporário, removido) | CT-026, 027, 028, 031 |
| PASSOU COM RESSALVA | CT-013 (sem tempo padrão na atividade), CT-021 (sem log da 2ª instância recusando o lock) |
| PASSOU na API (tela não aberta) | CT-001 |
| PARCIAL | CT-003 (branch sem script de banco), CT-029 (RF-04 passou; RF-05 a esclarecer com PM/dev) |
| Não executados | HIPOTESE do mapa: CT-002, 018, 019, 020, 024, 025, 030; fora do escopo: CT-016 (Oracle); outra sessão: CT-032 e todo o SQL Server (motivos abaixo) |

Double-check independente e análise de falha: nenhum defeito aberto; ver `03-analise-falha.md`.

## Descobertas de ambiente durante a execução
1. **Binário do Scheduler estava desatualizado** (compilado 2026-11-10 16:42) e não enfileirava o job 16, apesar de o fonte do HEAD ter o enfileiramento. Recompilei `Project.Agent.Worker.Scheduler` e `Project.Agent.Worker.Bpm` (`dotnet build`, 0 erros) e só então o job 16 passou a rodar. Isso corrige a premissa do gate ("build comprovado" só valia para o Worker BPM).
2. O Agent clássico como serviço exige elevação (`Start-Service` negado). Subir `SmartShareAgent.exe` como processo comum fez o clássico semear indicadores/CPP e corrigir `dt_termino`, mas ele terminou no meio do cálculo e deixou `STATUS_AGENT` 16 com `st_executando=1` (lock preso até o serviço ser parado). Baseline do clássico passou a ser a página `CalculoIndicador.aspx`.
3. Massa de CT-010 inválida na 1ª tentativa (feriado com ano 2026; o código casa feriado pelo ano 1904): refeita, ver CT-010.

## Resultado por cenário (Oracle)
| # | Cenário | Resultado | Evidência |
|---|---|---|---|
| CT-006 | Execução agendada no intervalo | PASSOU | Log `JOB_BPM\CalculoIndicador\20261111_CalculoIndicador.log`: jobs 41560 (11:49:13), 41608 (11:51:13), 41622 (11:52:13), 41641, 41656, 41684, 41709, 41733: disparo ~60 s (`Interval_Ms=60000`) |
| CT-007 | Tarefa em andamento respeita o período | PASSOU (paridade) | fluxo 2522 tarefa 2 (início ter 08:00): net8 50233 s às 11:57:13, clássico 50353 s às 11:59:13 (diferença = 120 s); análise independente: 10 h (ter) + 3 h 51 min 14 s (qua) = 49 874 s às 11:51:14, igual ao net8 daquele instante |
| CT-008 | Intervalo fora do período não conta | PASSOU (paridade) | fluxo 2523 (início seg 15:00): net8 61033 s, clássico 61153 s (120 s de diferença); inclui só 3 h (seg) + 10 h (ter) + qua |
| CT-009 | Limites do período (08:00 e 18:00) | PASSOU (paridade) | fluxos 2524 (08:00–18:00) e 2525 (07:59–18:01): 36000 s nos dois lados |
| CT-010 | Feriado geral e do calendário | PASSOU EM PARIDADE | Refeito após o double-check, com `DATA_DESTAQUE` no ano 1904 (convenção do código: net8 `CalculoIndicadorTempoUtilHelper.cs:13`, clássico `CalculoIndicadorBLL.cs:1227`): 101 = 1904-11-03 (cal 0), 102 = 1904-11-04 (cal 3); processo 541 usa calendário 3. Fluxo 2526, tarefa 2 de 02/11 09:00 a 05/11 09:00. net8: tarefa 36000 s, fluxo 36002 s. Clássico (página): 36000 / 36002. Idêntico e igual ao esperado (seg 9 h + qui 1 h; ter e qua descontadas). Antes (ano 2026) ambos davam 108000 s sem desconto, massa inválida. Evidência: `snapshot-net8-oracle-ct010-1904.txt`, `resultado-classico-oracle-ct010-1904.txt` (scratchpad). Limite: feriado geral e do calendário foram testados juntos |
| CT-011 | Paralelo classificado | PASSOU (paridade) na classificação | `CONTROLE_PASSO_PARALELO` do processo 621: 8 linhas idênticas (passos 2–9; 4 tp 1; 5 e 6 dentro; 7 tp 2) no net8 e no clássico. A soma de ramos no fim do paralelo foi exercitada depois, nas linhas do complemento (fluxo 2530). **Reexecutado após double-check:** DELETE autorizado das 8 linhas de `CONTROLE_PASSO_PARALELO` do processo 621 (backup em `bkp-ct014-ct011-antes.txt`); só o net8 rodou e recriou as 8 linhas idênticas às originais (passos 2–9; 4 tp 1; 5 e 6 dentro; 7 tp 2); clássico recriou as mesmas 8 |
| CT-012 | Prazo vira a meta | PASSOU (paridade) | fluxo 2527 com `dt_prazo` 12/11 12:00: `vl_tempoideal`=86400 s (24 h úteis) nos dois lados |
| CT-013 | Sem prazo usa tempo padrão | PASSOU COM RESSALVA | fluxo 2528: `vl_tempoideal`=0 nos dois lados (paridade), mas o "tempo padrão da atividade" esperado pelo mapa não existe para esta atividade (`PASSO_TEMPO` vazio), então a meta fica 0 |
| CT-014 | `dt_termino` do histórico corrigido | PASSOU (paridade, reexecutado após double-check) | UPDATE autorizado: `HISTORICO_TAREFA` 2486/tarefa 2 `DT_TERMINO`=NULL (original 2026-11-10 17:11:25). Rodado só o net8 (clássico em `ATIVO=1` pula): log `1 tarefa(s) do histórico tiveram a data de término corrigida` às 14:23:36 e `DT_TERMINO` voltou a 17:11:25. Repetido com o clássico (página): mesmo valor, 17:11:25. Evidência: `snapshot-net8-oracle-ct014-ct011cpp.txt`, `resultado-classico-oracle-ct014-ct011cpp.txt` |
| CT-021 | Duas instâncias | PASSOU COM RESSALVA | 2 processos Worker BPM por ~4 min (5 ciclos): cada Id de job iniciado 1 vez, 0 duplicidade em `TAREFA_INDICADOR`/`FLUXO_INDICADOR`, `JOB_BPM` com 1 linha ativa. Não há log da 2ª instância recusando o lock, então a disputa simultânea não foi provada |
| CT-022 | Execução agendada com cálculo em andamento é ignorada | PASSOU | 1º cálculo 11:49:13 → 11:50:42 (89 s > 60 s): às 11:50:13 o log registra "Job CalculoIndicador não possui itens ativos para execução" e nenhuma 2ª execução inicia |
| CT-023 | Após concluir, a próxima roda | PASSOU | job 41608 (programado 11:50:48, enfileirado após o fim às 11:50:42) executou às 11:51:13 |
| CT-029 | Log com totalizadores e tempo | PARCIAL: RF-04 PASSOU; RF-05 a esclarecer (inicialmente FALHOU; reclassificado após ler a US) | Log do net8: `Qtd1TarefaNaoVerificada=848, Qtd2=0, Qtd3TarefaEmExecucao=291, Qtd4=41, Qtd5=0`, conferidos por SQL (848 tarefas, 291 abertas, 41 histórico). **Não há valor de duração total** no log (só início e fim em linhas separadas, ex. 11:49:13 e 11:50:42); o clássico exibe `Tempo Total` (00:00:20.66 na página). Evidência: `Log\JOB_BPM\CalculoIndicador\20261111_CalculoIndicador.log`. **Esclarecimento (double-check):** texto da US #160818: 'gravar nos logs as informações de totalizadores... Armazenar o tempo de execução de todo processo.' O net8 loga início (`DataInicioProcessamento`) e fim (`DataTerminoProcessamento`) em linhas separadas, e a duração é derivável, mas **não há valor de duração registrado**. O 'Tempo Total' do clássico vem só da página `CalculoIndicador.aspx.cs` (Stopwatch); o Agent clássico (`Agent.cs` timerCalculoIndicador) também não loga duração. Classificação: divergência a esclarecer com o dev (severidade baixa), não paridade com o Agent clássico |

### Complemento (fluxos 2530 e 2531, avançados pela tela; net8 12:05:47–48, clássico 12:06:41–42, diferença 54 s)
| # | Cenário | Resultado | Evidência |
|---|---|---|---|
| CT-011 (ramos em andamento) / CT-017 | Paralelo com ramos em andamento; `FLUXO_INDICADOR` | PASSOU (paridade) | fluxo 2530 (621): tarefas 4 e 5 abertas (passos 5 e 6) (usuários 3 e 23). `TAREFA_INDICADOR`: finalizadas idênticas (4, 151, 0 s); em andamento 159 s (net8) × 213 s (clássico) = +54 s; `FLUXO_INDICADOR` idêntico: total 155, parcial 155, status 1. Limitação superada: o estado de um ramo concluído e a soma ao fim do paralelo foram exercitados depois (linhas seguintes) |
| CT-011 (um ramo concluído, outro aberto) | Fluxo 2530: tarefa 4 concluída por `qa.usuario2` (user 3) às 13:32:08 pela tela (Opções > Proximo); tarefa 5 (user 23) aberta | PASSOU (paridade) | net8 × clássico: tarefa 4 = 5339 s nos dois (12:03:09→13:32:08, confere); tarefa 5 aberta 5488 s × 5519 s (+31 s = intervalo entre os dois cálculos); tarefas 1–3 idênticas (4/151/0); `FLUXO_INDICADOR` 155/155/155 nos dois (tempo dos ramos não entra no total do fluxo enquanto o paralelo não termina). Evidência: `snapshot-net8-oracle-ct011-soma.txt`, `resultado-classico-oracle-ct011-soma.txt` |
| CT-011 (soma: ambos os ramos concluídos) | Fluxo 2530: tarefa 5 concluída por `qa.usuario3` (user 23) às 13:37:46; tarefa 6 (junção) concluída; tarefa 7 aberta | PASSOU (paridade) | net8 × clássico: tarefa 4 = 5339/5339; tarefa 5 = 5677/5677; junção (6) = 5677/5677 (= ramo mais longo); tarefa 7 aberta 96 s × 118 s (+22 s, intervalo entre cálculos); `FLUXO_INDICADOR` total 5832/5832 (= 155 + 5677: soma dos tempos antes do paralelo + ramo mais longo) e parcial 251 × 273 (+22 s). Evidência: `snapshot-net8-oracle-ct011-fim.txt`, `resultado-classico-oracle-ct011-fim.txt` (scratchpad) |
| CT-004 / CT-005 | Agent × flag `JOB_CONFIG.ATIVO` (Id 9) | PASSOU (Oracle) | Clássico: `ATIVO=1` pula o job (~10 min sem indicadores novos, `STATUS_AGENT` 16 intocado); `ATIVO=0` calcula (indicadores recriados, `STATUS_AGENT` 16 atualizado) — `Agent.cs:UsarNovoAgent` ~1855. net8 com binário atual e `ATIVO=0`: Scheduler e Worker no ar ~200 s (14:13:50–14:17:13), outros jobs seguiram rodando (logs de `InicioPublicacao`, `ExecutaSql` às 14:17:06) e **nenhuma** execução do `CalculoIndicador` (0 linhas novas no log, 0 linhas em `JOB_BPM` job 16). `ATIVO` restaurado para 1. Ressalva: tempos do clássico lidos na hora, sem arquivo de evidência salvo |
| CT-015 | Regressão bug #142303 (última atividade) | PASSOU (paridade) | fluxo 2531 (541) na atividade U3 "Papel 1 semana": net8 sem nenhuma linha `ERROR` nos logs do Worker BPM e do CalculoIndicador; valores = clássico (finalizadas 1/48/48 s; em andamento 45 s × 99 s = +54 s; `FLUXO_INDICADOR` total 97 nos dois, parcial 142 × 196) |
| CT-029 (paridade dos totalizadores) | Totalizadores net8 × clássico | PASSOU | mesmos números nos dois lados no ciclo de 2530/2531: `Qtd1=9, Qtd2=1, Qtd3=294, Qtd4=0, Qtd5=0`; clássico mostra também `Tempo Total 00:00:10.36` (net8 não registra a duração, ver CT-029 acima) |
| CT-026 | Erro numa tarefa não trava as outras | PASSOU (falha provocada por trigger) | Trigger temporário `QA160818_FALHA_TI` (BEFORE UPDATE em `TAREFA_INDICADOR`, só fluxo 2527, `ORA-20999`). Ciclo net8 14:50: 2527/tarefa 2 inalterado (59064, ultima verificação 14:24:24); 2522 e 2523 recalculados (59064→60622, 69864→71422); `Qtd3TarefaEmExecucao=293` processadas; erro logado com `cd_fluxo: 2527, cd_tarefa: 2` na região 'Tarefa em execução'. Evidência: `snapshot-pre-fase1.txt`, `snapshot-pos-fase1.txt`, `log-fase1-ct026.txt` |
| CT-027 | Erro logado completo | PASSOU (falha provocada) | Entrada `ERROR` do `CalculoIndicadorService` com mensagem + exceção completa (`OracleException`, `ORA-20999: QA US160818 falha provocada CT-026`, `ORA-06512`, `ORA-04088`, stack; 4520 caracteres, 21 linhas). Evidência: `log-fase1-ct026.txt` |
| CT-031 | Erros da rotina não afetam outros jobs | PASSOU (falha provocada) | Na mesma janela (14:49–14:51) os outros jobs do Worker e do Scheduler (`InicioPublicacao`, `ExecutaPassoAplicacao`, `AvancoTemporal`, `ExecutaWs`, `NotifyWf`, `ExecutaSql` etc.) continuaram rodando (logs atualizados 14:50:22–14:50:52). Erros em `ExecutaSql` (tabela de QA inexistente) e `NotifyWf` (e-mail de exemplo) são massa de outros ciclos: centenas de ocorrências fora da janela, sem relação com a falha provocada |
| CT-028 | Falha numa das 4 transações de semeadura aborta a execução | PASSOU (falha provocada) | `DELETE` da linha de `FLUXO_INDICADOR` do 2528 (backup em `bkp-fluxo-indicador-2528.txt`) + trigger `QA160818_FALHA_FI` (BEFORE INSERT, só fluxo 2528, `ORA-20998`). Ciclo net8 14:52: log `Erro na execução` com `ORA-20998`, **sem** linha `Qtd1..Qtd5`; `TAREFA_INDICADOR` dos 4 fluxos idêntico antes e depois (nenhuma região de cálculo rodou). Semeaduras 1 e 2 já tinham commitado (transações separadas, como no código). Evidência: `snapshot-pre-fase2.txt`, `snapshot-pos-fase2.txt`, `log-fase2-ct028.txt` |
| Observação (CT-026/028) | Reação do job ao erro | OBSERVAÇÃO (investigativa) | Erro em **uma** tarefa faz o job inteiro terminar com `Status: FalhaParaRepetir` (`Tentativas: 1`) e o Scheduler repete o ciclo (`Tentativas: 2` no ciclo seguinte; `JOB_CONFIG.MAX_TENTATIVAS=5`). O clássico só loga e segue. Confirmar com o dev se o retry do ciclo inteiro por erro de um item é intencional |
| CT-001 | Rotina aparece na tela de configuração | PASSOU NA API (tela do analytics não aberta) | Tela identificada na análise de falha: `job-config` do `smartshare-analytics`, alimentada por `JobConfigController.Get` (`JOB_CONFIG` com `STATUS_AGENT`). Subi a API net8 local (`dotnet run`, perfil `http`, porta 8081, Oracle `SHAREGUIZAO`) e chamei `GET /api/JobConfig`: 200, 30 rotinas, entre elas `id 9`, módulo `BPM`, job `CalculoIndicador`, `ativo=true`, `intervalMs=60000`; com `?Ativo=true&TextoLivre=Calculo` retorna só ela. Evidência: `evidencias/ct001-api-jobconfig.json`. **Não coberto:** a tela do analytics não foi aberta (exige login do Share 4 e o front no ar), então o passo 3 do mapa (o que a tela permite: visualizar, ativar/desativar, configurar; PM-05) segue sem resposta. A API também expõe `Put` (edição), o que indica que a tela permite alterar, sem confirmação do PM-05 |
| CT-003 | Configuração nos dois bancos | PARCIAL | A branch não tem `.sql` nem script de banco (diff vs `main` sem arquivos de banco): não há script a aplicar. A linha `JOB_CONFIG` Id 9 (Modulo 1, Job 16) existe nos dois bancos (criada pelo `JobConfigSeeder` do Scheduler: SQL Server `Ativo=0`/600000 ms, Oracle `Ativo=1`/60000 ms) e permaneceu **única** (count=1) após 5 reinícios do Scheduler no Oracle (idempotente). Passos no SQL Server: fora desta sessão (outra sessão). Logs do `CalculoIndicador` do net8 no Oracle: sem `ORA-` (outros jobs têm `ORA-` em logs de 03 e 06/11, fora do escopo) |

## Pendências
- **SQL Server (outra sessão):** repetir os cenários, corrigir a massa de feriado para o ano 1904 e reverter a massa de lá.
- **CT-001:** abrir a tela `job-config` do `smartshare-analytics` e decidir o PM-05 (o que a tela permite).
- **RF-05 e retry por erro:** respostas de PM/dev (ver Achados).
- **Cenários `HIPOTESE:` do mapa:** decisão de PM/dev (ver abaixo).

## Cenários não executados — e o motivo de cada um

**1. Não executados por serem `HIPOTESE:` no mapa** (a US e o dev não definem o comportamento esperado; o mapa restringe a execução automática; não é falta de ambiente nem de massa):
- **CT-002** — usuário sem permissão na tela de configuração: regra não definida na US.
- **CT-018** — passo novo "perde um ciclo": conflito PI-03 × CD-04, o dev precisa decidir qual vale.
- **CT-019** — processo sem calendário vinculado: regra não definida; além disso a premissa é impossível no schema (`PROCESSO.cd_calendario` NOT NULL nos dois bancos).
- **CT-020** — resultado equivalente ao clássico em massa maior: critério de equivalência depende do PM-09.
- **CT-024** — trava liberada após queda do processo: comportamento não descrito (DEV-03); clássico e net8 divergem por desenho (`st_executando` preso × lease).
- **CT-025** — execução ignorada gera log: a US não pede esse log (observado parcialmente no CT-022: net8 loga, clássico não — `Agent.cs:888-902`).
- **CT-030** — cliente com muitas tarefas: volume-limite [QTD_TAREFAS] não definido.

**2. Não executados por decisão do usuário (retirados do escopo):**
- **CT-016 (Oracle)** — sem processo com SubProcesso no Oracle. Segue no escopo do SQL Server.
- **CT-019** — também retirado por decisão do usuário (ver motivo acima).

**3. Mecanismo de falha — executados depois, com trigger temporário (autorizado):** CT-026, 027, 028 e 031 (ver tabela). O trigger foi removido ao final.

**4. Fora desta sessão:**
- **CT-032** — repetição no outro banco; no Oracle todos os cenários da lista foram rodados, menos o CT-026. Lado SQL Server na outra sessão.

Executados só em parte: CT-001 (passou na API; tela do analytics não aberta), CT-003 (PARCIAL, sem script de banco), CT-029 (RF-04 passou; RF-05 a esclarecer).

## Achados para análise de falha
Análise feita na etapa 03 (`03-analise-falha.md`): 4 achados, nenhum com evidência para abrir defeito.
- RF-05 (duração do processo não registrada como valor): INCONCLUSIVO, depende de PM-02/PM-03.
- Erro em 1 tarefa reagenda o job (`FalhaParaRepetir`): NÃO, comportamento deliberado (`CalculoIndicadorExecHandler.cs:79-83`); pergunta ao dev.
- `STATUS_AGENT` não atualizado pelo net8: NÃO, não é requisito; a listagem do net8 usa `JOB_CONFIG` (CT-001, ver tabela).
- Fluxo 2526 com datas futuras: NÃO, hipótese não confirmada (condição artificial; filtro igual ao do clássico).
- Ambiente: binário do Scheduler desatualizado (requer rebuild após `git pull`); não é defeito de produto.

## Estado final do ambiente (Oracle) — após a reversão
Verificado por leitura em 2026-11-11:
- Triggers `QA160818_FALHA_TI` e `QA160818_FALHA_FI`: removidos; restam os 4 `TRG_*` originais.
- `JOB_CONFIG` Id 9: `ATIVO=1` (original). Workers net8 parados.
- `DATA_DESTAQUE` da rodada (101, 102): removidos. `CONTROLE_PASSO_PARALELO` do processo 621: 0 linhas (original).
- `PROCESSO` 541 e 621: `cd_calendario=1` (original).
- Fluxos de teste 2522–2531: excluídos pela tela do Share (2522–2529 por `ExcluirFluxo.aspx`; 2530 e 2531 por "Minhas Solicitações > cancelar fluxo", logado como root).
- Processo rascunho 641 (`PROCESSO` e `VERSAO_PROCESSO`) e `CAL_QA` (`PERIODO` 101, `CALENDARIO` 3): removidos por SQL com backup (`evidencias/bkp-processo641-calqa.txt`). Resta só o `Calendário Padrão`.
- Não revertido (efeito normal do job): indicadores das demais tarefas em andamento, `STATUS_AGENT`, `JOB_BPM`, logs, binários recompilados do Scheduler e do Worker BPM. O serviço `SmartShareAgent` clássico segue em execução (decisão do usuário).
- Fora do escopo desta sessão: SQL Server (`CAL_QA` cd 5, `PERIODO` 3, feriados 2 e 3, processos 1030 e 10 com `cd_calendario=5`, `HISTORICO_TAREFA` 900787/2) — reverter na outra sessão. A massa de feriado lá também precisa do ano 1904.
- Segurança: senhas que apareceram na saída da sessão (root de teste, SQL Server, Oracle, `qa.usuario2`, `qa.usuario3`) devem ser rotacionadas. O arquivo `Variveis de Ambiente/` não está versionado (untracked); não commitar.

