# Registro da consolidação das skills de geração de mapas de testes — Arquitetura

## 1. Identificação

| Campo | Registro |
|---|---|
| Data | 09/10/2026 |
| Horário | 10:28:48 |
| Fuso horário | America/Sao_Paulo — UTC-03:00 |
| Pasta do registro | `skills-qa-smartshare/arquitetura/Documentação da criação das Skills` |
| Tipo de atividade | Análise comparativa e desenho de consolidação de skills |
| Responsável pela execução | Codex |
| Status | Consolidação implementada; skill definitiva criada, validada e instalada; arquivos-fonte originais preservados |

## 2. Prompt utilizado pelo solicitante

### 2.1. Prompt para análise e consolidação

> Pegue as skills "gerar-mapa-testes-v1-arquitetura" e "gerar-mapa-testes-v3"(da pasta arquitetura), faça um comparativo entre ambas e faça um esboço de como ficariam as 2 skills juntas em uma só, dando enfase nas regras que serão destinadas ao time de arquitetura

### 2.2. Prompt para criação deste registro

> Crie um documento dentro da pasta "documentação da criação das skills", nesse documento, você deverá fazer o registro das alterações que estão sendo realizadas conforme e a criação dessa skill, detalhe o prompt usado por mim, as alterações que voce realizou, quais arquivos foram usados como informação para essas alterações, qual foi a saída disso, e tambem insira a data e hora de que isso foi feito

### 2.3. Prompt para implementação da skill definitiva

> Crie uma skill para gerar mapa de testes definitiva, mantenha o padrão e variaveis de MCP que existem na V3 e padrão utilizado por steps tbm, a organização pode continuar da mesma forma da V3, utilize pontos importantes existentes na V1 arquitetura e implemente na V3

## 3. Objetivo da atividade

Registrar a análise realizada para avaliar a união das skills `gerar-mapa-testes-v1-arquitetura` e `gerar-mapa-testes-v3`, preservando as regras técnicas destinadas ao time de arquitetura e incorporando os controles operacionais da v3.

O objetivo desta etapa foi transformar a especificação de consolidação em uma skill única e utilizável, preservando o fluxo operacional da V3 e incorporando as regras arquiteturais relevantes da V1. Não houve sobrescrita, exclusão ou alteração do conteúdo das duas skills-fonte.

## 4. Arquivos utilizados como fonte de informação

### 4.1. Skills analisadas

1. [`gerar-mapa-testes-v1-arquitetura.md`](../gerar-mapa-testes-v1-arquitetura.md)
   - Base técnica e arquitetural da análise.
   - Regras de migração do Agent legado para o Agent novo.
   - Classificação dos requisitos como `Legado`, `Novo` ou `Transversal`.
   - Regras para bancos Oracle e SQL Server.
   - Cobertura de APIs, jobs, workers, integrações, segurança, observabilidade, performance e implantação.
   - Matriz de paridade, evidências de código e comparação back-to-back.

2. [`gerar-mapa-testes-v3.md`](../gerar-mapa-testes-v3.md)
   - Fluxo operacional baseado em histórias do Azure DevOps.
   - Localização ou criação do card `Criar Mapa de Teste`.
   - Restrição das fontes formais dos cenários.
   - Checklist de dimensões positivas, negativas, permissão, dados, concorrência e regressão.
   - Escolha formal da técnica de teste por cenário.
   - Histórico de defeitos.
   - Gate de aprovação antes da publicação.
   - Publicação em HTML via MCP e tratamento de hipóteses.

### 4.2. Instrução geral utilizada como referência metodológica

3. [`qa-test-map-generator/SKILL.md`](C:/Users/guilherme.borges/.codex/skills/qa-test-map-generator/SKILL.md)
   - Rastreabilidade entre requisitos, riscos e cenários.
   - Separação entre fatos, inferências, hipóteses, ambiguidades e ausências.
   - Priorização por risco.
   - Resultados observáveis.
   - Passo a passo alternando ação do executor e resposta do sistema.
   - Controle de cobertura, riscos residuais, lacunas e automação.

4. [`outputs/qa-test-map-generator/SKILL.md`](C:/Users/guilherme.borges/Documents/Codex/2026-10-27/documents-plugin-documents-openai-primary-runtime/outputs/qa-test-map-generator/SKILL.md)
   - Arquivo resultante da consolidação implementada.
   - Usado como fonte de conferência da versão final instalada.

