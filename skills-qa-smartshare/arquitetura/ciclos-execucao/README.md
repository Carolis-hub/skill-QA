# Ciclos de execução das tasks de QA

Uma pasta por task do Azure DevOps, nomeada `<id da task>-US<id da história>`. Dentro dela:

- `README.md`: resumo do ciclo (história, task, status de cada etapa, artefatos criados no Azure DevOps, pendências).
- Um `.md` por etapa, numerado na ordem em que a etapa rodou (`01-analise-negocio.md`, `02-analise-tecnica.md`, `03-mapa-testes.md`, `04-execucao-testes.md`...).

Ações de escrita no Azure DevOps também entram em `../log/LOG-ACOES.md`.

O passo a passo que as skills seguem para registrar cada etapa está em [COMO-REGISTRAR.md](COMO-REGISTRAR.md).

## Ciclos

| Task | História | Título | Etapa atual | Pasta |
|---|---|---|---|---|
| 164259 | 164251 | [BUG] Ajustar regra de leitura de status no BPM | **Rodada 1 encerrada** (relatório anexado à task 164259): 20 passou, 3 parcial, 1 falhou (#27 — defeito NÃO, aguarda dev/PO), 1 não executado (#22); #25 removido do mapa. **Rodada Oracle (etapa 16, 27/10) concluída:** 20 passou, 3 parcial, 1 com observação, 1 falhou (#27, igual ao SQL), 0 não executado; relatório Oracle anexado à task 164259. Próximo: rodada no HMG | [164259-US164251](164259-US164251/README.md) |
