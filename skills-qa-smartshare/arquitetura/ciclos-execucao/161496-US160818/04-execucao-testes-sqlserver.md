# Execução — Mapa de Testes #161491 Rotina - Calculo Indicador (US #160818) — rodada SQL Server

Evidências brutas em `evidencias/` (arquivos `sql-*.txt`). Rodada Oracle: `01-execucao-testes.md`.

**Status:** PARCIAL — todos os cenários executáveis do lado SQL Server passaram, inclusive CT-011 (soma dos ramos), CT-016 e CT-017, que ficaram bloqueados na 1ª passada (formulário do processo 10 não abre) e foram executados em 12/11 com processos novos (1039 criado pela tela e 1038 existente); `HIPOTESE:` do mapa não executados.
**Ambiente:** local não produtivo — Share `http://localhost:58149/SmartShare/` e net8 (`bin\Debug\net8.0`, commit `532fea37`, compilado 2026-11-11 11:47) no SQL Server `NOTE-74VQ\SQLEXPRESS` / `ShareGuizao` (Share e net8 trocados do Oracle para o SQL Server nesta rodada). RUN_ID `20261111-US160818-V02`.
**Gate:** `00-validacao-ambiente.md`, Atualização 10, LIBERADO PARA EXECUÇÃO (escopo SQL Server). Autorizações de escrita 1 a 6 concedidas pelo usuário, mais DELETE de indicadores dos fluxos de teste e trigger de atraso, cada um confirmado no momento.
**Método (PA-COMPARA adaptado):** sem snapshot/restore. net8 calculou primeiro (16:30:03); indicadores dos fluxos de teste apagados (autorizado); o clássico executou pela página `Workflow/CalculoIndicador.aspx` (16:39:34, mesma BLL do Agent clássico). Diferença entre os dois cálculos: 574 s, aplicada às tarefas em andamento.

## Resumo
- PASSOU (paridade ou comportamento esperado): CT-004, 006, 007, 008, 009, 010, 011, 012, 014, 015, 016, 017, 021, 022, 023, 026, 027, 028, 031 (CT-011 soma, CT-016 e CT-017 executados em 12/11, ver abaixo; o double-check sugere ressalva em CT-004, 014, 015, 021 e 031, ver "Divergências do double-check")
- PASSOU COM RESSALVA: CT-005 (net8 observado ~2 min sem executar), CT-013 (sem tempo padrão na atividade)
- PARCIAL: CT-001 (linha de `JOB_CONFIG` confirmada, tela não aberta), CT-003 (sem script de banco na branch), CT-029 (RF-04 passou; RF-05 a esclarecer)
- BLOQUEADO: nenhum (CT-011 soma, CT-016 e CT-017 destravados com o processo 1039 criado pela tela; o formulário do processo 10 segue sem abrir, fora do escopo desta US)
- Não executados: HIPOTESE do mapa (CT-002, 018, 020, 024, 025, 030), CT-019 (retirado do escopo: `PROCESSO.cd_calendario` NOT NULL)
- CT-032 (paridade nos dois bancos): lado SQL Server coberto por esta rodada (CT-004, 005, 007, 010, 011, 012, 014, 021, 026 iguais ao Oracle)