## 5. Alterações e decisões realizadas

### 5.1. Decisão principal de arquitetura da solução

A v1 foi definida como núcleo normativo da skill consolidada, porque contém as regras específicas do domínio de arquitetura. A v3 foi mantida como estrutura operacional principal, com as etapas, variáveis, MCPs, aprovação e publicação preservadas.

O desenho resultante separa dois conceitos:

- **Motor de análise:** identifica requisitos, riscos, evidências, estados, integrações e cenários.
- **Adaptador de publicação:** transforma o resultado em Markdown ou HTML e, quando solicitado, publica no Azure DevOps.

O resultado efetivo é uma skill única orientada ao Azure DevOps, sem perder a separação conceitual entre análise arquitetural e publicação. O conhecimento arquitetural passou a orientar a geração dos cenários, enquanto a publicação continua limitada ao adaptador MCP definido pela V3.

### 5.2. Regras arquiteturais preservadas da v1

Foram mantidas como regras obrigatórias para o time de arquitetura:

- classificar cada requisito como `Legado`, `Novo` ou `Transversal`;
- aplicar paridade somente aos requisitos de origem `Legado`;
- exigir evidência do comportamento em formato `arquivo:símbolo`, configuração, tabela, endpoint, log ou equivalente;
- considerar Oracle e SQL Server quando a demanda tocar persistência, SQL, repositório, job ou relatório;
- avaliar agendamento, misfire, sobreposição, concorrência, lock, lease, reprocessamento e idempotência;
- avaliar contratos de API, autenticação, timeout, retentativa, backoff, assincronia e compatibilidade;
- avaliar configuração, startup, restart, implantação, coexistência e rollback;
- avaliar observabilidade, logs, health checks, correlação e ausência de dados sensíveis;
- exigir matriz de paridade e evidências do legado e do novo quando aplicável;
- registrar lacunas, hipóteses e riscos residuais sem convertê-los automaticamente em fatos.

### 5.3. Regras incorporadas da v3

Foram incorporadas ao desenho consolidado:

- uso de fontes formais para justificar cada cenário;
- identificação explícita de regras condicionais;
- checklist de dimensões positivas, negativas, permissão, dados, concorrência e regressão;
- seleção formal da técnica de teste por cenário;
- categoria de regressão alimentada por pontos de impacto e histórico de defeitos;
- busca de defeitos históricos relevantes;
- aprovação explícita antes de criar ou atualizar um card;
- proteção contra sobrescrita silenciosa de um mapa existente;
- manutenção de hipóteses dentro do mapa, com notificação separada na história;
- Markdown como representação de análise e HTML como representação de publicação;
- publicação somente no card `Criar Mapa de Teste`, sem alteração automática de estado ou responsável.

### 5.4. Regra de reconciliação entre as duas skills

A v3 determina que a narrativa técnica, sozinha, não crie novos cenários. Essa regra foi preservada, mas adaptada para arquitetura:

> Código, configuração, logs, diagramas e contratos podem fornecer evidência e detalhar a execução. Eles só devem gerar um novo cenário quando estiverem vinculados a requisito, risco arquitetural, defeito, contrato, decisão arquitetural ou comportamento legado explicitamente identificado.

Assim, evita-se tanto a criação de cenários fora do escopo quanto a perda de riscos técnicos documentados.

### 5.5. Implementação efetivamente realizada

Foi criada uma nova versão do arquivo `qa-test-map-generator/SKILL.md` com frontmatter válido e a seguinte consolidação:

- manutenção do nome da skill `qa-test-map-generator`, permitindo atualização da skill já existente;
- descrição atualizada para indicar geração de mapas a partir de histórias do Azure DevOps, uso exclusivo de MCP e cobertura arquitetural;
- preservação dos nomes e da finalidade das variáveis da V3: `$ARGUMENTS`, `$WI_ID`, `$STORY_TITLE`, `$STORY_DESC`, `$STORY_AC`, `$STORY_RELATIONS`, `$STORY_AREA_PATH`, `$STORY_ITERATION_PATH`, `$STORY_PROJECT`, `$CARD_EXISTS`, `$MAPA_CARD_ID`, `$MAPA_CARD_STATE`, `$MAPA_CARD_DESC`, `$MAPA_CARD_HAS_CONTENT`, `$ANALISE_PONTOS`, `$ANALISE_CASOS`, `$DEFECT_HISTORY` e `$WORK_DIR`;
- preservação da sequência operacional Step 0 a Step 9;
- preservação dos MCPs `get_work_item`, `get_work_items_batch_by_ids`, `search_work_items`, `create_work_item` e `update_work_item`;
- inclusão de classificação `Legado`, `Novo` e `Transversal`;
- inclusão de evidência `arquivo:símbolo`, matriz de paridade, comparação back-to-back e requisito de localizar o legado quando a demanda exigir paridade;
- inclusão de checklist arquitetural para APIs, jobs, schedulers, banco dual, configuração, segurança, integrações, observabilidade, performance, resiliência, implantação e coexistência;
- inclusão do padrão de passos alternados por ator real, com resposta imediatamente iniciada por `O sistema deve...`;
- manutenção da publicação HTML com `table-layout:fixed`, larguras proporcionais e linha separadora própria para cada categoria;
- manutenção do gate explícito contra publicação ou sobrescrita sem aprovação;
- manutenção da notificação de hipóteses na história, do histórico de defeitos, do log de ações e do ciclo de execução.

Também foi atualizado o arquivo `agents/openai.yaml` para refletir o nome visual, a descrição curta e o prompt padrão da skill definitiva. Os diretórios `examples` e `templates` existentes foram preservados.

## 6. Estrutura proposta para a skill única

O esboço produzido foi organizado nos seguintes blocos:

1. objetivo e escopo;
2. modos de execução: análise, Azure DevOps e migração;
3. classificação de origem dos requisitos;
4. fontes permitidas e evidências técnicas;
5. análise arquitetural obrigatória;
6. dimensões funcionais e arquiteturais;
7. técnicas de teste;
8. categorias do mapa;
9. estrutura detalhada de cada cenário;
10. gate de aprovação;
11. publicação opcional;
12. tratamento de hipóteses;
13. controle de qualidade;
14. relatório final e governança.

## 7. Saída produzida

A saída final foi a skill consolidada implementada, com a seguinte diretriz:

> Preservar a v1 como núcleo técnico de arquitetura e incorporar da v3 o controle de fontes, as dimensões obrigatórias, o histórico de defeitos, a aprovação explícita e a publicação opcional no Azure DevOps.

Também foi definida uma lista de regras específicas para arquitetura, cobrindo:

- origem e paridade de requisitos;
- evidências técnicas;
- banco dual;
- jobs e schedulers;
- APIs e integrações;
- configuração e operação;
- observabilidade;
- segurança;
- hipóteses e controle de escopo.

O arquivo final possui 418 linhas e foi gravado primeiro no diretório de entregáveis do workspace e depois instalado no diretório ativo de skills do Codex.

## 8. Limitações e pendências identificadas

