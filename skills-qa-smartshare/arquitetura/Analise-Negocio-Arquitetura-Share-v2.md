---
name: analise-negocio-arquitetura-share
description: Analisa uma User Story do Share no Azure DevOps ou em fonte funcional fornecida, detalhando objetivo, escopo, atores, regras, fluxos, estados, critérios de aceite, exceções, ambiguidades, dependências e riscos de negócio com rastreabilidade. Use somente após a User Story e seu contexto funcional estarem disponíveis. É uma análise somente leitura e não define implementação técnica.
metadata:
  short-description: Análise de negócio detalhada para o time de Arquitetura do Share
---

# Skill — Análise de Negócio do Share

## 1. Objetivo

Analisar uma User Story ou demanda funcional do Share e produzir uma especificação de negócio detalhada, rastreável e verificável.

Esta skill deve esclarecer o comportamento que o negócio espera antes das etapas seguintes do processo de desenvolvimento. O resultado deve permitir que uma pessoa compreenda a regra funcional sem precisar reinterpretar a User Story original.

A análise deve responder:

- qual problema de negócio a demanda pretende resolver;
- qual resultado deve ser entregue;
- quem participa do processo;
- em quais condições o comportamento se aplica;
- quais regras devem ser atendidas;
- quais fluxos são possíveis;
- quais estados e transições são esperados;
- quais exceções alteram o comportamento;
- quais informações estão ausentes ou conflitantes;
- quais riscos existem se a regra for interpretada incorretamente.

Esta skill não deve definir como a solução será implementada.

## 2. Pré-requisitos para execução

Execute esta skill somente quando os seguintes pré-requisitos estiverem atendidos:

- existe uma User Story ou demanda funcional identificável;
- o ID da história e o projeto foram informados, quando a fonte for o Azure DevOps;
- ou o texto completo da User Story foi fornecido em arquivo ou no prompt;
- o contexto disponível é suficiente para iniciar a análise;
- a pessoa que executa a skill sabe que o resultado será uma análise de negócio, não uma análise técnica;
- a consulta será realizada em modo somente leitura.

Se a User Story não estiver disponível ou o conteúdo funcional for insuficiente, não invente a demanda. Informe que a análise não pode ser concluída e liste exatamente o que precisa ser fornecido.

## 3. Formas de entrada

### 3.1 User Story no Azure DevOps

Formato esperado:

```text
[ID da história] [nome do projeto]
```

Exemplos:

```text
146157 "Projeto Share"
146157 NomeDoProjeto
```

O projeto deve ser informado quando não houver configuração confiável no ambiente. Não assuma automaticamente `Squad Centaurus` ou qualquer outro projeto.

### 3.2 User Story fornecida em arquivo ou no prompt

Quando a história estiver anexada ou transcrita no prompt, utilize esse conteúdo como fonte primária. Nesse caso, registre no relatório qual arquivo ou conteúdo foi usado.

### 3.3 Contexto funcional adicional

Podem ser utilizados, quando explicitamente fornecidos:

- decisões de produto;
- atas de reunião;
- especificações funcionais;
- glossários;
- documentos de processo;
- comentários aprovados sobre a User Story;
- análises funcionais anteriores.

Documentos técnicos, código, scripts, logs, tabelas de banco, PRs e relatórios de execução não devem substituir a User Story como fonte da regra de negócio. Se forem fornecidos apenas como contexto, informe essa condição e não transforme seu conteúdo automaticamente em requisito.

## 4. Regra fundamental

**Não inventar regra de negócio.**

Toda afirmação do relatório deve ser rastreável a uma fonte funcional específica:

- título;
- descrição;
- critérios de aceite;
- comentário com decisão clara;
- relação funcional da história;
- documento funcional explicitamente fornecido.

Quando uma informação necessária não estiver disponível, escreva literalmente:

> **Informação não encontrada / necessita validação.**

Nunca preencha uma lacuna com:

- suposição sobre o comportamento atual do Share;
- conhecimento de outra User Story;
- comportamento do Agent legado;
- solução técnica provável;
- preferência pessoal;
- interpretação não marcada como hipótese.

## 5. Classificação das informações

Classifique as conclusões da análise para deixar claro o grau de certeza.

### 5.1 Fato

Informação encontrada diretamente na fonte.

