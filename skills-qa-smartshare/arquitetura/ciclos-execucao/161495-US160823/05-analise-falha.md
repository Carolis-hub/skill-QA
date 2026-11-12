# Etapa 05 — Análise de falha — #160823 Rotina - Inicio Desassociar Automático

- **Skill:** `/arquitetura-analise-falha` — cenário #22 (Oracle), reteste de 05/11/2026
- **Data:** 2026-11-05
- **Escreveu no Azure DevOps?** Não
- **Fontes lidas:** logs do Worker BPM (`JOB_BPM/InicioDesassociarAutomatico`, 05/11), `JOB_BPM` e `TAREFA` no Oracle, `FluxoService.cs` (net8), `Engine.cs` (clássico), relatório da etapa 04. Busca de bugs no Azure DevOps (2 consultas): nenhum resultado.

## Aprendizados consultados

Consulta realizada — nenhum aprendizado aplicável encontrado (base vazia antes desta análise).

## O que era esperado

- Cenário #22 do mapa (card #161490): um erro numa tarefa não trava as outras, e o job com erro fica reagendável.
- Paridade com o clássico: com o campo "Propriedade do Processo" (`id_tipo_valor=5`) sem valor inicial, o clássico desassocia a tarefa normalmente (`lida-no-codigo`: `Engine.cs`, método `AtualizarValoresCorrenteCampoFormularioDaTarefa`, usa `dRow["ds_valor_inicial"].ToString().ToLower()`, e `DBNull.ToString()` devolve texto vazio).

## O que aconteceu

Massa: processo 543 "QA-161495 Form2" (atividade de papel, 2 min), campo 1 tipo 5 com `ds_valor_inicial` nulo (`UPDATE` de 1 linha feito às 15:48 para recriar o gatilho). Fluxos 2143, 2144 e 2145 iniciados pela tela (`iniciafluxo.aspx?CDPROC=543`), tarefa 2 associada ao usuário 1 desde 15:50.

| Evento | Hora (local) | Evidência |
|---|---|---|
| Scheduler enfileirou os 3 jobs (36279, 36283, 36284) | 15:52:40 a 15:52:52 | `JOB_BPM`, `vista-no-banco` |
| Worker iniciou o job 36279 | 15:54:30 | log do Worker, `vista-em-log` |
| Job 36279 falhou com `NullReferenceException` | 15:55:27 (57 s depois) | log do Worker |
| Jobs 36283 e 36284 iniciados e falhos | 15:55:27 a 15:55:36 | log do Worker |
| Os 3 jobs em `FalhaParaRepetir`, 1 tentativa, reprogramados | 15:55 | `JOB_BPM` (`job_status_id=4`) |
| Segunda tentativa dos 3, mesma exceção | 15:56:56 a 15:57:11 | `JOB_BPM` (2 tentativas), 6 ocorrências no log |
| Tarefa 2 dos três fluxos | continua associada ao usuário 1 | `TAREFA`, `vista-no-banco` |

Pilha (resumida): `FluxoService.AtualizarValoresCorrenteCampoFormularioDaTarefa` (`FluxoService.cs:7742`), chamada por `FluxoService.DesassociarFluxo` (linhas 1135 e 1148) e por `InicioDesassociarAutomaticoExecHandler.Executar` (linha 103). A exceção reverte a transação de `DesassociarFluxo` (`catch` com rollback e `throw`), então nada foi gravado para a desassociação.

