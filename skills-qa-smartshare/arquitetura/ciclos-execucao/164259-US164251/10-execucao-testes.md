# Etapa 10 — Execução de Testes — cenários #6, #24, #22 e #25 — #164251

- **Skill:** `/executar-teste 164251`, continuação: "executar todos os testes restantes"
- **Data:** 2026-10-26 16:40–17:00
- **Escreveu no Azure DevOps?** Não
- **Escreveu no banco?** **Sim, com autorização explícita do usuário no chat** (Guilherme Henrique Correa Borges): 13 linhas em `JOB_BPM` e alteração temporária do `JOB_CONFIG`, já restaurada.
- **Ambiente:** SQL Server `NOTE-74VQ\SQLEXPRESS`, base `ShareGuizao` (QA local, não HMG).

## Pré-condições verificadas
- **O Worker BPM só lê o `JOB_CONFIG` na inicialização** (`Worker.cs`: agenda no Quartz os jobs com `Ativo = 1`, uma instância por `Max_Paralelo`). Alterar o `JOB_CONFIG` exige reiniciar o Worker.
- **Ativar o job 19 é seguro:** a consulta de pendências do ExecutaSql (`TarefaService.ListarPendenciasExecutaSql`) retorna **0** neste banco. Nenhum SQL real de processo seria enfileirado.
- **`JOB_CONFIG`:** quando o backup foi tirado (16:53), o usuário já tinha alterado o job 9 (`Max_Paralelo` 1 → 2) e o job 19 (`Ativo` 0 → 1). Os `UPDATE` de `sql\17-jobconfig-alteracao.sql` afetaram 0 linhas. Os valores originais estão em `sql\17-jobconfig-nota.txt`.

