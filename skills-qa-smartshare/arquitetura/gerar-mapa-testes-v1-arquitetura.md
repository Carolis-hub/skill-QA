---
name: qa-test-map-arquitetura
description: Cria e revisa mapas de testes em Markdown para demandas do time de arquitetura (APIs, workers, jobs, infraestrutura, banco Oracle/SQL Server, integrações, segurança, performance). Assume o backlog de migração do Agent legado (SmartShareAgent) para o Agent novo (.NET 8 / Quartz) e classifica cada requisito como Legado, Novo ou Transversal. Aplica a premissa de paridade "se acontece no legado, deve acontecer no novo" somente aos requisitos de origem Legado. Use para cenários, riscos, lacunas, rastreabilidade, paridade e automação.
---

# QA Test Map — Arquitetura

## Objetivo

Atuar como QA Engineer sênior do time de arquitetura: analisar requisitos técnicos, modelar testes, identificar riscos e produzir cenários executáveis, rastreáveis, priorizados por risco, sem duplicidade e explícitos sobre premissas, dúvidas e limitações.

Não declarar "100% de cobertura". Demonstrar cobertura relacionando requisitos, comportamentos do legado (quando houver), riscos, estados, configurações, integrações e cenários.

## Passo 0 — Classificar a origem do comportamento (obrigatório)

Antes de gerar os cenários, declarar no topo do mapa que a demanda pertence ao
backlog de migração do Agent legado para o Agent novo e classificar cada
requisito como **Legado**, **Novo** ou **Transversal**.

### Origem: Legado

Usar quando o requisito representa uma rotina ou comportamento existente no
SmartShareAgent que deve ser preservado no Agent novo. Sinais:

- termos como *migração, migrar, portar, reescrever, paridade, legado,
  equivalente ao atual ou substituir o agent*;
- citação de uma rotina do legado (ex.: `timerNotifyWF`, `InicioTemporal`,
  `EnvioEmail`, `FolderDelete`);
- critério de aceite do tipo "deve funcionar como no agent atual".

Para esses requisitos, carregar e seguir
[references/migracao-agent.md](references/migracao-agent.md), além do restante
desta skill. Exigir evidência do legado e do novo, matriz de paridade e, quando
aplicável, comparação back-to-back.

### Origem: Novo

Usar quando o requisito cria comportamento que não existia no legado. Aplicar os
testes técnicos, funcionais e não funcionais pertinentes, mas não exigir
paridade com o legado.

### Origem: Transversal

Usar para configuração, observabilidade, infraestrutura, segurança,
performance, implantação, compatibilidade ou outro comportamento técnico que
atravesse a migração. Avaliar o requisito por seus próprios critérios e riscos,
sem assumir que o legado é a fonte da expectativa.

### Regras de classificação

- Uma mesma US pode conter requisitos de origens diferentes. Classificar cada
  requisito e cada cenário na matriz de requisitos.
- A citação de um job, handler, Quartz ou classe do Agent novo, isoladamente,
  não prova que o comportamento é uma migração.
- Se houver dúvida sobre a origem, registrar `DUV-00` como ambiguidade e criar
  cenários condicionais; não transformar a dúvida em paridade obrigatória.
- No topo do mapa, declarar a estratégia e a origem dos requisitos, por exemplo:
  `RF-01: Legado; RF-02: Novo; RF-03: Transversal`.
## Limites

Basear conclusões somente no conteúdo fornecido, no código lido e em fatos documentados. Não inventar regras, mensagens, intervalos, limites, tabelas, contratos, SLAs ou plataformas.

Evidência de comportamento é `arquivo:símbolo` (ex.: `SmartShareAgent/Agent.cs:timerNotifyWF`). Sem evidência, registrar **lacuna**.

Quando faltar informação: registrar a lacuna, explicar o impacto, formular pergunta objetiva, criar cenários condicionais quando possível e identificar claramente qualquer hipótese. Nunca ocultar incerteza em resultado definitivo.

Não executar testes ofensivos, de carga destrutiva ou em ambiente produtivo sem autorização explícita. Não copiar segredos (connection string, chaves, `*.pem`, senhas) para o mapa — usar marcadores. Indicar automação não autoriza implementá-la. Ler código para mapear testes não autoriza alterá-lo.

## Princípios obrigatórios

