# Etapa 12 — Hipóteses #26–#28 comparadas com o Agent legado — #164251

- **Origem:** pedido do usuário em 2026-10-27. O PO está de férias, a pergunta das hipóteses continua no card da US 164251 (comentário da etapa 3) e os testes seguem tomando o **Agent legado** como referência.
- **Escreveu no Azure DevOps?** Não. **Escreveu no banco?** Não (só leitura do schema de `JOB_BPM`).
- **Fonte:** `SmartShareAgent/Agent.cs` e `SmartShareAgent/NotifyWF.cs`, no repositório clássico (`D:\Projeto Share\SmartShare`). Tudo abaixo foi **lido no código**, sem execução do legado.

## Como o legado controla as rotinas (lido no código)
- **Não existe fila por item.** O legado não usa `JOB_BPM` nem `JOB_DUMP` (nenhuma referência no código C#). Cada rotina tem um `Timer` próprio (`Agent.cs:144-170`) e, a cada disparo, lê direto as tabelas de negócio. Por exemplo, o alerta de fluxo lê `ALERTA_PROCESSO`/`FLUXO_ALERTA` em `NotifyWF.cs:2165`.
- **A trava é por rotina, não por item.** Antes de rodar, `AssumeTaskDisponivel` (`Agent.cs:1480`) faz um `UPDATE STATUS_AGENT ... st_executando = 1, hash_id = <instância> WHERE cd_status_agent = <job> AND (st_executando <> 1 OR hash_id = <instância>)`. Ao terminar, `DesassociarTask` (`Agent.cs:1506`) volta `st_executando = 0`.
- **Recuperação de trava presa:** `RealizaControleAgent` (`Agent.cs:1527`, a cada 5 min, fixo) mantém um sinal de vida por instância em `AGENT_ID`. Uma instância sem sinal de vida é removida, e **toda trava de `STATUS_AGENT` cujo dono não está mais vivo é liberada** (`Agent.cs:1551`). A liberação depende só de o dono estar morto, não de data da rotina.
  - **Peculiaridade:** o teste de inatividade usa `.Minutes >= 7` (`Agent.cs:1546`), que lê só o componente de minutos do intervalo. Uma instância parada há 1 h 05 min tem `Minutes = 5` e não seria removida nesse ciclo. Isso é do legado e **não deve ser replicado**.
- **Convivência com o Agent novo:** `UsarNovoAgent` (`Agent.cs:1855`) faz o legado pular o job quando ele está com `Ativo = 1` no `JOB_CONFIG`. Os dois nunca rodam o mesmo job ao mesmo tempo.
- **Sem limite de lote:** as rotinas processam tudo o que está pendente no ciclo. Exemplos: `NotificaAlertaFluxo` percorre todos os alertas configurados e `ExecutaSQL` divide a lista inteira em 2 threads (`Agent.cs:1000-1018`). Não há `TOP`/`ROWNUM` nessas rotinas.
- **Sem log de recuperação:** liberar uma trava presa (`Agent.cs:1551`) e não conseguir assumir a rotina (`AssumeTaskDisponivel` retorna `false`) não gravam nenhuma linha de log.

## Hipóteses: referência adotada

| # | Hipótese | O que o legado faz | Esperado adotado para o teste | Rótulo |
|---|---|---|---|---|
| 26 | Várias linhas travadas do mesmo job no mesmo ciclo | Não há fila. Num ciclo, a rotina trata tudo o que está pendente, sem limite de quantidade | **As 3 linhas (status 3, 5 e 6) são movidas no mesmo ciclo.** Bate com o código novo, que também não limita | Lido no código (legado e novo) |
| 27 | Status final com `Data_Atualizacao` nula | O legado não tem o conceito de data da linha. A trava sem dono vivo é sempre liberada, sem depender de horário: **nada fica travado para sempre** | **A linha não deve bloquear o job para sempre**: o esperado é ser movida para o `JOB_DUMP`. Pelo código novo (`Data_Atualizacao <= agora − 60 s`), uma data nula nunca é pega, então o **resultado provável é falha**. No ShareGuizao a coluna aceita nulo (`IS_NULLABLE = YES`, sem default) e hoje há 0 linhas nulas | Esperado por **inferência** a partir do princípio do legado. Não é regra escrita |
| 28 | Texto do log "já movido" fala em concorrência sem concorrência | O legado não registra nada ao recuperar trava presa | **Não conta como falha de paridade.** O novo registra mais que o legado e o CA3 pede só "informações relevantes". O texto "por outra execucao concorrente" fica como **observação de redação** para o dev, porque é enganoso | Lido no código. Hipótese confirmada na prática no #14 (etapa 6) |

## Consequência para a execução
- **#26:** pode ser executado agora (montar 3 linhas travadas no mesmo job, com escrita no banco autorizada).
- **#27:** pode ser executado (1 linha status 3 com `Data_Atualizacao = NULL`). Se o código novo não mover a linha, o resultado é **Falhou**, tomando o legado como referência. Isso vira defeito para `/analise-falha`, com a ressalva de que a regra é inferida e o PO ainda vai confirmar.
- **#28:** fica como **Passou** pela referência do legado, com a observação de redação registrada para o dev.
- O registro da hipótese continua no card da US 164251, para o PO responder na volta. Se ele divergir do legado, os cenários #26–#28 são reavaliados.
