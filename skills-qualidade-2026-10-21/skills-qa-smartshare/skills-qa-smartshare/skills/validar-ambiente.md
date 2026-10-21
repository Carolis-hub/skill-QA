---
description: Le o mapa de testes publicado no card "Criar Mapa de Teste" filho de uma User Story do Azure DevOps, extrai a coluna Pre-requisitos (formato [CATEGORIA] requisito), inspeciona o ambiente de teste somente em leitura (browser, banco read-only, configuracao) e valida se ele suporta a execucao de cada cenario. Entrega, por requisito, ATENDIDO / NAO ATENDIDO / NAO VERIFICAVEL e, por cenario, EXECUTAVEL / PARCIAL / BLOQUEADO, para decidir se vale rodar /executar-teste. Nao altera o ambiente, nao cria massa de dados e nao executa os cenarios.
---

Validar se o ambiente suporta os testes da User Story do Azure DevOps a partir de **$ARGUMENTS**.

Formato esperado: `[ID da User Story] [nome do projeto (opcional)] [ambiente (opcional, default: HMG)]`

Exemplos:
- `157538` → projeto resolvido automaticamente a partir do próprio work item, ambiente HMG
- `157538 "Nome do Projeto" HMG`

Esta skill fica **entre** `/gerar-mapa-testes-v3` e `/executar-teste`: o primeiro declara, por cenário, o que o ambiente precisa ter (coluna `Pre-requisitos`); esta skill olha o ambiente real e responde, antes de gastar uma execução, "esse ambiente consegue rodar esses cenários?". Não executa cenário nenhum.

---

## Regra fundamental (guardrails)

- **Somente leitura.** Nunca criar, alterar ou excluir dado, configuração, usuário, processo ou flag no ambiente — nem "só para destravar". Banco: apenas `SELECT`/`information_schema`. UI: apenas navegar e consultar telas de configuração; nunca salvar, publicar, ativar ou submeter formulário. Se um requisito só puder ser satisfeito alterando o ambiente, o resultado é `NAO ATENDIDO` e a skill descreve **o que precisa ser preparado** — quem prepara é a usuária ou o time.
- **Nunca rodar contra produção.** Se a URL do ambiente resolvido parecer produção (sem `hom`/`homolog`/`hml`/`dev` no domínio, ou a usuária não confirmar que é ambiente de teste), parar e perguntar antes de navegar.
- **Nunca marcar `ATENDIDO` sem evidência.** Cada `ATENDIDO` precisa apontar a observação que o comprova (tela/configuração consultada, resultado de query, valor encontrado). Sem evidência, o resultado é `NAO VERIFICAVEL`, nunca `ATENDIDO`.
- **Tentar antes de declarar `NAO VERIFICAVEL`.** As únicas razões válidas são: (1) falta de acesso (credencial, permissão, MCP indisponível) depois de uma tentativa real; (2) o requisito está redigido de forma que não permite verificação objetiva (vago, sem número, `HIPOTESE:`); (3) a verificação exigiria escrita ou ação irreversível. "Não tentei" ou "dá trabalho" não são motivos — tente no mesmo turno.
- **Nunca credenciais em texto.** Não registrar senha, token ou connection string no relatório.
- **Não reinterpretar o mapa.** Esta skill não cria, remove nem edita cenários ou pré-requisitos; se um pré-requisito parecer errado ou faltar, sinalize no relatório e deixe a correção para `/gerar-mapa-testes-v3`.

---

## Step 0 — Validar ferramentas e argumentos

1. Se `$ARGUMENTS` estiver vazio, pare e peça o ID da US.
2. Verifique que `mcp__azure-devops` está conectado (chamada de teste em `get_work_item`).
3. Verifique que `mcp__playwright` está conectado (`browser_tabs` com `action: "list"`). Se estiver indisponível, **não pare**: requisitos que só podem ser verificados pela UI viram `NAO VERIFICAVEL` (motivo: browser indisponível) e o relatório avisa.
4. Verifique se há MCP de banco somente leitura para o ambiente do SmartShare (nome a confirmar). Se não houver, requisitos que dependem de consulta a dados seguem para a UI quando possível; senão, `NAO VERIFICAVEL` (motivo: sem acesso de leitura ao banco).
5. **Gate de contexto**, igual ao de `/executar-teste` (Step 0.4): busque na memória e na KB do SmartShare por termos da US (nome da tela, do processo, do perfil) antes de navegar. Isso evita procurar por tentativa e erro onde uma configuração está. Em divergência entre KB e US, prevalece a US e a divergência é sinalizada no relatório.

