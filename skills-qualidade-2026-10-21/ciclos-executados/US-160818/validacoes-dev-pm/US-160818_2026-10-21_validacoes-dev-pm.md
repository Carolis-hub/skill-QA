# Validações pendentes — US #160818 Rotina - Calculo Indicador

Gerado em: 2026-10-21 | Origem: /analise-negocio (execução 2026-10-21_0951) e /analise-tecnica
Revisão da US (System.Rev): 7 | Card de Análise: #161472 | PRs: #29630 (SmartShare), #29631 (smartshare-net8)

Legenda de impacto: **Bloqueia teste** = impede /executar-teste; **Bloqueia mapa** = impede escrever resultado esperado; **Decisão** = precisa de decisão antes de fechar a US.

---

## A. Para o PM / PO (regra de negócio)

| # | Pergunta | Por que importa | Origem | Impacto |
|---|---|---|---|---|
| PM-01 | A US não tem critérios de aceite. Podem ser registrados (ou os 11 casos do card do dev serão adotados como critérios)? | Sem CA, o mapa de testes se baseia só na descrição e no card do dev. | Análise de negócio | Bloqueia mapa |
| PM-02 | Quais **totalizadores** devem ser gravados no log, e em que formato? São os mesmos do cálculo legado ou um conjunto novo? | O CA "log mostra totais e tempo" não tem resultado esperado verificável. | Descrição: "informações de totalizadores que o cálculo fornece" | Bloqueia mapa |
| PM-03 | O **tempo de execução** deve apenas ir para o log ou ser persistido em outro local? Qual formato/unidade? | "Armazenar o tempo" admite duas interpretações. | Descrição | Bloqueia mapa |
| PM-04 | Qual a **frequência/agendamento** da rotina? É configurável na tela de configuração? | Define como disparar e testar a trava de concorrência. | Descrição (ausente) | Bloqueia mapa |
| PM-05 | A rotina na **listagem da tela de configuração** é só visualização, ou permite ativar/desativar, configurar e executar manualmente? | O card do dev não tem caso de teste para a listagem. | Descrição: "deverá aparecer a listagem de rotina" | Bloqueia mapa |
| PM-06 | A regra "apenas 1 cálculo por vez" vale **por cliente (tenant) ou globalmente**? | Muda o cenário de teste de concorrência. | Descrição | Bloqueia mapa |
| PM-07 | Quando uma execução é **ignorada** por já haver cálculo rodando, isso deve gerar log? De que tipo? | A descrição só pede log de totais e de erro. | Descrição | Decisão |
| PM-08 | Dois comportamentos do clássico que **parecem bug** foram mantidos fiéis ao clássico. Corrigir agora ou manter? (1) ramo SubProcesso não persiste a histórico-tarefa nas regiões "Histórico nunca verificada" e "Histórico finalizada"; (2) `adicionaTempoFluxo` grava com `cd_fluxo_indicador`, `cd_processo` e `cd_versao_processo` zerados, e o UPDATE vira no-op. | O card pede avaliar com dev/PM antes de fechar a story. Define se o resultado esperado do teste é "igual ao clássico" ou "corrigido". | Card #161472 e anexo LACUNAS-CLASSICO-CALCULO-INDICADOR.md | Decisão |
| PM-09 | O resultado do cálculo migrado deve ser **idêntico ao clássico** (mesmos valores para os mesmos dados)? Existe critério ou massa de comparação? | A US é migração, mas não traz critério de equivalência. | Análise de negócio (regra implícita) | Bloqueia mapa |

---

## B. Para o Dev (técnico / ambiente de teste)

| # | Pergunta | Por que importa | Origem | Impacto |
|---|---|---|---|---|
| DEV-01 | Qual é a **chave/configuração de ativação** da rotina no net8 (nome, local, valor) e como alternar entre clássico e net8 por cliente? | Casos 8 e 11 não são executáveis sem isso. | Card, caso 8 | Bloqueia teste |
| DEV-02 | Qual o **mecanismo da trava de concorrência** (lock em banco, semáforo, outro)? Como rodar 2 instâncias para testar o caso 9? | Caso 9 e a regra "1 cálculo por vez". | Card, caso 9 / descrição | Bloqueia teste |
| DEV-03 | Se a execução terminar com **erro ou o processo cair**, a trava é liberada? Existe timeout? | Risco de trava presa impedir execuções futuras. | Análise de negócio (riscos) | Decisão |
| DEV-04 | Como **provocar a falha numa tarefa** (caso 7) em ambiente de teste (dado inválido, flag, mock)? | Cenário negativo sem reprodução definida. | Card, caso 7 | Bloqueia teste |
| DEV-05 | Qual o **intervalo do job** e como forçar a execução em teste (sem esperar o agendamento)? | Necessário para disparar a rotina. | Não informado | Bloqueia teste |
| DEV-06 | **Onde ficam os logs** e qual o formato dos totalizadores, do tempo de execução e do erro completo? | Caso 10 e o CA de log de erro. | Card, caso 10 | Bloqueia teste |
| DEV-07 | "Falha numa das 4 transações de semeadura aborta a execução inteira" (card) × "erro numa tarefa não trava as outras" (caso 7): confirmar que são níveis diferentes e qual é o resultado esperado em cada um. | Evita teste com expectativa contraditória. | Card #161472 | Decisão |
| DEV-08 | O que contém o PR **#29630** (SmartShare, "script job calculo indicador")? Scripts de banco? Quais, para SQL Server e Oracle? | O card só descreve o serviço do net8. | PR #29630 | Bloqueia teste |
| DEV-09 | Lista de **arquivos alterados** do PR #29631 e confirmação de que cobre só o `CalculoIndicadorService.cs` e o que a US pede. | O diff não pôde ser cruzado (o MCP não expõe as mudanças do PR). | PR #29631 | Decisão |
| DEV-10 | Erros nesta rotina **não impactam outros jobs** do Agent? Houve verificação ("verificar via CR/testes", card)? | Pedido do próprio card, sem resposta registrada. | Card #161472 | Decisão |
| DEV-11 | Quais telas/relatórios **leem as tabelas `*_INDICADOR`** e podem ser afetados pela migração? | Dependências indiretas não citadas no card. | Análise técnica | Decisão |
| DEV-12 | Há API, integração ou relatório alterado nesta US? (o card não menciona) | Define a abrangência do mapa. | Análise técnica | Decisão |

---

## Resumo
- PM/PO: 9 itens, sendo 6 que bloqueiam o mapa de testes e 3 que dependem de decisão.
- Dev: 12 itens, sendo 6 que bloqueiam a execução de teste e 6 que dependem de decisão.
- Nada foi gravado no Azure DevOps.