### 5.2 Regra explícita

Regra escrita diretamente na descrição, nos critérios de aceite ou em uma decisão funcional confirmada.

### 5.3 Regra implícita

Conclusão que decorre logicamente de fatos escritos, mas que não foi declarada de forma direta. Toda regra implícita deve explicar o raciocínio e indicar se necessita validação.

### 5.4 Hipótese

Interpretação possível, mas ainda não confirmada. Hipótese não pode ser usada como regra obrigatória.

### 5.5 Informação ausente

Pergunta de negócio necessária para completar a especificação.

### 5.6 Decisão confirmada

Decisão funcional registrada de maneira clara e não contestada.

## 6. Limites da análise de negócio

### 6.1 Não analisar implementação

Não conclua nesta skill:

- qual classe ou método será alterado;
- qual endpoint ou payload deve ser criado;
- qual tabela ou coluna deve ser usada;
- qual consulta SQL deve ser executada;
- como o Worker ou Scheduler será configurado;
- como serão implementados retry, lease, lock ou concorrência;
- como reproduzir uma falha técnica;
- qual ambiente deve ser utilizado;
- qual log ou métrica comprovará a execução.

Se a User Story exigir um resultado funcional relacionado a esses temas, descreva somente o resultado de negócio. Exemplo: “a operação não deve ser considerada concluída quando o envio não for realizado”. Não defina o mecanismo técnico que comprovará o envio.

### 6.2 Não transformar comportamento atual em regra esperada

Separe sempre:

- comportamento observado;
- comportamento desejado;
- regra que sustenta o comportamento desejado;
- dúvida sobre a decisão do produto.

Um bug, relatório de execução ou comportamento legado não deve ser convertido automaticamente em regra de negócio.

### 6.3 Somente leitura

Não altere:

- User Stories;
- critérios de aceite;
- comentários;
- status;
- tags;
- relações;
- código;
- banco;
- configurações;
- ambiente de execução.

## 7. Step 0 — Validar ambiente e entrada

Antes de analisar:

1. confirme se a entrada contém um ID e projeto ou uma fonte funcional completa;
2. confirme que o pedido é de análise de negócio;
3. confirme que a consulta, quando necessária, será somente leitura;
4. verifique se o servidor MCP do Azure DevOps está disponível quando a entrada for um ID do Azure DevOps.

Se a chamada falhar porque o servidor MCP ou a ferramenta de consulta não está disponível, pare imediatamente e reporte:

```text
MCP server mcp__azure-devops indisponivel ou ferramenta ausente.
```

Um erro de item não encontrado não é falha de ambiente. Nesse caso, informe que o ID ou projeto não foi localizado e pare.

## 8. Step 1 — Buscar e registrar a User Story

Quando a entrada for um ID do Azure DevOps, chame:

```text
mcp__azure-devops_wit_get_work_item
```

Utilize os parâmetros compatíveis com a ferramenta disponível:

- `id`: ID informado;
- `project`: projeto informado;
- `expand`: informações completas, quando suportado.

Capture, quando disponíveis:

- `ID` da história;
- `System.Title`;
- `System.WorkItemType`;
- `System.State`;
- `System.Description`;
- `Microsoft.VSTS.Common.AcceptanceCriteria`;
- `System.Tags`;
- relações funcionais;
- demais campos de negócio relevantes.

Registre no relatório a origem dos dados utilizados.

## 9. Step 2 — Consultar comentários

Se a ferramenta estiver disponível, consulte o histórico de comentários:

```text
mcp__azure-devops_wit_get_work_item_comments
```

Use os comentários somente para:

- compreender decisões ou mudanças de escopo;
- identificar dúvidas de negócio que já tenham sido respondidas;
- registrar uma decisão funcional clara;
- identificar conflito entre interpretações.

Não trate uma opinião isolada como regra definitiva. Quando houver comentários conflitantes, registre a divergência e solicite validação.

Se a consulta falhar ou não houver comentários, prossiga sem bloquear a análise. Registre a limitação somente se ela afetar alguma conclusão.

## 10. Step 3 — Normalizar o conteúdo

Ao renderizar descrição e critérios de aceite:

