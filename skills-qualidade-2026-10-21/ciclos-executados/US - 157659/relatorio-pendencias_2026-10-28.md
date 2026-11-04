# Relatório de pendências — Feature #158043 (HMG) — 2026-10-28

Consolida o que ficou pendente depois das execuções do dia. Fonte: relatórios de execução e de validação de cada US em `ciclos-executados\US-<ID>\`. Detalhe dos resultados no `relatorio-consolidado_2026-10-28.md`.

## 1. Visão geral

| US | Situação | Pendentes (nº) | Falhas sem defeito aberto |
|---|---|---|---|
| #154487 | Concluída | 4 | 0 |
| #157657 | Concluída | 3 | 0 |
| #157656 | Concluída | 11 | 0 |
| #157524 | Concluída | 6 | 1 (#12, decidido: defeito não será gerado) |
| #157525 | Fora da liberação (não desenvolvida) | — | 0 |
| #157526 | Concluída | 5 | 2 (#21/#22, severidade baixa; defeito ainda não gerado) |
| #159598 | Concluída | 11 | 0 |
| #157654 | Concluída | 10 | 0 |
| #160196 | Concluída | 3 (+ #4 sem logout) | 0 |
| #162232 | Não iniciada (adiada por você) | todos (27 no mapa) | — |

## 2. Pendências por US

### #154487 — BPM: respeita "Permite download/imprimir"
- #14: erro em lote registrado em LOG_APLICACAO (precisa de leitura do banco; pista: Id Log Aplicação 3075730 do 400 do #18).
- #17: comparar com a versão anterior (não há build anterior no HMG).
- #19, #20: hipóteses sem resultado esperado definido.
- #10 (lado positivo): testar com usuário com o papel Fiscal.
- Mapa: corrigir o esperado do #18 em `/gerar-mapa-testes-v3` ("Baixar funciona; Imprimir não se aplica ao tipo publicação").

### #157657 — ECM: filtro mantido ao voltar de ações com modal
- #5: editar pasta com filtro aplicado (a lista só mostra documentos, sem pasta para editar); depende de caminho de UI ou decisão.
- #22, #23: hipóteses sem esperado definido.
- Limpeza opcional: pastas duplicadas `QA-US157657` e `QA-US157657` solta em "Documentos"; massa restante em `QA-US157657-Q7`.

### #157656 — ECM: Manter filtro na Pasta principal
- #11, #12: subpasta e breadcrumb com filtro salvo (com filtro ativo a lista não mostra pastas): confirmar comportamento esperado com dev/PO.
- #10, #14, #16, #17, #21: hipóteses/multi-tenant/falha simulada sem esperado definido.
- #18: alto volume (definir volume e limite). #22: fluxo normal com filtro salvo.
- #24 (parte BPM): filtro do BPM da US 160196 (já coberto pelas execuções da #160196; só falta registrar).
- #25 (sem a flag): refazer com nova massa, se necessário.
- #2 e #19: conferência do registro no banco (FILTRO_USUARIO_TELA).

### #157524 — BPM: toolbar e abas
- #11: tooltip nos agrupamentos Tarefa e Processo (sem título truncado na massa; precisa de títulos longos).
- #13: usuários com e sem acesso a um processo (login manual).
- #18: comparação com a build master (não há build master).
- #20: loading ao navegar com filtros (sem detecção confiável do indicador).
- #22, #23: hipóteses.
- Achado a confirmar com dev/PO: nome do processo truncado sem tooltip (análise de falha deu NÃO por falta de esperado).

### #157526 — BPM: loading focal, lazy loading e paginação
- #13: hipótese (dois perfis de visibilidade). #27: volume de Finalizados e build anterior.
- #23: falha ao mudar de página no grupo (refazer com o grupo paginável).
- #24: ações dos cards (detalhar, executar, cancelar fluxo). #25: cor do hover da paginação (referência de cor Cyan).
- Confirmar com dev/PO: itens por página padrão = 25 (CA6/mapa dizem 10) e o overlay de loading cobrindo cabeçalho e título (CA1).
- Defeito dos casos #21/#22 (falha de consulta sem erro na área de conteúdo nem retry): análise com veredito SIM e severidade baixa; **falta sua decisão de gerar ou não o defeito**.

### #159598 — BPM: lazy loading
- #2, #3: Acompanhar e Finalizados com dados (o usuário "RO" não tem grupos nessas telas).
- #7: filtro que retorne mais de 25 grupos. #9: lote vs. "Itens por página".
- #14, #21: massa do Bug #161879 (poucos grupos e página pequena). #16: banco SQL Server e Oracle. #17: versão anterior (ordenação).
- #22: cor do hover da paginação. #23: ações dos cards em lotes carregados. #25: protótipo/volume.
- #24: aplicativo mobile (só o viewport foi testado).
- Confirmar com dev/PO o #20: após falha de um lote, a lista não volta a carregar ao rolar (só recarregando a página).

### #157654 — Manter Filtro (BE)
- #11, #14, #15, #20: hipóteses; #14 e #15 exigem chamada de API pura (Postman e token).
- #13: segundo usuário no mesmo cliente.
- #16, #17, #18: exclusão de usuários no clássico (destrutiva; usuários descartáveis e sua autorização).
- #19, #21: banco (criação das tabelas em SQL Server e Oracle; erro de conversão Oracle).

### #160196 — Manter Filtro (FE)
- #15: segundo usuário. #17: hipótese (processo inativo/removido). #21: Oracle.
- #4: repetir com logout e novo login (foi feita só recarga da página).

### #157525 e #162232
- #157525: fora da liberação; revalidar quando a US for desenvolvida (menu em dois níveis). Os 27 cenários bloqueados ficam para depois.
- #162232 (regressão geral de Performance BPM e Manter Filtro BPM/ECM): não iniciada, adiada por você.

## 3. Pendências por tipo de dependência

| O que falta | Quais cenários destrava |
|---|---|
| **Acesso de leitura ao banco** (FILTRO_USUARIO_TELA, TELA, LOG_APLICACAO; SQL Server e Oracle) | #154487 #14; #157656 #2/#19; #159598 #16; #157654 #19, #21 e conferência de registros; #160196 #21 |
| **2º usuário logado manualmente** (no mesmo cliente) | #157654 #13; #160196 #15; #157524 #13; #157526 #13 |
| **Usuário com dados em Acompanhar e Finalizados** (o "Administrador" perde a sessão por uso simultâneo; ideal um usuário dedicado) | #159598 #2, #3 e parte dos demais; #157526 em Finalizados |
| **Build anterior / build master** | #154487 #17; #157524 #18; #157526 #27; #159598 #17 |
| **App mobile e protótipo Figma (conector)** | #159598 #24, #25; #157526 layout |
| **Postman e token** | #157654 #14, #15 |
| **Usuários descartáveis + sua autorização** (exclusão no clássico) | #157654 #16, #17, #18 |
| **Massa específica** (títulos longos; poucos grupos/Bug #161879; grupos de exatamente 11 itens; campo de formulário) | #157524 #11; #159598 #14, #21; #157526 #15; #157656 #25 |

## 4. Confirmações com dev/PO (esperado indefinido)
1. Tooltip no nome do processo truncado (h5 cinza): entra no CA5 da #157524?
2. Itens por página padrão (25 vs. 10 do CA6) e overlay de loading sobre cabeçalho/título (#157526).
3. Falha de consulta: mensagem na área de conteúdo e retry (CA10, #157526) e lazy loading que não se recupera após falha de lote (#159598 #20).
4. Com filtro ativo no ECM a lista não mostra pastas (#157656 #11/#12): esperado?
5. Hipóteses de estado da flag e de filtro salvo apontando para valor inexistente (#157656, #160196, #157654).
6. Se a proteção contra filtro vazio (Bug #161543) deve existir também no endpoint (hoje só no front).

## 5. Decisões suas pendentes
- **Defeito de #157526 #21/#22** (severidade baixa): gerar ou não.
- **#162232**: quando executar.
- **Limpeza da massa de teste** no HMG (ver item 6), se quiser.

## 6. Massa e dados de teste no HMG (para limpeza)
- Processo 11611 (versões 2 e 3), fluxos 31825–31831, 31838 e 31839 (#154487).
- ECM: pastas `QA-US157657` (duplicadas), `QA-US157657-Q7` (1 documento), `QA-US157656-sub`, `QA-US157657` solta em "Documentos".
- Filtros salvos de teste do "RO": removidos. Filtro salvo do "Administrador" no ECM: restaurado e conferido.
- Preferência de agrupamento (Tarefa) em Minhas tarefas dos usuários "Administrador" e "RO" ficou salva dos testes.

## 7. Observações de método (para ler os relatórios com cuidado)
- Parte dos prints de #157526 e #159598 saiu antes do estado final; os resultados vêm das requisições e do DOM, e os prints decisivos foram refeitos ou copiados. Rotas de simulação deixadas ativas (unroute que não removia) podem ter afetado prints de loading em #157526; os resultados foram mantidos.
- Execuções de #157654 e #160196 não tiveram revisão independente de prints (evidência textual de API).
- Gate de KB (`C:\project personal\smartshare-kb`) não realizado em nenhuma US: a pasta não existe nesta máquina.
- O "Administrador" perde a sessão no HMG por token invalidado (provável uso simultâneo): preferir um usuário dedicado.
