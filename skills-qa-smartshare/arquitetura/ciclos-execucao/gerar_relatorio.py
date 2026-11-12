from pathlib import Path
import csv, hashlib, html, re, json
root=Path(__file__).resolve().parent
out=root/'relatorio-consolidado-2026-11-10'
out.mkdir(exist_ok=True)
cycles=['164259-US164251','161495-US160823','161711-US161711']
inventory=[]
for cycle in cycles:
    for p in sorted((root/cycle).rglob('*')):
        if p.is_file():
            raw=p.read_bytes()
            # Leitura integral dos registros textuais para inventário e rastreabilidade.
            content=raw.decode('utf-8-sig',errors='replace') if p.suffix.lower() in ['.md','.txt','.log','.sql','.html','.py'] else ''
            inventory.append({'ciclo':cycle,'arquivo':p.relative_to(root).as_posix(),'extensao':p.suffix,'bytes':len(raw),'linhas':len(content.splitlines()) if content else '', 'sha256':hashlib.sha256(raw).hexdigest()})
with (out/'inventario-fontes.csv').open('w',encoding='utf-8-sig',newline='') as f:
    w=csv.DictWriter(f,fieldnames=list(inventory[0]),delimiter=';');w.writeheader();w.writerows(inventory)
rows=[('164251','SQL Server',20,3,1,0,1,2),('164251','Oracle',20,4,1,0,0,2),('160823','Oracle',18,7,1,0,4,0),('160823','SQL Server',19,6,1,0,4,0),('161711 / 161716','Oracle',2,3,0,2,2,0),('161711 / 161713','Oracle',3,4,0,2,1,0),('161711 / 161712','Oracle',2,6,0,3,1,0),('161711 / 161714','Oracle',2,0,0,0,3,0),('161711 / 161839','Oracle',0,4,0,4,3,0)]
with (out/'indicadores.csv').open('w',encoding='utf-8-sig',newline='') as f:
    w=csv.writer(f,delimiter=';');w.writerow(['US / bug','Banco','Passou','Com ressalva / parcial / observação','Falhou','Inconclusivo / parcial sem conclusão','Não executado / fora','Não aplicável','Total']);w.writerows([(*r,sum(r[2:])) for r in rows])
