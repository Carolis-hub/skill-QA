# Rascunho — autonomia na preparação e execução de testes

**Status:** proposta para validação. Não altera as skills atuais.
**Data:** 09/11/2026.
**Escopo inicial:** `arquitetura-validar-ambiente` e `arquitetura-executar-teste`.

## 1. Resultado esperado

Executar o trabalho autorizado até a entrega, resolver decisões operacionais com evidências e solicitar intervenção somente quando faltar uma decisão indispensável ou uma autorização ainda não concedida. Manter rastreabilidade, proteção de dados e distinção entre falha funcional e impedimento de execução.

Esta proposta permite execução parcial quando o impedimento afetar apenas cenários isolados. Essa é uma mudança de comportamento em relação ao gate integral atual e precisa ser validada antes da implementação.

## 2. Texto comum proposto para as duas skills

### Autonomia e continuidade

Conduza o fluxo até a entrega dentro do escopo autorizado. Consultas, investigação, coleta de evidências, geração de artefatos locais e decisões técnicas reversíveis podem prosseguir sem nova confirmação quando cobertas pelo pedido e pelas permissões disponíveis.

Antes de solicitar informação ao usuário:

1. Consulte a história, o mapa, as análises, os arquivos oficiais de configuração e as evidências do ciclo que estiverem acessíveis e forem pertinentes.
2. Verifique se a informação ou autorização já foi fornecida na conversa ou em registro verificável desta execução.
3. Tente alternativas seguras e documentadas de investigação. Registre as tentativas relevantes; não repita tentativas sem nova evidência.
4. Se a dúvida persistir, apresente em uma solicitação consolidada o que falta, quais cenários dependem disso e qual decisão é necessária.

Não invente requisito, endpoint, credencial, resultado esperado, massa ou autorização. Uma decisão técnica operacional não substitui uma decisão de negócio.

Mensagens de progresso são informativas e não encerram a execução. Continue as etapas independentes enquanto aguarda uma decisão, quando a ferramenta e o fluxo permitirem. Se nenhuma etapa independente puder avançar, entregue o estado real e a condição objetiva de retomada.

### Reaproveitamento de autorização

Uma autorização explícita já concedida permanece válida dentro do ambiente, ciclo, objetos, operações e limites aprovados. Não solicite novamente autorização para a mesma ação coberta por esse escopo. Revalide as pré-condições técnicas antes de executá-la.

Mantenha `$AUTORIZACOES_EXECUCAO` com:

| Campo | Conteúdo obrigatório |
|---|---|
| Origem | Mensagem ou registro verificável da autorização |
| Contexto | História, ciclo e ambiente não produtivo identificado |
| Operação | Ação permitida e objetos afetados |
| Limites | Filtros, identificadores, quantidade máxima e finalidade |
| Recuperação | Validação posterior e rollback/limpeza, quando aplicável |
| Validade | Condições de uso, revogação ou encerramento do ciclo |

Ausência de resposta não é autorização. Autorizações genéricas como “pode fazer tudo” não substituem a definição do escopo de escritas ou ações de alto risco. Nova operação, outro ambiente ou impacto acima do aprovado exige nova decisão.

As permissões das ferramentas, do sistema operacional e do aplicativo continuam obrigatórias. Não usar outra ferramenta ou credencial para contornar uma restrição de acesso.

## 3. Validação de ambiente — substituição proposta do gate integral

### Gate global e elegibilidade por cenário

Valide os pré-requisitos antes de iniciar cada cenário e classifique cada requisito como global ou específico. A classificação deve decorrer das dependências comprovadas, e não apenas do tipo do recurso.

- **Global:** sua ausência compromete todos os cenários ou a confiabilidade da rodada, como ambiente de destino não identificado ou impossibilidade de comprovar a versão exigida para todo o escopo.
- **Específico:** afeta somente um subconjunto identificável, como massa exclusiva, perfil adicional, integração ou mecanismo de simulação usado apenas em determinados cenários.
- **Impacto desconhecido:** investigue as dependências antes de liberar. Não assuma independência sem evidência.

Um banco ou uma credencial pode ser global ou específico conforme o mapa. Uma falha de banco não bloqueia automaticamente cenários que comprovadamente não dependem dele.

