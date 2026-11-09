# US 164849: as conexões do cadastro de índice incluem as dos perfis pais?

> **DECISÃO DA PM (2026-11-06):** opção **B (só o próprio perfil)**. Os perfis pais deixam de contar. O #53 passa a ser defeito do BE: Bug #166286, filho da US 164849. Pendente de teste: alterar índice cuja conexão está ligada só a um perfil pai (risco de "Conexão não permitida para o usuário", CA43), não testado.

> **CORREÇÃO (2026-11-06, mesmo dia):** as seções "No Clássico" e a opção C abaixo foram escritas com base na cópia `SmartShare/WebApplication` do Clássico, que **não é o host de referência** e está desatualizada (o `TipoIndiceForm` dela não muda desde 2019-02-13). No host de referência, `SmartShare/SmartShareWeb`, a lista **é filtrada por perfil**: `Gerenciamento/TipoIndiceForm.ascx.cs`, `validaSessao` (linhas 34-53: só os perfis do usuário com `StLeitura`) e `PopuladdlConexao` (linhas 863-899: `CONEXAO` com `JOIN PERFIL_CONEXAO ... WHERE p.cd_perfil IN (perfis com leitura)`). A regra existe desde jul/2022 (commit `b4a93a01c`, 2022-07-18; SQL com o `JOIN` em `ed1644410`, 2022-08-02, junto com a tela de vínculo perfil × conexão, `9f1ddb080`). Logo: **a opção C ("todas as conexões, sem filtro") não existe no Clássico**, e o filtro por perfil **não é novo do BE**. O que difere do Clássico no BE de hoje é que ele também considera as linhas de **navegação** dos perfis pais (no Clássico só entram os perfis com leitura).

**Para validação da PM** · Mapa #164885, cenário #53 · Ambiente HMG (Oracle) · 2026-11-06

No HMG, a lista de conexões do cadastro de índice traz também as conexões ligadas aos **perfis pais** do usuário (RHteste e Geral), e não só as ligadas aos perfis dele. O CA42 diz apenas "perfis do usuário" e não esclarece se os pais contam. Precisamos de uma decisão da PM: o comportamento atual está certo, ou é defeito?

## 1. Decisão pedida

**Pergunta:** na lista de conexões do cadastro de índice, um administrador deve ver só as conexões ligadas aos perfis em que ele é leitor, ou também as ligadas aos perfis pais?

| Opção | Regra | O que acontece |
|---|---|---|
| A. Os pais contam (herança) | Conexão ligada a um perfil vale para ele e para todos os perfis abaixo | O BE já faz isso. Só o texto do CA42 e o mapa de testes mudam |
| B. Só os perfis do próprio usuário | Linhas de navegação dos pais (`st_navegacao = 1`) não contam | É defeito do BE: ajustar o filtro. Pode bloquear a edição de índices que usam conexão ligada só a um perfil pai |
| ~~C. Igual ao Clássico~~ (retirada: ver a correção no topo) | ~~Todas as conexões, sem filtro~~ | O Clássico de referência filtra por perfil com leitura; esta opção não existe |