---

## Step 1 — Localizar o mapa de testes

```
$parts    = "$ARGUMENTS".Trim() -split '\s+'
$itemId   = $parts[0]
$project  = if ($parts.Count -gt 1) { $parts[1].Trim('"') } else { $null }
$ambiente = if ($parts.Count -gt 2) { $parts[2] } else { "HMG" }
```

1. Busque o work item (`get_work_item`, `expand: "all"`; omita `project` se `$null`).
   - `System.WorkItemType` de User Story/PBI → siga.
   - Se `$itemId` já for um card `"Criar Mapa de Teste"` → use-o direto como `$MAPA_ITEM`.
   - Qualquer outro tipo (inclusive Bug) → pare e reporte que o ID não é uma US.
2. Nas `relations` da US, ache os filhos (`System.LinkTypes.Hierarchy-Forward`) e, entre eles, os de `System.WorkItemType` igual a `"Criar Mapa de Teste"`.
   - **Nenhum:** pare e sugira rodar `/gerar-mapa-testes-v3`.
   - **Mais de um:** liste ID, título e data de alteração e pergunte qual usar (default sugerido: o de `System.ChangedDate` mais recente).
3. Capture `$MAPA_ID`, `$STORY_ID`, `$STORY_TITLE` e `$DESCRIPTION_HTML` (`System.Description` do card).

---

## Step 2 — Extrair cenários e pré-requisitos

Parseie a tabela sob "Cenarios de teste" de `$DESCRIPTION_HTML` (mesma estrutura de `/executar-teste`, Step 2):

- cabeçalho de colunas: primeira linha — ignorar;
- linha de categoria: um único `<td colspan=9>` com `=== NOME ===` — guarda como categoria vigente;
- linha de cenário: 9 `<td>` na ordem `#`, `Cenario`, `Pre-requisitos`, `Acao`, `Resultado Esperado`, `Tipo`, `Tecnica`, `Dimensao`, `Origem`.

**Mapa com 8 colunas (sem `Pre-requisitos`):** é um mapa gerado antes da coluna existir. Pare e informe que não há pré-requisitos declarados para validar; sugira regerar o mapa com `/gerar-mapa-testes-v3`. Não tente inferir pré-requisitos por conta própria.

Para a coluna `Pre-requisitos` de cada cenário:

1. Divida a célula nos separadores `<br>` e leia cada item no formato `[CATEGORIA] requisito`. Categorias: `PROCESSO`, `USUARIO`, `DADOS`, `CONFIG`, `INTEGRACAO`, `AMBIENTE`.
2. `Nenhum específico` (ou `Nenhum especifico`) → cenário sem exigência: fica `EXECUTAVEL` direto, sem inspeção.
3. Item com prefixo `HIPOTESE:` → registre como `NAO VERIFICAVEL (hipótese)`; não tente verificar.
4. Item sem prefixo de categoria reconhecido → registre como `NAO VERIFICAVEL (formato)` e liste no relatório; não adivinhe a categoria.
5. Monte `$REQUISITOS` = lista de **requisitos distintos** (mesmo texto = mesmo requisito, validado uma única vez), cada um com os IDs dos cenários que dependem dele. Se o HTML tiver a seção "Pre-requisitos de ambiente (consolidado)", use-a para conferir; se divergir da soma das células, **a tabela de cenários prevalece** e a divergência é sinalizada.

---

## Step 3 — Planejar a verificação e confirmar

Antes de navegar, apresente ao usuário:

- ambiente e URL resolvidos;
- quantidade de cenários e de requisitos distintos, por categoria;
- como cada categoria será verificada (tabela abaixo) e o que ficará `NAO VERIFICAVEL` de antemão.