## Detalhe por cenário (SQL Server)
| # | Cenário | Resultado | Evidência |
|---|---|---|---|
| CT-004 | Ativar no net8: só ele calcula | PASSOU | `JOB_CONFIG` Id 9 `Ativo=1`: net8 calcula a cada ~60 s (`sql-log-net8-calculoindicador-1.txt`); `STATUS_AGENT` 16 do clássico ficou em 16:19:18 até 16:47 (próxima execução prevista 16:29 não ocorreu) |
| CT-005 | Desativar no net8: o clássico volta a calcular | PASSOU COM RESSALVA | `Ativo=0` às 16:47:47: o clássico (serviço `SmartShareAgent`) calculou às 16:49:18 (`STATUS_AGENT` e `dt_ultimaverificacao` 16:49:19) e o net8 não registrou nenhum "Iniciando" (`sql-ct005-resultado.txt`). Ressalva: janela de observação do net8 de 2 min |
| CT-006 | Execução agendada | PASSOU | jobs de 16:26 a 16:32, um por minuto (`Interval_Ms=60000`) |
| CT-007 | Tarefa em andamento respeita o período | PASSOU (paridade) | fluxo 900799, início ter 08:00: net8 66600 s, clássico 67174 s (+574 s); cálculo independente 10 h + 8,5 h = 66600 s |
| CT-008 | Intervalo fora do período | PASSOU (paridade) | fluxo 900800, início seg 15:00: net8 77400, clássico 77974 (+574) |
| CT-009 | Limites 08:00/18:00 | PASSOU (paridade) | fluxos 900801 (08:00–18:00) e 900802 (07:59–18:01): 36000 s nos dois lados |
| CT-010 | Feriado geral e do calendário | PASSOU (paridade) | fluxo 900803, 02/11 09:00 a 05/11 09:00, feriados 1904-11-03 (cal 0) e 1904-11-04 (CAL_QA): 36000 s nos dois lados. Os dois feriados foram testados juntos |
| CT-012 | Prazo vira a meta | PASSOU (paridade) | fluxo 900804, `dt_prazo` 12/11 12:00: `vl_tempoideal` 20162 s nos dois lados |
| CT-013 | Sem prazo usa tempo padrão | PASSOU COM RESSALVA | fluxo 900805: `vl_tempoideal` 0 nos dois lados; `PASSO_TEMPO` do processo 1030 sem linhas, então o "tempo padrão" do mapa não existe para esta atividade |
| CT-014 | Histórico sem término corrigido | PASSOU (paridade) | `HISTORICO_TAREFA` 900787/2 `dt_termino=NULL`: net8 log "1 tarefa(s) do histórico tiveram a data de término corrigida" e valor 2026-11-10 16:48:27; repetido com o clássico, mesmo valor (`sql-ct014-net8-apos.txt`, `sql-ct014-classico-apos.txt`) |
| CT-015 | Regressão bug #142303 | PASSOU | fluxo 900812 na última atividade (U3 Papel 1 semana): net8 sem nenhuma linha `ERROR`; tarefa 4 = 76 s no net8 contra 10 s do clássico 66 s antes (`sql-ct015-net8-apos.txt`). O clássico semeou este fluxo primeiro (ordem invertida) |
| CT-021 | Duas instâncias | PASSOU | 2 processos Worker BPM por ~3 min: cada Id (61123, 61133) iniciado uma vez; 0 duplicidade em `TAREFA_INDICADOR` e `FLUXO_INDICADOR`; a 2ª instância registrou "não possui itens ativos" enquanto a 1ª calculava (`sql-ct021-log-2-instancias.txt`) |
| CT-022 | Disparo com cálculo em andamento é ignorado | PASSOU (ciclo alongado por trigger `WAITFOR`) | ciclo 61116 de 17:09:49 a 17:11:02 (73 s); disparo de 17:10:49 registrou "não possui itens ativos" e não iniciou 2ª execução (`sql-ct022-ct023-log.txt`) |
| CT-023 | Depois de concluir, a próxima roda | PASSOU | job 61123 iniciou às 17:11:24, depois do fim do 61116 |
| CT-026 | Erro numa tarefa não trava as outras | PASSOU (falha provocada) | trigger temporário `QA160818_FALHA_TI` (AFTER UPDATE, só fluxo 900805): fluxo 900805 inalterado (1029 s, última verificação 16:41:09), demais recalculados (16:43:04); erro logado com `cd_fluxo: 900805, cd_tarefa: 2` (`sql-snapshot-pre/pos-ct026.txt`) |
| CT-027 | Erro logado completo | PASSOU | exceção `SqlException` com mensagem e stack completos, 2501 caracteres (`sql-log-ct026-erro-completo.txt`) |
| CT-028 | Falha na semeadura aborta a execução | PASSOU (falha provocada) | `FLUXO_INDICADOR` do 900806 apagado + trigger `QA160818_FALHA_FI` (AFTER INSERT): log "Erro na execução" sem linha `Qtd1..Qtd5`; `TAREFA_INDICADOR` idêntica antes e depois (`sql-log-ct028-erro.txt`) |
| CT-031 | Erros não afetam outros jobs | PASSOU | `NotifyWf`, `ExecutaPassoAplicacao`, `ExcluiFluxoEmSolicitacao` e `AvancoTemporal` rodaram às 16:43 junto do erro (`sql-ct031-outros-jobs.txt`) |
| CT-011 | Paralelo classificado | PASSOU (paridade) na classificação | `CONTROLE_PASSO_PARALELO` do processo 10: 34 linhas idênticas no net8 e no clássico (`sql-ct011-cpp-net8.txt` × `sql-ct011-cpp-classico.txt`). A soma dos ramos foi exercitada depois, nas três linhas seguintes |
| CT-017 / CT-011 (ramos em andamento) | Paralelo com 2 ramos abertos; `FLUXO_INDICADOR` | PASSOU (paridade) | fluxo 900814 (processo 1038, calendário 1, executor `root`), 2 ramos abertos às 08:20: tarefas finalizadas 0/0/0 nos dois lados; ramos abertos 1227 s (net8, 08:20:27) × 1294 s (clássico, 08:21:34): +67 s = intervalo entre os cálculos; `FLUXO_INDICADOR` 0/0/0 nos dois lados, sem incremento aplicado pelo ramo aberto (`sql-novo-rodada1-net8.txt`, `sql-novo-rodada1-classico.txt`) |
| CT-011 (um ramo concluído, outro aberto) | B1 concluído pela tela às 08:23:11 | PASSOU (paridade) | B1 = 1391 s nos dois lados (08:00 a 08:23:11, confere); B2 aberto 1478 × 1496 s (+18 s = intervalo); `FLUXO_INDICADOR` total 0 e parcial 1478 × 1496 nos dois lados (`sql-novo-rodada2-net8.txt`, `sql-novo-rodada2-classico.txt`) |
| CT-011 (soma: ambos os ramos concluídos) | B2 concluído às 08:25:53, junção feita, C aberta | PASSOU (paridade) | B1 = 1391 e B2 = 1553 s nos dois lados; `FLUXO_INDICADOR` total 1553 nos dois lados (= ramo mais longo) e parcial 83 × 101 s (+18 s = intervalo) (`sql-novo-rodada3-net8.txt`, `sql-novo-rodada3-classico.txt`) |
| CT-016 | SubProcesso mantido como no clássico | PASSOU (paridade) | processo 1039 (criado pela tela, passo 4 = SubProcesso apontando para o 1038). Fluxo 900817 concluído sem nenhum cálculo prévio: net8 gravou a tarefa de SubProcesso em `HISTORICO_TAREFA_INDICADOR` com valores zerados (`id_statustempo` 0, `dt_ultimaverificacao` NULL, `st_somado` 0) e as demais tarefas verificadas; o clássico no fluxo equivalente 900819 gravou o mesmo padrão. 2ª execução: net8 `Qtd4=1, Qtd5=1` e clássico `Qtd4=2, Qtd5=1` (cada lado reprocessou as tarefas de SubProcesso dos fluxos que existiam, sem persistir): a região "finalizada" (fluxo 900815, tarefa 3 com 1654 s de 08:27:34) ficou inalterada nos dois lados (`sql-ct016-*.txt`) |
| CT-029 | Totalizadores e tempo | PARCIAL | RF-04: `Qtd1=26` confere com +26 em `TAREFA_INDICADOR` (999 → 1025) e os totalizadores aparecem em todo ciclo. RF-05: o log não traz valor de duração, só início e fim em linhas separadas (mesma divergência do Oracle) |
| CT-001 | Rotina na tela de configuração | PARCIAL | `JOB_CONFIG` Id 9 (Modulo 1, Job 16) presente. Tela `job-config` do analytics não aberta (já passou na API no Oracle) |
| CT-003 | Configuração nos dois bancos | PARCIAL | a branch não tem script de banco; `JOB_CONFIG` Id 9 foi criada pelo Scheduler (`Ativo=0`, 600000 ms) e permaneceu única (count 1) depois de 5 reinícios do Scheduler |

