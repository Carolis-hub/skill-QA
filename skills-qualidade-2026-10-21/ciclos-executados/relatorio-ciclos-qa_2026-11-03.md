# Relatório de ciclos QA (base: ciclos-executados, 20/10 a 03/11/2026)

Detalhe dos bugs em `relatorio-bugs-vs-mapas_2026-11-03.md`.

## Mapas desconsiderados

Criados para testar o instalador, por orientação de Caroline em 03/11/2026: #154487, #157656, #157657 e todas as US da Feature #158043 (filhas no ADO: #157524, #157526, #157654, #157656, #159598, #160196, #162232). Total: 9 US. Os bugs delas também saem do relatório.

Também ficam fora as US sem subpasta de mapa de testes: #162365, #162650, #164837 e #165526 (checklist de liberação, mapa do CSV). Os bugs do checklist (#165557 e #165577) e o #165365, das US do instalador sem mapa, saem junto.

## Indicadores

| Indicador | Quantidade |
|---|---|
| Mapas criados | 27 US com mapa de testes (36 menos as 9 desconsideradas) |
| Mapas executados (skill) | 2 US com mapa feito pela skill (#163012 e #164996) |
| Mapas executados (outros) | 6 US com mapa criado e tarefa Teste em *Done* no ADO, sem execução pela skill nos ciclos: #157853, #162122, #162412, #162683, #163010 e #164414 |
| Bugs abertos por Caroline | 11 (nas US com mapa) |
| Bugs de todas as pessoas nas US com mapa da skill | 16 (11 de Caroline e 5 de outras pessoas) |
| Bugs criados por outras pessoas (US com mapa) | 5, todos ligados ao mapa (ver relatório de bugs) |

## Mapas executados

| US | Título |
|---|---|
| #163012 | Migração tela de gerenciamento \| Gerenciamento de parâmetros (Front-end) |
| #164996 | Migração tela de gerenciamento \| Gerenciamento de índice (FE) \| Opções do índice |

## Mapas sem execução (19)

Sem execução registrada e com tarefa Teste fora de *Done* no ADO (consulta de 03/11/2026):

- **Tarefa Teste em *New* (15):** #158841, #160818, #161357, #161897, #162264, #162265, #162266, #164248, #164847, #164848, #164849, #164850, #164851, #164852 e #165176.
- **Sem tarefa Teste (3):** #164997, #164998 e #165177.
- **Sem tarefas no ADO (1):** #157525 (US não desenvolvida).

## Bugs abertos por Caroline (11)

| Bug | US (título) | Citado no mapa | Origem |
|---|---|---|---|
| #165066 | #163012 Gerenciamento de parâmetros (FE) | Não | Skill (divergência do protótipo) |
| #165067 | #163012 Gerenciamento de parâmetros (FE) | Sim (#27) | Skill |
| #165068 | #163012 Gerenciamento de parâmetros (FE) | Não | Skill (divergência do protótipo) |
| #165073 | #163012 Gerenciamento de parâmetros (FE) | Sim (#31, #32) | Skill |
| #165160 | #163012 Gerenciamento de parâmetros (FE) | Não | Manual |
| #165161 | #163012 Gerenciamento de parâmetros (FE) | Não | Manual |
| #165690 | #164996 Opções do índice | Sim (#4, #5, #6) | Skill |
| #165691 | #164996 Opções do índice | Sim (#17) | Skill |
| #165721 | #164996 Opções do índice | Não | Skill (guardrail do ambiente) |
| #165724 | #164996 Opções do índice | Sim (#25) | Skill (parcial) e relato manual |
| #165727 | #164996 Opções do índice | Sim (#37) | Skill (fidelidade ao protótipo) |

## Mapas executados (outros)

Critério: mapa criado ("Criar Mapa de Teste" em *Done*) e tarefa de tipo Teste em *Done* no ADO, sem relatório de execução da skill na pasta. Consulta ao ADO em 03/11/2026.

| US | Título | Tarefa Teste | Bugs |
|---|---|---|---|
| #157853 | Unificação da DLL do Aspose para a versão mais recente | Done (#157862, #163549, #163631, #163817) | #163763 e #164268 |
| #162122 | Atualização do Bootstrap no Formulário BPM | Done (#162143) | Nenhum |
| #162412 | Migração Share 4 \| Login, esqueci senha, 2FA e banner | Done (#163795) | Nenhum |
| #162683 | Migração Share 4 \| Configuração SmartShare (WebConfig) no Nyx + parâmetros adicionais da ConnectionString | Done (#163792) | Nenhum |
| #163010 | Migração tela de gerenciamento \| Gerenciamento de parâmetros (Back-end) | Done (#163277) | Nenhum |
| #164414 | Login \| Exigir reautenticação (biometria/2FA) quando o login com informações salvas não é concluído | Done (#164423) | Nenhum |

Das 6 US, só a #157853 tem bugs filhos; as outras 5 foram testadas sem bug aberto.

## Falhas sem bug aberto

- #163012 #18: Esc não fecha o modal, sem Bug.

As falhas sem bug da #157524 e da #157526 saíram junto com os mapas desconsiderados.

## Ciclo completo por US executada

Etapas da cadeia de skills: análise de negócio, mapa de testes, validação de ambiente, execução, análise de falha e defeito. Análise técnica não entra no critério.

| US | Análise de negócio | Mapa | Validação de ambiente | Execução | Análise de falha | Defeito gerado | Ciclo completo |
|---|---|---|---|---|---|---|---|
| #163012 | Sim | Sim | Sim | Sim | Sim | Sim (#165066, #165067, #165068, #165073) | **Sim** |
| #164996 | Sim | Sim | Sim | Sim | Dentro do relatório de execução (sem arquivo próprio) | Sim (#165690, #165691, #165721, #165724, #165727) | **Sim**, com ressalva |

## Bugs criados por outras pessoas

Detalhe e análise em `relatorio-bugs-vs-mapas_2026-11-03.md` (seção "Bugs criados por outras pessoas"). Resumo: #163763 e #164268 (#157853) vieram antes do mapa e entraram no histórico de defeitos; #165097 (#161357), #165347 e #165361 (#161897) correspondem a cenários do mapa (#25, #8 e #16). Todos os 5 estão ligados ao mapa.

## Observação

A #157525 não é filha da Feature #158043 no ADO (a lista tem 7 filhas), mas o consolidado de 28/10 a trazia na Feature. Ela foi mantida; é uma US sem execução e sem bugs.
