---
id: APR-011
data: 2026-11-04
skill: gerar-mapa-testes-v3
escopo: Geral
status: Ativo
---
**Situação:** o mapa precisa de um número para o cenário de performance quando a US não traz o tempo (aplicação do APR-002).
**Pergunta feita:** qual o tempo máximo aceitável para o cenário de performance em Dia com período longo (US 163663, cenário 42).
**Resposta da usuária:** "tempo que cai em timeout".
**Como aplicar:** o "máximo aceitável" do APR-002 é o tempo imediatamente anterior ao timeout: o cenário passa se a tela carrega sem estourar o timeout configurado (por exemplo, o timeout de dashboard citado no card do dev) e não passa se der timeout. Não inventar um número em segundos; se o executor precisar do valor, lê-lo na configuração do ambiente. Não perguntar de novo.
