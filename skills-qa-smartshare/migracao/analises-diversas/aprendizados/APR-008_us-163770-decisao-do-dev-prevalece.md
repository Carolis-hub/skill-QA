---
id: APR-008
data: 2026-11-04
skill: analise-tecnica
escopo: US 163770
status: Ativo
---
**Situação:** a US 163770 diverge do card Análise #165789 em três pontos: CA-10 Exportar (D4, dashboard ECM não tem export), CA-14 valores idênticos em "por tipo" (D1, base única do card faz os valores subirem) e itens não previstos na US (D8 título de tipo sem "vigentes"; D9 barra "Área sem nome").
**Pergunta feita:** REC-163770-02, 03 e 04 (como tratar cada divergência).
**Resposta da usuária:** "manter a decisão do dev" nos três; no REC-04, "mesmo que não esteja previsto na US". REC-01 (ordenação em empate): aprovada.
**Como aplicar:** nesta US prevalece o card do dev nesses pontos, sem perguntar: não gerar cenário de Exportar (CA-10 não aplicável, pergunta à PM aberta); CA-14 não exige igualdade, a base de "por tipo" é a do card (CA-04 é o critério de soma); D8 e D9 são comportamento aceito, não defeito. Exceção consciente à precedência do APR-001, mesma linha do APR-004 e APR-007. Se a PM responder o contrário, reavaliar.
