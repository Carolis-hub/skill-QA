# Registro da revisão da skill `gerar-defeito` — Arquitetura do Share

## 1. Identificação

| Campo | Registro |
|---|---|
| Data | 28/10/2026 |
| Fuso horário | America/Sao_Paulo — UTC-03:00 |
| Skill original | [`gerar-defeito.md`](../gerar-defeito.md) |
| Skill revisada | [`gerar-defeito.md`](../versao-revisada-2026-10-28/gerar-defeito.md) |
| Responsável | Codex |
| Status | Revisão aplicada na cópia; original preservado |

## 2. Objetivo

Evitar Bugs duplicados, validar o contrato de campos do projeto e tornar explícito que o upload da evidência faz parte da aprovação.

## 3. Decisões aplicadas

- Foi adicionada busca de duplicidades por história, cenário, componente, título e comportamento observado.
- A aprovação do usuário passa a declarar também vínculo e upload das evidências listadas.
- O campo de passos e a escala de severidade devem ser confirmados no projeto antes da criação.
- O PAT corporativo foi mantido como fallback autorizado para anexos, sem aparecer em logs ou relatórios.
- Falha no upload passa a ter resultado próprio (`evidência não anexada` ou `INCONCLUSIVO`) e pode impedir que o Bug seja considerado pronto para triagem quando a evidência for essencial.
- Organização e caminhos do log deixaram de ser fixos.
- A separação entre criação do Bug e confirmação do vínculo à história foi preservada.

## 4. Resultado esperado

Bugs mais completos, sem duplicidade silenciosa, com severidade compatível com o projeto e evidência realmente disponível para o time.

