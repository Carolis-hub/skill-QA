---
version: 1.1
description: Le o mapa de testes publicado no card "Criar Mapa de Teste" filho de uma User Story do Azure DevOps, extrai a coluna Pre-requisitos (formato [CATEGORIA] requisito), valida no ambiente de teste se cada requisito existe e, quando nao existir, CONFIGURA o ambiente (cria usuarios, processos, configuracoes, dados) pela UI. URLs do ambiente, URLs de telas necessarias, admin e usuarios vem de um arquivo de configuracao preenchido pela usuaria (C:\skills-qualidade\config\ambiente-teste.local.md); usuarios criados sao gravados nele. Entrega, por requisito, ATENDIDO / CONFIGURADO / NAO ATENDIDO / NAO VERIFICAVEL e, por cenario, EXECUTAVEL / PARCIAL / BLOQUEADO. Nao executa os cenarios e nunca atua fora de ambiente marcado como teste.
---

**Versão da skill: 1.1** (2026-11-09) · histórico em `CHANGELOG.md`

Validar e preparar o ambiente para os testes da User Story do Azure DevOps a partir de **$ARGUMENTS**.

Formato esperado: `[ID da User Story] [nome do projeto (opcional)] [ambiente (opcional, default: HMG)]`

Exemplos:
- `157538` → projeto resolvido automaticamente a partir do próprio work item, ambiente HMG
- `157538 "Nome do Projeto" HMG`

Esta skill fica **entre** `/gerar-mapa-testes-v3` e `/executar-teste`: o primeiro declara, por cenário, o que o ambiente precisa ter (coluna `Pre-requisitos`); esta skill olha o ambiente real, **configura o que faltar** e responde "esse ambiente consegue rodar esses cenários?". Não executa cenário nenhum.

**Arquivo de configuração (`$AMBIENTE_CFG`)** = `C:\skills-qualidade\config\ambiente-teste.local.md`, caminho absoluto. É preenchido pela usuária (modelo em `templates\ambiente-teste.template.md`) com: ambientes, caminhos das telas de configuração (relativos à URL base), login/senha do admin e usuários de teste. Contém senhas: nunca vai para o GitHub nem para relatório/chat/work item. Tem também a seção **"Destinatário de e-mail de teste"** (só o endereço do domínio selbetti da usuária, sem senha), usada pela regra de notificação por e-mail (Step 4.6).

**URL base (`$URL_BASE`)** = perguntada à usuária **a cada execução** (Step 0.3), nunca assumida do arquivo. Ex.: `http://localhost:8080/smartshare/`. Toda URL de tela é `$URL_BASE` + caminho relativo da tabela "Telas de configuração" abaixo.

**Telas de configuração (caminhos relativos à `$URL_BASE`):**

| Tela | Caminho relativo | Uso |
|---|---|---|
| Menu configurações | `workspace/management/configuracoes` | ponto de entrada das configurações |
| Usuário | `workspace/management/usuario` (cadastro: `.../usuario/novo`) | listar e criar usuário (rota observada em 2026-10-23; `.../configuracoes/usuario` redireciona para a página inicial) |
| Perfil | `workspace/management/configuracoes/perfil` | criar perfil |
| Área | sem tela própria localizada: é um seletor "Área principal" no cadastro de usuário | selecionar área existente |
| Papel | `workspace/management/configuracoes/papel` | criar papel |
| Configuração do banco (webconfig) | `config/webconfig.aspx` | consultar e trocar o banco do ambiente (Step 0.3d); só por esta tela |

Perfil, área e papel são **dependências do cadastro de usuário** (Step 4.5). Na UI observada em 2026-10-23 a área não tem tela própria: o cadastro de usuário tem os seletores "Área principal" e "Papel principal", que listam as existentes; o tipo de usuário "Administrador" é um campo do cadastro. Os caminhos de perfil e papel acima vieram da usuária e não foram abertos nessa observação: confirmar ao usar.

---

## Regra transversal — Fidelidade à versão legada

Vale para todas as skills. O legado é a referência para descobrir o comportamento existente (a US explícita e as mudanças aprovadas prevalecem). Leia **`C:\skills-qualidade\skills-qa-smartshare\templates\DIRETRIZ_FIDELIDADE_LEGADO.md`** (fonte única; não replique o texto aqui) e aplique-a ao que esta skill faz: não presumir melhoria, investigar divergência legado × migrado e registrar exceção documentada.

## Regra transversal — Dúvidas viram aprendizados

Vale para todas as skills. Pasta: `C:\skills-qualidade\analises-diversas\aprendizados` (regras e formato em `README.md`, lista em `INDICE.md`).

1. **Antes de perguntar à usuária** qualquer dúvida, pendência ou pedido de retorno, ler `INDICE.md`. Se existir aprendizado `Ativo` aplicável à mesma situação (escopo `Geral`, da skill, ou da própria US), aplicar sem perguntar e escrever no relatório `Aplicado APR-NNN`.
2. **Ao perguntar**, depois da resposta e **antes de seguir**, gravar `APR-NNN_<slug>.md` (situação, pergunta, resposta, como aplicar, escopo) e a linha no `INDICE.md`. Resposta vaga ou adiada fica `Pendente`, não vira regra.
3. Nunca gravar segredo (senha, token, chave): registrar só "informado no chat, não gravado".
4. Resposta que contradiz um aprendizado: atualizar, marcar o antigo `Substituído por APR-NNN`.
5. O aprendizado **não dispensa** confirmação de ação irreversível ou de escrita, aprovação de recomendação (`REC-...`) nem os guardrails desta skill: nesses casos a skill pergunta, podendo citar o aprendizado como contexto.

## Regra fundamental (guardrails)

