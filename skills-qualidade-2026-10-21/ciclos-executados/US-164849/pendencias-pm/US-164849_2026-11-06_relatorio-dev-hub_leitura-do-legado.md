# Relatório ao dev do hub — leitura do legado (SmartShare clássico)

- **Data:** 2026-11-06
- **Origem:** QA da US 164849 (BE, "Gerenciamento de índice | Lançamento e integração"), mapa #164885
- **Destinatário:** dev que está ajustando o hub (`smartshare-hub`)
- **Pedido:** (1) incluir no hub a validação "nunca ler código comentado" e as regras de leitura do legado ligadas a ela; (2) registrar o ocorrido de hoje, que motivou o pedido.

Rótulos de evidência: `lida-no-codigo`, `lacuna`. Nenhum valor sensível consta neste documento.

---

## 1. Resumo

Hoje afirmei, durante o QA, que "o Clássico lista todas as conexões, sem filtro". **Estava errado.** O Clássico filtra pelos perfis do usuário com leitura. Cheguei à afirmação errada por dois motivos que se somaram:

1. Li uma **cópia velha** do Clássico (`WebApplication`), não o host de referência (`SmartShareWeb`).
2. A busca comum (Grep/ripgrep) **não enxerga `SmartShareWeb`**, porque o `.gitignore` do repositório Clássico a exclui.

Há ainda um terceiro risco, que ainda não causou erro mas está no mesmo lugar: `SmartShareWeb/Gerenciamento/TipoIndiceForm.ascx.cs` tem, logo acima da consulta viva, **uma consulta antiga comentada, sem filtro**. Quem ler esse arquivo e tomar a linha comentada como regra chega à mesma conclusão errada.

As correções já estão feitas do lado do QA. **O hub ainda não tem nenhuma delas.** É isso que este relatório pede.

---

## 2. O que aconteceu hoje

### 2.1 Linha do tempo

| Passo | O que houve |
|---|---|
| 1 | No teste #53 (lista de conexões do formulário de índice), o BE devolvia só as conexões ligadas aos perfis do usuário. Procurei a regra no Clássico. |
| 2 | Usei Grep na pasta `SmartShare/`. A busca só devolveu a cópia `WebApplication`, onde a consulta aparecia sem filtro. |
| 3 | Concluí "o Clássico lista todas as conexões" e tratei o filtro do BE como regra nova. Montei a "opção C: igual ao Clássico, sem filtro" para a PM. |
| 4 | A US (CA43) e o dev diziam o contrário. Em vez de duvidar da minha leitura, duvidei da US. Também li mal o CA42 ("perfis do usuário com permissão de leitura"), que equivale a `StLeitura`. |
| 5 | A usuária pediu a origem da regra ("de qual parte do código, desde quando"). Ao responder, abri `SmartShareWeb` por `git` e vi o filtro por perfil. |
| 6 | Reconhecida a falha, corrigi anexo da PM, relatório de execução, log e memória. A mensagem **já enviada** à PM continua com a afirmação errada (correção pendente). |

### 2.2 Causa mecânica

- `SmartShare/.gitignore:171` contém `/SmartShareWeb`. Grep respeita o `.gitignore` e por isso nunca varre essa pasta. `lida-no-codigo`
- `git grep`, `git log` e `git blame` enxergam a pasta (são 4959 arquivos rastreados). `lida-no-codigo`
- A cópia `WebApplication` está desatualizada: a última alteração de `Gerenciamento/TipoIndiceForm.ascx.cs` nela é de **2019-02-13** (commit `e9b11ff0c`). `lida-no-codigo`
- O `CLAUDE.md` do hub já avisa que `WebApplication` é cópia velha, mas **não diz como buscar** em `SmartShareWeb`. Tratei o aviso como ressalva, não como regra.

### 2.3 O que o Clássico faz de fato (`SmartShareWeb`)

`lida-no-codigo`, em `SmartShareWeb/Gerenciamento/TipoIndiceForm.ascx.cs`:

- linha 44: `perfisUsuario = user.LstPerfisUsuario.Where(x => x.StLeitura).ToList();` — só os perfis com leitura;
- linha 863: `PopuladdlConexao()` — monta a consulta de conexões a partir desses perfis;
- linha 881: a consulta **comentada** (`//DbDataReader dbReader = dbHnd.ExecuteReader("SELECT cd_conexao, ds_conexao FROM CONEXAO");`) é a versão antiga, sem filtro. **Não é regra.** A versão viva está nas linhas imediatamente acima (877–879), com `JOIN` em `PERFIL_CONEXAO` e `WHERE p.cd_perfil IN (...)`.

Observação sobre a origem: o histórico do arquivo mostra alterações de 2022-07/08 em "perfil ao criar conexão" e "aba de perfis em gerenciamento de conexão" (commits `b4a93a01c`, `ed1644410`, `9f1ddb080`). Não confirmei qual commit introduziu exatamente o filtro de leitura: **`lacuna`** para quem for citar a data.

### 2.4 Impacto

- Teste #53 concluído de forma errada por algumas horas; veredito de análise de falha revisto de NÃO para SIM.
- Uma "opção C" errada foi levada à PM e a mensagem foi enviada.
- Bug #166262 (outro assunto, `<retcoluna>`) cita números de linha da cópia `WebApplication`; a lógica é a mesma em `SmartShareWeb`, mas as linhas diferem.
- Nenhum dado de ambiente foi alterado por causa do erro.

### 2.5 Correções já feitas (lado QA)

