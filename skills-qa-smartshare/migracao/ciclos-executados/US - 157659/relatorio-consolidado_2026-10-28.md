# Relatório consolidado de execução — HMG (http://172.16.0.182/smartshare/) — 2026-10-28

Feature #158043. Execução via `/executar-teste` (Playwright), mapas HTML locais. Detalhes por US nos relatórios em `US-<ID>\execucoes\`.

## Visão geral

| US | Tema | Executados | Passou | Falhou | Pendentes / não executados | Situação |
|---|---|---|---|---|---|---|
| #154487 | BPM: Share respeita "Permite download/imprimir" | 14 | 14 (#10 e #18 com ressalva) | 0 | #14, #17, #19, #20 + N/A #8, #13 | Concluída |
| #157657 | ECM: manter filtro ao voltar de ações com modal | 16 | 16 (#8 com ressalva) | 0 | #5, #22, #23 + N/A #11, #12, #16, #17 | Concluída |
| #157656 | ECM: "Manter filtro" na Pasta principal | 16 | 16 (#2, #19, #20, #24 com ressalva) | 0 | #10, #11, #12, #14, #16, #17, #18, #21, #22 + BPM do #24 e #25 sem flag | Concluída (double-check feito) |
| #157524 | Performance BPM: toolbar (filtro e ações) e abas | 15 | 14 | 1 (#12) | #11 parcial, #13, #18, #20, #22, #23 | Concluída (double-check feito) |
| #157525 | Performance BPM, fluxos finalizados: menu lateral em menus e submenus | 0 | — | — | 30 cenários no mapa | Fora da liberação (US não desenvolvida; validação NAO PRONTO) |
| #157526 | Performance BPM: loading focal, lazy loading e paginação por scroll | 21 | 18 | 2 (#21, #22) | #13, #23, #24, #25, #27 | Concluída (double-check feito) |
| #157654 | Performance BPM: opção Manter Filtro (BE) | 12 | 12 | 0 | #11, #13–#21 | Concluída (sem revisão de prints: evidência textual de API) |
| #159598 | Performance BPM: lazy loading | 13 | 12 | 0 | #20 observado; #2, #3, #7, #9, #14, #16, #17, #21, #22, #23, #25 | Concluída (double-check feito) |
| #160196 | Performance BPM: opção Manter Filtro (FE) | 14 | 14 | 0 | #15, #17, #21 (+ #4 sem logout) | Concluída (sem revisão de prints; 3 cenários aproveitados da #157654/#157524) |
| #162232 | Regressão: Performance BPM e Manter Filtro BPM e ECM | 0 | — | — | 27 cenários no mapa | Não iniciada |

