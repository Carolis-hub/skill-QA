# Etapa 08 — analise-negocio — Bug #161714 (filho de #161711 Bugs Instaladores)

- **Skill e argumentos:** `/arquitetura-analise-negocio` com `#161711` e pedido de uma análise por bug
- **Data:** 2026-11-09
- **Escreveu no Azure DevOps:** Não
- **Aprovação:** não aplicável (etapa somente leitura)
- **Fontes lidas:** Bug #161714 (rev 13, `ReproSteps`), PBI #161711 (rev 20), Teste #166111 (metadados). Comentários: nenhum.

## Aprendizados consultados

Consulta realizada — nenhum aprendizado aplicável encontrado.

# Análise de Negócio — Bug #161714 [BUG/DISCUSSÃO][AgentWorkers] - BPM - Log de erro do AvancoTemporal esta mascarando o erro

**Projeto:** SmartShare Arquitetura | **Tipo:** Bug | **Status:** Done (06/11, tag "CR feito") | **Sprint:** Sprint 4 | **Responsável:** Vinicius Medeiros dos Santos | **Severidade:** 3 - Medium | **PR:** 30486 (Active; branch `bugfix/Bug161714-correcao-log-erro-descricao`) | **Card de Teste:** #166111 (New, sem responsável) | **Card de CR:** não existe

## Objetivo da alteração

Fazer o log de erro do job AvancoTemporal descrever de forma clara o problema real, em vez de uma mensagem que esconde o motivo. O bug pede primeiro achar qual log está mascarando e depois corrigir. (ReproSteps, "Descrição")

## Comportamentos esperados (contratos verificáveis)

- Quando o job AvancoTemporal falhar, o log deve trazer a descrição do erro real e não uma mensagem que esconda o motivo. (ReproSteps — critério escrito de forma vaga, ver Ambiguidades)

## Regras explícitas

- Nenhuma regra de negócio explícita além do objetivo acima. O bug informa apenas o nome da branch do PR. (ReproSteps)

## Regras implícitas

- IMPLÍCITA: a correção altera mensagem de log, não o fluxo do job. Raciocínio: a descrição não menciona mudança de comportamento, retry ou envenenamento.

## Condições e exceções

Nenhuma identificada. O bug não diz em quais falhas o log estava mascarado.

## Dependências

- Job AvancoTemporal (Scheduler/Worker BPM). O #161712 também altera o AvancoTemporalScheduler (`ExisteJobAtivo`), o que cria risco de interação nos mesmos arquivos de Scheduler.

## Informações ausentes

- Informação não encontrada / necessita validação: qual log estava mascarando o erro, qual era a mensagem antiga e qual deve ser a nova.
- Informação não encontrada / necessita validação: qual falha reproduz o cenário (tipo de erro no avanço temporal) e onde o QA lê o log.
- Informação não encontrada / necessita validação: critério de aceite do bug. O bug não tem passos de reprodução nem resultado esperado mensurável.

## Ambiguidades

- "Descrevem de forma clara o problema": pode significar mensagem com a causa original da exceção, ou preservação do stack trace. Sem exemplo antes/depois, não há como medir.

## Riscos identificados

- Teste sem critério objetivo tende a "passou" subjetivo; sem exemplo antes/depois, uma regressão no log não é detectada.
- Mensagem de log pode expor dado sensível (caminho, SQL, dado de fluxo) ao detalhar o erro. Risco declarado como hipótese, sem evidência no bug.
- PR 30486 Active, ainda não mesclado.

## Prontidão para as próximas etapas

| Gate | Resultado |
|---|---|
| Prontidão para análise técnica | **APTA COM RESSALVAS** — a análise técnica precisa descobrir qual log mudou (pelo diff do PR 30486) |
| Prontidão para geração do mapa | **BLOQUEADA** — sem resultado esperado mensurável |
| Prontidão para execução | **BLOQUEADA** — sem exemplo antes/depois, sem forma de provocar a falha e sem build com o PR 30486 |

## Pendências

- Pedir ao dev o exemplo antes/depois do log e um jeito de provocar a falha.
- Build com PR 30486.