- **Só atua em ambiente de teste.** A `$URL_BASE` é informada pela usuária a cada execução (Step 0.3) e a skill só navega em URLs que comecem por ela. Host `localhost`/`127.0.0.1` é aceito como teste; qualquer outro host só é aceito se a usuária confirmar na hora que é teste (e, havendo o ambiente no `$AMBIENTE_CFG`, com `Tipo = teste`). Produção ou URL não confirmada → parar e perguntar antes de navegar. Nunca inventar URL.
- **Validar primeiro, configurar só o que falta.** Requisito já atendido não é tocado. Só se configura o que um requisito do mapa exige e que a verificação provou ausente.
- **Configuração é por UI, com plano confirmado.** Criar/ajustar pela interface (nunca `INSERT`/`UPDATE`/`DELETE` no banco; banco só `SELECT`). O que será configurado é apresentado no Step 3 e só começa com o "sim" explícito da usuária.
- **Aditivo e rastreável.** Pode **criar** (usuário, processo, parâmetro, registro) e **ligar/ajustar** configuração exigida pelo requisito. Nunca excluir nem sobrescrever dado/configuração existente que não seja do requisito, nunca redefinir senha de usuário existente, nunca conceder perfil de administrador a usuário de teste. **Única exceção:** o administrador de automação `Claude-adm` do Step 0.3b, criado uma única vez, a pedido da usuária, para uso exclusivo desta skill. Cada mudança é registrada no relatório com **antes → depois**, para a usuária poder desfazer.
- **Ação irreversível ou de efeito fora do ambiente pede confirmação própria**, mesmo com o plano aprovado: publicar/ativar versão que não pode ser revertida, disparar integração real, enviar e-mail/notificação real, apagar algo. Se o requisito só se satisfaz assim e a usuária não autorizar → `NAO ATENDIDO`.
- **Notificação por e-mail segue a regra do Step 4.6.** Sempre que um requisito ou cenário (de qualquer categoria) depender de e-mail de notificação enviado ou recebido, o destinatário só pode ser o e-mail do domínio selbetti da usuária, **confirmado por ela a cada execução**, e valem as regras de validade do Step 4.6. Nunca outro endereço, nunca webmail nem senha de caixa.
- **Nunca marcar `ATENDIDO` ou `CONFIGURADO` sem evidência.** Cada um precisa apontar a observação que o comprova (tela/consulta e valor encontrado). Depois de configurar, **reverifique** o requisito pela UI; sem confirmação → não vale.
- **Tentar antes de declarar `NAO VERIFICAVEL`/`NAO ATENDIDO`.** Razões válidas para `NAO VERIFICAVEL`: (1) falta de acesso (credencial, permissão, URL, MCP) depois de uma tentativa real; (2) requisito vago, sem número, `HIPOTESE:`; (3) só verificável por ação proibida acima. "Não tentei" não é motivo.
- **Credenciais só no `$AMBIENTE_CFG`.** Senha de admin e de usuário (informado ou criado) nunca vai ao relatório, ao chat, ao LOG-ACOES ou ao work item. Connection string e token idem.
- **Dúvida de conceito ou de como configurar: consultar o hub, senão sinalizar. Nunca inventar.** Termos do mapa que a skill não saiba definir (ex.: "o que é um usuário publicador?", "como crio um perfil?", qual permissão compõe um perfil, onde fica um parâmetro) seguem o Step 3.5. Sem definição no hub, KB ou memória, a skill **não chuta** perfil, permissão ou configuração: sinaliza à usuária e deixa o requisito `NAO VERIFICAVEL`/`NAO ATENDIDO`.
- **Banco de dados: perguntar, confirmar a base e só trocar pela tela de configuração.** A cada execução a skill pergunta se o ambiente deve estar em **SQL Server** ou **Oracle** e confirma a base (Step 0.3c). Se o banco atual for outro, troca pelo procedimento do Step 0.3d (`config/webconfig.aspx` + conferência do `appsettings.json` do net8 + reinício da API), registrando como foi feito. Nunca troca o banco por `UPDATE`/script no banco, nunca em ambiente que não seja de teste, e credenciais do banco só vêm do `$AMBIENTE_CFG` (nunca neste arquivo, no relatório ou no chat).
- **Não reinterpretar o mapa.** Esta skill não cria, remove nem edita cenários ou pré-requisitos; se um pré-requisito parecer errado ou faltar, sinalize e deixe a correção para `/gerar-mapa-testes-v3`.

- **Dado simulado (mock) invalida a validação.** O ambiente de teste deve ser o mais próximo possível do cenário real: tela ou endpoint que serve dado simulado (data service em memória, fixture, resposta fixa) não valida dado nem integração. A skill **sempre** verifica isso (Step 3.7) antes de configurar qualquer dado. Mock confirmado → **gera defeito imediatamente** (Step 3.7), por instrução da usuária de 2026-11-03, e o veredito nunca é `PRONTO`. Não "contorna" criando dado no mock.

---

## Regra — US de BE: sem pré-requisito de tela

**Escopo da regra (classificação técnica):** vale a classificação do mapa (Step 3.4 do `/gerar-mapa-testes-v3`). A regra se aplica quando a US é só BE e/ou API, sem FE; classificada com FE, não se aplica à parte de front. Sem classificação, vale o critério abaixo.

Quando a US é de back-end (título com `BE`, ex.: `(BE)`; descrição declarada de BE/back-end; ou módulo da API; em dúvida, pergunte à usuária), verifique e configure só o que a API e os dados exigem (build, usuário/perfil/sessão, massa de dados, configuração, acesso ao banco, cliente HTTP). Não configure nem exija pré-requisito que só serve a um fluxo de tela; se o mapa trouxer um, marque o requisito `NÃO VERIFICÁVEL` com o motivo `pré-requisito de FE em US de BE (defeito do mapa)`.

