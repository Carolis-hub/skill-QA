---
description: Le o mapa de testes publicado no card "Criar Mapa de Teste" filho de uma User Story do Azure DevOps, extrai a coluna Pre-requisitos (formato [CATEGORIA] requisito), valida no ambiente de teste se cada requisito existe e, quando nao existir, CONFIGURA o ambiente (cria usuarios, processos, configuracoes, dados) pela UI. URLs do ambiente, URLs de telas necessarias, admin e usuarios vem de um arquivo de configuracao preenchido pela usuaria (C:\skills-qualidade\config\ambiente-teste.local.md); usuarios criados sao gravados nele. Entrega, por requisito, ATENDIDO / CONFIGURADO / NAO ATENDIDO / NAO VERIFICAVEL e, por cenario, EXECUTAVEL / PARCIAL / BLOQUEADO. Nao executa os cenarios e nunca atua fora de ambiente marcado como teste.
---

Validar e preparar o ambiente para os testes da User Story do Azure DevOps a partir de **$ARGUMENTS**.

Formato esperado: `[ID da User Story] [nome do projeto (opcional)] [ambiente (opcional, default: HMG)]`

Exemplos:
- `157538` → projeto resolvido automaticamente a partir do próprio work item, ambiente HMG
- `157538 "Nome do Projeto" HMG`

Esta skill fica **entre** `/gerar-mapa-testes-v3` e `/executar-teste`: o primeiro declara, por cenário, o que o ambiente precisa ter (coluna `Pre-requisitos`); esta skill olha o ambiente real, **configura o que faltar** e responde "esse ambiente consegue rodar esses cenários?". Não executa cenário nenhum.

**Arquivo de configuração (`$AMBIENTE_CFG`)** = `C:\skills-qualidade\config\ambiente-teste.local.md`, caminho absoluto. É preenchido pela usuária (modelo em `templates\ambiente-teste.template.md`) com: ambientes e URL base, URLs das telas necessárias, login/senha do admin e usuários de teste. Contém senhas: nunca vai para o GitHub nem para relatório/chat/work item.

---

## Regra fundamental (guardrails)

- **Só atua em ambiente de teste declarado no `$AMBIENTE_CFG`.** O ambiente precisa estar listado lá com `Tipo = teste` e a URL de navegação precisa pertencer à URL base dele. Qualquer outra URL (ou produção, ou URL que a usuária não confirmar como teste) → parar e perguntar antes de navegar. Nunca inventar URL.
- **Validar primeiro, configurar só o que falta.** Requisito já atendido não é tocado. Só se configura o que um requisito do mapa exige e que a verificação provou ausente.
- **Configuração é por UI, com plano confirmado.** Criar/ajustar pela interface (nunca `INSERT`/`UPDATE`/`DELETE` no banco; banco só `SELECT`). O que será configurado é apresentado no Step 3 e só começa com o "sim" explícito da usuária.
- **Aditivo e rastreável.** Pode **criar** (usuário, processo, parâmetro, registro) e **ligar/ajustar** configuração exigida pelo requisito. Nunca excluir nem sobrescrever dado/configuração existente que não seja do requisito, nunca redefinir senha de usuário existente, nunca conceder perfil de administrador a usuário de teste. Cada mudança é registrada no relatório com **antes → depois**, para a usuária poder desfazer.
- **Ação irreversível ou de efeito fora do ambiente pede confirmação própria**, mesmo com o plano aprovado: publicar/ativar versão que não pode ser revertida, disparar integração real, enviar e-mail/notificação real, apagar algo. Se o requisito só se satisfaz assim e a usuária não autorizar → `NAO ATENDIDO`.
- **Nunca marcar `ATENDIDO` ou `CONFIGURADO` sem evidência.** Cada um precisa apontar a observação que o comprova (tela/consulta e valor encontrado). Depois de configurar, **reverifique** o requisito pela UI; sem confirmação → não vale.
- **Tentar antes de declarar `NAO VERIFICAVEL`/`NAO ATENDIDO`.** Razões válidas para `NAO VERIFICAVEL`: (1) falta de acesso (credencial, permissão, URL, MCP) depois de uma tentativa real; (2) requisito vago, sem número, `HIPOTESE:`; (3) só verificável por ação proibida acima. "Não tentei" não é motivo.
- **Credenciais só no `$AMBIENTE_CFG`.** Senha de admin e de usuário (informado ou criado) nunca vai ao relatório, ao chat, ao LOG-ACOES ou ao work item. Connection string e token idem.
- **Dúvida de conceito ou de como configurar: consultar o hub, senão sinalizar. Nunca inventar.** Termos do mapa que a skill não saiba definir (ex.: "o que é um usuário publicador?", "como crio um perfil?", qual permissão compõe um perfil, onde fica um parâmetro) seguem o Step 3.5. Sem definição no hub, KB ou memória, a skill **não chuta** perfil, permissão ou configuração: sinaliza à usuária e deixa o requisito `NAO VERIFICAVEL`/`NAO ATENDIDO`.
- **Não reinterpretar o mapa.** Esta skill não cria, remove nem edita cenários ou pré-requisitos; se um pré-requisito parecer errado ou faltar, sinalize e deixe a correção para `/gerar-mapa-testes-v3`.

