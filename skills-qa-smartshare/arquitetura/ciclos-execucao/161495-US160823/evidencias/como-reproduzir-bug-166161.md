# Como reproduzir o Bug #166161 (para o dev)

Duas formas. A **forma B não depende de importar o processo** e é a mais segura quando o ambiente do dev tem IDs diferentes do ambiente de QA.

## Por que a importação do zip pode dar erro ao iniciar o processo

O `processo-543-QA-161495-Form2-export.zip` foi exportado do ambiente de QA e carrega IDs fixos desse ambiente. No ambiente do dev, o processo importado só inicia se esses registros existirem lá:

| Referência no export | Onde | Verificação no banco do dev (SQL Server e Oracle) |
|---|---|---|
| Papel principal, papel administrador e **executor da atividade** = 2 ("Papel Principal dos Processos") | `PROCESSO.CD_PAPEL_PRINCIPAL`, `CD_PAPEL_ADMINISTRADOR`, `PASSO_USUARIO.CD_EXECUTOR` (tipo de executor 1 = papel) | `SELECT cd_papel, ds_papel FROM PAPEL WHERE cd_papel = 2;` |
| Perfil vinculado = 4 ("Administrador SShare") | `PROCESSO.CD_PERFIL_VINCULADO` | `SELECT cd_perfil, ds_perfil FROM PERFIL WHERE cd_perfil = 4;` |
| Calendário = 1 | `PROCESSO.CD_CALENDARIO` | `SELECT COUNT(*) FROM CALENDARIO WHERE cd_calendario = 1;` |
| Pasta = 5 | `PROCESSO.CD_PASTA` | `SELECT COUNT(*) FROM PASTA WHERE cd_pasta = 5;` |
| Usuário 1 (criador da versão) | `VERSAO_PROCESSO.CD_USUARIO` | `SELECT COUNT(*) FROM USUARIO WHERE cd_usuario = 1;` |

Se algum não existir, ou se o papel 2 for outro papel (sem usuário), o fluxo não inicia ou nada é executado. Além disso, depois de importar é preciso **publicar** o processo (o import entra como rascunho) antes de iniciar um fluxo. Se o erro continuar, o dev precisa informar a mensagem exata (tela e o `Exibir informações técnicas`, ou o log) para identificar qual dessas referências falhou.

## Erro ao INICIAR o processo não é o bug

O bug **não** acontece ao iniciar o processo. Ele aparece depois, no Worker BPM, quando a tarefa de papel já venceu (2 min) e a rotina tenta desassociá-la. Se o início do fluxo dá erro, é outro problema de ambiente. A causa mais provável, verificada no ambiente de QA em 06/11/2026:

- **Parâmetro 96 ("Utilizar nova API do Engine") = 1.** Com 1, o Share clássico inicia, avança e cancela fluxo chamando a API net8 (`<origem>/smartshare/api/api/v1/engine/...`). Sem a API no ar e sem o nginx roteando `/smartshare/api/` para ela, o início do fluxo mostra "Erro inesperado" e, em "Exibir informações técnicas", uma pilha em `AuthenticationService` (`GenerateApiToken`) ou `EngineService`. Nenhum fluxo é criado.
- Verificar: `SELECT cd_parametro, ds_valor FROM PARAMETRO WHERE cd_parametro = 96;`
- Para reproduzir o bug sem a API do Engine: `UPDATE PARAMETRO SET ds_valor = '0' WHERE cd_parametro = 96;` (motor clássico) e iniciar o fluxo de novo. Anotar o valor original para restaurar depois. Com 96 = 1 é preciso subir a API (`Engine.Api`) e o nginx com a rota do Engine.
- Outras causas, se o 96 já for 0: ID de papel/perfil/calendário inexistente no banco do dev (tabela acima), processo importado ainda não publicado, ou Workers rodando de uma branch sem a rotina da US 160823 (o código de `InicioDesassociarAutomatico` só está na branch `feature/US160823-...`).
- Em qualquer caso, o texto de "Exibir informações técnicas" do erro ao iniciar identifica a causa.

## Forma B (recomendada): usar um processo que já exista no ambiente do dev

Pré-requisitos no processo escolhido:
- uma **atividade de papel** (executor = um papel que tenha usuário), com "Tempo total para desassociar" configurado nas opções avançadas da atividade (usar 2 minutos);
- um **campo de formulário** do tipo de valor "Propriedade do Processo" (`ID_TIPO_VALOR = 5`) no formulário da atividade (se não tiver, criar um novo campo pela tela, antes de publicar a versão);
- processo publicado.

Passos:

1. Deixar o campo com valor inicial nulo (a tela do Share não grava nulo; precisa ser no banco). Anotar o valor atual para restaurar depois:

   ```sql
   SELECT cd_campo, ds_valor_inicial FROM CAMPO_FORMULARIO
    WHERE cd_processo = <PROCESSO> AND id_tipo_valor = 5;

   UPDATE CAMPO_FORMULARIO SET ds_valor_inicial = NULL
    WHERE cd_processo = <PROCESSO> AND cd_campo = <CAMPO> AND id_tipo_valor = 5;
   COMMIT;
   ```

2. Banco (SQL Server ou Oracle) apontado nos Workers e no Share. `JOB_CONFIG` Id 12 (módulo 1, job 34) com `Ativo = 1` **antes de iniciar** Scheduler e Worker BPM (o `Ativo` é lido na partida).
3. Iniciar um fluxo do processo e deixar a tarefa da atividade de papel associada a um usuário (ex.: `iniciafluxo.aspx?CDPROC=<PROCESSO>` com o usuário logado).
4. Esperar o prazo (2 min) vencer, o ciclo do Scheduler (enfileira em `JOB_BPM`) e o do Worker BPM (até 5 min).
5. Resultado esperado do bug: o job fica em `FalhaParaRepetir` (`JOB_BPM.JOB_STATUS_ID = 4`), o log `JOB_BPM/InicioDesassociarAutomatico` do Worker mostra `System.NullReferenceException` em `FluxoService.AtualizarValoresCorrenteCampoFormularioDaTarefa` (`FluxoService.cs:7749`) e a tarefa continua associada.
6. Controle: restaurar o valor do campo (`UPDATE ... SET ds_valor_inicial = '[ds_usuario_corrente]'`); na próxima tentativa o job desassocia a tarefa.

## Forma A: importar o zip (se os IDs do ambiente conferirem)

1. Conferir a tabela acima no banco do dev.
2. No Share: Novo processo, aba "Importar", "Arquivo Externo", selecionar o zip; confirmar.
3. Abrir o processo importado, publicar a criação, e seguir os passos 2 a 5 da forma B (o campo importado já está sem valor inicial, mas confirmar com o `SELECT` do passo 1).

Nota: a importação pela tela não foi concluída por QA (o diálogo de upload não devolveu o arquivo ao formulário na automação); por isso a forma B é a de referência.