Registre `$PREREQUISITOS_EXECUCAO` com ID, escopo global/específico, cenários dependentes, fonte, evidência, status e ação pendente.

Use estes estados para o relatório de preparação:

| Estado | Critério | Efeito |
|---|---|---|
| LIBERADO PARA EXECUÇÃO | Todos os requisitos do escopo estão atendidos | Executar todos os cenários elegíveis |
| LIBERADO PARCIALMENTE | Globais atendidos; há impedimentos específicos | Executar somente a lista explícita de cenários elegíveis |
| BLOQUEADO | Há impedimento global comprovado ou nenhum cenário pode avançar | Não iniciar cenários |
| PAUSADO — AGUARDANDO DECISÃO/EVIDÊNCIA | Uma resposta é indispensável e não há trabalho independente possível | Registrar a solicitação e a condição de retomada |

`LIBERADO PARCIALMENTE` não significa aprovação funcional nem conclusão integral da rodada. O relatório deve listar cenários elegíveis, impedidos e suas dependências.

### Massas e preparação

Localize e valide primeiro as massas existentes. Gere arquivos locais de entrada quando isso estiver no escopo e não produzir efeitos externos. Prepare um plano consolidado para massas que exigirem escrita em banco.

Antes de pedir autorização, apresente cada operação concreta: ambiente, banco/schema, objeto, comando ou ação parametrizada, filtro, quantidade máxima, finalidade, impacto, forma de validação e rollback/limpeza.

Execute somente operações expressamente autorizadas. Após a escrita, releia os dados e valide quantidades, vínculos e estados. Limpeza por `DELETE` exige que essa operação também esteja expressamente coberta pela autorização.

Se uma massa não puder ser preparada, impeça os cenários dependentes e continue os independentes. Não crie estados artificiais para confirmar hipóteses de negócio.

## 4. Execução de testes — texto proposto para o Step 2.5

### Step 2.5 — Validar ambiente e determinar cenários elegíveis

Leia `00-validacao-ambiente.md`, confira a correspondência entre ambiente, versão, mapa e ciclo, e revalide itens que possam ter mudado. Aceite os estados `LIBERADO PARA EXECUÇÃO` e `LIBERADO PARCIALMENTE` respeitando a lista de elegibilidade.

1. Confirme os pré-requisitos globais. Se algum estiver pendente ou inconclusivo, não inicie a execução dependente deles.
2. Cruze cada cenário com os requisitos específicos e autorizações aplicáveis.
3. Execute os cenários elegíveis sem solicitar confirmação adicional para ações já autorizadas.
4. Registre os impedidos como `BLOQUEADO`, `INCONCLUSIVO` ou `HIPÓTESE NÃO VALIDADA`, conforme a evidência. Não classifique impedimento de ambiente como falha funcional.
5. Se surgir uma nova dependência, reavalie os cenários afetados e continue somente os que permanecerem comprovadamente independentes.
6. Após a resolução, revalide os itens afetados e retome os cenários pendentes sem repetir os já concluídos, salvo se a mudança invalidar os resultados anteriores.

Uma necessidade de escrita sem autorização impede a operação e os cenários dependentes; não bloqueia automaticamente toda a rodada.

## 5. Triagem — matriz proposta de decisão

| Situação | Comportamento após implementação |
|---|---|
| Leitura necessária no ambiente validado | Consultar sem nova confirmação, dentro do escopo e das permissões |
| Informação já disponível em fonte oficial acessível | Recuperar e validar antes de perguntar |
| Massa específica ausente | Procurar alternativas válidas; preparar plano de criação se necessário; continuar cenários independentes |
| Escrita coberta por autorização anterior | Conferir limites e pré-condições, executar e validar |
| Escrita fora da autorização | Solicitar aprovação concreta e consolidada; continuar trabalho independente |
| Exclusão ou ação irreversível/de alto risco | Exigir autorização explícita para aquela ação e seus alvos; reaproveitar somente se já cobrir exatamente o step |
| Ambiente possivelmente produtivo | Não executar probes nem escritas; solicitar identificação confiável do destino |
| Hipótese de negócio não confirmada | Consultar fontes; manter como hipótese e solicitar decisão quando indispensável |
| Ferramenta esperada indisponível | Usar somente alternativa documentada, permitida e capaz de produzir evidência equivalente; registrar a substituição |
| Ausência de mecanismo para simular uma falha específica | Impedir os cenários dependentes; executar os demais elegíveis |
| Mais de um mapa/card candidato | Aplicar vínculo ou identificador explícito do pedido; se continuar ambíguo, perguntar sem escolher por suposição |
| Relatório pronto | Entregar o artefato local; publicar externamente somente se o pedido ou autorização já cobrir o destino e a ação |

