# Configurações necessárias para o cenário #64: Workflow/BPM com SQL externo

US #164849 · Mapa #164885 · Ambiente HMG · 2026-11-06 · Fonte: instrução da usuária (APR-016)

**Cenário #64 (mapa):** pré-requisito `[PROCESSO] fluxo de Workflow/BPM com consulta SQL em banco externo configurada`. Ação: executar o fluxo com consulta externa. Esperado: funciona como antes (regressão). O que se quer provar: a mudança da US (validação de SELECT e serviço de banco externo compartilhados) não quebra o Workflow.

**Status do requisito no HMG (2026-11-06):** `NAO ATENDIDO`. Hoje o front `/bpm` responde 502, e o ECM-BE e o `SmartShareAPI` também; o BE do BPM (`/Share4/be/bpmApi/`) responde (403). Não há processo identificado com os passos abaixo.

## O que preparar

| # | Configuração | Detalhe | Fonte |
|---|---|---|---|
| 1 | **Serviços no ar** | Front do BPM (`/bpm`), BE do BPM, e o **agente do net8** (motor que executa os passos de banco e de comitê, `AgentBpmService`) | `/bpm` 502 observado; consumidores sem endpoint HTTP (147 rotas no Swagger) |
| 2 | **Conexão externa ativa e acessível** | SQL Server, Oracle, PostgreSQL ou Firebird, ligada a um perfil do usuário que modela e executa o fluxo. Nota: o PostgreSQL do HMG não conecta (falta o driver ODBC/DSN no servidor da API) | `GET /api/TipoBanco`; teste do #63 |
| 3 | **Modelo de processo com passo de banco de dados** | Um passo que usa a conexão do item 2 e executa SQL. O agente chama `ExecuteWorkflowFirstRow` (consulta) e `ExecuteWorkflowNonQuery` (comando de escrita, INSERT/UPDATE), os dois com `validateSingleColumnScript: false`, isto é, **sem** a validação de SELECT | `AgentBpmService.cs:1336` e `:1354` |
| 4 | **Consulta externa do Comitê** (opcional, é o ponto de maior risco) | Comitê com `ds_comando_sql` e `cd_conexao`. A consulta passa pela validação compartilhada (`ExternalDbSqlIntercept`) e é lida como lista de **inteiros** (uma coluna) | `ComiteService.cs:125`, `DBTranslator.cs:334-339` |
| 5 | **Usuário e perfis de workflow** | Usuário que inicia o processo e executa as tarefas, com os perfis de criador de processo e de lista de tarefas (aba Workflow do perfil) | `GET /api/Perfil/GetWorkflowProfilesTab` |
| 6 | **Massa no banco externo** | Para o passo de escrita, uma tabela de teste inócua no banco externo, mais um registro a consultar | a definir pelo dev |
| 7 | **Instância do fluxo** | Iniciar o processo (pelo front ou pela API do BPM-BE) e esperar o agente executar | n/a |

## Cuidados
- O passo de banco **pode gravar no banco externo**. Só executar com comando inofensivo (por exemplo, um `UPDATE` que não casa nenhuma linha) e **com a confirmação da usuária** antes do passo.
- Criar o modelo de processo, o Comitê e os perfis é criar configuração para teste: seguir o APR-015 (ler a regra legada de criação antes) e citar `arquivo:linha`.
- Sem os commits da US no hub (`main`), o risco de regressão só se confirma com a build entregue: o **Comitê** passa pela validação compartilhada; o **passo de banco do Workflow** está isolado pelo flag.

## Responsável
Cenário encaminhado ao dev em 2026-11-06 (mensagem pronta no chat). Esta lista deve ir no relatório do próximo `/validar-ambiente` da US.