report='''# Relatório consolidado das execuções de QA

**SmartShare Arquitetura • Sprint 4 • Posição documental em 10/11/2026**

Período das execuções: **26/10 a 10/11/2026**. Três ciclos analisados: leitura de status no BPM, desassociação automática e bugs dos instaladores. Ambiente de QA local; os registros não comprovam homologação em HMG ou produção. Responsável pelas execuções registrado: Guilherme Henrique Correa Borges.

## 1. Mensagem para apresentação

As execuções demonstraram recuperação de filas travadas, controle de concorrência, proteção contra duplicidade e funcionamento da desassociação automática nos dois bancos. A evidência mais forte de concorrência envolve **1.200 itens, em dois ensaios de 600**, sem duplicidade ou itens órfãos. Na validação de ExecutaWs, **103 pendências terminaram com 103 chaves distintas e zero duplicatas**.

O portfólio ainda exige ações antes de uma decisão de liberação: **um defeito novo confirmado e registrado (#166161)**, cobertura parcial nos instaladores e validação da integração dos PRs testados isoladamente. A ausência de cenários classificados como falha nos instaladores não representa aprovação integral: só **9 dos 47 cenários** passaram sem ressalva.

**Leitura recomendada para a gestão:** há progresso funcional comprovado, porém não há base documental para declarar os três ciclos integralmente homologados. A US 164251 atende aos critérios de aceite nos ensaios locais; a US 160823 tem recomendação registrada de não liberar até corrigir o defeito; os instaladores permanecem com cobertura incompleta e divergências de revisão pendentes.

## 2. Painel de indicadores

| Indicador | Valor | Interpretação |
|---|---:|---|
| Ciclos analisados | 3 | Três pastas de ciclos |
| Escopo atual dos mapas | 104 | 27 + 30 + 47 cenários; contagem por mapa, sem repetir por banco |
| Registros consolidados de cenário × banco | 161 | 54 + 60 + 47; não representa 161 testes distintos |
| Passou sem ressalva | 86 | 53,4% dos 161 registros |
| Resultado positivo com limitação | 37 | 23,0%; reúne parcial aprovado, ressalva e observação |
| Falhou | 4 | 2 ocorrências por banco de cada um de 2 cenários; somente um virou defeito novo |
| Inconclusivo ou parcial sem conclusão | 11 | Todos nos instaladores |
| Não executado ou fora do escopo da rodada | 19 | Inclui hipóteses e variantes clássicas dispensadas |
| Não aplicável | 4 | Dois cenários da US 164251 em cada banco |
| Com alguma execução/avaliação registrada | 138 | 86 + 37 + 4 + 11; inclui tentativas inconclusivas |
| Resultado positivo sem ou com limitação | 123 | 76,4% do escopo bruto; não é taxa de homologação |
| Defeito novo formalizado | 1 | Bug #166161, reproduzido em dois bancos |

**Como os números foram calculados:** unidade = cenário do mapa vigente por banco da rodada consolidada. As primeiras rodadas e os retestes são usados para explicar evolução, sem somar novamente seus resultados. O mapa antigo de 41 cenários dos instaladores e o cenário extra 36a ficam no histórico, fora do denominador atual de 47. Os 104 cenários dos mapas também podem se sobrepor funcionalmente entre bugs.

O indicador 138 não significa 138 execuções completas. Entre os 37 resultados positivos limitados há **6 “passou parcial”, 30 “passou com ressalva” e 1 “passou com observação”**. Os parciais sem conclusão de #161716/3 e #161712/4 foram agrupados com inconclusivos. As classificações originais continuam válidas; os agrupamentos servem apenas ao painel.

## 3. Resultados por ciclo e banco

| Ciclo / banco | Passou | Positivo limitado | Falhou | Inconclusivo / parcial sem conclusão | Não executado / fora | N/A | Total |
|---|---:|---:|---:|---:|---:|---:|---:|
| 164251 • SQL Server | 20 | 3 | 1 | 0 | 1 | 2 | 27 |
| 164251 • Oracle | 20 | 4 | 1 | 0 | 0 | 2 | 27 |
| 160823 • Oracle | 18 | 7 | 1 | 0 | 4 | 0 | 30 |
| 160823 • SQL Server | 19 | 6 | 1 | 0 | 4 | 0 | 30 |
| 161711 • Oracle, cinco bugs | 9 | 17 | 0 | 11 | 10 | 0 | 47 |
| **Total** | **86** | **37** | **4** | **11** | **19** | **4** | **161** |

Na US 164251, 49 de 50 cenários aplicáveis por banco tiveram execução (98%); a pendência é o #22 no SQL Server. Na US 160823, os 26 cenários executáveis foram exercitados em cada banco (52/52), mas quatro hipóteses por banco ficaram sem execução. Nos instaladores, 37/47 tiveram alguma avaliação (78,7%), incluindo 11 inconclusivos ou parciais sem conclusão; 26/47 tiveram resultado positivo, dos quais 17 com ressalva.

### 3.1 US 164251 — Regra de leitura de status no BPM

**Período:** 26 e 27/10. **Código:** commit d9784d80, PRs 29707 e 29965. **Escopo vigente:** 27 cenários; #25 de ECM removido. Fontes de fechamento: etapas 15 e 17.

Os estados finais 3, 5 e 6 foram retirados da fila e movidos ao JOB_DUMP sem reexecução. Os testes cobriram fluxo normal, retry, envenenamento, locks válidos, múltiplos itens, paralelismo e concorrência entre instâncias. O relatório conclui atendimento aos critérios de aceite nos dois bancos.

| Evidência quantitativa | SQL Server | Oracle |
|---|---|---|
| Concorrência real | 600 itens; divisão 435 / 165 entre instâncias | 600 itens; divisão 350 / 250 |
| Sobreposição observada | Aproximadamente 6,6 s | Aproximadamente 28 s |
| Integridade do ensaio | 0 duplicados, 0 órfãos | 0 duplicados, 0 faltantes |
| Retomada após limpeza | Novo agendamento em cerca de 2 s | Novo agendamento em cerca de 1 s |
| Falha de e-mail, cenário 22 | Não reproduzida; envios aceitos | 35 tentativas com erro, zero entregas; jobs em Sucesso conforme regra do PO |

No Oracle houve 615 movimentações verificadas sem StuckItemMoveError. Esse número não se soma aos 600 itens do ensaio, pois inclui seu volume. Os 625 dumps preservados são evidência de ambiente e também não equivalem a 625 cenários.

**Exceção importante:** #27 falhou nos dois bancos quando Data_Atualizacao era nula. A análise decidiu não abrir defeito por enquanto: o esperado vem de inferência do legado e não há caminho real de gravação do nulo confirmado. A decisão cabe a dev/PO. Permanecem a validação em HMG, o efeito de negócio dos itens movidos, o job 20 sem configuração e a borda temporal de aproximadamente 70 s no Oracle.

### 3.2 US 160823 — Início de desassociação automática

**Período:** 04 a 06/11. **Escopo:** 30 cenários, sendo 26 executáveis e quatro hipóteses. **Código:** net8 ab180c0f; clássico do PR 29228, commit 4b2b504ec, além da versão instalada usada na comparação inicial.

Foram validados prazos em minutos, horas, dias e semanas, retorno da tarefa ao papel, logs e opções da tarefa, atualização de formulário, isolamento da liberação de anexos por usuário e exclusão de tarefas inelegíveis. Também houve exercício de recuperação após falha e de concorrência entre Workers. No SQL Server, um ensaio registrou 35 fluxos distribuídos em 27 e 8 por instância, sem sobreposição de processamento.

**Defeito novo #166161:** valor inicial nulo em campo “Propriedade do Processo” provoca NullReferenceException e impede a desassociação. Reproduzido em Oracle e SQL Server. As duas falhas do painel correspondem ao mesmo defeito. A massa nula foi criada diretamente no banco; a ocorrência dessa origem em produção não foi confirmada. Severidade sugerida no registro: Medium, a confirmar com o time.

**Diferença operacional relevante:** no SQL Server, bloqueio de comando gerou timeout em cerca de 30 s; no Oracle foram observadas esperas de 80 a 88 s sem timeout equivalente. O lote sequencial fica exposto ao atraso de uma linha bloqueada. Avaliar timeout e isolamento; não extrapolar esses tempos para SLA ou benchmark de desempenho.

O fix do JOIN por passo do Agent clássico passou com o build do PR 29228 nos dois bancos, conforme fechamento de 06/11. Ainda faltam front de configuração, avanço explícito pela API net8, complementos de Oracle e decisão sobre as quatro hipóteses. A recomendação registrada é não liberar até corrigir #166161 e reexecutar a regressão.

### 3.3 US 161711 — Bugs dos instaladores

**Período:** 06 a 10/11, com fechamento atualizado na etapa 31. Cinco mapas atuais, cinco branches isoladas e 47 cenários. Não há execução equivalente consolidada em SQL Server. Testar branches isoladas não valida sua integração.

| Bug / PR | Tema | Passou | Ressalva | Inconclusivo / parcial | Não executado / fora |
|---|---|---:|---:|---:|---:|
| 161716 / 30104 | Duplicidade de ExecutaWs | 2 | 3 | 2 | 2 |
| 161713 / 30060 | Retry e envenenamento do ExecutaSql | 3 | 4 | 2 | 1 |
| 161712 / 30457 | Duplicidade no Scheduler | 2 | 6 | 3 | 1 |
| 161714 / 30486 | Log do AvancoTemporal | 2 | 0 | 0 | 3 |
| 161839 / 30253 | Destinatário da observação | 0 | 4 | 4 | 3 |
| **Total** | | **9** | **17** | **11** | **10** |

**Evidências de valor:** ExecutaWs limitou o primeiro ciclo a 100 linhas para 103 pendências; as três restantes entraram depois, com 103 sucessos e zero chaves repetidas. Três fluxos com endpoint indisponível chegaram ao estado Envenenado após cinco tentativas, sem recriação duplicada. No Scheduler, 11 linhas mantiveram 11 chaves distintas por aproximadamente dez ciclos, sem repetição.

**Avanços de 10/11:** backoff fixo de 60 s e exponencial de 60, 120, 240 e 480 s foram observados; recorrência voltou a ser exercitada com Worker real; fuso Asia/Tokyo foi refletido em cinco jobs; dois alertas para três destinatários foram percorridos sem suprimir o segundo alerta. Esses resultados têm ressalvas de ambiente e escopo.

**Limitações que impedem conclusão integral:** o PR 30486 altera o log em situação de erro, mas a exceção alvo em AvancarFluxo não foi exercitada. As duas aprovações desse bug são regressões, não prova da correção principal. O ExecutaSql falhou por conexão indisponível, não por SQL inválido, e o caminho de SQL válido ficou inconclusivo. O destinatário de observações foi identificado em log, porém a entrega de e-mail falhou. Comitê, ramos paralelos, executor anterior nulo e outras opções ainda têm lacunas.

Há divergências de revisão independente não incorporadas à classificação original: por exemplo, ressalvas sugeridas como inconclusivas e aprovações sugeridas com ressalva. A revisão antecede parte das rodadas posteriores; portanto, não foi usada para reclassificar automaticamente os resultados mais recentes. O painel preserva as classificações dos relatórios.

Os bugs 161715 e 161717 foram analisados, mas não têm mapa próprio vigente nessa rodada: 161715 sem implementação, relacionado ao PBI 165944; 161717 fechado sem correção, com regressão incluída no cenário 12 do mapa de 161712. Esses estados são os registrados nas fontes, sem consulta atual ao Azure DevOps.

## 4. Evolução das execuções

| Data | Marco | Ganho demonstrado |
|---|---|---|
| 26/10 | US 164251: bloqueio inicial de ferramentas, depois ensaios locais | De 5 aprovações iniciais para 18 ao fim do dia; concorrência e retry exercitados |
| 27/10 | Fechamento SQL Server e rodada Oracle | 20 aprovações sem ressalva em cada banco; falha de envio exercitada no Oracle |
| 04/11 | Início da US 160823 | Matriz de 30 cenários e primeira execução Oracle |
| 05/11 | SQL Server e investigação de valor nulo | Defeito #166161 formalizado; diferença de timeout identificada |
| 06/11 | Builds atualizados e comparação com clássico | Cenário 24 aprovado com fix; falha de nulo mantida; relatório final consolidado |
| 06 a 09/11 | Instaladores: análises, mapas e preparação | Mapa inicial de 41 substituído na consolidação por cinco mapas com 47 cenários |
| 09/11 | Oracle liberado com ressalva | Cinco bugs exercitados em branches isoladas |
| 10/11 | Complementos de massa e reexecuções | Backoff, timezone, recorrência e múltiplos alertas ganharam evidência |

Os placares intermediários são cumulativos e mudam com reclassificações, hipóteses e remoções de escopo. Por isso não foram somados nem usados para calcular produtividade diária.

## 5. Riscos e decisões para a próxima reunião

| Prioridade proposta | Tema | Impacto | Próxima ação | Responsável sugerido |
|---|---|---|---|---|
| Alta | Bug 166161 | Desassociação falha com nulo nos dois bancos | Corrigir e repetir #22, com nulo e vazio, nos dois bancos | Dev + QA |
| Alta | Integração dos PRs de instaladores | Comportamento de fila pode divergir do validado isoladamente | Resolver conflito 30060 × 30457 e testar build integrado | Dev + QA |
| Alta | JOB_DUMP bloqueia ou permite reenfileirar | PR 30457 difere de 30104 / 30060; risco de retorno de pendências já processadas | Confirmar regra e executar regressão da chave após dump | Dev + PO + QA |
| Alta | Envio de e-mail | Job pode terminar em Sucesso e marcar notificação sem entrega | Corrigir ambiente e validar entrega ponta a ponta | Responsável pelo ambiente + QA |
| Alta | Log principal do AvancoTemporal | Correção alvo ainda sem evidência direta | Definir mecanismo de exceção e executar cenários 1 a 3 | Dev + QA |
| Média | Oracle sem timeout equivalente | Linha bloqueada pode atrasar lote | Avaliar CommandTimeout e ensaio controlado de lock | Dev |
| Média | Data_Atualizacao nula | Item final pode permanecer na fila | Confirmar origem real e esperado do cenário 27 | Dev + PO |
| Média | SQL Server dos instaladores | Paridade entre bancos não demonstrada | Renovar gate e repetir cenários aplicáveis | QA |
| Média | Logs de inserção e ausência de identificação da instância | Mensagens não correspondem sempre a inserções; diagnóstico limitado | Alinhar log ao resultado e incluir identificação de execução | Dev |
| Média | Massa e restaurações | Resíduos e builds incompletos dificultam repetição | Inventariar massa e reconstruir worktrees necessários | QA |

As prioridades acima são uma proposta deste relatório, não severidades oficialmente atribuídas. Os achados de e-mail, timeout, logs e reenfileiramento não foram contados como novos defeitos formais.

## 6. Plano de fechamento e evidência esperada

1. Corrigir #166161 e executar #22 nos dois bancos, seguido da regressão #1, #2, #16, #17, #21 e #23. Evidência: tarefa desassociada, log e estado final consistentes, sem duplicidade.
2. Preparar build integrado dos instaladores e decidir a regra de consulta ao JOB_DUMP. Evidência: commit integrado identificado e cenários de chave ativa, envenenada, concluída e recorrente aprovados.
3. Disponibilizar conexão SQL válida, mecanismo de exceção no avanço e e-mail funcional. Evidência: caminho feliz, tratamento de erro alvo e recebimento real pelo destinatário correto.
4. Completar massas de observação, paralelismo e início temporal, além de repetir o escopo aplicável em SQL Server. Reavaliar os 11 inconclusivos e os dez itens não executados/fora sem transformar dispensa de escopo em aprovação.
5. Concluir a rodada em HMG da US 164251 e tratar os parciais restantes. Confirmar com dev/PO as hipóteses e o caso de data nula.
6. Resolver as divergências de revisão e publicar os artefatos faltantes somente conforme o fluxo de autorização do ciclo. Os mapas e relatórios dos instaladores permanecem locais nas fontes consultadas.

Não foram estimados prazo, esforço, custo evitado ou retorno financeiro: os registros não têm apontamentos de horas nem base suficiente para essas métricas.

## 7. Qualidade dos dados e limites da leitura

Os índices contêm pendências antigas e estados já superados. Exemplo: o índice geral ainda apresenta os instaladores bloqueados, embora as etapas 26 a 31 documentem execuções e complementos de 10/11. Também há restaurações que parecem pendentes em um relatório individual e estão concluídas no consolidado posterior. Para o painel, prevalece o fechamento mais recente e específico.

O relatório final de 160823 prevalece sobre observações intermediárias como “Oracle não repetido” no cenário 24. A classificação de ressalva não foi promovida a aprovação plena. O cenário 27 de 164251 continua Falhou no resultado de teste, mas não foi convertido em defeito formal.

Os logs podem conter vários bancos e janelas de tempo. Contar ERROR ou mensagens “inserido com sucesso” sem recorte não mede quantidade de defeitos ou jobs inseridos. Os valores operacionais aqui apresentados são os reconciliados pelos registros de execução; não foi realizada nova execução, nova consulta ao banco ou auditoria independente de cada evento dos logs.

Não há base para medir taxa de escape em produção, SLA, disponibilidade, desempenho sustentado, produtividade por hora, tempo médio de correção ou tendência estatística. Ensaios de 600 itens demonstram integridade naquele contexto e não capacidade máxima do produto.

## 8. Fontes e rastreabilidade

| Informação | Fonte principal |
|---|---|
| Fechamento SQL Server 164251 | [15-relatorio-execucao.md](../164259-US164251/15-relatorio-execucao.md) |
| Fechamento Oracle 164251 | [17-relatorio-execucao-oracle.md](../164259-US164251/17-relatorio-execucao-oracle.md) |
| Concorrência SQL Server, 600 itens | [07-execucao-testes.md](../164259-US164251/07-execucao-testes.md) |
| Veredito sobre data nula | [14-analise-falha.md](../164259-US164251/14-analise-falha.md) |
| Fechamento 160823 por banco | [relatorio-final-161495-US160823.md](../161495-US160823/relatorio-final-161495-US160823.md) |
| Evolução e retestes 160823 | [04-execucao-testes.md](../161495-US160823/04-execucao-testes.md) |
| Defeito formalizado | [06-defeito-166161.md](../161495-US160823/06-defeito-166161.md) |
| Instaladores, resultados atualizados | [31-execucao-testes-oracle-consolidado.md](../161711-US161711/31-execucao-testes-oracle-consolidado.md) |
| ExecutaWs | [26-execucao-testes-161716-oracle.md](../161711-US161711/26-execucao-testes-161716-oracle.md) |
| ExecutaSql e backoff | [27-execucao-testes-161713-oracle.md](../161711-US161711/27-execucao-testes-161713-oracle.md) |
| Scheduler, timezone e alertas | [28-execucao-testes-161712-oracle.md](../161711-US161711/28-execucao-testes-161712-oracle.md) |
| AvancoTemporal | [29-execucao-testes-161714-oracle.md](../161711-US161711/29-execucao-testes-161714-oracle.md) |
| Destinatários de observação | [30-execucao-testes-161839-oracle.md](../161711-US161711/30-execucao-testes-161839-oracle.md) |

O inventário anexo relaciona todos os arquivos das três pastas, incluindo etapas de negócio, análise técnica, mapas, execuções, validações de ambiente, relatórios, scripts e evidências. Contém tamanho e SHA-256 para identificar a versão documental utilizada. Não foram alterados os registros originais.
'''
report+='\n### Inventário por ciclo\n\n| Ciclo | Arquivos | Registros Markdown | Volume em bytes |\n|---|---:|---:|---:|\n'
for c in cycles:
    a=[x for x in inventory if x['ciclo']==c]
    report+=f"| {c} | {len(a)} | {sum(x['extensao']=='.md' for x in a)} | {sum(x['bytes'] for x in a):,} |\n"
