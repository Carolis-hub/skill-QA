# Relatório final de testes — US 160823 "Rotina - Inicio Desassociar Automático"

- **Task de testes:** 161495 (mapa de testes no card 161490, 30 cenários)
- **QA:** guilherme.borges@selbetti.com.br
- **Período:** 04/11/2026 a 06/11/2026
- **Código testado:** net8, branch `feature/US160823-migracao-job-inicio-desassociar-automatico`, build de `ab180c0f` (05/11 14:42); Agent clássico instalado (23/10) e Agent clássico da branch do PR 29228 (commit `4b2b504ec`, build de 06/11).
- **Bancos:** Oracle (`SHAREGUIZAO`) e SQL Server 2019 Express, os dois com Scheduler, Worker BPM e Share clássico apontados para o mesmo banco.

## Veredito

**A rotina migrada funciona nos dois bancos, com uma falha: o cenário #22 (valor inicial nulo) derruba a desassociação.** O defeito é o **Bug #166161**, sem correção no código até esta data. Os demais cenários executados passaram, alguns com ressalva. Recomenda-se não liberar a US até a correção do Bug e a reexecução descrita no fim deste relatório.

## Resultado por banco (30 cenários = 26 executáveis + 4 hipóteses)

| Resultado | Oracle | SQL Server |
|---|---|---|
| Passou | 18: #1, #2, #3, #5, #7, #8, #9, #10, #12, #13, #14, #16, #17, #18, #21, #23, #24, #27 | 19: #1, #2, #3, #5, #7, #8, #9, #10, #12, #13, #14, #16, #17, #18, #20, #21, #23, #24, #25 |
| Passou com ressalva | 7: #4, #6, #11, #19, #20, #25, #26 | 6: #4, #6, #11, #19, #26, #27 |
| Falhou | 1: #22 (valor inicial nulo) | 1: #22 (valor inicial nulo) |
| Não executados | #15, #28, #29, #30 (hipóteses, por decisão do usuário) | idem |

As duas falhas são o mesmo defeito, nos dois bancos.

## Defeito encontrado — Bug #166161

- **Sintoma:** com um campo "Propriedade do Processo" (tipo de valor 5) de `ds_valor_inicial` nulo, o job do Worker BPM falha com `NullReferenceException` em `FluxoService.AtualizarValoresCorrenteCampoFormularioDaTarefa` (`FluxoService.cs:7749`, `item.ds_valor_inicial.ToLower()`). A tarefa vencida não é desassociada e o job repete até esgotar as tentativas. O Agent clássico trata o mesmo nulo como texto vazio e desassocia.
- **Reproduzido** em Oracle (05/11 e 06/11) e SQL Server (05/11), inclusive com o build mais recente. Com `ds_valor_inicial` igual a `''` a desassociação funciona.
- **Ressalva sobre a frequência:** o nulo dos testes foi criado por `UPDATE`/`INSERT` direto no banco. O teste na tela do Share mostrou que a tela grava o primeiro item do combo (`[ds_usuario_solicitante]`), não `NULL`. A origem de um nulo real em produção (importação, dados antigos, integrações) não foi confirmada. Severidade sugerida: 3 - Medium, a confirmar com o time.
- Análise de falha: `05-analise-falha.md`; defeito: `06-defeito-166161.md`.

## O que foi validado

