---
description: Valida se uma release (conjunto de historias) esta pronta para producao — identifica impactos, seleciona regressao (automatizada + manual), executa, analisa falhas e recomenda Aprovada / Aprovada com ressalvas / Reprovada. Recomendacao, nao decisao automatica.
---

Homologar a release a partir de **$ARGUMENTS**.

Formato esperado: `[ID1 ID2 ID3 ...]` (lista de IDs de história/PBI que compõem a release) **ou** `"[nome da iteration]"` (best-effort — busca histórias Resolved/Done nessa iteration).

Exemplos:
- `157200 157538 157601` → release explícita por lista de histórias
- `"Sprint 24"` → best-effort por iteration

Este comando é a Skill 7 (QA Release Validator). Ele **recomenda**, não decide — a liberação para produção continua sendo uma decisão humana. Reaproveita `/analise-tecnica`, `/executar-teste` e `/analise-falha` como sub-rotinas em vez de reimplementar a lógica delas.

> **Sobre escala:** para releases com muitas histórias, os Steps 2–5 abaixo são paralelizáveis por natureza (cada história é independente até a consolidação final). Isso só deve ser feito via múltiplos agentes/Workflow se você pedir isso explicitamente nesta conversa — por padrão, este comando roda história por história, sequencialmente.

---

## Regra fundamental

A recomendação final (`Aprovada` / `Aprovada com ressalvas` / `Reprovada`) é uma **sugestão para decisão humana**, nunca uma aprovação automática de deploy. Nunca marcar um teste como aprovado sem tê-lo executado de fato (nada de "presumir que deve passar"). Nunca reprovar ou aprovar com base em suposição quando a execução real não foi possível — nesse caso, o status correto é `Aprovada com ressalvas` com a ressalva sendo justamente "não foi possível executar X".

### Guardrail vs. Gates — dois eixos independentes (não confundir)

Este comando opera sob um **guardrail de autoridade de decisão**: quem decide liberar para produção é sempre humano, nunca este agente. É deliberado — decisão crítica de negócio, com custo alto de reversão — e é um eixo **diferente** de **gate técnico** (verificação objetiva, que pode e deve ter poder real de reprovar: ex. `/gerar-defeito` já bloqueia sem veredito `SIM` de `/analise-falha`; `/analise-tecnica` já bloqueia sem o card `Análise` preenchido).

- **Gates** (evidência de execução, revisão de artefato) podem e devem ficar **mais rigorosos** com o tempo — isso é investimento paralelo, não uma troca por afrouxar o guardrail.
- **Guardrail** (quem decide) só deve afrouxar depois de um **histórico validado criteriosamente** de que o fluxo é confiável — é uma decisão separada e deliberada, nunca uma consequência automática de "os gates ficaram robustos o suficiente".

Nunca interpretar "os gates estão robustos" como justificativa, por si só, para reduzir a confirmação humana desta skill — isso exige uma decisão explícita e à parte.

*Origem: decisão de 2026-09-07, ao encaixar o framework SDD + Skills + Agents + Gates neste processo de QA.*

---

## Step 0 — Validar ambiente

Confirme `mcp__azure-devops` conectado. Se algum step abaixo precisar executar cenário de UI, confirme também `mcp__playwright` conectado (mesma checagem do `/executar-teste`).

---

## Step 1 — Coletar as histórias da release

- Se `$ARGUMENTS` for uma lista de números, use-os diretamente como `$RELEASE_STORIES`.
- Se for um texto (nome de iteration), tente localizar histórias com `mcp__azure-devops__search_work_items` filtrando por `System.WorkItemType: ["Product Backlog Item"]` e `System.State: ["Resolved", "Done", "Closed"]`, cruzando o texto da busca com o nome da iteration. Isso é **best-effort** — se o resultado parecer incompleto ou ambíguo, apresente a lista encontrada ao usuário e peça confirmação antes de prosseguir, em vez de assumir que está completa.

Para cada história em `$RELEASE_STORIES`, busque título e estado via `mcp__azure-devops_wit_get_work_items_batch_by_ids`.

---

## Step 2 — Identificar alterações e impactos por história

Para cada história:

1. Se `/analise-tecnica` já rodou para ela nesta conversa, reaproveite o relatório. Senão, rode o mesmo processo do `/analise-tecnica` (card `Análise` do dev + PR vinculado quando existir).
2. Se a história não tiver card `Análise` preenchido, **não bloqueie a release inteira por isso** — marque essa história especificamente como `IMPACTO NÃO MAPEADO` e trate isso como uma ressalva candidata no relatório final, não como impedimento de avaliar as demais.
3. Consolide por história: camadas tocadas, risco (Alto/Médio/Baixo), funcionalidades/integrações potencialmente impactadas.

---

## Step 3 — Selecionar os testes (de liberação e de regressão)

### 3.1 — Testes de liberação (específicos de cada história)

Para cada história, localize o(s) Test Case(s) vinculado(s) (`relations` com `TestedBy-Reverse`/`Tested By`). Se não houver Test Case publicado, marque `SEM TEST CASE — necessita /gerar-mapa-testes-v3 antes da homologação` para essa história.

### 3.2 — Regressão automatizada (Playwright)

