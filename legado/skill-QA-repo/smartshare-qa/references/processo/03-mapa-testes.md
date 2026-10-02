# Etapa 03 — Mapa de Testes (QA Test Designer)

**Objetivo:** transformar regra de negócio, critérios de aceite e pontos de impacto em um conjunto **completo e não redundante** de cenários. Não basta converter cada critério em um teste — aplique raciocínio de QA e técnicas formais.

## Base de conhecimento a consultar
- `product-knowledge/03-regras-negocio.md` — cada RULE-XXX envolvida deve ter cenário
- `product-knowledge/04-estados-workflows.md` — base para transição de estados e negativos por status
- `product-knowledge/07-permissoes-seguranca.md` — perfis reais para os cenários de permissão
- `product-knowledge/10-riscos-qa.md` — RISK-XXX da área viram cenários prioritários
- `product-knowledge/11-testes-existentes.md` — evitar redundância e reaproveitar cobertura existente
- `complementar/fluxos-criticos.md` — define prioridade Alta

Na tabela do mapa, inclua a coluna **Rastreabilidade** (RULE/RISK/Q relacionados).

## Entradas
US, regras, critérios de aceite, pontos de impacto (etapa 02), documentação, testes existentes, histórico de defeitos.

## Raciocínio esperado
Para a regra *"O usuário pode alterar o documento somente se estiver no status X"*, gere no mínimo:

| Tipo | Cenário |
|---|---|
| Positivo | Status X permite alteração |
| Negativo | Cada outro status relevante (Y, Z...) bloqueia alteração |
| Permissão | Usuário sem permissão tenta alterar (UI **e** API) |
| Dados | Documento inexistente / excluído |
| Concorrência | Documento alterado simultaneamente por dois usuários |
| Transição | Documento muda de status durante a edição |
| Regressão | Fluxo anterior continua funcionando |

## Técnicas — quando usar
- **Partição de equivalência:** entradas com classes de valores (tipos de documento, perfis, formatos). Um teste por classe válida e inválida.
- **Análise de valor limite:** campos com mínimo/máximo (tamanho, quantidade, datas, valores). Teste min-1, min, max, max+1.
- **Tabela de decisão:** regras com múltiplas condições combinadas (perfil × status × tipo). Uma coluna por combinação relevante.
- **Transição de estados:** entidades com ciclo de vida/status. Teste transições válidas e inválidas.
- **Pairwise:** muitas combinações de parâmetros — reduza mantendo cobertura de pares.
- **Teste exploratório orientado a charter:** áreas novas ou pouco documentadas. Defina missão, área, tempo e riscos a explorar.

Cite a técnica usada em cada grupo de cenários.

## Checklist de cobertura (percorrer sempre)
- [ ] Todos os critérios de aceite têm ao menos um cenário positivo
- [ ] Negativos para cada condição restritiva
- [ ] Bordas: vazio, nulo, espaços, caracteres especiais/acentos, tamanho máximo, zero, datas limite
- [ ] Permissões: cada perfil relevante + acesso direto por URL/API
- [ ] Integrações afetadas
- [ ] Performance: volume alto, anexos grandes, listas longas
- [ ] Segurança: injeção, manipulação de ID na requisição, exposição de dados
- [ ] Usabilidade: mensagens, feedback visual, responsividade
- [ ] Dados legados/existentes após a mudança
- [ ] Regressão das áreas apontadas na análise técnica e no histórico de defeitos

## Prioridade
- **Alta:** fluxo crítico, critério de aceite principal, segurança/permissão, área com histórico de defeito.
- **Média:** variações relevantes, integrações secundárias.
- **Baixa:** cosmético, cenários raros de baixo impacto.

## Formato de saída

Primeiro a visão resumida (mapa):

```
## Mapa de Testes — <US-ID> <título>

| ID | Cenário | Tipo | Técnica | Prioridade | Automação? | Rastreabilidade |
|---|---|---|---|---|---|---|
| CT-01 | ... | Positivo | Partição | Alta | Sim | RULE-001 |
```

Depois, detalhe os casos no padrão obrigatório (ao menos os de prioridade Alta, ou todos se o usuário pedir):

```
Título: [CT-01] ...
Objetivo: ...
Pré-condição: ...
Dados necessários: ...
Passos:
  1. ...
Resultado Esperado: ...
```

Encerre com:
- **Cobertura de critérios de aceite:** X de Y cobertos (listar descobertos, se houver).
- **Cenários de regressão** recomendados.
- **Pendências** que impedem escrever algum cenário com precisão.