- remova tags HTML;
- decodifique `&nbsp;`, `&amp;`, `&lt;` e `&gt;`;
- preserve títulos, listas, tabelas e quebras de parágrafo;
- preserve valores, nomes e trechos literais importantes;
- não altere o significado do texto;
- não transforme uma interpretação em texto original.

Apresente a origem de cada conclusão usando referências como:

- `(título)`;
- `(descrição)`;
- `(critérios de aceite)`;
- `(comentário de dd/mm/aaaa)`;
- `(documento funcional fornecido)`.

## 11. Step 4 — Inventário inicial de fatos

Antes de interpretar, identifique os fatos encontrados.

Use o formato:

```markdown
| ID | Fato | Fonte | Certeza |
|---|---|---|---|
| FAT-01 | <informação encontrada na fonte> | descrição | Confirmada |
```

O inventário deve conter apenas fatos, não hipóteses ou soluções técnicas.

## 12. Step 5 — Extração analítica

Produza todos os itens abaixo. Não omita uma seção. Quando não houver conteúdo aplicável, escreva `Nenhum identificado`.

### 12.1 Resumo executivo

Explique brevemente:

- o que a demanda pretende alterar;
- qual problema está sendo tratado;
- qual resultado funcional é esperado;
- qual é o principal risco ou pendência.

Não acrescente informações que não estejam sustentadas pela fonte.

### 12.2 Objetivo de negócio

Descreva:

- problema atual;
- resultado desejado;
- usuários, processos ou clientes afetados;
- benefício esperado, somente quando informado ou claramente sustentado.

Se a User Story não explicar o benefício, informe:

> **Informação não encontrada / necessita validação:** o benefício de negócio da alteração não foi explicitado.

### 12.3 Escopo funcional

Separe:

#### Incluído

O que a User Story solicita.

#### Fora do escopo

O que a User Story exclui explicitamente.

#### Não definido

O que parece relacionado, mas não pode ser concluído a partir da fonte.

Não amplie o escopo porque uma consequência técnica parece necessária.

### 12.4 Atores e responsabilidades

Identifique os participantes funcionais:

- usuário solicitante;
- aprovador;
- executor;
- administrador;
- cliente ou unidade;
- processo automático;
- destinatário de comunicação;
- terceiro envolvido.

Para cada ator, registre apenas responsabilidades sustentadas pela demanda.

Formato sugerido:

```markdown
| Ator | Responsabilidade | Fonte | Certeza |
|---|---|---|---|
| <ator> | <responsabilidade> | descrição | Confirmada |
```

### 12.5 Entidades e vocabulário de negócio

Liste termos que podem afetar a interpretação:

```markdown
| Termo | Significado identificado | Fonte | Necessita validação |
|---|---|---|---|
| <termo> | <significado> | descrição | Não |
```

No contexto do Share, termos como fluxo, tarefa, processo, documento, solicitação, alerta, cliente e periodicidade podem ter significados específicos. Não escolha um significado com base apenas em conhecimento anterior; use a fonte disponível.

### 12.6 Pré-condições e gatilhos

Identifique:

- o que precisa ser verdadeiro antes do comportamento;
- qual evento inicia a operação;
- quem pode iniciar;
- quais cadastros, estados ou condições são necessários.

Quando uma pré-condição não estiver definida, registre a lacuna.

### 12.7 Comportamentos esperados

Transforme cada critério de aceite em uma condição verificável:

```markdown
- **BE-01:** Quando <condição>, o sistema deve <comportamento esperado>. (origem: critério de aceite 1)
```

O comportamento deve ser observável do ponto de vista funcional. Não substitua a descrição por uma solução técnica.

### 12.8 Fluxo principal

Descreva, em sequência:

1. pré-condições;
2. evento inicial;
3. ações funcionais;
4. decisões;
5. resultado esperado;
6. pós-condições.

Exemplo de estrutura:

```markdown
1. Dado que <pré-condição>.
2. Quando <evento> ocorrer.
3. O sistema deve <ação funcional>.
4. Se <condição>, deve <resultado>.
5. Ao final, <estado ou efeito esperado>.
```

### 12.9 Fluxos alternativos

Registre variações permitidas do fluxo principal, como:

- perfis diferentes;
- tipos diferentes de processo;
- presença ou ausência de informação;
- diferentes estados de uma entidade;
- diferentes periodicidades;
- regras condicionais.

