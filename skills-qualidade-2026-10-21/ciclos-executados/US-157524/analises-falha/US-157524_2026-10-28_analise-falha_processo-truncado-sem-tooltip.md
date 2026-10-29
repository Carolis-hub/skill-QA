# Análise de Falha — #157524 Performance BPM | Reorganização da toolbar e das abas
**Item:** nome do processo truncado (texto cinza abaixo do título) sem tooltip — achado da execução de 2026-10-28, ligado ao CA5 / cenário #7 do mapa (não é o cenário #12).

## O que era esperado
- **CA5 do mapa/US:** "Títulos de tarefa/processo truncados exibem tooltip com o texto completo no hover" (Descrição da US #157524: "Inclusão de tooltip nos títulos de tarefa/processo quando o texto for truncado").
- **Análise dev #158115 (Done):** incluir o componente de tooltip do Nyx em `task-item-card.component.html` e `task-item-list.component.html`; "o texto do tooltip deve incluir a descrição da tarefa somente quando o texto estiver truncado".
- **Casos de teste do mapa Azure #158144:** CT07 (tooltip em títulos truncados, todas as combinações de visão e agrupamento) e CT08 (sem tooltip quando não truncado).

## O que aconteceu
- HMG, usuário "Administrador", BPM > Acompanhar, visão lista, aba Minhas solicitações: o nome do processo "QA 162706 - FORMULARIO ATIV A E B" aparece cortado com reticências e, com o mouse sobre ele, nenhum tooltip é exibido.
- Verificação no navegador durante o hover: elemento `h5.text-truncate` confirmado truncado (`scrollWidth` > `clientWidth`), sem janela de tooltip e sem atributo de tooltip. No mesmo cartão, o `h3` do título da tarefa tem `aria-describedby=ngb-tooltip-…` e abre tooltip.
- Reproduzido também em Minhas tarefas (visão lista) com o nome de processo "PROCESSO PERMISSÃO ANEXOS".
- Evidências: `execucoes\evidencias_2026-10-28\ev-157524-c7-processo-truncado-sem-tooltip.png` (print estático: mostra o texto cortado e nenhum tooltip, mas não prova ausência por si só; a ausência vem da checagem no DOM) e `ev-157524-c10-tooltip-cartao.png` (contraste: tooltip no título de tarefa).

## Componente relacionado
Hub, `smartshare-bpm-fe` (branch master local, pode não conter o código final da US): `src/app/modules/BPM/_shared/components/task-item/`
- `task-item-list/task-item-list.component.html:8`: `<h3 class="text-truncate …" [ngbTooltip]="item.name" …>` (título, com tooltip).
- `task-item-list/task-item-list.component.html:15`: `<h5 class="gray-60 … text-truncate …">` com o nome do processo (`item.processName`), **sem** `ngbTooltip`.
- `task-item-card/task-item-card.component.html:4` (h3 com `[ngbTooltip]="item.name"`) e `:11` (h5 `item.processName` com `text-truncate` quando há tag, sem `ngbTooltip`).
Os dois arquivos são exatamente os que a análise #158115 manda alterar. O `PR`/diff da US não foi consultado (limitação).

## Classificação
Funcional (UI): o comportamento diverge do CA5 se o rótulo do processo for considerado "título de processo". Não há erro de sistema, exceção nem resposta HTTP inesperada.

## Já existia antes?
Busca "tooltip truncado" no SHARE-4 não retornou Bug relacionado (só análises, PBIs e mapas de teste). Sem bug anterior para esse ponto. Informação não encontrada sobre o comportamento antes da US: não há build master para comparação.

## Relação com a alteração atual
Provável: o componente alterado pela US (task-item-card/list) é o mesmo em que o h5 do nome do processo não recebeu tooltip. Confirmação depende do diff do PR da US (não disponível aqui).

## Observação relacionada (cenário #12, já como Falhou)
No mesmo código o `h3` usa `[ngbTooltip]="item.name"` sem condição de truncamento, o que explica o tooltip aparecer em títulos não truncados. A análise #158115 pede tooltip só quando truncado. Causa provável do #12, ainda sem confirmação no código da branch da US.

## Veredito
**NÃO — evidência insuficiente para abrir defeito deste item, por ora.** A parte técnica está comprovada (DOM e código), mas falta o esperado claro: não está definido se o texto cinza do nome do processo é um "título de processo" no escopo do CA5. A análise #158115 cita apenas "a descrição da tarefa" e o título (`h3`), e o CT07 fala em "título de tarefa/processo"; o h5 é um rótulo secundário. Hipótese não confirmada não vira defeito.

O que coletar para virar `SIM`:
1. Confirmar com o dev (Rodrigo Emílio Ferreira Neves, autor da análise) ou o PO se o nome do processo exibido no cartão/lista (h5) entra no CA5.
2. Se entrar: repetir o hover com print tirado com o mouse parado sobre o elemento por 2 s (evidência visual) e checar no PR/branch da US se o h5 tem `ngbTooltip`.
3. Reproduzir também na visão cartão e nos agrupamentos Todos/Tarefa/Processo (hoje só confirmado em lista, agrupamento Todos).

Se a confirmação vier positiva, seguir para `/gerar-defeito` (não encadeado automaticamente). O #12 (tooltip em título não truncado) já tem esperado definido pela análise e pode seguir para `/gerar-defeito` à parte.
