# Skills de QA — SmartShare / Arquitetura

Este diretório reúne as skills utilizadas pelo agente de QA da frente de **Arquitetura do SmartShare**. As skills orientam a análise de histórias, a elaboração e execução de mapas de testes, a investigação de falhas e a abertura de defeitos. Os conhecimentos reutilizáveis ficam na base local de `aprendizados/`.

O conteúdo foi preparado para ser compartilhado entre QAs e Devs. Antes de executar as skills em outra máquina ou projeto, siga a seção [Configuração obrigatória](#configuração-obrigatória). Os arquivos `.md` são instruções operacionais do agente; eles não substituem a configuração dos conectores MCP, o acesso ao Azure DevOps, os ambientes de teste ou as permissões do usuário.

> **Atenção:** `Variveis de Ambiente/variaveis-de-ambiente-smartshare.md` é um documento sensível e pode conter credenciais ou referências de infraestrutura. Não o publique em repositório aberto, não o envie em tickets e não mantenha senhas em texto puro. Cada usuário deve usar um cofre de segredos ou variáveis de ambiente locais e, antes de compartilhar esta pasta, revisar, sanitizar ou remover esse arquivo.

## Visão geral do fluxo

O fluxo recomendado é:

```text
História no Azure DevOps
        │
        ├─ 1. /arquitetura-analise-negocio
        ├─ 2. /arquitetura-analise-tecnica
        ├─ 3. /arquitetura-gerar-mapa-testes
        ├─ 4. /arquitetura-validar-ambiente
        ├─ 5. /arquitetura-executar-teste
        │       └─ falha → /arquitetura-analise-falha → /arquitetura-gerar-defeito
        └─ 6. correção → /arquitetura-validar-ambiente → /arquitetura-executar-teste (Modo B)
```

  As etapas 1 e 2 produzem contexto. A etapa 3 transforma esse contexto em cenários rastreáveis. A etapa 4 valida o ambiente e todas as massas. A etapa 5 executa os cenários com evidência. As etapas de falha e defeito tratam desvios. Os aprendizados relevantes são consultados antes das etapas e avaliados ao final de cada ciclo.

Nenhuma skill deve inventar regra de negócio, declarar aprovação sem evidência ou tomar sozinha uma decisão que exige aprovação humana. Os gates e confirmações descritos em cada arquivo fazem parte do contrato do fluxo.

## Skills disponíveis

| Arquivo | Finalidade | Entrada usual | Escrita externa |
|---|---|---|---|
| [`arquitetura-analise-negocio.md`](arquitetura-analise-negocio.md) | Extrair objetivo, regras, critérios, ambiguidades, dependências e riscos da história. | ID da história e projeto opcional. | Não; registra apenas o ciclo localmente. |
| [`arquitetura-analise-tecnica.md`](arquitetura-analise-tecnica.md) | Ler a análise técnica do Dev, cruzar com PR/diff e mapear impacto por camada. | ID da história e projeto opcional. | Não; registra apenas o ciclo localmente. |
| [`arquitetura-gerar-mapa-testes.md`](arquitetura-gerar-mapa-testes.md) | Criar/revisar mapa de testes arquitetural, cobrindo legado/novo, APIs, workers, jobs, integrações, banco, segurança, performance e observabilidade. | ID da história e projeto opcional. | Sim, após aprovação, no card filho de mapa de testes. |
| [`arquitetura-validar-ambiente.md`](arquitetura-validar-ambiente.md) | Validar conectividade, configuração, serviços e todas as massas necessárias em Oracle e SQL Server antes da execução; criar massas ausentes somente com autorização e liberar a rodada apenas após confirmação completa. | ID da história ou card `Criar Mapa de Teste`, projeto e ambiente opcionais. | Pode criar massa em banco não produtivo após autorização explícita; registra relatório e log local. |
| [`arquitetura-executar-teste.md`](arquitetura-executar-teste.md) | Executar os cenários do mapa no ambiente definido, coletar evidências e reportar resultado. Também suporta reteste seletivo de Bug. | ID da história ou Bug, projeto e ambiente opcionais. | Pode escrever resultados/logs locais; ações no Azure DevOps dependem do fluxo e de autorização. |
| [`arquitetura-analise-falha.md`](arquitetura-analise-falha.md) | Investigar falha, causa provável, componente afetado e suficiência da evidência. | ID da história/Test Case e descrição opcional. | Não cria Bug; registra o ciclo localmente. |
| [`arquitetura-gerar-defeito.md`](arquitetura-gerar-defeito.md) | Montar e criar Bug com rastreabilidade da falha. | ID da história/Test Case e projeto opcional. | Sim, somente após confirmação explícita. |

### Integração com Claude Code

  Para evitar cópias divergentes, a estrutura compatível com o Claude fica em [`claude-skills/`](claude-skills/). Cada subpasta contém um `SKILL.md` com hard link para a definição correspondente na raiz desta pasta. No workspace do SmartShare, as sete pastas de skill em `.claude/skills/` são junctions para essa fonte central.

Os diretórios de dados usados pelas skills — `aprendizados/`, `ciclos-execucao/` e `log/` — ficam fisicamente no workspace para que o visualizador do Claude consiga abrir os artefatos. A pasta de arquitetura mantém junctions reversas para esses diretórios, preservando um ponto central de consulta sem duplicar arquivos. `Variveis de Ambiente/` permanece separado por conter dados potencialmente sensíveis.

Inicie o Claude a partir da raiz que contém o `.claude` do SmartShare. O diretório central pode ser disponibilizado adicionalmente com `--add-dir` quando necessário; essa opção amplia os diretórios acessíveis, mas não substitui a raiz de trabalho do projeto.

## Configuração obrigatória

### 1. Azure DevOps e MCP

Antes de usar qualquer skill que consulte ou altere cards:

- Configure e autentique o servidor MCP `mcp__azure-devops` no ambiente de cada usuário.
- Confirme que as ferramentas usadas pelas skills estão disponíveis: leitura de work items, comentários, busca, relações, PRs, Wiki e escrita de work items/Wiki quando aplicável.
- Valide as permissões mínimas: leitura para análises; criação/edição de work items, anexos ou Wiki somente para quem realmente executará essas ações.
- Confira o nome da organização, o projeto padrão e o repositório. Não assuma que `SmartShare Arquitetura`, `SHARE-4` ou `smartshare-net8` existem no ambiente de todos.
- Preserve a regra de usar MCP para Azure DevOps. Se a equipe precisar de outra integração, documente a decisão e ajuste a skill inteira, incluindo validações, logs e tratamento de erros.

Os nomes de tipos e títulos também precisam ser confirmados no processo local, principalmente:

- card filho de análise técnica: `Análise`;
- card filho que recebe o mapa: `Criar Mapa de Teste`;
- tipo de item usado para Bug;
- relações de hierarquia e relações com PR/commit;
- campos customizados, como pontos de impacto e caso de teste;
- estados válidos e regras de transição.

Se algum nome ou campo diferir, altere as referências nas skills antes de executar o fluxo. Não basta trocar somente o texto de exemplo.

### 2. Ambiente de execução, navegador e credenciais

Para `arquitetura-executar-teste`, incluindo o Modo B de teste de confirmação, cada QA/Dev deve informar ou configurar:

- URL e nome de cada ambiente (`HMG`, QA local, DEV, Oracle, SQL Server etc.);
- usuário de teste, perfis, papéis e dados de autenticação;
- caminho do navegador/Chromium e disponibilidade do MCP de navegador `mcp__playwright`;
- diretório de evidências e política de retenção;
- SMTP/Mailer, quando um cenário puder disparar comunicação real;
- autorização necessária para ações irreversíveis ou que alterem dados.

As variáveis esperadas pelos scripts citados nas skills incluem `SS_TEST_USER`, `SS_TEST_PASSWORD`, `SS_OUTPUT_DIR`, `SS_BROWSER_PATH`, `SS_ACTION`, `SS_MODE`, `SS_PREFIX`, `SS_SMTP_USER`, `SS_SMTP_PASS` e `SS_FROM`. Os valores devem ser fornecidos em tempo de execução. Não substitua esses nomes por credenciais gravadas no Markdown sem revisar todas as skills que os utilizam.

### 3. Bancos, workers e integrações

Quando a história envolver processamento assíncrono ou persistência, documente para o ambiente do usuário:

- tipo de banco e versão;
- servidor/host, banco, schema, cliente e modo de autenticação;
- tabelas e consultas permitidas para leitura;
- quais escritas são permitidas, por quem e com qual autorização;
- procedimento de montagem e limpeza dos dados de teste;
  - método de acesso disponível para `/arquitetura-validar-ambiente`: MCP, adapter local aprovado ou cliente autorizado para evidência manual; MCP de Oracle/SQL Server não é obrigatório se outro método verificável existir;
  - configuração local não sensível do adapter, quando aplicável; a skill não instala driver nem altera a configuração global do MCP automaticamente;
- serviços/processos do Worker, Scheduler, ECM e integrações relacionadas;
- como coletar logs e qual evidência comprova cada resultado;
- diferenças entre legado e novo, incluindo a forma de validar paridade.

Os nomes e endereços de SQL Server, Oracle, serviços e instalações que aparecem nos ciclos existentes são exemplos do ambiente original, não valores padrão. Substitua qualquer caminho, host, cliente, banco, schema ou serviço antes de reutilizar a execução.

### 4. Caminhos locais e registro do ciclo

As skills gravam rastreabilidade local em:

- [`ciclos-execucao/README.md`](ciclos-execucao/README.md): índice dos ciclos;
- [`ciclos-execucao/COMO-REGISTRAR.md`](ciclos-execucao/COMO-REGISTRAR.md): procedimento de registro;
- [`ciclos-execucao/<task>-US<historia>/`](ciclos-execucao/): relatórios por etapa;
- [`log/LOG-ACOES.md`](log/LOG-ACOES.md): ações de escrita no Azure DevOps e execuções relevantes.
- [`aprendizados/README.md`](aprendizados/README.md): base persistente de conhecimentos reutilizáveis;
- [`aprendizados/COMO-USAR.md`](aprendizados/COMO-USAR.md): procedimento compartilhado de consulta e registro.

Se a pasta for movida, revise os caminhos absolutos e as instruções de registro dentro das skills. Para cada história, use uma pasta no formato `<id-da-task>-US<id-da-historia>`; nunca reutilize o ciclo de outra história.

O ciclo `ciclos-execucao/164259-US164251/` é um registro histórico de referência. Ele contém relatórios, SQL, logs e evidências de um ambiente específico; não deve ser usado como configuração nem como fonte automática de credenciais, IDs ou resultados atuais.

## O que cada pessoa deve revisar nas skills

Antes de considerar a instalação funcional, procure e substitua os valores específicos do ambiente:

1. **Organização, projeto e repositório do Azure DevOps:** nomes, URLs, IDs e convenções de área/iteration.
2. **Tipos, títulos e campos de cards:** `Análise`, `Criar Mapa de Teste`, campos customizados e relações.
3. **MCPs e conectores:** `mcp__azure-devops`, `mcp__playwright` e qualquer servidor de banco/log que a equipe adotar.
4. **Ambientes:** URLs, nomes, builds, branches, commits, serviços ativos e parâmetros de execução.
5. **Dados e credenciais:** variáveis locais, cofre de segredos, usuários de teste e perfis; nunca inserir segredo no `.md`.
6. **Banco e integrações:** SQL Server/Oracle, schemas, tabelas, permissões, scripts de montagem/limpeza e política de rollback.
7. **Aprendizados:** estrutura `aprendizados/`, índice, estados de confiabilidade e origem das entradas.
8. **Padrões de evidência:** diretório, formato, nomenclatura, retenção e anexação permitida no Azure DevOps.
9. **Identidade e aprovação:** nome do aprovador, gates obrigatórios, ações que exigem confirmação e pessoas responsáveis.
10. **Comandos e nomenclatura:** aliases registrados no agente, especialmente `/arquitetura-gerar-mapa-testes`, e o nome real do arquivo/skill correspondente.

Uma forma rápida de localizar possíveis pontos de adaptação é pesquisar nos `.md` por `D:\`, `C:\`, `http://`, `https://`, `HMG`, `Oracle`, `SQLServer`, `SmartShare Arquitetura`, `SHARE-4`, `smartshare-net8`, IDs numéricos e nomes de serviços.

## Ordem recomendada para uma nova história

1. Confirmar o ID da história, o projeto e a referência da task.
2. Rodar `/arquitetura-analise-negocio` e registrar o relatório.
3. Confirmar que o Dev preencheu o card `Análise`; então rodar `/arquitetura-analise-tecnica`.
4. Rodar `/arquitetura-gerar-mapa-testes`, revisar o mapa e aprovar a publicação.
  5. Rodar `/arquitetura-validar-ambiente` para conferir Oracle, SQL Server, serviços, configuração e todas as massas; autorizar e confirmar criações quando necessário.
  6. Rodar `/arquitetura-executar-teste` e registrar cada rodada com número novo; nunca sobrescrever etapa anterior. A skill de execução deve revalidar o gate antes do primeiro cenário.
  7. Para falhas, rodar `/arquitetura-analise-falha`; somente depois de evidência suficiente, usar `/arquitetura-gerar-defeito` com confirmação explícita.
  8. Após a correção de um Bug, rodar `/arquitetura-validar-ambiente` novamente e então `/arquitetura-executar-teste` no Modo B, registrando o reteste seletivo.
9. Conferir o ciclo local e o `log/LOG-ACOES.md`, removendo segredos e dados pessoais indevidos.

## Checklist de validação da instalação

- [ ] O agente consegue ler os arquivos `.md` desta pasta.
- [ ] O MCP Azure DevOps está conectado e retorna um work item de teste.
- [ ] O projeto e os tipos de item foram confirmados.
- [ ] O card `Análise` e o card `Criar Mapa de Teste` são localizáveis pelo fluxo.
- [ ] O MCP de navegador está disponível para cenários de UI.
- [ ] As credenciais são fornecidas de forma segura e não estão no repositório.
- [ ] O ambiente de teste, banco, worker/scheduler e logs foram validados.
  - [ ] `/arquitetura-validar-ambiente` confirmou conectividade e todas as massas aplicáveis em Oracle e/ou SQL Server.
  - [ ] O relatório `00-validacao-ambiente.md` está `LIBERADO PARA EXECUÇÃO` e sua assinatura ainda corresponde ao mapa, ambiente, build e banco atuais.
  - [ ] Massas criadas possuem autorização registrada, IDs rastreáveis e plano de limpeza/rollback.
- [ ] O diretório de evidências é gravável e não expõe dados sensíveis.
- [ ] O ciclo local pode ser criado e atualizado sem sobrescrever histórico.
- [ ] A pasta `aprendizados/` e `aprendizados/entradas/` existem ou podem ser criadas sem conflito.
- [ ] O índice de aprendizados foi consultado e os registros relevantes foram revalidados no contexto atual.
- [ ] Foi executada uma história não produtiva em modo de leitura antes de habilitar escritas.
- [ ] As ações com impacto externo têm gate de aprovação e ficam registradas.

## Governança e manutenção

Ao alterar uma skill:

- descreva a motivação e o impacto no fluxo;
- preserve os guardrails de evidência, confirmação humana e não invenção de requisitos;
- atualize exemplos, nomes de ferramentas, caminhos e este README quando necessário;
- registre a mudança em `Documentação da criação das Skills/`;
- registre também quais skills e procedimentos foram modificados no documento da alteração;
- teste primeiro uma história de baixo risco e registre o resultado em `ciclos-execucao/`;
- não inclua tokens, senhas, connection strings ou dumps de produção no diretório.

Em caso de divergência entre uma skill e o ambiente, trate a divergência como bloqueio de configuração e registre o que falta. Não contorne silenciosamente uma validação trocando MCP por REST, presumindo um resultado ou usando credenciais de outra pessoa.

