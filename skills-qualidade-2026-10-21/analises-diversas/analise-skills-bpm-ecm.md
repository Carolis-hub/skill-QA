# Análise de Skills para Novo Produto BPM/ECM

> Confirmação: os 9 arquivos do diretório `C:\project personal\Skills-QA-Processo_2026-09-28` foram lidos integralmente antes de iniciar esta análise. Nenhuma informação externa a esses arquivos foi utilizada. Onde o conteúdo era ausente/ambíguo, isso está registrado explicitamente como "Informação não encontrada".

## 1. Resumo Executivo

- **Quantidade de skills analisadas:** 9
- **Quantidade de arquivos lidos:** 9 (100% do diretório)
- **Principais padrões encontrados:**
  - Todas as 9 skills são acopladas ao **Azure DevOps** via MCP (`mcp__azure-devops__*`), com tipos de work item customizados (`Análise`, `Analise Review`, `Criar Mapa de Teste`) e campos customizados (`Custom.Pontosdeimpacto`, `Custom.CasodeTeste`).
  - Projeto default hardcoded como `"Squad Centaurus"` em `analise-negocio.md:10,42`, `analise-tecnica.md:10,62`, `atualizar-documentacao.md:25`.
  - Regra recorrente de "nunca supor, escrever 'Informação não encontrada / necessita validação.'" aparece em `analise-negocio.md:19-23`, `analise-tecnica.md:19-23`, `analise-falha.md:17-19`.
  - Encadeamento manual entre skills (nunca automático) é uma regra consistente em todas: `analise-negocio.md:131`, `analise-tecnica.md:156`, `gerar-mapa-testes-v3` (implícito via reaproveitamento de relatórios, Step 3), `executar-teste.md:303`, `homologar-release.md:150`.
  - Forte acoplamento ao domínio **Cobrança** (boletos, CNAB, Pix, grupo de pagadores) em `executar-teste.md` (linhas 35-37, 168-186, 193) e em `priorizar-automacao.md` (linhas 13-14, 54, 94).
  - Log de governança centralizado em `~/.claude/docs/projetos/skills-qa/LOG-ACOES.md`, presente em `atualizar-documentacao.md:84-90`, `executar-teste.md:307-323`, `gerar-defeito.md:157-169`, `gerar-mapa-testes-v3.md:320-333`, `homologar-release.md:89-99`.
- **Principais riscos encontrados:**
  - Nenhuma menção a múltiplos bancos de dados (Oracle/SQL Server) em nenhum dos 9 arquivos — a única referência a banco é MySQL, single-database, específico do domínio Cobrança (`executar-teste.md:36,159`).
  - Nenhuma skill trata explicitamente dependências de configuração em cadeia (tipo do exemplo do enunciado: tipo de documento → tipo de índice → usuário → perfil).
  - Nenhuma skill trata múltiplos repositórios/múltiplos subprodutos como conceito — `analise-tecnica.md` opera sobre um único PR/diff.
  - Caminhos de arquivo/máquina hardcoded de uma pessoa específica (`C:\Users\cintia.gregorio\Desktop\automacao.teste`, `C:\Users\cintia.gregorio\Desktop\planilha_features\...`) em `priorizar-automacao.md:13,94`.
  - Vocabulário e exemplos de negócio (boleto, CNAB, Pix, grupo de pagadores, Cresol) fortemente atrelados ao produto de referência (Cobrança), não a BPM/ECM.
- **Principais lacunas identificadas:**
  - Ausência total de cobertura Oracle x SQL Server.
  - Ausência de mecanismo de rastreamento de dependências de configuração (pré-requisitos de cadastro para uma funcionalidade).
  - Ausência de tratamento para arquitetura multi-repositório (backend/frontend separados) e integrações cruzadas entre subprodutos.
  - Ausência de qualquer menção a BPM (workflow, fluxo de processo, tarefas) ou ECM (publicação de documento, índice, metadado) como conceito.
  - Ausência de qualquer menção a instalação/ambiente on-premise (versus SaaS/cloud implícito no uso de MCPs de nuvem).

## 2. Inventário das Skills

| Nome da Skill | Arquivo de origem | Objetivo | Status de aderência |
|---|---|---|---|
| QA Business Analyst | analise-negocio.md | Extrair objetivo, regras, ambiguidades e riscos de uma User Story do Azure DevOps | Reutilizável com adaptações significativas |
| QA Technical Analyst | analise-tecnica.md | Ler card de Análise do dev + PR vinculado e mapear componentes/dependências/risco por camada | Recomendada reconstrução |
| Gerador de Mapa de Testes v3 | gerar-mapa-testes-v3.md | Gerar e publicar mapa de cenários de teste no card "Criar Mapa de Teste" | Reutilizável com adaptações significativas |
| QA Test Executor | executar-teste.md | Executar cenários via Playwright, comparando esperado vs. obtido | Recomendada reconstrução |
| QA Failure Analyst | analise-falha.md | Investigar causa provável de uma falha de teste e decidir se justifica abrir defeito | Reutilizável com pequenas adaptações |
| Geração de Defeito | gerar-defeito.md | Estruturar e criar um Bug no Azure DevOps a partir de análise de falha | Reutilizável com pequenas adaptações |
| QA Release Validator | homologar-release.md | Validar se uma release está pronta para produção, recomendando aprovação | Reutilizável com adaptações significativas |
| QA Documentation Agent | atualizar-documentacao.md | Propor e publicar atualizações na wiki do Azure DevOps | Reutilizável com pequenas adaptações |
| QA Automation Engineer | priorizar-automacao.md | Classificar cenários e promover testes de alta prioridade para regressão automatizada | Reutilizável com adaptações significativas |

## 3. Análise Individual das Skills

### QA Business Analyst (analise-negocio.md)

#### Objetivo
Interpretar uma User Story do Azure DevOps (regra de negócio, critérios de aceite) e extrair objetivo, regras explícitas/implícitas, ambiguidades, dependências e riscos, "sem inventar informação" (linha 2). É somente leitura (linha 13).

#### Estrutura
Bem organizada em steps sequenciais (0 a 4), com regra fundamental explícita (linhas 17-23), formato de saída fixo (linhas 97-129) e seção de troubleshooting (linhas 135-140). Padronização alta — mesmo padrão de "Regra fundamental" + steps numerados se repete nas outras 8 skills.

#### Dependências
Explícitas: `mcp__azure-devops_wit_get_work_item` e `mcp__azure-devops_wit_get_work_item_comments` (linhas 29, 67). Implícita: projeto default `"Squad Centaurus"` (linha 42) — não hardcoded genérico. Dependências de negócio da própria história são item 6 do Step 3 (linha 84), mas dependências de configuração de sistema (cadastros pré-requisito) não aparecem em nenhum ponto do arquivo.

#### Cobertura para BPM/ECM
Não há nenhuma menção a BPM, ECM, Oracle, SQL Server, múltiplos repositórios ou front/back separados no arquivo inteiro. O mecanismo central (ler campos estruturados de uma User Story do Azure DevOps: título, descrição, critérios de aceite, comentários) é agnóstico de domínio e portanto tecnicamente aplicável a histórias de um produto BPM/ECM, **desde que a fonte continue sendo Azure DevOps com esses mesmos campos**.

#### Pontos Fortes
- Regra de "não inventar" e rastreabilidade por citação de origem (linhas 19-23, 77) é diretamente reaproveitável e valiosa em qualquer domínio.
- Já reconhece explicitamente a fronteira entre pergunta de negócio (aqui) e pergunta técnica de ambiente/infraestrutura (linhas 85, 139) — separação de responsabilidade que ajudaria a modelar dependências de configuração do BPM/ECM, se estendida.
- Estrutura de "Comportamentos esperados" como "Quando X, o sistema deve Y" (linha 106) é um formato de contrato verificável reutilizável.

#### Lacunas
- Nenhum item do Step 3 (9 itens, linhas 79-88) pede explicitamente para mapear pré-requisitos de configuração/cadastro (ex.: "que cadastros precisam existir antes desta regra valer"). O item 6 "Dependências" (linha 84) fala de "outras histórias, sistemas, integrações ou dados" de forma genérica, sem estrutura para dependências em cadeia como o exemplo do enunciado (tipo de documento → tipo de índice → usuário → perfil).
- Não há qualquer seção sobre banco de dados (Oracle/SQL Server) — não seria esperado nesta skill (é de negócio, não técnica), mas confirma que a responsabilidade de detectar isso não está coberta em nenhuma das 9 skills.

