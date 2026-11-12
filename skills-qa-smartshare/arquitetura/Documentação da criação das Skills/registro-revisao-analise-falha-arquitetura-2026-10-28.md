# Registro da revisão da skill `analise-falha` — Arquitetura do Share

## 1. Identificação

| Campo | Registro |
|---|---|
| Data | 28/10/2026 |
| Fuso horário | America/Sao_Paulo — UTC-03:00 |
| Skill original | [`analise-falha.md`](../analise-falha.md) |
| Skill revisada | [`analise-falha.md`](../versao-revisada-2026-10-28/analise-falha.md) |
| Responsável | Codex |
| Status | Revisão aplicada na cópia; original preservado |

## 2. Objetivo

Alinhar a investigação ao modelo oficial de mapas em card filho e separar falha funcional, sintoma técnico, ambiente e inconclusividade.

## 3. Decisões aplicadas

- O cenário do mapa e o relatório de execução são as fontes preferenciais; Test Case formal ficou apenas como legado.
- O relatório deve capturar US, `MAPA_ID` e número do cenário quando a origem for o mapa.
- A classificação deixou de ser binária: inclui sintoma, camada provável e causa provável.
- O veredito passou a aceitar `SIM`, `NÃO`, `INCONCLUSIVO` e `BLOQUEIO AMBIENTAL`.
- O histórico do ciclo é priorizado para reutilização e economia de tokens.
- O caminho de registro foi tornado relativo e o comando do mapa foi padronizado.

## 4. Resultado esperado

Reduzir Bugs abertos por evidência incompleta e fornecer diagnóstico mais útil para Devs de UI, API, Worker, Scheduler, banco e integração.

