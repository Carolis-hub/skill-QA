# Etapa 01 — analise-negocio — #161711 Bugs Instaladores

- **Skill e argumentos:** `/arquitetura-analise-negocio 161711`
- **Data:** 2026-11-06
- **Escreveu no Azure DevOps:** Não
- **Aprovação:** não aplicável (etapa somente leitura)
- **Fontes lidas:** PBI #161711 (rev 20) e seus 14 filhos (#161712, #161713, #161714, #161715, #161716, #161717, #161839, #165194, #165195, #165204, #165205, #165559, #165998, #166111); metadados dos PRs 30060, 30104, 30253, 30254, 30457, 30486 (somente para localizar o que cada bug entregou — o conteúdo dos diffs não foi lido nesta etapa). Comentários do PBI: nenhum (`System.CommentCount = 0`).

## Aprendizados consultados

Consulta realizada — nenhum aprendizado aplicável encontrado (`QA-KB-20261105-001` trata de nulo/paridade com o clássico no BPM; `QA-KB-20261106-001` trata de troca de banco do ambiente local. Nenhum se relaciona com duplicidade de jobs, envenenamento ou notificação).

# Análise de Negócio — #161711 Bugs Instaladores

**Projeto:** SmartShare Arquitetura | **Tipo:** Product Backlog Item | **Status:** Committed (coluna Teste) | **Sprint:** Sprint 4 | **Responsável:** Vinicius Medeiros dos Santos | **Tag:** agenteqa

## Objetivo da alteração

O PBI #161711 não tem descrição nem critérios de aceite (campos `System.Description` e `Microsoft.VSTS.Common.AcceptanceCriteria` ausentes). O escopo vem dos work items filhos e da explicação do QA nesta sessão: reunir bugs encontrados em rotinas (jobs dos Agents Worker/Scheduler e notificações do BPM) já migradas e liberadas, que ficaram para correção posterior, e validar a correção de cada um. (descrição do QA no chat; títulos dos filhos)

## Mapa dos filhos

| Bug / card | Tipo | Estado | PR vinculado (estado) | Card de Teste | Card de CR |
|---|---|---|---|---|---|
| #161716 ExecutaWS — jobs duplicados com muitos fluxos | Bug | Done, tag "CR feito" | 30104 (Active) | #165205 (New) | #165204 (Done) |
| #161713 BPM — ExecutaSql não envenena o job | Bug | Done, tag "CR feito" | 30060 (Active) | #165195 (New) | #165194 (Done) |
| #161712 Scheduler — várias tentativas de inserir o mesmo job | Bug/Discussão | Done, tag "CR feito" | 30457 (Active) | #165998 (New) | não existe card filho |
| #161714 BPM — log de erro do AvancoTemporal mascara o erro | Bug/Discussão | Done, tag "CR feito" | 30486 (Active) | #166111 (New) | não existe card filho |
| #161839 NotifyWF — observação "executor da tarefa anterior" não notifica | Bug | Done, tag "CR feito" | 30253 net8 e 30254 clássico (ambos Active) | #165559 (New) | não existe card filho |
| #161715 BPM — NotifyWF sem poisoning (retry infinito) | Outros (era Análise) | **New** | nenhum | não existe | não existe |
| #161717 EnviaAlertaFluxo — dump com sucesso sem e-mail | Bug | Done | nenhum | não existe | não existe |

Estado dos PRs: campo `status = 1` (Active) na API em todos os seis. Isso significa que as correções **não estão mescladas na `main`** (net8) nem na `master` (clássico, PR 30254) segundo o Azure DevOps. (lida no Azure DevOps)

## Comportamentos esperados (contratos verificáveis)

