# Etapa 05 — execucao-testes (PR 30253 / #161839, Oracle) — #161711 Bugs Instaladores

- **Skill e argumentos:** `/arquitetura-executar-teste 161711`, rodada 1 de 5 (um PR por vez). PR 30253 (#161839, net8), banco Oracle `SHAREGUIZAO`.
- **Data:** 2026-11-06
- **Escreveu no Azure DevOps:** Não
- **Status:** **PARCIAL** — 1 cenário executado, 7 pendentes.
- **Ambiente:** local do QA (não HMG; é o ambiente de teste que o QA usa), Share em IIS Express (`localhost:58149/SmartShare/`, "licenciado … Oracle"), Scheduler e Worker BPM do worktree do PR (commit `bfaf8358`), Oracle `SHAREGUIZAO`.
- **Banco:** Oracle primeiro (é o `DBType` dos `appsettings`). **A troca para SQL Server só depois de todos os testes do Oracle**, por instrução do QA.
- **Autorizações do QA no chat:** subir Worker BPM e Scheduler do worktree (aceitou que as pendências existentes pudessem gerar e-mail); criar massa extra pela tela. Nenhum `INSERT`/`UPDATE`/`DELETE` direto no banco foi feito: só leituras via `sqlplus`.

## Aprendizados consultados

`QA-KB-20261106-001` (troca de banco): será usado só na troca para SQL Server, depois dos testes do Oracle. Nenhum outro aplicável.

## Pré-requisitos do ambiente

| ID | Cenários | Pré-requisito | Evidência | Status |
|---|---|---|---|---|
| PR-01 | todos | Playwright e Azure DevOps | MCPs reconectados | OK |
| PR-02 | todos | Oracle, leitura | `sqlplus` leu `TAREFA` | OK |
| PR-03 | todos | Share local acessível e login | `Portal/Login.aspx` carregou; login `root` abriu `PadraoGeral.aspx` | OK |
| PR-04 | todos | Build do PR | worktree em `bfaf8358`; Worker BPM e Scheduler compilaram com 0 erros | OK |
| PR-05 | todos | Serviços rodando do worktree | log do Worker: "Iniciando worker/Bpm SHAREGUIZAO" (Oracle) | OK |
| PR-06 | #16 | Processo com observação = opção 4 | processo 481 v6, passo 5 (`id_permissao_observacao = 4`); fluxo 1682, tarefa 3, tarefa anterior executada por `cd_usuario` 1 | OK |
| PR-07 | #16 | Entrega de e-mail | `MailerException` ao enviar (ver #16) | **NÃO APLICÁVEL por decisão do QA** (evidência = destinatário no log) |
| PR-08 | #25, #26, #27, #19 | Massa: executores anteriores distintos, tarefa anterior automática, ramos paralelos | no Oracle só há executor anterior `cd_usuario` 1 ou nulo; nenhum destino com mais de uma origem | **PENDENTE** (criar pela tela, autorizado) |
| PR-09 | #18 | Executor anterior em papel/comitê | não levantado ainda | PENDENTE |
| PR-10 | #17 | Agent clássico com fix do PR 30254 | não verificado | PENDENTE |

## Detalhe por cenário

| # | Categoria | Ação | Esperado | Obtido | Resultado | Evidência |
|---|---|---|---|---|---|---|
| 16 | Fluxo principal | Na tarefa 3 do fluxo 1682 (opção 4), incluir a observação "QA-161711 #161839 PR30253 Oracle cenario 16" pela tela (15:55:22) | Executor da tarefa anterior recebe o e-mail | O Scheduler do PR criou o job 36569 (`NotificaObservacao`, fluxo 1682, tarefa 3). O Worker escolheu como destinatário `guilherme.borges@selbetti.com.br` (usuário 1 `root`, executor da tarefa 2) às 15:56:26 e tentou enviar. O envio falhou: `MailerException … BadRequest … "Write requests (excluding DELETE) must contain the Content-Type header declaration"` em `SendGridService.Send` (Graph). O job terminou "executado com sucesso" e `OBSERVACAO_TAREFA` cd 4 ficou `ST_NOTIFICADO = 1` | **PASSOU COM RESSALVA** — decisão do QA no chat (06/11): aceitar o log do Worker como evidência do destinatário. Classificação original: INCONCLUSIVO (entrega do e-mail não comprovada). Ressalva: o e-mail não chegou; falha de envio do ambiente | Log `logs-bpm\JOB_BPM\NotifyWf\20261106_NotifyWf.log` (job 36569). SQL no Oracle: consulta **antes** (3 aliases) para fluxo 1682, tarefa 3 retorna **0 linhas**; consulta **depois** (junção direta do PR) retorna **usuário 1** |

| 36a | Regressão (extra, fluxo com cadeia longa) | Com `ID_PERMISSAO_OBSERVACAO` = 4 no passo 6 do processo 522 v1 (UPDATE autorizado), incluir a observação "QA-161711 #161839 PR30253 Oracle fluxo 2082 passo 6" na tarefa 5 do fluxo 2082 (16:11:41) | Cadeia com 4+ tarefas anteriores continua achando o executor anterior (comportamento antigo preservado) | Job 36621 (`NotificaObservacao`, fluxo 2082, tarefa 5): o Worker escolheu `guilherme.borges@selbetti.com.br` (usuário 1, executor da tarefa 4) às 16:12:26; envio falhou pelo mesmo erro do Graph; `ST_NOTIFICADO = 1`. SQL no Oracle: consulta antes e depois retornam o mesmo usuário 1 | **PASSOU COM RESSALVA** (mesma ressalva do #16: destinatário no log, e-mail não chegou) | Log `NotifyWf` job 36621; SQL antes = depois = usuário 1 |
| 26 | Dados e borda | Consulta do PR no fluxo 1822, tarefa 2 (tarefa anterior = Início, sem usuário) | Sem erro; sem destinatário | A consulta retorna uma linha com `cd_usuario` NULL (sem erro de SQL). Não rodei o Worker nesse caso (o passo do fluxo 1822 não tem observação = 4) | **INCONCLUSIVO** — só a consulta foi validada, não o tratamento do Worker (`NotifyWFExecHandler.cs:1006-1036` não foi exercitado) | Saída da consulta no Oracle |

Cenários #17, #18, #19, #25, #27 e #36: **não executados** (ver Pendências). Motivo objetivo de #18, #19, #25 e #27: a massa não existe no Oracle e o processo não pôde ser desenhado.

## Resumo

- Executados: 3. PASSOU COM RESSALVA: 2 (#16, 36a; por decisão do QA sobre o e-mail). PASSOU: 0. INCONCLUSIVO: 1 (#26). Não executados: 6 (#17, #18, #19, #25, #27, #36).
- **Estado do ambiente a restaurar:** `PASSO_USUARIO.ID_PERMISSAO_OBSERVACAO` do processo 522 v1, passo 6, está em **4** (era 0), por UPDATE autorizado de 06/11. Reverter para 0 ao fim da rodada (UPDATE específico, a autorizar).
- Observações criadas no Oracle: fluxo 1682, tarefa 3 (cd_observacao 4); fluxo 2082, tarefa 5 (uma observação "QA-161711 …").
- O que a evidência mostra: o defeito do #161839 (nenhum destinatário encontrado com menos de 4 tarefas encadeadas) está corrigido no Oracle: o Worker do PR achou o executor anterior. O que falta provar é a chegada do e-mail.

## Achados fora do escopo do PR

- **Envio de e-mail do ambiente falha** com `BadRequest … Content-Type header` na chamada Graph (`Common.Mail/Services/SendGridService.cs:79`, `MailerService.SendMessage`). Não é do PR 30253 (o PR só altera `CaminhoFluxoRepository`). Efeito: nenhum e-mail do ambiente chega, e o handler marca a observação como notificada mesmo assim. Candidato a defeito separado, mas ainda sem análise de falha.
- O job `NotificaObservacao` termina com sucesso mesmo quando o envio falha (comportamento já descrito no #161715, não implementado).

## Pendências e instruções para retomada

1. ~~**#16 (entrega)**~~ — QA decidiu em 06/11 aceitar o log do Worker como evidência do destinatário: #16 = PASSOU COM RESSALVA. Vale para todos os cenários seguintes que dependem de "recebe e-mail" neste ambiente (a evidência é o destinatário no log do Worker, não a chegada). O envio com falha (`Content-Type`/Graph) segue como achado fora do escopo do PR.
2. **#25, #26, #27, #19, #18:** criar pela tela uma cópia de teste do processo 481 com os passos necessários (autorizado pelo QA; plano a ser mostrado antes de salvar). Liberação: processo publicado e fluxos criados.
2b. **Tentativa de criar a massa pela tela (06/11, 19:05–19:08):** o "+" do painel Processos abriu só "Gerenciamento de Pastas" (`gerenciamento/pasta.aspx?Cdpai=5&idTipoPasta=2`), sem salvar nada; `Workflow/Processo.aspx` direto dá erro (exige `wid` criptografado). O caminho do desenhador de processo não foi encontrado pela tela. Alternativas levantadas: o processo 522 v1 (`QA-161495 Matriz`) tem 4 passos de usuário e o 501 (`Teste ExecutaWS`) tem um passo automático (passo 11, sem `PASSO_USUARIO`); nenhum tem observação = opção 4 (todos 0). Ajustar isso exige `UPDATE` em `PASSO_USUARIO.ID_PERMISSAO_OBSERVACAO` (precisa de autorização específica) ou desenhar o processo.
3. **#36:** incluir observações em tarefas com as outras opções (2, 3, 5, 7) e conferir o destinatário no log do Worker.
4. **#17:** instalar o Agent clássico com o PR 30254 e repetir o #16.
5. Depois do Oracle completo: trocar para SQL Server (`QA-KB-20261106-001`) e repetir.
6. Serviços do worktree continuam rodando (Worker BPM e Scheduler); parar ao fim da rodada.
