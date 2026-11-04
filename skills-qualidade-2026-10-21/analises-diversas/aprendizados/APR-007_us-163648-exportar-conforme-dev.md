---
id: APR-007
data: 2026-11-04
skill: analise-tecnica
escopo: US 163648
status: Ativo
---
**Situação:** a US 163648 exige o Exportar (CA-07, Escopo), mas o card Análise #165848 diz que o Dashboard ECM não tem a ação Exportar ("fica fora do escopo"), com pergunta em aberto ao PM; o hub (branch `ecm-fase2`) confirma que não há Exportar.
**Pergunta feita:** como tratar o CA-07 (REC-163648-01 propunha marcá-lo como Bloqueado até o PM definir) e se havia retorno do dev.
**Resposta da usuária:** "deve ser mantido o comportamento da analise do dev, nesse caso."
**Como aplicar:** nesta US, considerar que o ECM não tem Exportar e que o CA-07 não se aplica. Não gerar cenário de Exportar no mapa; registrar o CA-07 como "não aplicável por decisão do dev, conforme usuária" e manter a pergunta ao PM como aberta. Se o PM responder o contrário, reavaliar. Mesma linha do APR-004 (US 163659); exceção consciente à precedência do APR-001, por decisão explícita da usuária. A REC-163648-01 ficou `Ajustada` com este texto.
