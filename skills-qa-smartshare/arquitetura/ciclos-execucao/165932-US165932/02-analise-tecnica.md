# Etapa 02 — Análise técnica — #165932 Novo Agent | Configuração | Acesso, estrutura e status geral

- **Skill:** `/arquitetura-analise-tecnica` — argumento `165932`
- **Data:** 2026-11-12 (após etapa 01)
- **Escreveu no Azure DevOps:** não (somente leitura)
- **Aprovação:** não aplicável
- **Fontes lidas:** card `Análise` #166455 (tipo `Análise`, estado Done, rev 14, campos Pontosdeimpacto, CasodeTeste, Descrição, Classes alteradas, Classes novas, Branch); história #165932 (rev 8) e filhos. Card #166789 (`Criar Mapa de Teste`, New) ignorado como fonte. Comentários: 0. PR: **nenhum vinculado**; busca por branch `feature/US165932-tela-configuracao-agent` nos repositórios `smartshare-net8`, `smartshare-analytics` e `SmartShare` (projeto SmartShare Arquitetura) retornou vazio. Código não lido (regra da skill).

## Aprendizados consultados

Consulta realizada — nenhum aprendizado aplicável encontrado.

# Análise Técnica — #165932 Novo Agent | Configuração | Acesso, estrutura e status geral

**Card de Análise:** #166455 (Done; criado 09/11, alterado 11/11 14:37; responsável Luis Fernando Bertucci)
**PR vinculado:** nenhum vinculado ainda
**Branch declarada no card:** `feature/US165932-tela-configuracao-agent`
**Repositórios:** smartshare-net8 (API), smartshare-analytics (front), SmartShare clássico (scripts de banco). Banco: SQL Server e Oracle ("Todos"). Navegador: sim. Idiomas: sim (pt/en/es).

## O que foi alterado (origem: análise do dev, card #166455)
**Banco (clássico):** `0.2 PreEstrutura.sql` e `Oracle/0.3 PreEstrutura.sql` (CREATE TABLE `AGENT_CONFIGURACAO`, linha única; Oracle sem sequence/trigger, datas `DATE`); `0.1 PreCarga.sql` e `Oracle/0.4 PreCarga.sql` (seed `(1, NULL, 0, 0, NULL, NULL, NULL)`, `TIPO_APLICACAO` 119, `TIPO_ACAO` 67–71, `TIPO_APLICACAO_TIPO_ACAO`).
**API net8 — alterados:** `ETipoAcao` (67–71), `Share4UserAuthorizationMiddleware` (`/SmartShareAgent` em rota de gerenciamento; rota nova `/Acesso` sem bloqueio), `HttpContextShare4Extensions`/`ICurrentUser` (role Share4), `ApiController` (sobrecarga `ReturnResponse(data, statusOnError)`), `DependencyInjection`, pacote `System.ServiceProcess.ServiceController`.
**API net8 — novos:** `AgentConfiguracao`, `AgentConfiguracaoFilter`, `AgentConfiguracaoRepository` (leitura + escrita: `GravarNomeBase`, `LimparNomeBase`, `TentarIniciarOperacao` atômico, `RenovarOperacao`, `EncerrarOperacao`, `AtualizarRetencaoLog`), enums `ESituacaoAgent`/`EStatusServicoAgent`/`EOperacaoAgent`, `IAgentServiceStatusReader`, `WindowsServiceStatusReader`, `SmartShareAgentService` (status, `ValidarPodeAlterar()`, `PrazoExpiracaoOperacao`), `SmartShareAgentValidacaoKeys`, `SmartShareAgentAuditoriaService`, DTOs, `SmartShareAgentController` (GET `api/SmartShareAgent/Status`), `AcessoController` (GET `api/Acesso/Administrador`).
**Front analytics — alterados:** `api-routes.ts`, `settings-hub-card.model.ts` (`requiresAdmin`), `settings-hub.component.ts`, `share-user-auth.interceptor.ts`, `gerenciamento.routes.ts`, `pt/en/es.json`.
**Front analytics — novos:** `smartshare-agent.component`, `adminGuard`, `smartshare-agent-status.store` (polling 30 s, timeout 10 s, `podeAlterarServidor`), `smartshare-agent.service`, `acesso.service` (cache por token Share4), `smartshare-agent-badge.helper`, model e constants.

