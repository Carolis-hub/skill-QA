# Registro das execuções (planilha)

Definição única das colunas de `C:\skills-qualidade\registro\registro-execucoes.csv`. Cada skill acrescenta **uma linha** ao terminar, com uma chamada só e sem reler o arquivo. Leia este arquivo apenas se tiver dúvida sobre uma coluna.

## Por que CSV

- Gravar uma linha custa uma chamada curta de ferramenta; reescrever ou ler uma planilha inteira custaria bem mais tokens.
- O Excel abre o arquivo direto (separador `;`, o padrão do Excel em português), com filtro e tabela dinâmica. Para uma versão `.xlsx` formatada, ela é gerada a partir deste CSV quando precisar.
- O relatório semanal usa este mesmo arquivo: toda terça o CSV é enviado ao artefato e a tabela "Registro das execuções" se atualiza, com o filtro por período.

## Colunas, nesta ordem

| Coluna | O que vai | Quem preenche |
|---|---|---|
| `data_hora` | `AAAA-MM-DD HH:mm` do fim da execução | todas |
| `skill` | nome sem barra, ex.: `executar-teste` | todas |
| `us` | número da US (ou da task/Bug) | todas |
| `titulo` | título da US, sem `;` | todas |
| `mensagens` | quantas mensagens a fase teve (contagem aproximada) | todas |
| `tokens_m` | consumo da fase em milhões, **só** se a usuária informar o `/cost`; vazio caso contrário. Nunca estimar. | todas |
| `cenarios` | mapa: cenários gerados; executar-teste: cenários executados; analise-falha: falhas analisadas | gerar-mapa, executar-teste, analise-falha |
| `passou` | cenários que passaram | executar-teste |
| `falhou` | cenários que falharam | executar-teste |
| `bugs` | Bugs criados | gerar-defeito |
| `bug_ids` | IDs separados por `|`, ex.: `165066|165067` | gerar-defeito |
| `orcamento` | `ok` ou `excedido` (regra `ORCAMENTO_TOKENS.md`) | validar-ambiente, executar-teste, analise-falha, gerar-defeito |
| `observacao` | uma frase curta: resultado, banco, modo, veredito | todas |

## Regras

- Campo que a skill não conhece fica **vazio**. O texto não leva `;` nem quebra de linha.
- Nunca reescreva, reordene nem apague linhas anteriores; só acrescente.
- Rodada com falha ou parada cedo também registra, com a observação do motivo.
- O consumo real de uma fase é conferido depois a partir das transcrições; a coluna `tokens_m` serve para quando a usuária já o tiver à mão.
