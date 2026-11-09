---
id: APR-006
data: 2026-11-04
skill: analise-tecnica
escopo: Geral
status: Ativo
---
**Situação:** a análise lista como pendência um risco ou cenário que não é testável na prática (ex.: overflow que exige bilhões de registros, US 163659 achado 1).
**Pergunta feita:** (pedido da usuária) o que fazer com casos não testáveis na prática.
**Resposta da usuária:** "casos não testáveis na prática devem ser desconsiderados das pendências."
**Como aplicar:** não listar como pendência (relatório nem arquivo de pendências-skills) o caso inviável de reproduzir em ambiente de teste. Mover para o bloco "Desconsiderados a pedido" do arquivo, se já existir, citando o motivo. Aplica-se a inviabilidade prática (volume, tempo, massa impossível), não a cenário difícil mas possível (ex.: massa direto no banco).