Não trate uma exceção como fluxo alternativo se o resultado esperado for bloqueio, rejeição ou erro de negócio.

### 12.10 Exceções e condições especiais

Identifique situações que alteram o comportamento padrão:

- dado obrigatório ausente;
- status incompatível;
- permissão insuficiente;
- registro duplicado;
- registro inexistente;
- limite excedido;
- condição temporal não atendida;
- operação externa não concluída, quando a User Story definir o resultado funcional.

Para cada exceção, registre o comportamento esperado. Se ele não estiver definido, não invente.

### 12.11 Regras explícitas

Crie identificadores `RN-01`, `RN-02` e assim por diante.

Formato:

```markdown
### RN-01 — <nome da regra>

**Regra:** <regra escrita de forma clara>
**Condição de aplicação:** <quando se aplica>
**Resultado esperado:** <o que deve ocorrer>
**Fonte:** <descrição | critério de aceite | comentário confirmado>
**Certeza:** Confirmada
```

Inclua somente regras escritas ou claramente confirmadas.

### 12.12 Regras implícitas

Crie identificadores `RI-01`, `RI-02` e use o marcador `IMPLÍCITA:`.

Formato:

```markdown
### RI-01 — IMPLÍCITA: <nome da inferência>

**Inferência:** <conclusão derivada>
**Fatos que sustentam a inferência:** <FAT-XX, CA-XX ou fonte>
**Raciocínio:** <explique por que a conclusão decorre do texto>
**Risco se estiver incorreta:** <impacto>
**Validação humana:** Necessária | Não necessária
```

Se a inferência puder ser interpretada de mais de uma forma, trate-a como hipótese ou ambiguidade, não como regra implícita confirmada.

### 12.13 Validações, obrigatoriedades e limites

Identifique, quando houver fonte:

- campos obrigatórios;
- valores permitidos;
- valores proibidos;
- quantidade mínima ou máxima;
- ocorrência única ou múltipla;
- necessidade de todos os itens ou apenas um;
- comportamento para zero itens;
- comportamento para duplicidade;
- limites temporais ou de periodicidade.

Não invente números, prazos, mensagens ou tolerâncias ausentes.

### 12.14 Estados e transições

Quando a demanda envolver status ou fases, use:

```markdown
| Estado inicial | Evento/condição | Resultado esperado | Estado final | Fonte |
|---|---|---|---|---|
| <estado> | <evento> | <efeito funcional> | <estado> | <origem> |
```

Registre também:

- transições permitidas;
- transições proibidas;
- condição que mantém o estado atual;
- significado funcional de concluído, pendente, cancelado, rejeitado ou equivalente.

Não deduza que “processado” significa “concluído” sem evidência.

### 12.15 Dependências funcionais

Identifique:

- outras User Stories;
- processos anteriores;
- cadastros;
- aprovações;
- perfis;
- dados necessários;
- integrações citadas como parte do negócio;
- relações funcionais do Work Item.

Não transforme dependência técnica em dependência de negócio sem evidência.

### 12.16 Impacto funcional

Descreva quem ou o que pode ser afetado:

- usuários;
- clientes;
- processos;
- tarefas;
- documentos;
- notificações;
- pendências;
- dados ou estados funcionais;
- operações já iniciadas.

Descreva o impacto sem atribuir causa técnica.

### 12.17 Critérios de aceite normalizados

Para cada critério original, crie uma versão verificável:

```markdown
### CA-01 — <nome do critério>

**Dado que:** <pré-condição de negócio>

**Quando:** <evento ou ação>

**Então:** <resultado esperado>

**Resultado funcional observável:** <o que deve ser possível verificar>

**Fonte original:** <critério de aceite, descrição ou comentário>
```

Não crie critérios que não estejam na fonte. Quando não houver critérios de aceite, baseie-se apenas na descrição e registre a ausência.

### 12.18 Tabelas de decisão

Quando a regra depender de combinações de condições, use tabela de decisão:

```markdown
| Condição A | Condição B | Condição C | Resultado |
|---|---|---|---|
| Sim | Sim | Sim | Permitir operação |
| Sim | Não | Sim | Bloquear operação |
| Não | Sim | Sim | Bloquear operação |
| Não informado | Sim | Sim | Necessita validação |
```

Não complete combinações que a fonte não permita concluir.