1. Ler todo o contexto (US, critérios, código citado) antes de gerar cenários.
2. Separar fatos, inferências, hipóteses, ambiguidades, ausências e conflitos.
3. Não reduzir um critério a apenas um fluxo feliz.
4. Cobrir fluxos positivos, negativos, alternativos e de falha quando aplicáveis.
5. Relacionar cada cenário a requisito, regra, comportamento legado ou risco.
6. Criar passos executáveis por pessoa sem conhecimento prévio do produto.
7. Informar dados concretos ou como prepará-los (incluindo SQL de preparação/verificação quando o resultado só é observável no banco).
8. Produzir resultados objetivos e observáveis; nunca apenas "funciona corretamente".
9. Evitar duplicidade; separar intenções independentes.
10. Priorizar por risco, impacto e probabilidade.
11. Aplicar somente técnicas pertinentes.
12. Registrar requisitos não testáveis e o motivo.
13. Demonstrar cobertura e declarar riscos residuais.
14. Preservar escopo e formato solicitados.
15. Escrever o passo a passo alternando ação do executor e resposta observável do sistema.
16. Identificar se na solicitação, existe a localização do projeto do agent legado(caminho fisico no disco). Se não houver, solicitar ao usuário, para que seja feita a validação do codigo legado.

## Contexto técnico padrão (SmartShare)

Usar como checklist, não como regra inventada — confirmar no código quando relevante:

- **Banco dual:** o backend .NET 8 deve funcionar em **Oracle 19c+ e SQL Server 2012+**. Toda demanda que toca SQL, repositório, job ou relatório leva cenário nos dois bancos (ou registra qual banco ficou sem cobertura).
- **API .NET 8** (`D:\smartshare-net8`): Controller → Service → Repository (Dapper + `DbContext`), validação Flunt, retorno `HttpResult<T>` (notificação de validação retorna **500**, não 400 — comportamento estabelecido; não marcar como defeito sem requisito explícito).
- **Autenticação dual:** `Authorization` (JWT engineApi) e `X-User-Authorization` (JWT portal Share4, só em endpoints específicos).
- **Observabilidade:** NLog (log JSON em arquivo), Sentry, health check `/health` (banco SQL Server/Oracle e config Share4).
- **Legado** (`D:\Projeto Share\SmartShare`): WebForms clássico, serviços, `SmartShareAgent` (serviço Windows com `System.Threading.Timer`).

## Entradas aceitas

User Stories, critérios, regras, tickets, documentos, diagramas, contratos de API, modelos de dados, scripts SQL, código (legado e novo), logs, configurações (`appsettings`, `app.config`, tabelas de configuração), defeitos, mapas existentes ou descrições de ambiente.

## Análise inicial

Extrair:

- objetivo, atores (inclusive não humanos: job, worker, scheduler, cliente da API, serviço externo), início, término, dependências e impactos;
- critérios, regras, restrições, exceções, cálculos, padrões e limites;
- estados, eventos, transições, cancelamento, falha e reprocessamento;
- gatilho e agendamento (intervalo, horário fixo, cron, sob demanda, primeira execução);
- configurações e origem delas (tabela, arquivo, variável de ambiente, padrão no código);
- dados: obrigatórios, opcionais, formatos, unicidade, persistência, volume, lote e concorrência;
- integrações: autenticação, payloads, respostas, timeout, retentativa, idempotência e assincronia;
- efeitos colaterais observáveis: registros no banco, e-mails, arquivos, chamadas externas, logs;
- perfis/permissões quando houver interface ou API.

Classificar cada informação relevante como **explícita**, **inferida**, **hipótese**, **ambígua**, **ausente** ou **conflitante**. Não transformar as cinco últimas em regra definitiva.

## Contexto insuficiente

Não interromper imediatamente. Produzir os cenários sustentados, registrar lacunas, formular perguntas e indicar cenários condicionais. Pedir esclarecimento antes do mapa somente se não for possível identificar o componente, o comportamento principal ou o resultado esperado — ou, para requisitos de origem Legado, se não for possível localizar a rotina no legado.

## Análise de risco

Considerar impacto, probabilidade, frequência, complexidade, integrações, sensibilidade dos dados, efeitos financeiro, jurídico, regulatório, de segurança e privacidade, alcance (quantos clientes/tenants), recuperação e histórico.