---

## Step 0 — Validar ferramentas, arquivo de configuração e argumentos

1. Se `$ARGUMENTS` estiver vazio, pare e peça o ID da US.
2. Verifique que `mcp__azure-devops` está conectado (chamada de teste em `get_work_item`).
3. **Pergunte a URL base (`$URL_BASE`), sempre, antes de qualquer outra coisa**, mesmo que já tenha sido informada em execução anterior ou conste no arquivo (pode sugerir como exemplo `http://localhost:8080/smartshare/`, mas só use após a resposta dela). Normalize para terminar com `/`. Em seguida, **leia `$AMBIENTE_CFG`.** Se não existir, crie-o a partir de `templates\ambiente-teste.template.md` (pasta `config` incluída), diga à usuária que ele precisa ser preenchido (admin, usuários) e **pare**. Se existir, resolva `$ambiente` (argumento ou `ambiente_padrao`) e extraia: admin e usuários do ambiente. As URLs das telas vêm de `$URL_BASE` + caminhos da tabela "Telas de configuração" (acima); a URL base do arquivo não é usada. Campo `<preencher>` necessário ao que será validado = informação ausente: pare e peça exatamente esse campo. Nunca adivinhe URL ou senha. O admin segue o Step 0.3b.

   **0.3b — Administrador de automação (`Claude-adm`).** Na tabela "Administração" do `$AMBIENTE_CFG`, procure uma linha do `$ambiente` com login `Claude-adm` e senha preenchida (não `<preencher>`).
   - **Existe:** faça login com ele (login/senha só do arquivo) e siga. Login falhou → não redefina a senha; trate como ausente e peça o admin de bootstrap abaixo (a linha antiga ganha a observação "login falhou em <data>").
   - **Não existe (primeira execução neste ambiente):** peça à usuária **uma única vez** um admin já existente do ambiente (login e senha informados no chat) apenas para criar o `Claude-adm`. Essa credencial de bootstrap é usada nesta execução e **não é gravada** em arquivo, relatório nem log. Com ela, crie o usuário `Claude-adm` pela tela de usuário (`$URL_BASE` + `workspace/management/configuracoes/usuario`), com o perfil de administrador do ambiente (se o perfil não for identificável, Step 3.5; não chute), senha aleatória de 16 caracteres gerada na hora (receita do Step 4.5) e e-mail, se obrigatório, no domínio de teste do ambiente. Reverifique (aparece no cadastro e o login com a senha gerada funciona) e grave no `$AMBIENTE_CFG`, via `Edit` (tabela "Administração": complete a linha `Claude-adm` marcada `A CRIAR`, ou anexe `ambiente | Claude-adm | senha | CRIADO | <data>` se não houver; nunca apague nem reescreva outras linhas).
   - Nas execuções seguintes e em `/executar-teste`, o `Claude-adm` é o admin padrão. Ele existe só para configurar o ambiente de teste: nunca o use para executar cenário nem o conceda a outro usuário.
   - Se a usuária não tiver admin de bootstrap ou o sistema recusar a criação (ex.: "Número de usuários disponíveis já foi alcançado", limite da licença): não tente liberar vaga desativando ou apagando usuários; registre o motivo na linha `Claude-adm` do `$AMBIENTE_CFG`, use o admin informado (ex.: `root`, registrado no arquivo **sem senha**; a senha é pedida no chat a cada execução) e rode só a verificação, sem criar usuários (requisitos [USUARIO] ausentes ficam `NAO ATENDIDO`).
   **0.3c — Banco de dados (SQL Server ou Oracle): perguntar e confirmar a base.** Logo depois do login, **pergunte à usuária, em uma pergunta objetiva, qual banco o ambiente deve usar nesta execução: SQL Server ou Oracle** (não assuma da execução anterior nem do arquivo; consulte `aprendizados\INDICE.md` antes, regra transversal). Em seguida **confirme a base**, lendo **sem alterar nada**: (a) a tela `$URL_BASE` + `config/webconfig.aspx` (Provider, Servidor/Instância, Base de Dados; não clique em "Salvar") e (b) a connection string de `C:\projetos_selbetti\smartshare-net8\src\3 - Core\Project.Core.Api\appsettings.json` (leitura; mascare usuário e senha). Mostre à usuária o resultado (provider, servidor/instância, base, sem senha) e peça o "confirmo":
   - **Banco atual = banco pedido, e as duas fontes concordam** → siga; registre `banco: <SQL Server | Oracle>` e a base confirmada.
   - **Banco atual ≠ banco pedido, ou `webconfig.aspx` e `appsettings.json` discordam** → faça a troca (Step 0.3d), só depois do "sim" dela (é mudança de configuração do ambiente).
   - **Teste que precisa valer nos dois bancos** (a US/mapa cita SQL Server e Oracle, ou CA de paridade): a skill prepara **um banco por vez**. Ao concluir 100% dos cenários em um banco, o `/executar-teste` (Step 5.5) abre um novo chat que roda `/validar-ambiente` para o outro banco e depois repassa **todos** os cenários. Nesta execução, valide apenas o banco informado e avise que o outro ficará para o novo chat.
   **Gate:** não inicie validação, configuração nem testes enquanto o banco e a base não estiverem **identificados e confirmados** pela leitura da configuração efetiva (não só pela resposta da usuária). Confirme também que **a aplicação e a API estão conectadas ao banco esperado**: webconfig e appsettings coerentes e, depois do reinício, evidência de conexão (login de usuário que só existe naquele banco, sem erro de conexão no log/inicialização da API). **Divergência entre as fontes (webconfig × appsettings × banco informado × comportamento da API) após a troca, ou conexão que não confirma:** interrompa e informe o problema; não prossiga.
   Grave `banco:` e a base no cabeçalho do relatório (Step 6).

   **0.3d — Troca de banco (procedimento).** Parâmetros (provider, servidor/instância, base, usuário e senha do banco, caminho virtual, admin do SmartShare) vêm da seção **"Troca de banco"** do `$AMBIENTE_CFG` (linha do banco de destino); campo `<preencher>` ou linha ausente = informação ausente: peça à usuária exatamente esse campo e grave-o no arquivo (nunca em outro lugar). Passos:
   1. **Registre o estado de origem** (provider/servidor/base atuais, sem senha), para poder voltar.
   2. Navegue para `$URL_BASE` + `config/webconfig.aspx` e preencha: em **Banco de dados**, Provider, Servidor/Instância, Base de Dados, Usuário e Senha; em **SmartShare**, Caminho Virtual (ex.: `/smartshare/`), Usuário Administrador e Senha. **Oracle:** o campo Base de Dados fica **em branco** (desabilitado para Oracle); Provider `System.Data.OracleClient`. **SQL Server:** use os valores da linha SQL Server do arquivo (Base de Dados preenchida). Clique em **Salvar** e **confirme a mensagem de sucesso** (sem ela, a troca não vale: registre a mensagem do sistema e pare).
   *Regra do procedimento: não avance para a etapa seguinte sem confirmar o resultado da anterior; registre o resultado de cada etapa (ok / mensagem do sistema).*
   3. **Validar a configuração da API .NET 8:** abra (somente leitura) `C:\projetos_selbetti\smartshare-net8\src\3 - Core\Project.Core.Api\appsettings.json` e valide a connection string: provider/provedor de conexão, servidor/instância, base (quando aplicável), usuário e demais parâmetros, e a **correspondência com o que foi salvo no `webconfig.aspx`**. Não copie senha para relatório ou log. Não alterou? Não edite à mão: reporte a divergência e pare.
   4. **Reinicializar a API do net8 (etapa obrigatória).** O `appsettings.json` alterado não conclui a troca. (a) **Identifique o processo** da API em execução (ex.: processo `dotnet`/`Project.Core.Api`, porta, serviço); (b) **reinicie** conforme o procedimento do ambiente (use o aprendizado registrado, se houver; senão peça à usuária o método e aguarde a confirmação, e registre-o); (c) confirme que **iniciou sem erro**; (d) verifique que a conexão aponta para o banco de destino; (e) se houver erro de conexão/inicialização, investigue (log, connection string, instância, credenciais) e registre causa e solução. Sem reinício confirmado, a troca não está concluída.
   5. **Reverificar:** repita a leitura do item 0.3c (webconfig + appsettings coerentes com o destino), confirme a conexão da API e o login pela tela com o admin (`Claude-adm`/`root`, Step 0.3b; usuário criado em um banco só autentica naquele banco). Sem login concluindo → `NAO ATENDIDO` com a mensagem; não tente contornar.
   6. **Registrar o aprendizado da troca:** ao terminar (sucesso ou não), grave `C:\skills-qualidade\analises-diversas\aprendizados\APR-NNN_troca-de-banco-<origem>-para-<destino>.md` (e a linha em `INDICE.md`, conforme `README.md` da pasta) descrevendo **como a troca foi feita nesta execução, de forma estruturada**: etapas executadas; arquivos e configurações alterados; procedimento de reinicialização (processo, comando/serviço, tempo de espera); como a conexão foi confirmada; problemas encontrados e respectivas soluções; particularidades da configuração do banco (ex.: Oracle sem Base de Dados, provider `System.Data.OracleClient`; SQL Server com `System.Data.SqlClient`, instância e base). **Nunca grave senha ou connection string completa**. O objetivo é a skill repetir a troca entre SQL Server e Oracle sozinha: nas execuções seguintes, leia esse aprendizado primeiro e siga-o, sem a usuária repetir o passo a passo; se a prática mudou, atualize o mesmo aprendizado.
   Esta é a skill de preparar o ambiente (`validar-ambiente`); o procedimento vale para qualquer direção (SQL Server → Oracle ou Oracle → SQL Server). Só se executa em ambiente de teste e com o "sim" da usuária.