- A referência `references/migracao-agent.md`, indicada pela v1, não foi localizada na pasta analisada.
- A v3 possui forte dependência de Azure DevOps, MCP e estado da conversa; essa dependência deve permanecer isolada no adaptador de publicação.
- O checklist da v3 pode gerar muitos cenários quando aplicado mecanicamente. Na consolidação, as dimensões arquiteturais adicionais devem ser avaliadas por pertinência, com `N/A` justificado quando não aplicáveis.
- O validador automático `quick_validate.py` não pôde ser executado porque o Python disponível não possui o módulo `yaml` (`ModuleNotFoundError: No module named 'yaml'`).
- Foi realizada validação estrutural manual, confirmando frontmatter, nome válido, descrição, Steps 0–9, variáveis da V3, MCPs, gate de aprovação, classificação arquitetural, padrão de passos alternados e HTML com tabela fixa.
- A skill foi instalada com sucesso no caminho ativo `C:\Users\guilherme.borges\.codex\skills\qa-test-map-generator\`.
- A limitação do validador automático não impediu a criação nem a instalação; a validação manual e a conferência por hash foram concluídas.

## 9. Controle de alterações dos arquivos

| Arquivo | Ação realizada nesta etapa |
|---|---|
| `gerar-mapa-testes-v1-arquitetura.md` | Apenas leitura e análise; nenhum conteúdo alterado |
| `gerar-mapa-testes-v3.md` | Apenas leitura e análise; nenhum conteúdo alterado |
| `qa-test-map-generator/SKILL.md` | Atualizado com a versão definitiva consolidada e instalado no diretório ativo de skills |
| `qa-test-map-generator/agents/openai.yaml` | Atualizado com os metadados visuais e prompt padrão da skill |
| `qa-test-map-generator/templates/*` | Preservados; nenhum arquivo removido ou sobrescrito |
| `qa-test-map-generator/examples/*` | Preservados; nenhum arquivo removido ou sobrescrito |
| `registro-consolidacao-gerar-mapa-testes-arquitetura-2026-10-09.md` | Atualizado para registrar a implementação efetiva |

## 10. Resultado final

O resultado desta atividade é a skill definitiva `qa-test-map-generator`, consolidada a partir da V1 arquitetura e da V3 operacional. A V1 e a V3 permaneceram preservadas como fontes para comparação, auditoria e eventual retrocesso. A versão ativa está instalada no diretório de skills do Codex e o arquivo resultante também foi mantido no diretório de entregáveis do workspace.

## 11. Detalhamento da execução da criação

### 11.1. Data, hora e ambiente

| Campo | Registro |
|---|---|
| Data da implementação | 27/10/2026 |
| Horário da implementação | 13:49:04 |
| Fuso horário | America/Sao_Paulo — UTC-03:00 |
| Executor | Codex |
| Skill de apoio utilizada | `skill-creator` |
| Diretório de trabalho | `C:\Users\guilherme.borges\Documents\Codex\2026-10-27\documents-plugin-documents-openai-primary-runtime` |

### 11.2. Procedimento realizado

1. Leitura integral das instruções da skill `skill-creator` antes de alterar qualquer arquivo.
2. Leitura da V1 arquitetura para identificar regras normativas, cobertura técnica, paridade, evidências e padrão de execução.
3. Leitura da V3 para identificar variáveis, MCPs, ordem dos Steps, gate de aprovação, formato HTML e regras de publicação.
4. Leitura da skill anterior `qa-test-map-generator/SKILL.md`, seus metadados, templates e exemplo, para preservar compatibilidade e não remover recursos existentes.
5. Criação do arquivo consolidado em `outputs/qa-test-map-generator/SKILL.md`.
6. Criação do novo `outputs/qa-test-map-generator/agents/openai.yaml`.
7. Validação estrutural manual do frontmatter, das variáveis, dos Steps, dos MCPs, das regras de arquitetura e do HTML.
8. Instalação da versão consolidada em `C:\Users\guilherme.borges\.codex\skills\qa-test-map-generator\`.
9. Atualização dos metadados ativos em `agents/openai.yaml`.
10. Conferência dos hashes SHA-256 entre os arquivos de entrega e os arquivos instalados, com resultado `SKILL_MATCH=True` e `YAML_MATCH=True`.

### 11.3. Resultado da implementação

| Artefato | Resultado |
|---|---|
| Skill consolidada | Criada e instalada |
| Frontmatter | Válido, com `name` e `description` |
| Fluxo V3 | Preservado nos Steps 0–9 |
| Variáveis MCP | Preservadas e documentadas |
| Regras V1 arquitetura | Incorporadas |
| Gate de aprovação | Mantido como obrigatório |
| Publicação | Mantida via MCP Azure DevOps, somente no card `Criar Mapa de Teste` |
| Templates e exemplos anteriores | Preservados |
| Validação automática | Indisponível por ausência do módulo Python `yaml` |
| Validação manual | Concluída com sucesso |

### 11.4. Arquivos finais

- Arquivo de entrega: `C:\Users\guilherme.borges\Documents\Codex\2026-10-27\documents-plugin-documents-openai-primary-runtime\outputs\qa-test-map-generator\SKILL.md`
- Metadados de interface: `C:\Users\guilherme.borges\Documents\Codex\2026-10-27\documents-plugin-documents-openai-primary-runtime\outputs\qa-test-map-generator\agents\openai.yaml`
- Skill instalada: `C:\Users\guilherme.borges\.codex\skills\qa-test-map-generator\SKILL.md`
- Metadados instalados: `C:\Users\guilherme.borges\.codex\skills\qa-test-map-generator\agents\openai.yaml`

### 11.5. Observação de preservação

Os arquivos-fonte `gerar-mapa-testes-v1-arquitetura.md` e `gerar-mapa-testes-v3.md` não foram alterados. A criação foi realizada em uma skill consolidada separada, mantendo as versões originais disponíveis para auditoria, comparação e recuperação.

