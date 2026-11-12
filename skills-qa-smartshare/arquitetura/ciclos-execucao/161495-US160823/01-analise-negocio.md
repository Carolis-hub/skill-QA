# Etapa 01 — Análise de Negócio — #160823 Rotina - Inicio Desassociar Automático

- **Skill:** `/arquitetura-analise-negocio #160823`
- **Data:** 2026-11-04 11:27
- **Escreveu no Azure DevOps:** não (somente leitura)
- **Aprovação:** N/A (sem gate)
- **Fontes lidas:** work item 160823 (rev 6, expand all), 1 comentário (referência Productboard), relações (somente contagem/tipo; cards filhos não usados)

## Aprendizados consultados

Consulta realizada — nenhum aprendizado aplicável encontrado. (`aprendizados/INDICE.md` vazio.)

---

# Análise de Negócio — #160823 Rotina - Inicio Desassociar Automático

**Projeto:** SmartShare Arquitetura | **Tipo:** Product Backlog Item | **Status:** Committed | **Sprint:** Sprint 4 | **Responsável:** Vinicius Medeiros dos Santos | **Pai:** #151954

> A história não tem critérios de aceite preenchidos (`Microsoft.VSTS.Common.AcceptanceCriteria` ausente). Os comportamentos abaixo derivam só da descrição.

## Objetivo da alteração
Migrar a rotina "Inicio Desassociar Automático" do Agent legado para o novo Agent, no novo padrão de desenvolvimento. (descrição)

## Comportamentos esperados (contratos verificáveis)
- Quando o novo Agent for executado, o sistema deve executar a rotina "Inicio Desassociar Automático" no novo Agent. (descrição)
- Quando a tela de configuração do SmartShare listar as rotinas, o sistema deve exibir "Inicio Desassociar Automático" na listagem. (descrição)
- Quando o serviço rodar, o sistema deve gravar nos logs o código do fluxo e da tarefa que estiver manipulando. (descrição)
- Quando houver outra informação relevante sendo tratada, o sistema pode registrá-la em log (opcional). (descrição)

## Regras explícitas
- A rotina é migrada para o novo Agent, no novo padrão de desenvolvimento. (descrição)
- A rotina aparece na listagem de rotinas da tela de configuração do SmartShare. (descrição)
- O log deve conter código do fluxo e código da tarefa manipulados. (descrição)
- Informações adicionais importantes "poderão" ser logadas — facultativo. (descrição)

## Regras implícitas
- IMPLÍCITA: paridade com o legado — a rotina nova deve produzir o mesmo efeito de negócio que a legada ("migração"). Raciocínio: a história pede migrar, não redefinir. O comportamento do legado não está descrito na história.
- IMPLÍCITA: a rotina legada deixa de executar quando a nova assumir (evitar dupla execução). Não dito; precisa validação.
- IMPLÍCITA: log por item processado (fluxo + tarefa), não só por execução. Raciocínio: "que estiver manipulando".
- IMPLÍCITA: a rotina na listagem de configuração segue o comportamento das demais rotinas migradas (ativar/desativar, parametrizar). Não dito.

## Condições e exceções
Nenhum identificado na história (sem critérios de aceite). Nada sobre falha, ausência de itens a processar, ou permissão de acesso à tela de configuração.

## Dependências
- Pai #151954 (contexto da migração de rotinas do Agent). Conteúdo não lido nesta etapa.
- Novo Agent e tela de configuração de rotinas já existentes. (descrição, "novo Agent", "listagem de rotina")
- 5 cards filhos (#161471, #161476, #161481, #161485, #161490) e a task de teste #161495. Não usados nesta etapa.
- Referência Productboard (hyperlink e comentário). Não acessível por esta skill.

## Informações ausentes
- Informação não encontrada / necessita validação: o que a rotina "Inicio Desassociar Automático" faz de negócio (o que desassocia, de quê, de quem)?
- Informação não encontrada / necessita validação: qual a condição de disparo (regra de tempo, status, prazo) para desassociar automaticamente?
- Informação não encontrada / necessita validação: qual a periodicidade de execução esperada?
- Informação não encontrada / necessita validação: critérios de aceite da história (não há).
- Informação não encontrada / necessita validação: o que acontece quando não há itens a desassociar ou quando um item falha?
- Informação não encontrada / necessita validação: a rotina legada é desativada na migração, ou convive com a nova?
- Informação não encontrada / necessita validação: nível/formato do log (informação, aviso, erro) e se registro por item é obrigatório.

## Ambiguidades
- "Inicio Desassociar Automático": "Inicio" pode ser a etapa inicial de um processo de desassociação (com uma rotina de "fim" separada) ou parte do nome da rotina legada. A história não explica.
- "Fluxo e tarefa": código do fluxo/tarefa do workflow BPM, ou outra entidade? Sem definição na história.
- "Novo padrão de desenvolvimento": padrão do Agent .NET 8 / Quartz? Não detalhado.
- "Poderá ser logado": informação adicional é opcional, mas não se sabe se há mínimo exigido além de fluxo/tarefa.

## Riscos identificados
- Sem descrição do comportamento do legado nem critérios de aceite: risco de migrar sem paridade e de não haver base objetiva de aceite.
- Dupla execução (legado + novo) pode desassociar o mesmo item duas vezes.
- Desassociação automática errada pode perder vínculo de tarefas/fluxos em produção.
- Log ausente ou incompleto dificulta auditoria e suporte.
- Rotina não visível na tela de configuração impede operação e desativação.

## Prontidão para as próximas etapas

| Gate | Resultado |
|---|---|
| Prontidão para análise técnica | APTA COM RESSALVAS — depende do card de Análise preenchido e do PR; o negócio da rotina precisa ser buscado no código legado |
| Prontidão para geração do mapa | APTA COM RESSALVAS — sem AC; só cenários de paridade e de log/listagem com base na descrição. Regra de negócio da rotina fica como lacuna |
| Prontidão para execução | BLOQUEADA — sem regra de negócio nem critério de aceite confirmados; dependente de PR/build e ambiente |

---

## Pendências
- Confirmar com PO/analista o comportamento de negócio e critérios de aceite.
- Obter, em `/arquitetura-analise-tecnica`, o comportamento da rotina legada.