- Anexo da PM, relatório de execução, log e memória corrigidos.
- `DIRETRIZ_FIDELIDADE_LEGADO.md` (fonte única das skills de QA) ganhou a seção "Como ler o legado (SmartShare clássico)", itens 1 a 8.
- As skills `/executar-teste` e `/gerar-mapa-testes-v3` ganharam um ponteiro para essa seção.
- Registrado como ALT-134 e ALT-135 no `REGISTRO_ALTERACOES.md` dos QA.

### 2.6 Ainda aberto

- Corrigir a mensagem já enviada à PM.
- Comentar no Bug #166262 a correção das referências de linha.
- Abrir o Bug do #53 (agora com evidência suficiente).
- **O pedido deste relatório: levar as regras ao hub.**

---

## 3. Item pendente para o hub

### 3.1 Onde

| Arquivo do hub | Situação hoje |
|---|---|
| `.claude/skills/analyse-legacy-smartshare/SKILL.md` (234 linhas, versão 2.0.0) | Já diz que `SmartShareWeb` é o host padrão e que diferenças das cópias devem ser registradas (linhas 214–215). **Não tem** a regra de busca, a de código comentado nem a de contraverificação. |
| `.claude/skills/analyse-legacy-smartshare/references/navigation.md` (13–14) e `peculiarities.md` (35) | Mesma situação: dizem qual é o host, não ensinam a buscar nem a descartar comentário. |
| `CLAUDE.md` da raiz do hub | Não menciona host de referência (0 ocorrências) nem aponta para a regra. |
| `.claude/skills/demanda-smartshare/references/geracoes-do-smartshare.md` (13) | Diz "Host padrão: SmartShareWeb". Vale um ponteiro para a nova seção. |

### 3.2 O que acrescentar (texto sugerido)

Proposta: criar em `analyse-legacy-smartshare` a seção **"Como ler o legado"** com os itens abaixo, e pôr no `CLAUDE.md` da raiz **uma linha de ponteiro** para ela (o `CLAUDE.md` diz onde a informação está, não o conteúdo).

1. **Cache primeiro.** Antes de reler o código, verificar se há diagnóstico em `SmartShare/.claude/docs/analises-realizadas/`.
2. **Host de referência.** `SmartShare/SmartShareWeb`. `WebApplication` e `BPMWebSite` são cópias velhas. Citar só caminhos de `SmartShareWeb`; o que só existir na cópia vai como "só na cópia".
3. **Como buscar.** Usar `git -C <hub>/SmartShare grep -n "<termo>" -- '*.cs' '*.aspx' '*.ascx'`. Grep/ripgrep **não** varre `SmartShareWeb` (`.gitignore:171`). `git grep`, `git log` e `git blame` são só leitura e não violam a regra de "não alterar o clássico".
4. **Ausência exige duas buscas.** Afirmar "o clássico não faz X" só depois de duas buscas independentes, nas duas cópias. Uma busca vazia é `lacuna`.
5. **Duvidar da leitura antes da US.** Se a US ou o dev contradiz o que li, a primeira hipótese é que li errado, não que a US erra.
6. **Origem e idade da regra.** `git log -S"<trecho>"` e `git blame`. Sem isso, não afirmar "desde quando".
7. **Contraverificação antes de enviar a terceiros.** Afirmação sobre o clássico que vai a PM, Bug ou comentário no ADO passa por verificação cruzada de um subagente (Sonnet, conforme regra 8 do `CLAUDE.md` do hub). Sem ela, vira `lacuna`.
8. **Nunca usar código comentado como regra.** Só código executável conta. Descartar `//`, `'`, `/* */`, `<%-- --%>`, `<!-- -->` e `#if false`. Comentário serve só de contexto. Antes de citar `arquivo:linha`, abrir cerca de 5 linhas ao redor para detectar bloco comentado. Ocorrência só em comentário = `lacuna`, **não** vira critério de aceite.

Exemplo real para a skill (item 8): `SmartShareWeb/Gerenciamento/TipoIndiceForm.ascx.cs:881` (consulta antiga comentada, sem filtro) acima da consulta viva, filtrada por perfil.

### 3.3 Fonte única já pronta

O texto completo dos itens 1–8 está em `C:\skills-qualidade\skills-qa-smartshare\skills-qa-smartshare\templates\DIRETRIZ_FIDELIDADE_LEGADO.md`, seção "Como ler o legado (SmartShare clássico)". Pode ser copiado como base. Se o hub adotar o texto, vale decidir qual lado passa a ser a fonte única, para não manter duas versões divergentes.

### 3.4 Como verificar que ficou bom

- Abrir uma sessão nova na raiz do hub e pedir "como o clássico monta a lista de conexões do formulário de índice". A resposta deve citar `SmartShareWeb/Gerenciamento/TipoIndiceForm.ascx.cs` (linhas 44 e 863 em diante), mencionar o filtro por perfil com leitura e **não** citar a linha 881 como regra.
- Pedir a mesma coisa só com Grep disponível e confirmar que o agente recorre a `git grep`.

### 3.5 Limites deste pedido

- Não editei nada no hub (regra de somente leitura para o QA).
- Não verifiquei ainda, em `SmartShareWeb`, as citações `ZoomCentroAreaSimples` (seleção do pai) e `AssociaPerfilUsuario.aspx.cs:185`. Quem for citá-las deve conferir antes.
- O item 7 depende de o dev concordar em tornar a contraverificação obrigatória; é a regra mais custosa das oito.
