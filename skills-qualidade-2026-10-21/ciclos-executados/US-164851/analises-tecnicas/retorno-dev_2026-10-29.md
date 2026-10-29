# Retorno do dev — US #164851 (registrado em 2026-10-29)

Origem: texto colado pela usuária, resposta do dev (Vinicius Mesquita Junge) aos 4 itens de `pendencias-skills\US 164851.txt`. **Não está registrado na US nem no card do Azure DevOps**, e as decisões abaixo são do dev, não confirmadas pela PM. O que muda o resultado esperado de teste foi marcado.

| # | Item | Resposta do dev | Efeito no teste |
|---|---|---|---|
| 1 | CA 94/96 permissão | "Permissão de gerenciar índices" = ser administrador, igual a todas as telas de gerenciamento (Share 4 e Clássico); não administrador recebe 403 em qualquer operação de opções, inclusive consulta | **Muda o esperado:** não existe cenário "consegue ver, mas não altera"; testar não administrador em GET, POST, PUT e DELETE, todos 403 |
| 2 | Caso 22 | Sem login ou token inválido → 403; não administrador → 403; token válido com sessão encerrada → 401; código mantido | **Muda o esperado do caso 22** do card (antes: "sem login → 401") |
| 3 | PRs | Oficiais para a Fase 3: 30019, 30020, 30080, 30092 e 30103 (opções); 30113 a 30119 serão abandonados; 164850 terá PR próprio; merge na ordem das US | Revisão e testes de opções partem do PR 30103; não verifiquei o 30103 (li o código do 30119) |
| 4 | "Opção não encontrada." | Mantida; complementa o CA 82 para alteração e remoção de opção | **Novo esperado:** PUT/DELETE de opção inexistente → "Opção não encontrada." |

## Não respondido pelo dev (continua aberto, bloqueante para `/executar-teste`)
- Caso 8: como criar tipo com opção de código 9999 em dev.
- Casos 20 e 24: mecanismo para forçar falha no log ou no UPDATE do valor inicial e para provocar erro técnico.
- Observação da regex de Números (`\d` aceita dígitos Unicode): sem retorno.

## Recomendações aprovadas
O retorno não toca em nenhuma das 8 (REC-01 e REC-05 seguem com as notas da análise técnica).
