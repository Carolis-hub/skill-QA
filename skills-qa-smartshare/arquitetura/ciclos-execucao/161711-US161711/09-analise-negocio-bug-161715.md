# Etapa 09 — analise-negocio — Item #161715 (filho de #161711 Bugs Instaladores)

- **Skill e argumentos:** `/arquitetura-analise-negocio` com `#161711` e pedido de uma análise por bug
- **Data:** 2026-11-09
- **Escreveu no Azure DevOps:** Não
- **Aprovação:** não aplicável (etapa somente leitura)
- **Fontes lidas:** #161715 (rev 59, tipo "Outros", antes Bug/Análise; `Description` e `ReproSteps` lidos em parte, o texto veio truncado pela ferramenta), PBI #165944 (título, estado e vínculo), PBI #161711 (rev 20). Comentários: nenhum.

## Aprendizados consultados

Consulta realizada — nenhum aprendizado aplicável encontrado.

# Análise de Negócio — #161715 [BUG/DISCUSSÃO][AgentWorkers] - BPM - Caso uma das notificações do NotifyWF não seja enviado, fica tentando infinito (não esta aplicando poisoning)

**Projeto:** SmartShare Arquitetura | **Tipo:** Outros (foi Bug, depois Análise) | **Status:** New | **Sprint:** Sprint 4 | **Responsável:** Vinicius Medeiros dos Santos | **PR:** nenhum | **Card de Teste:** não existe | **Relacionado:** PBI #165944 (New, sem responsável)

## Situação

Este item não tem correção implementada, então não há comportamento entregue para testar. O conteúdo é uma análise de solução, e o desenvolvimento aparece como PBI #165944, ligado a este item pela relação `Related` (título: "NotifyWF: job por pendência + poisoning correto nas 5 notificações"). (relações do item; título do #165944)

## Objetivo da alteração

Fazer as notificações do NotifyWF (Mensagem Nova, Observação, Tarefa, Exceção de Alçada e Alerta) falharem de verdade quando o envio falhar, para o job entrar em retry e, depois das tentativas, ser envenenado, em vez de ser retentado para sempre. (Description, "Causa raiz")

## Comportamentos esperados (contratos verificáveis, da proposta; não implementados)

- Quando uma notificação falhar, o erro deve chegar ao job, que entra em retry e, esgotadas as tentativas, é envenenado. (Description, "Correção proposta")
- A lista de notificações deve continuar sendo processada mesmo com um item falhando; a falha é sinalizada no final. (Description)
- O retry deve reenviar só para quem ainda não recebeu, com controle por destinatário (tabela nova, chave `cd_fluxo`, `cd_tarefa`, `tp_origem_notificacao`, `cd_origem_notificacao`, `ds_email`). (Description, "Tabela nova proposta")
- Item já envenenado não deve voltar para a fila (`ExisteChaveUnica`) nos tipos Mensagem Nova, Observação e Tarefa. (Description)

## Regras explícitas

- A correção exige tabela nova no banco (Oracle e SQL Server), usada pelos 5 tipos; a `LOG_EMAIL` fica sem consumidor conhecido, e a remoção não entra neste escopo. (Description, "Escopo adicional")
- Mensagem Nova e Observação passam a ter um job por item; a consulta de execução da Mensagem Nova hoje ignora `cd_fluxo`, `cd_tarefa` e `cd_passo` no filtro, e isso precisa ser corrigido antes. (Description)
- A decisão de usar a dump em cada método do NotifyScheduler é feita aqui, item por item (delegada pelo #161712). (#161712, OBS)

## Regras implícitas

- IMPLÍCITA: enquanto não houver PR, o NotifyWF mantém retry infinito em falha de notificação, e o NotifyScheduler recebe só o `ExisteJobAtivo` do #161712.

## Condições e exceções

- Tipos 1 (Mensagem Nova), 5 (Observação), 6 (Tarefa), 7 (Alerta) e 8 (Exceção de Alçada) do enum `ENotifyStep`, cada um com a sua chave de origem. (Description, tabela por tipo)
- Alerta e Exceção de Alçada são recorrentes por natureza; a dump não se aplica a eles. (#161712)

## Dependências

- PBI #165944 (execução), #161712 (`ExisteJobAtivo` no NotifyScheduler), mudança de schema nos dois bancos.

## Informações ausentes

- Informação não encontrada / necessita validação: o texto completo do item foi lido só até o trecho de Observação (a ferramenta devolveu o conteúdo truncado); as seções de Tarefa, Exceção de Alçada e Alerta não foram lidas nesta rodada.
- Informação não encontrada / necessita validação: se este item entra no teste do PBI #161711 ou se o teste migra para o #165944.
- Informação não encontrada / necessita validação: critério de aceite para o teste, já que não há implementação.

## Ambiguidades

- O item está como "Outros", mas o título ainda diz "BUG/DISCUSSÃO". Interpretação adotada: é análise, o bug real será tratado no #165944.

## Riscos identificados

- O PBI #161711 pode sair "completo" com o retry infinito de notificações ainda aberto.
- Mudança de schema em produção (Oracle e SQL Server) quando o #165944 for implementado.

## Prontidão para as próximas etapas

| Gate | Resultado |
|---|---|
| Prontidão para análise técnica | **BLOQUEADA** — sem implementação nem PR |
| Prontidão para geração do mapa | **BLOQUEADA** — sem comportamento entregue |
| Prontidão para execução | **BLOQUEADA** — sem build |

## Pendências

- Decidir se o item sai do escopo de teste do #161711 e passa para o #165944.
- Ler o texto completo do item (seções ainda não lidas) quando o #165944 entrar em teste.
