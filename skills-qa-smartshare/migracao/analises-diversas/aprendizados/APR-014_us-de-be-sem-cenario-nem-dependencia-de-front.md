---
id: APR-014
data: 2026-11-05
skill: gerar-mapa-testes-v3
escopo: Geral
status: Ativo
---
**Situação:** montagem do mapa de testes de uma US de BE (US 164848, cadastro do tipo de índice) cujos critérios e cenários tocavam tela, protótipo e o Clássico como interface.
**Pergunta feita:** (instrução da usuária, ao ver que o mapa tinha cenários e pré-requisitos com dependência de front).
**Resposta da usuária:** "us de be não devem possuir nenhum cenário ou dependência com front, ajuste skills e altere o mapa."
**Como aplicar:** em US de BE o mapa verifica só API (requisição/resposta) e dados (banco/log). Nenhum cenário, pré-requisito ou dependência pode exigir tela, UI, protótipo ou o Clássico/Portal como interface; consumidores são verificados pelo contrato de dados. CA de FE da US (tela, tooltip, aviso de saída, campo/seta) não gera cenário e vira nota "Fora do escopo do mapa (FE)" em "Fonte técnica". **Exceção ao APR-012** para esses CA de FE em US de BE: a regra "todo CA tem cenário" vale para os CA de BE. Regra gravada na skill (ALT-123, Step 3.10 do gerar-mapa-testes-v3).
