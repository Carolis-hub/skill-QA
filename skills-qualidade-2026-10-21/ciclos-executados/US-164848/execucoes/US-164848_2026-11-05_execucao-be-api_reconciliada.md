# Execução reconciliada — Mapa de Testes #164883 (US 164848, BE via API)

**Substitui, para leitura, o relatório `US-164848_2026-11-05_execucao-be-api.md`** (que continua guardado sem alteração). Aquele relatório foi feito sobre o mapa antigo de 65 cenários. Em 2026-11-05 o mapa foi regerado como US de BE (59 cenários, só API e dados, sem dependência de front; ALT-123), e a numeração mudou. Este arquivo reaproveita as evidências já coletadas, com os números e o texto do mapa atual. **Nenhum teste novo foi executado.**

**Ambiente, forma de execução e ressalvas gerais:** as do relatório original (HMG, Oracle, `POST /api/api/TipoIndice` e `GET .../GetOne` com a sessão do `Claude-adm`; sem acesso a `LOG_APLICACAO` nem ao banco; sem endpoint de alteração).

## De-para de numeração (antigo → atual)
| Antigo | Atual |
|---|---|
| 1 a 7 | 1 a 7 |
| 9 a 13 | 8 a 12 |
| 15 a 54 | 13 a 52 (antigo − 2) |
| 59 | 53 |
| 60 a 65 | 54 a 59 |
| **Removidos (dependiam de front):** 8, 14, 55, 56, 57, 58 | — |

Os antigos 53 (Detalhe do Clássico) e 54 (Indexador DI) foram reescritos como #51 e #52 (contrato de dados, sem tela). Os antigos 6 e 7 foram reescritos como #6 e #7 (API e banco, sem tela do Clássico).