## Onde foi alterado (por camada)
| Camada | Alterado | Risco | Justificativa |
|---|---|---|---|
| Banco (SQL Server e Oracle) | tabela nova, seed, tipos de aplicação/ação | **Alto** | Scripts entram no atualizador de banco dos clientes; paridade entre dois bancos; seed e FK de log. (análise do dev) |
| API — segurança (middleware, role) | `Share4UserAuthorizationMiddleware`, `HttpContextShare4Extensions`, `AcessoController` | **Alto** | Afeta todas as rotas de gerenciamento e dashboard; é o controle de acesso crítico (CV-01). (análise do dev) |
| API — código compartilhado | `ApiController` | **Médio** | Sobrecarga aditiva em classe base de todos os controllers; exige regressão do 500 atual. (análise do dev) |
| API — serviço/domínio | `SmartShareAgentService`, reader Windows, auditoria | **Médio** | Núcleo do status (CV-02/03); depende do SCM do Windows e de permissão do App Pool. (análise do dev) |
| API — repositório | `AgentConfiguracaoRepository` | **Médio** | Escrita atômica e flag com expiração de 5 min; sem endpoint nesta US, consumido por 165934/165935/165938. (análise do dev) |
| Integração externa | SCM do Windows (`ServiceController`) | **Alto** | Windows-only; permissão de leitura da identidade do App Pool é lacuna declarada. (análise do dev) |
| Front — roteamento/guard/interceptor | `adminGuard`, rotas, `share-user-auth.interceptor` | **Médio** | Controle de acesso no front e header Share4 em segmentos novos; `authRetryInterceptor` manda 403 ao login. (análise do dev) |
| Front — tela/store/helper | componente, store, badge helper | **Médio** | Regra de precedência do badge e das abas concentrada no helper; polling e estados (CV-02/04). (análise do dev) |
| Front — i18n | `pt/en/es.json` | **Baixo** | Paridade de chaves; primeira tela de gerenciamento com i18n. (análise do dev) |

## Dependências diretas (origem: análise do dev)
- `SmartShareAgentController` → `SmartShareAgentService` → `AgentConfiguracaoRepository` + `IAgentServiceStatusReader` (→ `WindowsServiceStatusReader` → SCM).
- `adminGuard` e hub de Configurações → `acesso.service` → `GET api/Acesso/Administrador` → middleware (role Share4).
- Tela → store → `smartshare-agent.service` → `GET api/SmartShareAgent/Status`.
- `SmartShareAgentAuditoriaService` → `ILogAplicacaoRepository.InsertLog` (tabela `LOG_APLICACAO`).
- Serviços do Windows com nomes `<nome base>_ECM`, `_BPM`, `_Scheduler`; `Environment.MachineName`.

## Dependências indiretas
- US 165934 a 165940 consomem DTO de status, `AGENT_CONFIGURACAO`, flag de operação (`RenovarOperacao`/`TentarIniciarOperacao`), `ValidarPodeAlterar()`, `podeAlterarServidor`, auditoria, regra de abas do helper e métodos de escrita do repositório.
- Todos os controllers herdam `ApiController`; todas as rotas de gerenciamento/dashboard passam pelo middleware.
- Atualizador de banco dos clientes recebe os scripts de PreEstrutura/PreCarga.
- Front das US de ação diferencia 409 (`AGENT_OPERACAO_EM_ANDAMENTO`) e 424 (`AGENT_SCM_INDISPONIVEL`) por `errors[].code`.

## Funcionalidades potencialmente impactadas
- Hub de Configurações (primeiro card filtrado por perfil).
- Todas as telas e APIs de gerenciamento e dashboard (middleware).
- Fluxo de login/redirecionamento do analytics (`authRetryInterceptor`, 401/403).
- Demais telas da série do Agent (165934–165940).

## Integrações potencialmente impactadas
- SCM do Windows via `ServiceController` (consulta); identidade do App Pool IIS.
- Header `X-User-Authorization` (Share4) nos novos segmentos `SmartShareAgent` e `Acesso`.
- Registro de log via `LOG_APLICACAO`.

## Dados potencialmente impactados
- Tabela nova `AGENT_CONFIGURACAO` (SQL Server e Oracle) e seed.
- `TIPO_APLICACAO` 119, `TIPO_ACAO` 67–71 e `TIPO_APLICACAO_TIPO_ACAO`; `LOG_APLICACAO` (registros futuros).
- Oracle: colunas de data `DATE` (sem milissegundos); sem sequence/trigger.

## Discrepâncias entre análise do dev e o PR (se houver)
Sem PR vinculado: **cruzamento com o diff não realizado**. Nenhum arquivo em discrepância apurável.

### Dentro do escopo da US
Não apurável (sem PR).

### Fora do escopo da US
Não apurável (sem PR).