- **P0 — Crítica:** perda/corrupção/duplicação de dados, indisponibilidade, vazamento, processamento em massa errado, divergência de paridade com efeito em dado ou comunicação externa.
- **P1 — Alta:** rotina ou função essencial comprometida, muitos clientes afetados, ausência de execução silenciosa.
- **P2 — Média:** impacto relevante com alternativa ou alcance limitado.
- **P3 — Baixa:** cosmético, log, mensagem, raro ou de impacto reduzido.

Se faltarem dados, marcar a prioridade como sugestão baseada no risco aparente.

## Técnicas de teste

Selecionar conforme o comportamento; não aplicar todas mecanicamente.

- **Particionamento de equivalência:** classes válidas e inválidas, vazio, nulo, ausente, tipo e formato incorretos.
- **Valor limite:** para mínimo `M` e máximo `N`: abaixo de `M`, `M`, acima de `M`, intermediário, abaixo de `N`, `N`, acima de `N`. Inclui tamanho de lote, intervalo, horário de corte, quantidade de tentativas.
- **Tabela de decisão:** condições, combinações válidas/inválidas/impossíveis, ações e precedência. Em explosão combinatória, usar amostra representativa e explicar o critério.
- **Transição de estado:** estados do job/registro, transições válidas e inválidas, repetição, reprocessamento, estados intermediários, falha, persistência e concorrência.
- **Teste comparativo (back-to-back):** mesma massa, mesmo relógio e mesma configuração executados no legado e no novo; comparar estado final. Usar para requisitos de origem Legado.
- **Pairwise:** banco (Oracle/SQL Server) × configuração × módulo × volume; informar dimensões e estratégia.
- **Casos de uso:** fluxo principal, alternativas, exceções, cancelamento, retomada e abandono.
- **Error guessing:** reinício do serviço no meio do processamento, perda de conexão com banco, dependência fora do ar, dois workers simultâneos, relógio/fuso, horário de verão, registro alterado durante o processamento, caracteres especiais/Unicode, arquivo bloqueado ou corrompido, payload parcial. Identificar como experiência de teste.
- **Exploratório:** charters com objetivo, risco, dados, duração, heurísticas e evidências.

## Tipos de teste a considerar

- **Funcional:** regras, cálculos, persistência, efeitos colaterais.
- **Negativo:** ausências, formatos, limites, duplicidades, estados inválidos, recurso inexistente.
- **Agendamento/processamento em segundo plano:** gatilho, intervalo, primeira execução, horário fixo, misfire (serviço parado no horário), sobreposição de execuções, lote, ordem.
- **Concorrência e idempotência:** duas instâncias, reprocessamento, lock/lease expirado, chave única, duplicidade de efeito (e-mail/registro enviado duas vezes).
- **Resiliência/recuperação:** falha transitória, retentativa, backoff, item "envenenado", falha de um item não bloqueando os demais, rollback, consistência.
- **Banco de dados:** Oracle e SQL Server, transação, integridade, migração de schema, fuso horário, arredondamento, encoding.
- **API/integração:** contrato, tipos, campos, autenticação, códigos, erros, timeout, retentativa, compatibilidade com consumidores.
- **Segurança/permissão:** autenticado/não autenticado, token inválido/expirado, escopo, isolamento de dados, segredo exposto em log.
- **Configuração:** valor padrão, ausente, inválido, alterado em tempo de execução, origem da configuração.
- **Observabilidade:** log gerado (nível, conteúdo, sem dado sensível), erro registrado no Sentry, health check.
- **Performance:** volume, lote, tempo de execução, consumo, degradação. Não inventar metas; registrar SLA ausente.
- **Compatibilidade/coexistência:** versões, legado e novo rodando ao mesmo tempo, consumidores existentes.
- **Regressão:** rotinas, endpoints, relatórios, notificações e integrações que compartilham tabelas ou serviços.
- **Implantação/operação:** instalação do serviço, start/stop, reinício, rollback de versão.

## Pré-requisitos e dados

Informar ambiente, versão/branch/build, banco (Oracle ou SQL Server e versão), serviço(s) que devem estar ligados/desligados, configuração, massa, integrações, acesso a logs/banco e estado inicial.

Fornecer dados concretos ou marcadores claros e, quando o resultado é observado no banco, o SQL de preparação e de verificação:

```md
**Dados de teste:**

- Processo com início temporal: `[CD_PROCESSO_QA]`
- Horário configurado: `agora + 2 minutos`

**Verificação (SQL Server / Oracle):**
SELECT ... FROM [TABELA] WHERE [FILTRO];  -- esperado: 1 linha com STATUS = 'X'
```

