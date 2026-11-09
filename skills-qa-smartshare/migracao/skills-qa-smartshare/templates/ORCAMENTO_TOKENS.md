# Orçamento de tokens por fase

Fonte única da regra "Orçamento de tokens da fase" das skills `/validar-ambiente`, `/executar-teste`, `/analise-falha` e `/gerar-defeito`. Leia este arquivo só quando o limite for atingido.

## Por que existe

Na medição de 09/11/2026 (4 US executadas, 934,9 M de tokens), cerca de 95% do total foi leitura de cache: a cada resposta o contexto inteiro da sessão é relido. O custo de uma fase cresce com o número de mensagens e com o tamanho do contexto. As fases mais caras foram `gerar-defeito` (456 M) e `analise-falha` (173 M), embora sejam as de menor trabalho, porque a sessão seguiu aberta com todo o histórico da execução.

## Limite

- **50 M de tokens** (leitura de cache incluída) **ou 100 mensagens** na fase, o que vier primeiro. A usuária pode trocar o valor a qualquer momento.
- **Fase** = a skill em andamento. Mudar de skill zera a contagem.
- A skill **não enxerga o próprio consumo**. Conte as mensagens da fase e, quando a usuária informar o consumo da sessão (`/cost` ou o contador do Claude Code), use o número dela no lugar da contagem.

## O que fazer ao atingir o limite

1. Termine o passo em andamento. **Nunca pare no meio de uma escrita no Azure DevOps, de um anexo ou de uma ação irreversível.**
2. **Avise uma vez**, em duas linhas: a fase passou do orçamento (mensagens ou tokens) e recomenda-se abrir uma sessão nova, porque cada resposta passa a reler todo o histórico.
3. Entregue o **bastão** em um bloco para copiar, com o mínimo para a sessão nova continuar:
   - skill e ID da US (e do mapa, se houver);
   - o que já foi feito e o que falta, em tópicos curtos;
   - caminhos dos arquivos de evidência e dos relatórios gravados;
   - decisões já tomadas pela usuária (para não perguntar de novo);
   - o comando de abertura, por exemplo `/task <ID_US> - <skill> <ID_US>`.
4. A usuária decide: abrir a sessão nova ou continuar nesta. Seguindo nesta, não avise de novo até o dobro do limite (100 M ou 200 mensagens).
5. No registro do log de ações (Observações), acrescente `orçamento excedido: <N> mensagens` quando houve aviso.

## O que o bastão não leva

Prints, saídas de ferramentas e o raciocínio da sessão anterior. A sessão nova lê só o que está nos arquivos e no bastão, que é o ponto da regra.
