# Aprendizados das skills de QA

Toda dúvida, pendência ou pedido de retorno que uma skill fez à usuária vira um **aprendizado** gravado aqui. Antes de perguntar de novo, a skill consulta esta pasta. Objetivo: reduzir a intervenção da usuária.

## Regra (vale para todas as skills)

1. **Antes de perguntar**: ler `INDICE.md`. Se houver aprendizado aplicável à mesma situação, aplicar sem perguntar e registrar no relatório/resposta `Aplicado APR-NNN`.
2. **Ao perguntar**: depois da resposta, gravar o aprendizado (arquivo `APR-NNN_<slug>.md` + linha no `INDICE.md`) **antes de seguir** a execução.
3. **Resposta vaga ou sem resposta**: não gravar como regra. Se a usuária disser "depois", registrar com status `Pendente`.
4. **Nunca gravar segredo**: senha, token, chave. Registrar só "informado no chat, não gravado".
5. **Escopo**: `Geral` (vale sempre), `Skill` (só aquela skill), `US` (só aquela US/ambiente). Aprendizado de escopo `US` não é reaproveitado em outra US.
6. **Conflito**: se a usuária contradiz um aprendizado, atualizar o arquivo, marcar o antigo `Substituído por APR-NNN` e manter o histórico.
7. **O que o aprendizado não substitui**: confirmação de ação irreversível ou de escrita (criar Bug, publicar no Azure DevOps, apagar arquivo, alterar valor de ambiente), aprovação de recomendação (`REC-...`), e todos os guardrails da skill. Nesses casos a skill ainda pergunta, mas pode citar o aprendizado como contexto.

## Formato de `APR-NNN_<slug>.md`

```
---
id: APR-NNN
data: AAAA-MM-DD
skill: <skill que perguntou>
escopo: Geral | Skill | US <ID>
status: Ativo | Pendente | Substituído por APR-NNN
---
**Situação:** quando a dúvida aparece (gatilho reconhecível).
**Pergunta feita:** texto objetivo.
**Resposta da usuária:** texto fiel, sem segredo.
**Como aplicar:** o que a skill faz da próxima vez, sem perguntar.
```

## Formato de `INDICE.md`

Tabela: `ID | Data | Skill | Escopo | Situação (gatilho) | Status | Arquivo`. Uma linha por aprendizado, a mais recente no fim.