**#161716 — ExecutaWS duplicado**
- Quando existirem mais tarefas WebService elegíveis do que o limite de seleção do Scheduler (reprodução original: 101 fluxos, job 28), o sistema deve criar um único job por chave funcional (`fluxo/tarefa/passo`) e não recriar o job enquanto o anterior estiver Agendado, Executando ou em FalhaParaRepetir. (ReproSteps)
- Quando as 101 tarefas terminarem, `JOB_DUMP` deve ter 101 registros de sucesso para 101 fluxos distintos, e 0 chaves repetidas. Linha de base do defeito: 134 registros, 33 duplicados. (ReproSteps, tabela "Resultado atual")
- O primeiro ciclo deve continuar respeitando o limite (100 jobs). (ReproSteps)
- A verificação de "já está na dump" não pode bloquear um reagendamento legítimo. (ReproSteps, "Obs. para quem validar")

**#161713 — ExecutaSql não envenena**
- Quando a execução SQL do BPM falhar e ainda houver tentativas (`MaxTentativas`, `PoliticaBackoff`), o job deve ser reagendado (retry) e não pode gravar variável de erro, avançar passo de escape nem notificar. (Description, item 3)
- Quando as tentativas se esgotarem, o sistema deve gravar a variável de erro, logar, tentar o passo de escape e notificar ocorrência se configurado. (Description, item 3)
- Quando o passo de escape não existir ou falhar ao avançar, o job deve ser envenenado (`JobStatusId = Envenenado` e registro em `JOB_DUMP`) e não terminar como sucesso. (ReproSteps)
- Quando uma pendência já estiver envenenada (chave na dump), o Scheduler não deve enfileirá-la de novo. (Description, item 2)

**#161712 — Scheduler insere o mesmo job várias vezes**
- Quando um job do Scheduler ainda estiver ativo (agendado, executando ou aguardando nova tentativa), o Scheduler não deve criar outro com a mesma chave. Aplicar `ExisteJobAtivo` em: AvancoTemporal, ExecutaPassoAplicacao, ExecutaSql, InicioPublicacao, NotificaInicioComPublicacao, os 5 métodos do NotifyScheduler, ExcluiFluxoEmSolicitacao, EnviaAlertaFluxo, InicioFluxoRevisao, InicioDesassociarAutomatico e, como reforço, InicioTemporal. (ReproSteps)
- Os jobs recorrentes ou de chave fixa (InicioPublicacao, NotificaInicioComPublicacao, InicioTemporal, ExcluiFluxoEmSolicitacao, EnviaAlertaFluxo, NotifyScheduler alertas e exceção de alçada) **não** devem usar a checagem de dump, pois ela os bloquearia para sempre. (ReproSteps)
- Nos jobs alterados, a data atual deve respeitar o timezone (`GetDataAtual`). (ReproSteps, OBS final)
- ExecutaWsScheduler e CalculoIndicador ficam fora deste bug: já cobertos pelos PRs 30104 e 29631. (ReproSteps)

**#161714 — log do AvancoTemporal**
- Quando o job AvancoTemporal falhar, o log deve descrever o motivo real do erro e não uma mensagem que o esconda. (ReproSteps — critério verificável escrito de forma vaga, ver Ambiguidades)

**#161839 — observação notificando executor anterior**
- Quando a atividade estiver configurada com "Visualização e Inclusão pelo executor notificando executor da tarefa anterior" e uma observação for incluída, o executor da tarefa anterior deve receber a notificação por e-mail. (ReproSteps, "Resultado esperado")
- Quando a tarefa anterior tiver sido atribuída a papel ou comitê, deve ser notificado quem de fato concluiu a tarefa. (ReproSteps, roteiro item 2)
- Quando a tarefa anterior for atividade automática (SQL, Web Service, e-mail, condição), nenhuma notificação deve ser enviada nessa opção e o fluxo e as demais notificações devem seguir normalmente. (ReproSteps, roteiro item 3)
- Quando dois fluxos reutilizarem os mesmos números de tarefa, cada fluxo deve notificar apenas o seu próprio executor anterior. (ReproSteps, roteiro item 4)
- O comportamento deve ser igual em Oracle e SQL Server, e o clássico deve receber a mesma correção (PR 30254). (ReproSteps)

## Regras explícitas

