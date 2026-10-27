# Arquitetura de Skills QA — BPM/ECM

> Esta proposta parte diretamente das duas análises anteriores deste diretório — [`analise-skills-bpm-ecm.md`](analise-skills-bpm-ecm.md) (auditoria das 9 skills existentes) e [`analise-riscos-skills-extensas.md`](analise-riscos-skills-extensas.md) (riscos de skills extensas e estratégias de mitigação) — e as trata como insumo obrigatório, não como contexto opcional. Toda decisão de granularidade, camada e skill recomendada abaixo cita, quando aplicável, o achado concreto que a motivou.
>
> Três lacunas estruturais identificadas nas análises anteriores são o eixo central desta arquitetura: **(1)** ausência de suporte a múltiplos bancos de dados (Oracle e SQL Server), **(2)** ausência de suporte a arquitetura multi-repositório (análise técnica hoje é single-PR/single-repo), **(3)** ausência de rastreamento de dependências de configuração em cadeia (o padrão "tipo de documento → tipo de índice → perfil → usuário → permissões" descrito no enunciado). Nenhuma das 9 skills auditadas cobre qualquer um dos três.

## Sumário

1. [Visão Geral](#1-visão-geral)
2. [Princípios Arquiteturais](#2-princípios-arquiteturais)
3. [Critérios de Granularidade](#3-critérios-de-granularidade)
4. [Estrutura da Biblioteca](#4-estrutura-da-biblioteca)
5. [Mapa de Dependências](#5-mapa-de-dependências)
6. [Catálogo de Skills](#6-catálogo-de-skills)
7. [Fluxos Orquestrados](#7-fluxos-orquestrados)
8. [Estratégia Oracle x SQL Server](#8-estratégia-oracle-x-sql-server)
9. [Estratégia de Cobertura e Controle de Dependências](#9-estratégia-de-cobertura-e-controle-de-dependências)
10. [Estratégia de Qualidade das Skills (Meta-QA)](#10-estratégia-de-qualidade-das-skills-meta-qa)
11. [Roadmap de Implementação](#11-roadmap-de-implementação)
12. [Recomendações Finais](#12-recomendações-finais)

---

## 1. Visão Geral

O produto é um BPM/ECM on-premise: ~7 repositórios, backend e frontend separados, dois SGBDs suportados (Oracle e SQL Server), funcionalidades altamente configuráveis, perfis e permissões complexas, e um padrão recorrente de **dependência em cadeia** entre cadastros (tipo de documento → tipo de índice → perfil → usuário → permissões, antes de publicar um documento). Esse padrão se repete "em grande parte do sistema" — não é uma exceção pontual, é uma característica estrutural do domínio.

A auditoria anterior mostrou que o conjunto de 9 skills existentes tem uma disciplina de processo madura e reaproveitável (rastreabilidade, aprovação humana, não-suposição, log de governança, checklists obrigatórios), mas foi desenhado para um produto de domínio único (Cobrança), single-repo, single-banco (MySQL) — o oposto da arquitetura declarada aqui em três eixos centrais.

A resposta arquitetural não é reescrever as 9 skills do zero nem criar uma "super-skill" única para BPM/ECM. É:

- **Preservar** o padrão de múltiplas skills pequenas e especializadas, encadeadas manualmente (gate humano entre etapas) — a análise de riscos já concluiu que consolidar em skills grandes aumenta perda de contexto, omissão silenciosa e dificuldade de manutenção, e que a divisão já em uso é o padrão correto a manter.
- **Adicionar** uma camada de conhecimento de produto (Camada 1) que hoje não existe em nenhuma forma — nem para BPM, nem para ECM, nem para o catálogo de dependências de configuração.
- **Reconstruir** apenas as duas skills cujo acoplamento estrutural (single-repo, domínio Cobrança) está no núcleo do funcionamento, não em detalhe periférico (`analise-tecnica.md` e `executar-teste.md`, conforme classificação "Recomendada reconstrução" da auditoria).
- **Introduzir** três capacidades novas, ausentes por completo hoje: rastreamento de dependência de configuração, validação multi-banco, e análise de impacto multi-repositório.
- **Formalizar** uma camada de meta-QA (qualidade das próprias skills), hoje inexistente mesmo informalmente, além do histórico reativo de troubleshooting já observado em `executar-teste.md`.

---

## 2. Princípios Arquiteturais

| # | Princípio | Descrição | Por quê (evidência) |
|---|---|---|---|
| P1 | **Responsabilidade única por skill** | Cada skill resolve exatamente um tipo de pergunta ou produz exatamente um tipo de artefato. Uma skill nunca analisa E executa E decide. | A análise de riscos identifica "dependência excessiva de uma única skill" como risco direto de concentração de responsabilidade; `homologar-release.md` já demonstra o padrão correto (orquestra, não reimplementa). |
| P2 | **Composição sobre concentração** | Fluxos complexos (planejamento, regressão, homologação de release) são resolvidos por uma skill orquestradora que consome skills atômicas, nunca por uma skill atômica crescendo para cobrir mais casos. | Skills extensas (`executar-teste.md`, 354 linhas; `gerar-mapa-testes-v3.md`, 346 linhas) já mostram sintomas documentados de perda de contexto e dificuldade de manutenção. |
| P3 | **Contrato de dados fixo entre skills** | Toda troca de informação entre skills usa um formato de campo fixo e nomeado (ex.: "Origem", "Cenário de origem", "Repositório de origem"), nunca prosa livre reformulável. | `gerar-defeito.md` já usa rótulo fixo lido de volta por `executar-teste.md` — padrão validado; a divergência de nomenclatura encontrada entre `priorizar-automacao.md` e `gerar-mapa-testes-v3.md` mostra o custo de não ter isso em todo lugar. |
| P4 | **Nunca supor — rastrear ou declarar ausência** | Toda skill deve citar a origem exata de cada afirmação (linha, campo, sistema) e registrar explicitamente "Informação não encontrada" quando não houver base — nunca preencher por inferência. | Regra já presente e validada em 3 das 9 skills atuais; é a base de qualquer auditoria de cobertura confiável. |
| P5 | **Checklist obrigatório sobre validação implícita** | Toda dimensão de cobertura que pode ser esquecida silenciosamente (config, SGBD, permissão, integração) vira uma linha obrigatória do checklist, com "N/A justificado" quando não aplicável — nunca uma omissão silenciosa. | `gerar-mapa-testes-v3.md` Step 4.1 já demonstra o mecanismo; a análise de riscos recomenda estendê-lo para toda dimensão nova (config, SGBD, multi-repo). |
| P6 | **Gate humano, nunca automação silenciosa de decisão irreversível** | Aprovação humana obrigatória antes de qualquer publicação, criação de defeito, ou decisão de release — preservado de todas as 9 skills atuais. | Já é o padrão em 100% das 9 skills (aprovação de wiki, de defeito, de release) — não há motivo para regredir esse ponto no novo produto. |
| P7 | **Skills agnósticas de domínio ficam no Core; conteúdo de produto fica isolado** | Mecanismo genérico (como comparar esperado vs. obtido, como registrar evidência) nunca se mistura com conteúdo específico de produto (credenciais, massa de dados, nomes de módulo). | Causa raiz identificada da reconstrução obrigatória de `executar-teste.md`: mecanismo genérico Playwright bom, mas 100% emaranhado com CNAB/Cobrança. |
| P8 | **Dependência de configuração é cidadã de primeira classe** | Toda skill de análise ou planejamento que toca uma funcionalidade configurável deve consultar o catálogo de dependências de configuração antes de declarar cobertura completa. | Gap identificado como um dos três eixos centrais ausentes em 100% das 9 skills; é o padrão mais citado no enunciado do produto (exemplo do documento → índice → perfil). |
| P9 | **Todo resultado de banco é rotulado por SGBD** | Nenhum veredito de teste que envolva persistência pode ser relatado sem indicar em qual SGBD rodou; "passou" nunca é consolidado entre Oracle e SQL Server sem essa distinção. | Risco explícito da análise de riscos: "um teste passou reportado sem indicar em qual banco rodou pode mascarar falha real só em um dos dois". |
| P10 | **A biblioteca é um sistema de engenharia, com QA de si mesma** | Skills têm versão, dono, changelog, e conjunto de casos de referência para regressão — não são documentos de texto livre editados ad hoc. | Recomendação explícita da análise de riscos (seção 4 e 6), ausente hoje mesmo informalmente. |

---

## 3. Critérios de Granularidade

A pergunta central de granularidade é: **quando uma capacidade vira sua própria skill, e quando ela fica dentro de outra?** Os critérios abaixo foram derivados diretamente dos padrões de sucesso/fracasso observados nas 9 skills auditadas.

### 3.1 O que deve ser uma skill independente

Uma capacidade merece skill própria quando **pelo menos duas** destas condições são verdadeiras:

- **Produz um artefato de decisão ou registro autônomo** (ex.: um veredito, um defeito, um mapa de cenários) que outras skills consomem por contrato de dados fixo — não apenas um passo intermediário de outra análise.
- **É reutilizável em mais de um fluxo** (ex.: rastreamento de dependência de configuração é consumido tanto pelo planejamento de testes quanto pela execução e pela análise de impacto de release).
- **Tem uma fonte de verdade e um conjunto de regras de negócio próprios**, distintos dos de qualquer skill vizinha (ex.: "o que é uma falha de dado ausente" é uma pergunta diferente de "o que é uma falha de lógica de negócio").
- **Seu tamanho isolado já se aproxima do limite recomendado** (ver 3.3) quando fundida com outra responsabilidade — sinal de que a fusão está gerando concentração excessiva (P1).

Exemplos concretos aplicando o critério: *Rastreador de Dependências de Configuração* é independente (reutilizada por três fluxos diferentes, fonte de verdade própria — o catálogo de configurações). *Validador Oracle x SQL Server* é independente (regra de negócio própria: equivalência de comportamento entre SGBDs, não apenas "rodar a mesma query duas vezes").

### 3.2 O que não deve ser separado

- **Passos que só fazem sentido em sequência estrita e nunca são reaproveitados isoladamente** (ex.: "montar rascunho de defeito" e "obter aprovação humana" dentro de `gerar-defeito.md` — separar geraria duas skills que sempre são chamadas juntas, sem nenhum ganho de reuso, só overhead de orquestração).
- **Variações de saída do mesmo raciocínio central** (ex.: gerar mapa de teste para um cenário BPM vs. um cenário ECM não deveria virar duas skills conceitualmente diferentes se o raciocínio de checklist é o mesmo — a diferença é o *conteúdo de domínio* injetado, não o mecanismo; ver 6.3 sobre como isso é resolvido via KB, não via duplicação de skill).
- **Validações triviais de formato** (ex.: "o campo veio preenchido?") nunca viram skill própria — ficam embutidas na skill que já produz o artefato.

### 3.3 Tamanho ideal de uma skill

- **Alvo:** 80–150 linhas de instrução (excluindo templates de saída extensos). As duas skills classificadas como mais bem-sucedidas em foco e reuso na auditoria anterior (`analise-falha.md`, 94 linhas, e `gerar-defeito.md`, 179 linhas) estão nessa faixa ou próximas dela.
- **Sinal de alerta:** acima de ~250 linhas, ou mais de ~8 regras na seção de "regra fundamental". As duas skills reconstruídas por decisão desta arquitetura (`executar-teste.md`, 354 linhas, e `gerar-mapa-testes-v3.md`, 346 linhas) estavam ambas acima desse limiar, e ambas mostram sintomas documentados (perda de contexto recorrente, necessidade de checklist forçado para não omitir dimensão).
- **Quando dividir:** no momento em que uma nova responsabilidade (uma nova pergunta a responder, uma nova fonte de dados a consultar) precisar ser adicionada a uma skill que já está no alvo de tamanho — a divisão deve acontecer *antes* de ultrapassar o sinal de alerta, não depois.

### 3.4 Quando criar uma skill orquestradora

Uma skill orquestradora é justificada quando **todas** estas condições se aplicam:

- O processo de negócio exige consolidar saídas de **três ou mais** skills atômicas em uma única decisão (ex.: homologação de release consolida impacto técnico, execução e análise de falha).
- Existe uma decisão de governança de alto nível que não pertence a nenhuma skill atômica individualmente (ex.: "release pronta para produção" não é responsabilidade de nenhuma skill de execução isolada).
- O fluxo se beneficia de paralelização futura entre as skills consumidas (mesmo que hoje sequencial) — sinal de que a composição, não a fusão, é a forma correta.

Uma skill orquestradora **nunca reimplementa lógica de análise** — ela consulta, consolida, e aplica critério de decisão explícito e determinístico sobre o que recebeu (herdando o padrão "Guardrail vs. Gates" já validado em `homologar-release.md`).

---

## 4. Estrutura da Biblioteca

### 4.1 Estrutura de diretórios

```
qa-skills/
├── 00-core/                          # Contratos, governança, formatos — nunca specific de domínio
│   ├── contrato-dados-entre-skills.md
│   ├── log-governanca.md
│   ├── formatos-padrao-saida.md
│   └── principios-nao-suposicao.md
│
├── 10-conhecimento-produto/           # Fonte de verdade sobre O QUE é o produto
│   ├── kb-bpm.md
│   ├── kb-ecm.md
│   ├── catalogo-repositorios.md
│   └── catalogo-configuracoes-dependencias.md
│
├── 20-analise/                        # Entender O QUE mudou e por quê
│   ├── analise-negocio.md
│   ├── analise-tecnica-multi-repo.md
│   └── rastreador-dependencias-configuracao.md
│
├── 30-planejamento/                   # Decidir O QUE testar
│   ├── gerar-mapa-testes.md
│   ├── estrategia-cobertura-multibanco.md
│   └── planejar-testes.md            # orquestradora
│
├── 40-execucao/                       # Rodar de fato
│   ├── preparador-massa-dados.md
│   ├── executor-teste-bpm.md
│   ├── executor-teste-ecm.md
│   └── validador-oracle-sqlserver.md
│
├── 50-diagnostico/                    # Interpretar resultado
│   ├── analise-falha.md
│   └── gerar-defeito.md
│
├── 60-release/                        # Consolidar decisão de negócio
│   ├── analisador-impacto-multirepo.md   # orquestradora
│   ├── verificador-config-compartilhada.md
│   └── homologar-release.md              # orquestradora master
│
├── 70-documentacao/                   # Manter conhecimento atualizado
│   └── atualizar-documentacao-multirrepo.md
│
├── 80-automacao/                      # Converter cobertura manual em automatizada
│   └── priorizar-automacao.md
│
└── 90-meta-qa/                        # QA da própria biblioteca de skills
    ├── auditor-consistencia-skills.md
    ├── validador-qualidade-saida.md
    ├── consolidador-metricas.md
    └── regressao-skills.md
```

### 4.2 Categorias de skills e por que cada agrupamento faz sentido

| Camada | Pergunta que responde | Por que existe como camada separada |
|---|---|---|
| **00-core** | "Como as skills conversam entre si?" | Nenhuma das 9 skills atuais tem esse contrato formalizado em arquivo próprio — está implícito e espalhado (rótulo "Cenário de origem" em `gerar-defeito.md`, coluna "Origem" em `gerar-mapa-testes-v3.md`). Formalizar aqui resolve a causa raiz da divergência de nomenclatura já encontrada entre skills. |
| **10-conhecimento-produto** | "O que é verdade sobre este produto, independente de qualquer execução específica?" | É a camada mais ausente hoje. `executar-teste.md` já tem o conceito de "KB de produto indexada" (Cobrança, Portaria), mas nada equivalente existe para dependências de configuração ou para múltiplos repositórios. Sem essa camada, toda skill de análise reinventaria conhecimento de produto a cada execução. |
| **20-análise** | "O que mudou, e o que isso implica?" | Separado de planejamento porque a pergunta "o que mudou" (fato) é logicamente anterior e distinta de "o que testar por causa disso" (decisão) — mistura das duas foi um dos fatores que tornou `analise-tecnica.md` rígida demais para multi-repo. |
| **30-planejamento** | "O que precisa ser verificado?" | Consome a análise e o catálogo de dependências para produzir um plano — nunca executa nada, preservando o princípio já validado em `analise-negocio.md`/`gerar-mapa-testes-v3.md` de ser somente leitura/geração, nunca ação. |
| **40-execução** | "O comportamento real bate com o esperado?" | Isolada porque é a camada com maior volume de ferramenta externa (browser, banco de dados) e maior risco de perda de contexto em execuções longas — justifica ser dividida por subdomínio (BPM vs. ECM) em vez de ser uma skill monolítica, replicando o raciocínio de tamanho de 3.3. |
| **50-diagnóstico** | "Por que falhou, e isso é um defeito?" | Separada de execução porque a decisão de "abrir defeito" é uma decisão de negócio (severidade, prioridade), não um resultado técnico — já validado como boa separação em `analise-falha.md`/`gerar-defeito.md`. |
| **60-release** | "Estamos prontos para produção?" | Camada puramente orquestradora — nunca deve conter lógica de análise própria, apenas consolidação e critério de decisão, herdando o padrão maduro já existente em `homologar-release.md`. |
| **70-documentação** | "O conhecimento publicado ainda reflete a realidade?" | Mantida separada por ser um fluxo de saída (publicação), com gate de aprovação próprio, distinto do fluxo de teste. |
| **80-automação** | "O que vale a pena automatizar?" | Fluxo de conversão de cobertura manual para automatizada é conceitualmente posterior a toda a cadeia de teste manual — mantido como categoria própria pois seu critério de decisão (criticidade, frequência, estabilidade) é independente do domínio testado. |
| **90-meta-qa** | "A biblioteca de skills continua confiável?" | Camada inteiramente nova, recomendada pela análise de riscos (seção 4) como ausente hoje mesmo informalmente — sem ela, a única forma de detectar divergência entre skills é auditoria manual pontual (como a que gerou os dois documentos anteriores). |

### 4.3 Relacionamento entre skills

O relacionamento segue estritamente o fluxo em cascata das camadas (0 → 9), com um desvio permitido: qualquer skill de qualquer camada pode consultar (somente leitura) a camada `10-conhecimento-produto` a qualquer momento, sem precisar declarar isso como dependência sequencial — é conhecimento de referência, não um passo do pipeline.

### 4.4 Fluxo de execução recomendado

```
analise-negocio ──┐
                   ├──► rastreador-dependencias-configuracao ──┐
analise-tecnica-multi-repo ──┘                                  │
                                                                  ▼
                                                         planejar-testes (orq.)
                                                         ├─ gerar-mapa-testes
                                                         └─ estrategia-cobertura-multibanco
                                                                  │
                                                                  ▼
                                                    preparador-massa-dados
                                                                  │
                                              ┌───────────────────┼───────────────────┐
                                              ▼                   ▼                   ▼
                                    executor-teste-bpm  executor-teste-ecm  validador-oracle-sqlserver
                                              │                   │                   │
                                              └───────────────────┴───────────────────┘
                                                                  ▼
                                                          analise-falha
                                                                  │
                                                          (veredito SIM)
                                                                  ▼
                                                           gerar-defeito
                                                                  │
                              ┌───────────────────────────────────┴─────────────────────┐
                              ▼                                                          ▼
                analisador-impacto-multirepo (orq.)                        priorizar-automacao
                verificador-config-compartilhada
                              │
                              ▼
                    homologar-release (orq. master)
                              │
                              ▼
                atualizar-documentacao-multirrepo

(camada 90-meta-qa roda em paralelo/periodicamente sobre toda a biblioteca, não é um passo do fluxo de uma execução)
```

---

## 5. Mapa de Dependências

| Skill | Depende de (contrato de entrada) | É consumida por |
|---|---|---|
| `kb-bpm` / `kb-ecm` | — (fonte primária, mantida por processo editorial) | Todas as skills de 20 a 70 (consulta, não dependência sequencial) |
| `catalogo-configuracoes-dependencias` | — (mantido junto ao time de dev do produto) | `rastreador-dependencias-configuracao`, `gerar-mapa-testes`, `verificador-config-compartilhada` |
| `catalogo-repositorios` | — | `analise-tecnica-multi-repo`, `analisador-impacto-multirepo` |
| `analise-negocio` | User Story / item de trabalho | `rastreador-dependencias-configuracao`, `gerar-mapa-testes`, `analise-falha` |
| `analise-tecnica-multi-repo` | Card de análise técnica + N PRs/repositórios (`catalogo-repositorios`) | `rastreador-dependencias-configuracao`, `gerar-mapa-testes`, `analise-falha`, `analisador-impacto-multirepo` |
| `rastreador-dependencias-configuracao` | Saída de `analise-negocio` + `analise-tecnica-multi-repo` + `catalogo-configuracoes-dependencias` | `planejar-testes`, `executor-teste-*`, `verificador-config-compartilhada` |
| `planejar-testes` (orq.) | `analise-negocio`, `analise-tecnica-multi-repo`, `rastreador-dependencias-configuracao` | `homologar-release` |
| `gerar-mapa-testes` | Saída de `planejar-testes` (contexto consolidado) | `executor-teste-*`, `priorizar-automacao` |
| `estrategia-cobertura-multibanco` | Saída de `gerar-mapa-testes` (cenários que tocam persistência) | `validador-oracle-sqlserver` |
| `preparador-massa-dados` | Saída de `rastreador-dependencias-configuracao` (pré-requisitos a criar) | `executor-teste-bpm`, `executor-teste-ecm`, `validador-oracle-sqlserver` |
| `executor-teste-bpm` / `executor-teste-ecm` | Mapa de testes + massa de dados + `kb-bpm`/`kb-ecm` | `analise-falha`, `analisador-impacto-multirepo` |
| `validador-oracle-sqlserver` | `estrategia-cobertura-multibanco` + massa de dados | `analise-falha`, `homologar-release` |
| `analise-falha` | Resultado de execução + `analise-negocio` + `analise-tecnica-multi-repo` (opcional) | `gerar-defeito` |
| `gerar-defeito` | Veredito `SIM` de `analise-falha` | `priorizar-automacao`, `homologar-release` (contagem) |
| `analisador-impacto-multirepo` (orq.) | `analise-tecnica-multi-repo` de N histórias da release | `homologar-release` |
| `verificador-config-compartilhada` | `catalogo-configuracoes-dependencias` + `rastreador-dependencias-configuracao` de N histórias | `homologar-release` |
| `homologar-release` (orq. master) | `analisador-impacto-multirepo`, `verificador-config-compartilhada`, `executor-teste-*`, `validador-oracle-sqlserver`, `analise-falha` | `atualizar-documentacao-multirrepo` (gatilho) |
| `atualizar-documentacao-multirrepo` | Release homologada + `kb-bpm`/`kb-ecm` | — (fim de fluxo) |
| `priorizar-automacao` | `gerar-mapa-testes` executado + histórico de execução | — (fim de fluxo, alimenta backlog de automação) |
| `auditor-consistencia-skills`, `validador-qualidade-saida`, `consolidador-metricas`, `regressao-skills` | Todas as skills acima (leitura de artefatos/log) | Time de QA / dono da biblioteca (não integra o pipeline de execução) |

---

## 6. Catálogo de Skills

> Convenção de leitura: **Criticidade** reflete o impacto de a skill *não existir* ou falhar silenciosamente, não a frequência de uso.

### 6.1 Camada Core (00)

#### `contrato-dados-entre-skills`
- **Objetivo:** definir e manter o dicionário único de campos fixos trocados entre skills (Origem, Cenário de origem, Repositório de origem, SGBD, Pré-requisito de configuração etc.), evitando divergência de nomenclatura como a já encontrada entre `priorizar-automacao.md` e `gerar-mapa-testes-v3.md`.
- **Entradas:** proposta de novo campo por qualquer skill.
- **Saídas:** dicionário de campos versionado, com nome canônico e skills que o consomem.
- **Dependências:** nenhuma.
- **Quando utilizar:** antes de criar ou alterar qualquer skill que produza ou consuma dado estruturado de outra.
- **Criticidade:** Alta.
- **Justificativa:** é o mecanismo que impede a causa raiz de inconsistência já observada na auditoria; sem ele, cada skill nova reintroduz risco de divergência.

#### `log-governanca`
- **Objetivo:** consolidar o padrão de log de auditoria (`LOG-ACOES.md`) já usado por 5 das 9 skills atuais, formalizando estrutura mínima obrigatória.
- **Entradas:** evento de qualquer skill executora (execução, criação de defeito, publicação).
- **Saídas:** entrada de log padronizada.
- **Dependências:** nenhuma.
- **Quando utilizar:** toda skill de camada 20 em diante deve escrever aqui ao concluir.
- **Criticidade:** Alta.
- **Justificativa:** já é o ativo mais reaproveitável identificado na auditoria; é a base de toda a estratégia de observabilidade (seção 9).

#### `formatos-padrao-saida`
- **Objetivo:** manter os templates de relatório fixo (estrutura de seções, não conteúdo) usados por cada categoria de skill.
- **Entradas:** tipo de skill (análise, execução, diagnóstico etc.).
- **Saídas:** template de referência.
- **Dependências:** nenhuma.
- **Quando utilizar:** ao criar nova skill ou nova versão de uma existente.
- **Criticidade:** Média.
- **Justificativa:** reduz variância de formato entre skills da mesma categoria, facilitando parsing e auditoria cruzada.

#### `principios-nao-suposicao`
- **Objetivo:** documentar formalmente a regra "nunca supor, registrar Informação não encontrada", hoje repetida textualmente em pelo menos 3 das 9 skills de forma redundante.
- **Entradas:** nenhuma (documento de referência).
- **Saídas:** texto canônico a ser referenciado (não copiado) por todas as skills.
- **Dependências:** nenhuma.
- **Quando utilizar:** referência obrigatória em toda skill de análise/diagnóstico.
- **Criticidade:** Média.
- **Justificativa:** elimina duplicação textual entre skills (reduz tamanho individual, ver 3.3) sem perder a regra.

### 6.2 Camada Conhecimento de Produto (10)

#### `kb-bpm`
- **Objetivo:** indexar conhecimento funcional de BPM (tipos de fluxo, estados de processo, regras de transição, papéis envolvidos), no mesmo padrão de KB indexada já usado para Cobrança/Portaria em `executar-teste.md`.
- **Entradas:** documentação funcional de BPM do produto (a levantar).
- **Saídas:** índice consultável por palavra-chave.
- **Dependências:** nenhuma.
- **Quando utilizar:** consultada por qualquer skill de análise, planejamento ou execução que toque um fluxo de processo.
- **Criticidade:** Alta.
- **Justificativa:** gap total hoje — nenhuma das 9 skills tem qualquer noção de BPM como conceito.

#### `kb-ecm`
- **Objetivo:** indexar conhecimento funcional de ECM (tipos de documento, tipos de índice, metadados, regras de publicação/versionamento).
- **Entradas:** documentação funcional de ECM do produto (a levantar).
- **Saídas:** índice consultável por palavra-chave.
- **Dependências:** nenhuma.
- **Quando utilizar:** consultada por qualquer skill que toque publicação/gestão documental.
- **Criticidade:** Alta.
- **Justificativa:** gap total hoje — nenhuma das 9 skills tem qualquer noção de ECM/publicação de documento.

#### `catalogo-repositorios`
- **Objetivo:** manter o mapa de quais dos ~7 repositórios existem, o que cada um contém (backend/frontend/módulo específico) e como eles se referenciam entre si.
- **Entradas:** estrutura declarada de repositórios do produto.
- **Saídas:** tabela repositório → responsabilidade → dependências conhecidas com outros repositórios.
- **Dependências:** nenhuma.
- **Quando utilizar:** toda vez que uma análise técnica precisar decidir quais repositórios consultar para uma mudança.
- **Criticidade:** Alta.
- **Justificativa:** é o insumo que resolve diretamente a limitação central de `analise-tecnica.md` (hoje lê "um" PR, singular) identificada na auditoria.

#### `catalogo-configuracoes-dependencias`
- **Objetivo:** manter o grafo de dependências de configuração do produto — para cada funcionalidade configurável, qual é a cadeia de pré-requisitos (o exemplo do enunciado: publicar documento requer Tipo de Documento → Tipo de Índice → Perfil → Usuário → Permissões).
- **Entradas:** levantamento junto ao time de desenvolvimento/produto (não documentado em nenhuma fonte hoje, precisa ser criado).
- **Saídas:** grafo de dependências consultável por funcionalidade, com indicação de qual cadastro é pré-requisito de qual.
- **Dependências:** nenhuma.
- **Quando utilizar:** consultado por `rastreador-dependencias-configuracao`, `gerar-mapa-testes` e `verificador-config-compartilhada`.
- **Criticidade:** Alta.
- **Justificativa:** é a fonte de verdade que resolve a lacuna mais citada no enunciado do produto e confirmada como ausente nas duas análises anteriores.

### 6.3 Camada Análise (20)

#### `analise-negocio` *(herdada, adaptação pequena)*
- **Objetivo:** extrair objetivo, regras, ambiguidades e dependências de negócio de uma história/item de trabalho — mantendo o mecanismo já validado de `analise-negocio.md`.
- **Entradas:** item de trabalho (história/card).
- **Saídas:** relatório estruturado de regras, comportamentos esperados e dependências declaradas.
- **Dependências:** nenhuma skill (fonte primária é o sistema de gestão de trabalho).
- **Quando utilizar:** início de toda análise de uma nova história.
- **Criticidade:** Alta.
- **Justificativa:** classificada como "reutilizável com adaptações significativas" na auditoria — a única mudança necessária é adicionar um item explícito de "dependência de configuração" distinto de "dependência de sistema/integração", conforme já recomendado.

#### `analise-tecnica-multi-repo` *(reconstrução)*
- **Objetivo:** substituir `analise-tecnica.md`, consolidando múltiplos PRs de múltiplos repositórios (via `catalogo-repositorios`) vinculados à mesma história, mantendo a disciplina já validada de "discrepância dev vs. PR" e "risco dentro/fora do escopo".
- **Entradas:** card de análise técnica + lista de PRs/repositórios vinculados.
- **Saídas:** relatório por camada/componente, agora com coluna "Repositório de origem" obrigatória.
- **Dependências:** `catalogo-repositorios`.
- **Quando utilizar:** toda história com mudança técnica, antes do planejamento de testes.
- **Criticidade:** Alta.
- **Justificativa:** classificada como "Recomendada reconstrução" — o modelo single-PR está no núcleo da skill atual, incompatível com a arquitetura de ~7 repositórios do novo produto.

#### `rastreador-dependencias-configuracao` *(nova)*
- **Objetivo:** para uma história/funcionalidade, mapear a cadeia de cadastros/configurações pré-requisito necessários, cruzando com `catalogo-configuracoes-dependencias` e indicando o que já existe no ambiente de teste versus o que precisa ser criado.
- **Entradas:** saída de `analise-negocio` e `analise-tecnica-multi-repo`; `catalogo-configuracoes-dependencias`.
- **Saídas:** lista ordenada de pré-requisitos, com status (existe/precisa criar) por ambiente.
- **Dependências:** `analise-negocio`, `analise-tecnica-multi-repo`, `catalogo-configuracoes-dependencias`.
- **Quando utilizar:** entre a análise e o planejamento de testes, sempre que a funcionalidade tocada for configurável.
- **Criticidade:** Alta.
- **Justificativa:** recomendação central e nova das duas análises anteriores — sem esta skill, o padrão de dependência em cadeia do produto não é rastreado por nenhum mecanismo, gerando risco sistemático de `NAO EXECUTADO — dado ausente` em produção, não em teste.

### 6.4 Camada Planejamento (30)

#### `planejar-testes` *(orquestradora)*
- **Objetivo:** consolidar as saídas de `analise-negocio`, `analise-tecnica-multi-repo` e `rastreador-dependencias-configuracao` num contexto único para geração do mapa de testes, decidindo se a base de insumo está completa o suficiente para prosseguir.
- **Entradas:** relatórios das três skills de análise.
- **Saídas:** pacote de contexto consolidado + sinalização de insumo incompleto (gate localizado, não global — herdando o padrão de `homologar-release.md`).
- **Dependências:** `analise-negocio`, `analise-tecnica-multi-repo`, `rastreador-dependencias-configuracao`.
- **Quando utilizar:** sempre antes de `gerar-mapa-testes`.
- **Criticidade:** Alta.
- **Justificativa:** critério de orquestradora atendido (3+ skills atômicas consolidadas) — evita que `gerar-mapa-testes` precise conhecer os detalhes de três fontes diferentes.

#### `gerar-mapa-testes` *(herdada, adaptação significativa)*
- **Objetivo:** gerar o mapa de cenários de teste a partir do contexto consolidado, preservando o checklist obrigatório de dimensões já validado em `gerar-mapa-testes-v3.md`, estendido com as dimensões "Configuração/Pré-requisito", "SGBD" e "Fluxo BPM/Transição de Estado".
- **Entradas:** saída de `planejar-testes`.
- **Saídas:** mapa de cenários com colunas: Origem, Categoria, Pré-requisito de configuração, SGBD aplicável, Cenário.
- **Dependências:** `planejar-testes`.
- **Quando utilizar:** toda história/funcionalidade antes da execução.
- **Criticidade:** Alta.
- **Justificativa:** classificada como "reutilizável com adaptações significativas" — a espinha dorsal (checklist + rastreabilidade estrita) é sólida; as três dimensões novas resolvem exatamente os três gaps centrais.

#### `estrategia-cobertura-multibanco` *(nova)*
- **Objetivo:** para cada cenário do mapa de testes que envolve persistência/consulta, decidir se a validação precisa rodar em Oracle, SQL Server, ou ambos, e com qual critério de equivalência.
- **Entradas:** mapa de testes gerado.
- **Saídas:** anotação por cenário: SGBD(s) obrigatório(s) + critério de equivalência esperado (ex.: "mensagem de erro pode diferir textualmente entre SGBDs, comportamento de negócio deve ser idêntico").
- **Dependências:** `gerar-mapa-testes`.
- **Quando utilizar:** todo cenário marcado com categoria de dados/persistência.
- **Criticidade:** Alta.
- **Justificativa:** resolve diretamente o risco de falso negativo já identificado na análise de riscos (mensagem de erro divergente entre SGBDs sendo tratada como falha real).

### 6.5 Camada Execução (40)

#### `preparador-massa-dados` *(nova)*
- **Objetivo:** a partir da lista de pré-requisitos de `rastreador-dependencias-configuracao`, criar de fato (ou confirmar existência de) a massa de dados de configuração necessária no ambiente de teste, antes da execução.
- **Entradas:** lista de pré-requisitos com status "precisa criar".
- **Saídas:** confirmação de massa de dados pronta, ou bloqueio explícito do que não pôde ser criado (e por quê).
- **Dependências:** `rastreador-dependencias-configuracao`.
- **Quando utilizar:** imediatamente antes de qualquer execução de teste.
- **Criticidade:** Alta.
- **Justificativa:** equivalente funcional à seção "Preparação de dados CNAB" de `executar-teste.md`, generalizada para o padrão de configuração do BPM/ECM — sem ela, `executor-teste-*` herdaria o mesmo acoplamento de domínio que motivou a reconstrução.

#### `executor-teste-bpm` *(reconstrução, especialização de domínio)*
- **Objetivo:** executar cenários de fluxo BPM via automação de UI (ou equivalente), comparando esperado vs. obtido, reaproveitando o esqueleto técnico validado de `executar-teste.md` (login, ação, snapshot, evidência de rede, double-check independente).
- **Entradas:** mapa de testes (cenários de categoria BPM) + massa de dados preparada + `kb-bpm`.
- **Saídas:** relatório por cenário (Passou/Falhou/Não executado) com evidência.
- **Dependências:** `gerar-mapa-testes`, `preparador-massa-dados`, `kb-bpm`.
- **Quando utilizar:** execução de cenários de workflow/processo.
- **Criticidade:** Alta.
- **Justificativa:** o núcleo técnico de `executar-teste.md` (guardrails de evidência, double-check) é maduro e deve ser preservado; o conteúdo de domínio (Cobrança/CNAB) é 100% descartado e substituído por `kb-bpm`, exatamente como recomendado na auditoria.

#### `executor-teste-ecm` *(reconstrução, especialização de domínio)*
- **Objetivo:** equivalente a `executor-teste-bpm`, mas para cenários de publicação/gestão documental (tipo de documento, tipo de índice, versionamento, permissão de publicação).
- **Entradas:** mapa de testes (cenários de categoria ECM) + massa de dados preparada + `kb-ecm`.
- **Saídas:** relatório por cenário, mesmo formato de `executor-teste-bpm`.
- **Dependências:** `gerar-mapa-testes`, `preparador-massa-dados`, `kb-ecm`.
- **Quando utilizar:** execução de cenários de publicação/gestão documental.
- **Criticidade:** Alta.
- **Justificativa:** mesma lógica de `executor-teste-bpm` — separação por subdomínio evita que uma única skill de execução cresça além do limiar de tamanho seguro (3.3) ao acumular conhecimento de dois domínios funcionalmente distintos.

#### `validador-oracle-sqlserver` *(nova)*
- **Objetivo:** para cenários anotados por `estrategia-cobertura-multibanco`, executar (ou validar) a mesma verificação em Oracle e em SQL Server separadamente, nunca consolidando resultado único.
- **Entradas:** anotação de SGBD obrigatório por cenário + massa de dados.
- **Saídas:** relatório por cenário **por banco**, nunca agregado (Passou-Oracle / Passou-SQLServer podem divergir e ambos aparecem).
- **Dependências:** `estrategia-cobertura-multibanco`, `preparador-massa-dados`.
- **Quando utilizar:** todo cenário que envolve leitura/escrita de dado persistido.
- **Criticidade:** Alta.
- **Justificativa:** gap de cobertura "certo, dado o estado atual (0% de cobertura)" segundo a análise de riscos — é a skill que resolve isso de forma estrutural, não pontual.

### 6.6 Camada Diagnóstico (50)

#### `analise-falha` *(herdada, adaptação pequena)*
- **Objetivo:** investigar causa provável de uma falha de teste e decidir se há evidência suficiente para abrir defeito — preservando o raciocínio já validado (agnóstico de domínio) de `analise-falha.md`.
- **Entradas:** resultado de execução (`executor-teste-*` ou `validador-oracle-sqlserver`) + relatórios de análise disponíveis.
- **Saídas:** veredito SIM/NÃO + classificação de causa, agora incluindo a categoria nova "Configuração/pré-requisito ausente" (distinta de funcional/técnica).
- **Dependências:** saída de qualquer skill de execução; opcionalmente `analise-tecnica-multi-repo`.
- **Quando utilizar:** toda vez que um cenário for marcado como Falhou.
- **Criticidade:** Alta.
- **Justificativa:** classificada como "reutilizável com pequenas adaptações" — a única mudança estrutural é a nova categoria de causa, que evita classificar erroneamente uma falha de preparação de ambiente como bug de aplicação (risco explícito já identificado).

#### `gerar-defeito` *(herdada, adaptação pequena)*
- **Objetivo:** estruturar e registrar um defeito a partir de um veredito SIM de `analise-falha`, com aprovação humana obrigatória — preservando o mecanismo já validado.
- **Entradas:** veredito SIM + evidência de `analise-falha`.
- **Saídas:** defeito registrado no sistema de gestão de trabalho, vinculado ao cenário de origem.
- **Dependências:** `analise-falha` (veredito SIM).
- **Quando utilizar:** após veredito SIM.
- **Criticidade:** Alta.
- **Justificativa:** classificada como "reutilizável com pequenas adaptações" — ajustes são de configuração pontual (nome de campo de template, organização), não estruturais; adicionar campo "Repositório/Subproduto de origem" dado o contexto multi-repo.

### 6.7 Camada Release (60)

#### `analisador-impacto-multirepo` *(orquestradora, nova)*
- **Objetivo:** consolidar o impacto técnico de N históricas de uma release através de múltiplos repositórios, identificando sobreposição de componentes tocados entre histórias diferentes (regressão cross-repo).
- **Entradas:** saída de `analise-tecnica-multi-repo` de todas as histórias da release.
- **Saídas:** mapa consolidado de componentes/repositórios tocados, com sinalização de sobreposição entre histórias.
- **Dependências:** `analise-tecnica-multi-repo` (N instâncias).
- **Quando utilizar:** antes da homologação de uma release com múltiplas histórias.
- **Criticidade:** Alta.
- **Justificativa:** resolve o risco "regressão cross-repo não detectada", classificado como probabilidade alta em arquitetura multi-repo sem skill dedicada — nenhuma das 9 skills atuais audita "quem mais usa este componente" além do escopo de uma história isolada.

#### `verificador-config-compartilhada` *(nova)*
- **Objetivo:** antes de uma release, identificar se alguma configuração alterada por qualquer história é compartilhada entre subprodutos (BPM consome uma configuração que ECM também usa, por exemplo), sinalizando risco de efeito colateral cruzado.
- **Entradas:** `catalogo-configuracoes-dependencias` + saída de `rastreador-dependencias-configuracao` de todas as histórias da release.
- **Saídas:** lista de subprodutos potencialmente afetados por configuração compartilhada alterada.
- **Dependências:** `catalogo-configuracoes-dependencias`, `rastreador-dependencias-configuracao`.
- **Quando utilizar:** antes da homologação de release.
- **Criticidade:** Média.
- **Justificativa:** gap identificado nas duas análises anteriores — "configurações compartilhadas entre sistemas" citado no enunciado do produto como característica central, sem mecanismo de verificação em nenhuma das 9 skills.

#### `homologar-release` *(orquestradora master, herdada, adaptação significativa)*
- **Objetivo:** consolidar impacto, execução, validação multi-banco e análise de falha em uma recomendação de release (Aprovada/Aprovada com ressalvas/Reprovada), preservando a governança "Guardrail vs. Gates" já validada.
- **Entradas:** `analisador-impacto-multirepo`, `verificador-config-compartilhada`, `executor-teste-bpm`/`executor-teste-ecm`, `validador-oracle-sqlserver`, `analise-falha`.
- **Saídas:** recomendação estruturada com critério explícito, incluindo agora uma dimensão obrigatória "Cobertura Oracle x SQL Server: completa/parcial/não aplicável" por história (parcial vira ressalva obrigatória).
- **Dependências:** todas as skills de camada 40, 50 e as duas skills de 60 acima.
- **Quando utilizar:** decisão final de liberação de release.
- **Criticidade:** Alta.
- **Justificativa:** camada de orquestração e governança já madura em `homologar-release.md`; a cobertura real depende inteiramente das skills de insumo terem sido reconstruídas primeiro (é por isso que esta arquitetura reconstrói as camadas 20-50 antes de adaptar esta).

### 6.8 Camada Documentação (70)

#### `atualizar-documentacao-multirrepo` *(herdada, adaptação pequena)*
- **Objetivo:** identificar páginas de documentação impactadas por uma release validada, agora considerando que documentação pode estar distribuída entre wikis de múltiplos repositórios/subprodutos, sem perder rastreio de que é a mesma mudança de origem.
- **Entradas:** release homologada + `kb-bpm`/`kb-ecm`.
- **Saídas:** proposta de atualização por página, com aprovação individual obrigatória (preservado de `atualizar-documentacao.md`).
- **Dependências:** `homologar-release` (gatilho).
- **Quando utilizar:** após homologação de release com impacto documental.
- **Criticidade:** Média.
- **Justificativa:** classificada como "reutilizável com pequenas adaptações" — a única lacuna real é orquestração entre múltiplas wikis, resolvida como extensão de fluxo, não reconstrução.

### 6.9 Camada Automação (80)

#### `priorizar-automacao` *(herdada, adaptação significativa)*
- **Objetivo:** classificar cenários executados manualmente em alta/média/baixa prioridade de automação e promover os de alta prioridade para a suíte de regressão, preservando o framework de decisão já validado (criticidade, frequência, estabilidade, custo manual, risco de regressão).
- **Entradas:** histórico de execução de `executor-teste-bpm`/`executor-teste-ecm`/`validador-oracle-sqlserver`.
- **Saídas:** lista de cenários promovidos + gap de automação identificado.
- **Dependências:** histórico de execução.
- **Quando utilizar:** periodicamente, após acumular execuções suficientes.
- **Criticidade:** Média.
- **Justificativa:** classificada como "reutilizável com adaptações significativas" — framework de priorização é genérico e sólido; camada de execução (caminhos hardcoded, nome de planilha, framework assumido) precisa de generalização e resolução da divergência de nomenclatura já identificada com `gerar-mapa-testes-v3.md` (resolvida estruturalmente aqui via `contrato-dados-entre-skills`).

### 6.10 Camada Meta-QA (90)

#### `auditor-consistencia-skills` *(nova)*
- **Objetivo:** revisão periódica (não por execução individual) comparando terminologia, nomes de campo e formato entre todas as skills da biblioteca, capturando divergências como a já encontrada entre `priorizar-automacao.md` e `gerar-mapa-testes-v3.md` antes que virem confusão em produção.
- **Entradas:** biblioteca completa de skills + `contrato-dados-entre-skills`.
- **Saídas:** relatório de divergências encontradas, com recomendação de correção.
- **Dependências:** `contrato-dados-entre-skills`.
- **Quando utilizar:** a cada mudança de versão de qualquer skill, e periodicamente (ex.: mensal).
- **Criticidade:** Média.
- **Justificativa:** recomendação explícita da análise de riscos (seção 4) — mecanismo que não existia em nenhuma forma até a auditoria manual que gerou os dois documentos anteriores.

#### `validador-qualidade-saida` *(nova, LLM-as-judge)*
- **Objetivo:** avaliar, por amostragem, se a saída de uma execução de skill aderiu ao checklist/regras esperados, usando um segundo modelo (ou o mesmo modelo em chamada isolada, sem herdar raciocínio) — generalizando o padrão já validado de double-check independente de `executar-teste.md`.
- **Entradas:** amostra de execuções reais + checklist da skill avaliada.
- **Saídas:** veredito estruturado de aderência por execução amostrada, com apontamento de regra não seguida.
- **Dependências:** nenhuma skill específica (consome saída de qualquer uma).
- **Quando utilizar:** amostragem periódica, com foco nos pontos identificados como frágeis (evidência de rede, comparação de mensagem de erro entre SGBDs, cenários `HIPOTESE:`).
- **Criticidade:** Média.
- **Justificativa:** prática de mercado citada explicitamente na análise de riscos (seção 6) como ausente hoje; generaliza o único mecanismo de verificação cruzada já existente (double-check em `executar-teste.md`) para toda a biblioteca.

#### `consolidador-metricas` *(nova)*
- **Objetivo:** agregar o `log-governanca` em indicadores objetivos (cobertura funcional, cobertura de dependências, cobertura Oracle x SQL Server, taxa de defeitos escapados, reabertura de bugs, efetividade dos testes).
- **Entradas:** `log-governanca` acumulado.
- **Saídas:** painel/relatório periódico de indicadores.
- **Dependências:** `log-governanca`.
- **Quando utilizar:** periodicamente (ex.: por release ou mensal).
- **Criticidade:** Média.
- **Justificativa:** a análise de riscos já identifica que boa parte do insumo bruto existe (log de ações), faltando apenas o passo de consolidação — maior ganho de curto prazo com menor esforço de instrumentação nova.

#### `regressao-skills` *(nova)*
- **Objetivo:** manter um conjunto de casos de referência (histórias/PRs/cenários reais já resolvidos manualmente, com gabarito conhecido) e rodar as skills periodicamente contra eles a cada mudança de versão, sinalizando divergência inesperada.
- **Entradas:** conjunto de casos de referência versionado + nova versão de uma skill.
- **Saídas:** relatório de divergência (o que passou a se comportar diferente do gabarito).
- **Dependências:** nenhuma skill específica (framework de teste da biblioteca).
- **Quando utilizar:** a cada alteração de versão de qualquer skill antes de publicá-la.
- **Criticidade:** Alta (para a saúde de longo prazo da biblioteca, mesmo não sendo usada por execução).
- **Justificativa:** recomendação central de mercado citada na análise de riscos — equivalente a teste de regressão de software aplicado a artefato de linguagem natural; hoje o único "aprendizado" observado é reativo (troubleshooting pós-incidente em `executar-teste.md`), nunca preventivo.

---

## 7. Fluxos Orquestrados

### 7.1 `planejar-testes`
- **Responsabilidades:** decidir se a base de análise (negócio + técnica + dependências de configuração) está completa o suficiente para gerar um mapa de testes confiável; sinalizar gate localizado quando um insumo estiver ausente, sem travar toda a história.
- **Entradas:** relatórios de `analise-negocio`, `analise-tecnica-multi-repo`, `rastreador-dependencias-configuracao`.
- **Saídas:** contexto consolidado + lista de lacunas de insumo (se houver).
- **Skills consumidas:** as três skills de camada 20.

### 7.2 `analisador-impacto-multirepo`
- **Responsabilidades:** consolidar múltiplas análises técnicas de uma release, identificando sobreposição de componente/configuração entre histórias diferentes — a peça que hoje falta para detectar regressão cross-repo.
- **Entradas:** N relatórios de `analise-tecnica-multi-repo` (um por história da release).
- **Saídas:** mapa de sobreposição + lista de componentes de alto risco por serem tocados por mais de uma história.
- **Skills consumidas:** `analise-tecnica-multi-repo` (N instâncias), `catalogo-repositorios`.

### 7.3 `homologar-release` (master)
- **Responsabilidades:** aplicar o critério "Guardrail vs. Gates" já validado — gates técnicos (execução, cobertura multi-banco) podem endurecer com o tempo, mas a decisão final de produção é sempre humana. Consolida também a nova dimensão obrigatória de cobertura Oracle x SQL Server.
- **Entradas:** saídas de `analisador-impacto-multirepo`, `verificador-config-compartilhada`, `executor-teste-bpm`, `executor-teste-ecm`, `validador-oracle-sqlserver`, `analise-falha` (de todas as histórias/cenários da release).
- **Saídas:** recomendação Aprovada / Aprovada com ressalvas / Reprovada, com critério determinístico documentado.
- **Skills consumidas:** todas as listadas acima.

### 7.4 Estratégia de cobertura (transversal, não é uma única skill)

A "estratégia de cobertura" não é modelada como uma skill própria, mas como uma responsabilidade distribuída entre `gerar-mapa-testes` (garante checklist obrigatório de dimensões), `estrategia-cobertura-multibanco` (garante dimensão de SGBD) e `consolidador-metricas` (mede se a cobertura declarada de fato ocorreu). Modelar como skill única concentraria responsabilidade de forma incompatível com P1/P2.

---

## 8. Estratégia Oracle x SQL Server

| Necessidade do enunciado | Mecanismo desta arquitetura |
|---|---|
| **Execução em Oracle** | `validador-oracle-sqlserver` executa a verificação de persistência isoladamente contra o ambiente Oracle, usando acesso de leitura dedicado (equivalente ao padrão já validado `mysql-cobranca-hmg`, mas para Oracle — "leitura permitida, escrita nunca"). |
| **Execução em SQL Server** | Mesma skill, mesmo mecanismo, contra o ambiente SQL Server — nunca a mesma chamada; são duas execuções sempre distintas e sempre ambas registradas. |
| **Comparação de comportamentos** | `estrategia-cobertura-multibanco` define, por cenário, qual é o critério de equivalência esperado *antes* da execução (ex.: "mensagem de erro pode divergir textualmente, comportamento de negócio deve ser idêntico") — decisão tomada com contexto de negócio, não inferida ad hoc no momento da comparação. |
| **Identificação de diferenças** | `validador-oracle-sqlserver` nunca consolida um veredito único; todo resultado é relatado por banco (P9). Divergência de resultado entre os dois bancos gera automaticamente um item para `analise-falha` avaliar sob a nova categoria "Configuração/pré-requisito ausente" ou causa técnica real. |
| **Rastreabilidade dos resultados** | Cada linha do relatório de `validador-oracle-sqlserver` carrega o campo fixo `SGBD` (definido em `contrato-dados-entre-skills`), consumido por `consolidador-metricas` para o indicador "Cobertura Oracle x SQL Server" e por `homologar-release` como dimensão obrigatória de decisão. |

Esta estratégia resolve diretamente o risco classificado como "certo, dado o estado atual (0% de cobertura)" pela análise de riscos anterior, e o risco de falso negativo por comparação literal de mensagem de erro entre SGBDs distintos.

---

## 9. Estratégia de Cobertura e Controle de Dependências

Dado que "muitas funcionalidades dependem de configurações prévias", o controle de dependências é tratado como um fluxo de dados explícito, não como uma responsabilidade difusa:

1. **Identificar pré-requisitos:** `rastreador-dependencias-configuracao` consulta `catalogo-configuracoes-dependencias` para toda funcionalidade tocada por uma história, produzindo a cadeia completa (não apenas o primeiro nível — o exemplo do enunciado tem 5 níveis: Tipo de Documento → Tipo de Índice → Perfil → Usuário → Permissões).
2. **Identificar dependências:** a mesma skill distingue dependência de **configuração** (cadastro que precisa existir) de dependência de **sistema/integração** (já coberta parcialmente por `analise-tecnica-multi-repo`) — são categorias diferentes, tratadas por mecanismos diferentes, nunca fundidas (evita repetir a ambiguidade já observada em `analise-negocio.md`, onde "Dependências" era um item genérico único).
3. **Mapear impacto:** `verificador-config-compartilhada` cruza a cadeia de dependências com o `catalogo-configuracoes-dependencias` para identificar se algum item da cadeia é compartilhado entre subprodutos — se uma configuração alterada por BPM também é consumida por ECM, isso vira sinalização explícita antes da release.
4. **Validar configurações obrigatórias:** `preparador-massa-dados` confirma, no ambiente de teste, que cada item da cadeia identificada por `rastreador-dependencias-configuracao` de fato existe antes de qualquer execução — bloqueando localmente (não a release inteira) o cenário específico que depende do item ausente, com causa registrada.
5. **Garantir cobertura de cenários indiretos:** `gerar-mapa-testes` inclui, na dimensão obrigatória "Pré-requisito de configuração" do checklist, um cenário de borda para cada nível ausente da cadeia (ex.: "tentar publicar documento com tipo de índice válido mas perfil sem a permissão específica") — não apenas o caminho feliz onde tudo já está configurado.

Este fluxo transforma o padrão de dependência em cadeia — hoje tratado, na melhor das hipóteses, como um item textual genérico dentro de "Dependências" — em um dado estruturado, rastreável e consultado por múltiplas skills, coerente com P8.

---

## 10. Estratégia de Qualidade das Skills (Meta-QA)

| Mecanismo | O que garante | Skill responsável |
|---|---|---|
| **Qualidade das saídas** | Amostragem periódica avalia se a saída de uma execução real aderiu ao checklist da skill, com foco nos pontos de maior risco de falso positivo/negativo já identificados (evidência de rede, comparação de erro entre SGBDs). | `validador-qualidade-saida` (LLM-as-judge) |
| **Cobertura** | Indicadores objetivos (não impressão subjetiva) cruzando critério de aceite ↔ cenário ↔ execução ↔ SGBD ↔ dependência de configuração. | `consolidador-metricas` |
| **Consistência** | Revisão periódica de terminologia/formato entre todas as skills, ancorada no dicionário único de `contrato-dados-entre-skills`. | `auditor-consistencia-skills` |
| **Regressão de prompts/skills** | Conjunto de casos de referência com gabarito conhecido, rodado a cada mudança de versão de qualquer skill. | `regressao-skills` |
| **Evolução da biblioteca** | Toda skill é versionada (o hábito de numeração "v2"/"v3" já observado em `gerar-mapa-testes-v3.md` vira prática obrigatória, não incidental), com changelog e dono nomeado — nenhuma skill é editada ad hoc sem registro. | Governança de `00-core` (processo, não uma skill de execução) |

**Cadência recomendada:** `auditor-consistencia-skills` e `regressao-skills` rodam a cada mudança de versão de qualquer skill (evento-driven); `validador-qualidade-saida` e `consolidador-metricas` rodam em cadência periódica (ex.: por release ou mensal), já que dependem de volume acumulado de execuções reais para amostragem significativa.

---

## 11. Roadmap de Implementação

### Fase 1 — Essenciais

Objetivo: fechar os três gaps estruturais mais críticos e estabelecer a fundação de contrato/conhecimento sem a qual todo o resto herda o mesmo risco de inconsistência já observado.

| Skill | Motivo de estar na Fase 1 |
|---|---|
| `contrato-dados-entre-skills` | Sem isso, toda skill nova corre o mesmo risco de divergência já confirmado entre skills existentes. |
| `catalogo-configuracoes-dependencias` | Fonte de verdade da lacuna mais citada no enunciado do produto. |
| `catalogo-repositorios` | Fonte de verdade que resolve a limitação estrutural mais crítica (single-repo). |
| `rastreador-dependencias-configuracao` | Capacidade nova mais crítica identificada nas duas análises anteriores. |
| `analise-tecnica-multi-repo` | Reconstrução obrigatória — bloqueia toda a cadeia a jusante enquanto for single-repo. |
| `gerar-mapa-testes` (com as 3 dimensões novas) | Sem as dimensões novas, o mapa de testes continua sistematicamente incompleto para o domínio. |
| `analise-negocio` (adaptação pequena) | Baixo custo, alto valor de rastreabilidade desde o início. |
| `log-governanca` | Base de toda a estratégia de observabilidade posterior; custo mínimo de implementar desde já. |

### Fase 2 — Expansão

Objetivo: cobrir execução real (BPM, ECM, multi-banco) e fechar o ciclo de diagnóstico/defeito com as adaptações necessárias.

| Skill | Motivo de estar na Fase 2 |
|---|---|
| `kb-bpm`, `kb-ecm` | Necessárias para execução real, mas dependem de levantamento de conteúdo (esforço de curadoria, não só de skill). |
| `preparador-massa-dados` | Depende de `rastreador-dependencias-configuracao` já estar validada em produção (Fase 1). |
| `executor-teste-bpm`, `executor-teste-ecm` | Reconstrução de maior esforço; depende de `kb-bpm`/`kb-ecm` e `preparador-massa-dados` prontos. |
| `estrategia-cobertura-multibanco`, `validador-oracle-sqlserver` | Fecham o gap de cobertura mais citado como "certo, dado o estado atual" pela análise de riscos. |
| `analise-falha` (nova categoria de causa) | Pequeno esforço, mas só faz sentido pleno depois que `preparador-massa-dados` existe (para a categoria "config ausente" ter sentido operacional). |
| `gerar-defeito` (campo de repositório/subproduto) | Pequeno esforço, encaixa após `analise-tecnica-multi-repo` da Fase 1. |
| `planejar-testes` (orquestradora) | Formaliza a composição das skills de análise da Fase 1, uma vez que todas já existem. |

### Fase 3 — Maturidade

Objetivo: orquestração de release completa, automação e meta-QA formal — capacidades avançadas que dependem de todo o restante já estar em operação e gerando histórico real.

| Skill | Motivo de estar na Fase 3 |
|---|---|
| `analisador-impacto-multirepo` | Precisa de histórico real de múltiplas histórias/releases para ter valor de sobreposição a detectar. |
| `verificador-config-compartilhada` | Depende de `catalogo-configuracoes-dependencias` maduro e populado com uso real. |
| `homologar-release` (adaptação com dimensão SGBD) | Depende de todas as skills de insumo (Fases 1 e 2) estarem operacionais e confiáveis. |
| `atualizar-documentacao-multirrepo` | Fluxo de saída, menor urgência relativa ao ciclo de teste em si. |
| `priorizar-automacao` (adaptação) | Só faz sentido após acumular execuções manuais suficientes para priorizar automação real. |
| `auditor-consistencia-skills`, `regressao-skills`, `validador-qualidade-saida`, `consolidador-metricas` | Meta-QA da biblioteca só tem insumo (skills, versões, execuções, log) suficiente depois que as Fases 1 e 2 estão em uso real — implementar antes seria meta-QA sem sujeito para auditar. |

---

## 12. Recomendações Finais

- **Não migrar as 9 skills existentes por cópia direta.** Sete delas são reutilizáveis com adaptações de escopo variável (pequenas a significativas); duas (`analise-tecnica.md`, `executar-teste.md`) precisam de reconstrução porque seu acoplamento está no núcleo, não em detalhe — tratar as duas categorias de forma diferente evita retrabalho.
- **Priorizar a Fase 1 mesmo sem ainda ter `kb-bpm`/`kb-ecm` prontos.** O maior risco de produção hoje não é falta de conhecimento de domínio, é ausência total de rastreamento de dependência de configuração e de suporte multi-repo — os dois gaps que, segundo a análise de riscos, têm probabilidade "alta"/"certa" e impacto "alto".
- **Resistir à tentação de consolidar skills por conveniência de manutenção.** A análise de riscos já demonstrou, com evidência concreta das próprias 9 skills atuais, que o padrão de múltiplas skills pequenas é o que funciona; o principal risco de manutenção não é ter muitas skills, é não ter um contrato de dados formal entre elas — por isso `contrato-dados-entre-skills` está na Fase 1, não como nice-to-have posterior.
- **Tratar o catálogo de dependências de configuração como ativo de produto, não de QA.** Ele deveria idealmente ser mantido em conjunto com o time de desenvolvimento (é conhecimento sobre o sistema, não sobre o processo de teste) — QA consome e valida, mas a curadoria inicial exige colaboração cross-time, o que deve ser negociado antes de comprometer o prazo da Fase 1.
- **Instrumentar meta-QA desde o primeiro dia de forma leve (log estruturado), mesmo adiando a análise formal para a Fase 3.** `log-governanca` custa pouco para implementar já na Fase 1 e é o único jeito de a Fase 3 ter dado histórico suficiente para gerar valor real quando chegar a hora.
- **Medir o sucesso da arquitetura pelos três indicadores que hoje são zero:** cobertura de dependências de configuração, cobertura Oracle x SQL Server, e cobertura de regressão cross-repo. Esses três, e não o número de skills criadas, são o critério real de que esta arquitetura resolveu o problema que a motivou.
