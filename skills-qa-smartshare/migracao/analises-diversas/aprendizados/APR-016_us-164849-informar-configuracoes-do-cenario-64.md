---
id: APR-016
data: 2026-11-06
skill: validar-ambiente
escopo: US 164849
status: Ativo
---
**Situação:** o `/validar-ambiente` roda para a US 164849 e o mapa #164885 traz o cenário #64 (regressão do Workflow/BPM com SQL externo), cujo pré-requisito `[PROCESSO] fluxo de Workflow/BPM com consulta SQL em banco externo configurada` a skill não consegue verificar nem montar sozinha. O cenário ficou com o dev (2026-11-06).
**Pergunta feita:** nenhuma. Instrução da usuária, depois de o #64 ser encaminhado ao dev.
**Resposta da usuária:** "64- deve ser informado sobre as configurações para esse cenario quando rodar a skill de validar ambiente".
**Como aplicar:** ao rodar `/validar-ambiente` para a US 164849, listar no relatório, em "O que preparar no ambiente", as configurações necessárias ao #64, sem esperar a pergunta. A lista de referência está em `C:\skills-qualidade\ciclos-executados\US-164849\validacoes-ambiente\US-164849_2026-11-06_cenario-64-configuracoes.md`: serviços no ar, conexão externa, modelo de processo com passo de banco e/ou consulta do Comitê, usuário e perfis de workflow, massa e ações de alto risco. O requisito fica `NAO VERIFICAVEL` ou `NAO ATENDIDO` (nunca `ATENDIDO` sem evidência). A skill não monta o processo sozinha: criar configuração segue o APR-015 (validar a regra legada antes) e escrita em banco externo pede confirmação própria. Vale só para esta US; para ampliar a outros cenários `[PROCESSO]` sem como montar, a usuária decide.