- `ExisteChaveUnica` olha só `JOB_DUMP` (job concluído com sucesso ou envenenado); `ExisteJobAtivo` olha `JOB_BPM` (Agendado, Executando, FalhaParaRepetir). Um não substitui o outro. (#161716, #161712)
- Em #161839: se existir mais de uma tarefa anterior real (ramos paralelos), hoje só o último executor da lista é notificado. Isso **não muda** nesta correção e foi declarado fora de escopo (decisão de produto). (#161839, "Fora do escopo")
- #161717 foi fechado sem correção porque o defeito não foi reproduzido; será reavaliado se voltar. (#161717)
- #161715 define para notificações: tabela nova de controle de envio por destinatário (Oracle e SQL Server), job por mensagem/observação/exceção de alçada/alerta e uso de `ExisteChaveUnica` em três dos cinco tipos. **Não foi implementado** (sem PR; estado New). (#161715)

## Regras implícitas

- IMPLÍCITA: o PBI só deve ser considerado testado quando cada bug corrigido (cinco com PR) tiver o seu card de Teste executado, porque cada card `Teste` filho é nomeado pelo bug que cobre. Raciocínio: hierarquia e nomes dos cards #165195, #165205, #165559, #165998 e #166111.
- IMPLÍCITA: #161715 e #161717 não geram teste neste ciclo, a menos que o time os reabra. Raciocínio: #161715 está New e sem PR; #161717 foi fechado sem alteração.
- IMPLÍCITA: a correção do #161713 depende de a configuração de tentativas do job estar definida (`MaxTentativas`, `PoliticaBackoff`) para que o retry seja observável. Raciocínio: a decisão Retry/Envenenado vem de `JobResiliencePolicy.CalcularFalha` com esses valores.
- IMPLÍCITA: as correções dos bugs #161716, #161713 e #161712 foram feitas em PRs separados que alteram os mesmos arquivos de Scheduler; o comportamento final depende da ordem em que forem integrados. Raciocínio: ver Riscos.

## Condições e exceções

- Banco: Oracle e SQL Server (explícito no #161839 e no #161715; os demais bugs não citam, o produto roda nos dois).
- Volume: o defeito do #161716 só aparece com mais pendências do que o limite de seleção do Scheduler (100) e ciclo do Scheduler mais curto que o processamento.
- Tipo da tarefa anterior no #161839: usuário direto, papel, comitê, atividade automática, condição/divisão paralela.
- Retry do #161713: comportamento muda conforme a tentativa atual contra `MaxTentativas`.
- Jobs recorrentes (alertas, exceção de alçada, InicioTemporal) têm regra própria: não usam a dump.

## Dependências

- PR 29631 (`feature/US160818-migracao-job-calculo-indicador`, origem do `ExisteJobAtivo`), citado como aberto e não mesclado em #161716 e #161712. Os PRs 30104 e 30457 alteram `JobBpmService` e `JobBpmRepository` (portam o método).
- #161712 delega ao #161715 a decisão item a item do uso de `ExisteNaTabelaDump` no NotifyScheduler. Como #161715 não foi feito, essa parte segue em aberto.
- #161713 e #161712 alteram o mesmo handler (`ExecutaSqlSchedulerHandler`); #161716 e #161712 alteram os mesmos arquivos de serviço e repositório do job.
- #161839 envolve dois repositórios: net8 (PR 30253) e SmartShare clássico (PR 30254, `SmartShareAgent/NotifyWF.cs`).
- Ambiente de teste: Scheduler e Worker BPM rodando, mock de endpoint HTTP 200 (para #161716), massa de fluxos com a configuração de observação (para #161839).

## Informações ausentes

- Informação não encontrada / necessita validação: o PBI #161711 não tem descrição nem critérios de aceite; confirmar que o escopo de teste é "um card Teste por bug corrigido" (cinco bugs).
- Informação não encontrada / necessita validação: #161714 não diz qual erro de log estava mascarado nem como deve ficar a mensagem correta (qual job, qual cenário de falha, texto esperado).
- Informação não encontrada / necessita validação: #161715 (Outros, New) e #161717 (Done sem correção) entram neste ciclo de teste? Se sim, qual o critério de aceite, já que não há implementação.
- Informação não encontrada / necessita validação: #161712 lista 11 jobs a ajustar, mas não define, job a job, o comportamento esperado observável pelo QA (ex.: quantos jobs devem existir em JOB_BPM após N ciclos) nem o resultado esperado para a validação de timezone (`GetDataAtual`).
- Informação não encontrada / necessita validação: #161839 declara fora de escopo a notificação de vários ramos paralelos; confirmar que o QA não deve testar notificação de todos os ramos.
- Informação não encontrada / necessita validação: o #161713 não informa os valores de `MaxTentativas` e `PoliticaBackoff` a usar no teste. Pergunta de ambiente, será tratada na análise técnica.

## Ambiguidades

- #161714: "log não descreve de forma clara o problema" admite dois resultados — (a) a mensagem passa a conter a causa original da exceção; (b) o log não perde o stack trace. Sem exemplo do log antigo e do novo, não há como medir.
- #161713 "envenenar": pode significar apenas job em `JOB_DUMP` com status Envenenado, ou também o fluxo ficar parado/avançar pelo passo de escape. A descrição usa os dois sentidos.
- #161712 "ExisteJobAtivo como reforço" em InicioTemporal: o próprio texto diz que "na prática não precisa", mas pede para usar; não está claro se o QA deve exigir a checagem nesse job.
- #161839: "executor da tarefa anterior" com tarefa anterior automática — o roteiro diz que nenhuma notificação é enviada; o título do bug sugere que sempre deveria notificar. Interpretação adotada: vale o roteiro (sem notificação).

## Riscos identificados

- Os seis PRs estão Active, não concluídos. Testar contra um build que não contenha a correção produz falso "passou" ou falso "falhou". (lida no Azure DevOps)
- Quatro bugs (#161716, #161713, #161712 e a parte de Scheduler do #161714) mexem em `BpmSchedulerJob.cs`, `ExecutaSqlSchedulerHandler.cs`, `JobBpmService.cs`, `JobBpmRepository.cs` ou `JobLogMessages.cs`. Testar cada um isolado pode passar e a combinação falhar, ou o contrário (conflito de merge e método `ExisteJobAtivo` portado duas vezes).
- Marcar jobs recorrentes ou de chave fixa com checagem de dump bloquearia o job para sempre (alertas, exceção de alçada, InicioTemporal, ExcluiFluxoEmSolicitacao, EnviaAlertaFluxo). É o principal risco de regressão do #161712.
- #161713: se o escape não avançar e o job não for envenenado, a falha real continua mascarada e o time de monitoramento não vê o erro.
- #161716: reagendamento legítimo bloqueado por chave residual na dump (o próprio bug pede para validar isso).
- #161839: notificação para pessoa errada se a junção cruzar fluxos distintos com os mesmos números de tarefa.
- #161715 pendente mantém retry infinito de notificação no NotifyWF; o NotifyScheduler fica só com o `ExisteJobAtivo` do #161712. Risco de release: o PBI sai "completo" sem o problema de NotifyWF resolvido.
- #161717 fechado sem reprodução: risco residual de o defeito ressurgir (e-mails faltando para mais de um alerta no mesmo período).

## Prontidão para as próximas etapas

| Gate | Resultado |
|---|---|
| Prontidão para análise técnica | **APTA COM RESSALVAS** — o negócio está claro nos bugs #161716, #161713, #161839; #161714 e #161712 têm lacunas de comportamento esperado |
| Prontidão para geração do mapa | **BLOQUEADA** — falta o card `Análise` (ver análise técnica), PBI sem critérios de aceite e PRs não mesclados |
| Prontidão para execução | **BLOQUEADA** — nenhum build com as correções confirmado; PRs Active |

## Pendências

- Decidir se #161715 e #161717 entram no escopo de teste.
- Obter do dev o exemplo antes/depois do log do #161714.
- Confirmar o build/ambiente com os PRs 30060, 30104, 30253/30254, 30457 e 30486.