4. Verifique que `mcp__playwright` está conectado. Se indisponível, **não pare**: tudo que depende da UI vira `NAO VERIFICAVEL` (motivo: browser indisponível) e nada é configurado.
5. Verifique se há MCP de banco somente leitura para o ambiente (nome a confirmar). Se não houver, a verificação segue pela UI; senão `NAO VERIFICAVEL` (sem acesso de leitura ao banco).
   **0.5b — Conector Figma.** Se algum requisito do mapa for de acesso ao protótipo (ex.: `[AMBIENTE] acesso ao protótipo Figma da US`) ou a US trouxer link do Figma, verifique se o **conector Figma** está conectado ao chat (ferramentas do servidor Figma, por exemplo `get_metadata`, `get_screenshot` e `whoami`; se estiverem como ferramentas adiadas, carregue-as com `ToolSearch`). Conector ausente → o requisito fica `NAO VERIFICAVEL (conector Figma não conectado)`; peça à usuária para conectá-lo ao chat. **Nunca** digite login/senha do Figma no navegador nem use credencial do `$AMBIENTE_CFG` para autenticar: a autenticação é da usuária, pelo conector.
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

- ambiente, `$URL_BASE` informada, as URLs de tela (base + caminho) que serão usadas e o **banco** confirmado no Step 0.3c (e a troca de banco, se for fazer);
- quantidade de cenários e de requisitos distintos, por categoria;
- como cada categoria será verificada e **o que será configurado caso falte** (tabela abaixo), com o que ficará `NAO VERIFICAVEL` de antemão.