### Discrepâncias entre o card e a história (lidas nos textos, sem código)
- Card diz "Validada contra a US rev 7"; a história lida está na **rev 8**. A diferença entre revs não foi verificada. Risco: regra alterada na rev 8 não refletida no card.
- CA-08: a história diz que serviços "Desconhecido" se conferem visualmente após 165935/165937; o card diz que **nesta US o CA-08 se verifica no DTO e na store** (a tela não lista serviços). Critério de verificação diverge.
- Card define regras que a história **não escreve**: abas em "Instalando..." (cadeado, desabilitadas), "Instalação incompleta" (abas liberadas), "Atualizando serviços..." (abas habilitadas), "Servidor indisponível" na abertura (abas desabilitadas sem cadeado), timeout de 10 s para indisponível, `Paused` conta como Parado, 403 para não-admin em `Status`. São decisões técnicas, sem confirmação de negócio na história.
- Card afirma que o texto "Acesso negado" usa `NotificationService.warning()`; a história não define o tipo do toast.

## Versão analisada x implantada
| Item | Valor |
|---|---|
| Esperado | branch `feature/US165932-tela-configuracao-agent`; build com PR (não existente) |
| Encontrado | nenhum PR, build ou commit identificado |
| Verificação | busca de PR por branch em 3 repositórios; implantação não consultada |
| Resultado | **NÃO VALIDADO** — **BLOQUEANTE PARA EXECUÇÃO** (sem build identificado, o comportamento testado pode divergir) |

## Casos de teste sugeridos pelo dev (card #166455, sugestão do dev, não validada pelo QA)
1. Admin abre Configurações, vê o card e abre na aba Instalação (CA-01).
2. Não admin: card não aparece (CA-02).
3. Não admin acessa `/management/smartshare-agent`: volta a Configurações com toast "Acesso negado" não modal (rodapé, 5 s, fechar) e nenhuma chamada a `SmartShareAgent/Status` sai (CA-03, CA-14).
4. Não admin chama `GET api/SmartShareAgent/Status`: 403; `GET api/Acesso/Administrador`: 200 com false.
5. `ds_nome_base` NULL: "Não instalado", Controle/Logs desabilitadas com cadeado e mensagem, sem servidor (CA-04).
6. Instalado com 3, 0 e 2 serviços: badges de sucesso, neutro e atenção; 3 abas e servidor (CA-05, CA-06).
7. Serviço parado em `services.msc`: badge muda em até ~30 s sem recarregar (CA-07).
8. API fora do ar ou SCM inacessível, admin na aba Logs: permanece em Logs, "Servidor indisponível", mensagem abaixo das abas, `podeAlterarServidor` falso, serviços Desconhecido na store; recupera sozinho (CA-08, CA-09).
9. Na aba Logs, 3 serviços removidos por fora: volta para Instalação, "Não instalado", abas bloqueadas (CA-10).
10. 1 de 3 serviços removido: "Instalação incompleta", abas liberadas.
11. StartPending/StopPending: "Atualizando serviços..."; Paused conta como Parado.
12. `st_operacao = 1` renovado há menos de 5 min: "Instalando..."; sem renovação há mais de 5 min a flag é ignorada.
13. Auditoria com sucesso e falha em `LOG_APLICACAO` (119, 67–71), sem senha (CA-11).
14. Aba do navegador oculta: polling pausa e volta; sem chamada no SSR.
15. Textos em pt/en/es com paridade de chaves.
16. Leitura de `AGENT_CONFIGURACAO` em Oracle e SQL Server; script Oracle sem sequence/trigger, seed e `DATE`.
17. Meta de 3 s em homologação com App Pool iniciado e cache de acesso vazio (DevTools: Acesso + Status); repetir por URL direta.
18. Antes da primeira resposta: "Verificando status..." com carregamento, abas desabilitadas sem cadeado; sem resposta em 10 s, "Servidor indisponível" (CA-12).
19. "Instalando...": Controle/Logs desabilitadas com cadeado e mensagem.
20. Outro admin desinstala com você na aba Controle: volta para Instalação, "Desinstalando...", abas sem cadeado; ao concluir, "Não instalado" com cadeado (CA-13, CV-04).
21. "Atualizando serviços...": 3 abas habilitadas.
22. SCM inacessível com API no ar: `Status` 200, `situacao = ServidorIndisponivel`, serviços Desconhecido, `nomeBase`/`nomeServidor` preenchidos.
23. Indisponível já na abertura: Controle/Logs desabilitadas sem cadeado.
24. `ValidarPodeAlterar()`: 424 `AGENT_SCM_INDISPONIVEL`; 409 `AGENT_OPERACAO_EM_ANDAMENTO`; code nunca "ERROR"; aceita com flag expirada; nunca vai ao login.
25. Troca de usuário sem reload: cache descartado, não-admin recebe toast "Acesso negado" sem ir ao login (CA-03).
26. Toast no rodapé, com tipo e fechar; some em 5 s; fechar remove antes (CA-14).
27. Renovações da flag: `dtInicio` fixo, `dtRenovacao` avança.
28. `ReturnResponse(data, status)`: sem notificações 200; com notificações o status informado; `ReturnResponse(data)` com notificações continua 500.
29. `AgentConfiguracaoRepository` (SQL Server e Oracle): `TentarIniciarOperacao` (1 linha / 0 linha / vencida = 1), `RenovarOperacao`, `EncerrarOperacao`, `GravarNomeBase`, `LimparNomeBase`, `AtualizarRetencaoLog`; sem dependência de milissegundos.

