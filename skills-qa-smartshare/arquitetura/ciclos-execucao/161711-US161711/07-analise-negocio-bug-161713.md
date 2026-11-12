# Etapa 07 — analise-negocio — Bug #161713 (filho de #161711 Bugs Instaladores)

- **Skill e argumentos:** `/arquitetura-analise-negocio` com `#161711` e pedido de uma análise por bug
- **Data:** 2026-11-09
- **Escreveu no Azure DevOps:** Não
- **Aprovação:** não aplicável (etapa somente leitura)
- **Fontes lidas:** Bug #161713 (rev 20, `Description` e `ReproSteps`), PBI #161711 (rev 20), CR #165194 e Teste #165195 (metadados). Comentários: nenhum.

## Aprendizados consultados

Consulta realizada — nenhum aprendizado aplicável encontrado.

# Análise de Negócio — Bug #161713 [BUG][AgentWorkers] - BPM - Não está "envenenando" os JOBs - SQL

**Projeto:** SmartShare Arquitetura | **Tipo:** Bug | **Status:** Done (06/11, tag "CR feito") | **Sprint:** Sprint 4 | **Responsável:** Vinicius Medeiros dos Santos | **Severidade:** 3 - Medium | **PR:** 30060 (Active) | **Card de CR:** #165194 (Done) | **Card de Teste:** #165195 (New, sem responsável)

## Objetivo da alteração

Fazer o job `ExecutaSql` do BPM entrar no ciclo normal de retry e envenenamento. Antes, qualquer erro virava "sucesso" porque o tratamento herdado do clássico (variável de erro, escape, notificação) engolia a exceção. Quando o escape não avançava, a falha real ficava mascarada. (Description, "Causa raiz")

## Comportamentos esperados (contratos verificáveis)

- Quando a execução SQL falhar e ainda houver tentativas (contra `MaxTentativas`, com `PoliticaBackoff`), o job deve ser reagendado e não deve gravar variável de erro, avançar escape nem notificar ocorrência. (ReproSteps, item 1)
- Quando não houver mais tentativas, o sistema deve gravar a variável de erro do fluxo, logar, tentar o passo de escape e notificar ocorrência se estiver configurado. (ReproSteps, item 1)
- Quando o escape não existir ou o avanço falhar, o job deve ser envenenado (`JobStatusId = Envenenado` com registro em `JOB_DUMP`) em vez de terminar como sucesso. (ReproSteps, item 1)
- Quando uma pendência já estiver na dump, o Scheduler não deve enfileirá-la de novo (`ExisteChaveUnica`). (ReproSteps, item 3)

## Regras explícitas

- O comportamento "erro vira desvio de negócio" vem do clássico e só fazia sentido quando o escape sempre existia e avançava. (Description, "Causa raiz")
- `AvancaPassoEscapeExecutaSql` passa a informar se avançou (`true`) ou não (`false`: sem escape configurado ou falha no avanço). (ReproSteps, item 2)
- Validação do dev: build da solução sem erros; 2048 testes passando e 2 falhas anteriores em `Usuario*Tests`, sem relação com BPM (confirmado pelo dev). (ReproSteps, item 5)

## Regras implícitas

- IMPLÍCITA: com escape que avança com sucesso após esgotar as tentativas, o job fecha como sucesso sem ser envenenado. Raciocínio: o envenenamento só ocorre quando o escape não avança.
- IMPLÍCITA: o retry precisa ser observável, então a configuração do job (`MaxTentativas`, `PoliticaBackoff`) precisa estar definida no ambiente de teste.

## Condições e exceções

- Tentativas restantes: retry sem efeitos colaterais de negócio.
- Tentativas esgotadas com escape configurado e que avança: sucesso com tratamento.
- Tentativas esgotadas sem escape ou com escape que falha: envenenado.
- Banco: Oracle e SQL Server.

## Dependências

- `JobResiliencePolicy` / `BpmExecJob` (mecanismo central de backoff e envenenamento).
- PR 30060 e PR 30457 (#161712) alteram o mesmo handler `ExecutaSqlSchedulerHandler`; conflito registrado na etapa 03 do ciclo.
- Parametrização de `JOB_CONFIG` do job (`MaxTentativas`, `PoliticaBackoff`).

## Informações ausentes

- Informação não encontrada / necessita validação: valores de `MaxTentativas` e `PoliticaBackoff` do ambiente de teste (pergunta de ambiente, vai para a análise técnica).
- Informação não encontrada / necessita validação: como o QA deve provocar uma falha de SQL de forma controlada (pergunta técnica).

## Ambiguidades

- "Envenenar": ora é o job ficar `Envenenado` em `JOB_DUMP`, ora é o fluxo seguir pelo escape. Interpretação adotada: envenenado só quando o escape não avança.

## Riscos identificados

- Falha real continua mascarada se o escape não avançar e o job não for envenenado (o defeito original).
- Retry executado com efeitos de negócio duplicados (variável de erro, ocorrência) se a decisão de retry falhar.
- Conflito de merge com o PR 30457.
- PR 30060 Active, ainda não mesclado.

## Prontidão para as próximas etapas

| Gate | Resultado |
|---|---|
| Prontidão para análise técnica | **APTA** — comportamento esperado claro e verificável |
| Prontidão para geração do mapa | **APTA COM RESSALVAS** — depende dos valores de `JOB_CONFIG` e de como forçar a falha |
| Prontidão para execução | **BLOQUEADA até haver build com o PR 30060 e meio de forçar falha de SQL** |

## Pendências

- Valores de `MaxTentativas` e `PoliticaBackoff`; mecanismo para forçar falha.
- Build com PR 30060 (conflito com PR 30457).
