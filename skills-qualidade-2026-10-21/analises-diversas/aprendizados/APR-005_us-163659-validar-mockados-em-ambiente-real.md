---
id: APR-005
data: 2026-11-04
skill: analise-tecnica
escopo: US 163659
status: Ativo
---
**Situação:** o card Análise #165849 marca cenários como validados só com API simulada (mock).
**Pergunta feita:** (pedido da usuária) o que fazer com os cenários validados apenas com mock.
**Resposta da usuária:** "adicione todos os itens testados mockados para serem validados em ambiente real na execução dos testes."
**Como aplicar:** no mapa e na execução da US 163659, tratar como cenários a executar em ambiente real: CT-01, CT-02, CT-03, CT-04, CT-05, CT-06, CT-07, CT-08, CT-11, CT-13, CT-14 e CT-15. CT-09 e CT-12 constam como "Validado" sem ambiente informado: incluir também. Não aceitar a validação com mock do dev como evidência. CT-10 (Exportar) segue fora, conforme APR-004.
