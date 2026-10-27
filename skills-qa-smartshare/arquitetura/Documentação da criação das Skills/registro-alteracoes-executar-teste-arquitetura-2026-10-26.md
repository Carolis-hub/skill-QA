# Registro das alterações da skill `executar-teste` — Arquitetura do Share

## 1. Identificação

| Campo | Registro |
|---|---|
| Data | 26/10/2026 |
| Horário da documentação | 15:51:08 |
| Fuso horário | America/Sao_Paulo — UTC-03:00 |
| Pasta do registro | `D:\Skills QA - Share\skill-QA\skills-qa-smartshare\arquitetura\Documentação da criação das Skills` |
| Skill alterada | [`executar-teste.md`](../executar-teste.md) |
| Tipo de atividade | Adaptação e evolução de skill de execução de testes |
| Responsável pela execução | Codex |
| Status | Alterações aplicadas e validadas |

## 2. Objetivo

Adaptar a skill de execução de testes, originalmente criada para outro contexto de produto, para o fluxo realizado pelo time de **Arquitetura do Share**, preservando as variáveis e chamadas MCP necessárias para acesso ao Azure DevOps, Playwright e demais MCPs utilizados durante a execução.

Também foram adicionados controles para:

- validar os pré-requisitos do ambiente antes de iniciar qualquer cenário;
- pausar a rodada quando houver requisito pendente ou inconclusivo;
- permitir leituras em banco sem autorização prévia;
- exigir autorização explícita para `INSERT` e `UPDATE`;
- proibir `DELETE` direto no banco;
- explicar ao usuário como corrigir e retomar cenários não executados.

## 3. Prompts utilizados pelo solicitante

### 3.1. Prompt inicial de adaptação

> Essa é uma skill que foi criada para um outro produto que existe na empresa, ela tem o objetivo de realizar a execução dos testes mapeados nos mapas de testes da US, quero que voce adpte essa skill para a execução que é feita dentro do time de Arquitetura do Share, mantendo as variaveis de MCP para que a skill consiga ter acesso ao MPC sempre que precisar, e tambem adicione uma regra de validar todos os pre-requisitos dentro do ambiente disponibilizado para que os testes possam ocorrer corretamente, caso nao tenha todos os pre-requisitos necessários para realização dos cenários, a execução deverá ser pausada

### 3.2. Prompt de ajuste das regras de banco

> Edite de uma forma que fique mais ou menos nesse sentido
>
> "Validações em bancos poderão ser feitas com exceção somente de DELETE, leitura será feita sem solicitar autorização, e INSERT e UPDATE serão feitos mediante autorização do usuario executando a skill, essa solicitação de autorização deverá ser feita já no inicio da execução da skill, onde estiver sendo validados os requisitos, deverá ser feito uma analise se precisará realizar essas ações e já solicitar a autorização

### 3.3. Prompt de ajuste do encerramento da execução

> Adicione que ao finalizar a execução e restando testes que nao foram executados, deverá ser identificado para o usuario o porque de não ter sido executado e uma instrução para que o usuario da skill saiba o que fazer após realizar essas correções para execução dos cenarios

### 3.4. Prompt para criação deste registro

> Crie um documento dentro da pasta D:\Skills QA - Share\skill-QA\skills-qa-smartshare\arquitetura\Documentação da criação das Skills documentando todas essas alteações que foram feitas desde a skill base até agora, documente tambem o prompt usado, data e hora

## 4. Skill base analisada

A versão base já possuía o fluxo geral de execução de testes:

- receber o ID de uma User Story ou Bug em `$ARGUMENTS`;
- localizar o card filho `Criar Mapa de Teste` no Azure DevOps;
- executar os cenários no browser real;
- comparar resultado esperado e resultado obtido;
- capturar snapshots, screenshots e evidências de rede;
- trabalhar com Modo A, para execução normal, e Modo B, para reteste seletivo pós-bug;
- registrar resultados no relatório, log de ações e ciclo de execução.

Ela também possuía uma seção de pré-requisitos técnicos, mas essa seção era limitada a cenários negativos/borda e permitia prosseguir quando a informação técnica não estivesse disponível. A principal mudança foi transformar essa validação em um gate obrigatório da rodada.

## 5. Alterações realizadas

### 5.1. Adaptação para Arquitetura do Share

O frontmatter e o contexto inicial foram ajustados para indicar que a versão é destinada ao fluxo do time de Arquitetura do Share.

