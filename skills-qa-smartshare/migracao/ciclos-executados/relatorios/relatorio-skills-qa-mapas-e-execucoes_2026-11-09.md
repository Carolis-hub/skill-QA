# Relatório das skills de QA — mapas gerados e execuções (base: 20/10 a 09/11/2026)

Fonte dos tokens: transcrições das sessões do Claude Code (`~/.claude/projects`), que gravam o uso de cada resposta. Títulos das US consultados no Azure DevOps (SHARE-4) em 09/11/2026. Bugs conferidos no ADO (pai e título).

## Resumo

| Indicador | Valor |
|---|---|
| US em que a skill gerou mapa de testes (com sessão localizada) | 49 |
| Tokens do `/gerar-mapa-testes-v3` nessas US | 297,4 M (13,1 M sem contar leitura de cache) |
| Tokens das análises que alimentam o mapa (`/analise-negocio` + `/analise-tecnica`) | 170,6 M |
| US com execução de testes pela skill (recorte sem instalador) | 4 (#163012, #164996, #164848, #164849) |
| Tokens do `/executar-teste` nessas 4 US | 205,8 M |
| Tokens do pipeline completo de execução (validar ambiente + executar + análise de falha + gerar defeito) | 934,9 M |
| Bugs encontrados nas execuções | 13 abertos a partir da execução (fora da contagem: 2 registrados manualmente na #163012 e 1 vinculado à #164998) |

Unidade: M = milhões de tokens. **Total** soma entrada, escrita de cache, **leitura de cache** e saída. A leitura de cache é a maior parte (a cada resposta o contexto da sessão é relido) e infla o total em sessões longas; por isso o resumo traz também o valor sem ela.

## 1. US em que a skill gerou mapa de testes

- **Tokens do mapa:** da leitura do `gerar-mapa-testes-v3` até a próxima skill (ou fim da sessão).
- **Tokens das análises:** `/analise-negocio` + `/analise-tecnica` da mesma US (a skill de mapa reaproveita essas análises).
- **Execuções da skill:** nº de vezes que o mapa foi gerado para a US (2 = regerado).
- US #162122: a sessão de 20/10 que cita "162142" foi tratada como #162122 (mesma US, nova geração).

| # | US | Título | 1ª geração | Execuções da skill | Tokens do mapa (M) | Tokens das análises (M) | Total (M) |
|---|---|---|---|---|---|---|---|
| 1 | #162122 | Atualização do Bootstrap no Formulário BPM | 20/10 | 2 | 4,6 | 1,9 | 6,6 |
| 2 | #163010 | Migração tela de gerenciamento \| Gerenciamento de parâmetros (Back-end) | 20/10 | 1 | 13,2 | 2,6 | 15,8 |
| 3 | #160818 | Rotina - Calculo Indicador | 21/10 | 1 | 13,0 | 2,7 | 15,7 |
| 4 | #162683 | Migração Share 4 \| Configuração SmartShare (WebConfig) no Nyx + parâmetros adicionais da ConnectionString | 21/10 | 1 | 20,6 | 6,9 | 27,5 |
| 5 | #163012 | Migração tela de gerenciamento \| Gerenciamento de parâmetros (Front-end) | 21/10 | 1 | 9,1 | 1,8 | 10,9 |
| 6 | #164248 | Migração Share 4 \| WebConfig \| Leitores de ConnectionString do back-end aceitam parâmetros adicionais | 21/10 | 1 | 7,5 | 2,9 | 10,4 |
| 7 | #164414 | Login \| Exigir reautenticação (biometria/2FA) quando o login com informações salvas não é concluído | 22/10 | 1 | 3,2 | 1,8 | 4,9 |
| 8 | #158841 | Melhoria \| Ajustar o parametro 111 para que não seja obrigatório preenchimento | 23/10 | 1 | 2,8 | 2,7 | 5,5 |
| 9 | #161357 | Melhoria ECM \| Ajustar a ordenação dos documentos | 23/10 | 1 | 6,5 | 1,5 | 8,0 |
| 10 | #161897 | BPM \| Orientação Procedimento \| Abrir orientação de procedimento em nova guia | 23/10 | 1 | 2,8 | 2,2 | 5,0 |
| 11 | #162264 | Melhoria Formulário \| Configurar Dica de campo no Editor de Formulário | 23/10 | 1 | 2,0 | 1,7 | 3,8 |
| 12 | #162412 | Migração Share 4 \| Login, esqueci senha, 2FA e banner | 23/10 | 1 | 9,7 | 3,5 | 13,2 |
| 13 | #164847 | Migração tela de gerenciamento \| Gerenciamento de índice (BE) \| Listagem e busca | 26/10 | 1 | 5,6 | 2,8 | 8,4 |
| 14 | #164848 | Migração tela de gerenciamento \| Gerenciamento de índice (BE) \| Cadastro do tipo de índice | 26/10 | 1 | 26,4 | 1,9 | 28,3 |
| 15 | #162266 | Melhoria Formulário \| Persistir Dica de campo na exportação/importação de processo (XML) | 27/10 | 1 | 2,1 | 2,1 | 4,2 |
| 16 | #164849 | Migração tela de gerenciamento \| Gerenciamento de índice (BE) \| Lançamento e integração | 27/10 | 1 | 4,0 | 2,3 | 6,3 |
| 17 | #164852 | Migração tela de gerenciamento \| Gerenciamento de índice (BE) \| Consumo pela camada ECM - testes gerais | 27/10 | 2 | 13,8 | 16,3 | 30,1 |
| 18 | #164850 | Migração tela de gerenciamento \| Gerenciamento de índice (BE) \| Alteração, inativação e exclusão | 29/10 | 1 | 16,4 | 2,0 | 18,4 |
| 19 | #164851 | Migração tela de gerenciamento \| Gerenciamento de índice (BE) \| Opções do índice | 29/10 | 1 | 5,4 | 7,7 | 13,1 |
| 20 | #165176 | API de tipo de documento: filtrar por código e retornar stRequerido nos índices | 29/10 | 1 | 2,9 | 1,8 | 4,7 |
| 21 | #165177 | Migração \| Gerenciamento de Notificação: aceitar estilização HTML no campo de conteúdo | 29/10 | 1 | 6,7 | 9,7 | 16,3 |
| 22 | #164996 | Migração tela de gerenciamento \| Gerenciamento de índice (FE) \| Opções do índice | 30/10 | 1 | 5,5 | 2,7 | 8,2 |
| 23 | #164997 | Migração tela de gerenciamento \| Gerenciamento de índice (FE) \| Ajustes do formulário | 30/10 | 1 | 4,6 | 5,8 | 10,4 |
| 24 | #164998 | Migração tela de gerenciamento \| Gerenciamento de índice (FE) \| Ajustes da listagem, inativação e exclusão | 30/10 | 1 | 5,2 | 2,7 | 7,9 |
| 25 | #164837 | DI CLIENT \| Tela de Indexação | 03/11 | 1 | 5,1 | 3,9 | 9,0 |
| 26 | #164840 | DI CLIENT \| Indexação automática | 03/11 | 1 | 2,7 | 2,5 | 5,2 |
| 27 | #162648 | Migração Share 4 \| Reset de autenticação de duplo fator | 04/11 | 1 | 4,0 | 5,4 | 9,4 |
| 28 | #163451 | Dashboard ECM - Redimensionar painel de detalhamento arrastando | 04/11 | 1 | 3,9 | 1,9 | 5,7 |
| 29 | #163452 | Dashboard ECM - Lembrar largura do painel de detalhamento por usuário | 04/11 | 1 | 3,3 | 3,6 | 6,9 |
| 30 | #163453 | Dashboard ECM - Atalhos, acessibilidade e dispositivos no painel redimensionável | 04/11 | 1 | 3,6 | 2,2 | 5,8 |
| 31 | #163648 | Dashboard ECM - Organizar em abas Conteúdo e Armazenamento | 04/11 | 1 | 3,7 | 7,0 | 10,7 |
| 32 | #163659 | Dashboard ECM - Totalizador Páginas publicadas na aba Conteúdo | 04/11 | 1 | 5,0 | 4,5 | 9,5 |
| 33 | #163663 | Dashboard ECM - Gráfico Volumetria de publicações (Dia/Semana/Mês) | 04/11 | 1 | 7,2 | 5,0 | 12,2 |
| 34 | #163664 | Dashboard ECM - Detalhamento ao clicar no gráfico Volumetria de publicações | 04/11 | 1 | 3,3 | 2,0 | 5,3 |
| 35 | #163665 | Dashboard ECM - Zoom por barra de seleção no gráfico Volumetria de publicações | 04/11 | 1 | 2,9 | 2,0 | 4,9 |
| 36 | #163770 | Dashboard ECM - Documentos por tipo e por área lado a lado (todas as áreas) | 04/11 | 1 | 2,4 | 4,3 | 6,7 |
| 37 | #163954 | Dashboard ECM - Gráfico Documentos por responsável | 04/11 | 1 | 4,8 | 3,9 | 8,7 |
| 38 | #163955 | Dashboard ECM - Totalizadores do repositório na aba Armazenamento | 04/11 | 1 | 3,4 | 2,5 | 5,9 |
| 39 | #164835 | DI CLIENT \| Tela inicial | 04/11 | 1 | 2,9 | 1,5 | 4,4 |
| 40 | #164836 | DI CLIENT \| Iniciar Indexação | 04/11 | 1 | 3,6 | 1,3 | 4,8 |
| 41 | #162626 | Herdar perfis da pasta de destino ao publicar documento recortado | 05/11 | 1 | 3,2 | 5,4 | 8,6 |
| 42 | #162649 | Migração Share 4 \| Troca de senha obrigatória (primeiro acesso e senha expirada) | 05/11 | 1 | 3,1 | 1,9 | 5,0 |
| 43 | #163958 | Dashboard ECM - Gráfico Tamanho do repositório por tipo de documento | 05/11 | 2 | 7,2 | 5,3 | 12,5 |
| 44 | #162627 | Instrumentar eventos GA4 de uso do Recorte de Documentos e da herança de perfis da pasta | 06/11 | 1 | 2,7 | 1,7 | 4,4 |
| 45 | #163956 | Dashboard ECM - Exportar a aba ativa | 06/11 | 1 | 3,4 | 1,6 | 5,0 |
| 46 | #164793 | Gravar índices do tipo Seleção ao publicar documentos gerados pela divisão | 06/11 | 1 | 3,3 | 1,9 | 5,2 |
| 47 | #165078 | UNIMED FEDERAÇÃO — Ampliar o limite de caracteres do campo DS_DESTINO_VALOR (banco + interface) | 06/11 | 1 | 5,0 | 3,3 | 8,4 |
| 48 | #165924 | Migração - Gerar pacote \| Exibir onboarding da novidade Gerar pacote na tela Documentos | 09/11 | 1 | 7,8 | 1,4 | 9,3 |
| 49 | #166234 | [ECM Dashboard] Detalhamento ao clicar no gráfico Tamanho do repositório por tipo | 09/11 | 1 | 6,3 | 4,7 | 11,0 |
| | **Total (49 US)** | | | | **297,4** | **170,6** | **468,0** |

US com mapa de testes na pasta `ciclos-executados` mas **sem sessão localizada** (sem tokens): #157525, #157853, #162265 e #162365. Fora da lista, como no relatório de 03/11: as US do instalador (#154487, Feature #158043 e filhas), cujo mapa foi gerado numa única sessão de 401 M tokens junto com a validação e a execução delas.

## 2. Execuções de testes feitas pela skill

- **Tokens do executar-teste:** só a fase `/executar-teste`.
- **Tokens do pipeline de execução:** `/validar-ambiente` + `/executar-teste` + `/analise-falha` + `/gerar-defeito` da US.
- **Bugs:** defeitos filhos da US criados a partir da execução (ID, pai e título conferidos no ADO).

| # | US | Título | Período | Tokens do executar-teste (M) | Tokens do pipeline de execução (M) | Bugs | Detalhe dos bugs |
|---|---|---|---|---|---|---|---|
| 1 | #163012 | Migração tela de gerenciamento \| Gerenciamento de parâmetros (Front-end) | 23/10 a 26/10 | 57,8 | 158,8 | 4 | 4 por falha/divergência: #165066, #165067, #165068, #165073 (+2 registrados manualmente após validação com a PM: #165160, #165161) |
| 2 | #164996 | Migração tela de gerenciamento \| Gerenciamento de índice (FE) \| Opções do índice | 30/10 a 03/11 | 47,2 | 279,6 | 5 | 5: #165690, #165691, #165721, #165724, #165727 (+1 de fidelidade ao protótipo, vinculado à #164998: #165754) |
| 3 | #164848 | Migração tela de gerenciamento \| Gerenciamento de índice (BE) \| Cadastro do tipo de índice | 05/11 a 06/11 | 85,4 | 316,7 | 2 | 2: #166156, #166233 |
| 4 | #164849 | Migração tela de gerenciamento \| Gerenciamento de índice (BE) \| Lançamento e integração | 06/11 a 06/11 | 15,4 | 179,8 | 2 | 2: #166262, #166286 |
| | **Total (4 US)** | | | **205,8** | **934,9** | **13** | |

Tokens por fase em cada execução (M, total com cache):

| US | validar-ambiente | executar-teste | analise-falha | gerar-defeito |
|---|---|---|---|---|
| #163012 | 30,1 | 57,8 | 13,6 | 57,3 |
| #164996 | 12,8 | 47,2 | 22,5 | 197,1 |
| #164848 | 32,6 | 85,4 | 129,0 | 69,7 |
| #164849 | 24,1 | 15,4 | 7,9 | 132,3 |

Outras execuções fora da tabela:
- **Reteste do BUG-03** (arquivo local, sem ID no ADO), sessão de 05/11: 13,4 M tokens, sem bug novo.
- **Instalador** (#154487, #157524, #157526, #157654 e demais da Feature #158043): executadas pela skill em 27 e 28/10, fora do recorte por orientação de 03/11. A sessão inteira (mapa, validar ambiente, execução e análise de falha) somou 401 M tokens.
- **Ciclo da task #164259 (US #164251, Arquitetura):** rodadas SQL e Oracle de 26 e 27/10 registradas em `arquitetura/ciclos-execucao`, sem sessão correspondente no histórico disponível (tokens n/d).

## 3. Como os números foram medidos (limites)

- O uso é somado por sessão, a partir da leitura do arquivo da skill (ou do comando `/skill`) até a leitura da próxima skill. Conversa entre uma skill e outra (perguntas, ajustes de skill, push para o git) cai na fase anterior. Isso pesa mais em `gerar-defeito` (#164996: 428 mensagens, #164849: 187) e em mapas cuja sessão continuou com outros assuntos (#162683, 20,6 M).
- Trechos de manutenção das próprias skills foram retirados dos mapas (4 segmentos: #164998, #164849, #164852 e #163954). Sessões duplicadas (mesma execução retomada) contam uma vez.
- Subagentes entram no total da sessão em que rodaram.
- Os 13 bugs são os defeitos criados por `/gerar-defeito` nas sessões acima; os 2 manuais da #163012 e o #165754 (vinculado à #164998) aparecem entre parênteses e não entram na contagem. Não há contagem de bugs para mapas sem execução.
- Não há campo de tokens nos ciclos nem no ADO; para registrar daqui para frente, o mais simples é gravar o consumo da sessão no último passo de cada skill.
