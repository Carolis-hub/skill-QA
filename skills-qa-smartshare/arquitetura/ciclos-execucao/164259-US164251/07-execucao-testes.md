# Etapa 07 — Execução de Testes — cenário #15 (concorrência) — #164251 [BUG] Ajustar regra de leitura de status no BPM

- **Skill:** `/executar-teste 164251`, continuação: cenário #15
- **Data:** 2026-10-26 15:52–15:57
- **Escreveu no Azure DevOps?** Não
- **Escreveu no banco?** **Sim, com autorização explícita do usuário no chat** (Guilherme Henrique Correa Borges), mesma exceção da etapa 06.
- **Ambiente:** SQL Server `NOTE-74VQ\SQLEXPRESS`, base `ShareGuizao` (QA local, não HMG), login integrado do Windows.

## Montagem
- **Instância 1:** Worker BPM em console já em execução (PID 21788, branch do PR 29707, commit `d9784d80`). Ciclo do job 8 no segundo :02.
- **Instância 2:** o mesmo executável, subido às 15:53:58,9 com `NLOG_LOGROOT` apontando para `evidencias\worker2-log` (logs separados por instância). A aplicação iniciou às 15:54:09 e o ciclo do job 8 ficou no segundo :12. Encerrada às ~15:57 (PID 31164).
- **Scheduler:** havia também um Scheduler em console apontando para o SQL Server (PID 36280, iniciado às 15:16:32 pelo usuário). Não interfere no job 8, que não recebe itens novos.

## Tentativa 1 — 30 itens (sem sobreposição)
- `sql\09-montagem-c15.sql`: 30 linhas status 3 no job 8 (Ids 40097–40126), criadas às 15:53:10.
- A instância 1 moveu os 30 entre 15:54:02,64 e 15:54:03,68. A instância 2 fez o primeiro ciclo às 15:54:12 e encontrou a fila vazia.
- Resultado correto (30 dumps, nenhum duplicado, 0 restantes), mas **sem disputa**: não vale como evidência de concorrência.

## Tentativa 2 — 600 itens (com sobreposição)
- **Montagem:** `sql\10-montagem-c15-carga.sql` criou 600 linhas status 3 no job 8 (Ids 40142–40741) às 15:55:24, para a varredura da instância 1 durar mais de 10 s e alcançar o ciclo da instância 2.
- **Instância 1:** moveu **435** itens, de 15:56:02,64 a 15:56:18,20.
- **Instância 2:** moveu **165** itens, de 15:56:11,64 a 15:56:18,21.
- **Sobreposição:** ~6,6 s com as duas instâncias varrendo a mesma lista. No log as duas se alternam Id a Id, por exemplo:
  ```
  15:56:11.6006 inst1 Id 40457
  15:56:11.6303 inst1 Id 40458
  15:56:11.6421 inst2 Id 40459
  15:56:11.6433 inst1 Id 40460
  15:56:11.6715 inst2 Id 40461
  15:56:11.7023 inst2 Id 40462
  15:56:11.7123 inst1 Id 40463
  ```
- **Conferência (log + banco):**
  - Ids registrados nas **duas** instâncias: **0**; Ids distintos somando as duas: 600;
  - 600 Ids com dump, 600 dumps no total (**nenhum duplicado**);
  - **0** linhas restantes no `JOB_BPM` (nenhuma órfã);
  - 0 dumps com `Lock_Id`/`Lock_Expira_Em` preenchidos;
  - 0 mensagens "ja tinha sido movido" ou "Erro ao mover";
  - 0 linhas ERROR nas duas instâncias.

## Resultado

| # | Cenário | Resultado | Evidência |
|---|---|---|---|
| 15 | Duas instâncias pegam o mesmo item travado | **Passou** | Disputa real de ~6,6 s sobre 600 itens: cada item foi movido por uma única instância, 1 dump por item, nenhum item órfão, sem erro |

## Placar acumulado da execução (etapas 05 + 06 + 07)
- **Passou:** 12 (#2, #3, #8, #9, #10, #11, #13, #14, #15, #17, #19, #20)
- **Passou parcial:** 4 (#1, #5, #7, #23)
- **Falhou:** 0
- **Não executado:** 7 (#4, #6, #18, #21, #22, #24, #25)
- **Hipótese:** 3 (#26, #27, #28) · **N/A:** 2 (#12, #16)

## Dados deixados no ambiente
630 linhas `qa-us164251-c15*` no `JOB_DUMP` (job 8), movidas pelo próprio Worker. Ficam como evidência; nenhuma linha de teste sobrou no `JOB_BPM`.

## Pendências atualizadas
- **#4 (agendamento volta depois da limpeza):** agora existe um Scheduler em console apontando para o SQL Server (PID 36280). O cenário pode ser executado no job 32 à meia-noite, ou em outro job com chave fixa de agendamento.
- **Demais não executados:**
  - #6 e #24: mudar o `JOB_CONFIG`;
  - #18, #21 e #22: provocar falha;
  - #25: Worker de ECM.
