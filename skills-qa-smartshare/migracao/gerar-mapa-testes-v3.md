---
description: Gera mapa de testes em .txt (Pré-Requisitos / Ação / Resultado esperado) a partir do ID de um work item do Azure DevOps, validando descrição, critérios de aceite e análise dev antes de montar os casos de teste.
---

Gerar o mapa de testes do work item do Azure DevOps a partir de **$ARGUMENTS**.

Formato esperado: `[ID da US ou link do work item]`

Exemplos:
- `146157`
- `https://dev.azure.com/selbettidev/_workitems/edit/146157`

Use quando a pessoa enviar o ID ou o link de uma US/work item do Azure DevOps (org `selbettidev`) e pedir o mapa de teste.

**Cada US é independente:** não reaproveitar dados, regras ou respostas de mapas de outras US.

---

## 1. Coletar as informações (Claude in Chrome)

1. Abrir a US: `https://dev.azure.com/selbettidev/_workitems/edit/<ID>` (funciona sem saber o projeto; redireciona para SHARE-4, Squad Fênix etc.).
2. Ler com `get_page_text`. Se vier vazio ("No text content found"), chamar de novo: a página ainda estava carregando.
3. Capturar: título, Description, Acceptance Criteria, imagens relevantes da descrição (screenshot) e comentários.
4. Localizar a task filha **Análise** em Related Work:
   - Se aparecer "Show more (x of y)", o clique por ref costuma não expandir. Fazer screenshot e clicar pela coordenada do link "Show more".
   - Usar `find` para achar o link "Análise" (não "Análise Review") e confirmar o ID com `read_page` no ref (o `find` às vezes inventa IDs).
5. Abrir a Análise e ler: Alteração Técnica, Alteração/Criação de Classe/Tela, Pontos de impacto, Caso de Teste e Discussion (comentários da Análise Review costumam ter pontos importantes).
6. Se a análise estiver vazia, conferir rapidamente Desenvolvimento / Ajustes CR. Se também estiverem vazios, registrar isso.
7. **NÃO** usar `javascript_tool` para chamar a API REST do Azure DevOps (a pessoa recusou). Usar só navegação e leitura da página.
8. Fechar as abas abertas por mim ao terminar.

Se não houver acesso ao navegador: pedir que a pessoa cole título, Description, Acceptance Criteria e Análise Dev. **Não iniciar o mapa sem os critérios de aceite.**

---

## 2. Validar (vai para o CHAT, não para o arquivo)

### Descrição
- Objetivo e escopo claros?
- Termos ambíguos ("ajustar", "melhorar", "etc.", "outras ações permitidas", "a confirmar")?
- O título bate com a descrição?

### Critérios de aceite
- Cada CA é testável e tem resultado observável?
- Há CA que depende de "a confirmar com dev/design" ou sem valor concreto (tempo, limite, texto de mensagem)?
- Faltam cenários negativos, de borda, de permissão?
- Há CAs contraditórios entre si ou com a descrição?

### Análise dev: incoerências e pontos em aberto
- A análise cobre todos os CAs?
- A análise faz algo diferente do que a US pede (divergência de regra)?
- A análise altera algo não previsto (impacto oculto: outro sistema, Clássico, mensagens, nomes de arquivo, comportamento legado)?
- Itens pedidos na US (ex.: "investigação técnica sugerida") que a análise não respondeu.
- Itens incompletos (só título, "ponto em aberto", seção vazia).
- Erros técnicos visíveis (ex.: sintaxe de script SQL diferente entre SQL Server e Oracle).
- Riscos de segurança (permissão, ownership em endpoints, exposição de dados).
- Telas, APIs, regras e integrações impactadas estão identificadas?
- Campos vazios (Alteração de Classe/Tela, Caso de Teste), Análise Review ainda "New", tasks de CR/Mapa ausentes.

---

## 3. Montar os casos de teste

- Todo CA gera pelo menos 1 caso positivo.
- Incluir negativos, borda, regressão e segurança quando fizer sentido. Checklist:
  - Limites exatos (ex.: 255/256, 500/501, 4GB, página de 25).
  - Fluxos alternativos citados na análise (API, outros meios de publicação, outros botões que reaproveitam a mesma lógica).
  - Regressão do comportamento antigo e de outros sistemas afetados (ex.: Share Clássico quando o agent/lib é compartilhado).
  - API via Postman quando a análise descreve endpoints (status HTTP, mensagens de erro, ownership: tentar acessar/excluir recurso de outro usuário).
  - SQL Server e Oracle quando há alteração de banco, select ou insert.
  - Volume/performance quando a US fala em volume alto.
  - Idiomas/formatos quando a análise define formatos por idioma.
  - Concorrência (dois usuários na mesma ação) e troca de contexto (trocar cliente, busca, ordenação, página).