| Categoria | Verificar | Se não existir, configurar (UI do ambiente de teste) |
|---|---|---|
| `PROCESSO` | Telas de modelagem/workflow: contar e tipificar atividades/etapas, regras e sequência | Criar o processo/fluxo com a estrutura exigida (ex.: 2 atividades de usuário). Publicar/ativar só com confirmação própria (irreversível?) |
| `USUARIO` | Primeiro o `$AMBIENTE_CFG` (usuário informado), depois o cadastro do ambiente: existência, perfil, permissão | Criar o usuário com o perfil mínimo exigido (Step 4.5) e gravar login/senha no `$AMBIENTE_CFG` |
| `DADOS` | `SELECT` no banco read-only, ou busca na UI por registro no estado exigido (status, vazio, inexistente) | Criar o registro pela UI no estado exigido. Estado que só o banco/rotina produz → `NAO ATENDIDO` com instrução |
| `CONFIG` | Telas de parâmetros/licenças/módulos; flags quando legíveis | Ajustar o parâmetro/módulo exigido, registrando o valor anterior. Flag não legível/editável → `NAO VERIFICAVEL` |
| `INTEGRACAO` | Acessibilidade do serviço (URL/tela de status, conector configurado) | Só configurar o conector no ambiente de teste. Nunca disparar operação real com efeito colateral |
| `AMBIENTE` | Versão/build, URL, disponibilidade. **Protótipo Figma:** pelo conector (Step 0.5b), extraia `fileKey` e `node-id` do link da US (`figma.com/design/<fileKey>/...?node-id=<a>-<b>` → nó `<a>:<b>`) e chame `get_metadata` nesse nó (somente leitura). Respondeu com os frames → `ATENDIDO` (evidência: nome do arquivo/página e frames encontrados, ex.: "Handoff", "Fluxo completo"); link sem `node-id` → liste as páginas (`get_metadata` sem nó) e peça um link do nó; erro de permissão/arquivo → `NAO ATENDIDO` com a mensagem; sem conector → `NAO VERIFICAVEL` | Nada a configurar: divergência vira `NAO ATENDIDO` com instrução |

**Notificação por e-mail:** se algum requisito depender dela (Step 4.6), mostre também aqui o endereço selbetti lido de "Destinatário de e-mail de teste" no `$AMBIENTE_CFG` e **peça à usuária para confirmá-lo** (e para confirmar que o Agent está em execução) antes de configurar qualquer coisa. A confirmação é **obrigatória em toda execução, mesmo com o endereço preenchido no arquivo**: mostre o endereço escrito por extenso, peça para conferir a grafia (um erro de digitação manda o e-mail a outra pessoa) e só siga com o "confirmo" dela; se ela corrigir, use o endereço corrigido nesta execução e avise que o arquivo precisa ser ajustado (não o reescreva sem pedido). Endereço ausente ou `<preencher>` → peça o campo. Sem a confirmação, os requisitos de e-mail ficam `NAO VERIFICAVEL (destinatário não confirmado)`.

Liste explicitamente cada item que será criado/alterado (`o quê`, `onde`, `valor`). **A configuração só começa com o "sim" da usuária neste plano**; sem ele, a skill roda só a verificação e os ausentes ficam `NAO ATENDIDO`. Se `$ambiente` parecer produção ou não for `teste` no arquivo, pare aqui (guardrail). Com muitos requisitos, diga a ordem planejada — comece pelos que bloqueiam mais cenários — e prossiga; não pede nova confirmação por requisito, salvo ação irreversível.

---

## Step 3.5 — Resolver dúvidas de conceito e de configuração (hub primeiro)

Para cada requisito cujo termo ou configuração a skill não saiba definir (ex.: "usuário publicador", "como criar um perfil", quais permissões formam um perfil, onde fica um parâmetro), antes de verificar ou configurar, nesta ordem:

1. **Hub (código, somente leitura).** Localize-o por `SMARTSHARE_HUB`; se ausente, `C:\GIT\smartshare-hub`. Busque o termo e sua configuração: enums/constantes de perfil e permissão, seeds/migrations, telas e serviços de cadastro de perfil/usuário, parâmetros. Cite `repositório, arquivo <path>` como evidência. **Regra fixa: não alterar nada no hub.** O hub (`SMARTSHARE_HUB` ou `C:\GIT\smartshare-hub`) é somente leitura: nenhum checkout, pull, fetch com alteração de branch, commit, push, edição, criação ou remoção de arquivo, nem execução de build, script ou comando que escreva no diretório.
2. **KB e memória do SmartShare** (Gate de contexto, Step 0.6).
3. **Não localizou?** **Sinalize à usuária** e não configure: diga o termo, o que buscou (hub: onde procurou; KB/memória) e a pergunta objetiva (ex.: "o que define o perfil publicador no SmartShare e como é criado?"). Registre em "Dúvidas sinalizadas" do relatório. O requisito fica `NAO VERIFICAVEL (definição não localizada)`; se a usuária responder na hora, siga com a resposta e registre a fonte como "informado pela usuária".

Hub ausente (nenhum caminho existe) não é erro: pula o item 1 e registra que o código não foi consultado. O que o hub revelar entra como evidência, mas **não substitui** o texto do mapa: divergência entre hub e mapa vai para "Observações".

---

## Step 3.7 — Verificar se a tela e os dados são reais ou simulados (mock) — e gerar defeito se forem simulados

Roda **antes** de configurar qualquer dado (Step 4): criar dado em tela que usa mock não prova nada. Aplica-se a cada tela sob teste que o mapa usa (a da US e as que ela alimenta). É verificação de **leitura**: só usa dado que o plano do Step 3 já previa criar ou que já existe.

