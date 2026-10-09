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
| Status | Esboço consolidado produzido; os arquivos originais não foram sobrescritos |

## 2. Prompt utilizado pelo solicitante

### 2.1. Prompt para análise e consolidação

> Pegue as skills "gerar-mapa-testes-v1-arquitetura" e "gerar-mapa-testes-v3"(da pasta arquitetura), faça um comparativo entre ambas e faça um esboço de como ficariam as 2 skills juntas em uma só, dando enfase nas regras que serão destinadas ao time de arquitetura

### 2.2. Prompt para criação deste registro

> Crie um documento dentro da pasta "documentação da criação das skills", nesse documento, você deverá fazer o registro das alterações que estão sendo realizadas conforme e a criação dessa skill, detalhe o prompt usado por mim, as alterações que voce realizou, quais arquivos foram usados como informação para essas alterações, qual foi a saída disso, e tambem insira a data e hora de que isso foi feito

## 3. Objetivo da atividade

Registrar a análise realizada para avaliar a união das skills `gerar-mapa-testes-v1-arquitetura` e `gerar-mapa-testes-v3`, preservando as regras técnicas destinadas ao time de arquitetura e incorporando os controles operacionais da v3.

O objetivo desta etapa foi produzir uma especificação de consolidação. Não houve sobrescrita, exclusão ou alteração do conteúdo das duas skills originais.

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

## 5. Alterações e decisões realizadas

### 5.1. Decisão principal de arquitetura da solução

A v1 foi definida como núcleo normativo da skill consolidada, porque contém as regras específicas do domínio de arquitetura. A v3 foi tratada como camada de orquestração, aprovação e publicação.

O desenho resultante separa dois conceitos:

- **Motor de análise:** identifica requisitos, riscos, evidências, estados, integrações e cenários.
- **Adaptador de publicação:** transforma o resultado em Markdown ou HTML e, quando solicitado, publica no Azure DevOps.

Essa separação evita que o conhecimento arquitetural fique acoplado ao Azure DevOps.

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

A saída da análise foi um comparativo entre as skills e um esboço de uma possível skill consolidada, com a seguinte diretriz:

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

## 8. Limitações e pendências identificadas

- A referência `references/migracao-agent.md`, indicada pela v1, não foi localizada na pasta analisada.
- A v3 possui forte dependência de Azure DevOps, MCP e estado da conversa; essa dependência deve permanecer isolada no adaptador de publicação.
- O checklist da v3 pode gerar muitos cenários quando aplicado mecanicamente. Na consolidação, as dimensões arquiteturais adicionais devem ser avaliadas por pertinência, com `N/A` justificado quando não aplicáveis.
- Nesta etapa, não foi criado um novo arquivo executável da skill consolidada. Foi produzido o desenho funcional e o registro da decisão de consolidação; os arquivos originais permanecem preservados.

## 9. Controle de alterações dos arquivos

| Arquivo | Ação realizada nesta etapa |
|---|---|
| `gerar-mapa-testes-v1-arquitetura.md` | Apenas leitura e análise; nenhum conteúdo alterado |
| `gerar-mapa-testes-v3.md` | Apenas leitura e análise; nenhum conteúdo alterado |
| `qa-test-map-generator/SKILL.md` | Apenas leitura como referência metodológica |
| `registro-consolidacao-gerar-mapa-testes-arquitetura-2026-10-09.md` | Criado para documentar a atividade |

## 10. Resultado final

O resultado desta atividade é uma base documentada para criação futura de uma skill única de geração de mapas de testes para arquitetura. A recomendação é implementar a consolidação em um novo arquivo, preservando as duas versões atuais para comparação, auditoria e eventual retrocesso.

