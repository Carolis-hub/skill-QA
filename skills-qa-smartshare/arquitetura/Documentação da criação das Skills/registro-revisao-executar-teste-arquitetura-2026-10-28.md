# Registro da revisão da skill `executar-teste` — Arquitetura do Share

## 1. Identificação

| Campo | Registro |
|---|---|
| Data | 28/10/2026 |
| Fuso horário | America/Sao_Paulo — UTC-03:00 |
| Skill original | [`executar-teste.md`](../executar-teste.md) |
| Skill revisada | [`executar-teste.md`](../versao-revisada-2026-10-28/executar-teste.md) |
| Responsável | Codex |
| Status | Revisão aplicada na cópia; original preservado |

## 2. Objetivo

Melhorar a execução de testes arquiteturais, mantendo o uso do front e do navegador, mas permitindo gates por cenário, rastreio técnico, autorização controlada de banco e entrega formal do relatório.

## 3. Decisões aplicadas

- O uso do Playwright e do front foi mantido, conforme solicitado.
- Pré-requisitos passaram a ser separados em globais e específicos por cenário.
- `DELETE` direto no banco deixou de ser proibido de forma absoluta: exige autorização explícita do usuário executor, ambiente não produtivo, filtro seguro, quantidade esperada e plano de limpeza/rollback.
- `INSERT` e `UPDATE` também passaram a exigir plano de limpeza e verificação pós-execução.
- As tentativas de desbloqueio foram limitadas a duas tentativas seguras e reversíveis.
- O double-check deve confirmar que conseguiu ler cada evidência; caso contrário, retorna `INCONCLUSIVO`.
- O parser do mapa passou a consumir `Camada` e `Componente`, priorizando esses campos no Modo B.
- Os resultados foram ampliados para `PASSOU`, `PASSOU COM RESSALVA`, `FALHOU`, `BLOQUEADO`, `INCONCLUSIVO`, `NÃO APLICÁVEL` e `HIPÓTESE NÃO VALIDADA`.
- Ao final, a skill grava o relatório completo em `.md`, apresenta-o ao usuário e, somente após aprovação, procura o card filho `Teste` para anexar o relatório.
- O anexo usa MCP quando disponível e PAT corporativo como fallback autorizado; o resultado é verificado e registrado.
- Os caminhos de ambiente, ciclo e log foram tornados relativos.

## 4. Resultado esperado

Executar o máximo de cenários independentes com segurança, produzir um relatório auditável e evitar anexos ou escritas externas sem aprovação específica.