Diferença para a rodada de 04/11: não houve travamento. Cada job falhou sozinho, os seguintes foram processados e o Worker seguiu. O isolamento entre jobs funcionou (primeira parte do #22), mas a tarefa vencida nunca é desassociada enquanto o campo estiver nulo.

## Componente relacionado

- `FluxoService.AtualizarValoresCorrenteCampoFormularioDaTarefa` (`smartshare-net8/src/3 - Core/Project.Core.Application/Services/FluxoService.cs:7742`): `switch (item.ds_valor_inicial.ToLower())` sem teste de nulo (`lida-no-codigo`).
- Equivalente clássico: `SmartShare.BPM/Workflow/Engine.cs`, mesmo método, sem exceção com nulo.
- Consulta de origem dos campos: `CampoFormularioRepository.GetFieldsWithValueTypeProcessPropertyByCdFluxo` (`WHERE id_tipo_valor = 5`), que traz campos com valor inicial nulo.

## Classificação

- **Sintoma:** Técnico. Exceção não tratada que impede o efeito de negócio (desassociar).
- **Camada provável:** Worker (handler do job) sobre o `FluxoService` (camada de aplicação).
- **Causa provável:** `ds_valor_inicial` nulo e `.ToLower()` direto. Confirmada pela pilha e pela leitura do código; o clássico trata o nulo como texto vazio.

## Já existia antes?

Não encontrado: duas buscas no Azure DevOps (tipo Bug, projeto SmartShare Arquitetura) retornaram 0 resultados. A busca cobre só esse projeto.

## Relação com a alteração atual

`DesassociarFluxo` chamar `AtualizarValoresCorrente...` já existia no `FluxoService`; a US 160823 passa a exercitá-lo em lote pelo job. Não tenho evidência suficiente sobre se o PR 29340 alterou esse método (diff não aberto nesta análise). O defeito aparece no caminho novo do job e quebra a paridade com o clássico.

## Lacunas

- Não tenho evidência suficiente sobre a causa dos 57 s antes do erro no primeiro job (15:54:30 a 15:55:27). Os dois seguintes levaram 5 s e 9 s. Pode ser abertura de conexão ou consulta no Oracle; não medido.
- Não tenho evidência suficiente sobre como o travamento de 04/11 (job em "Executando" sem erro) se relaciona com este erro. Hoje o erro apareceu e o Worker não travou; a causa do travamento anterior segue sem confirmação.
- Teste na tela (06/11, SQL Server): a tela **não** gera `NULL` ao salvar um campo tipo 5 sem escolher o valor inicial; grava `[ds_usuario_solicitante]` (o navegador seleciona o primeiro item do combo). A leitura de código que sugeria `NULL` (`CampoFormulario.aspx.cs:1566-1568`, `1858-1861`) só vale se o valor chegar vazio ao servidor, o que não ocorre no uso normal. A origem de um `NULL` real em produção não está confirmada; a frequência esperada do defeito é menor do que eu havia suposto.
- ~~Não validado em SQL Server~~ — validado depois (16:37 a 16:48): o valor nulo também falha no SQL Server (fluxos 900710 a 900712); texto vazio (`''`) desassocia normalmente (fluxo 900713). O defeito não é específico do Oracle. Segue sem confirmação se o Oracle grava o vazio da tela como `NULL` (inferência).

## Passos para reproduzir

1. Oracle, `JOB_CONFIG` Id 12 `Ativo=1`, Worker BPM e Scheduler com `DBType=Oracle`.
2. Processo com atividade de papel, "Tempo total para desassociar" de 2 min e um campo "Propriedade do Processo" (`id_tipo_valor=5`) com `ds_valor_inicial` nulo.
3. Iniciar um fluxo, deixar a tarefa de papel associada a um usuário e esperar 2 min.
4. Aguardar o ciclo do Scheduler e o do Worker (até 5 min): o job vai a `FalhaParaRepetir` com `NullReferenceException` e a tarefa continua associada.

## Veredito

**SIM — evidência suficiente para abrir defeito**: esperado claro (desassociar como o clássico), obtido comprovado (log e banco), passos reproduzíveis, não é hipótese. Severidade, se abrir: sugestão **média** (a tarefa vencida nunca é desassociada e o job repete até esgotar as tentativas; o impacto depende da frequência de campos tipo 5 sem valor inicial, ainda não confirmada). A decisão de severidade é do time.

Correção sugerida ao dev (não implementada): tratar `ds_valor_inicial` nulo como vazio, como o clássico; avaliar `CommandTimeout` no Oracle.

## Pendências

- Aprovação do usuário para `/arquitetura-gerar-defeito` (não encadeado).
- Estado deixado no Oracle: campo 543/1 com valor inicial nulo; jobs 36279, 36283 e 36284 em retentativa (até `Max_Tentativas` 5).
