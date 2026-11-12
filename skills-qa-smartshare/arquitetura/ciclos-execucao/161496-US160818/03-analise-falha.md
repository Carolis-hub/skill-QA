# Etapa 03 — analise-falha — #160818 Rotina - Calculo Indicador

- **Skill e argumentos:** `/arquitetura-analise-falha #160818` com 4 achados da etapa 01 (`01-execucao-testes.md`).
- **Data:** 2026-11-11. **Escreveu no Azure DevOps:** Não (somente leitura; busca de bugs).
- **Fontes lidas:** US #160818 (descrição), mapa #161491 (RF-04/05/06, CT-001, 026, 028, 029), código net8 (`CalculoIndicadorService.cs`, `CalculoIndicadorExecHandler.cs`, `BpmExecJob.cs`, `JobConfigRepository.cs`, `JobConfigController.cs`) e clássico (`CalculoIndicadorDAL.cs`, `Agent.cs`), evidências do ciclo.
- **Aprendizados consultados:** QA-KB-20261111-001 a 004 (registrados na etapa 01); sem aplicação direta além do contexto.
- **Rótulos:** `lida-no-codigo` = lido no fonte; `vista-no-log` e `vista-no-banco` = observada na execução; `lacuna` = sem evidência.

## Resumo

| # | Achado | Veredito |
|---|---|---|
| 1 | CT-029 / RF-05: duração do processo não registrada como valor | INCONCLUSIVO |
| 2 | Erro em 1 tarefa faz o job terminar `FalhaParaRepetir` e repetir o ciclo | NÃO (comportamento deliberado; pergunta ao dev) |
| 3 | net8 não atualiza `STATUS_AGENT` / "Consulta de Status Agent" | NÃO (não é requisito); revela a tela do CT-001 |
| 4 | Fluxo 2526 com datas futuras: net8 cresce por ciclo × clássico 108000 s | NÃO — hipótese não confirmada (condição artificial) |

Nenhum achado tem evidência suficiente para abrir defeito agora.

---

## Achado 1 — RF-05: tempo de execução do processo

**O que era esperado.** US #160818: "Armazenar o tempo de execução de todo processo" e "gravar nos logs as informações de totalizadores". Mapa CT-029 passos 3–4: "o sistema deve registrar o tempo total"; o mapa marca "formato e destino finais dependem de PM-02 e PM-03".

**O que aconteceu.** O log do net8 traz os totalizadores (`Qtd1..Qtd5`) e as linhas "Iniciando processamento" (`DataInicioProcessamento`) e "executado com sucesso" (`DataTerminoProcessamento`) em registros separados; não há campo ou linha com a duração calculada (`vista-no-log`, `evidencias/log-fase1-ct026.txt`). `CalculoIndicadorExecHandler.cs:70-77` loga só as quantidades; não há `Stopwatch` no handler (`lida-no-codigo`). O Agent clássico também não loga duração (`Agent.cs`, timerCalculoIndicador); o "Tempo Total" só aparece na página `CalculoIndicador.aspx.cs`.

**Componente.** `CalculoIndicadorExecHandler` (Worker BPM); camada WORKER / OBSERVABILIDADE.

**Classificação.** Sintoma: FUNCIONAL ou N/A, conforme PM-02/PM-03. Camada: Worker / Observabilidade. Causa provável: duração não implementada como valor registrado; início e fim existem e permitem derivar a duração. `Não tenho evidência suficiente.` para dizer se isso atende o RF-05.

**Já existia antes?** Busca de bugs por "Calculo Indicador Agent": só o Bug #142303 (cálculo na última atividade, Done), sem relação. Não há bug anterior sobre duração.