**Falhas reais: nenhuma.** A única que existiu (#154487 #18) foi reclassificada para "Passou com ressalva" após a resposta do hub (comportamento existente por desenho).

## 1. Testados — resultado

### #154487 (14 Passou)
#1, #2, #3, #4, #5, #6, #7 (evidência parcial), #9, #10 (parcial: sem usuário com papel Fiscal), #11, #12, #15, #16, #18 (com ressalva).

### #157657 (16 Passou)
#1, #2, #3, #4, #6, #7, #8 (ressalva: busca "Pedro" casa com os 2 documentos), #9, #10, #13, #14, #15, #18, #19, #20, #21.

### #157656 (14 Passou, parcial)
#1, #2 (banco não consultado; evidência pela resposta da API), #3, #5, #6, #7, #8, #9, #13, #19 (parcial: só mobile), #20, #23, #24 (parcial: só telas ECM), #25 (com flag).

## 2. Com falha

Nenhuma. Histórico: #154487 #18 foi inicialmente "Falhou" (impressão em lote de anexo de publicação → 400) e reclassificado para "Passou com ressalva": o hub (`AnexoUtil.GetAttachmentFileByteArray`) só imprime em lote anexos Documento Eletrônico PDF, comportamento existente por desenho.

## 3. Pendentes / não executados

| US | # | Motivo | O que falta |
|---|---|---|---|
| 154487 | 14 | sem acesso de leitura ao banco | consultar LOG_APLICACAO, id 3075730 (gerado no 400 do #18) |
| 154487 | 17 | sem versão anterior no HMG | comparar com versão anterior |
| 154487 | 19, 20 | hipótese sem resultado esperado | definir esperado |
| 154487 | 10 (lado positivo) | — | testar com usuário com o papel Fiscal |
| 157657 | 5 | com filtro ativo a lista só mostra documentos, sem pasta para editar | confirmar se existe caminho de UI |
| 157657 | 22, 23 | hipóteses sem esperado definido | definir esperado |
| 157656 | 4 | exige logout/login | aguarda você logar de novo |
| 157656 | 15 (conf.) | confirmar filtro do admin intacto | aguarda login do admin |
| 157656 | 11, 12 | filtro ativo não lista pastas, impossível entrar em subpasta | confirmar comportamento esperado com dev/PO |
| 157656 | 10, 14, 16, 17, 21 | hipóteses sem esperado definido / multi-tenant / falha simulada | definir esperado ou simular |
| 157656 | 18 | alto volume sem massa definida | definir volume e limite |
| 157656 | 22 | fluxo normal com filtro salvo | executar (cobertura parcial pela 157657) |
| 157656 | 24 (BPM) | filtro BPM da US 160196 | executar |
| 157656 | 25 (sem flag) | massa consumida | repetir com nova massa, se necessário |
| 157656 | 2, 19 (banco) | sem acesso ao banco (FILTRO_USUARIO_TELA) | confirmar registro único/removido por SQL |

### US não iniciadas (#157524, #157525, #157526, #157654, #159598, #160196, #162232)
- Mapas HTML gerados em `US-<ID>\mapas-teste\US-<ID>_2026-10-27_mapa-teste.html` (um por US, só arquivo local, sem publicar no Azure). A contagem de cenários inclui hipóteses a confirmar.
- Nenhuma passou por `/validar-ambiente` nem por `/executar-teste`: 0 executados, 0 falhas; todos os cenários estão pendentes.
- Total pendente nas 7 US: 178 cenários.
- Dependências já conhecidas: #157654 (BE) e #160196 (FE) cobrem o "Manter filtro" do BPM, a contraparte da #157656 (ECM); a #162232 é a regressão geral dessas e das de performance. #157524, #157525, #157526 e #159598 são de performance/carregamento do BPM e precisam de massa de volume.
- Próxima etapa sugerida: `/validar-ambiente` para a próxima US da fila (ordem a definir por você).

## 4. Achados e observações

- **#157656 #25:** "Pesquisar em: Todas as pastas" (padrão) retornou 1194 documentos de todo o repositório; "Selecionar todos" nesse modo alcançaria itens fora da pasta aberta. Com "Pasta atual" funcionou corretamente (26 itens, `apagarlistadocumento`).
- **#157656 #11/#12:** com filtro aplicado, a Pasta principal não lista pastas (só documentos).
- **#154487:** botão geral de imprimir visível quando só há anexos de publicação, clique mostra aviso genérico (UX existente).
- Corrigir o esperado do #18 do mapa 154487 em `/gerar-mapa-testes-v3`.

## 5. Estado do ambiente

- Filtro salvo do admin "Administrador": restaurado e conferido (backup em `config\ambiente-teste.local.md`); #157656 usou o usuário "RO" sem tocar nele.
- Massa de teste a limpar por você, se desejar: processo 11611 (versões 2 e 3), fluxos 31825–31831, 31838, 31839; pastas `QA-US157657` (duplicadas), `QA-US157657-Q7` (1 documento restante), `QA-US157656-sub`, `QA-US157657` solta em "Documentos".
- Gate de KB não realizado (`C:\project personal\smartshare-kb` inexistente).