## Pré-requisitos técnicos de execução de teste
- **Banco:** scripts PreEstrutura/PreCarga aplicados em SQL Server e Oracle (tabela, seed 1, tipo de aplicação 119, ações 67–71). Informação não encontrada / necessita validação: se os scripts já estão aplicados nos ambientes de teste. **Bloqueante para `/arquitetura-executar-teste`.**
- **Estado "Instalado":** a gravação de `ds_nome_base` e dos serviços `<nome base>_ECM/_BPM/_Scheduler` depende de instalação manual + `UPDATE` em `AGENT_CONFIGURACAO` (a 165934 ainda não entrega o instalador). `UPDATE` de massa exige autorização do dono (regra 4 do workspace). Informação não encontrada / necessita validação: nome base e procedimento de massa. **Bloqueante.**
- **Estados "Instalando..."/"Desinstalando...":** exigem `st_operacao`/`dt_renovacao_operacao` por `UPDATE` direto (nenhum endpoint desta US escreve). Mesma autorização. **Bloqueante para CA-13 e caso 12.**
- **SCM com falha só do SCM (API no ar):** o card não descreve mecanismo para reproduzir (casos 8, 22, 24). Informação não encontrada / necessita validação: feature flag, permissão negada ao App Pool ou stub. **Bloqueante para esses casos.**
- **API fora do ar:** reprodutível parando o App Pool/site (card caso 8); confirmar com o dono do ambiente.
- **Permissão do SCM para a identidade do App Pool:** lacuna declarada pelo dev, a confirmar em homologação. **Bloqueante para execução em qualquer caso de status.**
- **Plataforma:** API em Windows/IIS (premissa do card); ambiente de teste deve ser Windows com os serviços do Agent presentes. Logs, tela com i18n e `NotificationService` (5 s) no front.
- **Perfis:** um usuário admin e um não admin com token Share4 válido. Informação não encontrada / necessita validação: usuários de teste.
- **CA-11 (auditoria):** `SmartShareAgentAuditoriaService` não é chamado por nenhum endpoint desta US (consumido por 165934–165938). Só testável em nível de serviço/unitário aqui; conferência em `LOG_APLICACAO` end-to-end depende das US de ação.
- **Meta de 3 s:** só medível com App Pool iniciado; partida a frio do IIS fica fora (mitigação de infra: AlwaysRunning + preloadEnabled).

## Informações ausentes
- Informação não encontrada / necessita validação: PR/build vinculado e versão implantada (BLOQUEANTE PARA EXECUÇÃO).
- Informação não encontrada / necessita validação: diferença entre US rev 7 (base do card) e rev 8 (lida nesta análise).
- Informação não encontrada / necessita validação: confirmação de negócio das regras só do card (abas em Instalando/Incompleta/Atualizando, timeout 10 s, `Paused` = Parado, 403 em `Status`).
- Informação não encontrada / necessita validação: critério de verificação do CA-08 (visual após 165935/165937 x DTO e store).
- Informação não encontrada / necessita validação: permissão de leitura do SCM para o App Pool (lacuna do dev).
- Informação não encontrada / necessita validação: se scripts de banco já estão aplicados e quem autoriza as massas.
- Informação não encontrada / necessita validação: mecanismo para falha só do SCM.
- Diff real não analisado: classes realmente alteradas e arquivos fora do escopo não apuráveis.

## Pendências desta etapa
- Vincular PR/informar build e confirmar versão implantada antes de executar.
- Rodar `/arquitetura-analise-tecnica 165932` de novo quando houver PR, para cruzar o diff.
- Confirmar rev 7 x rev 8 com o dev.
