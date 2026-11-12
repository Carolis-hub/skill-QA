# Etapa 17 — analise-tecnica — Item #161715 (filho de #161711 Bugs Instaladores)

- **Skill e argumentos:** `/arquitetura-analise-tecnica 161711` com uma análise por bug
- **Data:** 2026-11-09
- **Escreveu no Azure DevOps:** Não
- **Aprovação:** o QA autorizou em 09/11, no chat, usar bugs e diffs dos PRs como fonte no lugar do card `Análise` ausente.
- **Fontes:** texto do #161715 (já lido em parte na etapa 09; o trecho de Tarefa, Alçada e Alerta não foi lido) e título do PBI #165944. **Não há PR nem diff.**

## Aprendizados consultados

Consulta realizada — nenhum aprendizado aplicável encontrado.

# Análise Técnica — #161715 BPM: notificação do NotifyWF falha e fica tentando infinito (sem poisoning)

**Card de Análise:** nenhum | **PR vinculado:** nenhum | **Relacionado:** PBI #165944 (New)

## Resultado

Sem implementação, a exceção autorizada (bugs e diffs) não tem diff para ler. O que existe é uma **proposta de solução** escrita pelo dev. Registro o que ela afirma, sem validar contra código.

## O que a proposta altera (não implementado)

- Repassar a falha de cada notificação ao job para ele entrar em retry e, esgotadas as tentativas, ser envenenado, processando a lista inteira antes de sinalizar. (Description, "Correção proposta")
- Tabela nova de controle de envio por destinatário no banco, com chave `cd_fluxo`, `cd_tarefa`, `tp_origem_notificacao` (enum `ENotifyStep`), `cd_origem_notificacao` e `ds_email`, e `dt_envio` informativo. Mudança de schema em Oracle e SQL Server. (Description)
- Job por mensagem e por observação (em vez de um job por tarefa) e uso de `ExisteChaveUnica` em Mensagem Nova, Observação e Tarefa. (Description)
- A `GetNotifyMensagemNovoLista` (`TarefaNotificacaoRepository.cs:209-262`) hoje ignora `cd_fluxo`, `cd_tarefa` e `cd_passo` no `WHERE`: precisa ser corrigida antes. (Description, afirmação do dev, não conferida no código)

## Onde (camadas)

| Camada | Alterado (proposto) | Risco | Justificativa |
|---|---|---|---|
| Banco | tabela nova e índice composto nos dois bancos | **Alto** | Schema em produção |
| Scheduler/Worker | NotifySchedulerHandler, NotifyWFExecHandler | **Alto** | Muda a granularidade do job |
| Repositório | consultas de pendência | Médio | Filtro hoje incompleto |

## Pré-requisitos técnicos de execução de teste

Não aplicável: nada a testar neste item. O teste migra para o PBI #165944 quando houver PR.

## Informações ausentes

- Informação não encontrada / necessita validação: sem PR, não há como confirmar nada contra o código.
- Informação não encontrada / necessita validação: texto do #161715 de Tarefa, Alçada e Alerta ainda não lido.

## Gate

Análise técnica **BLOQUEADA** para este item até haver PR no #165944.
