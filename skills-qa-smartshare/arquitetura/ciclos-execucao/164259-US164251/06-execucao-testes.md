# Etapa 06 — Execução de Testes (com escrita no banco) — #164251 [BUG] Ajustar regra de leitura de status no BPM

- **Skill:** `/executar-teste 164251` — continuação da etapa 05, para os cenários que exigiam escrita
- **Data:** 2026-10-26 15:44–15:49
- **Escreveu no Azure DevOps?** Não
- **Escreveu no banco?** **Sim, com autorização explícita do usuário no chat** (Guilherme Henrique Correa Borges, 2026-10-26). É exceção a duas regras: a skill `/executar-teste` proíbe INSERT, UPDATE e DELETE, e o `CLAUDE.md` diz que quem executa script é humano.
- **Ambiente:** SQL Server `NOTE-74VQ\SQLEXPRESS`, base `ShareGuizao` (QA local, não HMG), login integrado do Windows, sem uso de senha.
- **Worker:** BPM em console (PID 21788), branch do PR 29707, commit `d9784d80`; jobs 8 (AvancoTemporal) e 9 (NotifyWf) com ciclo a cada minuto, no segundo :02.

## Scripts e saídas (pasta `sql\`)
- `06-montagem-cenarios.sql`: montagem, em uma transação. Saída em `06-montagem-saida.txt`.
- `08-acompanhamento.txt`: estado de `JOB_BPM` e `JOB_DUMP` a cada 10 s, de 15:44:32 a 15:49:10.
- `07-limpeza-cenarios.sql`: remove a linha do #19. Saída em `07-limpeza-saida.txt` (1 linha removida; 0 linhas `qa-us164251-` restantes no `JOB_BPM`).

Linhas criadas às 15:44:20,653 (todas com `Chave_Unica` iniciando em `qa-us164251-`):

| Cenário | Id | Job | Status | Montagem |
|---|---|---|---|---|
| #2 | 40046 | 8 | 5 | `Data_Atualizacao` 5 min atrás, sem lock |
| #8/#9 | 40047 | 9 | 3 | `Data_Atualizacao` = agora |
| #10 | 40048 | 8 | 3 | 5 min atrás, lock válido até 15:47:20 |
| #14 | 40049 | 9 | 3 | 5 min atrás, sem lock, **mais** 1 registro já no `JOB_DUMP` com o mesmo Id_Origem |
| #19 | 40050 | 8 | 2 | Executando, lock válido até 2026-10-27 15:44:20 |

## Resultado por cenário

| # | Cenário | Resultado | Evidência |
|---|---|---|---|
| 2 | Travado com Envenenado (5) é movido | **Passou** | Movido no primeiro ciclo (15:45:02). 1 dump status 5, sem lock. Log: `Job AvancoTemporal (Id: 40046, ChaveUnica: qa-us164251-c2-envenenado) estava travado com status final 5 e foi movido para JOB_DUMP, por ja ter sido processado anteriormente.` |
| 8 | Recém-finalizado (<60 s) não é travado | **Passou** | No ciclo das 15:45:02 a linha tinha ~42 s e continuou no `JOB_BPM` (acompanhamento 15:45:10–15:46:00). Nenhum log de travado nesse ciclo |
| 9 | Logo acima de 60 s é movido | **Passou** | Movido no ciclo das 15:46:02, com ~102 s. 1 dump status 3, sem lock. Log "status final 3" com Id 40047 |
| 10 | Status final com lock válido não é movido | **Passou** | Ficou no `JOB_BPM` nos ciclos das 15:45, 15:46 e 15:47, com o lock válido até 15:47:20. Movido no ciclo das 15:48:02, o primeiro depois do vencimento. 1 dump status 3; log "status final 3" com Id 40048 |
| 14 | Linha travada que já tem registro no dump | **Passou** | Saiu do `JOB_BPM` no ciclo das 15:45:02. Continua 1 único dump (o pré-existente, `Data_Dump` 15:44:20). Log: `Job NotifyWf (Id: 40049, ChaveUnica: qa-us164251-c14-ja-no-dump) ja tinha sido movido para JOB_DUMP por outra execucao concorrente - a linha que sobrou no JOB_BPM foi removida.` |
| 19 | Executando com lock válido não é tocado | **Passou** | Continuou no `JOB_BPM` com status 2 e lock intacto em todos os 5 ciclos (15:45–15:49). Nenhuma linha de log com o Id 40050. Removida depois pela limpeza |

Em todo o período: 0 linhas ERROR no log dos jobs; nenhum Id_Origem com mais de 1 dump.

## Observação sobre a hipótese #28
O cenário #14 produziu a mensagem `ja tinha sido movido para JOB_DUMP por outra execucao concorrente`, **sem nenhuma concorrência** (havia uma instância só e o dump foi montado por script). Isso confirma na prática o ponto da hipótese #28: o texto do log não descreve o caso real. Continua sendo decisão de dev/PO se isso atende o CA3.

## Placar acumulado da execução (etapas 05 + 06)
- **Passou:** 11 (#2, #3, #8, #9, #10, #11, #13, #14, #17, #19, #20)
- **Passou parcial:** 4 (#1, #5, #7, #23)
- **Falhou:** 0
- **Não executado:** 8 (#4, #6, #15, #18, #21, #22, #24, #25)
- **Hipótese:** 3 (#26, #27, #28) · **N/A:** 2 (#12, #16)

## Double-check
Não rodei sub-agente para esta etapa. Os 6 cenários têm evidência direta e dupla (tempo de saída do `JOB_BPM` no acompanhamento de 10 em 10 s, mais a linha de log com Id e status). Se quiser, o double-check independente pode ser rodado sobre este arquivo.

## Pendências
1. Rechecar depois da 00:00 de 2026-10-27 o Id 6686 (job 32, Cancelado): completa o #1.
2. Os 8 não executados precisam de outra coisa além de escrita no banco:
   - #4: Scheduler apontando para o SQL Server;
   - #15: segunda instância do Worker;
   - #6 e #24: mudar o `JOB_CONFIG`;
   - #18, #21 e #22: provocar falha (scripts break/restore);
   - #25: Worker de ECM.
3. Completar os parciais #5 (efeito de negócio) e #23 (NotifyWf em ciclos diferentes).
4. Resposta de dev/PO às hipóteses #26, #27 e #28 (o #28 agora tem evidência prática).
5. Rodada funcional no HMG.
