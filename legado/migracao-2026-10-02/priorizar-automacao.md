---
description: Classifica cenarios de teste (alta/media/baixa prioridade de automacao) e promove os de alta prioridade de tests/user-stories/ para tests/regressao/ no projeto automacao.teste, sempre com aprovacao antes de escrever e execucao real do spec antes de declarar sucesso.
---

Priorizar automação a partir de **$ARGUMENTS**.

Formato esperado: `[ID da história ou módulo em tests/user-stories/]`

Exemplos:
- `157538` → localiza o spec correspondente por ID de história
- `<nome-do-módulo>` → avalia todos os specs desse módulo em `tests/user-stories/<nome-do-módulo>/`

Este comando é a Skill 9 (QA Automation Engineer). Projeto alvo: pasta `automacao.teste` (pergunte ao usuário o caminho local, se não for conhecido). Estrutura vigente:
- `tests/user-stories/<módulo>/<categoria>.spec.ts` — testes específicos de uma história (categorias herdadas do `gerar-mapa-testes`: fluxo-principal, fluxo-alternativo, validacoes-campos, comportamento-modal, busca-vinculos, cancelamento, erros-integracao, consistencia-persistencia, casos-borda)
- `tests/regressao/<módulo>/<cenário>.spec.ts` — regressão promovida, estável, executada a cada release (consumida por `/homologar-release`)

---

## Regra fundamental

**Nunca promover um cenário construído a partir de uma hipótese não confirmada** (`HIPOTESE:` no mapa de testes de origem, ou lógica de negócio ainda marcada como ambígua em `/analise-negocio`). Instabilidade de regra de negócio é o oposto de "estável" — promover isso quebra a regressão assim que a regra for esclarecida/mudar.

**Nunca sobrescrever um arquivo de regressão já existente sem mostrar o que vai mudar e pedir aprovação.** **Nunca declarar uma promoção concluída sem rodar de fato o spec** (`npx playwright test <caminho>`) e ver passar.

---

## Step 0 — Validar ambiente

Confirme que a pasta `automacao.teste` existe no caminho informado (ou perguntado ao usuário) e que `npx playwright --version` funciona nesse diretório. Se não existir ou não rodar, pare e reporte — não tente criar a estrutura do zero sem confirmar com o usuário.

---

## Step 1 — Localizar os cenários candidatos

- Se `$ARGUMENTS` for um ID numérico: localizar o(s) arquivo(s) em `tests/user-stories/**/` cujo nome contenha esse ID (padrão `us<ID>-*.spec.ts`) ou, se a história pertencer a um módulo conhecido, todos os specs daquele módulo.
- Se for um nome de módulo: listar todos os `.spec.ts` em `tests/user-stories/<módulo>/`.

Se nada for encontrado, isso é um **gap de automação**, não uma promoção — pule para o Step 5 (Gap de automação).

Ler cada spec encontrado e listar os blocos `test(...)`/`test.describe(...)` como `$CANDIDATOS` (título do teste, categoria pelo nome do arquivo).

---

## Step 2 — Classificar cada cenário

Para cada candidato em `$CANDIDATOS`, avaliar contra os critérios do documento, buscando sinal concreto (não impressão):

| Critério | Como avaliar |
|---|---|
| Cenário crítico | Está em `fluxo-principal.spec.ts` ou cobre um critério de aceite obrigatório (não `HIPOTESE:`)? |
| Executado frequentemente | O módulo é usado em toda release (login, emissão) ou é uma tela/ação de uso raro? |
| Repetitivo/estável | A regra de negócio por trás está confirmada (`/analise-negocio` sem ambiguidade nesse ponto) e não é hipótese? |
| Alto custo manual | O fluxo tem múltiplos passos de UI (preencher, navegar, confirmar) que seriam tediosos repetir manualmente a cada release? |
| Alto risco de regressão | Consultar `mcp__azure-devops__search_work_items` por bugs anteriores na mesma área (mesmo padrão do `gerar-mapa-testes-v3`/`analise-falha`) — módulo com histórico de defeito pesa a favor de alta prioridade |

Classificar cada candidato em **Alta / Média / Baixa**, com justificativa de 1 linha citando o critério decisivo.