## Steps que pararam por ação de alto risco
Nenhum.

## Cenários BLOQUEADOS
Nenhum no fim da rodada. **CT-016, CT-017 e a soma dos ramos do CT-011 foram destravados em 12/11** por decisão do usuário de criar um processo funcional. Ver "Execução complementar de 12/11" mais abaixo. Registro da 1ª tentativa, que ficou bloqueada:

- **CT-016, CT-017 e a soma dos ramos do CT-011** (processo 10 `Teste Agent BPM - Avanco Temporal`): o formulário da 1ª atividade (`FormularioPadrao20.aspx`) mostra "O parâmetro iderro está vazio" e o fluxo 900813 não avança pela tela. Tentativas: iniciar o fluxo, associar a atividade (ok, `cd_usuario=1`), clicar Avançar e confirmar duas vezes (a tarefa 2 continuou aberta). Os ramos do paralelo (63) são passos automáticos de SQL, WS e Aplicação, que dependem de conexões e configurações não validadas neste ambiente. Avançar por `UPDATE` seria condição artificial sem autorização. Para liberar: corrigir o formulário do processo 10 ou indicar outro processo com paralelo e ramos de usuário no SQL Server.

## Cenários não executados e o motivo
**1. `HIPOTESE:` do mapa** (a US e o dev não definem o comportamento): CT-002, CT-018, CT-020, CT-024, CT-025, CT-030.
**2. Retirado do escopo por decisão do usuário:** CT-019 (premissa impossível: `PROCESSO.cd_calendario` NOT NULL) e CT-016 no Oracle.
**3. Bloqueados por ambiente:** nenhum no fim (CT-016, CT-017 e soma do CT-011 executados em 12/11).