(out/'relatorio-consolidado.md').write_text(report,encoding='utf-8')
def inline(s):
    s=html.escape(s)
    s=re.sub(r'\[([^\]]+)\]\(([^)]+)\)',r'<a href="\2">\1</a>',s)
    return re.sub(r'\*\*(.*?)\*\*',r'<strong>\1</strong>',s)
parts=[]; table=False; listing=False
for line in report.splitlines():
    if not line.startswith('|') and table: parts.append('</tbody></table></div>');table=False
    if not re.match(r'^\d+\. ',line) and listing:parts.append('</ol>');listing=False
    if line.startswith('|'):
        cells=[x.strip() for x in line.strip('|').split('|')]
        if all(re.fullmatch(r':?-+:?',x) for x in cells):continue
        tag='td' if table else 'th'
        if not table:parts.append('<div class="table"><table><tbody>');table=True
        parts.append('<tr>'+''.join(f'<{tag}>{inline(x)}</{tag}>' for x in cells)+'</tr>')
    elif line.startswith('#'):
        n=len(line)-len(line.lstrip('#'));parts.append(f'<h{n}>{inline(line[n:].strip())}</h{n}>')
    elif re.match(r'^\d+\. ',line):
        if not listing:parts.append('<ol>');listing=True
        parts.append('<li>'+inline(re.sub(r'^\d+\. ','',line))+'</li>')
    elif line.strip():parts.append('<p>'+inline(line)+'</p>')