Duas perguntas de apoio:
1. **Gravar o índice (CA43).** Hoje, ao salvar um índice, o sistema só aceita uma conexão que apareça na lista daquele administrador. Se ele tentar gravar com outra, o sistema recusa com "Conexão não permitida para o usuário". A pergunta: essa recusa deve seguir **sempre a mesma regra da lista**, qualquer que seja a opção escolhida acima? Exemplo: se a lista passar a mostrar só os perfis do próprio usuário (opção B), um índice que já usa uma conexão ligada a um perfil pai pode deixar de poder ser alterado por esse administrador.
2. **Ligação revogada (sem permissão de leitura).** Cada ligação entre um perfil e uma conexão tem um indicador de leitura (`st_leitura`): 1 = o perfil pode usar a conexão, 0 = ligação revogada. **Hoje o BE esconde a conexão quando a ligação está revogada**: o código do net8 exige `st_leitura = 1` na lista, e ao tirar todos os perfis de uma conexão ele só muda o indicador para 0, sem apagar a linha (`PerfilConexaoRepository.cs:57-118`). Testei: a conexão deixou de aparecer para quem a via. No Clássico, essas ligações aparecem na aba de perfis da conexão (Bug #160105), mas nunca foram usadas na tela de índice. A pergunta: uma ligação revogada deve **esconder** a conexão, como o BE faz hoje?

## 2. O que acontece hoje (HMG, Oracle)

O usuário de teste `qa.semconexao.us164849` tem leitura **só** no perfil `QA164849 sem conexao` (12027), que não tem nenhuma conexão ligada. Os pais dele são `RH_TESTE` (11107) → `RHteste` (9388) → `Geral` (1).

| Usuário | Conexões que aparecem no cadastro de índice |
|---|---|
| `qa.semconexao.us164849` (leitura só no perfil sem conexão) | 142, 82, 202, 1, 103 |
| `Claude-adm` (administrador com muitos perfis) | 142, 82, 122, 202, 263, 1, 2, 103 |

Explicação comprovada: as 5 conexões do primeiro usuário são exatamente as ligadas a `RHteste` e a `Geral`.

| Conexão | Perfis da cadeia do usuário a que está ligada | Aparece? |
|---|---|---|
| 142 | RHteste | sim |
| 1 | RHteste | sim |
| 82, 103, 202 | RHteste e Geral | sim |
| 122, 2, 263 | nenhum | não |

**Teste complementar: quem é leitor do perfil pai vê as conexões dos filhos? Sim.** Liguei a conexão de teste 283 **só** ao `RH_TESTE` (11107) e comparei três usuários com leitura em um único perfil cada:

| Usuário | Leitura só em | Vê a 283? |
|---|---|---|
| 9042 | `RH_TESTE` (o próprio perfil) | sim |
| 9022 | perfil 12027 (filho do `RH_TESTE`) | sim: herda dos pais |
| 9043 | `RHteste` (centro, pai do `RH_TESTE`) | sim: herda dos filhos |

A plataforma nova já trata o leitor de um perfil como leitor **indireto** dos perfis abaixo dele (`GET /api/PerfilUsuario/ReadersIndirect`): o 9043 aparece como leitor indireto do `RH_TESTE` (origem 9388) e do 12027 (origem 11107). Ou seja, a visibilidade vale para **a árvore inteira, para cima e para baixo**. A conexão 283 foi desvinculada depois do teste.

Resultado repetido duas vezes, igual. O mapa esperava "só o item vazio" (#53), mas esse esperado foi **derivado** do CA42 pelo gerador do mapa: o card do dev não cita esse caso.

## 3. Como simular

**Pela tela (qualquer pessoa com acesso ao HMG):**
1. Entrar com o `qa.semconexao.us164849` (a credencial está com a QA, no arquivo de configuração de testes; não vai neste documento).
2. Configurações → Gerenciamento de índices → Novo índice.
3. Escolher Tipo de índice "Informado", Tipo de índice no DI "Consulta" e abrir o campo **Conexão**. Anotar as opções.
4. Repetir com o `Claude-adm` e comparar: a diferença é só 122, 2 e 263.
5. Para ver a causa: Configurações → Gerenciamento de conexão → conexão 142 → aba **Perfis**. Só `RHteste` está marcado. Em nenhuma conexão aparece o perfil `QA164849 sem conexao`.

**Pela API (QA):** `GET /smartshare/api/api/TipoIndice/Conexoes` com a sessão do usuário. Hoje devolve `[vazio, 142, 82, 202, 1, 103]`.

**Condições:** o endpoint só responde para usuário do tipo **Administrador**. O publicador recebeu 403 em todas as operações. Para montar outra massa, seguir a regra do Clássico: o usuário recebe leitura na área principal e nos filhos dela, e só navegação nos pais (`Usuario.aspx.cs:2592-2617`).

## 4. Comportamento no Clássico (legado)

Lido no código do hub (cópia `WebApplication`):

- **O cadastro de índice lista todas as conexões**, sem filtro de perfil nem de situação: `SELECT cd_conexao, ds_conexao FROM CONEXAO` (`TipoIndiceForm.ascx.cs:835-849`).
- **Existe um filtro por perfil, mas sem chamador nesta tela:** `ConexaoDAL.ListarPorPerfilUsuario` junta `PERFIL_CONEXAO` pelos perfis informados e traz só conexões com `st_ativo = 1`, sem olhar `st_leitura` (`ConexaoDAL.cs:262-271`).
- **Perfis de um usuário novo:** a área principal e os filhos com leitura; os pais só com navegação, `st_navegacao = 1` (`Usuario.aspx.cs:2592-2617`).
- **O Clássico trata navegação como diferente de pertencimento:** ao criar perfil, copia só `st_navegacao = 0` (`Perfil.aspx.cs:643`) e filtra o mesmo ao listar perfis administráveis (`AssociaPerfilUsuario.aspx.cs:185`).
- **Aba Perfis da conexão** mostra também os vínculos com `st_leitura = 0` (Bug #160105).

Conclusão do legado: **a regra "por perfil" é nova do BE.** O Clássico não filtrava a lista nessa tela. Ressalva: pode divergir do host de referência.

## 5. Impactos

- **Quem é afetado:** só administradores com acesso a Gerenciamento de índices. Como todo perfil descende de `Geral`, todo administrador vê ao menos as conexões ligadas a `Geral`.
- **Em relação ao Clássico:** não há regressão. O BE atual é mais restritivo que o Clássico.
- **Direção da visibilidade:** nos dois sentidos. Quem é leitor de um perfil baixo vê as conexões dos perfis pais. Quem é leitor de um perfil alto (por exemplo `Geral`) vê as conexões ligadas a qualquer perfil abaixo dele. Na prática, um administrador de topo vê todas as conexões da árvore dele.
- **Opção A (pais contam):** uma conexão ligada a `Geral` ou a um centro fica visível a todos os administradores abaixo. A restrição por área só vale de cima para baixo. Com a conexão, o administrador pode salvar índice e usar o Testar SQL para ler o banco externo com a credencial guardada nela.
- **Opção B (só o próprio perfil):** administradores perdem conexões que veem hoje. Índices existentes com conexão ligada só a um perfil pai podem ficar sem poder ser alterados ("Conexão não permitida para o usuário", CA43). Ponto a confirmar, porque a alteração com conexão não permitida não foi testada.
- **Opção C (igual ao Clássico):** sem risco de bloqueio, mas sem controle por perfil, contra o CA42 e o CA43.
- **Impacto no teste:** o #53 ("perfis sem vínculo a nenhuma conexão") só pode ser atendido na opção B. Na opção A o mapa precisa de cenários novos (conexão do perfil pai aparece para o filho; conexão de perfil irmão não aparece).
- **Esforço da correção (opção B):** provavelmente um filtro único (`st_navegacao`), mas o código do BE não foi lido e o net8 usa navegação de propósito em outros pontos (dashboards).

## 6. Fontes e limites

- US #164849: CA42 e CA43. Card de Análise do dev #164863: "perfis do usuário (`PERFIL_USUARIO`) → `PERFIL_CONEXAO` com `st_leitura = 1` → `CONEXAO` com `st_ativo = 1`" (não diz se as linhas de navegação entram).
- Mapa #164885, cenário #53 (origem CA42). Execução e análise de falha de 2026-11-06.
- **Limites:** a US não tem PR vinculado e o código do BE novo não foi lido; a UI não expõe `st_leitura` do vínculo; o Clássico lido é a cópia `WebApplication` do hub.
