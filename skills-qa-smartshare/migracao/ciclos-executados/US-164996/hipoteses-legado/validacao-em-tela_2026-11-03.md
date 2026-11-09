---
us: 164996
origem: validação do SmartShare clássico em tela (somente leitura, sem gravar nada), em 2026-11-03
telas: gerenciamento/TipoIndice.aspx (122 tipos de índice) e gerenciamento/Indice.aspx?tipoindice=104 (selecao) e 106 (selecao data)
sessao: já logada pela usuária
---

# Validação em tela do Clássico — hipóteses do mapa #165653 (cenários 38 a 44)

Nada foi gravado: só listagens, abertura de abas e formulários, e cancelamento. Os testes que gravam (HIP-01, 05 e 06) aguardam autorização.

| ID | Hipótese | Resultado em tela | Estado |
|---|---|---|---|
| HIP-164996-01 | Remover a opção não limpa o valor inicial do índice | Não verificado: exige excluir uma opção que seja valor inicial (grava no banco) | Pendente de autorização |
| HIP-164996-02 | Ativa só persiste no botão Salvar | **Confirmada em tela.** Em Detalhar, "Ativo" é um campo do formulário (checkbox) com Salvar, Cancelar e Excluir. Desmarquei Ativo e cancelei: a listagem continuou com todas as opções ativas. Não há gravação ao marcar | Confirmada |
| HIP-164996-03 | Lista só mostra o total, sem "N ativas" | **Confirmada em tela.** A listagem mostra só "Total de registros: 10" e a coluna Ativo com ícone por linha; nenhum contador de ativas | Confirmada |
| HIP-164996-04 | Mensagem de data sem "(a partir de 31/12/1979)" | **Parcial.** No tipo Data o campo é um seletor de data (Telerik) com a data de hoje. Ao digitar 15/06/1975 e sair do campo, ele fica com borda laranja (inválido) e **nenhum texto de mensagem aparece**. A mensagem ao clicar em Salvar não foi testada (risco de gravar) | Parcial |
| HIP-164996-05 | Números sem teto 9999 e sem barra de negativo | Não verificado: exige tentar gravar 10000 e -1 em um tipo Números | Pendente de autorização |
| HIP-164996-06 | Não bloqueia valor duplicado | Não verificado: exige gravar o mesmo valor duas vezes | Pendente de autorização |
| HIP-164996-07 | Campo limita a 70 caracteres | **Confirmada em tela.** O campo Valor do formulário tem `maxlength=70`; a opção mais longa existente tem exatamente 70 caracteres | Confirmada |

## Observações do Clássico (úteis para o mapa)
- O código da opção é sequencial **por índice** (1 a 10 no tipo "selecao"); na tela nova, o mock numera de forma global.
- A listagem do tipo Data mostra valores que a regra atual recusaria: "11/08/2207" e "26/07/2022 14:16:38" (com hora). Apoia os cenários #15 e #16 (opções antigas fora da regra são exibidas normalmente).
- A tela do Clássico não tem confirmação visual "N opções · N ativas" nem botão de editar na linha com aviso de sucesso: edição e inclusão passam por abas (Listar, Detalhar, Incluir) e botões Salvar e Cancelar.
- O servidor do Clássico ficou cerca de 20 minutos sem responder no início; voltou depois de uma ação da usuária.

## Atualização: testes com gravação autorizados pela usuária (03/11/2026)
Dados de teste criados no HMG do Clássico (prefixo "QA US164996"): tipo de índice 1060 (Seleção, Letras e Números) e 1061 (Seleção, Números), e opções nesses tipos. Nenhum dado existente foi alterado nem excluído.