css='''body{margin:0;background:#edf2f7;color:#17283d;font:16px/1.65 "Segoe UI",Arial,sans-serif}main{max-width:1160px;margin:40px auto;background:white;padding:64px;box-shadow:0 8px 36px #18334d18}h1{font-size:40px;line-height:1.15;color:#102b49;border-top:9px solid #00a68b;padding-top:26px}h2{margin-top:48px;padding-bottom:10px;border-bottom:2px solid #00a68b;color:#10375a}h3{margin-top:32px;color:#12576c}strong{color:#10375a}.table{overflow-x:auto;margin:22px 0}table{width:100%;border-collapse:collapse;font-size:14px;line-height:1.5}th{background:#123651;color:white;text-align:left}td,th{padding:11px 13px;border:1px solid #d9e2ec;vertical-align:top}tr:nth-child(even){background:#f1f6f9}a{color:#087b89}li{margin:14px 0}footer{margin-top:50px;color:#66788a;font-size:12px}@media print{body{background:white;font-size:10pt}main{margin:0;padding:0;box-shadow:none;max-width:none}h1{font-size:26pt}h2{font-size:17pt;break-after:avoid}h3{break-after:avoid}tr{break-inside:avoid}table{font-size:8pt}.table{overflow:visible}a{color:inherit;text-decoration:none}p{orphans:3;widows:3}@page{size:A4 landscape;margin:16mm}}'''
(out/'relatorio-apresentacao.html').write_text('<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Relatório consolidado de QA — 10/11/2026</title><style>'+css+'</style><main>'+''.join(parts)+'<footer>Base documental local • 26/10 a 10/11/2026 • Indicadores com rastreabilidade nos anexos</footer></main></html>',encoding='utf-8')
assert [sum(r[i] for r in rows) for i in range(2,8)]==[86,37,4,11,19,4]
assert sum(sum(r[2:]) for r in rows)==161
print(json.dumps({'arquivos_inventariados':len(inventory),'markdown':sum(x['extensao']=='.md' for x in inventory),'totais':[86,37,4,11,19,4],'entregas':[p.name for p in out.iterdir()]},ensure_ascii=False))
