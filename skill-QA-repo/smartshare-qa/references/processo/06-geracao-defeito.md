# Etapa 06 — Geração de Defeito (Azure DevOps)

**Objetivo:** estruturar defeitos claros, reproduzíveis e baseados em evidência, prontos para o Azure.

## Base de conhecimento a consultar
- `complementar/historico-defeitos.md` — verificar duplicidade antes de sugerir abertura
- `product-knowledge/03-regras-negocio.md` — citar RULE-XXX como fonte do Resultado Esperado
- `complementar/fluxos-criticos.md` — defeito em fluxo crítico eleva a severidade sugerida

## Formato mínimo (padrão do time)

```
Título: BUG – <comportamento inesperado>

Contexto:
<funcionalidade, ambiente, versão, perfil e passos resumidos>

Resultado Atual:
<o que aconteceu>

Resultado Esperado:
<o que deveria acontecer + fonte da regra>

Impacto:
<quem é afetado, frequência, existe contorno?>
```

## Formato completo (card no Azure)

```
Título: BUG – <comportamento inesperado>

Contexto:
Pré-condições:
Passos para reprodução:
  1.
  2.
Resultado Esperado:
Resultado Atual:
Impacto:
Severidade sugerida: Crítica | Alta | Média | Baixa
Ambiente: <HML/DEV> — <URL>
Versão/Build:
Navegador/SO (se UI):
US relacionada:
Evidências: <prints, vídeo, request/response, log, correlation id>
Informações técnicas relevantes: <status HTTP, mensagem de erro, endpoint>
Reprodutibilidade: Sempre | Intermitente (x de y) | Uma vez
```

## Boas práticas de título
- Específico: **BUG – API retorna 500 ao salvar documento no status Y com campo X preenchido**
- Evite: "Erro ao salvar", "Não funciona", "Problema na tela".

## Severidade sugerida
| Severidade | Critério |
|---|---|
| **Crítica** | Bloqueia fluxo crítico, perda/corrupção de dados, falha de segurança/permissão, sem contorno |
| **Alta** | Funcionalidade principal com erro, contorno difícil, afeta muitos usuários |
| **Média** | Funcionalidade secundária com erro, existe contorno razoável |
| **Baixa** | Cosmético, texto, alinhamento, impacto mínimo |

A severidade é **sempre sugestão**; a decisão é humana.

## Guardrails
- Não invente passos, versões, IDs, logs ou mensagens. Campo sem informação → "Não informado".
- Um defeito por problema. Se houver vários, separe.
- Antes de sugerir abertura, verifique se não é duplicado de defeito conhecido (`complementar/historico-defeitos.md`) quando essa informação existir.
- Abrir o card no Azure é uma ação que exige confirmação do QA.