| Categoria | Como verificar (somente leitura) |
|---|---|
| `PROCESSO` | Telas de configuração/modelagem do processo ou workflow: contar e tipificar atividades/etapas, conferir regras e sequência. Banco read-only, se houver, para confirmar a definição |
| `USUARIO` | Cadastro de usuários/perfis/grupos: existência, quantidade, perfil e permissão. Nunca autenticar com credencial que não tenha sido fornecida pela usuária |
| `DADOS` | Consulta de leitura no banco ou busca na UI por registro que satisfaça o estado exigido (status, vazio, inexistente) |
| `CONFIG` | Telas de parâmetros/licenças/módulos; flags quando legíveis. Flag não legível → `NAO VERIFICAVEL` |
| `INTEGRACAO` | Acessibilidade do serviço (resposta de uma URL/tela de status, configuração do conector). Nunca disparar operação real com efeito colateral |
| `AMBIENTE` | Versão/build exibido pelo sistema, URL, disponibilidade da aplicação |

**Se `$ambiente` parecer produção, pare aqui e pergunte** (guardrail). Se o volume for grande (muitos requisitos), diga a ordem planejada — comece pelos requisitos que bloqueiam mais cenários — e prossiga; a verificação é somente leitura, não precisa de nova confirmação por requisito.

---

## Step 4 — Inspecionar o ambiente (somente leitura)

Para cada requisito de `$REQUISITOS`, na ordem planejada:

1. Verifique conforme a tabela do Step 3. Reaproveite uma observação já feita (ex.: a mesma tela de usuários serve a vários requisitos `USUARIO`).
2. Atribua o status:
   - **`ATENDIDO`** — a observação comprova o requisito, com a quantidade/estado exigido (ex.: exigia "2 atividades de usuário" e o processo tem exatamente 2 ou mais, conforme a redação — registre o valor observado).
   - **`NAO ATENDIDO`** — a observação mostra que o ambiente não tem o que se pede (ex.: processo com 1 atividade de usuário). Registre o valor observado e o que falta para atender.
   - **`NAO VERIFICAVEL`** — não foi possível observar, com uma das 3 razões válidas das regras fundamentais, indicando qual.
3. Registre **evidência curta** por requisito: onde olhou (tela/menu ou consulta) e o valor encontrado. Em UI, tire screenshot só quando a evidência não for textual. Em banco, registre a consulta (sem dados sensíveis) e o resumo do resultado.
4. Se uma observação revelar algo relevante fora do que o requisito pede (ex.: o processo existe, mas está inativo), registre como **observação** no requisito — sem converter em novo requisito nem alterar o mapa.

Pare e peça ajuda à usuária (uma pergunta objetiva) só quando faltar acesso que ela provavelmente tem (credencial, permissão para uma tela). Antes de perguntar, mostre o que já tentou. Se ela não puder ajudar, siga com `NAO VERIFICAVEL`.

---

## Step 5 — Calcular a viabilidade por cenário

Para cada cenário, combine o status dos seus requisitos:

| Situação dos requisitos do cenário | Viabilidade |
|---|---|
| todos `ATENDIDO`, ou `Nenhum específico` | **EXECUTAVEL** |
| algum `NAO ATENDIDO` | **BLOQUEADO** (cite o(s) requisito(s) que faltam) |
| nenhum `NAO ATENDIDO`, mas algum `NAO VERIFICAVEL` | **PARCIAL** (executável por conta e risco: cite o que não foi confirmado) |

`BLOQUEADO` prevalece sobre `PARCIAL`. Calcule também o resumo: totais por viabilidade e por categoria do mapa (`FLUXO PRINCIPAL`, `PERMISSAO`, etc.), e o **veredito geral**:

- **PRONTO** — nenhum cenário `BLOQUEADO` e nenhum `PARCIAL`;
- **PRONTO COM RESSALVAS** — nenhum `BLOQUEADO`, mas há `PARCIAL`;
- **PARCIALMENTE PRONTO** — há `BLOQUEADO` e há `EXECUTAVEL`/`PARCIAL`;
- **NAO PRONTO** — todos os cenários com algum requisito `NAO ATENDIDO`, ou o ambiente indisponível/produção.

---

## Step 6 — Relatório e persistência

Defina `$EXEC` = data e hora no formato `AAAA-MM-DD_HHmm`. Apresente no chat e grave **exatamente o mesmo conteúdo** em `$CICLOS_DIR\US-<ID>\validacoes-ambiente\US-<ID>_<$EXEC>.md`, com `$CICLOS_DIR` = `C:\skills-qualidade\ciclos-executados`, diretório único de registro, nunca relativo ao diretório de trabalho nem dentro de `skills-qa-smartshare` (crie os diretórios se não existirem; **nunca sobrescreva** uma validação anterior). Front matter:

