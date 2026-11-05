---
id: APR-012
data: 2026-11-05
skill: gerar-mapa-testes-v3
escopo: Geral
status: Ativo
---
**Situação:** montagem do mapa de testes de uma US com critérios de aceite (CA), em especial quando o card do dev diz que o CA ficou fora da entrega ou não foi executado (US 163958: CA-10 Exportar, CA-08 foco de teclado).
**Pergunta feita:** (instrução da usuária, ao fechar as RECs da US 163958).
**Resposta da usuária:** "deve existir cenário de teste para todos os CAs."
**Como aplicar:** o mapa traz ao menos um cenário por CA, sem exceção, e inclui uma matriz CA → cenário para conferir a cobertura. CA que o dev deixou fora da entrega (decisão do dev, APR-010) mantém o cenário, marcado como "fora da entrega conforme o dev", com o resultado esperado da US, para o time decidir a execução. Não omitir CA por ser inviável ou não executado pelo dev; casos inviáveis na prática (APR-006) continuam fora das pendências, mas o CA segue com cenário.
