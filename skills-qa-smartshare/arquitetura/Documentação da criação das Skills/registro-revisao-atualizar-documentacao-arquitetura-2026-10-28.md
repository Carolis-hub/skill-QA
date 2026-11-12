# Registro da revisão da skill `atualizar-documentacao` — Arquitetura do Share

## 1. Identificação

| Campo | Registro |
|---|---|
| Data | 28/10/2026 |
| Fuso horário | America/Sao_Paulo — UTC-03:00 |
| Skill original | [`atualizar-documentacao.md`](../atualizar-documentacao.md) |
| Skill revisada | [`atualizar-documentacao.md`](../versao-revisada-2026-10-28/atualizar-documentacao.md) |
| Responsável | Codex |
| Status | Revisão aplicada na cópia; original preservado |

## 2. Objetivo

Preservar a aprovação página por página e reduzir o risco de sobrescrever alterações de outras pessoas ou publicar conteúdo sensível.

## 3. Decisões aplicadas

- A skill lê o ciclo primeiro para reduzir consultas e tokens.
- Foi adicionada inspeção de tokens, senhas, connection strings, dados pessoais e endpoints sensíveis.
- Antes da publicação, a página é relida; se mudou depois da aprovação, uma nova aprovação é obrigatória.
- A releitura após publicar foi mantida.
- A política de rollback não foi alterada nesta etapa, conforme solicitação.
- Caminhos de log e ciclo foram tornados relativos.

## 4. Resultado esperado

Publicações aprovadas permanecem completas, não sobrescrevem alterações recentes e não expõem dados que não deveriam estar na Wiki.

