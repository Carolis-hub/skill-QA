# Etapa 12 — analise-negocio — Bug #161839 (filho de #161711 Bugs Instaladores)

- **Skill e argumentos:** `/arquitetura-analise-negocio` com `#161711` e pedido de uma análise por bug
- **Data:** 2026-11-09
- **Escreveu no Azure DevOps:** Não
- **Aprovação:** não aplicável (etapa somente leitura)
- **Fontes lidas:** Bug #161839 (rev 15, `ReproSteps`), PBI #161711 (rev 20), Teste #165559 (metadados). Comentários: nenhum.

## Aprendizados consultados

Consulta realizada — nenhum aprendizado aplicável encontrado.

# Análise de Negócio — Bug #161839 [BUG]NotifyWF - Observação configurada para notificar executor da tarefa anterior não envia notificação

**Projeto:** SmartShare Arquitetura | **Tipo:** Bug | **Status:** Done (06/11, tag "CR feito") | **Sprint:** Sprint 4 | **Responsável:** Vinicius Medeiros dos Santos | **Severidade:** 3 - Medium | **PRs:** 30253 (net8) e 30254 (SmartShare clássico), ambos Active | **Card de Teste:** #165559 (New, sem responsável) | **Card de CR:** não existe | **Ambiente do relato:** `smartshare_debug`

## Objetivo da alteração

Fazer a opção de observação "Visualização e Inclusão pelo executor notificando executor da tarefa anterior" notificar de fato o executor da tarefa anterior. As demais opções de observação já notificavam. A causa é uma junção de três aliases de `CAMINHO_FLUXO` que só acha resultado com 4 ou mais tarefas encadeadas antes da atual; o clássico tem o mesmo defeito e a mesma correção. (ReproSteps)

## Comportamentos esperados (contratos verificáveis)

- Quando a atividade usar essa opção e uma observação for incluída, o executor da tarefa anterior deve receber a notificação por e-mail. (ReproSteps, "Resultado esperado")
- Fluxo simples (2 a 3 tarefas): a notificação deve chegar (cenário que antes falhava). (ReproSteps, roteiro 1)
- Tarefa anterior atribuída a papel ou comitê: deve ser notificado quem concluiu a tarefa. (roteiro 2)
- Tarefa anterior automática (SQL, Web Service, e-mail, condição): não deve haver notificação nessa opção, e o fluxo e as demais notificações devem seguir normalmente. (roteiro 3)
- Dois fluxos com os mesmos números de tarefa: cada fluxo notifica só o seu executor anterior. (roteiro 4)
- Comportamento igual em Oracle e SQL Server. (roteiro 5)
- O clássico recebe a mesma correção (PR 30254, `SmartShare/SmartShareAgent/NotifyWF.cs`, `case 4`). (ReproSteps, "Ajuste equivalente no SmartShare clássico")

## Regras explícitas

- Em fluxo com execução paralela pode haver mais de um executor anterior, mas só o último da lista é notificado hoje. Fica fora de escopo, é decisão de produto e não muda neste bug. (ReproSteps, "Fora do escopo")
- Passos de condição ou divisão paralela não aparecem em `CAMINHO_FLUXO`; a tarefa anterior encontrada é sempre uma atividade real. (ReproSteps)
- O handler já trata "ninguém para notificar": pula o envio, marca a observação como processada e segue. (ReproSteps)
- No clássico, a criação de cada tipo de tarefa automática não foi conferida linha a linha; o próprio bug declara isso como lacuna. (ReproSteps)

## Regras implícitas

- IMPLÍCITA: o teste cobre dois produtos (net8 e clássico), cada um com o seu build e o seu PR. Raciocínio: dois PRs em repositórios diferentes.
- IMPLÍCITA: o teste precisa de e-mail funcional no ambiente para ver a notificação chegar, ou aceitar log/consulta como evidência. Raciocínio: a etapa 05 do ciclo registrou falha de e-mail do Graph (`MailerException`) e o QA aceitou o log do Worker como evidência.

## Condições e exceções

- Tipo do executor da tarefa anterior: usuário, papel, comitê, automático.
- Tamanho da cadeia de tarefas (2 ou 3 versus 4 ou mais).
- Banco: Oracle e SQL Server.
- Ramos paralelos: só o último executor é notificado (fora de escopo).

## Dependências

- PRs 30253 (net8) e 30254 (clássico), e-mail do ambiente, massa de processo com a opção configurada (a execução da etapa 05 usou o processo 522 v1, passo 6, com UPDATE ativo a reverter).

## Informações ausentes

- Informação não encontrada / necessita validação: confirmação de que o QA não deve testar notificação de todos os ramos paralelos (declarado fora de escopo).
- Informação não encontrada / necessita validação: critério de aceite no clássico para tarefas automáticas (lacuna declarada no próprio bug).

## Ambiguidades

- Título e roteiro: o título sugere que sempre notifica; o roteiro diz que tarefa anterior automática não gera notificação. Interpretação adotada: vale o roteiro.

## Riscos identificados

- Notificação para pessoa errada se a junção cruzar fluxos com os mesmos números de tarefa.
- Notificação enviada só ao último executor em fluxos paralelos (comportamento conhecido, fora de escopo).
- Falha de e-mail do ambiente confundida com falha do bug (já ocorreu na etapa 05).
- Dois PRs Active, ainda não mesclados.

## Prontidão para as próximas etapas

| Gate | Resultado |
|---|---|
| Prontidão para análise técnica | **APTA** (já feita, etapa 03) |
| Prontidão para geração do mapa | **APTA** (mapa já existe, etapa 04) |
| Prontidão para execução | **APTA COM RESSALVAS** — execução parcial na etapa 05 (Oracle, PR 30253); faltam o cenário #26 (inconclusivo), tarefa automática, dois fluxos e SQL Server; e-mail do ambiente falha |

## Pendências

- Reverter o UPDATE ativo do processo 522 v1, passo 6 (`ID_PERMISSAO_OBSERVACAO` 4 para 0), registrado na etapa 05.
- Ambiente de e-mail funcional ou decisão do QA sobre aceitar log como evidência.
