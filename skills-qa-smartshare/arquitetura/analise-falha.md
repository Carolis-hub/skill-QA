---
description: Investiga uma falha de teste (de /executar-teste ou relatada manualmente) e determina causa provavel, componente relacionado e se ha evidencia suficiente para abrir um defeito no Azure DevOps. Nao cria nada — so decide se vale a pena seguir para /gerar-defeito.
---

Analisar a falha a partir de **$ARGUMENTS**.

Formato esperado: `[ID da história ou Test Case] [descrição da falha (opcional)]`

Exemplos:
- `157538 Ao salvar com o campo obrigatório vazio o sistema gravou o registro mesmo assim` → descrição manual
- `153287` → sem descrição: reaproveita o resultado de um `/executar-teste 153287` que já rodou nesta conversa

Este comando é a Skill 5 (QA Failure Analyst). Ele **não cria bug** — só decide, com rastreabilidade, se a falha tem evidência suficiente para justificar um defeito. Quem decide criar de fato é o `/gerar-defeito`, sempre com confirmação humana antes de escrever no Azure DevOps.

---

## Regra fundamental

Quando faltar evidência ou contexto para concluir algo com segurança, escrever literalmente **"Não tenho evidência suficiente."** na seção correspondente — nunca preencher com suposição. O veredito final também pode ser "evidência insuficiente para abrir defeito", e isso é um resultado válido, não uma falha do comando.

---

## Step 0 — Reunir a fonte da falha

1. Se `$ARGUMENTS` tiver mais de um token, trate o restante como descrição manual da falha (`$OBTIDO_MANUAL`) fornecida pelo usuário.
2. Se houver só o ID e um `/executar-teste` para esse mesmo ID já rodou nesta conversa, reaproveite diretamente a(s) linha(s) marcadas `Falhou` do relatório dele — esperado, obtido, evidência, step específico.
3. Se não houver nem descrição manual nem execução prévia na conversa, pergunte ao usuário o que foi observado (esperado vs. obtido) antes de continuar — não adivinhe a falha a partir só do ID.

---

## Step 1 — Contexto da história/Test Case

Chame `mcp__azure-devops_wit_get_work_item` com o ID informado (`expand: "all"`). Se for um Test Case, capture também a história relacionada (`relations`, `TestedBy`) e busque essa história também, para ter a regra de negócio original.

Se `/analise-negocio` e/ou `/analise-tecnica` já rodaram para essa história nesta conversa, **reaproveite os relatórios deles** em vez de reprocessar do zero — em particular:
- comportamentos esperados (contratos verificáveis) de `/analise-negocio`,
- componentes/camadas/risco de `/analise-tecnica`.

---

## Step 2 — Checklist de análise (Skill 5)

Responda cada pergunta, citando a origem da informação:

1. **Que era esperado?** — do critério de aceite/cenário do Test Case, ou da regra de negócio.
2. **Que aconteceu?** — o obtido, com a evidência disponível (snapshot, screenshot, mensagem de erro, resposta de API).
3. **Qual componente pode estar relacionado?** — cruzar com o relatório de `/analise-tecnica` (camadas alteradas) quando existir; se não existir, indicar `Informação não encontrada / necessita validação.`
4. **O problema parece funcional ou técnico?** — funcional (comportamento não bate com a regra de negócio) vs. técnico (erro de sistema, exceção, timeout, resposta HTTP inesperada).
5. **O comportamento já existia anteriormente?** — consulte `mcp__azure-devops__search_work_items` por bugs anteriores na mesma área/componente (mesmo padrão do Step 3.5 do `gerar-mapa-testes-v3`). Se achar bug relacionado (mesmo que fechado), cite o ID.
6. **Existe relação com a alteração atual?** — se houver PR vinculado à história (via `/analise-tecnica`), verificar se o componente da falha aparece no diff. Se não houver PR disponível, registrar isso como limitação, não como "não relacionado".
7. **Há evidência suficiente para abrir um defeito?** — veredito explícito: `SIM` ou `NÃO`, com justificativa. Só é `SIM` se houver: esperado claro, obtido comprovado (não suposto), passos reproduzíveis, e não for uma hipótese não confirmada (`HIPOTESE:`) do mapa de testes.

---

## Step 3 — Relatório final

```
# Análise de Falha — <ID> <Título>

## O que era esperado
...

## O que aconteceu
...

## Componente relacionado
...

## Classificação
Funcional / Técnico — <justificativa>

## Já existia antes?
<Sim, ver Bug #<id> / Não encontrado / Informação não encontrada — busca indisponível>

## Relação com a alteração atual
...

## Veredito
SIM — evidência suficiente para abrir defeito
ou
NÃO — <motivo específico do que falta>
```

Se o veredito for `SIM`, pergunte ao usuário se deseja prosseguir para `/gerar-defeito` — não encadear automaticamente.
Se for `NÃO`, explique exatamente o que precisaria ser coletado (ex.: reproduzir de novo com evidência, confirmar regra com o PO, aguardar PR).

---

## Troubleshooting

- Se a "falha" reportada for, na verdade, um cenário marcado `HIPOTESE:` no mapa de testes que nunca foi confirmado como regra real, o veredito correto é `NÃO` — a causa é falta de regra definida, não um defeito de implementação.
- Se `search_work_items` não retornar nada ou não estiver disponível, registrar isso explicitamente em "Já existia antes?" — não afirmar que é a primeira ocorrência sem checar.
- Nunca classificar como "Técnico" só porque não se sabe explicar — se não há informação suficiente para classificar, usar `Informação não encontrada / necessita validação.`
