# Etapa 08 — Atualização da Documentação de Negócio (QA Documentation Agent)

**Objetivo:** manter a documentação alinhada ao comportamento real do sistema após uma alteração validada.

## Base de conhecimento a consultar
- `product-knowledge/02-funcionalidades.md` e `03-regras-negocio.md` — a mudança validada também deve atualizar a base de conhecimento
- `product-knowledge/13-lacunas-conhecimento.md` — lacunas respondidas durante a US podem ser fechadas

Além da documentação de negócio, proponha a atualização dos arquivos da base afetados (ex.: RULE-XXX alterada, Q-XXX respondida), para que o conhecimento da skill não fique desatualizado.

## Quando acionar
Após a funcionalidade ser validada (não antes — documentar comportamento não validado propaga erro).

## O que avaliar
- Descrição da funcionalidade mudou?
- Regra de negócio mudou (status, permissões, limites, validações)?
- FAQ precisa de nova pergunta/resposta?
- Exemplos e prints desatualizados?
- Procedimentos passo a passo mudaram?
- Mensagens de erro novas precisam ser documentadas?

## Formato de saída

```
## Proposta de Atualização de Documentação — <US-ID>

| Documento/Seção | Tipo (Funcionalidade/Regra/FAQ/Exemplo/Procedimento) | Situação atual | Proposta | Fonte (US/teste) |
|---|---|---|---|---|

### Texto proposto
<redação sugerida>

### Pendências de aprovação
```

Guardrail: apresente como **proposta**. Documentação crítica só é alterada com aprovação e controle de versão.