- **Funcional (net8):** desassocia tarefa de papel vencida (prazo em minutos, horas, dias e semanas), devolve ao papel, grava `OPCAO_TAREFA` e `LOG_APLICACAO`, atualiza valores "corrente" do formulário, apaga a liberação de anexo só do usuário desassociado, respeita limite do prazo, não age em tarefa sem usuário, concluída, de passo sem tempo ou dentro do prazo, e reavalia tarefa reassociada.
- **JOIN por passo (PR 29228):** o Agent clássico instalado (23/10) desassociava tarefa de passo sem tempo (fluxo 900599, SQL Server) e falhava em cascata; o build do PR passou nos dois bancos (#24).
- **Paridade clássico x net8:** ambos desassociam os mesmos casos; o clássico assume quando a rotina net8 é desativada (#11, #27).
- **Resiliência:** erro em uma tarefa não trava as outras (#22 isolamento), job com falha é reagendado e recupera (#23), duas instâncias do Worker não processam o mesmo job (#21), tarefa concluída entre agendamento e execução gera "nada a fazer" (#16).
- **API do Engine (parâmetro 96 = 1):** iniciar e cancelar fluxo pelo Engine da API net8 funcionou em SQL Server (#25).

## Achados para o time de desenvolvimento

1. **Bug #166161** (acima).
2. **Timeout de comando:** no SQL Server o comando aborta em 30 s e o job vai a `FalhaParaRepetir`; no Oracle não há timeout, um lock de linha deixa o job esperando sem limite (80 a 88 s observados) e um valor nulo chegou a travar o Worker na primeira rodada. Avaliar `CommandTimeout` no Oracle.
3. **Branch do PR no clássico** parte de uma base mais antiga da `master` (`VersaoAgent` 3.84.4 contra 3.88.0): integrar a `master` antes do release. O Agent instalado hoje ainda não tem o fix do PR 29228.
4. **`JOB_CONFIG_PADRAO` Id 12** está com `Ativo=1` no SQL Server; o script de carga manda 0.
5. **Valor "corrente" no início do fluxo** difere entre clássico (papel 1) e net8 (papel executor real): confirmar o esperado (#17).
6. **Log do Scheduler** registra "inserido com sucesso" a cada ciclo para a mesma chave enquanto o Worker não roda (ruído, sem duplicidade de processamento).
7. **Relógio:** `dt_inicio` em hora local; o `sysdate` do Oracle estava 3 h à frente. Relevante se o Worker rodar em fuso diferente do banco.
8. A tela de atividade de executor tipo usuário não tem "Tempo total para desassociar" (só papel).

## Ressalvas e lacunas

- **#4:** só a API (`GET /api/JobConfig`) foi testada; o front de configuração de rotinas não, porque exige proxy na mesma origem do Share.
- **#21:** o log não traz PID/host; a concorrência foi provada por horários e ausência de job duplicado, não por disputa pelo mesmo job.
- **#16 (06/11):** a conclusão foi simulada por `UPDATE` de `dt_termino` (a rodada de 05/11 usou a tela).
- **#20:** no SQL Server passou por repetição de #1, #5 e #13; no Oracle, #1 e #13 foram repetidos e o #5 (60 min) não.
- **#25:** no Oracle o cancelamento foi pelo motor clássico (parâmetro 96 = 0); pela API net8 só foi exercitado no SQL Server (`IniciarFluxo` e `CancelarFluxo`); `AvancarFluxo` explícito pela API não foi exercitado.
- **#7, #8, #12, #14:** provas por ausência de inserção no log; só #12 e #13 têm controle positivo próprio.
- Os `UPDATE`s de apoio (`dt_inicio`, tempo do passo, `JOB_CONFIG`) não são auditáveis no banco; constam no relatório da etapa 04.
- Os logs de arquivo do Agent clássico só registram quando ele age.
- Double-check independente (subagente, somente leitura) feito para os cenários do SQL Server e do Agent clássico; para o Oracle foi feito por log e banco durante a execução.

## Massa e estado do ambiente

- **Massa de teste não removida** (nenhum `DELETE` foi autorizado): Oracle, processos 521 a 523 e 541 a 543, fluxos 2062 a 2228 e usuário de teste `qa.usuario2`; SQL Server, processos 1028 a 1032 (o 1032 é um rascunho criado no teste de tela) e fluxos 9005xx a 9007xx.
- **Alterações de ambiente revertidas:** Agent clássico (binários e `ConfigAgent.xml` por hash), `JOB_CONFIG` Id 12 (Oracle `Ativo=1`, SQL Server `Ativo=0`), parâmetro 96 (Oracle 0, SQL Server 1), campos de formulário de teste, nginx e API local. O serviço `SmartShareAgent` está parado.
- O ambiente local está **apontado para Oracle** desde 06/11 11:34. O procedimento da troca de banco está em `aprendizados/entradas/QA-KB-20261106-001.md`.

## Para retomar quando o Bug #166161 for corrigido

1. Compilar o net8 da correção e subir Scheduler e Worker BPM.
2. **Reexecutar o #22 com valor inicial nulo** (e com `''`) em Oracle e SQL Server; fechar o Bug se passar.
3. **Regressão rápida nos dois bancos:** #1, #2, #16, #17, #21 e #23.
4. Complementar o que ficou limitado: #4 (front), #5 e #25 no Oracle, e o `AvancarFluxo` pela API, se houver ambiente com proxy.
5. Confirmar com dev/PO as hipóteses #15, #28, #29 e #30, que não foram executadas.

## Artefatos

Relatório de execução completo (evidências, horários e consultas): `04-execucao-testes.md`. Análise de falha: `05-analise-falha.md`. Defeito: `06-defeito-166161.md`. Mapa de testes: card #161490. Aprendizados: `aprendizados/`.
