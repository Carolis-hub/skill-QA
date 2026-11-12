# Consumo por skill no Codex

Inicie cada etapa no começo de uma mensagem com o nome completo da skill, por exemplo `/arquitetura-validar-ambiente 146157` ou `$arquitetura-validar-ambiente 146157`. Use uma skill por turno. As continuações e confirmações contam para a última skill iniciada. Quando você iniciar `/arquitetura-executar-teste 146157`, o próprio turno da troca conta para a nova execução.

Se quiser fechar uma etapa antes da próxima, comece uma mensagem com `/fim-skill`. O turno do marcador já entra em `outros`. Esse marcador é interpretado pelo coletor e pode ser incluído na próxima mensagem normal. Sem ele, a atribuição continua até a próxima skill ou o fim do log.

Na pasta de arquitetura, rode com Python 3:

```powershell
python .\telemetria\consumo_codex.py "<id-da-sessao>" --csv ".\consumo-sessao.csv"
```

Também é possível passar o caminho do arquivo de sessão JSONL. A opção `--csv` é facultativa. Cada exportação recalcula a sessão até o último registro disponível e substitui o arquivo CSV indicado.

O CSV traz uma linha por execução de skill. Use `tipo=skill` para agrupar o consumo por skill e `tipo=sessao` para o total por conversa. Use `outros` e `sem_atribuicao` para conciliar o total. Campos vazios indicam dados indisponíveis. Entrada em cache e raciocínio são detalhamentos, portanto use `total_tokens` para as somas.

O coletor usa o formato observado nos logs locais do Codex, que pode mudar entre versões. Logs antigos podem fornecer somente o total acumulado. Se houver diferença positiva entre o total da sessão e as respostas medidas, ela aparece como `sem_atribuicao`. O relatório contém identificadores, nomes de skills e contagens, sem copiar mensagens do log. A coleta para Claude Code requer um adaptador próprio.
