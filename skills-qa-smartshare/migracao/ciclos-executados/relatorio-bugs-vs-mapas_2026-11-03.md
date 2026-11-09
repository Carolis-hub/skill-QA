# Bugs das US com mapa gerado pela skill — 2026-11-03

Base: 27 US com mapa de testes em `ciclos-executados`, depois de desconsiderar os mapas do instalador (#154487, #157656, #157657 e as US da Feature #158043). Bugs: filhos (Bug) dessas US no Azure DevOps (SHARE-4), 16 no total. Títulos das US consultados no ADO em 03/11/2026.

- **Quem executou:** quem abriu o bug (quem executou o teste que o achou).
- **Citado no mapa:** o bug ou o cenário dele aparece no histórico de defeitos ou nos cenários do mapa da própria US (busca de texto nas HTML; o campo esperado não foi lido).
- **Localizado pela skill (gerar defeito):** o bug foi gerado pela skill de gerar defeito, a partir de falha ou divergência achada na execução. #165160 e #165161 foram relatados por Caroline (achado manual) e ficam como Não.

## US com bugs

| US | Título |
|---|---|
| #157853 | Unificação da DLL do Aspose para a versão mais recente |
| #161357 | Melhoria ECM \| Ajustar a ordenação dos documentos |
| #161897 | BPM \| Orientação Procedimento \| Abrir orientação de procedimento em nova guia |
| #163012 | Migração tela de gerenciamento \| Gerenciamento de parâmetros (Front-end) |
| #164996 | Migração tela de gerenciamento \| Gerenciamento de índice (FE) \| Opções do índice |

## Bugs

| Bug | US | Título da US | Quem executou | Citado no mapa | Localizado pela skill |
|---|---|---|---|---|---|
| #163763 | #157853 | Unificação da DLL do Aspose | Pedro Roque | Sim (histórico) | Não |
| #164268 | #157853 | Unificação da DLL do Aspose | Rodrigo Neves | Sim (histórico) | Não |
| #165097 | #161357 | Melhoria ECM \| Ajustar a ordenação dos documentos | Thiago Gon | Sim (#25, hipótese na v1 do mapa) | Não |
| #165347 | #161897 | BPM \| Orientação Procedimento em nova guia | Thiago Gon | Sim (#8, citado no próprio bug) | Não |
| #165361 | #161897 | BPM \| Orientação Procedimento em nova guia | Thiago Gon | Sim (#16, citado no próprio bug) | Não |
| #165066 | #163012 | Gerenciamento de parâmetros (FE) | Caroline Oliveira | Não | Sim (divergência do protótipo) |
| #165067 | #163012 | Gerenciamento de parâmetros (FE) | Caroline Oliveira | Sim (#27) | Sim (falha do #27) |
| #165068 | #163012 | Gerenciamento de parâmetros (FE) | Caroline Oliveira | Não (o #15 cobre só o comportamento) | Sim (divergência do protótipo) |
| #165073 | #163012 | Gerenciamento de parâmetros (FE) | Caroline Oliveira | Sim (#31, #32) | Sim (falha do #31 e #32) |
| #165160 | #163012 | Gerenciamento de parâmetros (FE) | Caroline Oliveira | Não | Não (manual) |
| #165161 | #163012 | Gerenciamento de parâmetros (FE) | Caroline Oliveira | Não | Não (manual) |
| #165690 | #164996 | Gerenciamento de índice (FE) \| Opções do índice | Caroline Oliveira | Sim (#4, #5, #6) | Sim (falha do #4, #5 e #6) |
| #165691 | #164996 | Gerenciamento de índice (FE) \| Opções do índice | Caroline Oliveira | Sim (#17) | Sim (falha do #17 e revisão de idioma) |
| #165721 | #164996 | Gerenciamento de índice (FE) \| Opções do índice | Caroline Oliveira | Não (mock só como pré-requisito) | Sim (guardrail do ambiente) |
| #165724 | #164996 | Gerenciamento de índice (FE) \| Opções do índice | Caroline Oliveira | Sim (#25) | Sim (#25 parcial, divergência relatada) |
| #165727 | #164996 | Gerenciamento de índice (FE) \| Opções do índice | Caroline Oliveira | Sim (#37) | Sim (fidelidade ao protótipo) |

## Totais (16 bugs)

| | Sim | Não |
|---|---|---|
| Citado no mapa | 11 | 5 |
| Localizado pela skill | 9 | 7 |

| Cruzamento | Qtde |
|---|---|
| Localizado pela skill e citado no mapa | 6 |
| Localizado pela skill e fora do mapa | 3 |
| Não localizado pela skill e citado no mapa | 5 |
| Não localizado pela skill e fora do mapa | 2 (#165160, #165161, manuais) |

Desconsiderados (18 bugs das US do instalador com mapa): #158663, #160816, #162539, #162559, #162695, #161879, #161948, #161543, #161559, #161611, #161629, #161805, #162279, #162380, #162552, #162556, #162629 e #162682.

## Bugs criados por outras pessoas (5)

Dos 16 bugs, 5 foram abertos por Pedro Roque, Rodrigo Neves e Thiago Gon. Todos estão em *Done*, severidade 3 - Medium.

| Bug | US | Aberto por | Data | Mapa (data) | Cenário no mapa | O que aconteceu |
|---|---|---|---|---|---|---|
| #163763 | #157853 | Pedro Roque | 14/10 | 28/10 | Histórico de defeitos do mapa (cenários de Viewer Externo com imagens, ex.: #8, #19, #20) | Bug anterior ao mapa. O mapa o usou como histórico. A causa foi o TIFF preto e branco com a tag IsBlackWhite na DLL 19.9. |
| #164268 | #157853 | Rodrigo Neves | 19/10 | 28/10 | Histórico de defeitos do mapa | Bug legado (já ocorria na master), anterior ao mapa. A relação com o Aspose foi inferida. |
| #165097 | #161357 | Thiago Gon | 27/10 | 23/10 e 26/10 | #25 "Desempate por Nome quando o Tipo de documento é igual" (hipótese na v1, cenário na v2) | O mapa previa o caso. O bug foi aberto depois do mapa, com a tarefa Teste em *New*. Origem: critério da PM sobre desempate por nome. |
| #165347 | #161897 | Thiago Gon | 28/10 | 23/10 | #8 "Tabela mais larga que a tela" (CA5), citado no próprio bug como "Mapa de testes #163200, cenário #8" | O mapa previa o caso e o bug veio da execução dele. |
| #165361 | #161897 | Thiago Gon | 28/10 | 23/10 | #16 "Script no conteúdo", citado no próprio bug como "Mapa de testes #163200, cenário #16" | O mapa previa o caso (origem: casos de teste do dev). O script executa na nova guia, falha de segurança (XSS). |

**Leitura da análise:**
- **Todos os 5 estão ligados ao mapa.** Isso corrige a primeira versão deste relatório, que marcava #165097, #165347 e #165361 como fora do mapa. Eles estão no mapa, e dois (#165347 e #165361) citam o cenário no próprio texto.
- **Dois momentos:** #163763 e #164268 vieram antes do mapa e alimentaram o histórico de defeitos. #165097, #165347 e #165361 vieram da execução de cenários já previstos no mapa.
- **Quem executou os 3 bugs da #161357 e da #161897:** Thiago Gon. O formato do texto (US, mapa, cenário, CA, passos, esperado e obtido) é o da skill de gerar defeito, mas não há relatório de execução dessas US na pasta, então mantive "Não" em "Localizado pela skill".
- **Teste ainda em *New*:** nas duas US, #161357 e #161897, a tarefa Teste está em *New*, embora os bugs já tenham sido achados executando o mapa.