**Como verificar (registre cada evidência no relatório):**
1. **Rede.** Com a tela aberta, faça uma leitura (abrir a listagem) e, se o plano já previa gravar algo, uma gravação, e consulte `browser_network_requests` (ou `read_network_requests`). A tela não fez nenhuma chamada de API de dados (`/api`, `/be/`, serviço do BE) → indício de mock. Chamada só de arquivos estáticos, i18n e shell da aplicação não conta como dado.
2. **Persistência.** Depois de criar **um** registro mínimo (só se o plano do Step 3 já previa criá-lo), recarregue a página (F5). Registro sumiu → dado em memória (mock).
3. **Fonte real.** Se o mesmo ambiente tem outra tela com dado real do mesmo domínio (ex.: o Clássico) e a listagem nova abre vazia ou diferente dela → indício de que não lê a mesma base.
4. **Código (somente leitura).** Se o caminho do código da tela é conhecido (hub ou clone local do projeto), procure `mock`, `simulad`, `INITIAL_`, `of(` no serviço de dados da tela e cite `arquivo:linha`. Não altere nada.

**Conclusão:** novo requisito implícito `[AMBIENTE] dados reais (não simulados) em <tela>`:
- `ATENDIDO` quando há chamada de API de dados **e** o registro persiste ao recarregar;
- `NAO ATENDIDO` (**mock confirmado**) com **duas ou mais** evidências concordando (rede + persistência, ou código + uma delas);
- `NAO VERIFICAVEL` quando não deu para observar (browser indisponível, evidência única ou contraditória).

**Se o mock for confirmado, gere o defeito agora, sem esperar o fim da validação e sem pedir nova aprovação** (instrução explícita da usuária, 2026-11-03: "para que seja possível realizar os testes o ambiente deve estar o mais próximo possível do cenário real"). Siga o formato do `/gerar-defeito` e crie via MCP (nunca REST para criar):
- **Título:** `BUG - [Ambiente de teste usa dados simulados (mock) em <tela>]`;
- **ReproSteps** (campo `Microsoft.VSTS.TCM.ReproSteps`, em HTML): contexto (US, mapa, ambiente e URL base), **cenário de origem** no rótulo fixo `<p><strong>Cenário de origem:</strong> N/A — validação de ambiente do mapa de testes #<MAPA_ID></p>`, passos para reproduzir cada evidência, resultado esperado (dado real vindo do BE/banco, persistente, igual ao cenário de produção), resultado atual com as evidências (chamadas de rede ausentes, registro que some, trecho do código com `arquivo:linha`), impacto (resultado de teste de dado e de integração não reflete o cenário real; cenários que dependem de dado persistente ou legado ficam sem valor de aceite), ambiente e versão;
- **Severidade sugerida:** Alta, "a confirmar com o time" (impede validar dado e integração);
- **Vínculo:** filho da US (`wit_work_item_link_write`, `type: "parent"`), conferindo `Hierarchy-Reverse`; anexe as evidências pelo mesmo procedimento do Step 3.5 do `/gerar-defeito`;
- se a US ou a análise técnica **já declara** que a simulação é provisória (ex.: "sem integração com o BE: simulado no data service mock"), diga isso no Bug e mesmo assim gere: a decisão de aceitar o risco é do time, não da skill;
- antes de criar, busque Bug aberto do mesmo problema (`search_work_items`) e, se existir, **comente nele** em vez de duplicar.

**Efeitos na validação:** o `[AMBIENTE] dados reais` fica `NAO ATENDIDO`; requisitos `[DADOS]` e `[INTEGRACAO]` que dependem da tela com mock viram `NAO ATENDIDO` com o motivo "dado simulado (ver Bug #<id>)" — **não** se tenta configurá-los (nada de dado criado em mock) —, e o veredito geral nunca é `PRONTO`: o máximo é `PARCIALMENTE PRONTO`, e os cenários que dependem da tela com mock ficam `BLOQUEADO` (motivo: dado simulado). O `/executar-teste` **recusa executar** em ambiente com mock (guardrail do Step 0.5 dele): o caminho é integrar a tela ao BE e revalidar.

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
3. **Prepare as dependências do usuário (perfil, área, papel).** Abra a tela de usuário (`$URL_BASE` + `workspace/management/configuracoes/usuario`) e identifique quais desses itens o cadastro exige. Para cada um que o requisito pede e **não existe**, crie-o antes do usuário pela respectiva tela (perfil e papel: telas da tabela "Telas de configuração"; área: sem tela própria, só seleção), sempre de forma aditiva e registrando antes → depois. Se o item já existe, reaproveite (não edite). Não localizou a definição de qual permissão compõe o perfil/papel → Step 3.5, não chute. A ordem de criação segue o que a tela de usuário exigir; não presuma.
4. **Crie** pelo cadastro de usuários do ambiente (`$URL_BASE` + caminho de usuário; admin do arquivo): login `qa.<perfil-sem-acento-minusculo>.us<ID>`; e-mail, se obrigatório, no domínio de teste do ambiente e nunca de pessoa real (**exceção:** usuário destinatário de notificação por e-mail usa o endereço selbetti confirmado da usuária, Step 4.6); senha aleatória de 16 caracteres gerada na hora (maiúscula, minúscula, número, símbolo), ex.: `-join ((48..57)+(65..90)+(97..122)+(33,35,36,37,42,43,45,63) | Get-Random -Count 16 | % {[char]$_})`; só o perfil/permissão exigido. Se o sistema forçar troca de senha no primeiro acesso, desmarque quando existir; senão faça o primeiro login, troque para a senha gerada e anote na Observação.
   **4.1 Vincule os perfis "Geral" (obrigatório ao criar qualquer usuário).** Logo depois de criar (o cadastro abre em `.../usuario/editar/<cd_usuario>`), abra a aba **Perfis** e, em **cada** seção da tela, marque o grupo **Geral** (o checkbox "Select Geral" no topo da árvore, que marca também os filhos), depois **Salvar**. Seções: **Grupos que atuam como leitor** e **Grupos para quem podem publicar** (todos os tipos de usuário) e, só para o tipo **Administrador**, também **Grupos que administram** (3 seções). Cada seção é um acordeão: expanda os fechados antes de marcar. Registre antes → depois. Observado em 2026-10-26: o checkbox só muda com clique de mouse real nas coordenadas dele (`mouse.click`), e `check({force:true})` não marca a partir da 2ª seção.
   **Também no mesmo cadastro, pois sem isso o login do usuário novo não conclui na tela** (a API `autenticar` responde 200, mas o front volta ao login com `You provided 'undefined' where a stream was expected`): escolha uma **Área principal ativa** (a área "TI" estava inativa: salvar com ela falha com "Usuário não pode ser ativado — Área Principal inativa"; use uma área ativa, ex.: "Area Padr?o") e preencha o **Menu inicial** (ex.: "Minhas atividades"). Observado em 2026-10-26 com o conjunto área ativa + perfis Geral + Menu inicial; qual dos três é o mínimo necessário não foi isolado.