---

## Step 0 — Validar ferramentas, arquivo de configuração e argumentos

1. Se `$ARGUMENTS` estiver vazio, pare e peça o ID da US.
2. Verifique que `mcp__azure-devops` está conectado (chamada de teste em `get_work_item`).
3. **Leia `$AMBIENTE_CFG`.** Se não existir, crie-o a partir de `templates\ambiente-teste.template.md` (pasta `config` incluída), diga à usuária que ele precisa ser preenchido (URL base, URLs necessárias, admin, usuários) e **pare**. Se existir, resolva `$ambiente` (argumento ou `ambiente_padrao`) e extraia: URL base, URLs necessárias, admin e usuários do ambiente. Campo `<preencher>` necessário ao que será validado = informação ausente: pare e peça exatamente esse campo. Nunca adivinhe URL ou senha.
4. Verifique que `mcp__playwright` está conectado. Se indisponível, **não pare**: tudo que depende da UI vira `NAO VERIFICAVEL` (motivo: browser indisponível) e nada é configurado.
5. Verifique se há MCP de banco somente leitura para o ambiente (nome a confirmar). Se não houver, a verificação segue pela UI; senão `NAO VERIFICAVEL` (sem acesso de leitura ao banco).
6. **Gate de contexto**, igual ao de `/executar-teste` (Step 0.4): busque na memória e na KB do SmartShare por termos da US (tela, processo, perfil) antes de navegar, para saber onde cada configuração está. Em divergência entre KB e US, prevalece a US e a divergência é sinalizada.

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

## Step 3 — Planejar a verificação e a configuração, e confirmar

Antes de navegar, apresente à usuária:

- ambiente, URL base e as URLs do `$AMBIENTE_CFG` que serão usadas;
- quantidade de cenários e de requisitos distintos, por categoria;
- como cada categoria será verificada e **o que será configurado caso falte** (tabela abaixo), com o que ficará `NAO VERIFICAVEL` de antemão.

| Categoria | Verificar | Se não existir, configurar (UI do ambiente de teste) |
|---|---|---|
| `PROCESSO` | Telas de modelagem/workflow: contar e tipificar atividades/etapas, regras e sequência | Criar o processo/fluxo com a estrutura exigida (ex.: 2 atividades de usuário). Publicar/ativar só com confirmação própria (irreversível?) |
| `USUARIO` | Primeiro o `$AMBIENTE_CFG` (usuário informado), depois o cadastro do ambiente: existência, perfil, permissão | Criar o usuário com o perfil mínimo exigido (Step 4.5) e gravar login/senha no `$AMBIENTE_CFG` |
| `DADOS` | `SELECT` no banco read-only, ou busca na UI por registro no estado exigido (status, vazio, inexistente) | Criar o registro pela UI no estado exigido. Estado que só o banco/rotina produz → `NAO ATENDIDO` com instrução |
| `CONFIG` | Telas de parâmetros/licenças/módulos; flags quando legíveis | Ajustar o parâmetro/módulo exigido, registrando o valor anterior. Flag não legível/editável → `NAO VERIFICAVEL` |
| `INTEGRACAO` | Acessibilidade do serviço (URL/tela de status, conector configurado) | Só configurar o conector no ambiente de teste. Nunca disparar operação real com efeito colateral |
| `AMBIENTE` | Versão/build, URL, disponibilidade | Nada a configurar: divergência vira `NAO ATENDIDO` com instrução |

