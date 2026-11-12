# Registro da revisão da skill `priorizar-automacao` — Arquitetura do Share

## 1. Identificação

| Campo | Registro |
|---|---|
| Data | 28/10/2026 |
| Fuso horário | America/Sao_Paulo — UTC-03:00 |
| Skill original | [`priorizar-automacao.md`](../priorizar-automacao.md) |
| Skill revisada | [`priorizar-automacao.md`](../versao-revisada-2026-10-28/priorizar-automacao.md) |
| Responsável | Codex |
| Status | Revisão aplicada na cópia; original preservado |

## 2. Objetivo

Usar os cenários do mapa como fonte de automação e elevar a confiança antes de promover um spec para regressão.

## 3. Decisões aplicadas

- A origem oficial passou a ser o card `Criar Mapa de Teste` publicado pela `Arquitetura-gerar-mapa-testes`.
- Foram adicionadas verificações de assertions, `skip`, `fixme`, waits artificiais e correspondência com o cenário.
- A promoção exige, quando possível, três execuções limpas para detectar flakiness.
- A automação continua seguindo a estrutura específica do Share; não foi alterado o modelo de criação de automações, conforme solicitado.
- O ciclo passou a ser referenciado por caminho relativo.

## 4. Resultado esperado

Somente automações que comprovem o comportamento e tenham estabilidade mínima entram na regressão, sem modificar o modelo adotado pelo time do Share.

