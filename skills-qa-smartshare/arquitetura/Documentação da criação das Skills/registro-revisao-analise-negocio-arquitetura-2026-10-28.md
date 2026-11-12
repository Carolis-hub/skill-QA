# Registro da revisão da skill `analise-negocio` — Arquitetura do Share

## 1. Identificação

| Campo | Registro |
|---|---|
| Data | 28/10/2026 |
| Fuso horário | America/Sao_Paulo — UTC-03:00 |
| Skill original | [`analise-negocio.md`](../analise-negocio.md) |
| Skill revisada | [`analise-negocio.md`](../versao-revisada-2026-10-28/analise-negocio.md) |
| Responsável | Codex |
| Status | Revisão aplicada na cópia; original preservado |

## 2. Objetivo

Adicionar um gate explícito de prontidão para negócio e permitir retomada econômica pelo ciclo persistente, sem alterar a regra de não inventar requisitos.

## 3. Decisões aplicadas

- Criadas decisões para prontidão de análise técnica, mapa e execução: `APTA`, `APTA COM RESSALVAS` ou `BLOQUEADA`.
- A skill deve ler primeiro o ciclo existente e reutilizar relatórios sem repetir processamento desnecessário.
- A referência ao mapa foi corrigida para `/Arquitetura-gerar-mapa-testes`.
- O caminho absoluto do procedimento de registro foi substituído por `./ciclos-execucao/COMO-REGISTRAR.md`.
- Comentários do Azure DevOps continuam sendo tratados conforme a regra original, sem alteração de autoridade.

## 4. Resultado esperado

Lacunas de regra são identificadas antes da geração e execução do mapa, reduzindo retrabalho e consumo de tokens.

