---
id: APR-017
data: 2026-11-06
skill: executar-teste
escopo: US 164849
status: Ativo
---
**Situação:** o #53 (lista de conexões do formulário de índice) mostrou o BE incluindo as conexões dos perfis pais do usuário (linhas de navegação, `st_navegacao = 1`). O CA42 não dizia se os pais contam.
**Pergunta feita:** à PM, com as opções A (pais contam), B (só o próprio perfil) e C (igual ao Clássico, descartada por erro de leitura).
**Resposta da PM:** opção B, só o próprio perfil.
**Como aplicar:** nesta US, a lista de conexões do índice só vale com as conexões dos perfis do usuário com leitura; conexão de perfil pai ou irmão não aparece. O #53 é defeito do BE (Bug #166286). Ao retestar, incluir o cenário de alteração de índice com conexão ligada só a um perfil pai (CA43), ainda não testado.