#### Riscos
- **Acoplamento ao produto original:** projeto default `"Squad Centaurus"` (linha 42) é específico do produto de referência; se o novo produto BPM/ECM usar múltiplos projetos Azure DevOps (um por repositório/subproduto, plausível dado "aproximadamente 7 repositórios" do contexto informado), o default fixo perde sentido e a skill precisaria de lógica para escolher o projeto certo por subproduto.
- **Premissa rígida:** assume que toda análise de negócio nasce de uma única User Story com campos padrão do Azure DevOps (linhas 51-58) — não há previsão para regra de negócio que atravesse múltiplas histórias em repositórios/produtos diferentes (situação mais provável no BPM/ECM multi-repo do que no produto original).

#### Recomendações
- Adicionar um item explícito no Step 3 para "Dependências de configuração/cadastro" (distinto de "Dependências" de sistemas/integrações), com estrutura para representar cadeias (A depende de B depende de C).
- Substituir o default fixo de projeto por um mecanismo que aceite ou pergunte o repositório/subproduto de origem quando a arquitetura for multi-repo.
- Adicionar uma pergunta explícita ao final: "esta regra depende de configuração prévia declarada na história? Se sim, qual?" — mantendo a mesma disciplina de "Informação não encontrada" quando não estiver escrito.

#### Classificação de Aderência
**Reutilizável com adaptações significativas** — o mecanismo central (extração rastreável de regras de negócio a partir de campos estruturados do Azure DevOps) é sólido e agnóstico de domínio, mas falta estrutura para dependências de configuração em cadeia e para múltiplos repositórios/projetos, que são características centrais do novo produto conforme o contexto informado.

#### Evidências
- Arquivo: analise-negocio.md, linha 42 — `$project = if ($parts.Count -gt 1) { ... } else { "Squad Centaurus" }` — projeto default hardcoded.
- Arquivo: analise-negocio.md, linhas 79-88 — lista dos 9 itens de extração, nenhum menciona pré-requisito de configuração/cadastro explicitamente.
- Arquivo: analise-negocio.md, linhas 19-23 — regra de rastreabilidade, ponto forte genérico.

---

### QA Technical Analyst (analise-tecnica.md)

#### Objetivo
Ler o card "Análise" (preenchido pelo dev) vinculado a uma história do Azure DevOps, cruzar com o PR vinculado e mapear classes/componentes impactados, dependências e risco por camada (linha 2). Roda entre `/analise-negocio` e `/gerar-mapa-testes-v2` (linha 13).

#### Estrutura
Estrutura idêntica ao padrão das outras skills (Regra fundamental, pré-requisito bloqueante, Steps 0-4, Troubleshooting). É a skill mais detalhada em tratar discrepância e escopo (linhas 25-32, 88, 138-144).

#### Dependências
Explícitas: exige um card filho do tipo exato `"Análise"` (distinto de `"Analise Review"`, linhas 37-39); opcionalmente um Pull Request vinculado (`get_pull_request`, `get_pull_request_changes`, linha 85). Sem o card `Análise` preenchido, a skill **bloqueia completamente** (linhas 41-47) — não há fallback de leitura direta de código.

#### Cobertura para BPM/ECM
- **Múltiplos repositórios:** não coberto. A skill lê **um** PR vinculado à história (linha 83: singular "um `ArtifactLink` para Pull Request"). Não há previsão para uma mudança que atravesse múltiplos repositórios (ex.: uma alteração de backend em um repo e o front correspondente em outro), cenário citado como central na arquitetura do novo produto ("~7 repositórios", "Backend e Frontend separados", "integrações entre componentes").
- **Front-end e Back-end:** o campo "Onde foi alterado (por camada)" (linha 97, tabela linha 119-121) já prevê "front-end, API, serviço/domínio, banco de dados, integrações, relatórios" — a estrutura conceitual de camada existe, mas a fonte de dados (um PR só) não escala para repositórios separados.
- **Oracle/SQL Server:** nenhuma menção a banco de dados específico; "banco de dados" aparece apenas como uma das camadas possíveis (linha 97), sem qualquer orientação de como validar em dois SGBDs diferentes.
- **Dependências de configuração:** o Step 3 já distingue "dependências diretas" e "dependências indiretas" (linhas 98-99), mas seu escopo é **explicitamente restrito às mudanças dentro do escopo declarado da US** (linhas 25-32) — dependências de configuração pré-existentes fora do PR (ex.: cadastro de tipo de documento que já existe no sistema, necessário para o novo fluxo funcionar) não têm mecanismo de detecção, pois a fonte de verdade é só "o que o dev escreveu" ou "o que está no diff" (linha 19-23).

#### Pontos Fortes
- Já resolve, de forma madura, o problema de "discrepância entre o que o dev disse e o que o PR realmente mudou" (Step 2, linhas 81-89) e separa claramente risco dentro/fora do escopo da US (linhas 138-144) — esse raciocínio de escopo é diretamente reaproveitável para a complexidade multi-repo, desde que estendido para múltiplos PRs de múltiplos repositórios.
- O item "Pré-requisitos técnicos de execução de teste" (linha 102) já pede identificar configuração/infraestrutura necessária (bucket, variável de ambiente, mecanismo de simulação de falha) — é o embrião mais próximo, entre as 9 skills, de tratar dependência de configuração, mas focado em infraestrutura técnica de teste, não em cadastros funcionais de negócio (tipo de documento, perfil de usuário).

#### Lacunas
- Não há suporte a mais de um PR/repositório por história — arquitetura fundamentalmente single-repo.
- Nenhuma seção pede verificar se a funcionalidade alterada depende de cadastros/configurações prévias já existentes no sistema (fora do escopo do PR atual) — o exemplo do enunciado (tipo de documento → tipo de índice → usuário → perfil) não seria capturado por esta skill, pois ela só analisa "o que mudou", não "o que precisa já existir para a mudança funcionar".
- Sem menção a Oracle/SQL Server ou a necessidade de validar uma mudança de schema/query em dois SGBDs.

#### Riscos
- **Cobertura insuficiente:** ao operar com "a fonte da verdade técnica é o card Análise... não o LLM" (linha 19) e um PR só, a skill bloquearia ou produziria análise incompleta para qualquer história cuja mudança real atravesse repositórios (cenário citado como normal no novo produto).
- **Acoplamento ao produto original:** os nomes de tipo de work item (`Análise`, `Analise Review`, `Criar Mapa de Teste`) e campos (`Custom.Pontosdeimpacto`, `Custom.CasodeTeste`) são específicos do processo Azure DevOps configurado para o produto de referência — precisam existir de forma idêntica no novo processo, ou a skill inteira quebra (bloqueio, linhas 41-47).
- **Premissa rígida:** "nunca ler o código diretamente por conta própria como substituto" (linha 47) da ausência do card Análise é uma decisão de processo do time atual (dev preenche, QA não caça sozinho) — pode ou não fazer sentido no novo contexto; se o time do novo produto não adotar esse mesmo ritual de card `Análise`, a skill fica inutilizável sem essa adaptação de processo, não só de skill.

#### Recomendações
- Estender Step 2 para aceitar N PRs/repositórios vinculados a uma mesma história (união dos diffs, como já é feito em `executar-teste.md` Modo B para múltiplos commits/PRs de um fix, linha 106) — esse padrão de "união de diffs" já existe em outra skill e pode ser copiado.
- Adicionar uma seção "Pré-requisitos de configuração/cadastro" simétrica à seção "Pré-requisitos técnicos de execução de teste" (linha 102), mas para dependências funcionais (cadastros que precisam existir).
- Adicionar campo de banco de dados alvo (Oracle/SQL Server/ambos) na tabela de camadas quando a camada tocada for "banco de dados".

#### Classificação de Aderência
**Recomendada reconstrução** — a decisão arquitetural central (um único card `Análise` + um único PR como fonte de verdade) conflita diretamente com a arquitetura declarada do novo produto (múltiplos repositórios, dependências cruzadas). Adaptar exigiria reestruturar o modelo de dados de entrada, não apenas ajustar texto.

