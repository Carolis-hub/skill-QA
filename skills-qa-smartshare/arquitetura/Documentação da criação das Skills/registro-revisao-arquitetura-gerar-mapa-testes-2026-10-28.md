# Registro da revisão da skill `Arquitetura-gerar-mapa-testes` — Arquitetura do Share

## 1. Identificação

| Campo | Registro |
|---|---|
| Data | 28/10/2026 |
| Fuso horário | America/Sao_Paulo — UTC-03:00 |
| Skill original | [`Arquitetura-gerar-mapa-testes.md`](../Arquitetura-gerar-mapa-testes.md) |
| Skill revisada | [`Arquitetura-gerar-mapa-testes.md`](../versao-revisada-2026-10-28/Arquitetura-gerar-mapa-testes.md) |
| Responsável | Codex |
| Status | Revisão aplicada na cópia; original preservado |

## 2. Objetivo

Manter o nome atual da skill e melhorar a qualidade do mapa sem transformar dimensões arquiteturais em preenchimento artificial.

## 3. Decisões aplicadas

- O nome oficial permanece `Arquitetura-gerar-mapa-testes`.
- A análise técnica ausente ou vazia agora bloqueia a geração do mapa.
- Fontes técnicas secundárias — PR, diff, arquivo:símbolo, dependências e histórico — podem justificar cenários quando sua relação com a história estiver explicada.
- As dimensões podem ser `APLICÁVEL`, `N/A — motivo`, `BLOQUEADA` ou `FORA DO ESCOPO`; não é necessário criar cenários artificiais.
- Dados de banco passaram a exigir escopo, autorização e limpeza/rollback quando houver escrita.
- A tabela recebeu as colunas `Camada` e `Componente`, permitindo reteste seletivo baseado em impacto técnico.
- Após publicar, o card deve ser relido para confirmar quantidade de cenários, categorias, tabela e ausência de truncamento.
- `$WORK_DIR` passou a ser relativo ao ciclo e não deve conter segredos.
- O PAT corporativo para anexos foi mantido como exceção empresarial, sem alterar a regra do mapa de não usar PAT para publicação do mapa.

## 4. Resultado esperado

Mapas mais focados, rastreáveis e utilizáveis pelo executor, com vínculo técnico suficiente para selecionar retestes adjacentes.