Cruze as camadas/funcionalidades impactadas (Step 2) com os módulos já cobertos em `automacao.teste` (login, adaptação mobile, e o que mais existir na estrutura de `tests/`). Se uma história tocar uma área com regressão automatizada existente, inclua o script correspondente (`npm run test:login`, `npm run test:<módulo>`, etc.) na lista de execução. Se tocar uma área sem automação, isso é regressão manual (Step 3.3).

### 3.3 — Regressão manual (sem automação ou automação quebrada)

Para áreas impactadas sem regressão automatizada, ou cuja automação esteja marcada como quebrada, listar os Test Cases manuais relevantes (via histórico de defeitos e funcionalidades relacionadas do Step 2) para execução via `/executar-teste`.

Apresente a lista consolidada de testes selecionados (liberação + regressão automatizada + regressão manual) ao usuário **antes de executar**, com a justificativa de por que cada um entrou na seleção — não execute nada ainda.

---

## Step 4 — Executar

### 4.1 — Regressão automatizada

Rode os scripts npm selecionados (via Bash/PowerShell, no diretório `automacao.teste`). Capture o resumo de saída do Playwright (quantos passaram/falharam) sem reinterpretar — reportar exatamente o que o runner disse.

### 4.2 — Testes de liberação e regressão manual

Para cada Test Case selecionado, aplique o mesmo processo do `/executar-teste` (triagem human-in-the-loop, execução via `mcp__playwright`, evidência obrigatória, incluindo os guardrails de ambiente/credenciais/banco de dados definidos lá). Não pule silenciosamente nenhum Test Case da lista — se algum não puder ser executado, registre o motivo explicitamente.

### 4.3 — Registrar no log de ações (governança)

Esta skill **executa de fato contra HMG** (regressão automatizada + testes de liberação/manual) — mesmo padrão de auditoria do `/executar-teste`, mas aqui a execução representa a **homologação oficial** (Rodada 2), não a validação funcional inicial (Rodada 1, que já foi registrada por `/executar-teste` quando cada história passou por lá individualmente).

Depois do relatório do Step 6, acrescente uma linha por história executada ao final da tabela em `~/.claude/docs/projetos/skills-qa/LOG-ACOES.md` (via `Edit`, nunca sobrescrevendo):

```
| <data/hora atual> | `/homologar-release` | Execução de regressão/homologação oficial | US #<id> (release: #<id1>, #<id2>, ...) | <resultado desta história: passou/falhou/não executado> | <nome do usuário que aprovou a seleção do Step 3> | 2 (homologação oficial, HOM) | <resumo de 1 linha: falhas críticas encontradas, se houve> |
```

Se a mesma execução cobrir várias histórias da release, uma linha por história (não uma linha agregada) — cada uma precisa ser rastreável individualmente pelo card/US correspondente.

---

## Step 5 — Analisar falhas

Para cada falha (automatizada ou manual), aplique o checklist do `/analise-falha`: esperado, obtido, componente, funcional/técnico, já existia antes, relação com a alteração atual, evidência suficiente para defeito.

Classifique cada falha como:
- **Crítica** — bloqueia a funcionalidade principal da história ou quebra um fluxo já existente em produção (regressão real).
- **Não crítica** — comportamento secundário, cosmético, ou hipótese não confirmada da fase de mapa de testes.

---

## Step 6 — Relatório final e recomendação

```
# Homologação de Release

**Histórias incluídas:** #<id1>, #<id2>, ...
**Ambiente:** HMG

## Resumo de execução
- Testes planejados: N
- Executados: N
- Aprovados: N
- Falharam: N
- Não executados (motivo): N

## Impacto por história
| História | Impacto mapeado? | Camadas de risco | Testes vinculados |
|---|---|---|---|

## Falhas encontradas
| # | História/Test Case | Cenário | Severidade da falha | Crítica? | Já existia antes? |
|---|---|---|---|---|---|

## Riscos ainda existentes
- ...

## Recomendação
**Status:** Aprovada / Aprovada com ressalvas / Reprovada

**Justificativa:** ...
```

**Critério de recomendação** (aplicar de forma explícita, não por impressão geral):
- **Reprovada** — pelo menos uma falha crítica confirmada (evidência suficiente) em fluxo já existente ou em critério de aceite obrigatório.
- **Aprovada com ressalvas** — sem falha crítica confirmada, mas há: falhas não críticas pendentes, histórias com `IMPACTO NÃO MAPEADO`, testes que não puderam ser executados, ou hipóteses não validadas ainda em aberto. Listar cada ressalva individualmente.
- **Aprovada** — todos os testes selecionados foram executados, nenhuma falha crítica, nenhuma ressalva pendente.

Se houver falhas com veredito `SIM` (evidência suficiente) no Step 5, pergunte ao usuário se deseja abrir os defeitos correspondentes via `/gerar-defeito` — não encadear automaticamente, e não fazer isso para todas de uma vez sem revisão individual.

---

## Troubleshooting

- Se a lista de histórias vier de uma iteration (modo best-effort) e a busca retornar um número suspeito de resultados (0 ou muito acima do esperado), pare e peça confirmação da lista antes de gastar execução em cima dela.
- Se `automacao.teste` não existir no caminho esperado ou os scripts `npm run test:*` falharem por motivo de ambiente (não relacionado ao teste em si, ex.: sessão HMG fora do ar), registrar isso como "não executado por indisponibilidade de ambiente", nunca como falha de teste.
- Nunca inferir o resultado de um Test Case a partir do resultado de outro "parecido" — cada um precisa da sua própria execução e evidência.