#### Evidências
- Arquivo: analise-tecnica.md, linha 83 — "Procure em `$STORY_RELATIONS`... um `ArtifactLink` para Pull Request" (singular, sem previsão de múltiplos repositórios).
- Arquivo: analise-tecnica.md, linhas 25-32 — escopo de análise de risco restrito ao PR/escopo declarado da US.
- Arquivo: analise-tecnica.md, linha 102 — único ponto que se aproxima de "pré-requisito", mas focado em infraestrutura de teste, não em cadastro de negócio.

---

### Gerador de Mapa de Testes v3 (gerar-mapa-testes-v3.md)

#### Objetivo
Gerar um mapa de casos de teste a partir de uma história do Azure DevOps e publicá-lo na Descrição do card "Criar Mapa de Teste" filho da história, via MCP (linha 2).

#### Estrutura
A mais longa e detalhada das 9 skills (346 linhas), com histórico de decisões datadas (linhas 25-28, 136), checklist obrigatório de dimensões (Step 4.1, linhas 140-153) e regras de escopo de origem restritas a 4 fontes (Step 4.0, linhas 127-138). Estrutura muito bem padronizada e rastreável.

#### Dependências
Explícitas: `mcp__azure-devops__get_work_item`, `search_work_items`, `update_work_item`, `create_work_item` (linha 65). Reaproveita opcionalmente `/analise-negocio` e `/analise-tecnica` (Step 3, linhas 103-111). Depende de um tipo de work item exato chamado `"Criar Mapa de Teste"` (linha 94) — específico do processo configurado no Azure DevOps do produto de referência.

#### Cobertura para BPM/ECM
- O checklist de dimensões (positivo/negativo/permissão/dados/concorrência/regressão, linhas 146-153) é uma técnica de design de teste agnóstica de domínio — aplicável tanto a Cobrança quanto a BPM/ECM.
- **Multi-banco:** não coberto — nenhuma dimensão ou categoria do checklist (Step 4.3, linhas 164-174) contempla "validar em Oracle" vs. "validar em SQL Server". A tabela de cenários (Step 5) também não tem coluna para banco de dados alvo.
- **Dependências de configuração:** o escopo de origem restrito a 4 fontes (Instruções QA, Critérios de Aceite, Pontos de Impacto do dev, Casos de Teste do dev — linhas 129-134) é uma decisão deliberada (linha 136, "decisão de Cintia, 2026-09-22") para **não** deixar a skill inferir cenários a partir de risco percebido fora dessas fontes. Isso significa que, se a história não mencionar explicitamente o pré-requisito de configuração (ex.: "para publicar, é preciso ter tipo de índice cadastrado"), a skill **não vai gerar** um cenário de teste para essa dependência, mesmo que ela exista de fato no sistema — é uma limitação deliberada, não um bug, mas se torna um risco maior no BPM/ECM, onde essas dependências são descritas como uma característica central do produto.
- **BPM/ECM como conceito:** ausente; a categoria fixa `=== ERROS DE INTEGRACAO / API ===` (linha 172) é o item mais próximo de fluxo integrado, mas modelado para chamada de API, não para transições de estado de um processo BPM.

#### Pontos Fortes
- O checklist obrigatório de dimensões (linha 20, "em vez de deixar a cobertura a critério livre do modelo") é uma boa prática estrutural, diretamente reutilizável.
- A decisão de restringir origem a 4 fontes rastreáveis (linhas 127-138) evita "inflar" o mapa com hipóteses não fundamentadas — atende bem ao requisito do enunciado de "não fazer suposições".
- Categoria `REGRESSAO` alimentada por histórico real de defeitos (`search_work_items`, Step 3.5) é um mecanismo concreto e reaproveitável de rastreamento de impacto indireto, ainda que limitado à mesma área/palavra-chave.

#### Lacunas
- Nenhuma coluna/dimensão para banco de dados alvo.
- Nenhuma dimensão para "pré-requisito de configuração ausente" — o checklist trata "Dados" (linha 151: "dado inexistente, nulo ou vazio relevante à regra") de forma pontual (um dado faltando), não como cadeia de dependências de cadastro (múltiplos níveis, como no exemplo do enunciado).
- Sem suporte a cenário que atravesse mais de um repositório/subproduto (a fonte "Pontos de Impacto do dev" é a mesma limitação single-PR do `/analise-tecnica`).

#### Riscos
- **Dependências não consideradas:** por desenho (não por omissão acidental), a skill não vai gerar cenários para dependências de configuração implícitas não citadas na história — no BPM/ECM, onde o enunciado descreve isso como padrão recorrente, isso geraria mapas de teste sistematicamente incompletos para esse tipo de risco, a menos que as próprias Instruções QA/Critérios de Aceite passem a documentar essas dependências explicitamente (mudança de processo, não só de skill).
- **Acoplamento ao produto original:** tipo de work item `"Criar Mapa de Teste"` e a estrutura de card único por história pressupõem o mesmo processo Azure DevOps do produto de referência.

#### Pontos Fortes (continuação) / Oportunidades de melhoria
- Adicionar uma dimensão nova ao checklist do Step 4.1: **"Pré-requisito de configuração"** — para cada regra condicional, perguntar explicitamente "que cadastros/configurações precisam existir antes desta ação ser possível?" e gerar cenário de borda para cada um ausente — desde que essa informação já esteja em uma das 4 fontes aceitas (ou seja necessário ampliar as fontes aceitas para incluir explicitamente documentação de pré-requisitos funcionais, se existir no novo processo).
- Adicionar coluna "SGBD" (Oracle/SQL Server/Ambos/N-A) na tabela de cenários quando o cenário envolver validação direta de dado persistido.
- Adicionar uma categoria fixa `=== FLUXO BPM ===` ou `=== TRANSICOES DE ESTADO ===` para cenários de workflow (ex.: uma tarefa não pode avançar sem aprovação anterior).

#### Classificação de Aderência
**Reutilizável com adaptações significativas** — a espinha dorsal (checklist de dimensões + rastreabilidade estrita de origem + categorias fixas) é sólida e vale a pena preservar, mas precisa de dimensões novas (configuração, banco de dados, fluxo de processo) para cobrir o novo domínio.

#### Evidências
- Arquivo: gerar-mapa-testes-v3.md, linhas 127-138 — Step 4.0, escopo de origem restrito a 4 fontes, decisão datada de 2026-09-22.
- Arquivo: gerar-mapa-testes-v3.md, linhas 146-153 — tabela do checklist de dimensões, sem dimensão de configuração/banco de dados.
- Arquivo: gerar-mapa-testes-v3.md, linha 172 — categoria mais próxima de fluxo integrado (`ERROS DE INTEGRACAO / API`), modelada para API, não para workflow BPM.

---

### QA Test Executor (executar-teste.md)

#### Objetivo
Executar de fato, via browser (Playwright), os cenários do mapa de testes publicado no card "Criar Mapa de Teste", comparando obtido vs. esperado, e também oferecer reteste seletivo pós-bug (linha 2).

#### Estrutura
A skill mais longa (354 linhas) e mais rica em guardrails (Regra fundamental, linhas 20-37). Bem estruturada, mas com forte densidade de regras específicas de um domínio.

#### Dependências
Explícitas: `mcp__azure-devops`, `mcp__playwright` (linha 43-45). Explicitamente dependente de arquivos de KB de produto: `~/.claude/docs/projetos/cobranca/00-INDICE.md` e `~/.claude/docs/projetos/portaria/00-INDICE.md` (linha 48) — **apenas dois produtos são citados**, Cobrança e Portaria, nenhum deles BPM/ECM. Também depende de `~/.claude/secrets/cobranca-ambientes.md` (linha 193) e de um MCP de banco `mysql-cobranca-hmg` (linha 36, 159) — nomeado explicitamente com o sufixo "-cobranca", ou seja, um MCP dedicado ao domínio de Cobrança, MySQL.

