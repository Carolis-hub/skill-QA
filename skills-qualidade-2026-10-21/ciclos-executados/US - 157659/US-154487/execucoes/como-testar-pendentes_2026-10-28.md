# #154487 — como testar os itens pendentes

Contexto: ambiente HMG (http://172.16.0.182/smartshare/). Fluxos de teste já criados no processo 11611 (versões 2 e 3; tipos de anexo 3 e 4):

| Fluxo | Conteúdo | Para que serve |
|---|---|---|
| 31825 | 1 anexo PDF com permissão | #1, #15 |
| 31826 | 1 anexo PDF sem permissão | #2, #12 |
| 31827 | 3 anexos permitidos (A, B, C) | #3, #17 |
| 31828 | mix: A e B permitidos, C sem permissão | #4, #6, #9, #14, #16, #20 |
| 31829 | 2 anexos sem permissão | #5 |
| 31830 | 1 de 3 permitido | #11 |
| 31831 | finalizado, mix | #7 |
| 31838 | tipo 4: flag desmarcada, papel "Fiscal" em "Download/Imprimir permitido para" | #10 |
| 31839 | só anexo de publicação SmartShare | #18 |

Endpoints observados (rede do navegador): lote em andamento `GET .../bpmApi/api/v1/attachment/downloadAllToPrint/<fluxo>/<n>`; lote em finalizados `GET .../attachment-history/downloadAllToPrintHistory/<fluxo>/<n>`. O erro de lote devolve `400` com `{"message":"Falha ao efetuar geração de documentos para print em lote dos anexos. Id Log Aplicação: <id>"}`.
Arquivos de teste: `C:\skills-qualidade\.playwright-mcp\anexos-teste\QA-US154487-anexo-A/B/C.pdf`.
Regras desta pasta: download de arquivo só com a sua autorização; senhas só você digita; nunca excluir dados existentes.

---

## #14 — Erro na impressão em lote é logado em LOG_APLICACAO
**Precisa de:** leitura do banco (SELECT em LOG_APLICACAO).

**Caminho mais simples (já provocamos o erro):** o 400 do fluxo 31839 gerou `Id Log Aplicação: 3075730`.
1. No banco do HMG: `SELECT * FROM LOG_APLICACAO WHERE <coluna do id> = 3075730` (confirme o nome da coluna de id na tabela).
2. Esperado: 1 linha com a mensagem "Não há nenhum arquivo PDF do Tipo Eletrônico para imprimir." (exceção `FileNotFoundException` registrada pelo `catch`), data/hora próxima de 2026-10-28 ~08:00.
3. Se a linha não existir: a US falha (o erro foi convertido em 400 mas não foi logado).

**Para repetir e ter um novo id (se o anterior tiver sido limpo):**
1. Abra o fluxo 31839 (só anexo de publicação) em Minhas tarefas ou Acompanhar > Anexos.
2. Clique no botão geral **Imprimir** (rodapé). Aparece o toast "Não é possível realizar a impressão em lote. Tente imprimir individualmente."
3. Na aba Rede do navegador (F12), abra a resposta do `downloadAllToPrint/31839/...` e copie o `Id Log Aplicação`.
4. Faça o SELECT acima com esse id.

Observação: a falha "real" no mix (fluxo 31828) não gera erro; para logar é preciso um erro de verdade no servidor (como no 31839).

---

## #17 — Arquivo de impressão igual ao da versão anterior (todos permitidos)
**Precisa de:** uma instância da versão anterior à US (não existe no HMG) ou o PDF gerado por ela.

1. Peça ao dev/DevOps a URL de um ambiente com a build anterior (ou a branch/build pré-fix) com o mesmo fluxo.
2. Nas duas versões, abra um fluxo com 3 anexos permitidos (no HMG, o 31827) e clique em **Imprimir** geral. Baixe/salve o PDF de cada versão (**você autoriza o download**).
3. Compare:
   - número de páginas (3 e 3);
   - ordem das páginas (A, B, C);
   - texto de cada página (extraia com `pdftotext` ou abra lado a lado).
   Não compare hash do arquivo inteiro: metadados (data de geração) mudam.
4. Esperado: conteúdo e ordem equivalentes. Qualquer página a mais, a menos ou fora de ordem é falha.
Referência já obtida no HMG (versão com a US): `downloadAllToPrint/31827` → 200, PDF de 3 páginas (A, B, C).

---

## #19 — Hipótese: anexo não-PDF sem permissão
**Precisa de:** um anexo DOCX ou imagem num tipo com "Permite download/imprimir" desabilitado.

1. Em um fluxo do processo 11611 (tipo 3, flag desmarcada) anexe um arquivo `.docx` e outro `.png` (arquivos só em `C:\skills-qualidade`).
2. Abra Anexos, menu (três pontinhos) de cada um.
3. Esperado (hipótese): **Imprimir e Baixar ocultos**, como no PDF. O Bug #158663 citava só PDF.
4. Observação do hub: para qualquer anexo que não seja Documento Eletrônico em PDF o front já não oferece Imprimir individual; o ponto a verificar de fato é se **Baixar** também some quando a flag está desmarcada.
5. Se o resultado for diferente do esperado, confirme com dev/PO antes de reportar como falha (é hipótese).

---

## #20 — Hipótese: impressão em lote por chamada direta ao endpoint com anexo sem permissão
**Precisa de:** cliente HTTP (Postman ou curl) e o token do usuário de teste.

1. Logado pelo navegador como o usuário de teste, abra o fluxo 31828 (mix) e clique em **Imprimir** geral.
2. F12 > Rede > clique direito na chamada `downloadAllToPrint/31828/...` > **Copiar como cURL** (inclui o token/cookies).
3. Execute o cURL no Postman/terminal e salve o PDF de saída (**você autoriza o download**).
4. Esperado: PDF com 2 páginas (A e B), sem o anexo C (sem permissão). Se vier C, é a brecha de controle de acesso citada na US.
5. Variações úteis: repetir com o fluxo 31829 (todos sem permissão): esperado erro/ausência de arquivo, nunca um PDF com anexos. Não envie ids de fluxos de outros usuários sem autorização.
Nota: o endpoint recebe o id do fluxo (não a lista de anexos), então "incluir o anexo sem permissão" = chamar o endpoint do fluxo que o contém; a filtragem é feita no servidor (`AnexoUtil.GetAttachmentFileByteArray`).

---

## #10 (lado positivo) — Restrições por papel: usuário com o papel Fiscal vê Imprimir/Baixar
**Precisa de:** um usuário com o papel "Fiscal" e acesso ao fluxo 31838. Login manual seu.

1. Confirme que o papel **Fiscal** existe e qual usuário o tem (Configurações > Papel/Usuário). Se não houver usuário com o papel, peça a um administrador (ou crie um usuário de teste e vincule ao papel, com sua autorização).
2. Faça login manualmente no Playwright com esse usuário. O usuário precisa enxergar o fluxo 31838 (participante/responsável ou acesso por papel).
3. Abra Anexos do fluxo 31838 (tipo 4: flag desmarcada; papel Fiscal em "Download/Imprimir permitido para").
4. Esperado: o anexo mostra **Imprimir** (se PDF eletrônico) e **Baixar**, e o botão geral Imprimir/Baixar aparece.
5. Contraprova já feita: o "Administrador", sem o papel, **não** vê nenhuma das duas opções nesse fluxo.

---

## Ordem sugerida
1. #14 (rápido, só precisa do SELECT com o id 3075730).
2. #10 positivo (depende só do usuário com papel Fiscal).
3. #20 (cURL + token).
4. #19 (criar anexos DOCX/PNG).
5. #17 (depende da build anterior).