## Execução de #6 e #24
1. `sql\19-montagem-c6-c24.sql` às 16:53:35:
   - Id **41009**: job 19, status 3, travado (#6);
   - Ids **41010–41021**: 12 itens Agendados do job 9, `{"NotifyStep":8}`, cada um com chave e chave de concorrência próprias (#24).
2. O Worker BPM antigo (PID 21788, iniciado pelo usuário às 14:34) foi encerrado às 16:53:52, antes do ciclo das 16:54:02. Um novo foi subido às 16:53:53 a partir do mesmo executável (PID 22844), lendo o `JOB_CONFIG` alterado.

### #6 — Limpeza no ExecutaSql (job 19)
- 16:54:32,89 `Job ExecutaSql (Id: 41009, ChaveUnica: qa-us164251-c6-executasql-travado) estava travado com status final 3 e foi movido para JOB_DUMP, por ja ter sido processado anteriormente.`
- `JOB_DUMP`: 1 registro com status 3; nada sobrou no `JOB_BPM`.

| # | Resultado | Evidência |
|---|---|---|
| 6 | **Passou** | Movido no primeiro ciclo do job 19, com log e 1 dump |

### #24 — Execução paralela por instâncias (job 9 com `Max_Paralelo` = 2)

| Hora | Id | Instância |
|---|---|---|
| 16:54:33,83 | 41010 | 2 |
| 16:54:33,88 | 41011 | 1 |
| 16:54:34,11 | 41012 | 2 |
| 16:54:34,18 | 41014 | 1 |
| 16:54:34,37 | 41013 | 2 |
| 16:54:34,43 | 41016 | 1 |
| 16:54:34,63 | 41015 | 2 |
| 16:54:34,69 | 41018 | 1 |
| 16:54:34,95 | 41017 | 2 |
| 16:54:35,05 | 41020 | 1 |
| 16:54:35,24 | 41019 | 2 |
| 16:54:35,57 | 41021 | 2 |

- **Divisão:** 5 itens na instância 1 e 7 na instância 2. Cada Id tem exatamente 1 "Iniciando processamento" e 1 "executado com sucesso".
- **Banco:** os 12 têm 1 dump cada (status 3, 0 tentativas), nada sobrou no `JOB_BPM`, 0 ERROR.

| # | Resultado | Evidência |
|---|---|---|
| 24 | **Passou** | 2 instâncias processando a mesma fila em paralelo; cada item executado uma única vez; nenhum dump duplicado |

### Restauração
- `sql\20-jobconfig-restauracao.sql`: job 19 `Ativo = 0`; job 9 `Max_Paralelo = 1` (saída em `20-jobconfig-restauracao-saida.txt`).
- O Worker do teste (PID 22844) foi encerrado e um novo foi subido às 16:57:20 (PID 39784) com a configuração restaurada. Conferido às 16:58:50: ExecutaSql sem nenhum ciclo (job 19 inativo), NotifyWf só com a instância 1, demais jobs rodando a cada minuto.
- **Atenção:** o Worker BPM agora roda como processo iniciado por esta sessão, não mais na janela de console original do usuário.

## #22 — Exceção no EnviaAlertaFluxo não vira Sucesso: não executado
- **Código:** na branch testada **e na `main` atual** (conferido no Azure DevOps), o `catch` do `EnviaAlertaFluxoExecHandler` termina com `jr.Sucesso = true`. O próprio código documenta que isso é intencional: *"Mantendo a regra do clássico, o envio é feito por perfil, por isso, caso ocorra erro no envio de email para algum dos participantes, o processo é marcado com sucesso e não será reagendado."* Nenhum commit cita o Bug 157977.
- **Conflito:** o resultado esperado do #22 no mapa ("não fica com status 3"), que veio do histórico do Bug 157977, contradiz essa regra. Executar o cenário só confirmaria o status 3 por desenho. É uma divergência de regra, não um defeito desta US.
- **Risco de executar:** mudar o horário do job 32 faria o Worker processar o item real 39820 (Agendado desde 22/09) com **16 alertas de fluxo vencidos** (14 fluxos, 8 destinos por papel). A configuração de e-mail é OAuth com o remetente do usuário, então seriam **e-mails reais** para membros dos papéis, além de atualizar as datas no `FLUXO_ALERTA`. O horário do job 32 **não foi alterado** sem confirmação específica do usuário.
- **Decisão pendente:** PO/dev confirmar qual é a regra válida e, se o cenário continuar no mapa, ajustar o resultado esperado. A execução precisa de confirmação explícita do envio real de alertas, ou de uma massa de alertas com destinatários de teste.

## #25 — ECM não muda de comportamento: não executado (ambiente)
- **Situação:** o Worker de ECM do usuário (`Project.Agent.Worker.Ecm.exe`, PID 31000, iniciado às 16:37:58) está rodando, mas **não agendou nenhum job**. O log mostra "Adding 0 jobs, 0 triggers" e não registra "Iniciando worker/Ecm".
- **Causa (código + config):** `Worker.cs` sai no início quando `AppConfig.StAtivo` é falso. O `appsettings.json` do ECM só tem a seção `Logging`: sem `ConnectionStrings`, `DBType` ou `AppConfig`.
- **Não foi corrigido nesta sessão:** a correção exigiria copiar a connection string e a chave de criptografia para um arquivo versionado do repositório.
- **Para destravar:** o usuário configura o `appsettings` do ECM como fez com o BPM e o Scheduler e reinicia o ECM. `JOB_ECM` está vazio, e não há dump ECM hoje.

## Placar acumulado da execução (etapas 05 a 10)
- **Passou:** 17 (#2, #3, #4, #6, #8, #9, #10, #11, #13, #14, #15, #17, #18, #19, #20, #21, #24)
- **Passou parcial:** 4 (#1, #5, #7, #23)
- **Falhou:** 0
- **Não executado:** 2 (#22: conflito de regra e risco de e-mail real; #25: Worker ECM sem configuração)
- **Hipótese:** 3 (#26, #27, #28) · **N/A:** 2 (#12, #16)

## Dados deixados no ambiente
13 linhas `qa-us164251-c6/c24` no `JOB_DUMP`. Nenhuma linha de teste no `JOB_BPM`. `JOB_CONFIG` restaurado. `EMAIL_CONFIGURACAO` e o job 32 não foram alterados.