#### Cobertura para BPM/ECM
- **Oracle/SQL Server:** não há qualquer suporte — o único acesso a banco mencionado em toda a base de 9 skills é `mysql-cobranca-hmg`, leitura MySQL específica de Cobrança (linhas 36, 159). Não há MCP, convenção de nome, ou instrução equivalente para Oracle ou SQL Server em nenhum lugar dos 9 arquivos.
- **Multi-produto:** o Step 0 (linha 48) já tem o conceito de "KB de produto" indexado (`00-INDICE.md` por produto) e escala nominalmente para novos produtos — mas hoje só lista dois (Cobrança, Portaria), nenhum genérico para "o novo produto".
- **Preparação de dados específicos do domínio:** toda a seção "Preparação de dados CNAB" (linhas 168-186) e a lógica de instância (Cooperado legado, Cooperativa, Central, Confederação — linha 193) são 100% específicas do domínio Cobrança bancária; não têm equivalente conceitual (tipo de documento, tipo de índice) para BPM/ECM.
- **Ambientes on-premise:** não é tratado como tema — a skill assume acesso remoto via MCP Playwright e MCP Azure DevOps residentes na mesma sessão, sem qualquer menção a particularidades de ambiente on-premise (rede interna, VPN, múltiplas instâncias por cliente).