## 6. Reteste e publicação

No reteste, calcule os cenários candidatos a partir do defeito, dos arquivos alterados e das dependências conhecidas. Se a seleção estiver coberta por escopo explícito do usuário e for sustentada pelas evidências, informe a seleção e prossiga. Quando houver ambiguidade material de cobertura, apresente a lista e a justificativa para decisão antes de executar o subconjunto incerto. A seleção por categoria isolada não comprova cobertura suficiente.

A publicação do relatório exige destino inequívoco e autorização. Se o usuário já pediu explicitamente execução e publicação no card identificado, não solicite nova confirmação ao final. Se pediu apenas execução, entregue o relatório e mantenha a publicação pendente de autorização específica.

A análise de falha e a abertura de defeito só serão encadeadas quando estiverem incluídas no pedido ou em autorização explícita do fluxo. A autonomia não amplia o escopo solicitado.

## 7. Exemplos de experiência após a implementação

### Massa ausente em dois cenários

**Situação:** mapa com 20 cenários; dois dependem de um grupo inexistente.

**Mensagem esperada:** “Os pré-requisitos globais estão válidos. Vou executar os 18 cenários independentes. Para os cenários 7 e 8, preparei a operação de criação do grupo com os limites e a limpeza descritos no plano; a execução desses dois depende dessa autorização.”

O plano deve acompanhar a solicitação real. Os dois cenários permanecem pendentes até a criação e validação da massa.

### Autorização já concedida

**Situação:** o usuário aprovou a criação de até três registros com marcador do ciclo em uma tabela de HMG, incluindo a limpeza filtrada desses registros.

**Comportamento esperado:** conferir ambiente e filtros, executar dentro do limite, validar e registrar as operações. Uma quarta inclusão exige nova autorização.

### Credencial de perfil adicional ausente

**Situação:** o login padrão funciona; um cenário exige perfil adicional sem credencial disponível.

**Comportamento esperado:** executar os cenários do perfil disponível e solicitar somente a credencial/perfil adicional pelo canal autorizado, sem expor segredos nos relatórios.

### Ambiente de destino desconhecido

**Situação:** não é possível determinar se a conexão aponta para HMG ou produção.

**Comportamento esperado:** interromper o acesso a esse destino e solicitar identificação confiável. Não tentar descobrir por operações que possam afetar o ambiente.

## 8. Critérios de aceitação da alteração

- Uma autorização válida não é solicitada novamente para a mesma operação e escopo.
- Pendência específica não impede cenários comprovadamente independentes.
- Pendência global impede os cenários que dependem dela.
- Nenhuma escrita ou publicação ocorre sem autorização aplicável.
- Nenhuma alternativa contorna restrições de ferramentas ou acessos.
- Relatórios parciais distinguem resultados executados, cenários impedidos e decisões pendentes.
- Hipóteses e indisponibilidades não se tornam falhas funcionais sem evidência.
- A retomada preserva resultados válidos e revalida o que foi afetado pela mudança.

## 9. Aplicação prevista após validação deste rascunho

Atualizar as duas skills e suas versões equivalentes na raiz do projeto, quando correspondentes. Substituir todas as regras de bloqueio integral incompatíveis, alinhar a triagem, os estados de preparação, os modelos de relatório e as regras de reaproveitamento de autorização.

A implementação deve revisar referências e arquivos de apoio para que nenhuma instrução residual continue exigindo pausa integral por pendência específica. Este documento propõe o comportamento; não é uma autorização para executar escritas, publicar relatórios ou modificar ambientes.
