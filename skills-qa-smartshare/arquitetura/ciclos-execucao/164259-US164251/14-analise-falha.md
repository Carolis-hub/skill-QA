# Etapa 14 — Análise de Falha — #27 do mapa #165040 (US 164251)

- **Skill:** `/analise-falha` — cenário #27: linha com status 3 e `Data_Atualizacao` NULL não é movida para o `JOB_DUMP`
- **Data:** 2026-10-27
- **Escreveu no Azure DevOps?** Não. **Escreveu no banco?** Não.
- **Fonte da falha:** execução da etapa 13 (`13-execucao-testes.md`, `sql\28-acompanhamento-c26-c27.txt`)

# Análise de Falha — #164251 [BUG] Ajustar regra de leitura de status no BPM (cenário #27)

## O que era esperado
- **Mapa #165040, #27:** é um cenário `HIPOTESE:`, com resultado "VERIFICAR COM DEV/PO". A pergunta está no comentário da US 164251 desde a etapa 3.
- **Referência adotada (etapa 12):** o PO está de férias, então o esperado veio do Agent legado. O legado libera qualquer trava cujo dono não está mais ativo, sem olhar data (`SmartShareAgent/Agent.cs:1551`). Daí se **inferiu** que uma linha não pode travar o job para sempre: a linha com data nula deveria ser movida para o `JOB_DUMP`. Isso é inferência, não regra escrita: o legado não tem fila de itens nem coluna de data equivalente.
- **Apoio no texto da US 164251:** a descrição pede para "contemplar todos os jobs, pois o erro pode acontecer em qualquer job que fique preso com um destes status" (3, 5, 6). A US não fala nada de data de atualização nula.

## O que aconteceu
- **Visto no banco e no log (etapa 13):** a linha 43789 (job 9, status 3, `Data_Atualizacao = NULL`, sem lock) foi montada às 07:29:41.
- O NotifyWf rodou pelo menos 3 ciclos (07:30, 07:31 e 07:33) e processou normalmente os itens reais 43795–43798.
- A linha **ficou no `JOB_BPM`**: não apareceu no log do NotifyWf e não gerou registro no `JOB_DUMP`. Foi removida pela limpeza.
- **Reprodutível:** sim, com `sql\26-montagem-c26-c27.sql` (bloco do #27) e o Worker no ar por 2 ou mais ciclos do job.

## Componente relacionado
- **Lido no código** (branch `bugfix/US164251-bpm-correcao-job-travando-execucao`, commit `d9784d80`):
  - `JobBpmRepository.GetJobsTravados` (`src/3 - Core/Project.Core.Infraestructure/Repositories/JobBpmRepository.cs:186-213`) filtra por `AND Data_Atualizacao <= @Limite`, com `@Limite = agora − 60 s`. Em SQL, comparar com NULL nunca dá verdadeiro, então a linha nunca entra na busca.
  - `ClaimJobTravado` repete a mesma condição no SQL Server e no Oracle (`DBTranslator.cs:860` e `:875`). Mesmo que a busca mudasse, a reserva da linha também excluiria a data nula.
- A escolha foi deliberada no card de Análise **#164256**: só a idade de `Data_Atualizacao` distingue um item recém-terminado de um travado há dias, porque `Lock_Expira_Em` já é zerado no mesmo UPDATE que grava o status final. O caso NULL não foi tratado ali.
- **A coluna aceita nulo** no ShareGuizao (`IS_NULLABLE = YES`, sem default) e nos scripts de estrutura dos dois bancos: `Database/Desenvolvimento/1.0 Estrutura.sql:6793` (`datetime NULL`) e `Database/Oracle/1.Estrutura.sql:7505` (`TIMESTAMP(3)` sem `NOT NULL`).
- **Não foi encontrado nenhum caminho que grave nulo** no código do Agent novo:
  - os handlers do Scheduler e o `BpmExecJob` (`:513`, `:543`) sempre preenchem `DataAtualizacao`;
  - o UPDATE genérico (`JobBpmExtension.cs:233`) grava NULL só se a entidade vier com data mínima (`NullIfMinSqlDate`), e nenhum ponto de chamada nessa situação foi encontrado;
  - nenhum outro repositório do workspace grava em `JOB_BPM` (o clássico só tem a tabela nos scripts de estrutura).
- **No ambiente:** 0 linhas com data nula no `JOB_BPM` do ShareGuizao.

## Classificação
**Funcional (borda de dados), não confirmada como regra.** O código faz exatamente o que o card de Análise #164256 descreve. A divergência é com uma expectativa inferida (legado) e com a leitura ampla do texto da US ("qualquer job que fique preso com um destes status"), não com uma regra escrita para o caso nulo. Não houve exceção, erro nem comportamento técnico inesperado.

## Já existia antes?
- Busca no Azure DevOps (projeto SmartShare Arquitetura, termos "JOB_BPM Data_Atualizacao" e "job travado JOB_DUMP"): **nenhum bug** sobre data de atualização nula. Os resultados foram a Análise #164256, o mapa #165040, a US 164251 e o Bug #156951 (jobs repetidos no Step 3, sem relação com data nula).
- Antes da correção, nenhuma linha com status final era movida, nem com data preenchida. O caso nulo continua sem tratamento, mas **não piorou** com a alteração.

## Relação com a alteração atual
**Sim, direta.** A condição `Data_Atualizacao <= @Limite` foi introduzida pelo PR 29707 (`GetJobsTravados`, `ClaimJobTravado`) e é o que deixa a linha de fora. É uma lacuna de borda da própria correção, não uma regressão de outra área.

## Veredito
**NÃO — evidência insuficiente para abrir defeito.**

O obtido está comprovado e é reprodutível, mas faltam duas coisas:
1. **O esperado não é regra confirmada.** O #27 é `HIPOTESE:` no mapa, e o esperado adotado foi inferido do legado, que não tem um caso equivalente. Pela regra da skill, hipótese não confirmada não vira defeito.
2. **Não há evidência de que a condição ocorra na prática.** Não foi encontrado caminho no código que grave `Data_Atualizacao` nula, e há 0 linhas nulas no ambiente. Hoje, a linha só existe se for inserida à mão.

## O que coletar para reabrir a decisão
- **Dev (Vinicius, responsável pela US):** confirmar se existe algum caminho que grave `JOB_BPM.Data_Atualizacao` nula (script de suporte, carga, migração, outra aplicação, Oracle) e se a busca deveria tratar o nulo. Por exemplo, usar `COALESCE(Data_Atualizacao, Data_Criacao)` ou tratar NULL como travado. A decisão de como corrigir é do dev.
- **PO, na volta das férias:** responder a hipótese #27 no comentário da US 164251.
- **Opcional, em HMG ou na base de algum cliente com autorização:** contar quantas linhas têm `Data_Atualizacao IS NULL` no `JOB_BPM`. Se houver, é evidência de que o caso acontece na prática.
- Se o dev ou o PO confirmarem que a linha deve ser movida, **o #27 vira defeito** com a evidência desta análise e da etapa 13, sem precisar reexecutar.

## Efeito no placar
O #27 continua **Falhou** contra o esperado inferido, com veredito de defeito **NÃO** por enquanto. Na prática, fica como **achado de borda para o dev**, junto com os demais achados do README do ciclo.