| ID | Hipótese | Resultado em tela | Estado |
|---|---|---|---|
| HIP-164996-01 | Remover a opção não limpa o valor inicial | **Confirmada.** No tipo 1060 defini a opção código 2 ("QA B") como Valor inicial e salvei. Excluí a opção (confirmação "Confirma a exclusão deste registro?", sem aviso de que era o valor inicial; "Exclusão realizada com sucesso"). Criei outra opção ("QA C"), que recebeu o código 2 (código = maior código + 1). Ao reabrir o tipo, o Valor inicial aparecia como "QA C": o Clássico manteve a referência ao código excluído | Confirmada |
| HIP-164996-05 | Números sem teto 9999 e sem negativo | **Confirmada.** No tipo 1061 (Números): "10000" foi gravado ("Inclusão realizada com sucesso"), "-1" foi recusado com "Este campo recebe valores numéricos do tipo inteiro"; vazio dá "Este campo é requerido". Ou seja, só inteiro não negativo, sem teto | Confirmada |
| HIP-164996-06 | Não bloqueia valor duplicado | **Confirmada.** No tipo 1060 gravei "QA A" duas vezes e as duas entraram (códigos 1 e 2, "Total de registros: 2") sem mensagem | Confirmada |

Observações adicionais do Clássico:
- O Clássico mostra aviso de sucesso para incluir ("Inclusão realizada com sucesso"), alterar ("Alteração realizada com sucesso") e excluir ("Exclusão realizada com sucesso"), em faixa verde no topo.
- Excluir pede confirmação com texto fixo, sem citar o registro nem o uso como valor inicial.
- Mudar o Valor inicial do tipo para "em branco" (vazio) no formulário Detalhar gerou a página "Ixxi... algo deu errado" (erro inesperado, protocolo 817402). A exclusão do tipo 1060 também gerou essa página (protocolo 817401).

## Limpeza
- Excluídos por mim: opções "10000" (tipo 1061), "QA A", "QA B" e "QA C" (tipo 1060) e o tipo 1061.
- **Pendente:** o tipo de índice **1060 "QA US164996 selecao"** continua cadastrado (Total de registros: 123; eram 122). A exclusão dele falhou com a página de erro do Clássico. Precisa ser excluído por você ou por quem tiver acesso ao banco.

## Ponto a validar na nova tela: valor inicial que aponta para opção excluída (anotado em 03/11/2026)
**No Clássico (relatado pela usuária, mesmo erro que eu vi):** depois de excluir a opção que era o Valor inicial do tipo (HIP-01), abrir o tipo em Detalhar quebra a página. O erro é `'ddlIndiceSelecao' tem um SelectedValue que é inválido porque ele não existe na lista de itens` (`ArgumentOutOfRangeException`, em `Gerenciamento/TipoIndiceForm.ascx.cs`, linha 280, `set_strValorInicial`, chamado por `TipoIndice.aspx.cs`, linha 463, `PreencherDetalhes`). Efeito: o tipo não abre para editar nem para excluir (a exclusão também passa por Detalhar). Foi o que aconteceu com o tipo de teste 1060.

Vale como **evidência de que a regra nova do CA 10 corrige um defeito real do Clássico** (o BE limpa o Valor inicial ao remover a opção) e como cenário a validar na tela nova.

A validar na nova tela (a incluir no mapa se a usuária aprovar):
1. Definir uma opção como Valor inicial do índice, remover essa opção e abrir o formulário do índice: a página deve abrir normalmente, com o Valor inicial vazio, sem erro (cobre também o #11 do mapa; falta checar a abertura depois de recarregar a página).
2. Com o formulário já aberto numa aba, remover a opção pela modal e voltar ao formulário: o campo deve esvaziar (CA 10) sem erro.
3. Dado legado: índice cujo Valor inicial aponta para uma opção que já não existe (herança do Clássico): o formulário deve abrir sem erro (Valor inicial vazio ou aviso), e não quebrar como no Clássico. Depende do dado vir do BE; no mock não há como criar.

Estado do dado de teste: o tipo **1060 "QA US164996 selecao"** ficou no HMG do Clássico e não abre por causa desse erro. Contorno possível (não executado): cadastrar duas opções no tipo, de modo que existam os códigos 1 e 2 (o Valor inicial aponta para o 2) e então o Detalhar abre; ou excluir pelo banco, quem tiver autorização.