Liste explicitamente cada item que será criado/alterado (`o quê`, `onde`, `valor`). **A configuração só começa com o "sim" da usuária neste plano**; sem ele, a skill roda só a verificação e os ausentes ficam `NAO ATENDIDO`. Se `$ambiente` parecer produção ou não for `teste` no arquivo, pare aqui (guardrail). Com muitos requisitos, diga a ordem planejada — comece pelos que bloqueiam mais cenários — e prossiga; não pede nova confirmação por requisito, salvo ação irreversível.

---

## Step 3.5 — Resolver dúvidas de conceito e de configuração (hub primeiro)

Para cada requisito cujo termo ou configuração a skill não saiba definir (ex.: "usuário publicador", "como criar um perfil", quais permissões formam um perfil, onde fica um parâmetro), antes de verificar ou configurar, nesta ordem:

1. **Hub (código, somente leitura).** Localize-o por `SMARTSHARE_HUB`; se ausente, `C:\GIT\smartshare-hub`. Busque o termo e sua configuração: enums/constantes de perfil e permissão, seeds/migrations, telas e serviços de cadastro de perfil/usuário, parâmetros. Cite `repositório, arquivo <path>` como evidência. Nenhum checkout, pull, commit ou escrita no hub.
2. **KB e memória do SmartShare** (Gate de contexto, Step 0.6).
3. **Não localizou?** **Sinalize à usuária** e não configure: diga o termo, o que buscou (hub: onde procurou; KB/memória) e a pergunta objetiva (ex.: "o que define o perfil publicador no SmartShare e como é criado?"). Registre em "Dúvidas sinalizadas" do relatório. O requisito fica `NAO VERIFICAVEL (definição não localizada)`; se a usuária responder na hora, siga com a resposta e registre a fonte como "informado pela usuária".

Hub ausente (nenhum caminho existe) não é erro: pula o item 1 e registra que o código não foi consultado. O que o hub revelar entra como evidência, mas **não substitui** o texto do mapa: divergência entre hub e mapa vai para "Observações".

---

## Step 4 — Verificar e configurar o ambiente

Para cada requisito de `$REQUISITOS`, na ordem planejada:

1. **Verifique** conforme a tabela do Step 3. Reaproveite observações já feitas (a mesma tela de usuários serve a vários requisitos).
2. **Se atendido** → `ATENDIDO`, registrando o valor observado (ex.: exigia "2 atividades de usuário" e o processo tem 2).
3. **Se não atendido e configurável** (e a usuária aprovou o plano) → configure (Step 4.5 para usuário; demais categorias pela UI conforme a tabela), registrando **antes → depois**, e **reverifique**. Confirmado → `CONFIGURADO`. Não confirmado, ou o sistema recusou (permissão, validação, campo desconhecido) → `NAO ATENDIDO` com a mensagem do sistema; não tente contornar.
4. **Se não atendido e não configurável** (categoria `AMBIENTE`, estado que só o banco produz, plano não aprovado, ação irreversível não autorizada, falta de admin) → `NAO ATENDIDO`, valor observado e o que falta.
5. **Se não foi possível observar**, com uma das 3 razões válidas → `NAO VERIFICAVEL`, indicando qual.
6. Registre **evidência curta** por requisito: onde olhou e o valor. Screenshot só quando a evidência não for textual. Em banco, a consulta (sem dado sensível) e o resumo.
7. Achado relevante fora do requisito (ex.: o processo existe, mas está inativo) vai como **observação**, sem virar novo requisito nem alterar o mapa.

Pare e peça ajuda (uma pergunta objetiva) só quando faltar acesso que a usuária provavelmente tem. Antes de perguntar, mostre o que tentou. Se ela não puder ajudar, siga com `NAO VERIFICAVEL`.