- **Alta** → candidato a promoção para `tests/regressao/`.
- **Média** → fica em `tests/user-stories/` por enquanto; registrar como "candidato futuro" no relatório, não promover automaticamente.
- **Baixa** → não promover; permanece como teste único da história, sem ação adicional.

Apresentar a tabela de classificação **antes** de tocar em qualquer arquivo.

---

## Step 3 — Propor a promoção (apenas cenários Alta)

Para cada cenário de prioridade Alta:

1. Definir o caminho de destino em `tests/regressao/<módulo>/<nome-do-cenário>.spec.ts`.
2. Se o arquivo de destino já existir, ler o conteúdo atual e propor um **merge** (adicionar o(s) `test()` novo(s) preservando os existentes) — nunca sobrescrever o arquivo inteiro sem necessidade.
3. Se não existir, propor criação, reaproveitando o Page Object já existente em `pages/` (não criar um novo Page Object se um equivalente já cobre a tela).
4. Propor a entrada correspondente em `package.json` → `scripts` (`"test:<módulo>:<cenário>"`), seguindo o padrão de nomes já usado no projeto.

Apresentar o diff completo (arquivo de teste + linha do `package.json`) e **parar para aprovação** antes de escrever qualquer coisa.

---

## Step 4 — Escrever, rodar e confirmar (só após aprovação)

1. Escrever o(s) arquivo(s) aprovados via `Write`/`Edit`.
2. Atualizar `package.json` com o novo script.
3. Rodar o spec recém-criado/atualizado isoladamente: `npx playwright test <caminho>` (via Bash/PowerShell, no diretório do projeto).
4. Se passar: reportar sucesso com o resumo da execução real (não presumir).
5. Se falhar: **não ajustar o teste para "forçar passar"** sem entender a causa — reportar a falha como está e perguntar se é problema no script novo ou um comportamento real da aplicação (nesse caso, pode virar insumo para `/analise-falha`).

---

## Step 5 — Gap de automação (quando não existe nenhum spec ainda)

Se a história/módulo não tiver nenhum arquivo em `tests/user-stories/`, isso não é uma promoção — é ausência total de automação. Nesse caso:

1. Verificar se a história já tem um Test Case publicado no Azure DevOps (via `/gerar-mapa-testes-v2`/`v3`) — usar os cenários de lá como base, nunca inventar cenário novo aqui.
2. Se houver uma planilha de referência de features do projeto, consultá-la para contexto adicional sobre a subfeature (ler via script Python com `openpyxl`, já disponível no ambiente) — perguntar ao usuário o caminho, se não for conhecido.
3. Propor a criação do primeiro spec em `tests/user-stories/<módulo>/<categoria>.spec.ts`, categoria por categoria, reaproveitando Page Object existente quando houver ou propondo um novo quando a tela ainda não tiver nenhum.
4. Isso é criação de automação nova, não promoção — não vai direto para `tests/regressao/`. Só entra lá depois de rodar de verdade e ser classificado como Alta prioridade em uma execução futura deste comando.

---

## Step 6 — Relatório final

```
# Priorização de Automação — <ID/módulo>

## Classificação
| Cenário | Prioridade | Justificativa |
|---|---|---|

## Promovidos para regressão
- tests/regressao/<módulo>/<arquivo>.spec.ts — resultado da execução: <N passed / N failed>
- package.json atualizado: "test:<script>"

## Candidatos futuros (Média, não promovidos agora)
- ...

## Gap de automação identificado
- <história/módulo sem spec algum> — recomendação: criar em tests/user-stories/ primeiro
```

---

## Troubleshooting

- Nunca promover um `test()` cujo nome/comentário indique `HIPOTESE` ou "VERIFICAR COM DEV/PO" — isso vem direto do mapa de testes e não deve virar regressão travada.
- Se dois specs cobrirem o mesmo cenário (um em `user-stories/`, outro já em `regressao/`), não duplicar — apontar a duplicidade e perguntar se o de `user-stories/` deve ser removido após a promoção.
- Se `npx playwright test` falhar por motivo de ambiente (HMG fora do ar, sessão expirada) e não por erro do script, não classificar como "falha da automação" — reportar como bloqueio de ambiente e tentar novamente depois.