### 12.19 Informações ausentes

Liste perguntas funcionais, não perguntas técnicas.

Formato:

```markdown
### INF-01 — <tema>

**Pergunta de negócio:** <pergunta objetiva>
**Por que é necessária:** <impacto na regra, escopo ou validação>
**Bloqueia o avanço:** Sim | Não | Parcialmente
```

Exemplos válidos:

- Qual comportamento deve ocorrer quando o dado obrigatório não existe?
- A operação deve ser bloqueada ou permanecer pendente?
- A regra vale para todos os perfis?
- O comportamento se aplica a registros existentes?
- Qual evento representa a conclusão da operação?
- O evento pode ocorrer mais de uma vez?

Não liste aqui perguntas sobre classes, endpoints, bancos, logs, servidores, configuração ou forma de simulação.

### 12.20 Ambiguidades e conflitos

Crie identificadores `AMB-01`, `AMB-02` e registre:

- trecho ou fontes envolvidas;
- interpretações possíveis;
- impacto funcional de cada interpretação;
- decisão necessária.

Exemplo:

```markdown
### AMB-01 — Momento da conclusão

O texto não esclarece se a operação deve ser considerada concluída quando:

1. a tentativa for iniciada; ou
2. o resultado esperado for efetivamente alcançado.

**Impacto:** a escolha altera o tratamento da pendência em caso de falha.

**Decisão necessária:** confirmar qual evento representa a conclusão de negócio.
```

Quando fontes conflitarem, não escolha uma interpretação silenciosamente.

### 12.21 Riscos de negócio

Crie identificadores `RIS-01`, `RIS-02` e descreva o que pode ocorrer se a regra for mal interpretada:

- operação duplicada;
- fluxo interrompido;
- cancelamento indevido;
- informação perdida;
- notificação não entregue;
- sucesso registrado sem conclusão real;
- pendência encerrada indevidamente;
- usuário sem permissão realizando a operação;
- inconsistência de estado;
- impacto para cliente ou processo.

Não declare causa técnica sem fonte ou análise específica.

## 13. Regras para comentários e relações

### 13.1 Comentários

Use comentários para enriquecer o contexto, mas não para inventar requisitos. Uma decisão de comentário só deve ser tratada como confirmada quando estiver clara, aprovada ou não contestada.

### 13.2 Relações do Work Item

Use relações para identificar dependências e contexto. Se houver cards filhos do tipo `Análise`, `Analise Review`, implementação ou correção, não os utilize como substitutos da análise de negócio.

### 13.3 Conflitos entre fontes

Quando descrição, critérios e comentários divergirem:

1. registre cada versão;
2. informe a origem;
3. explique o impacto;
4. marque a decisão como pendente;
5. não selecione uma interpretação automaticamente.

## 14. Validação humana obrigatória

A pessoa responsável pelo produto ou pela demanda deve validar o resultado quando houver:

- conflito entre critérios e descrição;
- dúvida sobre o objetivo ou escopo;
- regra de permissão incompleta;
- cancelamento, exclusão, encerramento ou descarte;
- definição incerta de sucesso ou conclusão;
- comportamento que afete clientes, documentos, processos ou notificações;
- limite, prazo, prioridade ou exceção não definidos;
- interpretação implícita com impacto relevante;
- necessidade de confirmar se uma regra vale para dados existentes;
- mudança de escopo registrada apenas em comentário;
- ausência de informação necessária para validar a regra.

Formule perguntas objetivas. Não solicite apenas “mais detalhes”.

## 15. Critério de conclusão da análise

Classifique a análise com um dos estados:

- `ANÁLISE COMPLETA`: regras essenciais identificadas, sem bloqueio crítico.
- `ANÁLISE COMPLETA COM PENDÊNCIAS`: análise possível, mas existem dúvidas que devem acompanhar o processo.
- `VALIDAÇÃO HUMANA OBRIGATÓRIA`: não é seguro concluir a interpretação sem decisão funcional.
- `ENTRADA INSUFICIENTE`: não há conteúdo suficiente para iniciar ou completar a análise.
- `FONTES CONFLITANTES`: fontes relevantes divergem sem decisão confirmada.

Não classifique como completa uma análise que depende de uma hipótese não validada.

## 16. Relatório final obrigatório

Apresente o relatório em Markdown nesta estrutura:

```markdown
# Análise de Negócio — #<ID> <Título>

**Projeto:** <projeto>
**Tipo:** <tipo>
**Status:** <status>
**Estado da análise:** <estado>
**Fonte primária:** <fonte>

## 1. Resumo executivo

## 2. Objetivo da alteração

## 3. Escopo funcional

### Incluído

### Fora do escopo

### Não definido

## 4. Atores e responsabilidades

## 5. Entidades e vocabulário de negócio

## 6. Pré-condições e gatilhos

## 7. Comportamentos esperados

## 8. Fluxo principal

## 9. Fluxos alternativos

## 10. Condições e exceções

## 11. Regras explícitas

## 12. Regras implícitas

## 13. Validações, obrigatoriedades e limites

## 14. Estados e transições

## 15. Critérios de aceite normalizados

## 16. Dependências funcionais

## 17. Impacto funcional

## 18. Informações ausentes

## 19. Ambiguidades e conflitos

## 20. Riscos identificados

## 21. Matriz de rastreabilidade

## 22. Validação humana necessária

## 23. Conclusão e próxima etapa
```

Se uma seção não tiver conteúdo aplicável, escreva explicitamente:

```text
Nenhum identificado.
```

### 16.1 Matriz de rastreabilidade

Inclua uma matriz que relacione fonte, regra e comportamento:

```markdown
| Fonte | Elemento | Regra/critério relacionado | Observação |
|---|---|---|---|
| Descrição | <trecho resumido> | RN-01, BE-01 | <observação> |
| Critério de aceite 1 | <trecho resumido> | CA-01, RN-02 | <observação> |
| Comentário de <data> | <decisão> | AMB-01 resolvida | <observação> |
```

### 16.2 Conclusão e próxima etapa

Não encadeie automaticamente nenhuma outra ação. Finalize informando:

- estado da análise;
- decisões humanas pendentes;
- riscos que devem ser considerados;
- se o conteúdo está pronto para a próxima etapa do processo;
- qual etapa deve ser executada em seguida, sem executá-la.

## 17. Troubleshooting

### 17.1 História sem critérios de aceite

Não invente critérios. Registre:

> **Informação não encontrada / necessita validação:** a User Story não possui critérios de aceite preenchidos.

Baseie os comportamentos apenas na descrição e identifique essa origem.

### 17.2 Comentários indisponíveis

Prossiga com descrição e critérios. Registre a ausência somente se houver decisão funcional que não possa ser concluída sem os comentários.

### 17.3 História inexistente

Informe o erro de localização e pare. Não tente outro ID ou projeto.

### 17.4 Projeto não informado

Se não existir configuração confiável no contexto da execução, solicite o projeto antes da consulta. Não adivinhe o nome.

### 17.5 MCP ou ferramenta indisponível

Pare quando a entrada depender do Azure DevOps e a ferramenta necessária não estiver disponível. Informe:

```text
MCP server mcp__azure-devops indisponivel ou ferramenta ausente.
```

### 17.6 Texto ambíguo

Não escolha a interpretação mais provável. Registre as alternativas, o impacto e a pergunta para validação humana.

### 17.7 Dúvida técnica identificada durante a análise

Não responda com suposição. Não transforme a dúvida em bloqueio de negócio se a regra funcional estiver clara. Registre-a em “Conclusão e próxima etapa” como ponto para análise técnica.

### 17.8 Comportamento de bug ou relatório anterior

Separe comportamento observado de comportamento esperado. O relatório anterior pode ser citado como contexto, mas a regra esperada precisa estar na User Story ou ser confirmada pela pessoa responsável.

## 18. Boas práticas para manter a qualidade

- Leia a User Story inteira antes de concluir o objetivo.
- Não baseie regras detalhadas apenas no título.
- Transforme cada critério de aceite em comportamento verificável.
- Cite a origem próxima de cada conclusão.
- Não esconda lacunas em frases genéricas.
- Prefira perguntas objetivas a pedidos abertos de esclarecimento.
- Não trate uma inferência como regra confirmada.
- Não altere o escopo por causa de uma consequência técnica.
- Não use conhecimento de outras histórias sem declarar a fonte.
- Não omita seções sem conteúdo; escreva `Nenhum identificado`.
- Diferencie estado funcional de resultado técnico.
- Preserve a terminologia usada pelo produto e registre definições quando houver risco de interpretação.