5. **Reverifique:** o usuário aparece no cadastro com o perfil, os perfis "Geral" ficaram marcados ao reabrir a aba Perfis e o login com a senha gerada **conclui na tela** (entra em `/bpm?redirect=my-tasks`; faça em contexto de navegador separado para não derrubar a sessão do admin; depois deslogue). Só então `CONFIGURADO`.
6. **Grave** uma linha em "Usuários de teste" do `$AMBIENTE_CFG` (via `Edit`, **anexando**; nunca apague nem reescreva linhas existentes): `Login | Senha | Perfil | Ambiente | CRIADO | <US> | <data> | <obs>`.

### 4.6 — Notificação por e-mail (regra transversal)

Aplica-se **sempre** que um requisito ou cenário, de qualquer categoria, depender de notificação por e-mail enviada ou recebida (ex.: e-mail do BPM, aviso de documento, alerta de tarefa).

1. **Destinatário único.** Só o e-mail do domínio selbetti da usuária, lido de "Destinatário de e-mail de teste" no `$AMBIENTE_CFG` e **confirmado por ela a cada execução** (Step 3). Nunca outro endereço (pessoa real, domínio externo, Gmail), nunca login em webmail, nunca senha de caixa de e-mail.
2. **Agent.** O envio é feito pelo `SmartShareAgent`, serviço do Windows que a usuária mantém em execução. A skill não consegue verificá-lo pela UI: peça a confirmação (Step 3) e **nunca tente iniciar ou parar o serviço**. Sem confirmação → o envio fica `NAO VERIFICAVEL (Agent não confirmado)`.
3. **Regras de validade para receber** (lidas no código do clássico, `SmartShareAgent/Notify.cs`; no caminho novo do net8 são hipótese até o dev confirmar):
   - existe notificação **ativa** (`st_ativo = 1`) para o par aplicação/ação do evento; o par é único e o sistema recusa duplicado. Existindo, reaproveite sem editar; não existindo, crie pela tela;
   - o destinatário da notificação é um **perfil**, e os **perfis filhos** (por perfil pai) também recebem;
   - o usuário que recebe pertence a esse perfil (ou a um filho), está **ativo**, **não está ausente** e tem o e-mail igual ao endereço selbetti confirmado.
4. **Usuário destinatário.** Reaproveite um usuário de teste que cumpra o item 3; senão crie conforme o 4.5, com o e-mail selbetti confirmado. **Nunca altere o e-mail de um usuário existente** (regra aditiva).
5. **Todos os destinatários do perfil.** Antes de qualquer disparo, liste os usuários do perfil destinatário (e dos filhos) com o e-mail de cada um. Se algum tiver e-mail que não seja o selbetti confirmado ou um endereço de teste, **não dispare**: sinalize em "Dúvidas sinalizadas" e deixe o requisito `NAO ATENDIDO`. Disparar o envio é efeito fora do ambiente e segue a confirmação própria da regra fundamental.
6. **Par aplicação/ação.** Pela tela de Gerenciamento de Notificação, para **cada aplicação selecionada**, liste as ações disponíveis (somente leitura, sem salvar) e registre os pares no relatório, na seção "Pares aplicação/ação". Se o dev informou o par exato, use-o; senão é **hipótese** e fica marcada como tal. Sem URL confirmada da tela, peça-a (nunca invente).
7. **Acesso à caixa.** A leitura dos e-mails recebidos é feita pelo conector Outlook da usuária (somente busca e leitura), na execução dos cenários. Aqui basta confirmar que o conector está conectado; se não estiver, `NAO VERIFICAVEL (conector de e-mail não conectado)`. Nunca clicar em links do e-mail, responder, encaminhar ou apagar.

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
banco: <SQL Server | Oracle> (base/instância confirmada)
execucao: <$EXEC>
veredito: <PRONTO | PRONTO COM RESSALVAS | PARCIALMENTE PRONTO | NAO PRONTO>
configurado: <n itens configurados>
---
```

Modelo do relatório:

```
# Validação de ambiente — #<ID> <Título da US>

Mapa: #<MAPA_ID> · Ambiente: <ambiente> (<URL>) · Banco: <SQL Server | Oracle> · Execução: <$EXEC>
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

## Notificação por e-mail (só se aplicável, Step 4.6)
- Destinatário confirmado pela usuária: <sim/não> · Agent confirmado em execução: <sim/não> · Conector de e-mail: <conectado/não>
| Aplicação | Ações disponíveis na tela | Par usado | Origem (informado pelo dev / hipótese) |
|---|---|---|---|

