# Validações adicionais — US #163453 (pedidas pela usuária em 2026-11-04)

Origem: pendências 1, 2, 3, 4, 5 e 8 de `C:\skills-qualidade\pendencias-skills\US 163453.txt`.
Insumo para `/gerar-mapa-testes-v3 163453`. Casos de teste **sugeridos pelo QA**, não validados pelo dev nem pela PM.

Resultado esperado = o que a **US** diz (CA), não o que o dev implementou. Onde divergem, o caso está marcado **DIVERGE** e deve ser aberto como defeito ou levado à PM.

## Pendência 1 — Tablets e dimensões (CA-06, CA-05)

Larguras em px CSS (viewport), **aproximadas, de referência de mercado; confirmar no DevTools/dispositivo antes de executar** (não vêm da US). Corte do dev: 768px.

| Caso | Dispositivo | Orientação | Largura ref. | Esperado pela US | Esperado pela implementação | Observação |
|---|---|---|---|---|---|---|
| T-01 | iPad mini (6ª/7ª ger.) | Retrato | 744 | Alça visível e redimensionável (CA-06) | Sem alça, tela cheia | **DIVERGE** |
| T-02 | iPad mini (6ª/7ª ger.) | Paisagem | 1133 | Alça visível | Alça visível | |
| T-03 | iPad 9ª/10ª ger. | Retrato | 810 | Alça visível | Alça visível | |
| T-04 | iPad Air / iPad 10,9" | Retrato | 820 | Alça visível | Alça visível | |
| T-05 | iPad Pro 11" | Retrato | 834 | Alça visível | Alça visível | |
| T-06 | iPad Pro 12,9" | Retrato | 1024 | Alça visível | Alça visível | |
| T-07 | iPad (qualquer) / Android | Paisagem | ≥ 1024 | Alça visível | Alça visível | |
| T-08 | Galaxy Tab (8"–11") | Retrato | ~800 | Alça visível | Alça visível | Confirmar largura do modelo real |
| T-09 | Tablet Android 7–8" | Retrato | ~600–720 | Alça visível (tablet) | Sem alça | **DIVERGE**, confirmar modelo |
| T-10 | Surface Pro | Retrato | ~912 | Alça visível | Alça visível | |
| T-11 | Fronteira | — | 767 | — | Sem alça | Já coberto pelo dev (CV-04) |
| T-12 | Fronteira | — | 768 | — | Com alça | Já coberto pelo dev (CV-04) |
| T-13 | Celular deitado | Paisagem | ~780–932 | Sem alça (celular, CA-05) | Com alça | **DIVERGE** inversa: celular com alça |

Para cada caso: abrir o detalhamento de um gráfico, conferir presença da alça; quando presente, arrastar, duplo clique/toque e setas (se houver teclado). Registrar largura real medida (`window.innerWidth`).
Pergunta a levar à PM/dev (não decidir aqui): o critério por largura de janela atende CA-05/CA-06 ou é preciso detectar dispositivo? (REC-163453-03 segue pendente.)

## Pendência 2 — Leitor de tela real (CA-04)

| Caso | Passos | Esperado |
|---|---|---|
| LT-01 | NVDA + Firefox/Chrome: Tab até a alça | Anuncia como controle de redimensionamento (separator), nome e orientação |
| LT-02 | NVDA: pressionar ←/→ na alça | Anuncia o novo valor em percentual, com o texto "N% da largura da tela" (ou equivalente em en/es) |
| LT-03 | Narrador + Edge: mesmos passos de LT-01/02 | Mesmo anúncio |
| LT-04 | Idiomas pt, en, es | `valuetext` traduzido em cada idioma (`dashboard.ecm.aside.resizeValueText`) |
| LT-05 | Limites 30% e 100% | Anúncio de 30 e 100 sem erro |

Registrar se o `aria-valuetext` é de fato falado (CV-03 do dev mostrou `valuetext` vazio na árvore do Chromium).

## Pendência 3 — Duplo toque e arraste em tablet físico (CA-01, CA-06)

| Caso | Passos | Esperado |
|---|---|---|
| TF-01 | Tablet físico: arrastar a alça com o dedo | Largura muda, respeitando 30%–100% |
| TF-02 | Duplo toque na alça (painel fora do padrão) | Volta à largura padrão (REC-163453-04, pendente: CA-01 só cita "duplo clique") |
| TF-03 | Duplo toque: painel não fecha, nada é gravado como preferência | Painel aberto; ao reabrir, largura padrão |
| TF-04 | Repetir em retrato e paisagem, em ao menos um iPad e um Android | Mesmo comportamento |

Se o duplo toque não restaurar: abrir como achado (dev diz que `dblclick` não é garantido em touch) e levar à PM, pois o CA-01 não define dispositivo.

## Pendência 4 — Foco ao clicar na alça (CA-02)

| Caso | Passos | Esperado |
|---|---|---|
| FC-01 | Clicar (sem arrastar) na alça e pressionar ← | Setas agem sem precisar de Tab; foco visível |
| FC-02 | Arrastar a alça e soltar; pressionar → | Idem |
| FC-03 | Repetir em Chrome, Edge, Firefox e Safari | Mesmo comportamento; registrar navegadores onde só há efeito após Tab |

## Pendência 5 — Foco com diálogo aria-modal (CA-02)

| Caso | Passos | Esperado |
|---|---|---|
| FM-01 | Abrir o detalhamento; só teclado: Tab até a alça | Alça alcançável apenas por Tab; registrar quantos Tab são necessários e se o foco passa por elementos fora do diálogo |
| FM-02 | Abrir o detalhamento; conferir onde está o foco | Registrar elemento focado (dev diz que o foco não entra no diálogo ao abrir; preexistente) |
| FM-03 | Esc com foco na alça | Painel fecha, foco volta ao gatilho (registrar, não decidir) |

Se alcançar a alça for impraticável por teclado, é risco para CA-02: levar ao dev/PM (dev sugere story própria).

## Pendência 8 — Gravação a cada tecla (desempenho)

| Caso | Passos | Esperado |
|---|---|---|
| PF-01 | Segurar ← por ~5 s (auto-repeat) | Largura muda sem travar nem atraso perceptível; sem erro no console |
| PF-02 | Mesmo teste com Performance do DevTools (profile) | Registrar frame rate e tempo de bloqueio do `StorageService`; sem long tasks relevantes |
| PF-03 | Segurar → até 30% e ← até 100% | Para nos limites sem erro; ao reabrir, usa a largura gravada |
| PF-04 | Segurar a tecla e recarregar a página | Largura persistida é a última exibida |
| PF-05 | Storage indisponível/cheio (navegação privada ou cota esgotada) | Painel continua usável; nenhum erro visível (dev: falha de storage não propaga) |
| PF-06 | Máquina de baixo desempenho ou CPU throttling 4x–6x | Sem travamento que impeça ajustar a largura |

Critério numérico de "aceitável" **não existe na US**: registrar os valores medidos e levar à PM/dev (lacuna, não vira critério de aceite).