Foi incluída uma regra explícita para preservar as variáveis e os MCPs existentes, incluindo:

```text
$ARGUMENTS
$itemId
$project
$ambiente
$MAPA_ITEM
$MAPA_ID
$STORY_ID
$DESCRIPTION_HTML
$SCENARIOS
$MODO
$FIX_FILES
```

Também foram preservadas as referências aos MCPs existentes, incluindo:

- `mcp__azure-devops`;
- `mcp__azure-devops_wit_get_work_item`;
- `mcp__azure-devops__get_work_item_comments`;
- `mcp__azure-devops__get_pull_request_changes`;
- `mcp__azure-devops__update_work_item`;
- `mcp__playwright`;
- ferramentas `mcp__playwright__browser_*`.

Foi mantida a regra de não substituir MCP por REST, PAT ou outro acesso sem orientação explícita.

### 5.2. Gate obrigatório de pré-requisitos

A antiga seção `Step 2.5 — Consultar pré-requisitos técnicos de execução` foi substituída por:

> `Step 2.5 — Validar todos os pré-requisitos do ambiente (gate obrigatório)`

O gate ocorre depois de localizar e interpretar o mapa de testes, mas antes da triagem final e antes da execução de qualquer cenário.

Foi criada a variável `$PREREQUISITOS_EXECUCAO`, com uma matriz contendo:

- ID do requisito;
- cenários dependentes;
- fonte da informação;
- método de validação;
- evidência coletada;
- status;
- pendência ou ação necessária.

Os status possíveis são:

- `OK`;
- `NAO APLICAVEL`;
- `PENDENTE`;
- `INCONCLUSIVO`.

### 5.3. Itens obrigatórios de validação do ambiente

O gate passou a verificar, conforme a necessidade dos cenários:

- disponibilidade do MCP do Azure DevOps;
- disponibilidade do MCP do Playwright;
- disponibilidade do MCP de banco quando houver dependência de banco;
- ambiente correto, com HMG como padrão;
- URL não produtiva e host acessível;
- versão ou revisão da aplicação implantada;
- autenticação, credenciais, instância e perfil;
- permissões necessárias;
- banco, serviços, workers, filas, jobs e integrações;
- feature flags, mocks, stubs ou LocalStack para cenários negativos;
- registros, grupos, clientes, estados anteriores e massas de teste;
- arquivos necessários para importação/upload;
- snapshots, screenshots, rede e diretório de evidências;
- segurança da rodada e autorização para operações de banco.

### 5.4. Regra de pausa da execução

Foi adicionada uma regra de pausa integral:

- qualquer requisito `PENDENTE` ou `INCONCLUSIVO` pausa toda a rodada;
- não é permitida execução parcial;
- os cenários não devem ser classificados como `Passou`, `Falhou` ou `NAO EXECUTADO` apenas por estimativa;
- a skill deve informar o impacto da pendência por cenário;
- a matriz completa deve ser revalidada depois da correção;
- o resultado deve ser registrado como `PAUSADA` no relatório, log e ciclo de execução.

Essa regra diferencia bloqueio da rodada de um cenário individual não executado após o gate já ter sido aprovado.

### 5.5. Regras para validações em banco

As regras de banco foram atualizadas para o seguinte comportamento:

#### Leitura

Leituras podem ser realizadas sem solicitar autorização. A skill deve usar leituras para:

- descobrir schema via `information_schema`;
- localizar dados de teste;
- confirmar presença ou ausência de registros;
- comparar estados antes e depois;
- verificar históricos;
- localizar registros candidatos;
- validar os efeitos de ações realizadas pela aplicação.

#### `INSERT` e `UPDATE`

`INSERT` e `UPDATE` diretos são permitidos somente após autorização explícita do usuário que está executando a skill.

Durante o Step 2.5, a skill deve analisar o mapa, a análise técnica e os dados do ambiente para identificar antecipadamente se essas operações serão necessárias. Para cada operação, deve apresentar:

- ambiente;
- tabela ou objeto;
- operação;
- finalidade;
- escopo dos dados;
- comando ou plano de alteração;
- impacto esperado;
- forma de validação.

A autorização deve ser específica. Uma autorização para um registro, tabela ou ambiente não autoriza outras operações.

Foram adicionadas as variáveis:

```text
$OPERACOES_BANCO
$AUTORIZACOES_BANCO
```