## Dúvidas sinalizadas
- <termo/configuração>: <onde buscou (hub: repositório/arquivo, KB, memória)> — <pergunta objetiva à usuária>

## Dados simulados (mock) — Step 3.7
| Tela | Rede (chamadas de API de dados) | Persiste ao recarregar? | Fonte real comparada | Código | Conclusão | Bug |
|---|---|---|---|---|---|---|
(ou `Dados reais confirmados` / `NAO VERIFICAVEL: <motivo>`)

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

- **Banco não confirmado ou webconfig e appsettings discordando:** não valide nem configure dado; resolva o banco primeiro (Step 0.3c/0.3d). Dados criados em um banco não existem no outro (usuários, processos): cada troca de banco exige nova validação do ambiente.
- **Troca de banco sem reiniciar a API do net8:** a connection string do `appsettings.json` só é relida no reinício; login falhando logo após a troca costuma ser API ainda no banco antigo.

- **Mapa sem coluna `Pre-requisitos` (8 colunas):** não há o que validar. Pare e sugira regerar com `/gerar-mapa-testes-v3`; nunca invente pré-requisitos.
- **Muitos cenários `Nenhum específico`:** é válido. Eles entram como `EXECUTAVEL`; só informe a contagem.
- **Requisito vago** (ex.: "ambiente configurado", sem número): `NAO VERIFICAVEL (requisito vago)`; sugira reescrevê-lo no mapa com `/gerar-mapa-testes-v3` em vez de interpretá-lo.
- **Termo desconhecido (ex.: "usuário publicador") ou perfil que não sabe criar:** consultar o hub (Step 3.5); sem definição lá, sinalizar à usuária e não criar perfil/usuário por palpite.
- **`$AMBIENTE_CFG` ausente ou com `<preencher>` no que é necessário:** criar a partir do modelo e parar pedindo o campo exato; nunca adivinhar URL/senha.
- **URL base:** sempre perguntada no início de cada execução (Step 0.3); não reutilizar a de execução anterior sem perguntar.
- **Tela de área:** usa o mesmo caminho da tela de perfil (confirmado pela usuária); se a tela não tiver o cadastro de área, localizar pelo menu configurações e perguntar.
- **Criação de usuário falha por perfil/área/papel inexistente:** criar a dependência pela tela própria (Step 4.5.3); se a definição de permissões não for localizada, Step 3.5.
- **Primeira execução sem `Claude-adm`:** pedir o admin de bootstrap (uma vez, não gravado), criar o `Claude-adm` e anexá-lo ao `$AMBIENTE_CFG` (Step 0.3b). Nunca gravar a senha do admin de bootstrap.
- **Plano de configuração não aprovado / sem admin no arquivo / ambiente não `teste`:** rodar só a verificação; ausentes ficam `NAO ATENDIDO` com instrução em "O que preparar no ambiente".
- **Configuração recusada pelo sistema** (permissão, campo obrigatório, regra de negócio): `NAO ATENDIDO` com a mensagem; não contornar nem alterar outra configuração para "destravar".
- **Requisito que só se satisfaz com ação irreversível ou efeito externo** (publicar versão definitiva, integração real, notificação): pedir confirmação própria; sem ela, `NAO ATENDIDO`.
- **Protótipo Figma sem acesso** (página de login do Figma no navegador, "Cadastre-se ou faça login"): não autenticar pelo navegador. Usar o conector Figma (Step 0.5b); se a usuária ainda não o conectou, requisito `NAO VERIFICAVEL (conector Figma não conectado)` e a pendência "conectar o Figma ao chat" em "O que preparar no ambiente". Com o conector, o cenário de paridade visual (`/executar-teste`) lê o protótipo por `get_screenshot`/`get_metadata`.
- **Usuário recém-criado autentica (API 200) mas a tela de login não avança:** conferir se os perfis **Geral** foram vinculados nas seções da aba Perfis (3 para Administrador, 2 para os demais), se a área principal está **ativa** e se o **Menu inicial** está preenchido (Step 4.5, item 4.1). Não redefinir senha nem alterar outro cadastro para contornar.
- **E-mail de notificação não chega:** conferir, nesta ordem, Agent em execução (pedir à usuária), notificação ativa para o par, perfil destinatário (e filhos), usuário ativo, não ausente e com o e-mail selbetti. Não alterar a configuração de e-mail do ambiente para "destravar".
- **Usuário do arquivo apagado do ambiente ou com login falho:** não reutilizar nem redefinir senha; criar outro e anotar na linha antiga.
- **`$AMBIENTE_CFG` guarda senha em texto:** intencional e restrito a ambiente de teste; o arquivo fica fora do sync com o GitHub.
- **Ambiente indisponível ou instável:** veredito `NAO PRONTO`, motivo no relatório; não classifique requisitos individualmente por palpite.
- **Resultado muda entre execuções** (ambiente mutável): por isso cada validação é gravada com `$EXEC` e nunca sobrescrita; o relatório vale para o momento em que foi feito. Recomende revalidar logo antes de `/executar-teste` se houve mudança no ambiente.
- **Divergência entre a tabela e a seção consolidada do mapa:** a tabela de cenários prevalece; sinalize em "Observações".
- **Mapa com mais de um card "Criar Mapa de Teste":** sempre perguntar qual usar; nunca escolher sozinho sem confirmação.
- **Tela só carrega shell, i18n e arquivos estáticos e nenhuma chamada de dado:** é o indício mais forte de mock (Step 3.7). Confirme com a persistência (F5) antes de gerar o defeito; uma única evidência não basta.
- **Mock confirmado numa US que já avisa "simulado até a integração":** o defeito sai do mesmo jeito (decisão da usuária, 2026-11-03), citando o aviso; a decisão de aceitar é do time.
