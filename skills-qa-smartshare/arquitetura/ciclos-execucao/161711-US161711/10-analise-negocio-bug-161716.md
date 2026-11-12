# Etapa 10 — analise-negocio — Bug #161716 (filho de #161711 Bugs Instaladores)

- **Skill e argumentos:** `/arquitetura-analise-negocio` com `#161711` e pedido de uma análise por bug
- **Data:** 2026-11-09
- **Escreveu no Azure DevOps:** Não
- **Aprovação:** não aplicável (etapa somente leitura)
- **Fontes lidas:** Bug #161716 (rev 13, `ReproSteps`), PBI #161711 (rev 20), Análise #161472 (busca: origem do `ExisteJobAtivo`, PR 29631), CR #165204 e Teste #165205 (metadados). Comentários: nenhum.

## Aprendizados consultados

Consulta realizada — nenhum aprendizado aplicável encontrado.

# Análise de Negócio — Bug #161716 [BUG] ExecutaWS - Jobs são duplicados em execuções com grandes quantidades de fluxos

**Projeto:** SmartShare Arquitetura | **Tipo:** Bug | **Status:** Done (06/11, tag "CR feito") | **Sprint:** Sprint 4 | **Responsável:** Vinicius Medeiros dos Santos | **Severidade:** 3 - Medium | **PR:** 30104 (Active; branch proposta `bugfix/bug161716-executaws-duplicate-jobs`) | **Card de CR:** #165204 (Done) | **Card de Teste:** #165205 (New, sem responsável)

## Objetivo da alteração

Impedir que uma tarefa WebService ainda aberta receba outro job quando o volume de pendências supera o limite de seleção do Scheduler e o ciclo é mais curto que o tempo de processamento. (ReproSteps)

## Comportamentos esperados (contratos verificáveis)

- Quando houver mais tarefas WebService elegíveis do que o limite do Scheduler, deve existir um único job por chave funcional (`fluxo/tarefa/passo`) enquanto o anterior estiver Agendado, Executando ou em FalhaParaRepetir. (ReproSteps, "Ajuste proposto")
- Quando as 101 tarefas terminarem, `JOB_DUMP` deve ter 101 registros de sucesso para 101 fluxos distintos e nenhuma chave repetida. Linha de base do defeito: 134 registros, 33 duplicados. (ReproSteps, "Resultado atual")
- O primeiro ciclo continua criando exatamente 100 jobs. (ReproSteps)
- A verificação de dump não pode impedir um reagendamento legítimo. (ReproSteps, "Obs. para quem validar")

## Regras explícitas

- `ExisteChaveUnica` enxerga só `JOB_DUMP`, que só recebe linha quando o job termina com sucesso ou envenenado; por isso não cobre job ainda agendado, executando ou aguardando nova tentativa. (ReproSteps, "Por que não ExisteChaveUnica sozinho")
- `ExisteJobAtivo` consulta `JOB_BPM` por `ChaveUnica` + módulo + job nos status Agendado, Executando e FalhaParaRepetir. Foi portado do PR 29631 (CalculoIndicador, análise #161472) para evitar conflito de merge futuro. (ReproSteps; Análise #161472)
- A checagem entra por pendência dentro do laço de `EnfileirarPendencias`, pulando o enfileiramento quando já existir job ativo. (ReproSteps)

## Regras implícitas

- IMPLÍCITA: o Scheduler (job 28 no teste) precisa rodar em intervalo curto para provocar o defeito; com ciclo longo o defeito não aparece. Raciocínio: a causa é o ciclo curto frente ao tempo de processamento.

## Condições e exceções

- Volume maior que o limite de seleção (100) e ciclo menor que o processamento.
- Reprodução original usa mock de endpoint HTTP 200 com JSON válido.
- Banco: Oracle e SQL Server.

## Dependências

- PR 29631 (`ExisteJobAtivo`, ainda não mesclado), PR 30457 (#161712) com o método portado de novo (risco de duplicação), mock HTTP, Scheduler e Worker BPM ativos.

## Informações ausentes

- Informação não encontrada / necessita validação: limite exato de seleção do Scheduler no ambiente de teste (o bug usa 100).
- Informação não encontrada / necessita validação: qual a chance real de a chave bloquear um reagendamento novo. O bug pede essa validação ao CR/teste e não responde.

## Ambiguidades

- "Validar existe na tabela DUMP": o texto não deixa claro se a dump é checada além do `ExisteJobAtivo` neste job. O trecho "Por que não ExisteChaveUnica sozinho" sugere que sim, as duas juntas.

## Riscos identificados

- Dois PRs (30104 e 30457) criam `ExisteJobAtivo`; o merge pode duplicar ou conflitar o método.
- Chave residual na dump bloqueando reagendamento legítimo.
- Teste de 101 fluxos exige massa e mock de endpoint: sem eles, o resultado é inconclusivo.
- PR 30104 Active, ainda não mesclado.

## Prontidão para as próximas etapas

| Gate | Resultado |
|---|---|
| Prontidão para análise técnica | **APTA** |
| Prontidão para geração do mapa | **APTA** — critérios numéricos claros (101 fluxos, 100 jobs, 0 duplicados) |
| Prontidão para execução | **BLOQUEADA até haver build com o PR 30104**, mock HTTP e massa de 101 fluxos |

## Pendências

- Build com PR 30104; confirmar como os dois `ExisteJobAtivo` (30104 e 30457) convivem no build de teste.