### 4.5 — Usuários: reaproveitar, senão criar, e gravar no `$AMBIENTE_CFG`

1. **Defina o usuário** a partir do texto do requisito (ex.: "usuário com perfil Aprovador"). Vago, sem perfil identificável → `NAO VERIFICAVEL (requisito vago)`. Perfil/grupo inexistente no ambiente → não crie o perfil; `NAO ATENDIDO` com instrução. Um usuário serve a todos os requisitos que ele satisfaz.
2. **Reaproveite:** procure em "Usuários de teste" do `$AMBIENTE_CFG` um usuário do ambiente com esse perfil e confirme que existe e entra (login com a credencial do arquivo). Existindo → `ATENDIDO` (evidência: "informado em `$AMBIENTE_CFG`, login confirmado"). Falhou o login → não redefina a senha; trate como ausente e crie outro (observação na linha antiga: "login falhou em <data>").
3. **Crie** pelo cadastro de usuários do ambiente (URL do `$AMBIENTE_CFG`; admin do arquivo): login `qa.<perfil-sem-acento-minusculo>.us<ID>`; e-mail, se obrigatório, no domínio de teste do ambiente e nunca de pessoa real; senha aleatória de 16 caracteres gerada na hora (maiúscula, minúscula, número, símbolo), ex.: `-join ((48..57)+(65..90)+(97..122)+(33,35,36,37,42,43,45,63) | Get-Random -Count 16 | % {[char]$_})`; só o perfil/permissão exigido. Se o sistema forçar troca de senha no primeiro acesso, desmarque quando existir; senão faça o primeiro login, troque para a senha gerada e anote na Observação.
4. **Reverifique:** o usuário aparece no cadastro com o perfil e o login com a senha gerada funciona (depois deslogue). Só então `CONFIGURADO`.
5. **Grave** uma linha em "Usuários de teste" do `$AMBIENTE_CFG` (via `Edit`, **anexando**; nunca apague nem reescreva linhas existentes): `Login | Senha | Perfil | Ambiente | CRIADO | <US> | <data> | <obs>`.

---

## Step 5 — Calcular a viabilidade por cenário

Para cada cenário, combine o status dos seus requisitos:

| Situação dos requisitos do cenário | Viabilidade |
|---|---|
| todos `ATENDIDO`/`CONFIGURADO`, ou `Nenhum específico` | **EXECUTAVEL** |
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
configurado: <n itens configurados>
---
```

Modelo do relatório:

```
# Validação de ambiente — #<ID> <Título da US>

Mapa: #<MAPA_ID> · Ambiente: <ambiente> (<URL>) · Execução: <$EXEC>
**Veredito: <veredito>** — <N> cenários: <a> executáveis, <b> parciais, <c> bloqueados · <k> itens configurados

## Requisitos (<M> distintos)

| Requisito | Status (ATENDIDO / CONFIGURADO / NAO ATENDIDO / NAO VERIFICAVEL) | Evidência / valor observado | Cenários |
|---|---|---|---|
| [PROCESSO] fluxo com 2 atividades de usuário | NAO ATENDIDO | Processo "X" tem 1 atividade de usuário (Modelagem > Processo X) | #3, #7 |

## Viabilidade por cenário

| # | Cenário | Categoria | Viabilidade | Motivo (requisitos pendentes) |
|---|---|---|---|---|

## O que foi configurado (antes → depois)
| Requisito | O que foi feito | Onde (tela/URL) | Antes → depois |
|---|---|---|---|

## O que preparar no ambiente (pendente — não foi possível configurar)
- <requisito NAO ATENDIDO>: <o que falta, em termos acionáveis — ex.: "configurar processo com 2 atividades de usuário">

## Usuários de teste
| Login | Perfil | Situação (INFORMADO / CRIADO / FALHA) | Cenários |
|---|---|---|---|

Credenciais em `$AMBIENTE_CFG` — a senha **não** aparece neste relatório.

## Dúvidas sinalizadas
- <termo/configuração>: <onde buscou (hub: repositório/arquivo, KB, memória)> — <pergunta objetiva à usuária>

## Não verificados (e por quê)
- <requisito NAO VERIFICAVEL>: <razão válida>