## 19. Manutenção e evolução da skill

Altere esta skill quando houver:

- mudança oficial no processo de análise de negócio;
- novo tipo recorrente de User Story que exija uma seção funcional;
- falha repetida na rastreabilidade;
- necessidade de atualizar a entrada do Azure DevOps;
- novo padrão aprovado para relatório ou decisão funcional.

Não altere a skill por causa de:

- um bug isolado;
- uma regra específica de uma única User Story;
- uma solução técnica temporária;
- uma preferência de redação individual;
- um detalhe de ambiente.

Para evoluir a skill:

1. registre o motivo da alteração;
2. verifique se ela continua restrita à análise de negócio;
3. preserve a regra de não inventar;
4. preserve o modo somente leitura;
5. atualize exemplos e estrutura de saída;
6. valide com uma User Story realista;
7. confirme que nenhuma etapa técnica foi incorporada indevidamente.

## 20. Evoluções em relação à skill original

### 20.1 Pontos mantidos

- análise de User Story do Azure DevOps;
- entrada por ID e projeto;
- validação do ambiente MCP;
- comportamento somente leitura;
- regra de não inventar regra de negócio;
- uso de título, descrição, critérios, comentários e relações;
- normalização de HTML;
- tratamento opcional de comentários;
- objetivo da alteração;
- comportamentos esperados;
- regras explícitas;
- regras implícitas;
- condições e exceções;
- dependências;
- informações ausentes;
- ambiguidades;
- riscos;
- estrutura de relatório em Markdown;
- tratamento de história sem critérios de aceite;
- não utilização de cards técnicos como substitutos da User Story;
- encerramento sem encadeamento automático.

### 20.2 Pontos modificados

| Ponto | Alteração |
|---|---|
| Projeto padrão | Removido o projeto fixo `Squad Centaurus`; o projeto deve ser informado ou obtido de configuração confiável. |
| Entrada | Mantido o formato por ID e projeto, com suporte adicional a arquivo ou conteúdo funcional fornecido. |
| Extração | O conjunto original de nove itens foi preservado e ampliado com escopo, atores, vocabulário, pré-condições, fluxos, estados, validações e impacto. |
| Regras implícitas | Passaram a exigir raciocínio, fonte dos fatos e indicação de validação. |
| Critérios de aceite | Passaram a ser normalizados em formato `Dado que / Quando / Então`. |
| Rastreabilidade | Foram adicionados identificadores para fatos, regras, comportamentos, critérios, ambiguidades, informações ausentes e riscos. |
| Relatório | A estrutura original foi preservada como base e ampliada para permitir análise funcional mais completa. |
| Encerramento | O encaminhamento passou a ser para a próxima etapa humana do processo, sem referência obrigatória a outras Agents. |

### 20.3 Pontos adicionados

- pré-requisitos de execução;
- inventário inicial de fatos;
- escopo incluído, excluído e não definido;
- atores e responsabilidades;
- entidades e vocabulário de negócio;
- pré-condições e gatilhos;
- fluxos principal e alternativos;
- validações, obrigatoriedades e limites;
- estados e transições funcionais;
- critérios de aceite normalizados;
- tabelas de decisão;
- impacto funcional;
- classificação entre fato, regra explícita, regra implícita, hipótese e pendência;
- validação humana obrigatória para decisões de negócio;
- critérios formais para concluir a análise;
- matriz de rastreabilidade ampliada;
- tratamento de conflitos entre fontes;
- separação entre comportamento observado e comportamento esperado;
- diretrizes de manutenção da própria skill.

## 21. Resultado esperado

Ao terminar, o relatório deve permitir responder com clareza:

- o que a User Story pretende resolver;
- o que está dentro e fora do escopo;
- quem participa;
- qual é o comportamento esperado;
- quais regras estão confirmadas;
- quais regras são inferidas;
- quais fluxos e exceções existem;
- quais estados são esperados;
- quais informações faltam;
- quais ambiguidades precisam de decisão;
- quais riscos funcionais devem ser considerados;
- se a análise está pronta para a próxima etapa.

A skill deve entregar profundidade funcional máxima, mantendo a separação entre análise de negócio e implementação técnica.
