# Etapa 07 — Homologação de Release (QA Release Validator)

**Objetivo:** avaliar se uma release está pronta, comparando **o que foi desenvolvido × o que deveria funcionar × o que pode ter sido impactado**.

## Base de conhecimento a consultar
- `product-knowledge/09-dependencias-impactos.md` — regressão sugerida por componente alterado
- `product-knowledge/10-riscos-qa.md` — riscos das áreas alteradas
- `product-knowledge/11-testes-existentes.md` — suítes Playwright disponíveis para selecionar
- `complementar/fluxos-criticos.md` — sempre entram na regressão
- `complementar/historico-defeitos.md` — áreas instáveis

## Entradas
Release, lista de alterações, USs, PRs, mapas de teste, histórico de defeitos, regressão automatizada, ambiente de homologação.

## Processo
Release → Identificar alterações → Relacionar USs → Identificar impactos → Selecionar testes (liberação + regressão) → Executar → Analisar falhas → Gerar relatório → Recomendação

## Seleção da regressão (Playwright e manual)
Pondere para cada área: código alterado, dependências, funcionalidades relacionadas, histórico de defeitos, criticidade, frequência de uso, impacto no negócio, alterações em dados e em integrações.

| Área | Motivo da seleção | Tipo (Automatizado/Manual) | Prioridade |
|---|---|---|---|

Fluxos críticos (`complementar/fluxos-criticos.md`) entram sempre.

## Critérios de decisão
- **Aprovada:** todos os cenários críticos e de alta prioridade passaram; nenhum defeito crítico/bloqueante aberto.
- **Aprovada com ressalvas:** falhas apenas de baixa/média severidade com contorno, riscos conhecidos e aceitos pelo responsável.
- **Reprovada:** falha em cenário crítico, defeito crítico/bloqueante aberto, ou cenários críticos não executados/sem evidência.

Cenário crítico não executado **não** conta como aprovado.

## Formato do relatório

```
## Relatório de Homologação — Release <versão> — <data>

**Status sugerido:** Aprovada | Aprovada com ressalvas | Reprovada

### Resumo
Testes planejados: X | Executados: X | Aprovados: X | Falharam: X | Bloqueados: X

### Escopo
| US | Título | Status |
|---|---|---|

### Defeitos
| ID | Título | Severidade | Status |
|---|---|---|---|

### Riscos remanescentes
- ...

### Recomendação
<frase objetiva, ex.: "Release não recomendada para produção devido à falha em cenário crítico de emissão de documento.">
```

A aprovação final para produção é decisão humana; o relatório é uma recomendação fundamentada.
