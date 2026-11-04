# Fidelidade ao protótipo — US 164996 (Opções do índice) — 03/11/2026

Regra da usuária: a tela deve ser **expressamente fiel ao protótipo** e **qualquer divergência deve ser sinalizada**. Tolerância: ±1 px por arredondamento.

**Fonte do esperado:** `get_design_context` dos 7 quadros de "Opções do índice" do Figma `Gerenciamento de índice` (valores padrão dos tokens do design system Nyx). **Fonte do obtido:** estilos computados e retângulos da tela, lidos no navegador com janela de 1280×832, mais zoom nos prints. O ambiente usa dados simulados (Bug #165721), então vale para o que o FE desenha, não para dado.

Limite da medição: os componentes `nyx-*` (botões, ícones, checkbox, mensagem de erro, toast, overlay, caixa do modal) têm Shadow DOM, então só o retângulo externo é medido; cor, raio, borda e sombra internos só por comparação visual. Esses itens estão em "Não verificados".

## Divergências medidas (esperado × obtido)

### Lista de opções (quadro "Opções do índice", 14257:3188)
| Id | Elemento | Protótipo | Dev (medido) |
|---|---|---|---|
| F1 | Linha: padding e altura | padding 16 px em todos os lados; altura 57 px (16+24+16+1) | padding 8 px em cima e embaixo, 16 px nos lados; altura 72 px (73 com borda) |
| F2 | Linha: separador | borda **inferior** 1 px `#e2e2e2` | borda **superior** 1 px `#d4d4d4` (a primeira linha não tem) |
| F3 | Coluna Código | Roboto 14 px / 16 px | 16 px |
| F4 | Altura de linha do texto da linha ("Financeiro", "Ativa") | 24 px | `normal` (cerca de 19 px) |
| F5 | Valor da opção inativa | cor `#707070` | cor `rgb(67,67,67)` (`#434343`) |
| F6 | Contêiner da lista | raio 8 px | raio 12 px |
| F7 | Botões Editar e Remover | botão 24×24, ícone 12×12, ícone de linha (contorno) | botão 30×30, ícone 20×20; nas capturas o ícone é preenchido (sólido), não de contorno |
| F8 | Texto de orientação | Roboto 16 px / 24 px (duas linhas = 48 px) | altura de linha `normal` (duas linhas = 38 px) |
| F9 | Placeholder "Nome da opção" | cor `#353535` | cor `#434343` (`rgb(67,67,67)`) |
| F10 | Botão "Adicionar opção" | altura 36 px (padding 10, rótulo Medium 14/16), largura cerca de 121 px | altura 40 px, largura 126 px |
| F11 | Botão "Fechar" | altura 42 px (padding 12, rótulo Bold 16/18), largura cerca de 72 px | altura 40 px, largura 66,8 px |
| F12 | Contador "N opções · N ativas" | Roboto 12 px / 16 px (altura 16 px) | 12 px, altura de linha `normal` (altura 14 px) |

### Edição na linha (quadro "edição, remoção e erro", 14257:3685)
| Id | Elemento | Protótipo | Dev (medido) |
|---|---|---|---|
| F13 | Campo de edição | borda 1,5 px `#353535` (ativo), texto preto | borda 1 px `#d4d4d4`, texto `#353535` |
| F14 | Botões Salvar e Cancelar | altura 36 px | Salvar 40 px; Cancelar 42 px (tamanhos diferentes entre si) |

### Confirmação de remoção
| Id | Elemento | Protótipo | Dev (medido) |
|---|---|---|---|
| F15 | Faixa de confirmação | padding 16 px em todos os lados; borda inferior 1 px `#d4d4d4`; texto 16 px / 24 px | padding 8 px em cima e embaixo, 16 px nos lados; sem borda inferior; altura de linha `normal`; altura 72 px |
| F16 | Botões Cancelar e Remover | altura 36 px; Remover `#ff2d2d` | Cancelar 42 px; Remover 40 px; o tom do Remover parece mais escuro que `#ff2d2d` (verificação visual, ver "Não verificados") |

### Mensagem de erro (quadros obrigatório, Números e Data)
| Id | Elemento | Protótipo | Dev |
|---|---|---|---|
| F17 | Texto da mensagem | cor `#353535` (cinza escuro), com ícone de triângulo | texto **vermelho** com o ícone de triângulo (zoom `ev-164996-fid-erro-dev.png`); a cor exata não é mensurável por estilo (Shadow DOM) |
| F18 | Borda do campo em erro | 1,5 px `#cc2424` | aparenta 1 px vermelha (visual) |

### Estado vazio (quadro "sem opções", 14289:10074)
| Id | Elemento | Protótipo | Dev |
|---|---|---|---|
| F19 | Ícone | ícone de servidor 44×44 | ícone de lista (três itens) |
| F20 | Texto | uma linha centralizada, Roboto 14 px / 20 px, largura 280: "Nenhuma opção cadastrada. Crie opções utilizando o botão acima" | duas linhas: título "Nenhuma opção cadastrada" e dica "Adicione a primeira opção no campo acima." (já registrado como D1) |

### Toast (quadro "Mensagens de sucesso", 14289:12189)
| Id | Elemento | Protótipo | Dev |
|---|---|---|---|
| F21 | Altura do toast | cerca de 56 px (padding 16 + texto 24), largura 418 px | altura 64 px, largura 418 px |
| F22 | Textos | oito toasts, entre eles "Opção incluída com sucesso." e "Opção alterada com sucesso." | já registrados como D2 e D3; o toast fica atrás do modal (D4) |

## Medido e conforme
- **Título:** Roboto 700, 24 px / 32 px, preto.
- **Orientação:** Roboto 16 px, preto.
- **Campo "Nome da opção":** altura 50 px (12+24+12+2), padding 12/16, borda 1 px `#d4d4d4`, raio 8 px, fundo branco, texto `#353535`.
- **Contador:** 12 px.
- **Coluna Código:** largura 56 px.
- **Modal:** largura 800 px (766 + padding 2×16 + borda 2×1).
- **Faixa de confirmação:** fundo `#ffebeb`.
- **Textos de "Ativa" e do valor:** 16 px.
- **Textos literais** do modal, da confirmação, de obrigatório, Números e Data (as mensagens divergentes já estão em D1 a D3).

## Não verificados (e por quê)
| Item | Motivo |
|---|---|
| Overlay `rgba(18,18,18,0.4)`, sombra do modal, borda `#d4d4d4`, raio 10 px e padding 16 px da caixa do modal | A caixa e o overlay estão no Shadow DOM do `nyx-modal`; só a largura foi inferida |
| Botão fechar (X) 20×20 e ícone 16 px | Shadow DOM |
| Checkbox 16 px, raio 4 px, cor `#2099fa`, ícone de check 12 px, borda `#a9a9a9` do desmarcado | Shadow DOM do `nyx-checkbox` |
| Cor exata do botão Remover (`#ff2d2d`), do botão Cancelar (borda `#a9a9a9`) e dos botões de marca (`#2099fa`) | Shadow DOM do `nyx-button` |
| Cor e peso exatos da mensagem de erro e da borda do campo em erro (F17 e F18) | Shadow DOM do `nyx-text-helper` e do campo; só visual |
| Cor do fundo do toast, raio 12 px, sombra, ícone check-circle 20 px e botão fechar | Shadow DOM do `nyx-toast` |
| Nome do ícone de remover no Figma | O export traz o mesmo recurso "pen" nos dois botões; não confirmado |
| Hover, foco e estado desabilitado dos botões | O Figma não especifica |
| Posição vertical do modal | O Figma usa 80 px e 163 px conforme o quadro; o dev centraliza |

## Conclusão
Há **21 divergências medidas ou visíveis** (F1 a F21, mais as D1 a D5 já registradas) entre a tela e o protótipo. A tela **não é fiel ao protótipo** em espaçamento, alturas, tipografia, raios, tamanhos de botões e ícones, cor da mensagem de erro, estado vazio e altura do toast. Itens do Shadow DOM seguem sem verificação e exigem inspeção pelo dev.

Evidências: `evidencias_2026-10-30\ev-164996-fid-lista-dev.jpg`, `...-fid-edicao-dev.jpg`, `...-fid-confirmacao-dev.png`, `...-fid-erro-dev.png`, e os quadros do Figma em `mapas-teste\prototipo\` (`01-opcoes.png`, `02-edicao-remocao-erro.png`, `03-sem-opcoes.png`, `04-obrigatorio.png`, `07-toasts.png`, `10-lista-figma-contexto.png`).

Observação do mapa: o texto do estado vazio no mapa (#13) termina com ponto final ("...botão acima."); o quadro do Figma não tem o ponto final.
