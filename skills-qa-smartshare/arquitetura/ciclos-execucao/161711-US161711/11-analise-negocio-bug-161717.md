# Etapa 11 — analise-negocio — Bug #161717 (filho de #161711 Bugs Instaladores)

- **Skill e argumentos:** `/arquitetura-analise-negocio` com `#161711` e pedido de uma análise por bug
- **Data:** 2026-11-09
- **Escreveu no Azure DevOps:** Não
- **Aprovação:** não aplicável (etapa somente leitura)
- **Fontes lidas:** Bug #161717 (rev 7, `ReproSteps`), PBI #161711 (rev 20). Comentários: nenhum.

## Aprendizados consultados

Consulta realizada — nenhum aprendizado aplicável encontrado.

# Análise de Negócio — Bug #161717 [BUG]EnviaAlertaFluxo - Job faz o dump com sucesso mas não chega a notificação no email

**Projeto:** SmartShare Arquitetura | **Tipo:** Bug | **Status:** Done (06/11), **fechado sem correção** | **Sprint:** Sprint 4 | **Responsável:** Vinicius Medeiros dos Santos | **Severidade:** 3 - Medium | **PR:** nenhum | **Card de Teste:** não existe | **Card de CR:** não existe

## Objetivo da alteração

Nenhuma alteração foi feita. O bug descrevia que, na atividade "Envia alerta", os e-mails não eram enviados quando havia mais de um alerta para o mesmo período. O time testou, não conseguiu reproduzir e fechou o bug, com reavaliação se o erro voltar. (ReproSteps)

## Comportamentos esperados (contratos verificáveis)

- Quando houver mais de um alerta configurado para o mesmo período, o job EnviaAlertaFluxo deve enviar todos os e-mails e a notificação deve chegar. (ReproSteps, "O erro descrito era")
- Esse comportamento não tem teste dedicado no PBI, e nenhuma entrega no Azure DevOps o cobre.

## Regras explícitas

- Bug fechado sem correção por não ter sido reproduzido. (ReproSteps, OBS)

## Regras implícitas

- IMPLÍCITA: o #161712 aplica `ExisteJobAtivo` ao EnviaAlertaFluxo (sem dump), o que pode afetar alertas repetidos do mesmo fluxo e tarefa. Raciocínio: a chave é fixa e o job é recorrente; o PBI #165944 também trata Alerta (tipo 7, nível/tier de atraso).

## Condições e exceções

- Vários alertas no mesmo período (níveis de atraso diferentes) para a mesma tarefa.

## Dependências

- #161712 (checagem de job ativo no EnviaAlertaFluxo) e PBI #165944 (controle de envio por destinatário no Alerta).

## Informações ausentes

- Informação não encontrada / necessita validação: massa e passos que o time usou para tentar reproduzir (o bug só traz uma imagem e a frase "realizamos testes").
- Informação não encontrada / necessita validação: se o QA deve manter esse cenário como regressão no teste do #161712.

## Ambiguidades

- "Job faz o dump com sucesso mas não chega a notificação": não diz se o e-mail falhou no envio (Graph/SMTP) ou se não foi gerado. Esse ponto interage com a falha de e-mail do ambiente já vista na etapa 05 do ciclo (`MailerException` do Graph).

## Riscos identificados

- Defeito pode reaparecer sem teste de regressão, principalmente com o `ExisteJobAtivo` novo no EnviaAlertaFluxo.
- Falha de e-mail do ambiente (Graph) pode ser confundida com este bug.

## Prontidão para as próximas etapas

| Gate | Resultado |
|---|---|
| Prontidão para análise técnica | **BLOQUEADA** — sem implementação e sem PR |
| Prontidão para geração do mapa | **APTA COM RESSALVAS** — só como cenário de regressão dentro do mapa do #161712 |
| Prontidão para execução | **BLOQUEADA** — depende de ambiente de e-mail que funcione e de build do #161712 |

## Pendências

- Decidir se o cenário "vários alertas no mesmo período" vira regressão do #161712.
