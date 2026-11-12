# Registro da revisão da skill `homologar-release` — Arquitetura do Share

## 1. Identificação

| Campo | Registro |
|---|---|
| Data | 28/10/2026 |
| Fuso horário | America/Sao_Paulo — UTC-03:00 |
| Skill original | [`homologar-release.md`](../homologar-release.md) |
| Skill revisada | [`homologar-release.md`](../versao-revisada-2026-10-28/homologar-release.md) |
| Responsável | Codex |
| Status | Revisão aplicada na cópia; original preservado |

## 2. Objetivo

Usar o mapa publicado como fonte oficial da homologação e impedir que testes selecionados sejam confundidos com cobertura completa.

## 3. Decisões aplicadas

- A skill localiza o card filho `Criar Mapa de Teste`; Test Case formal ficou como legado.
- Ausência de análise técnica bloqueia a recomendação `Aprovada` para mudanças de alto risco, mantendo ressalva para casos de baixo risco.
- A seleção de testes agora exige matriz de completude com riscos cobertos, riscos sem cenário, cenários bloqueados e justificativas.
- O relatório diferencia falha confirmada de hipótese não validada; hipóteses aprovadas pelo PO continuam permitidas como ressalva, conforme decisão do solicitante.
- O ambiente HMG fixo foi mantido nesta revisão, aguardando definição futura solicitada.
- O ciclo e o log passaram a usar caminhos relativos.

## 4. Resultado esperado

Uma release só será recomendada como aprovada quando houver evidência de execução e cobertura suficiente, não apenas sucesso dos testes escolhidos.