- Quando o comportamento não estiver definido: escrever o passo e, no resultado, "Registrar o comportamento observado". Levar a dúvida ao dev. **Nunca inventar regra.**
- Copiar exatamente nomes de telas, botões, campos e mensagens da US/análise.
- Conferir no fim: todo CA tem caso? Algum caso depende de regra inventada?

---

## 4. Formato do arquivo (somente casos de teste)

Salvar em `/mnt/user-data/outputs/mapa_teste_<ID>.txt` (texto puro, UTF-8, sem markdown). **O arquivo NÃO tem a seção de validação.**

```
MAPA DE TESTE - TASK <ID>
Título: <título da US>
Data: <dd/mm/aaaa>
Análise dev: Task <ID da análise> (<nome do dev>) [- Branch / PR, se houver]

==================================================
CASOS DE TESTE
==================================================
Observação geral para todos os casos:
- <ambiente/versão, massa de dados, usuários de teste, ferramentas (Postman, 7-Zip, DevTools), bancos, apoio dev/infra>

CT01 - <título descritivo do cenário>
Critério relacionado: CA01 [/ Análise dev (...)]
Tipo: Positivo | Negativo | Borda | Regressão

Pré-Requisitos:
- <estado do sistema, usuário/perfil, dados necessários>

Ação:
1. <uma ação por linha, verbo no infinitivo>

Resultado esperado:
- <resultado verificável: mensagem, campo, valor, status, quantidade>
--------------------------------------------------
```

### Exemplo de caso bem escrito

```
CT02 - Bloquear salvamento sem CPF preenchido
Critério relacionado: CA02
Tipo: Negativo

Pré-Requisitos:
- Usuário com perfil "Atendente" logado no sistema.
- Tela "Cadastro de Cliente" acessível.

Ação:
1. Acessar o menu Clientes > Novo Cliente.
2. Preencher o campo "Nome" com "Maria Souza".
3. Deixar o campo "CPF" vazio.
4. Clicar em "Salvar".

Resultado esperado:
- O cadastro não é salvo.
- O campo "CPF" fica destacado em vermelho.
- É exibida a mensagem "CPF é obrigatório".
```

---

## 5. Resposta no chat

1. Uma frase: mapa pronto + quantidade de casos.
2. **Validação:** Descrição / Critérios de aceite / Análise dev, cada um com OK ou com ressalvas e os pontos principais (curtos).
3. **Mensagem para o dev**, pronta para copiar, em bloco de código:
   - Começa com "Oi <primeiro nome>, tudo bem? Estou montando o mapa de testes da US <ID> (<tema>) e tenho algumas dúvidas sobre a análise (task <ID>):"
   - Perguntas numeradas com título curto, contexto em 1 linha e a pergunta objetiva.
   - Termina com "Obrigada!".

---

## 6. Quando a pessoa trouxer as respostas do dev

- Atualizar os CTs afetados com o comportamento confirmado e marcar "(confirmado pelo dev)". Remover "a confirmar" / "registrar" desses pontos.
- Criar os casos novos que a resposta exigir **sem renumerar** os existentes (usar subnúmeros: CT14.1, CT14.2, CT17.1...).
- Ajustar a "Observação geral" se a resposta valer para todos os casos (ex.: testar em SQL Server e Oracle).
- Marcar como "EXECUTAR SÓ SE..." os casos que dependem de resposta ainda pendente.
- Se a pessoa pedir para redigir perguntas ao dev, escrever de forma clara, com contexto e o que se espera como resposta.
- No chat: listar em poucas linhas o que mudou e o que ainda está pendente.

---

## 7. Se pedirem para colocar o mapa na descrição da US

- O campo Description do Azure DevOps é Markdown: clicar em "Edit Description" e acrescentar o mapa ao **FINAL** do conteúdo existente (nunca substituir), convertido para Markdown (`## Mapa de testes`, `### CTxx`, `Pré-Requisitos:`, listas).
- Textos grandes travam a extensão: enviar em partes (ex.: guardar em uma variável da página por blocos) e só depois aplicar no campo e salvar.
- Confirmar que salvou antes de dizer que foi feito.

---

## Regras

- Redação clara e descritiva: quem executar o teste não deve precisar perguntar nada.
- Proibido resultado vago ("funcionar corretamente", "exibir ok"). Descrever exatamente a mensagem, campo, valor ou status esperado.
- Uma ação por passo, verbo no infinitivo (Acessar, Clicar, Informar, Salvar).
- Não inventar regra de negócio: lacunas viram pergunta ao dev e "registrar o comportamento" no CT.
- Manter nomes de telas, campos e mensagens exatamente como estão na task.
- Numerar os critérios como CA01, CA02... na ordem da US, se não estiverem numerados.
- Ressalvas na validação não impedem o mapa: gerar o mapa mesmo assim.
- Escrever em português do Brasil, linguagem simples.