## Achados
- Observação (mesma do Oracle): erro em uma tarefa faz o job terminar `FalhaParaRepetir` e o Scheduler repete o ciclo. Confirmar com o dev se é intencional.
- Observação: `WAITFOR` de 90 s no trigger estourou o timeout de 30 s do comando e o net8 registrou o timeout como erro de região; só um atraso de 12 s por linha alongou o ciclo sem erro.
- RF-05 (duração do processo): ver CT-029, depende de PM-02/PM-03.

## Pendências e instruções para retomada
1. **Fluxo de teste 900812 ainda existe** (`FLUXO`, 4 `TAREFA`, 4 `TAREFA_INDICADOR`): `ExcluirFluxo.aspx?cdF=900812&cdU=1&cdT=4` não removeu. Cancelar por "Minhas Solicitações" no Share como `root`, conferindo `hdCdFluxo` antes de confirmar (QA-KB-20261111-002).
2. **Share e net8 seguem apontando para o SQL Server.** Para voltar ao Oracle, restaurar os backups do estado Oracle em `scratchpad\bkp-config-sql` (`Web.config` e `appsettings.json` da API, Scheduler e Worker BPM) ou refazer o `webconfig.aspx`.
3. **CT-001:** abrir a tela `job-config` do `smartshare-analytics` e decidir o PM-05.
4. **CT-011 (soma), CT-016, CT-017:** executados em 12/11 (seção abaixo). Pendente só a decisão do PM-08 (o esperado de CT-016 e CT-017 muda se o PM decidir corrigir o comportamento herdado).
5. **RF-05 e retry por erro:** respostas de PM/dev.
6. **Segurança:** a senha de teste do `root` apareceu na saída desta sessão (falha na máscara ao inspecionar o arquivo de variáveis); rotacionar, junto com as já listadas no ciclo. O arquivo `Variveis de Ambiente/` não está versionado; não commitar.

## Estado final do ambiente (SQL Server) — após a reversão
Verificado por leitura em 2026-11-11 17:2x:
- Triggers `QA160818_*`: todos removidos (`sys.triggers` sem linhas).
- `JOB_CONFIG` Id 9: `Ativo=0`, `Interval_Ms=600000` (original), 1 linha. Workers net8 parados; `SmartShareAgent` clássico segue rodando.
- `DATA_DESTAQUE` cd 2 e 3: voltaram a 2026-11-16/17 (valores originais de antes desta rodada; o ano certo para o código é 1904).
- `CONTROLE_PASSO_PARALELO` do processo 10: 0 linhas (original).
- `HISTORICO_TAREFA` 900787/2: `dt_termino` 2026-11-10 16:48:27 (original).
- Fluxos 900799 a 900806 e 900813 excluídos pela tela (`ExcluirFluxo.aspx`), com tarefas e indicadores. Fluxos 900807 a 900811 foram criados pelo job `InicioTemporal` do net8 em outros processos e não foram tocados.
- Mantidos do ciclo anterior, fora desta reversão: `CALENDARIO` cd 5 `CAL_QA`, `PERIODO` cd 3, `PROCESSO` 1030 e 10 com `cd_calendario=5`.
- Não revertido (efeito normal do job): indicadores das demais tarefas, `STATUS_AGENT`, `JOB_BPM`, logs.
- **Após a execução complementar de 12/11 (08:40):** `JOB_CONFIG` Id 9 de volta a `Ativo=0`, `Interval_Ms=600000`; Scheduler e Worker BPM do net8 parados; nenhum fluxo de teste aberto (900814 a 900820 todos concluídos, com histórico em `HISTORICO_*`); linha `JOB_BPM` 61143 apagada (o Scheduler recriou a do ciclo seguinte). **Mantido de propósito:** processo 1039 "QA-160818 SubProcesso" (publicado, pasta 5) para reutilização; os fluxos concluídos e seus históricos não foram removidos (fluxo concluído não é excluível por `ExcluirFluxo`).