## Resumo
- Cenários no mapa: 59
- Executados: 36
- Passou: 33 (muitos com ressalva `*`, ver o relatório original)
- Parcial: 3 (#6, #7, #38)
- Falhou: 0
- Não executado: 23
- Removidos do mapa por serem de front: 6 (os antigos 8, 14, 55, 56, 57 e 58), nenhum deles era resultado `Passou` ou `Falhou`

## Detalhe por cenário executado
| # (atual) | Antigo | Cenário | Obtido | Resultado |
|---|---|---|---|---|
| 1 | 1 | Inclusão válida (Informado) | 200, cd 1120, GetOne confere | Passou* (log aplicação 19 não verificado) |
| 2 | 2 | Inclusão só com Descrição | 200, cd 1121, padrões do CA 16 conferem | Passou |
| 3 | 3 | Inclusão Específico com Identificador | 200, cd 1122, DI=3 | Passou |
| 4 | 4 | Inclusão Múltipla Seleção | 200, cd 1123, DI=4 | Passou |
| 6 | 6 | Registro gravado pela API é íntegro no banco | GetOne devolve os valores gravados; o banco não foi consultado (a evidência pela tela do Clássico deixa de valer) | **Parcial** |
| 7 | 7 | Registro legado lido e alterado pela API | cd 1144 (criado pelo Clássico) lido pela API sem erro; alteração sem endpoint | **Parcial** |
| 13 | 15 | Descrição vazia | 3 variações → 500 "Descrição: Este campo é requerido." | Passou (mensagem com prefixo) |
| 14 | 16 | Limite da Descrição | 50 ok (cd 1124); 51 rejeita | Passou |
| 15 | 17 | Limite do Identificador | 50 ok (cd 1122); 51 rejeita | Passou |
| 16 | 18 | Limite da regex | 500 ok (cd 1125); 501 rejeita | Passou |
| 17 | 19 | Limite da máscara | 150 ok (cd 1126); 151 rejeita | Passou |
| 18 | 20 | Domínio Tipo de índice | 1–4 aceitos; 0 e 5 rejeitados | Passou |
| 19 | 21 | Domínio Tipo de valor | 1–3 aceitos; 0 e 4 rejeitados | Passou |
| 20 | 22 | Domínio DI | 0 e 6 rejeitados | Passou |
| 21 | 23 | Ordenação 1 e 255 | cd 1127 e 1128 | Passou |
| 22 | 24 | Ordenação 0 e 256 | rejeita com a mensagem do CA 17 | Passou |
| 23 | 25 | Ordenação vazia, 10.5, abc | rejeita com a mensagem do CA 17 | Passou |
| 24 | 26 | Tipo × DI permitidos | 6 combinações aceitas | Passou |
| 25 | 27 | Tipo × DI proibidos | 4 rejeitadas | Passou |
| 26 | 28 | Escolha Única fora de Seleção | Informado com 1 grava 0 (cd 1132) | Passou |
| 27 | 29 | Identificador fora de Específico | "abc" não gravado (cd 1133; Oracle lê vazio como NULL) | Passou |
| 28 | 30 | Regex válida | 500 chars gravados (cd 1125) | Passou |
| 29 | 31 | Regex inválida | 500 "Expressão regular inválida."; nada gravado | Passou* (log) |
| 30 | 32 | Máscara MFP válida | 150 chars gravados (cd 1126) | Passou |
| 31 | 33 | Máscara com Tipo de valor Data | gravada vazia (cd 1134) | Passou |
| 32 | 34 | Máscara com tipo ≠ Informado | gravada vazia (cd 1135) | Passou |
| 33 | 35 | Flags de exibição | A (cd 1136) e B (cd 1137) persistem; `st_portal_cliente=1` não persiste (ambiente sem Portal) | Passou* |
| 35 | 37 | Portal do cliente sem Portal | `st_portal_cliente` fica 0; `Lookups.possuiPortal=false` na resposta da API | Passou |
| 36 | 38 | Sem sessão válida | sem headers → 403; Bearer inválido → 403 (CA 95 aceita 401/403) | Passou (reclassificado em 2026-11-05) |
| 37 | 39 | Sem permissão no menu Configurações | publicador (tipo 2) → 403 ao incluir; alterar sem endpoint | Passou* |
| 38 | 40 | Sem permissão de gerenciar índices: incluir | publicador → 403, nada gravado; o usuário também não acessa a listagem, então o pré-requisito "com acesso à listagem" (e o resultado "listagem 200") não foram atendidos | **Parcial** |
| 41 | 43 | Campos obrigatórios nunca nulos | cd 1121 (só Descrição): a API devolve `st_portal`=1, `st_portal_cliente`=0 e DI=2, não nulos; banco não consultado (a evidência pela tela do Clássico deixa de valer) | Passou* |
| 43 | 45 | Texto com aspas e SQL | gravado literal (cd 1138) | Passou |
| 45 | 47 | Duas inclusões simultâneas | cd 1142 e 1143 | Passou* (logs não verificados) |
| 46 | 48 | Rejeição não grava nem loga | 23 rejeições, total 125 → 125 | Passou* (log) |
| 51 | 53 | Conversão numérica dos campos que o Clássico lê | a API devolve 0/0/2 numéricos e não nulos (cd 1136); banco não consultado (a evidência pela tela do Clássico deixa de valer) | Passou* |
| 54 | 60 | HIPOTESE: descrição duplicada | bloqueia com "Já existe um índice com esta descrição." (também sem diferenciar maiúsculas) | Observação, não classificado |

(*) ver "Ressalvas e achados" do relatório original.

## Não executados
| # (atual) | Antigo | Motivo |
|---|---|---|
| 5, 8, 9, 10, 11, 12 | 5, 9, 10, 11, 12, 13 | Exigem alteração; sem endpoint de alteração no controller (e, nos #5, #8 a #12, dado legado específico não localizado) |
| 34 | 36 | Ambiente sem módulo Portal; o cenário exige ambiente com Portal |
| 39, 40, 42 | 41, 42, 44 | Exigem alteração (sem endpoint) |
| 44 | 46 | Exige leitura de `LOG_APLICACAO` (sem acesso) |
| 47, 48 | 49, 50 | Dependem do mecanismo para forçar falha técnica (não definido) |
| 49, 50 | 51, 52 | Banco do ambiente é Oracle; SQL Server indisponível; a repetição no Oracle depende do #49 |
| 52 | 54 | Antes dependia de telas de outros módulos. **Agora é de API e dados, pode ser executado** (incluir via API e conferir na API e no banco; o banco hoje não tem acesso) |
| 53 | 59 | Exige alteração (sem endpoint) |
| 55 a 59 | 61 a 65 | Hipóteses do mapa: aguardam decisão do dev/PO (os CA 18/19, 20, 21 e 64 já trazem decisão da PM; reclassificar) |

## Itens do relatório original que deixam de valer
- **Antigos #8 e #55 (lançamento de documento), #14 (cancelar), #57 (Portal), #56 (MFP) e #58 (Busca):** removidos do mapa por serem de front. Deixam de contar como "não executados". O cd 1145 e a associação ao tipo de documento 100 (já desfeita) ficam só como registro histórico.
- **Evidências pela tela do Clássico** (Detalhar do cd 1136 e do cd 1121, print `classico-detalhe-1121.png`): não valem mais como evidência dos #6, #41 e #51. Foram trocadas por evidência da API; o banco segue sem acesso.
- **Bug #166156 (Salvar do front usa dado simulado):** é de front e está fora do escopo desta US de BE; não bloqueia nenhum cenário do mapa atual.

## Pendências para fechar o mapa
1. Acesso de leitura ao banco e a `LOG_APLICACAO` fecharia os #1, #6, #29, #41, #44, #45, #46, #51 e #52.
2. Endpoint de alteração (PUT) ou massa de dados legada, para os #5, #7 e #8 a #12, #39, #40, #42 e #53.
3. Usuário não administrador com acesso à listagem, para o #38 (ou aceitar que, no BE, menu e "gerenciar" são a mesma barreira, como já apontado no relatório original).
4. Ambiente com Portal (#34) e mecanismo de falha técnica (#47 e #48).
5. Decisão do dev/PO para as hipóteses #55 a #59.

## Registros de teste criados no HMG (não excluídos)
Códigos 1120 a 1145, como no relatório original. A exclusão é do escopo da BE 04.
