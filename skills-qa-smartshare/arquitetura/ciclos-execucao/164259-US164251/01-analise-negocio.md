# Etapa 1 — Análise de Negócio — #164251 [BUG] Ajustar regra de leitura de status no BPM

- **Skill:** `/analise-negocio 164251` (somente leitura)
- **Data:** 2026-10-26
- **Fontes lidas:** campos da US 164251 (título, descrição, critérios de aceite dentro da descrição). Sem comentários na US no momento da análise.

**Projeto:** SmartShare Arquitetura | **Tipo:** Product Backlog Item | **Status:** Committed (coluna "Análise" no quadro)

> O card é do projeto **SmartShare Arquitetura**, não do `SHARE-4`. A correção está no PR 29965 (repositório `smartshare-net8`). O campo "Critérios de aceite" está vazio: os critérios estão dentro da descrição.

## Objetivo da alteração
Evitar que um item preso na tabela BPM com status final (Sucesso, Envenenado ou Cancelado), que nunca foi movido para a tabela DUMP, trave os novos processamentos daquele job. O BPM passa a buscar esses itens, movê-los para a DUMP e registrar em log o ocorrido. (descrição)

## Comportamentos esperados (contratos verificáveis)
- Quando existir na tabela BPM um item de um job com status **Sucesso (3)** que não foi para a DUMP, o BPM deve carregar esse item na busca de itens para processar. (descrição, "Como ajustar")
- Quando existir um item com status **Envenenado** ou **Cancelado**, o BPM deve carregá-lo da mesma forma. (descrição, "Como ajustar")
- Quando o BPM carregar um item com status Sucesso, Envenenado ou Cancelado, deve **movê-lo para a tabela DUMP**, sem executar o job de novo. (descrição e critério de aceite 2)
- Quando o item for movido para a DUMP por essa regra, o sistema deve **logar** as informações do processo, deixando claro que era um item já processado antes e que não tinha sido movido para a DUMP. (descrição e critério de aceite 3)
- Depois que o item preso for movido, o Scheduler deve **voltar a agendar** novos itens daquele job, e o processamento não pode mais travar. (critério de aceite 2)
- A correção deve valer para **todos os jobs**, não só para o `EnviaAlertaFluxo`. (critério de aceite 4)
- A correção não pode criar novos defeitos. (critério de aceite 1)

## Regras explícitas
- Status **3 = Sucesso**. (descrição)
- Os status a incluir na busca do BPM são **Sucesso, Envenenado e Cancelado**. (descrição)
- Item carregado com esses status → mover para a tabela DUMP. (descrição)
- O Scheduler não agenda um item novo se já existe uma linha do job na tabela BPM, e não sobrescreve essa linha. É o comportamento atual que causa o travamento. (descrição)
- Hoje o BPM não executa itens com status 3, porque esse status não está entre os que o job carrega. (descrição)
- O ajuste precisa cobrir todos os jobs. (critério de aceite 4)

## Regras implícitas
- **IMPLÍCITA:** um item com status final **não pode ser executado de novo**. A descrição pede só para "mover para a tabela DUMP", e o item já foi "processado anteriormente". Executar de novo duplicaria efeitos (por exemplo, mandar o alerta duas vezes).
- **IMPLÍCITA:** itens com os status que o BPM já carregava continuam sendo **executados normalmente**.
- **IMPLÍCITA:** o comportamento de movimentação para a DUMP no caminho normal (item termina e é movido) não deve mudar. Vem do critério "não criar novos bugs".
- **IMPLÍCITA:** o log tem que permitir **distinguir** um item movido por essa recuperação de um item movido no fluxo normal.

## Condições e exceções
- **Situação que dispara a regra:** item com status final que não chegou à DUMP (parada do processo ou queda de VPN no momento da movimentação). (descrição)
- **Status cobertos:** só Sucesso, Envenenado e Cancelado. (descrição)
- **Escopo:** qualquer job, não só `EnviaAlertaFluxo`. (critério de aceite 4)

## Dependências
- **Scheduler**: deixa de agendar enquanto existe a linha presa. (descrição)
- **Motor BPM**: a busca de itens para processar. (descrição)
- **Tabelas BPM e DUMP.** (descrição)
- **Job `EnviaAlertaFluxo` (AlertaFluxo)**: cenário onde o problema foi visto. (descrição)
- **Correção vinculada**: PR 29965 e um commit "Fixed in Commit". (relações)
- **Cards filhos**: Análise 164256 (Done), Desenvolvimento 164257 (Done), Code Review 164258 (Done) e Testes 164259 (Committed).

## Informações ausentes
- Informação não encontrada / necessita validação: valores numéricos dos status Envenenado e Cancelado. *(Respondido na etapa 2: 5 e 6.)*
- Informação não encontrada / necessita validação: quais informações exatas devem entrar no log.
- Informação não encontrada / necessita validação: "todos os jobs" são todos os jobs do BPM ou existe uma lista?
- Informação não encontrada / necessita validação: se houver mais de uma linha presa do mesmo job, todas devem ser movidas no mesmo ciclo?
- Informação não encontrada / necessita validação: depois de mover o item preso, o novo item deve ser agendado no mesmo ciclo ou só no ciclo seguinte do Scheduler?

## Ambiguidades
- **"Mover para a tabela DUMP"**: copiar e apagar da BPM, ou só copiar. O objetivo de destravar sugere apagar.
- **"Garantir que o ajuste não criei novos bugs"**: vago, não diz qual regressão verificar.
- **"Buscar itens para processar"**: os status finais podem entrar na mesma busca ou numa varredura separada. Para o teste importa o efeito.

## Riscos identificados
- Reexecução de item já concluído (alerta duplicado no `EnviaAlertaFluxo`).
- Correção parcial: funciona para o `EnviaAlertaFluxo` e não para os outros jobs.
- Status esquecido: Envenenado ou Cancelado de fora.
- Regressão no fluxo normal ao incluir status novos na busca.
- Log insuficiente para distinguir a recuperação de uma movimentação normal.
- Reproduzir o cenário exige escrita direta no banco, que precisa de autorização.