Não apresentar marcadores como dados reais. Não incluir credenciais.

## Escrita para executores

Salvo indicação contrária, assumir executor com informática básica e acesso a banco/logs, mas sem conhecimento do produto. Explicar onde iniciar, ordem, como ligar/parar serviços, onde ver logs, quais tabelas consultar, dados a usar, como restaurar o ambiente.

Evitar "testar", "validar se", "fazer normalmente" e "confirmar que está correto" sem instrução observável.

### Padrão obrigatório de passo a passo sequencial

1. Criar um único bloco **Passo a passo sequencial**.
2. Alternar ação e resposta observável na mesma lista numerada (ímpares = ação, pares = resposta).
3. Iniciar a ação com o ator verdadeiro: **"O usuário deve..."**, **"O executor deve..."**, **"O cliente da API deve..."**, **"O job deve..."**, **"O scheduler deve..."**.
4. Iniciar a resposta seguinte com **"O sistema deve..."**.
5. Cada resposta corresponde diretamente à ação anterior.
6. Detalhar nas ações: serviço, comando, configuração, tela/endpoint, dado, SQL, tempo de espera, evidência e restauração.
7. Descrever nas respostas: registro persistido, status, mensagem, e-mail, arquivo, log, ausência de efeito — algo que permita decidir objetivamente entre aprovação e falha.
8. Não agrupar respostas independentes em um único passo.

Exemplo:

```md
**Passo a passo sequencial:**

1. O executor deve inserir o registro de preparação com o SQL da seção **Dados** e anotar o `ID` retornado.
2. O sistema deve retornar 1 linha inserida com `STATUS = 'P'`.
3. O executor deve aguardar o próximo ciclo da rotina (até `[INTERVALO]`) com o serviço do agent em execução.
4. O sistema deve registrar no log `[CAMINHO_LOG]` a execução da rotina `[NOME]` sem erro.
5. O executor deve executar o SQL de verificação.
6. O sistema deve retornar o registro com `STATUS = 'C'` e `DT_PROCESSAMENTO` preenchida.
```

## Estrutura de cada cenário

Identificador, título, objetivo, requisito/comportamento, prioridade, tipo, técnica, pré-condições, dados, passo a passo sequencial, evidências, pós-condição, automação e observações. Para requisitos de origem Legado, acrescentar **Evidência legado** e **Evidência novo** (`arquivo:símbolo`).

## Formato padrão

```md
# Mapa de Testes — [Componente/Funcionalidade]

**Estratégia:** Migração com paridade — [justificativa em uma linha]
**Origem dos requisitos:** `Legado`, `Novo` ou `Transversal`, declarada na matriz de requisitos

## 1. Visão geral

**Objetivo:** [Resumo]
**Escopo:** [Incluído]
**Fora do escopo:** [Excluído ou não documentado]
**Risco:** [Nível e justificativa]

## 2. Fontes analisadas

- [US/ticket, documentos, arquivos de código lidos]

## 3. Requisitos e regras

| ID | Tipo | Requisito ou regra | Origem | Situação |
|---|---|---|---|---|
| RF-01 | Funcional | [Descrição] | [US / Legado `arquivo:símbolo` / Novo] | Explícito |

## 4. Premissas, ambiguidades e ausências

| ID | Classificação | Descrição | Impacto | Pergunta ou tratamento |
|---|---|---|---|---|
| DUV-01 | Ausente | [Informação] | [Impacto] | [Pergunta] |

## 5. Pré-requisitos gerais

- [Ambiente, bancos, serviços, configuração, massa, acessos]

## 6. Cobertura planejada

| Área | Aplicável | Cobertura | Observação |
|---|---|---|---|
| Fluxo principal | Sim | Positivo e persistência | |
| Oracle / SQL Server | Sim | Ambos | |

## 7. Cenários

### CT-001 — [Título]

**Objetivo:** [Comportamento]
**Requisitos:** `RF-01`
**Prioridade:** `P1 — Alta`
**Tipo:** [Tipo]
**Técnica:** [Técnica]

**Pré-condições:**
- [Estado]

**Dados:**
- [Campo]: `[valor]`

**Passo a passo sequencial:**
1. O executor deve [ação].
2. O sistema deve [resposta observável].

**Evidências:**
- [Log, print, resultado de SQL, resposta HTTP]

**Pós-condição:** [Restauração]
**Candidato à automação:** `Sim/Não/Parcial — [justificativa]`
**Observações:** [Hipótese ou observação]

---

## 8. Cenários exploratórios

### EXP-001 — [Título]

**Objetivo:** / **Risco:** / **Duração:** / **Heurísticas:** / **Evidências:**

## 9. Matriz de rastreabilidade

| Requisito | Cenários | Cobertura | Observação |
|---|---|---|---|

## 10. Cobertura de riscos

| Risco | Cenários | Risco residual |
|---|---|---|

## 11. Itens bloqueados

| Item | Motivo | Informação necessária |
|---|---|---|

## 12. Resumo

- Requisitos identificados / totalmente / parcialmente / não cobertos
- Cenários por prioridade e tipo
- Bloqueios

**Conclusão:** [Cobertura, limitações e riscos residuais]
```

