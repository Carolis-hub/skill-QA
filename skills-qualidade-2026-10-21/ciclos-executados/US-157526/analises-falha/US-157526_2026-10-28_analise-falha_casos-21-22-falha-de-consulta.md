# Análise de Falha — #157526 Performance BPM | Otimização de carregamento
**Itens:** cenários #21 (falha de consulta ao abrir a tela) e #22 (tentar novamente após falha), execução de 2026-10-28, resultado Falhou.

## O que era esperado
- **CA10 da US #157526:** "Falha de consulta (rede/timeout) exibe mensagem de erro na área de conteúdo e permite tentar novamente."
- **Análise dev #158119 (Done):** "Em caso de falha na consulta (erro de rede/timeout), a tela exibe mensagem de erro na área de conteúdo (não trava em 'Carregando' indefinidamente) e permite tentar novamente."
- **Mapa Azure #158142, CT10:** "A área de conteúdo exibe uma mensagem de erro, sem travar em 'Carregando'. É oferecida uma opção para tentar novamente (retry), e o retry realiza uma nova tentativa de consulta."
- Referência de padrão do produto (PBI #26693, modal de consulta): falha de consulta mostra blankslate com a mensagem "Ocorreu uma falha ao realizar a consulta." e botão "TENTAR NOVAMENTE" que refaz a requisição.

## O que aconteceu
- HMG, usuário "RO", BPM > Acompanhar. Com a requisição `POST bpmApi/api/v1/Grouping/FollowUp` simulada como falha **no navegador** (resposta HTTP 500; e, separadamente, queda de conexão), sem alterar o servidor:
  1. A **área de conteúdo** exibe o blankslate **"Não há tarefas em andamento."** (o mesmo de uma lista realmente vazia), sem mensagem de erro e **sem botão ou opção de tentar novamente**. Não trava em "Carregando" (esse ponto do CA10 está ok).
  2. Aparece **um toast temporário** (~4,6 s, amostragem a cada 200 ms) com o texto "Ocorreu um erro ao carregar as informações. Contate o administrador do sistema", **fora da área de conteúdo** e sem ação de retry.
- Para recuperar, o usuário precisa recarregar a página ou trocar de aba por conta própria.
- Passos: 1) interceptar `Grouping/FollowUp` e responder 500 (ou abortar); 2) abrir BPM > Acompanhar; 3) observar a área de conteúdo e o toast. Reproduz 100% das vezes (HTTP 500 e queda de rede).
- Evidências em `execucoes\evidencias_2026-10-28\`: `ev-157526-c21-falha-api.png` e `ev-157526-c21-falha-rede.png` (blankslate "Não há tarefas em andamento." sem erro nem retry) e `ev-157526-c21-toast-erro.png` (toast). O revisor independente confirmou nos dois primeiros prints a ausência de mensagem de erro e de botão; que a API estava falhando vem da simulação no script, não dos prints.
- **Correção da execução:** o relatório inicial dizia "sem mensagem de erro". O toast só foi encontrado nesta análise (amostragem rápida); a checagem inicial foi feita 8 s depois da falha, quando o toast já havia sumido. O relatório de execução foi corrigido.

### Observação da usuária (2026-10-28): o toast não explica o erro exato
O toast usa uma mensagem genérica única ("Ocorreu um erro ao carregar as informações. Contate o administrador do sistema"). Ela aparece igual para HTTP 500 e para queda de rede, e não informa a causa (rede, timeout, erro do servidor), nem o código da falha, nem um identificador de log para o administrador. No código do hub o erro real só é registrado em `console.log(error)`, sem chegar ao usuário. Em outro ponto do BPM (impressão em lote, #154487) o sistema já devolve "Id Log Aplicação: <id>", então há precedente de mensagem rastreável. O CA10 pede apenas "mensagem de erro", sem exigir a causa; portanto isso é uma **lacuna de qualidade da mensagem**, a incluir no defeito como complemento (não como falha separada), com o esperado a confirmar com dev/PO.

## Componente relacionado
Hub, `smartshare-bpm-fe` (master local; pode não conter o código final da US), `src/app/modules/BPM/follow/task-view/grouped-by-task-view.ts` (padrão repetido em `follow/task-view/task-view.ts` e nos equivalentes de `finalized` e My tasks):
```
getGroupingFollowUp(value).pipe(catchError(error => {
    console.log(error);
    ... toast "msgError.errorLoadingTasks" (type danger, autoHide) ...
    return of({});
}))
```
O `catchError` mostra só o toast com autoHide e devolve `of({})`, o que renderiza a lista vazia (`task-view-blankslate`, `TaskBlankslate.NoData`). Não há estado de erro nem ação de retry; o blankslate tem apenas os tipos NoData, Filter e Search. Isso explica exatamente o que se observa no HMG.

## Classificação
Funcional (comportamento diferente da regra de negócio do CA10). A falha é do tratamento de erro no front (erro tratado como lista vazia), não de erro de sistema: o back-end foi simulado com 500 e a rede foi derrubada de propósito.

## Já existia antes?
Busca no SHARE-4 ("falha consulta mensagem de erro tentar novamente BPM") não retornou Bug relacionado a esse ponto. O padrão `catchError` + toast + `of({})` já aparece no código das telas (provável comportamento anterior à US); o CA10/CT10 foi o que passou a exigir mensagem na área de conteúdo e retry. Informação não encontrada sobre o comportamento exato antes da US (sem build anterior).

## Relação com a alteração atual
Provável: o CA10 é desta US (#157526) e as telas Minhas tarefas, Acompanhar e Finalizados são as alteradas. O diff do PR da US não foi consultado (limitação): não dá para afirmar se o tratamento de erro foi implementado parcialmente ou ficou de fora.

## Veredito
**SIM — evidência suficiente para abrir defeito** (#21 e #22 juntos, mesma causa).
- Esperado claro: CA10, análise #158119 e CT10 (#158142).
- Obtido comprovado: simulações com HTTP 500 e queda de rede, prints (conteúdo sem erro e sem retry) e captura do toast temporário; código do hub coerente.
- Passos reproduzíveis: descritos acima.
- Não é hipótese: #21 e #22 não são `HIPOTESE:` no mapa.

Ressalvas para o defeito: a falha foi simulada no navegador (não houve falha real do servidor); testado em Acompanhar (agrupamento por Processo), as demais telas seguem o mesmo padrão de código mas não foram exercitadas; o #23 (falha ao mudar de página) não foi executado. Severidade definida pela usuária em 2026-10-28: **baixa**. Justificativa: existe aviso de erro na tela (toast), que é o padrão do resto do sistema; o risco de o usuário achar que não tem tarefas (blankslate "Não há tarefas em andamento.") é mitigado pelo aviso e pelo contorno de recarregar. (Sugestão inicial da análise: média.)

Próximo passo: perguntar se prossegue para `/gerar-defeito` (não encadeado automaticamente).