Se uma necessidade de `INSERT` ou `UPDATE` surgir apenas durante a execução, a skill deve pausar antes da escrita, solicitar autorização específica e somente retomar após a autorização.

#### `DELETE`

`DELETE` direto no banco é sempre proibido, mesmo com autorização do usuário. Se um cenário depender dessa operação, a execução deve ser pausada e o bloqueio deve ser registrado.

### 5.6. Tratamento de cenários não executados

Foi adicionada a seção `Pendências e instruções para retomada` ao relatório final.

Quando restar qualquer cenário não executado, a skill deve identificar individualmente:

1. o cenário ou step;
2. o motivo da não execução;
3. as evidências da tentativa ou do bloqueio;
4. o que o usuário precisa corrigir ou providenciar;
5. a condição objetiva que libera o cenário;
6. como retomar a execução.

A instrução padrão de retomada é executar novamente a skill com os mesmos argumentos de `$ARGUMENTS`, permitindo que todos os pré-requisitos sejam revalidados e que os cenários pendentes sejam executados.

A skill não deve finalizar com uma orientação genérica como `corrigir e tentar novamente`. Quando não houver pendências, deve informar explicitamente:

```text
Nenhum cenário ficou pendente de execução.
```

### 5.7. Relatórios, logs e ciclos

O relatório final passou a conter:

- status `CONCLUÍDA` ou `PAUSADA`;
- matriz de pré-requisitos;
- seção de pendências e instruções para retomada;
- contagens sem estimativas quando a execução for pausada;
- motivo exato da pausa no log de ações;
- pendências registradas no ciclo de execução.

Também foi padronizada a referência da rodada funcional como:

```text
1 (funcional, HMG)
```

### 5.8. Correções de consistência

Foi corrigida a referência inconsistente a `HOM`, adotando `HMG` para a execução funcional da frente de Arquitetura do Share.

Também foi corrigida a numeração do Step 0 após a inclusão da regra adicional de preservação dos MCPs.

## 6. Regras preservadas da skill base

As seguintes regras não foram removidas:

- execução pelo mapa de testes publicado no card `Criar Mapa de Teste`;
- Modo A para execução normal;
- Modo B para reteste seletivo pós-bug;
- detecção de Bugs corrigidos sem reteste confirmado;
- comparação literal entre esperado e obtido;
- exigência de evidência para classificar como `Passou`;
- captura de screenshot para falhas;
- inspeção de rede em resultados divergentes ou inconclusivos;
- retomada do mesmo step após expiração de sessão;
- confirmação específica para ações irreversíveis ou de alto risco;
- double-check independente das classificações;
- registro no `LOG-ACOES.md`;
- registro do ciclo de execução;
- preservação do marcador `Reteste (Modo B)` no Bug.

## 7. Arquivos consultados

1. [`executar-teste.md`](../executar-teste.md) — arquivo da skill adaptada.
2. [`variaveis-de-ambiente-smartshare.md`](../Variveis%20de%20Ambiente/variaveis-de-ambiente-smartshare.md) — referência de variáveis, endpoints e credenciais do ambiente; nenhum segredo foi reproduzido neste registro.
3. [`COMO-REGISTRAR.md`](../ciclos-execucao/COMO-REGISTRAR.md) — regras para registro no ciclo de execução.
4. [`analise-tecnica.md`](../analise-tecnica.md) — fonte das regras de pré-requisitos técnicos.
5. `C:\Users\guilherme.borges\.codex\skills\.system\skill-creator\SKILL.md` — orientação metodológica para atualização de skills.

## 8. Validação realizada

Foram verificadas:

- presença do frontmatter Markdown;
- referência explícita à Arquitetura do Share;
- preservação das referências MCP do Azure DevOps e Playwright;
- existência do gate obrigatório de pré-requisitos;
- existência das regras de pausa `PENDENTE`/`INCONCLUSIVO`;
- regras de leitura sem autorização, `INSERT`/`UPDATE` com autorização e `DELETE` proibido;
- seção de pendências e instruções de retomada;
- consistência da numeração do Step 0;
- ausência de erros no `git diff --check`.

Nenhuma operação de banco foi executada durante esta atividade.

## 9. Resultado final

A skill agora está orientada para a execução do time de Arquitetura do Share, mantendo o fluxo MCP existente e adicionando um controle explícito de prontidão do ambiente. A execução somente começa quando os pré-requisitos necessários estão comprovados e as autorizações de banco necessárias foram obtidas.
