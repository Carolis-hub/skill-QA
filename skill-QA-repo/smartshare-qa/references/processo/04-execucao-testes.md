# Etapa 04 — Execução dos Testes (QA Test Executor)

**Objetivo:** executar o mapa de testes (manual assistido ou via LLM/automação quando disponível), registrando evidências e comparando esperado × obtido.

## Base de conhecimento a consultar
- `complementar/ambientes-perfis-teste.md` — ambiente, perfis e massa de dados
- `product-knowledge/05-apis.md` — preparar pré-condições via API quando possível
- `product-knowledge/06-banco-dados.md` — conferir persistência esperada (somente leitura)

## Entradas
Mapa de testes, ambiente, perfis permitidos, dados de teste, URL/API, configuração do ambiente.

## Ciclo por cenário
1. Selecionar o cenário (ordem: prioridade Alta primeiro).
2. Preparar pré-condições e dados.
3. Executar os passos.
4. Capturar resultado e evidência (print, vídeo, request/response, log).
5. Comparar esperado × obtido.
6. Classificar e seguir para o próximo.

## Classificação
| Status | Quando usar |
|---|---|
| **Passou** | Resultado comprovado por evidência e igual ao esperado |
| **Falhou** | Resultado diferente do esperado, com evidência → ir para etapa 05 |
| **Bloqueado** | Impossível executar (ambiente, dado, credencial, dependência) |
| **Não executado** | Não houve tempo/escopo — registrar motivo |
| **Inconclusivo** | Executou, mas não foi possível comprovar o resultado |

Um cenário sem evidência **nunca** é "Passou".

## Human-in-the-loop — pare e peça intervenção quando houver
- Falta de credencial ou perfil de teste
- Regra de negócio ambígua
- Dados de teste inexistentes
- Ambiente indisponível ou instável
- Necessidade de aprovação manual
- Operação irreversível (exclusão definitiva, envio real de e-mail/assinatura, integração com terceiros)
- Ação de alto risco ou em ambiente que possa conter dados reais

Nunca execute testes em produção nem manipule dados produtivos sem autorização explícita.

## Formato de saída

```
## Execução — <US-ID> | Ambiente: <HML/DEV> | Versão: <x> | Data: <dd/mm/aaaa>

| ID | Cenário | Status | Evidência | Observação |
|---|---|---|---|---|

**Resumo:** Planejados X | Executados X | Passou X | Falhou X | Bloqueado X | Inconclusivo X
**Falhas para análise:** ...
**Pendências de intervenção humana:** ...
```

## Roteiro de teste exploratório (quando solicitado)
```
Charter: Explorar <área> com <recursos/técnica> para descobrir <tipo de risco>
Duração: <timebox>
Perfil/Ambiente: ...
Heurísticas: CRUD, limites, interrupção (voltar/atualizar/sessão expirada), concorrência, dados estranhos, permissões
Anotações / Bugs / Perguntas / Ideias de novos testes
```
