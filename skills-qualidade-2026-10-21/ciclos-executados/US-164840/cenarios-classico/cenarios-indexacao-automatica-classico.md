# US 164840 — Cenários extraídos do clássico (Indexação automática)

Origem: `SmartShare/SmartShare.DI.IndexacaoAutoService/` (hub, somente leitura). Evidência = `lida-no-codigo`.
Abreviações: `MIA` = `ManagerIndexacaoAutomatica.cs`; `CC` = `CampoConsulta.cs`; `G` = `SmartShare.DI/SmartShare.DI/Global.cs`.
Não é o código do Agente novo (`smartshare-di` não está no hub): é o **comportamento de referência** do legado.
Coluna "Legado vs US": **Preservar** = o card diz que o legado é mantido de propósito (r29); **Verificar** = o card não diz.

## A. Ciclo e pré-condições
| ID | Cenário | Esperado no clássico | Evidência | Legado vs US |
|---|---|---|---|---|
| CL-01 | Ciclo normal | Timer de 10 s; para o timer durante o processamento e religa no `finally` (sem reentrância) | MIA:59, 78, 98-101 | Card: 10 s sem reentrância |
| CL-02 | Exceção no ciclo | Intervalo passa a 60 s; volta a 10 s no ciclo seguinte bem-sucedido | MIA:91, 96 | Card: 60 s após exceção |
| CL-03 | Recarga de configuração | A cada 100 arquivos processados recarrega dados do cliente e zera o cache de propriedades por tipo | MIA:42, 107-112, 974 | Card: recarga a cada 100 |
| CL-04 | Cache por tipo de documento | Config do tipo (índices, máscara, regiões, templates) é carregada uma vez e só muda após a recarga; alterar a configuração no meio não vale até lá | MIA:282-334 | Verificar |
| CL-05 | Pré-condição inválida | Sem `IsIntegracaoAutomatica`, sem `DtEfetivacao`/`DtVencimento` ou pasta inexistente: lança exceção (log) e cai no intervalo de 60 s | MIA:960-971 | Verificar |

## B. Seleção e preparo dos arquivos
| ID | Cenário | Esperado no clássico | Evidência |
|---|---|---|---|
| CL-06 | Extensões lidas | `.tif .tiff .pdf .png .jpg .jpeg .gif`; outras são ignoradas | G:12; MIA:945 |
| CL-07 | Pastas ignoradas | `_templates`, `_Indexados`, `_IndexadosOriginal`, `_Verificados` e diretórios alocados à atividade de indexação | G:11; MIA:939-942 |
| CL-08 | Ordem | Por data de criação (o `OrderBy` por nome é sobreposto pelo segundo `OrderBy`) | MIA:945 |
| CL-09 | Capa DI com mais de 1 página | Remove a página 1 antes de indexar | MIA:180-184 |
| CL-10 | Capa DI com 1 página | Original vai para `_NaoIndexados` (nome repetido ganha sufixo `_1`, `_2`…), log, segue ao próximo | MIA:185-190, 118-133 |
| CL-11 | Nome do arquivo com separador | Separador do template de indexação do tipo (padrão `_`); a parte após o primeiro separador entra no nome do arquivo gerado | MIA:198-220 |

## C. Descoberta do tipo de documento
| ID | Cenário | Esperado no clássico | Evidência |
|---|---|---|---|
| CL-12 | Tipo fixo do cliente | Se há tipo fixo, ele vale e não tenta OCR nem QR | MIA:230-236 |
| CL-13 | Tipo por template (OCR) | Lê a zona OCR e usa o primeiro número; sem número: erro `TemplateTipoDocumento` | MIA:447-471 |
| CL-14 | Sem template, tipo da pasta | Usa `cpiInfo.CdTipoDocumento` | MIA:472-473 |
| CL-15 | Tipo por QR Code | Lê o QR conforme a posição configurada | MIA:246-253 |
| CL-16 | Tipo do QR não pertence ao cliente | `TipoDocumentoQRCodeCliente`, mensagem "Tipo de Documento N não pertencente ao Cliente.", tipo zerado, vai para crítica | MIA:255-264 |
| CL-17 | Exceção na leitura do QR do tipo | `TipoDocumentoQRCode` com a mensagem da exceção | MIA:267-274 |
| CL-18 | Nenhum tipo identificado | Erro `TipoDocumento` (se não houver erro de tipo anterior); insere documento criticado sem tipo (tipo 0, sem índices) | MIA:410-418 |

## D. Extração dos índices
| ID | Cenário | Esperado no clássico | Evidência | Legado vs US |
|---|---|---|---|---|
| CL-19 | Ordem das fontes | OCR → código de barras (do original) → QR → nome do arquivo → consulta SQL → valor fixo | MIA:341-346, 349-353 | Card: ordem OCR, barras, QR, nome, SQL |
| CL-20 | Primeiro valor vale | Fonte posterior não sobrescreve valor já obtido, exceto a consulta SQL, que sobrescreve | MIA:572, 708, 755, 652-655 | Card: igual |
| CL-21 | OCR vazio ocupa o índice | Região lida sem texto grava vazio no dicionário e bloqueia as fontes seguintes; depois cai no valor fixo, se houver | MIA:518, 349-353 | Card: preservado |
| CL-22 | Falha de OCR em região | `IndiceOCR` com tipo de índice e região na mensagem | MIA:520-527 | Verificar |
| CL-23 | Código de barras incompleto | Menos índices achados que configurados: `IndiceCodigoBarras` e lista "Não foram localizados os índices …(motivo)" | MIA:553-569 | Card: motivo `Barcode`/`DV`/`LeadTools` na mensagem |
| CL-24 | Exceção no código de barras | `IndiceCodigoBarrasEx` | MIA:576-583 | Verificar |
| CL-25 | QR com índice faltando | `IndiceQRCode` com mensagem do QR ou "Posição N inexistente."; exceção dá `IndiceQRCodeEx` | MIA:683-721 | Card: 40 casos de QR |
| CL-26 | Índice pelo nome do arquivo | Pela posição após o separador; falta dá `IndiceIndexacao` | MIA:735-768 | Verificar |
| CL-27 | DPI pelo nome do arquivo | Só se há configuração de DPI no template; erro dá `DPIIndexacao` | MIA:776-795, 389-390 | Verificar |

