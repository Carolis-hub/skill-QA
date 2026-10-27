# Etapa 13 — Execução de Testes — hipóteses #26 e #27 (referência: Agent legado) — #164251

- **Skill:** `/executar-teste 164251`, continuação. O PO está de férias, então o esperado vem do Agent legado (etapa 12).
- **Data:** 2026-10-27 07:29–07:35
- **Escreveu no Azure DevOps?** Não
- **Escreveu no banco?** **Sim, com autorização explícita do usuário no chat** (Guilherme Henrique Correa Borges): 4 linhas em `JOB_BPM` com a chave `qa-us164251-c26/c27`. A do #27 foi removida pela limpeza; as do #26 ficaram no `JOB_DUMP` como evidência.
- **Ambiente:** SQL Server `NOTE-74VQ\SQLEXPRESS`, base `ShareGuizao` (QA local, não HMG). Worker BPM em console (branch do PR 29707, commit `d9784d80`), subido pela sessão às ~07:29:50 e encerrado às ~07:35. `JOB_CONFIG` sem alteração: jobs 8 e 9 ativos, a cada 60 s, `Max_Paralelo = 1`.

## Montagem (`sql\26-montagem-c26-c27.sql`, saída em `sql\26-montagem-c26-c27-saida.txt`, 07:29:41)

| Cenário | Id | Job | Status | Data_Atualizacao | Lock |
|---|---|---|---|---|---|
| #26 | 43786 | 8 (AvancoTemporal) | 3 | agora − 5 min | sem |
| #26 | 43787 | 8 | 5 | agora − 5 min | sem |
| #26 | 43788 | 8 | 6 | agora − 5 min | sem |
| #27 | 43789 | 9 (NotifyWf) | 3 | **NULL** | sem |

## Resultado (`sql\28-acompanhamento-c26-c27.txt`)

### #26 — várias linhas travadas do mesmo job no mesmo ciclo — **Passou**
- **Esperado (legado, etapa 12):** as 3 movidas no mesmo ciclo, sem limite de lote.
- **Obtido:** no primeiro ciclo do job 8, as 3 foram movidas em 130 ms (07:30:10,90 → 07:30:11,03), na ordem dos Ids:
  - log `Job AvancoTemporal (Id: 43786, ChaveUnica: qa-us164251-c26-sucesso) estava travado com status final 3 e foi movido para JOB_DUMP…`;
  - o mesmo para 43787 (status 5) e 43788 (status 6).
- `JOB_DUMP`: 1 registro para cada Id, com o status correto (3, 5, 6); 0 duplicados. 0 linhas `ERROR`.

### #27 — status final com `Data_Atualizacao` nula — **Falhou** (contra o esperado inferido do legado)
- **Esperado (inferido do legado, etapa 12):** a linha não pode travar o job para sempre, então deveria ser movida para o `JOB_DUMP`.
- **Obtido:** depois de pelo menos 3 ciclos do job 9 (07:30, 07:31 e 07:33, em que o NotifyWf processou normalmente os itens reais 43795–43798), a linha **43789 continuou no `JOB_BPM`** com status 3, `Data_Atualizacao = NULL` e sem lock. O Id não aparece no log do NotifyWf (0 ocorrências) e não foi criado registro no `JOB_DUMP`.
- **Causa provável (lida no código, sem confirmação do dev):** a busca de travados exige `Data_Atualizacao <= agora − 60 s`. Comparar com NULL nunca dá verdadeiro, então a linha nunca entra na busca.
- **Impacto:** uma linha assim, com a mesma `Chave_Unica` do agendamento fixo, reproduziria o bug original: o Scheduler não insere o próximo item e o job fica travado para sempre.
- **Probabilidade:** no ShareGuizao a coluna aceita nulo (`IS_NULLABLE = YES`, sem default), mas hoje há 0 linhas com data nula. As linhas criadas pelo Scheduler que vimos nesta rodada sempre tinham `Data_Atualizacao` preenchida. Não se sabe se algum caminho do sistema grava nulo.
- **Ressalva:** o esperado foi **inferido** do princípio do legado ("trava sem dono vivo é sempre liberada"). Não é uma regra escrita. A hipótese continua no card da US para o PO confirmar na volta.
- **Próximo passo:** `/analise-falha` antes de qualquer defeito.

### #28 — texto do log "já movido" — **Passou** pela referência do legado (sem nova execução)
- Já executado na prática no #14 (etapa 6). O legado não registra nada ao recuperar trava presa, então registrar mais não quebra a paridade.
- **Observação para o dev:** o texto "por outra execucao concorrente" é enganoso quando não houve concorrência.

## Limpeza (`sql\27-limpeza-c26-c27.sql`, saída em `sql\27-limpeza-c26-c27-saida.txt`)
- 1 linha removida (43789, #27). Restam 0 linhas `qa-us164251-*` no `JOB_BPM`.
- Os dumps do #26 (43786–43788) ficaram no `JOB_DUMP` como evidência, como nas etapas anteriores.
- Worker BPM da sessão encerrado. Nenhum processo `BpmWorker` ficou rodando. O Scheduler (PID 36280) e o Worker ECM (PID 31000) do usuário não foram tocados.

## Placar final da rodada 1 (27 cenários)
- **Passou:** 20 (#1, #2, #3, #4, #6, #8, #9, #10, #11, #13, #14, #15, #17, #18, #19, #20, #21, #24, #26, #28)
- **Passou parcial:** 3 (#5, #7, #23)
- **Falhou:** 1 (#27, contra o esperado inferido do legado)
- **Não executado:** 1 (#22, porque a falha de envio não ocorreu)
- **N/A:** 2 (#12, #16)
