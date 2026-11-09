# CHANGELOG — Skills QA SmartShare

Versões das skills em `skills/` e dos arquivos de apoio em `templates/`. O detalhe linha a linha de cada mudança está no [`REGISTRO_ALTERACOES.md`](REGISTRO_ALTERACOES.md) (ALT-001 em diante, por rodada).

Como versionar daqui para frente: a versão fica no início de cada skill, em dois lugares que devem andar juntos: `version:` no cabeçalho (front matter) e a linha `**Versão da skill: X.Y** (data)` logo no começo do texto, que aparece quando a skill roda. Mudou comportamento ou relatório de uma skill → registrar a ALT no `REGISTRO_ALTERACOES.md`, descrever aqui sob uma nova versão (`1.1`, `1.2`, ...; `2.0` para quebra de fluxo) e atualizar os dois lugares nas skills alteradas. Não se usa tag git.

## 1.3 — 2026-11-09

Menos tokens nas fases de execução (a leitura de cache foi ~95% do consumo medido em 09/11). Afeta `validar-ambiente`, `executar-teste`, `analise-falha` e `gerar-defeito`, que passam à versão 1.3.
- **Orçamento de tokens da fase:** cada uma das 4 skills tem o limite de 50 M de tokens ou 100 mensagens por fase; ao atingir, a skill termina o passo em andamento, avisa uma vez e entrega um bastão para abrir sessão nova. Regras e formato em `templates/ORCAMENTO_TOKENS.md` (ALT-142).
- **Defeitos em lote no `gerar-defeito`:** todos os itens com veredito SIM da execução viram uma lista, com uma única aprovação, criação em sequência, um único vínculo à história e um único script de anexos para todos os Bugs; a falha de um Bug não interrompe os demais; o log segue com uma linha por Bug (ALT-143).

Regra de versão por skill: a versão exibida em cada skill é a do último release em que ela mudou; as skills que não mudaram ficam na versão anterior.

## 1.2 — 2026-11-09

Só `gerar-mapa-testes-v3` (as outras 9 skills seguem na 1.1): removida a seção "O que muda em relação ao v2", de ~1,5 mil tokens, que era histórico. As regras que ela listava continuam nos Steps próprios (2, 3, 3.5, 3.9, 3.10, 4.0, 4.2b, 4.4, 5, 5b e 6.5). Não muda comportamento (ALT-141).

## 1.1 — 2026-11-09

Mudança de caminho, sem mudança de comportamento. O aninhamento duplo `skills-qa-smartshare\skills-qa-smartshare` foi removido: as skills, os `templates` e os documentos de gestão agora ficam direto em `C:\skills-qualidade\skills-qa-smartshare\`. Nas 10 skills, o caminho da diretriz de fidelidade ao legado e o `$TEMPLATES_DIR` do `gerar-mapa-testes-v3` passaram de `...\skills-qa-smartshare\skills-qa-smartshare\templates` para `...\skills-qa-smartshare\templates` (ALT-140). **No ambiente local, a pasta tem de ser movida junto**; do contrário as skills não acham `DIRETRIZ_FIDELIDADE_LEGADO.md`.

## 1.0 — 2026-11-09

Primeira versão numerada. Consolida o estado das 10 skills depois das rodadas 1 a 23 do registro (ALT-001 a ALT-137).

Skills: `analise-negocio` · `analise-tecnica` · `gerar-mapa-testes-v3` · `validar-ambiente` · `executar-teste` · `analise-falha` · `gerar-defeito` · `homologar-release` · `atualizar-documentacao` · `priorizar-automacao`.
Apoio: `templates/DIRETRIZ_FIDELIDADE_LEGADO.md`, `templates/ambiente-teste.template.md`, `templates/mapa-teste-viewer.template.html`.

### O que a 1.0 inclui

- **Base (rodadas 1 a 7):** neutralização das referências ao produto anterior e adaptação ao SmartShare; diretório único de registro das execuções (`C:\skills-qualidade\ciclos-executados`); consulta ao código via hub, somente leitura; HTML interativo local do mapa de testes.
- **Ambiente (rodadas 8 a 10, 14):** `validar-ambiente` valida e configura o ambiente de teste (usuários, processo, parâmetros, dados); backup e restauração de valores alterados na execução; recusa de execução em ambiente com dados simulados (mock).
- **Análises e pendências (rodadas 11, 12, 16, 17, 23):** pendências e recomendações da `analise-tecnica` em arquivo único (`pendencia -> recomendacao`), recomendação só depois das duas análises e do hub, nunca aprovada sem resposta explícita da usuária; marcação da US no início do ciclo (`Committed` e tag `agentqa`); `analise-negocio` sem arquivos, só no chat.
- **Mapa e protótipo (rodadas 13, 18, 19, 20):** paridade visual com o protótipo Figma (zero tolerância); regra de US de BE (sem dependência de front); classificação técnica FE/BE/API e tipos de teste por área.
- **Execução e falha (rodadas 15, 19, 20, 22):** `analise-falha` obrigatória antes de qualquer Bug; execução completa em cada banco (SQL Server e Oracle) com matriz por banco e um chat por banco; aprendizados estruturados (dúvidas viram `APR-NNN`); tabela "Bugs criados" (item e ID do Bug) no relatório.
- **Legado (rodadas 20, 21):** diretriz única de fidelidade à versão legada, com a seção "Como ler o legado" (`git grep`, nunca código comentado).

### Observações da 1.0
- Os relatórios de execução, análise de falha, homologação e defeito são entregues só no chat (ver `analise-tecnica` e `validar-ambiente` para os que gravam arquivo).
- O arquivo `validacoes-ambiente\US-<ID>_<EXEC>.md` continua sendo gravado, porque o `executar-teste` o lê entre conversas.