## E. Consulta SQL
| ID | Cenário | Esperado no clássico | Evidência |
|---|---|---|---|
| CL-28 | Uma linha de retorno | Preenche o índice (e os campos invisíveis ainda vazios) | CC:92-114 |
| CL-29 | Zero ou mais de uma linha | `ConsultaSqlSemRetornoUnico`, mensagem "Tipo de índice N filtro X" | CC:116-117; MIA:632, 658-664 |
| CL-30 | Exceção na consulta | `ConsultaSqlSemRetornoUnico`, mensagem "Erro ao realizar consulta. Erro: …" | MIA:623-630 |
| CL-31 | Filtro ausente | Sem valor lido nem fixo para o filtro: `ConsultaSqlSemFiltro`, "Tipo de índice N", vai ao próximo | MIA:598-613 |
| CL-32 | Conversão numérica/data do retorno | O valor convertido é calculado, mas o gravado é `item.DsValor` original: a conversão se perde. **Peculiaridade/defeito** | MIA:636-655 |

## F. Validação e título
| ID | Cenário | Esperado no clássico | Evidência | Legado vs US |
|---|---|---|---|---|
| CL-33 | Índice numérico inválido | Zera o valor e dá `ValidacaoIndice` | MIA:883-893 | Verificar |
| CL-34 | Índice data inválido | `Global.ParseData`; vazio dá `ValidacaoIndice` | MIA:895-902; G:30 | Verificar |
| CL-35 | `isValid` não volta a verdadeiro | Depois do primeiro inválido, a flag fica falsa para os índices seguintes. **Peculiaridade** | MIA:878, 905 | Card: preservado (r29) |
| CL-36 | Índice requerido vazio | `ValidacaoIndiceRequerido` | MIA:908-909 | Card: igual |
| CL-37 | Só o primeiro erro vale | Todos os pontos checam `_erroIndexacao == Nenhum` antes de gravar o erro | MIA:258, 525, 559, 607, 687, 855, 905, 908 | Card: igual |
| CL-38 | Validação por integração (DLL) | Quando o tipo exige: sem `DsIntegracao` dá `IntegracaoConfigInexistente`; falha dá `IntegracaoFalha`; exceção dá `IntegracaoErroValidacao` | MIA:825-869 | Card: tipo que exige DLL vai para `IntegracaoConfigInexistente` |
| CL-39 | Título pela máscara | Troca `[IND_n]` pelo valor; índice ausente vira vazio; limpa máscaras restantes | MIA:804-823 | Verificar |

## G. Saída e falhas
| ID | Cenário | Esperado no clássico | Evidência | Legado vs US |
|---|---|---|---|---|
| CL-40 | Documento criticado | `StCriticado=1`, `CdErroCritica` = código do erro, mensagem e stack gravadas; `IdTipoIndexacao=2` | MIA:392-401 | Card: crítica com o código |
| CL-41 | Falha ao inserir | Apaga o arquivo temporário; o original continua na pasta; sem limite de tentativas: tenta de novo a cada ciclo. **Peculiaridade** | MIA:423-428 | Card: nova tentativa sem limite (r29) |
| CL-42 | Estado do QR entre arquivos | `strQRCodeTpDoc` e `vlPosicaoTpDocQRCodeDOC` são campos da classe e só são zerados quando há tipo QR do cliente: com tipo fixo ou OCR, o valor do arquivo anterior é usado nos índices QR. **Peculiaridade** | MIA:36-37, 249-253, 685 | Card: preservado (r29) |
| CL-43 | Parada | `Dispose` para o timer e chama `LiberaCliente(cliente, usuário)`; erros ignorados | MIA:998-1015 | Card: apaga a reserva |
| CL-44 | Falha ao iniciar o serviço | Exceção no `OnStart`: log e `Stop()` | Service.cs:47-51 | Verificar |

## Lacunas
- `id_statusenvio = 6` no insert: a gravação está em `IndexadorControl.InsereDocumento`, **não lida** nesta busca.
- Efeito exato de `LiberaCliente` (CL-43) e da reserva em `CLIENTE_PASTA_INDEXACAO`: não lido.
- Telas de configuração relacionadas, encontradas mas **não lidas**: `SmartShare.DI.Client/Telas/ConfigIndexacaoAutomatica.cs`, `ConfereIndexacaoAutomatica.cs`, `SmartShare.DI.Server/Telas/IndexacaoAutomaticaQRCode.cs`.
- Rotação e OCR do arquivo de trabalho (`RotacionarEAplicarOCR`, card: fora por ora): não localizado como método próprio neste serviço.
