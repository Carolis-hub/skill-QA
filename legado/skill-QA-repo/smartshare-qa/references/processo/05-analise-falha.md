# Etapa 05 — Análise de Falha (QA Failure Analyst)

**Objetivo:** quando um teste falha, não basta dizer "falhou". Determine o que aconteceu, a provável origem e se há evidência suficiente para abrir defeito.

## Base de conhecimento a consultar
- `product-knowledge/05-apis.md` — códigos de erro esperados e validações do endpoint
- `product-knowledge/08-integracoes.md` — comportamento quando a integração falha/está indisponível
- `product-knowledge/03-regras-negocio.md` — confirmar se o "esperado" é regra `[CONFIRMADO]` ou apenas `[INFERIDO]`
- `complementar/historico-defeitos.md` — falha já conhecida? possível duplicidade?

Se o "esperado" se apoiar apenas em regra `[INFERIDO]`, classifique como **Dúvida de regra**, não como defeito.

## Perguntas obrigatórias
1. O que era esperado? (cite a fonte: US, regra, critério, documentação)
2. O que aconteceu? (fatos + evidência)
3. Qual componente pode estar relacionado? (front, API, serviço, banco, integração, configuração)
4. O problema parece **funcional** (regra implementada errada) ou **técnico** (erro 500, timeout, exceção)?
5. O comportamento já existia antes? (reproduz em versão anterior/produção?)
6. Tem relação com a alteração atual?
7. Há evidência suficiente para abrir defeito?

## Descartar falsos positivos antes de abrir bug
- Dado de teste incorreto ou pré-condição não atendida
- Ambiente instável / deploy incompleto / cache
- Expectativa baseada em regra não confirmada (então é dúvida de negócio, não bug)
- Script de automação desatualizado (seletor mudou) — é manutenção de teste, não defeito do produto

## Técnicas úteis de isolamento
- Reproduzir na UI **e** direto na API (a camada que falha indica a origem).
- Variar um fator por vez (perfil, status, dado, navegador).
- Checar console do navegador e aba Network (status HTTP, payload, resposta).
- Comparar com versão/ambiente anterior.

## Formato de saída

```
## Análise de Falha — <CT-ID>

**Esperado:** ... (fonte: ...)
**Obtido:** ...
**Classificação:** Funcional | Técnico | Ambiente | Dado de teste | Teste desatualizado | Dúvida de regra
**Componente provável:** ... (Hipótese / Confirmado)
**Pré-existente?** Sim / Não / Não verificado
**Relacionado à alteração atual?** Sim / Não / Provável
**Evidências:** ...
**Recomendação:** Abrir defeito | Validar regra com PM | Corrigir dado/ambiente e reexecutar | Ajustar automação
```

Se a evidência for insuficiente, diga: *"Não tenho evidência suficiente para abrir o defeito"* e liste o que falta coletar.
