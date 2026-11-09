# Template ideal — Card de Análise Técnica (dev) para suportar as skills de QA

Este template cobre os campos do card `Análise` do Azure DevOps na ordem em que as skills de QA
(`/analise-tecnica`, `/gerar-mapa-testes-v3`, `/executar-teste`) os consomem. Preencher mesmo que
de forma breve — campo vazio é tratado como bloqueio, não como "sem impacto".

---

## 1. Alteração Técnica (narrativa)

> Descrever a mudança **desta história**, não uma visão geral do sistema. Se o sistema já tem
> documentação de arquitetura, linkar em vez de reescrever.

- **O que mudou e por quê** (1–3 parágrafos, direto ao ponto):
  - Exemplo ruim: "Ajustes no back-end." (genérico demais, vira "informação ausente" para o QA)
  - Exemplo bom: "O método `AcquireNextDocumentForProcessingAsync` passou a filtrar documentos com
    `st_revisao = 0` antes de enfileirar; antes isso não existia e causava reprocessamento duplicado."
- **Camada(s) tocada(s):** [ ] Front-end [ ] API [ ] Serviço/domínio [ ] Banco de dados [ ] Integração externa [ ] Job/agendador

## 2. Pontos de impacto (`Custom.Pontosdeimpacto`)

> Lista objetiva de classes/métodos/componentes alterados ou criados, e o que muda no comportamento
> de cada um. É o campo mais usado por `/analise-tecnica` para montar dependências e risco.

| Classe/Método/Componente | Tipo de mudança | Comportamento antes → depois |
|---|---|---|
| ex.: `DocumentoDIRepository.AcquireNextDocumentForProcessingAsync` | Alterado | Antes: não filtrava `st_revisao`. Depois: ignora documentos com `st_revisao = 0` duplicado. |

- **Quem depende disso (chamadores diretos/indiretos conhecidos):**
- **O que pode ser impactado mesmo sem alteração direta** (efeito cascata):

## 3. Alteração de Classe/Tela

> Nome exato das telas/classes **existentes** que mudaram — usado literalmente no passo a passo do
> mapa de testes (o QA copia o nome exato, não parafraseia).

- Tela/Classe:
- O que mudou nela (campo novo, validação nova, botão removido etc.):

## 4. Criação de Classe/Tela

> Mesma lógica do item 3, mas para telas/classes **novas**.

- Tela/Classe criada:
- Onde ela é acessada/chamada a partir de:

## 5. Detalhes Técnicos

| Campo | Preencher com |
|---|---|
| Classe/Tela a ser alterada | nome exato |
| Classe/Tela a ser Criada | nome exato |
| Banco de dados | Sim/Não + tabela(s)/script(s) envolvidos |
| Repositório | nome do repositório de código |
| Navegador | aplicável? quais navegadores foram testados/homologados pelo dev |
| Idiomas | aplicável? quais idiomas afetados |
| Impacto na Liberação? | Sim/Não — se a mudança é visível para o cliente final ou só interna |

## 6. Caso de Teste (`Custom.CasodeTeste`)

> Sugestão do dev para pelo menos 1 cenário positivo e, se souber, 1 negativo. Não precisa ser
> exaustivo — o QA valida e expande. Mas sem nenhum, o mapa de testes perde o ponto de partida.

- Cenário sugerido 1 (positivo):
- Cenário sugerido 2 (negativo/borda), se souber:

## 7. Pré-requisitos técnicos de execução de teste

> Crítico para `/executar-teste` em cenários negativos/de borda que dependem de simular falha técnica
> ou configuração de ambiente. Sem isso, o QA não consegue reproduzir o cenário e o teste fica
> "bloqueado" por falta de insumo, não por reprovação real.

- Configuração real usada (nome de bucket, variável de ambiente, URL, endpoint):
- Existe mecanismo para simular a falha em ambiente de teste? (feature flag / credencial inválida
  proposital / mock-stub / LocalStack / outro):
- Se não existir mecanismo, declarar isso explicitamente (evita o QA "quebrar a cabeça" tentando
  reproduzir algo que o próprio dev sabe que não é simulável hoje):

## 8. Vínculos obrigatórios

- **Pull Request:** linkar na seção "Development" do work item (permite ao QA cruzar card × diff real
  e detectar divergências).
- **Branch/Repositório do Projeto:** preencher na seção "Projeto" do work item.

## 9. Discussion / comentários

> Qualquer esclarecimento adicional, decisão tomada em reunião, ou resposta a dúvida de QA/Análise
> Review deve ficar registrada aqui — não apenas falada verbalmente.

---

## Checklist rápido antes de marcar o card como "Done"

- [ ] Pontos de impacto preenchido com classes/métodos reais (não a arquitetura geral do sistema)
- [ ] Caso de Teste com pelo menos 1 cenário
- [ ] Alteração/Criação de Classe/Tela com nomes exatos (se aplicável)
- [ ] Detalhes Técnicos preenchidos (ou marcados como "N/A" quando não aplicável — não deixar em branco)
- [ ] PR vinculado em Development
- [ ] Pré-requisitos técnicos de teste descritos para qualquer cenário negativo/de falha
- [ ] Acceptance Criteria da US (não deste card) revisado — a análise cobre todos os critérios?
