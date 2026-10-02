# Etapa 01 — Análise de Negócio (QA Business Analyst)

**Objetivo:** interpretar US, regra de negócio e critérios de aceite **antes** de criar testes, transformando critérios em condições verificáveis e expondo lacunas cedo — quando corrigir é barato.

## Base de conhecimento a consultar
- `product-knowledge/14-indice-rastreabilidade.md` — localizar a funcionalidade citada na US
- `product-knowledge/02-funcionalidades.md` — comportamento atual da funcionalidade
- `product-knowledge/03-regras-negocio.md` — regras vigentes (RULE-XXX) que a US mantém, altera ou contradiz
- `product-knowledge/04-estados-workflows.md` — status existentes quando a US citar status
- `product-knowledge/07-permissoes-seguranca.md` — perfis reais para perguntar "quem não pode?"
- `product-knowledge/12-glossario.md` — traduzir termos da US para nomes do código
- `product-knowledge/13-lacunas-conhecimento.md` — reaproveitar perguntas Q-XXX já abertas

Se a US alterar uma regra existente, sinalize explicitamente: *"Esta US altera RULE-XXX (comportamento atual: ...)"*.

## Entradas
User Story, regra de negócio, critérios de aceite, documentação relacionada, histórico de alterações (quando houver).

## O que fazer
1. **Objetivo da alteração** — em uma frase: o que muda, para quem e por quê.
2. **Comportamentos esperados** — trate cada critério de aceite como contrato: *"Quando [condição], o sistema deve [comportamento]"*.
3. **Regras explícitas** — o que está escrito.
4. **Regras implícitas** — o que é consequência lógica ou padrão do produto (marque como *Hipótese* e peça validação).
5. **Condições e exceções** — status, perfis, valores, campos obrigatórios, estados de erro.
6. **Dependências** — outras USs, módulos, integrações, dados.
7. **Informações ausentes** — o que um QA precisaria para testar e não está disponível.
8. **Ambiguidades** — termos vagos ("rápido", "adequado", "quando necessário"), critérios contraditórios, comportamento não definido para valores fora do esperado.
9. **Riscos iniciais** — classifique por probabilidade × impacto.

## Perguntas que sempre valem a pena fazer
- O que acontece com os dados/registros **já existentes** após a mudança?
- Quem **não** deve conseguir fazer isso?
- O que acontece em cada status **diferente** do citado?
- Há limite de tamanho, quantidade, formato?
- A mudança aparece em relatórios, exportações, notificações, API ou auditoria?
- Existe comportamento anterior que os usuários esperam que continue igual?

## Formato de saída

```
## Análise de Negócio — <US-ID> <título>

**Objetivo:** ...

### Critérios de aceite como condições verificáveis
| # | Condição (Quando...) | Comportamento esperado (Então...) | Fonte |
|---|---|---|---|

### Regras explícitas
### Regras implícitas (Hipóteses — validar)
### Condições e exceções
### Dependências
### Ambiguidades
### Informações ausentes → "Informação não encontrada / necessita validação"
### Riscos iniciais
| Risco | Probabilidade | Impacto | Mitigação via teste |
|---|---|---|---|

### Perguntas para PM/Dev
```

**Lembrete:** nunca preencha uma lacuna com uma regra inventada. Uma pergunta bem feita ao PM vale mais que dez cenários baseados em suposição.