## Execução complementar de 12/11 — CT-011 (soma), CT-016 e CT-017
**Motivo:** na 1ª passada os três ficaram bloqueados porque o formulário do processo 10 não abre. O usuário pediu para criar um processo funcional.

**Processo criado pela tela (sem INSERT):** `PROCESSO` 1039 "QA-160818 SubProcesso", pasta 5, calendário CAL_QA (cd 5), vínculo "Geral", papéis "Papel Default". Fluxo: Início, A Inicial (usuário `root`, sem formulário, opção "Proximo"), Sub-Processo (passo 4, tipo 8, aponta para o processo 1038), C Final (usuário `root`, opção "Proximo"), Fim. Desenhado no editor gráfico (mxGraph), com o código do processo do Sub-Processo definido por script nos atributos da célula (`zoomh_Processo`), porque o editor não abre diálogo ao clicar duas vezes na forma. Replicação de anexo e formulário do Sub-Processo = "Nenhum". Publicado pelo "Liberar Processo" (status 3, versão 1). Para CT-011 e CT-017 usou-se o processo 1038 já existente (paralelo com 2 ramos de usuário, executor `root`, calendário 1, sem formulário).

**Método:** igual ao da rodada: net8 calcula primeiro, resultado congelado, indicadores dos fluxos apagados, clássico calcula pela página `Workflow/CalculoIndicador.aspx`. Tarefas em andamento comparadas pelo intervalo entre os dois cálculos. O cálculo só foi feito depois das 08:00 (os calendários 1 e 5 começam às 08:00; antes disso todo valor seria 0).

**Escritas autorizadas pelo usuário nesta etapa (todas conferidas):** `UPDATE JOB_CONFIG` Id 9 para `Ativo=1, Interval_Ms=60000` e de volta a `Ativo=0, 600000`; `DELETE` de `TAREFA_INDICADOR` e `FLUXO_INDICADOR` dos fluxos 900814, 900815 e 900816 (10 e 3 linhas na rodada 1; o mesmo na 2 e na 3); `DELETE FROM JOB_BPM WHERE Id=61143` (1 linha, job 16 pendente desde 11/11 17:14).

**Fluxos criados pela tela:** 900814 (processo 1038), 900815 e 900817 e 900819 (processo 1039) e os filhos 900816, 900818 e 900820 (processo 1038). Todos concluídos pela tela até o fim.

| # | Rodada | Hora do net8 | Hora do clássico | Resultado |
|---|---|---|---|---|
| 1 | CT-017: 2 ramos abertos (900814); SubProcesso aberto (900815/900816) | 08:20:27 | 08:21:34 | paridade (+67 s nas tarefas em andamento = intervalo) |
| 2 | CT-011: B1 concluído às 08:23:11 | 08:24:38 | 08:24:56 | paridade (B1 1391 s; B2 aberto +18 s) |
| 3 | CT-011 soma: B2 concluído às 08:25:53 | 08:27:15 | 08:27:34 | paridade (B1 1391, B2 1553, total do fluxo 1553 = ramo mais longo) |
| 4 | CT-016: fluxos concluídos sem cálculo prévio (900817/900818) | 08:34:07 e 08:35:4x | 08:38 e 08:39 (fluxo equivalente 900819/900820) | mesmo padrão de persistência e de reprocessamento |

