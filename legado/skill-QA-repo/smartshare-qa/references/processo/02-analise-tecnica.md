# Etapa 02 — Análise Técnica (QA Technical Analyst)

**Objetivo:** a partir da alteração no código, identificar o que é direta e indiretamente impactado. A pergunta central não é "o que mudou?", e sim: **"se isto mudar, quem depende disso e que partes do produto podem mudar de comportamento?"**

## Base de conhecimento a consultar
- `product-knowledge/09-dependencias-impactos.md` — ficha DEP-XXX do componente alterado (dependentes diretos/indiretos, regressão sugerida)
- `product-knowledge/01-arquitetura-produto.md` — camada e módulo do componente
- `product-knowledge/05-apis.md` — endpoints que usam o componente
- `product-knowledge/06-banco-dados.md` — tabelas, flags, soft delete, triggers afetados
- `product-knowledge/08-integracoes.md` — integrações disparadas
- `complementar/historico-defeitos.md` — defeitos anteriores no mesmo componente

Se o componente não tiver ficha DEP-XXX, diga isso e marque o mapa de impacto como `[INFERIDO]`.

## Entradas
Análise técnica do Dev, PR/diff, classes e métodos alterados, descrição técnica, dependências, funcionalidades/integrações/dados potencialmente impactados.

## Roteiro
1. **O que foi alterado?** Classes, métodos, componentes de front-end, endpoints, queries, migrations, configurações.
2. **Onde foi alterado?** Camada (front-end, API, serviço, banco, job/worker, integração).
3. **Quem depende disso?**
   - Dependências diretas: quem chama o método/endpoint alterado.
   - Dependências indiretas: quem consome o resultado (relatórios, exportações, notificações, integrações, outras telas).
4. **O que pode ser impactado?** Funcionalidades, integrações, dados existentes, permissões, performance.
5. **Qual o risco?** Classifique cada área.

## Sinais de alerta (aumentam o risco)
- Alteração em componente/serviço compartilhado por vários módulos.
- Alteração em regra de permissão ou autenticação.
- Migration ou alteração de schema/dados existentes.
- Mudança em contrato de API (campos, tipos, obrigatoriedade, códigos de retorno).
- Validação feita só no front-end (verificar se a API também valida).
- Alteração em cálculo, status ou transição de estado.
- Área com histórico de defeitos (consultar `complementar/historico-defeitos.md`).

## Formato de saída

```
## Análise Técnica — <US-ID / PR>

### Alterações identificadas
| Camada | Componente/Arquivo | Tipo de alteração |
|---|---|---|

### Mapa de impacto
| Área | Direto/Indireto | Nível de risco (Alto/Médio/Baixo) | Justificativa |
|---|---|---|---|

### Dependências
- Diretas: ...
- Indiretas: ...

### Áreas de regressão recomendadas
### Pontos que exigem teste via API (além da UI)
### Lacunas → "Informação não encontrada / necessita validação"
```

Se nenhuma análise técnica ou PR for fornecido, diga isso explicitamente e baseie o impacto apenas em hipóteses marcadas como tal, pedindo ao Dev os pontos de impacto.