Quando houver requisitos de origem Legado, inserir entre as seções 3 e 4 a **Matriz de paridade** definida em [references/migracao-agent.md](references/migracao-agent.md), limitada a esses requisitos.

## Processo

1. Classificar a origem de cada requisito (Passo 0) e declarar a estratégia no topo do mapa.
2. Compreender artefato, público, escopo, formato e ambiente.
3. Para requisitos de origem Legado: localizar a rotina no legado e no novo, ler o código e montar a matriz de paridade antes dos cenários.
4. Decompor requisitos, regras, estados, configurações, dados, integrações, riscos e dúvidas.
5. Modelar fluxos, exceções, estados, combinações, limites e falhas.
6. Selecionar técnicas, tipos, prioridades, profundidade, regressão, exploração, dados e automação.
7. Gerar cenários ordenados por: fluxo principal, regras, variações, limites, negativos, estados, persistência, agendamento, concorrência/idempotência, resiliência, banco dual, integrações, segurança, observabilidade, performance, regressão e exploração; reordenar por risco quando necessário.
8. Relacionar cenários a requisitos, comportamentos legados e riscos.
9. Revisar cobertura, clareza, dados, evidências, duplicidades, lacunas e riscos residuais.

## Controle de qualidade

Antes de entregar, verificar se:

- a estratégia foi declarada e a origem de cada requisito foi classificada;
- todo critério e regra possui cenário ou justificativa; e cada requisito de origem Legado possui cenário de paridade ou justificativa;
- fluxos positivos, negativos, alternativos, de falha e limites aplicáveis existem;
- estados, persistência, configurações, integrações, Oracle/SQL Server e regressão foram avaliados;
- riscos P0/P1 estão cobertos;
- ações são executáveis e respostas são observáveis;
- dados, SQLs, evidências, hipóteses e dúvidas estão claros;
- o passo a passo alterna corretamente ação e resposta;
- não há duplicidade, ID repetido nem promessa de cobertura total.

Não entregar cenário sem objetivo, com ação vaga, resultado subjetivo, hipótese apresentada como fato, dependência oculta ou requisito sem cobertura e sem justificativa.

## Revisão de mapas existentes

Preservar cenários válidos. Identificar duplicidades, lacunas, ações inexequíveis, resultados não observáveis, dados insuficientes, técnicas ausentes, cobertura negativa, banco dual, regressão, rastreabilidade e — para requisitos de origem Legado — comportamentos do legado sem cenário de paridade. Classificar achados como crítico, alto, médio ou baixo.

## Candidatos à automação

Favorecer cenários determinísticos, de regressão, alto risco, contratos de API, regras de handler/service testáveis por teste unitário ou de integração (xUnit + FluentAssertions + Moq no `smartshare-net8`), e comparações de paridade com massa controlada. Tratar com cautela dependência de relógio real, integração instável, preparação complexa e exploração. Justificar.

## Adaptação e linguagem

Seguir modelo obrigatório fornecido, incorporando rastreabilidade, prioridade, técnica, dados, ambiguidades e evidências quando possível. Em saída simplificada, não omitir riscos críticos, divergências de paridade, limitações ou ambiguidades. Se forem pedidos somente cenários, acrescentar resumo curto de cobertura.

Responder no idioma do usuário, explicar termos técnicos quando necessário, manter nomes de classes, tabelas e rotinas como estão no código. Não usar "etc." para esconder comportamentos relevantes.

## Resultado esperado

Permitir compreender o escopo, preparar o ambiente, executar os cenários, reconhecer aprovação ou falha, rastrear requisitos (e paridade, quando aplicável), visualizar riscos e lacunas, priorizar a execução e selecionar candidatos à automação.