**Observações sobre o ambiente (aprendizados):**
- O Worker BPM lê o `JOB_CONFIG` na partida. Subido com `Ativo=0` ele não registra o job `CalculoIndicador`, e mudar a flag depois não adianta: é preciso reiniciar os Workers. Nesta etapa a mudança só valeu depois de reiniciar.
- Uma linha de `JOB_BPM` pendente (job 16, Id 61143) impede o Scheduler de agendar novo ciclo ("já existe execução pendente ou em andamento"), e o Worker não a consome. Foi preciso apagá-la (autorizado).
- `HISTORICO_TAREFA_INDICADOR` e `HISTORICO_FLUXO_INDICADOR` guardam os indicadores dos fluxos terminados. `TAREFA_INDICADOR` e `FLUXO_INDICADOR` ficam vazias para o fluxo depois que ele termina.

**Ressalvas desta execução:**
- CT-016: net8 (fluxo 900817) e clássico (fluxo 900819) não rodaram sobre a mesma entrada; foram fluxos com a mesma forma, e os tempos reais (54 s × 41 s no `HISTORICO_FLUXO_INDICADOR`) diferem porque os fluxos foram conduzidos à mão. A comparação vale para a estrutura (SubProcesso zerado, demais tarefas verificadas, reprocessamento sem persistir), não para os valores. A região "finalizada" ficou coberta só pelo fluxo 900815 (tarefa de SubProcesso com valor de 08:27:34 inalterada depois da 1ª e da 2ª execução nos dois lados).
- O esperado de CT-016 e CT-017 muda se o PM-08 decidir corrigir o comportamento herdado do clássico.
- O formulário do processo 10 segue sem abrir; não foi investigado (fora do escopo da US).

## Divergências do double-check
Sub-agente independente (Sonnet) leu só as evidências em `evidencias/sql-*.txt`. Sem divergência de classificação em CT-006, 007, 008, 009, 010, 011, 012, 013, 022, 023, 026/027, 028 e 005 (CT-005 mantém a ressalva). As classificações originais ficam como estão; a decisão sobre as divergências abaixo é do usuário.

| # | Classificação original | Sugestão do sub-agente | Motivo | Tratamento |
|---|---|---|---|---|
| CT-014 | PASSOU | PASSOU COM RESSALVA | o log "1 tarefa(s)... corrigida" não estava nos arquivos de evidência | evidência acrescentada depois: `sql-ct014-log-net8-correcao.txt` (16:40:59, extraído do log do Worker). Valor final nos dois lados em `sql-ct014-net8-apos.txt` e `sql-ct014-classico-apos.txt`. O estado NULL antes do clássico só está no relatório |
| CT-015 | PASSOU | PASSOU COM RESSALVA | arquivo sem prova de "sem ERROR" e sem o valor de 10 s do clássico | a contagem de `ERROR` no log do net8 entre 16:49 e 16:5x foi 0 (conferida de novo); o valor do clássico (10 s às 16:49:19) só consta no relatório. A ordem foi invertida (clássico semeou primeiro) |
| CT-031 | PASSOU | PASSOU COM RESSALVA | `sql-ct031-outros-jobs.txt` traz só o último timestamp de cada job, sem janela; nenhum registra execução depois do erro das 16:43:34 | prova concorrência só até 16:43:11 (NotifyWf); `InicioTemporal` e `ExecutaSql` sem prova |
| CT-004 | PASSOU | PASSOU COM RESSALVA | a leitura de `STATUS_AGENT` = 16:19:18 até 16:47 não está em arquivo de evidência | só no relatório; não comprova que o clássico estava ativo entre 16:29 e 16:47 (o serviço estava Running) |
| CT-021 | PASSOU | PASSOU COM RESSALVA | o log só mostra Ids 61123 e 61133 com `instância: 1`; nenhuma linha da instância 2 iniciando job | ausência de duplicidade compatível; a execução concorrente das duas instâncias não foi provada por log (mesma ressalva do Oracle) |

Observação (sem mudar classificação): em CT-007 e CT-008 o net8 usou 16:30:00 em vez de 16:30:03.967 (diferença real 570 s, não 574 s); tolerância de ~4 s, sem impacto na paridade. `sql-log-ct026-erro-completo.txt` termina cortado (stack parcial; a mensagem e `cd_fluxo`/`cd_tarefa` estão completos).