```
---
us: <ID>
mapa: <MAPA_ID>
ambiente: <ambiente> (<URL>)
execucao: <$EXEC>
veredito: <PRONTO | PRONTO COM RESSALVAS | PARCIALMENTE PRONTO | NAO PRONTO>
---
```

Modelo do relatório:

```
# Validação de ambiente — #<ID> <Título da US>

Mapa: #<MAPA_ID> · Ambiente: <ambiente> (<URL>) · Execução: <$EXEC>
**Veredito: <veredito>** — <N> cenários: <a> executáveis, <b> parciais, <c> bloqueados

## Requisitos (<M> distintos)

| Requisito | Status | Evidência / valor observado | Cenários |
|---|---|---|---|
| [PROCESSO] fluxo com 2 atividades de usuário | NAO ATENDIDO | Processo "X" tem 1 atividade de usuário (Modelagem > Processo X) | #3, #7 |

## Viabilidade por cenário

| # | Cenário | Categoria | Viabilidade | Motivo (requisitos pendentes) |
|---|---|---|---|---|

## O que preparar no ambiente
- <requisito NAO ATENDIDO>: <o que falta, em termos acionáveis — ex.: "configurar processo com 2 atividades de usuário">

## Não verificados (e por quê)
- <requisito NAO VERIFICAVEL>: <razão válida>

## Observações
- <achados fora dos requisitos, divergências KB × US, divergência entre tabela e seção consolidada do mapa, itens com formato inválido>

## Próximo passo sugerido
- <PRONTO: rodar /executar-teste <ID>> · <RESSALVAS/PARCIAL: rodar /executar-teste ciente de que os cenários PARCIAL/BLOQUEADO podem virar NAO EXECUTADO> · <NAO PRONTO: preparar o ambiente e revalidar>
```

Esta skill **não altera nenhum work item** nem posta comentário. Se a usuária pedir para registrar o resultado na US, ofereça postar um comentário-resumo (veredito e "O que preparar no ambiente") — só com confirmação explícita, no mesmo padrão do Step 6.5 de `/gerar-mapa-testes-v3`.

---

## Step 7 — Registrar no log de ações (governança)

Acrescente uma linha ao final da tabela em `~/.claude/docs/projetos/skills-qa/LOG-ACOES.md` (via `Edit`, nunca sobrescrevendo o arquivo):

```
| <data/hora atual, ex.: `Get-Date -Format "yyyy-MM-dd HH:mm"`> | `/validar-ambiente` | Validação de ambiente (somente leitura) | US #<ID> / mapa #<MAPA_ID> | <Sucesso \| Parcial \| Falha> | <usuária> | veredito: <veredito>; <a>/<b>/<c> cenários exec./parc./bloq.; relatório: <caminho> |
```

---

## Troubleshooting

- **Mapa sem coluna `Pre-requisitos` (8 colunas):** não há o que validar. Pare e sugira regerar com `/gerar-mapa-testes-v3`; nunca invente pré-requisitos.
- **Muitos cenários `Nenhum específico`:** é válido. Eles entram como `EXECUTAVEL`; só informe a contagem.
- **Requisito vago** (ex.: "ambiente configurado", sem número): `NAO VERIFICAVEL (requisito vago)`; sugira reescrevê-lo no mapa com `/gerar-mapa-testes-v3` em vez de interpretá-lo.
- **Requisito verificável só com escrita** (ex.: "usuário consegue logar" exigiria autenticar com credencial ausente): `NAO VERIFICAVEL`, com a razão. Nunca criar usuário/dado para provar.
- **Ambiente indisponível ou instável:** veredito `NAO PRONTO`, motivo no relatório; não classifique requisitos individualmente por palpite.
- **Resultado muda entre execuções** (ambiente mutável): por isso cada validação é gravada com `$EXEC` e nunca sobrescrita; o relatório vale para o momento em que foi feito. Recomende revalidar logo antes de `/executar-teste` se houve mudança no ambiente.
- **Divergência entre a tabela e a seção consolidada do mapa:** a tabela de cenários prevalece; sinalize em "Observações".
- **Mapa com mais de um card "Criar Mapa de Teste":** sempre perguntar qual usar; nunca escolher sozinho sem confirmação.
