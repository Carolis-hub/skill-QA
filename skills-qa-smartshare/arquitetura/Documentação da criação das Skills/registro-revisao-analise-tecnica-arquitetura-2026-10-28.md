# Registro da revisão da skill `analise-tecnica` — Arquitetura do Share

## 1. Identificação

| Campo | Registro |
|---|---|
| Data | 28/10/2026 |
| Fuso horário | America/Sao_Paulo — UTC-03:00 |
| Skill original | [`analise-tecnica.md`](../analise-tecnica.md) |
| Skill revisada | [`analise-tecnica.md`](../versao-revisada-2026-10-28/analise-tecnica.md) |
| Responsável | Codex |
| Status | Revisão aplicada na cópia; original preservado |

## 2. Objetivo

Preservar o bloqueio obrigatório do card `Análise`, ampliar a avaliação de mudanças fora do escopo e validar a correspondência entre o código analisado e o artefato implantado.

## 3. Decisões aplicadas

- O bloqueio por ausência ou vazio do card `Análise` foi mantido como requisito da esteira.
- Mudanças fora do escopo continuam fora da cobertura da US, mas agora geram risco potencial, necessidade de revisão e impacto no gate da release.
- Foi adicionada a matriz de versão analisada versus versão implantada: build, commit, branch, método de verificação e resultado.
- A referência ao mapa foi padronizada para `/Arquitetura-gerar-mapa-testes`.
- O ciclo passou a ser referenciado por caminho relativo.
- A skill orienta reaproveitamento do ciclo para economia de tokens.

## 4. Resultado esperado

Evitar execução sobre build divergente e impedir que mudanças laterais relevantes desapareçam do relatório de QA.