#### Pontos Fortes
- Guardrails de segurança e rigor de evidência (nunca aprovar sem evidência, nunca rodar contra produção — linhas 29, 34) são princípios de processo genéricos e valiosos, independente do domínio.
- O padrão de "ler antes de concluir impossível" (linha 37, tentar alternativa antes de desistir) e o histórico de falhas reais registrado (linhas 31, 352 — US #157198, #161881) mostram maturidade de processo por iteração real, reaproveitável como filosofia.
- O Modo B (reteste seletivo pós-bug, linhas 92-117) é um mecanismo genérico de proporcionalidade de regressão que não depende do domínio Cobrança — só depende de mapa de testes + PR do fix, ambos conceitos genéricos.
- Double-check independente via subagente (Step 4.5, linhas 236-249) é uma prática de qualidade reutilizável em qualquer domínio.

#### Lacunas
- Nenhuma seção equivalente à de KB de Cobrança/Portaria existe (ainda) para o novo produto — precisaria ser criada do zero.
- Nenhum mecanismo de acesso a Oracle/SQL Server (leitura) — o padrão existente (`mysql-cobranca-hmg`) precisaria ser replicado/generalizado para os dois SGBDs exigidos.
- Nenhuma seção equivalente a "Preparação de dados CNAB" para os artefatos típicos de BPM/ECM (ex.: gerar um documento de teste com metadados de índice específicos, ou disparar uma instância de processo BPM).
- A lógica de login/instância (linha 193) é hardcoded para as 5 instâncias de Cobrança — precisaria de reformulação total para o(s) subproduto(s) do BPM/ECM.

#### Riscos
- **Ausência de validações importantes:** ao herdar esta skill "como está" para o novo produto, toda tentativa de rodar cenário de borda contra Oracle/SQL Server ficaria sem instrução — cairia na categoria "dado ausente"/"ambiente" por omissão, não por decisão deliberada, o que long-term mascara lacuna real de cobertura.
- **Acoplamento ao produto original:** é a skill mais fortemente acoplada de todas ao domínio de Cobrança (arquivo de credenciais, CNAB, instâncias nomeadas) — o esqueleto de execução via Playwright é reaproveitável, mas todo o conteúdo específico de domínio precisaria ser descartado e reescrito.
- **Cobertura insuficiente:** a auto-detecção de Bug pendente de reteste (Step 1, Modo A) e a comparação de estado do Bug via `System.State` presumem os mesmos estados (`Done`, `Resolved`) do processo Azure DevOps atual — se o processo do novo produto usar nomes de estado diferentes, a lógica de "estado equivalente a corrigido" (linha 71) precisaria de reconfiguração, mas isso já está sinalizado como parametrizável ("o que o projeto usar").

#### Recomendações
- Criar um MCP (ou script) de leitura equivalente ao `mysql-cobranca-hmg`, mas para Oracle e outro para SQL Server, com a mesma filosofia "leitura permitida, escrita nunca" (linha 36).
- Criar KBs de produto (`00-INDICE.md`) para o(s) subproduto(s) BPM e ECM, seguindo o mesmo padrão indexado por palavra-chave (linha 48).
- Criar uma seção de "Preparação de dados de configuração pré-requisito" (equivalente à seção CNAB, linhas 168-186) para os artefatos típicos do BPM/ECM (ex.: massa de teste para tipo de documento + tipo de índice + perfil, já configurados, antes de testar publicação).
- Extrair a lógica de resolução de instância/credencial (linha 193) para um arquivo de configuração por subproduto, com a mesma disciplina de "nunca hardcode" já presente.

#### Classificação de Aderência
**Recomendada reconstrução** — o núcleo de execução via Playwright (login, ação, snapshot, evidência de rede, double-check) é reaproveitável como esqueleto, mas o conteúdo de domínio (que é a maior parte do arquivo: credenciais, CNAB, KB de Cobrança/Portaria, MCP MySQL) precisa ser essencialmente recriado para BPM/ECM e para dois SGBDs.

#### Evidências
- Arquivo: executar-teste.md, linha 36 — "acesso de leitura via MCP `mysql-cobranca-hmg` (read-only) para os ambientes de Cobrança" — único acesso a banco em toda a base, MySQL, um produto só.
- Arquivo: executar-teste.md, linha 48 — KBs indexadas só para "Cobrança" e "Portaria".
- Arquivo: executar-teste.md, linhas 168-186 — seção inteira de preparação de dados CNAB, 100% específica de Cobrança bancária.
- Arquivo: executar-teste.md, linha 193 — 5 instâncias nomeadas de Cobrança hardcoded na lógica de login.

---

### QA Failure Analyst (analise-falha.md)

#### Objetivo
Investigar uma falha de teste e determinar causa provável, componente relacionado e se há evidência suficiente para abrir um defeito — não cria nada, só decide (linha 2).

#### Estrutura
A mais enxuta das 9 (94 linhas), estrutura clara em checklist de 7 perguntas (Step 2, linhas 41-51) com relatório fixo (Step 3).

#### Dependências
Explícitas: `mcp__azure-devops_wit_get_work_item`, `mcp__azure-devops__search_work_items` (linhas 33, 49). Reaproveita relatórios de `/analise-negocio` e `/analise-tecnica` quando disponíveis (linhas 35-37).

#### Cobertura para BPM/ECM
O raciocínio central (esperado vs. obtido, funcional vs. técnico, já existia antes, relação com a mudança atual, evidência suficiente) é inteiramente agnóstico de domínio e de banco de dados — não há nada no arquivo que dependa de Cobrança, Oracle, SQL Server, ou de arquitetura multi-repo especificamente. É a skill mais "pura" do conjunto nesse sentido.

#### Pontos Fortes
- Veredito binário explícito (SIM/NÃO) com regra de "evidência insuficiente é resultado válido" (linha 19) é uma boa prática de rigor, plenamente reutilizável.
- Já trata explicitamente cenários `HIPOTESE:` do mapa de testes como motivo de veredito `NÃO` (linha 91) — mantém coerência com `gerar-mapa-testes-v3`.

#### Lacunas
- O item 6 "Existe relação com a alteração atual?" (linha 50) depende de "se houver PR vinculado (via `/analise-tecnica`)" — herda a limitação de PR único de `/analise-tecnica`; se o novo produto tiver múltiplos PRs/repositórios por história, esta pergunta precisaria considerar todos eles, não um só.
- Não há orientação para diferenciar uma falha causada por dado/configuração pré-requisito ausente (ex.: "o tipo de índice não estava configurado, por isso a publicação falhou") de uma falha de implementação real — o Step 2 classifica só em "funcional" ou "técnico" (linha 48), sem uma terceira categoria "falha de preparação de ambiente/configuração", que seria relevante no BPM/ECM dado o padrão de dependências em cadeia citado no enunciado.

#### Riscos
- **Cobertura insuficiente:** o risco é herdado, não próprio — ao depender de `/analise-tecnica` para o item de PR, qualquer limitação daquela skill (single-repo) se propaga para esta.
- Risco baixo de acoplamento ao produto original: não há nenhuma referência a Cobrança/CNAB/Pix neste arquivo especificamente.

#### Recomendações
- Adicionar uma classificação adicional no item 4 (linha 48): "Funcional / Técnico / **Configuração/pré-requisito ausente**" — para distinguir explicitamente falha por dependência de cadastro não atendida, comum no padrão descrito para o novo produto.
- Quando `/analise-tecnica` evoluir para suportar múltiplos PRs/repositórios (ver recomendação da skill acima), o item 6 aqui automaticamente ganha essa cobertura, sem mudança própria necessária além de citar "PRs" no plural.

#### Classificação de Aderência
**Reutilizável com pequenas adaptações** — o raciocínio central é agnóstico de domínio e de banco de dados; as únicas adaptações necessárias são herdadas de outras skills (PR único) ou uma nova categoria de classificação de causa.

#### Evidências
- Arquivo: analise-falha.md, linha 48 — classificação binária "funcional ou técnico", sem categoria de configuração/pré-requisito ausente.
- Arquivo: analise-falha.md, linha 50 — dependência do PR único vinda de `/analise-tecnica`.
- Arquivo: analise-falha.md, linha 19 — regra de rigor "evidência insuficiente é resultado válido", ponto forte agnóstico.

---

### Geração de Defeito (gerar-defeito.md)

#### Objetivo
Montar o registro estruturado de um defeito (Bug) a partir de uma análise de falha concluída e criar no Azure DevOps via MCP, sempre com confirmação humana (linha 2).

#### Estrutura
Bem estruturada (179 linhas), com pré-requisito bloqueante claro (linhas 15-18) e um detalhe técnico relevante e bem documentado: por que usar `ReproSteps` em vez de `Description` (linhas 88-90), com incidente real citado (US #161109, Bug #161659).

#### Dependências
Explícitas: `mcp__azure-devops__create_work_item`, `wit_work_item_link_write`, REST direto via PAT para anexos (linhas 108-142, já que "Não existe tool MCP de upload de anexo", linha 110). Depende de `/analise-falha` ter rodado com veredito `SIM` (linhas 15-18).

#### Cobertura para BPM/ECM
O mecanismo (montar rascunho estruturado → aprovação → criar Bug → vincular como filho → anexar evidência → log) é inteiramente agnóstico de domínio, banco de dados e arquitetura de repositórios. O único acoplamento é ao **processo Azure DevOps específico** (nomes de campo `Microsoft.VSTS.TCM.ReproSteps`, tipo de vínculo `parent`/`Hierarchy-Reverse`, formato fixo do rótulo "Cenário de origem" para leitura posterior por `/executar-teste`, linha 88 de `gerar-defeito.md`).

#### Pontos Fortes
- A explicação do "porquê" de usar `ReproSteps` em vez de `Description`, com incidente real documentado, é exatamente o tipo de conhecimento tácito de processo que vale a pena preservar — desde que se confirme que o template de Bug do novo produto/projeto também expõe esse campo dessa forma (ver Riscos).
- Contrato de formato fixo do rótulo "Cenário de origem" (linha 88) é uma integração deliberada e bem documentada entre duas skills (esta e `/executar-teste`), reutilizável como padrão de design.
- Nunca decide severidade sozinho, sempre como sugestão editável (linha 176) — boa prática de governança, agnóstica de domínio.

#### Lacunas
- O mecanismo de anexo de evidência via REST+PAT (linhas 108-142) é específico da API do Azure DevOps — se o novo produto usar outra ferramenta de gestão de trabalho (não informado nos arquivos, mas a arquitetura multi-repo levanta a dúvida de se o processo de ADO é o mesmo em todos os repositórios), precisaria revalidação.
- Não há qualquer campo para indicar em qual repositório/subproduto o defeito ocorreu — apenas "projectId" (linha 81), que no produto de referência mapeia 1:1 com "Squad Centaurus"; num produto de ~7 repositórios, pode ser necessário decidir explicitamente em qual projeto/área o Bug deve ser criado.

#### Riscos
- **Premissa rígida:** assume que o template de Bug do projeto Azure DevOps do novo produto também usa `ReproSteps` como campo visível principal (linha 89-90) — isso é uma configuração específica do processo do projeto "Squad Centaurus" mencionada como descoberta empírica (linha 90), não uma garantia do Azure DevOps em geral. **Informação não encontrada** nos arquivos sobre qual processo/template o novo produto usará.
- **Acoplamento ao produto original:** URL hardcoded do link do Bug usa `https://dev.azure.com/selbettidev/<project>/...` (linha 150) — a organização `selbettidev` está fixa; se o novo produto usar outra organização Azure DevOps, precisa ajuste trivial mas obrigatório.

#### Recomendações
- Validar, antes de reaproveitar, se o template de Bug do processo do novo projeto Azure DevOps também usa `ReproSteps` como campo visível — se usar `Description` ou outro campo custom, ajustar a constante.
- Adicionar campo opcional "Repositório/Subproduto de origem" ao rascunho do Step 1, quando a arquitetura multi-repo tornar isso ambíguo.

#### Classificação de Aderência
**Reutilizável com pequenas adaptações** — mecanismo de negócio (aprovação, estrutura, vínculo, log) é sólido e agnóstico; ajustes necessários são de configuração pontual (nome de campo do template, organização, projeto), não de reformulação estrutural.

#### Evidências
- Arquivo: gerar-defeito.md, linhas 88-90 — decisão de usar `ReproSteps`, justificada por incidente real, mas específica do template do processo atual.
- Arquivo: gerar-defeito.md, linha 150 — URL com organização `selbettidev` hardcoded.
- Arquivo: gerar-defeito.md, linha 176 — severidade sempre sugestão, nunca decisão automática — boa prática agnóstica.

---

### QA Release Validator (homologar-release.md)

#### Objetivo
Validar se uma release (conjunto de histórias) está pronta para produção — identifica impactos, seleciona regressão, executa, analisa falhas e recomenda Aprovada/Aprovada com ressalvas/Reprovada (linha 2). Recomendação, não decisão automática.

#### Estrutura
Bem organizada (159 linhas), reaproveita `/analise-tecnica`, `/executar-teste` e `/analise-falha` como sub-rotinas explícitas (linha 13) em vez de reimplementar. Tem uma seção de governança de decisão bem pensada ("Guardrail vs. Gates", linhas 23-32).

#### Dependências
Explícitas e por composição: depende inteiramente das skills `/analise-tecnica`, `/executar-teste`, `/analise-falha` (linha 13), e do projeto de automação `automacao.teste` (linha 69, "cruze... com os módulos já cobertos em `automacao.teste`").

#### Cobertura para BPM/ECM
- Herda todas as limitações de single-repo de `/analise-tecnica` (Step 2, linha 55) e de domínio-Cobrança de `/executar-teste` (Step 4.2, linha 87).
- A seleção de regressão automatizada (Step 3.2, linha 69) cita módulos nominalmente de Cobrança ("login, grupo-pagadores, adaptação mobile") — específico do produto de referência, mas a lógica ("cruzar camadas impactadas com módulos cobertos por automação") é um mecanismo genérico e reaproveitável.
- Nenhuma menção a Oracle/SQL Server ou a validação cruzada em dois bancos como critério de release readiness.
- O conceito central da skill (consolidar decisão de "pronto para produção" a partir de execução real + análise de risco + guardrail humano) é altamente relevante e diretamente aplicável a uma release BPM/ECM multi-repo — mas os **insumos** que ela consome (impacto por história via `/analise-tecnica`, execução via `/executar-teste`) precisam ser reconstruídos primeiro para suportar multi-repo/multi-banco, já que esta skill não reimplementa nada, só orquestra.

#### Pontos Fortes
- A separação conceitual "Guardrail vs. Gates" (linhas 23-32), com origem em decisão datada (linha 32), é uma peça de governança madura e diretamente reaproveitável — decisão explícita de que só decisão humana libera produção, gates técnicos podem endurecer com o tempo.
- Critério de recomendação explícito e determinístico (linhas 145-149), não por "impressão geral" — boa prática replicável.
- Já lida com histórias sem impacto mapeado sem travar a release inteira (linha 56) — flexibilidade útil, generalizável para "subproduto sem análise disponível".

#### Lacunas
- Nenhum critério de "Reprovada"/"ressalva" contempla explicitamente "falha por SGBD específico" (ex.: passou em SQL Server mas falhou em Oracle) — o critério atual (linhas 145-149) não tem categoria para isso.
- Nenhuma menção a validar dependências de configuração compartilhadas entre subprodutos antes de liberar a release (cenário citado como central no contexto do novo produto: "compartilhamento de configurações entre sistemas").

#### Riscos
- **Dependências não consideradas:** por ser 100% dependente de `/analise-tecnica` e `/executar-teste` como sub-rotinas (linha 13), toda limitação multi-repo/multi-banco identificada nessas duas se propaga integralmente para esta.
- **Acoplamento ao produto original:** caminho fixo do projeto de automação `automacao.teste` (herdado via Step 3.2) e nomes de módulo hardcoded de Cobrança.

#### Recomendações
- Adicionar ao critério de recomendação (Step 6) uma dimensão explícita "Cobertura Oracle x SQL Server: completa/parcial/não aplicável" por história, com regra de que "parcial" vira ressalva obrigatória.
- Adicionar ao Step 2 uma verificação explícita de "configurações compartilhadas entre subprodutos tocadas por esta release" — sinalizando como impacto cross-repo, não apenas por história isolada.

#### Classificação de Aderência
**Reutilizável com adaptações significativas** — a camada de orquestração e governança (guardrail vs. gates, critério de recomendação) é madura e vale muito a pena preservar; a cobertura real depende inteiramente das skills de insumo serem reconstruídas para multi-repo/multi-banco primeiro.

#### Evidências
- Arquivo: homologar-release.md, linhas 23-32 — separação "Guardrail vs. Gates", decisão datada de 2026-09-07.
- Arquivo: homologar-release.md, linha 69 — módulos de automação citados nominalmente (Cobrança).
- Arquivo: homologar-release.md, linhas 145-149 — critério de recomendação sem dimensão de SGBD.

---

### QA Documentation Agent (atualizar-documentacao.md)

#### Objetivo
Identificar páginas da wiki do Azure DevOps impactadas por uma história validada e propor atualização, sempre com aprovação explícita página por página (linha 2).

#### Estrutura
Bem estruturada (116 linhas), com regra fundamental clara sobre a limitação técnica do Azure DevOps Wiki (substituição total da página, não patch parcial — linha 17) e fluxo de aprovação individual bem desenhado.

#### Dependências
Explícitas: `mcp__azure-devops__get_wikis`, `search_wiki`, `get_wiki_page`, `list_wiki_pages`, `update_wiki_page`, `create_wiki_page` (linhas 25, 39-41, 79-80).

#### Cobertura para BPM/ECM
O mecanismo (buscar página → comparar com comportamento confirmado → propor edição completa → aprovar por página → publicar → reler para confirmar) é agnóstico de domínio, banco de dados e arquitetura de repositórios — depende só de existir uma wiki central do Azure DevOps. Se o novo produto mantiver documentação em múltiplas wikis (uma por repositório/subproduto, plausível dado "~7 repositórios"), a skill já pergunta qual wiki usar quando há mais de uma no mesmo projeto (linha 25), mas não tem mecanismo para buscar **através de múltiplos projetos/wikis simultaneamente** — a busca (`search_wiki`, linha 39) é implicitamente escopada a uma wiki/projeto por vez.

#### Pontos Fortes
- Nunca publicar sem aprovação página por página (linha 17-19) — princípio de segurança sólido e diretamente reutilizável, inclusive reforçado pelas regras globais do ambiente ("Explicit permission required" para "Publicar, postar ou modificar conteúdo público").
- Já lida com o caso "página não encontrada, propor criação" (linha 55) em vez de forçar informação em página errada — boa prática.
- Releitura pós-publicação para confirmar que o conteúdo bate com o aprovado (linha 82) é uma verificação de qualidade genérica e valiosa.

#### Lacunas
- Nenhum mecanismo para documentar dependências de configuração entre subprodutos (ex.: uma mudança que afeta a documentação de dois subprodutos simultaneamente, por compartilharem configuração) — a skill trata "página impactada" no singular por vez, sem noção de propagação cruzada entre wikis de produtos diferentes.
- Não há orientação para o caso de a mesma história impactar documentação em mais de uma wiki de projetos diferentes.

#### Riscos
- **Cobertura insuficiente:** se o novo produto mantiver uma wiki por repositório/subproduto (plausível dada a arquitetura de ~7 repositórios), a skill precisaria rodar uma vez por wiki manualmente — funcional, mas sem orquestração entre elas, o que pode gerar inconsistência entre documentações relacionadas.
- Risco baixo de acoplamento ao produto original: o conteúdo do arquivo não cita nenhum termo específico de Cobrança.

#### Recomendações
- Adicionar um passo opcional (quando aplicável) de detectar se a história/mudança afeta mais de um subproduto e, nesse caso, perguntar explicitamente em quais wikis buscar, uma de cada vez, sem perder o rastreio de que é a mesma mudança de origem.

#### Classificação de Aderência
**Reutilizável com pequenas adaptações** — mecanismo central é sólido, agnóstico de domínio; a única lacuna real é orquestração entre múltiplas wikis de múltiplos repositórios, que é mais uma extensão do fluxo do que uma reconstrução.

#### Evidências
- Arquivo: atualizar-documentacao.md, linha 17 — regra de nunca publicar sem aprovação, "conteúdo final completo da página" por limitação técnica do Azure DevOps Wiki.
- Arquivo: atualizar-documentacao.md, linha 25 — pergunta qual wiki usar se houver mais de uma no mesmo projeto, mas sem previsão de múltiplos projetos.
- Arquivo: atualizar-documentacao.md, linha 82 — releitura pós-publicação para confirmar sucesso, boa prática agnóstica.

---

### QA Automation Engineer (priorizar-automacao.md)

#### Objetivo
Classificar cenários de teste em alta/média/baixa prioridade de automação e promover os de alta prioridade de `tests/user-stories/` para `tests/regressao/` no projeto `automacao.teste` (linha 2).

#### Estrutura
Bem estruturada (127 linhas), com regra fundamental clara (nunca promover hipótese não confirmada, nunca declarar sucesso sem rodar de fato — linhas 21-23).

#### Dependências
Explícitas e fortemente hardcoded: projeto alvo `C:\Users\cintia.gregorio\Desktop\automacao.teste` (linha 13); planilha `C:\Users\cintia.gregorio\Desktop\planilha_features\features_cobranca.xlsx` (linha 94) lida via Python/openpyxl. Ambos caminhos são específicos de uma máquina/pessoa e de um domínio (o nome do arquivo já é `features_cobranca.xlsx`).

#### Cobertura para BPM/ECM
- Estrutura de categorias herdadas de `gerar-mapa-testes` (linha 14: "fluxo-principal, fluxo-alternativo, validacoes-campos, comportamento-modal, busca-vinculos, cancelamento, erros-integracao, consistencia-persistencia, casos-borda") é conceitualmente agnóstica de domínio, embora o nome específico das categorias precise mapear com as categorias fixas do `gerar-mapa-testes-v3` (que, aliás, usa nomes ligeiramente diferentes — ver observação abaixo).
- Nenhuma menção a Oracle/SQL Server, BPM ou ECM.
- Critério de priorização (Step 2, linhas 44-54: criticidade, frequência, estabilidade, custo manual, risco de regressão) é um framework de decisão genérico e reutilizável, independente de domínio.

#### Pontos Fortes
- Nunca promover cenário construído de hipótese não confirmada (linha 21) — mantém coerência com as demais skills que tratam `HIPOTESE:` com cuidado.
- Nunca declarar promoção concluída sem rodar de fato o spec (linha 23, 83-85) — disciplina de verificação real, reutilizável.
- Trata "gap de automação" (nenhum spec ainda) como caso distinto de "promoção" (Step 5, linhas 89-96), evitando forçar um fluxo que não se aplica.

#### Lacunas
- Caminhos hardcoded de máquina/pessoa específica (`cintia.gregorio\Desktop`) tornam a skill inutilizável sem reconfiguração even dentro do mesmo produto de referência, quanto mais no novo produto.
- Nome do arquivo de contexto (`features_cobranca.xlsx`, linha 94) é literal do domínio Cobrança — não existe hoje um equivalente para outro domínio.
- **Observação de inconsistência interna encontrada nos arquivos:** as categorias citadas aqui (linha 14: "fluxo-principal", "comportamento-modal", "busca-vinculos", "cancelamento", "consistencia-persistencia") não coincidem exatamente com as categorias fixas do `gerar-mapa-testes-v3.md` (linhas 166-174: "FLUXO PRINCIPAL", "FLUXO ALTERNATIVO", "VALIDACOES DE CAMPOS", "PERMISSAO", "DADOS E CASOS DE BORDA", "CONCORRENCIA", "ERROS DE INTEGRACAO / API", "REGRESSAO", "CASOS DE BORDA / HIPOTESES"). Isso é uma divergência real entre dois arquivos do mesmo diretório, registrada aqui como fato observado, não suposição — pode indicar que `priorizar-automacao.md` não foi atualizado na mesma revisão que `gerar-mapa-testes-v3.md` (v3 é citado como versão nova; a lista de categorias em `priorizar-automacao.md` linha 14 parece herdada de uma versão anterior do gerador de mapas).

#### Riscos
- **Acoplamento ao produto original:** é a segunda skill mais acoplada (depois de `executar-teste.md`) — caminho de máquina, nome de planilha, e nome do projeto de automação são todos específicos do time/produto atual.
- **Premissas rígidas:** assume Playwright como framework de automação único (`npx playwright test`, linha 29, 83) — não informado se o novo produto usará o mesmo framework de automação de front-end (arquitetura BPM/ECM separando backend/frontend pode implicar em stacks de teste diferentes, mas isso não está confirmado em nenhum arquivo — **Informação não encontrada**).

#### Recomendações
- Extrair os caminhos hardcoded (linha 13, 94) para variáveis de configuração/ambiente, independentemente do novo produto — já seria uma melhoria necessária mesmo dentro do produto de referência.
- Resolver a divergência de nomenclatura de categorias entre esta skill e `gerar-mapa-testes-v3.md` antes de reutilizar qualquer uma das duas, para não gerar confusão sobre qual taxonomia é a vigente.
- Confirmar explicitamente, antes de reutilizar, se o novo produto usa Playwright para automação de front-end (se usar outra stack, o Step 4 precisa reescrita completa dos comandos de execução).

#### Classificação de Aderência
**Reutilizável com adaptações significativas** — o framework de priorização (critérios de decisão) é genérico e vale a pena preservar; a camada de execução (caminhos hardcoded, nome de planilha, framework assumido) precisa de generalização e resolução da divergência de nomenclatura identificada.

#### Evidências
- Arquivo: priorizar-automacao.md, linha 13 — caminho hardcoded `C:\Users\cintia.gregorio\Desktop\automacao.teste`.
- Arquivo: priorizar-automacao.md, linha 94 — planilha `features_cobranca.xlsx`, nome literal do domínio Cobrança.
- Arquivo: priorizar-automacao.md, linha 14 vs. gerar-mapa-testes-v3.md, linhas 166-174 — divergência de nomenclatura de categorias entre os dois arquivos, observação factual.

## 4. Matriz Consolidada

| Skill | Objetivo | Cobertura Atual | Lacunas | Aderência | Recomendação |
|---|---|---|---|---|---|
| QA Business Analyst (analise-negocio.md) | Extrair regras de negócio de User Story do ADO | Rastreabilidade rigorosa, agnóstica de domínio | Sem estrutura para dependências de configuração em cadeia; projeto default fixo | Reutilizável com adaptações significativas | Adaptar |
| QA Technical Analyst (analise-tecnica.md) | Mapear impacto técnico via card Análise + 1 PR | Camadas técnicas e discrepâncias de escopo bem tratadas | Single-repo/single-PR; sem multi-banco; sem pré-requisito de config funcional | Recomendada reconstrução | Recriar |
| Gerador de Mapa de Testes v3 (gerar-mapa-testes-v3.md) | Gerar/publicar mapa de cenários no card ADO | Checklist de dimensões robusto, rastreabilidade estrita de origem | Sem dimensão de config/SGBD; sem categoria de fluxo BPM | Reutilizável com adaptações significativas | Adaptar |
| QA Test Executor (executar-teste.md) | Executar cenários via Playwright | Guardrails de evidência e segurança maduros; Modo B proporcional | 100% acoplado a domínio Cobrança (CNAB, credenciais, MySQL); sem Oracle/SQL Server | Recomendada reconstrução | Recriar |
| QA Failure Analyst (analise-falha.md) | Investigar causa de falha, decidir se abre defeito | Raciocínio agnóstico de domínio e banco | Herda limitação single-PR; falta categoria "config ausente" | Reutilizável com pequenas adaptações | Adaptar (pequeno) |
| Geração de Defeito (gerar-defeito.md) | Criar Bug estruturado no ADO com aprovação | Fluxo de aprovação e vínculo maduro, agnóstico de domínio | Depende de template específico (`ReproSteps`); sem campo de subproduto/repo | Reutilizável com pequenas adaptações | Adaptar (pequeno) |
| QA Release Validator (homologar-release.md) | Recomendar liberação de release para produção | Governança "Guardrail vs. Gates" madura; critério de decisão explícito | Herda limitações de insumos (single-repo, domínio Cobrança); sem critério multi-banco | Reutilizável com adaptações significativas | Adaptar (após recriar insumos) |
| QA Documentation Agent (atualizar-documentacao.md) | Propor/publicar atualização de wiki do ADO | Aprovação página por página, releitura de confirmação | Sem orquestração entre múltiplas wikis de múltiplos repositórios | Reutilizável com pequenas adaptações | Adaptar (pequeno) |
| QA Automation Engineer (priorizar-automacao.md) | Priorizar e promover testes para regressão automatizada | Framework de priorização genérico e sólido | Caminhos hardcoded de máquina/pessoa; nome de planilha específico de Cobrança; divergência de nomenclatura com v3 | Reutilizável com adaptações significativas | Adaptar |

## 5. Gaps para o Novo Produto BPM/ECM

Com base exclusivamente no que foi (não) encontrado nos 9 arquivos:

- **Dependências entre configurações:** nenhuma das 9 skills tem um mecanismo dedicado a rastrear cadeias de pré-requisito de cadastro (ex.: tipo de documento → tipo de índice → usuário → perfil, do exemplo do enunciado). O item mais próximo é "Pré-requisitos técnicos de execução de teste" em `analise-tecnica.md:102`, mas ele é sobre infraestrutura de teste (bucket, variável de ambiente), não sobre cadastros funcionais de negócio.
- **Testes Oracle x SQL Server:** ausente por completo. O único acesso a banco em toda a base é `mysql-cobranca-hmg` (MySQL, leitura, um produto só) em `executar-teste.md:36,159`. Nenhum arquivo menciona Oracle ou SQL Server.
- **Fluxos BPM:** nenhuma menção a processo, workflow, tarefa, transição de estado de processo em nenhum dos 9 arquivos.
- **Publicação ECM:** nenhuma menção a documento, publicação de documento, índice, metadado em nenhum dos 9 arquivos.
- **Integrações entre repositórios:** `analise-tecnica.md` opera sobre um PR só (linha 83); nenhuma skill tem conceito de "diff consolidado de múltiplos repositórios para uma mesma história".
- **Configurações compartilhadas:** não há menção ao conceito de configuração compartilhada entre sistemas/subprodutos em nenhum arquivo.
- **Instalação e ambientes on-premise:** nenhuma menção a instalação, deploy on-premise, ou particularidades de ambiente não-cloud em nenhum dos 9 arquivos — todas as skills assumem acesso via MCPs já conectados (Azure DevOps, Playwright, MySQL).
- **Testes end-to-end multi-repo:** `homologar-release.md` chega mais perto (orquestra múltiplas histórias), mas cada história ainda é tratada com o modelo single-repo herdado de `analise-tecnica.md`.
- **Permissões e perfis:** parcialmente coberto — `gerar-mapa-testes-v3.md:150` já tem a dimensão "Permissão" no checklist obrigatório ("Usuário/perfil sem permissão tenta a mesma ação"), mas é tratado como uma dimensão de teste isolada por regra condicional, não como parte de uma cadeia de dependência de configuração (perfil precisa existir e estar associado a um usuário, que precisa ter sido dado como pré-requisito antes do próprio cenário rodar).

## 6. Novas Skills Recomendadas

> Nota: os itens abaixo são propostas baseadas em lacunas explicitamente identificadas nas seções 3 e 5; não há, nos 9 arquivos, nenhuma skill similar já esboçada para estes objetivos — são recomendações novas, não adaptações.

### Skill: Rastreador de Dependências de Configuração

#### Objetivo
Mapear, a partir de uma história/funcionalidade, a cadeia de cadastros e configurações pré-requisito necessárias para a funcionalidade operar (ex.: tipo de documento → tipo de índice → usuário → perfil).

#### Problema que resolve
Nenhuma das 9 skills atuais rastreia dependências de configuração em cadeia — apenas dependências de sistemas/PR (`analise-tecnica.md`) ou infraestrutura de teste (`analise-tecnica.md:102`). Sem essa skill, mapas de teste e execuções corem risco sistemático de gerar `NAO EXECUTADO — dado de teste ausente` por falta de preparação de ambiente que poderia ter sido antecipada.

#### Entradas necessárias
História/funcionalidade alvo; documentação de cadastros do produto (não identificada em nenhum dos 9 arquivos — precisaria ser criada/localizada no novo produto).

#### Saídas esperadas
Lista ordenada de pré-requisitos de configuração, com indicação de qual já existe no ambiente de teste e qual precisa ser criado antes da execução — consumível por `/executar-teste` (equivalente à seção Step 2.5 já existente para pré-requisitos técnicos) e por `/gerar-mapa-testes-v3` (nova dimensão de checklist).

#### Prioridade
Alta

### Skill: Validador Multi-Banco (Oracle x SQL Server)

#### Objetivo
Para cenários que envolvem persistência/consulta de dados, garantir e registrar validação equivalente em ambos os SGBDs suportados.

#### Problema que resolve
Nenhuma skill hoje distingue SGBD; o único MCP de leitura de banco existente é MySQL, único produto (Cobrança). Sem isso, testes que dependem de comportamento específico de SGBD (tipos de dado, locking, sintaxe SQL) arriscam cobertura falsamente equivalente entre os dois bancos obrigatórios do novo produto.

#### Problema que resolve (detalhe)
Evita que um cenário "passou" seja reportado com base em um único SGBD quando o produto suporta dois.

#### Entradas necessárias
Acesso de leitura a ambos os bancos (Oracle e SQL Server) via MCP equivalente ao `mysql-cobranca-hmg`; cenário de teste e o dado/query a validar em cada banco.

#### Saídas esperadas
Relatório por cenário indicando Passou/Falhou por banco, separadamente, nunca consolidado como um resultado único.

#### Prioridade
Alta

### Skill: Analisador de Impacto Multi-Repositório

#### Objetivo
Substituir/estender `analise-tecnica.md` para consolidar múltiplos PRs de múltiplos repositórios vinculados a uma mesma história, mantendo a mesma disciplina de "card Análise como fonte de verdade + discrepância dev vs. PR" já validada.

#### Problema que resolve
`analise-tecnica.md` hoje lê "um" PR (linha 83); a arquitetura do novo produto (~7 repositórios, backend/frontend separados) torna isso insuficiente para a maioria das histórias reais.

#### Entradas necessárias
Lista de PRs/repositórios vinculados à história (mecanismo de vínculo ainda não definido nos arquivos — **Informação não encontrada**, precisa ser definido no novo processo).

#### Saídas esperadas
Mesmo relatório de `analise-tecnica.md` (Step 4), mas com uma linha "Repositório de origem" adicional em cada tabela de camada/dependência.

#### Prioridade
Alta

### Skill: QA Test Executor para BPM/ECM (reconstrução de executar-teste.md)

#### Objetivo
Equivalente funcional ao `executar-teste.md`, mas com KB de produto, credenciais e preparação de massa de dados específicas de BPM/ECM (ex.: gerar documento de teste com metadados de índice, disparar instância de processo) no lugar do conteúdo de Cobrança (CNAB, instâncias bancárias).

#### Problema que resolve
`executar-teste.md` é hoje inteiramente inutilizável fora do domínio Cobrança em sua maior parte (credenciais, preparação CNAB, KB indexada) — precisa de um equivalente dedicado.

#### Entradas necessárias
KB de produto BPM/ECM (a criar); arquivo de credenciais de ambiente equivalente; mecanismo de geração de massa de teste para documento/índice/perfil (equivalente às skills `gerar-cnab240`/`gerar-cnab400` referenciadas, mas não presentes neste diretório).

#### Saídas esperadas
Mesmo relatório estruturado de execução (Passou/Falhou/Não executado com evidência), reaproveitando o esqueleto Playwright já validado.

#### Prioridade
Alta

### Skill: Verificador de Configuração Compartilhada entre Subprodutos

#### Objetivo
Antes de uma release, identificar se alguma configuração alterada por uma história é compartilhada entre subprodutos/repositórios, sinalizando risco de efeito colateral cruzado.

#### Problema que resolve
`homologar-release.md` e `analise-tecnica.md` avaliam impacto por história isolada; nenhum mecanismo hoje verifica se uma configuração alterada é consumida por outro subproduto.

#### Entradas necessárias
Mapa de quais configurações são compartilhadas entre quais subprodutos (não documentado em nenhum dos 9 arquivos — precisa ser levantado junto ao time de dev do novo produto).

#### Saídas esperadas
Lista de subprodutos potencialmente afetados por uma configuração compartilhada alterada, para entrar como ressalva em `homologar-release.md`.

#### Prioridade
Média

## 7. Conclusão

Das 9 skills analisadas, nenhuma foi classificada como "reutilizável sem alterações". A avaliação, fundamentada exclusivamente no conteúdo lido, mostra um conjunto de skills tecnicamente maduro em disciplina de processo (rastreabilidade, aprovação humana, evidência obrigatória, não-suposição, log de governança) — esses princípios são diretamente aproveitáveis no novo produto BPM/ECM, independentemente do domínio. Contudo, o acoplamento estrutural é substancial em três eixos que o contexto do novo produto torna centrais e que **não aparecem em nenhum dos 9 arquivos**: (1) suporte a múltiplos bancos de dados (Oracle e SQL Server — hoje só há MySQL, single-produto), (2) arquitetura multi-repositório com backend/frontend separados (hoje o modelo é single-PR/single-repo em `analise-tecnica.md`, propagado para `analise-falha.md` e `homologar-release.md`), e (3) rastreamento de dependências de configuração em cadeia (nenhuma skill trata isso como conceito estruturado, apenas dependências pontuais de dado ou infraestrutura de teste).

Duas skills (`analise-tecnica.md` e `executar-teste.md`) foram classificadas como "Recomendada reconstrução" porque seu acoplamento ao domínio/arquitetura de referência está no núcleo do seu funcionamento, não em detalhes periféricos. As demais 7 são reutilizáveis com adaptações de escopo variável, sendo o padrão de processo (aprovação humana, rastreabilidade, log de auditoria) o principal ativo a preservar em qualquer reconstrução.

## Limitações da Análise

- Todos os 9 arquivos do diretório foram lidos por completo, sem truncamento — nenhum arquivo ficou parcialmente lido ou com erro de leitura.
- Esta análise não teve acesso a nenhum artefato do "novo produto" além da descrição textual fornecida no pedido do usuário (arquitetura, banco de dados, dependências de configuração) — não há arquivo correspondente no diretório analisado que descreva o novo produto; todas as comparações usaram essa descrição fornecida em linguagem natural como termo de comparação, não um documento formal.
- Não há, no diretório, nenhum artefato que documente o processo/template exato do Azure DevOps do novo produto (tipos de work item, campos customizados) — qualquer afirmação sobre compatibilidade futura desses aspectos é necessariamente condicional ("se o novo processo usar os mesmos campos...").
- As skills `gerar-cnab240` e `gerar-cnab400`, referenciadas dentro de `executar-teste.md` (linhas 176-178), não fazem parte deste diretório e não foram lidas — qualquer avaliação sobre elas está fora do escopo desta análise.