**Relação com a alteração atual.** Sim: o handler faz parte da migração (PRs #29630 e #29631).

**Veredito: INCONCLUSIVO.** Há indício, mas o RF-05 não define onde nem em que formato armazenar. Para virar defeito falta a resposta de PM-02/PM-03 (ou do dev) sobre se "armazenar" exige um valor de duração no log ou em tabela, e em que formato.

## Achado 2 — erro em 1 tarefa reagenda o job inteiro

**O que era esperado.** US: "Caso ocorra algum erro, logar o erro completo que ocorrer" (RF-06). CT-026: erro numa tarefa não trava as outras; CT-027: erro logado completo. Não há esperado sobre o status do job nem sobre retry.

**O que aconteceu.** Com falha provocada por trigger (CT-026/028): erro logado completo, demais itens processados, e o job terminou `Status: FalhaParaRepetir` com `Tentativas: 1`; o ciclo seguinte repetiu com `Tentativas: 2` (`vista-no-log`, `evidencias/log-fase1-ct026.txt` e `log-fase2-ct028.txt`). No código isso é explícito: `CalculoIndicadorExecHandler.cs:79-83` (`if (resultado.DeuErro) { Sucesso = false; Reagendar = true; }`) e `BpmExecJob.cs:592-624` (`FalhaParaRepetir` até `maxTentativas`, depois `Envenenado`) (`lida-no-codigo`).

**Componente.** `CalculoIndicadorExecHandler`, `BpmExecJob`, `JobResiliencePolicy`. Camada: WORKER / SCHEDULER.

**Classificação.** Sintoma: TÉCNICO (observação). Camada: Worker / Scheduler. Causa provável: decisão de projeto do dev (reagendar quando `DeuErro`).

**Já existia antes?** Não encontrado bug relacionado.

**Relação com a alteração atual.** Sim, é código novo da migração.

**Veredito: NÃO — comportamento deliberado, sem esperado contrário.** Perguntas para o dev: o retry do ciclo inteiro por erro de um item é intencional? Em erro persistente de um item, o job chega a `Envenenado` após `MAX_TENTATIVAS` (5)? O segundo ponto não foi testado: `Não tenho evidência suficiente.` O erro foi provocado por trigger (artifício); uma causa real equivalente (deadlock, timeout) não foi reproduzida.

## Achado 3 — `STATUS_AGENT` e "Consulta de Status Agent"

**O que era esperado.** RF-02: "a rotina aparece na listagem da tela de configuração do SmartShare". Nenhuma fonte exige que o net8 atualize `STATUS_AGENT`.

**O que aconteceu.** O net8 não atualiza `STATUS_AGENT` 16 (`DT_ULTIMA_VERIFICACAO`, `ST_EXECUTANDO`) durante a execução; quem atualizou foi o clássico (`vista-no-banco`). A tela clássica "Consulta de Status Agent" (`Consulta/StatusAgent.aspx`) lista o job do clássico.

**Descoberta (muda o CT-001).** A listagem do net8 é outra: `JobConfigController` (`Get`) chama `JobConfigRepository.cs:97-98` (`FROM JOB_CONFIG J LEFT JOIN STATUS_AGENT S ON J.Job = S.cd_status_agent`; o nome vem de `ds_status_agent`), consumida pela tela `job-config` do `smartshare-analytics` (`pages/job-config/job-config-list`, rota `job-config.routes.ts`) (`lida-no-codigo`). Como `JOB_CONFIG` Id 9 e `STATUS_AGENT` 16 existem nos dois bancos, a listagem deve mostrar "CalculoIndicador". Isso **não foi visto na tela**.

**Componente.** `JobConfigRepository` e `JobConfigController` (API); `smartshare-analytics` (UI). Camada: API / UI.

**Classificação.** Sintoma: N/A (não é falha). Causa: o net8 usa `JOB_CONFIG` e `JOB_BPM` como estado de execução, não o `STATUS_AGENT` (`lida-no-codigo`).

**Já existia antes?** Não aplicável.

**Veredito: NÃO — não é requisito nem defeito.** O CT-001 (INCONCLUSIVO) agora tem caminho de execução: abrir a tela `job-config` do `smartshare-analytics` (ou fazer `GET` no `JobConfigController`) e ver "CalculoIndicador" listado. Ainda não executado.

## Achado 4 — fluxo 2526 com datas futuras

**O que era esperado.** CT-010 esperava paridade net8 × clássico. A massa usou tarefa com `dt_termino` no futuro (13→18/11, "hoje" 11/11).

**O que aconteceu.** net8: `vl_tempototal` da tarefa em 447565 s no 1º ciclo e crescendo a cada ciclo (1295300 s no 7º). Clássico (página, 1 execução): 108000 s (`vista-no-banco`, `evidencias/resultado-net8-oracle-1.txt`, `snapshot-net8-oracle-congelado.txt`, `resultado-classico-oracle-pagina.txt`).

**Causa provável (lida no código).** A região "Tarefa recém-finalizada" seleciona `T.dt_termino >= TI.dt_ultimaverificacao AND TI.dt_ultimaverificacao IS NOT NULL` (net8 `CalculoIndicadorRepository.cs:66`; clássico `CalculoIndicadorDAL.cs:43`, mesmo filtro). Com `dt_termino` no futuro a tarefa continua sendo selecionada a cada ciclo, e `ProcessarTarefaFinalizada` soma `RetTempoValidoPeriodo(dt_ultimaverificacao, dt_termino)` e grava `dt_ultimaverificacao = dataAtual` (`CalculoIndicadorService.cs:297-325`): cada ciclo soma de novo o trecho até o término futuro. O clássico rodou 1 vez pela página e o net8 rodou 7 vezes, então a diferença vem do número de ciclos, não de regra diferente. Que o clássico como Agent acumularia igual é inferência do código, não foi executado.

**Componente.** `CalculoIndicadorService.ProcessarTarefaFinalizada`; camada WORKER / BANCO.

**Classificação.** Sintoma: TÉCNICO, com causa na massa (estado impossível: tarefa terminada no futuro). Camada: Worker.

**Já existia antes?** Não encontrado.

**Relação com a alteração atual.** O filtro é herança do clássico; sem divergência de regra.

**Veredito: NÃO — hipótese não confirmada.** A condição foi criada por SQL e não há caminho suportado que gere `dt_termino` futuro. Falta demonstrar um fluxo real com término no futuro, ou confirmar com fonte que o produto deve tratar essa condição. O CT-010 refeito com datas no passado deu paridade (36000 s nos dois lados).

---

## Pendências desta etapa

- Dev/PM: PM-02/PM-03 (formato e destino do tempo de execução, RF-05); intenção do retry por `DeuErro` e do estado `Envenenado`.
- QA: executar o CT-001 na tela `job-config` do `smartshare-analytics` (ou via `JobConfigController`).
- Nenhum defeito a abrir agora; nenhum encadeamento para `/arquitetura-gerar-defeito`.

**Atualização (mesma data):** o CT-001 foi executado pela API: `GET /api/JobConfig` listou `CalculoIndicador` (id 9, BPM, ativo). A hipótese lida no código está confirmada na camada de API; a tela do analytics não foi aberta.
