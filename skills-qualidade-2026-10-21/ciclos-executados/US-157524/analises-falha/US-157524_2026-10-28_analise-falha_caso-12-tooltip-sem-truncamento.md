# Análise de Falha — #157524 Performance BPM | Reorganização da toolbar e das abas
**Item:** cenário #12 do mapa, "Sem tooltip quando o texto não está truncado" (execução de 2026-10-28, resultado Falhou).

## O que era esperado
- Cenário #12: ao passar o mouse sobre um título que cabe sem truncar, o tooltip **não** é exibido.
- Fonte: análise dev #158115 (Done): "O texto do tooltip deve incluir a descrição da tarefa somente quando o texto estiver truncado" e "Se não estiver truncado, não deve apresentar o tooltip"; mapa Azure #158144, CT08 "Tooltip não aparece quando o texto não está truncado" (pré-requisito: título curto, sem truncamento).
- O CA5 da US só exige tooltip nos truncados; a usuária definiu em 2026-10-28 que vale o comportamento da análise.

## O que aconteceu
- HMG, usuário "Administrador". Em BPM > Minhas tarefas, o título "Atividade A" (não truncado: `scrollWidth` ≤ `clientWidth`) exibe tooltip "Atividade A" ao hover, tanto na **visão lista** quanto na **visão cartão**.
- Para contraste, o título "Atividade 2 com nome grande para verificar se o titulo é truncado na visão de cards e lista" (truncado) exibe tooltip com o texto completo (comportamento correto).
- Também reproduzido em Acompanhar > Minhas solicitações, lista (print `c12-sem-tooltip.png`).
- Evidências em `execucoes\evidencias_2026-10-28\`: `ev-157524-c12-sem-tooltip.png` (Acompanhar, lista), `ev-157524-c12-nao-truncado-minhas-tarefas.png` (lista) e `ev-157524-c12-nao-truncado-cartao.png` (cartão). O revisor independente confirmou nos prints o tooltip sobre título não truncado nas duas visões.
- Passos: 1) abrir BPM > Minhas tarefas; 2) localizar um título curto que cabe no cartão/linha ("Atividade A"); 3) passar o mouse sobre o título e aguardar ~1,5 s; 4) o tooltip aparece com o próprio texto.

## Componente relacionado
Hub, `smartshare-bpm-fe` (branch master local; pode não conter o código final da US), `src/app/modules/BPM/_shared/components/task-item/`:
- `task-item-list/task-item-list.component.html:8`: `<h3 class="text-truncate …" [ngbTooltip]="item.name" placement="bottom" …>`
- `task-item-card/task-item-card.component.html:4`: `<h3 class="font-weight-bold text-truncate" [ngbTooltip]="item.name" placement="bottom" …>`
O binding de tooltip é incondicional (sem verificar truncamento), o que explica o tooltip em títulos curtos. Hipótese baseada no código da master local; precisa ser confirmada no diff/PR da US.

## Classificação
Funcional (UI): o comportamento visível não bate com a regra da análise (tooltip só quando truncado). Não há erro de sistema, exceção nem resposta HTTP inesperada.

## Já existia antes?
Busca "tooltip truncado" no SHARE-4 não retornou Bug relacionado. Informação não encontrada sobre o comportamento anterior à US (não há build master para comparar); o `[ngbTooltip]` incondicional no código da master local sugere que o tooltip sempre existiu nesse título, e a US pede a condição "somente truncado".

## Relação com a alteração atual
Provável: os arquivos são os mesmos que a análise #158115 manda alterar para incluir o tooltip "somente quando truncado". O diff do PR da US não foi consultado (limitação), então não dá para afirmar se a condição foi implementada de forma parcial ou ficou de fora.

## Veredito
**SIM — evidência suficiente para abrir defeito.**
- Esperado claro: análise #158115 e CT08 (e decisão da usuária de seguir a análise).
- Obtido comprovado: prints em lista e cartão, confirmados pelo revisor, mais checagem no DOM de que o elemento não está truncado.
- Passos reproduzíveis: descritos acima, 100% reproduzível nas duas visões.
- Não é hipótese: o cenário #12 não é `HIPOTESE:` no mapa.

Ressalvas para o defeito: causa provável no código da master local (a confirmar no PR da US) e o agrupamento Tarefa/Processo não foi testado para esse caso. Severidade sugerida: baixa (UI, sem perda de função).

Próximo passo: perguntar se prossegue para `/gerar-defeito` (não encadeado automaticamente).