## Observações
- <achados fora dos requisitos, divergências KB × US, divergência entre tabela e seção consolidada do mapa, itens com formato inválido>

## Próximo passo sugerido
- <PRONTO: rodar /executar-teste <ID>> · <RESSALVAS/PARCIAL: rodar /executar-teste ciente de que os cenários PARCIAL/BLOQUEADO podem virar NAO EXECUTADO> · <NAO PRONTO: preparar o ambiente e revalidar>
```

Esta skill **não altera nenhum work item** nem posta comentário (e o comentário, se pedido, nunca inclui senha). A configuração do ambiente é a única escrita que ela faz. Se a usuária pedir para registrar o resultado na US, ofereça postar um comentário-resumo (veredito e "O que preparar no ambiente") — só com confirmação explícita, no mesmo padrão do Step 6.5 de `/gerar-mapa-testes-v3`.

---

## Step 7 — Registrar no log de ações (governança)

Acrescente uma linha ao final da tabela em `~/.claude/docs/projetos/skills-qa/LOG-ACOES.md` (via `Edit`, nunca sobrescrevendo o arquivo):

```
| <data/hora atual, ex.: `Get-Date -Format "yyyy-MM-dd HH:mm"`> | `/validar-ambiente` | Validação e configuração de ambiente de teste | US #<ID> / mapa #<MAPA_ID> | <Sucesso \| Parcial \| Falha> | <usuária> | veredito: <veredito>; <a>/<b>/<c> cenários exec./parc./bloq.; relatório: <caminho>; itens configurados: <k> (usuários: <n>) |
```

---

## Troubleshooting

- **Mapa sem coluna `Pre-requisitos` (8 colunas):** não há o que validar. Pare e sugira regerar com `/gerar-mapa-testes-v3`; nunca invente pré-requisitos.
- **Muitos cenários `Nenhum específico`:** é válido. Eles entram como `EXECUTAVEL`; só informe a contagem.
- **Requisito vago** (ex.: "ambiente configurado", sem número): `NAO VERIFICAVEL (requisito vago)`; sugira reescrevê-lo no mapa com `/gerar-mapa-testes-v3` em vez de interpretá-lo.
- **Termo desconhecido (ex.: "usuário publicador") ou perfil que não sabe criar:** consultar o hub (Step 3.5); sem definição lá, sinalizar à usuária e não criar perfil/usuário por palpite.
- **`$AMBIENTE_CFG` ausente ou com `<preencher>` no que é necessário:** criar a partir do modelo e parar pedindo o campo exato; nunca adivinhar URL/senha.
- **Plano de configuração não aprovado / sem admin no arquivo / ambiente não `teste`:** rodar só a verificação; ausentes ficam `NAO ATENDIDO` com instrução em "O que preparar no ambiente".
- **Configuração recusada pelo sistema** (permissão, campo obrigatório, regra de negócio): `NAO ATENDIDO` com a mensagem; não contornar nem alterar outra configuração para "destravar".
- **Requisito que só se satisfaz com ação irreversível ou efeito externo** (publicar versão definitiva, integração real, notificação): pedir confirmação própria; sem ela, `NAO ATENDIDO`.
- **Usuário do arquivo apagado do ambiente ou com login falho:** não reutilizar nem redefinir senha; criar outro e anotar na linha antiga.
- **`$AMBIENTE_CFG` guarda senha em texto:** intencional e restrito a ambiente de teste; o arquivo fica fora do sync com o GitHub.
- **Ambiente indisponível ou instável:** veredito `NAO PRONTO`, motivo no relatório; não classifique requisitos individualmente por palpite.
- **Resultado muda entre execuções** (ambiente mutável): por isso cada validação é gravada com `$EXEC` e nunca sobrescrita; o relatório vale para o momento em que foi feito. Recomende revalidar logo antes de `/executar-teste` se houve mudança no ambiente.
- **Divergência entre a tabela e a seção consolidada do mapa:** a tabela de cenários prevalece; sinalize em "Observações".
- **Mapa com mais de um card "Criar Mapa de Teste":** sempre perguntar qual usar; nunca escolher sozinho sem confirmação.
