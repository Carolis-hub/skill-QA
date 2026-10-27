# Etapa 04 — Execução de Testes — #164251 [BUG] Ajustar regra de leitura de status no BPM

- **Skill:** `/executar-teste 164251` (Modo A, ambiente HMG)
- **Data:** 2026-10-26 14:36
- **Escreveu no Azure DevOps?** Não
- **Status:** Bloqueada no Step 0 (validação de ambiente). Nenhum cenário executado.

## Resumo
- Executados: 0
- Passou: 0
- Falhou: 0
- Não executado: 28 (execução não iniciada)

## Motivo do bloqueio (Step 0)
1. **MCP `azure-devops` não conectou nesta sessão:** "connection timed out after 30000ms" na abertura da sessão. Fora da sessão, `claude mcp list` mostrou o servidor como conectado, então a causa provável é a demora do `npx` ao iniciar. Precisa ser reconectado pelo usuário em `/mcp`.
2. **MCP de navegador (`mcp__playwright` / `user-playwright`) não existe na configuração.** Não há servidor Playwright configurado.

## Observação para a próxima tentativa
Este mapa não tem cenário de tela: a verificação é por banco (`JOB_BPM`, `JOB_DUMP`) e pelo log do Worker BPM. Mesmo com os dois MCPs:
- Os cenários #1 a #11, #14, #15, #17 a #19 e #21 exigem **escrita** em `JOB_BPM` (montar linha travada, alterar status, `Data_Atualizacao` ou lock). Pela regra da skill, isso é `NAO EXECUTADO` (categoria 3) até alguém com autorização rodar o SQL.
- Não existe MCP de **leitura** de banco nesta configuração, então nem a conferência do resultado (linha saiu do `JOB_BPM`, registro no `JOB_DUMP`) pode ser feita pela skill.
- Os cenários #26 a #28 são hipóteses e não executam.
- Os cenários #12 e #16 são N/A.

## Correção aplicada no ambiente (2026-10-26, segunda tentativa)
A segunda tentativa falhou pelo mesmo timeout mesmo depois do `/mcp`. Medição: o servidor demorava ~19 s pelo `npx -y` (resolução no registro npm a cada início) e passava de 30 s na abertura do app. Pacote `@azure-devops/mcp@2.11.0` instalado em `%USERPROFILE%\.mcp-servers\azure-devops` e o `~/.claude.json` passou a iniciar o servidor com `node` direto nesse caminho (~4 s). Backup do `~/.claude.json` anterior em `%TEMP%`.

## Pendências para destravar
1. Reconectar o MCP `azure-devops` (`/mcp`).
2. Definir como a execução vai acontecer: QA/dev roda o SQL de preparação e o ciclo do Worker, e a skill confere resultado e log; ou a execução é manual, com registro dos resultados neste ciclo.
3. Acesso de leitura ao banco do ambiente (MCP read-only) e ao log do Worker.
4. Itens já listados no README do ciclo: build da branch do PR 29707, autorização de escrita, SQL Server/Oracle, Worker ativo, 2 instâncias.
