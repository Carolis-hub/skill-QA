# RELATORIO_DIFF

Gerado em 2026-10-14 com `git diff --no-index` e replay determinístico das alterações registradas; atualizado em 2026-10-20 (rodada 5) com `git diff --no-index` sobre o estado atual.

## Resumo

- Arquivos de skill: origem 9, destino 10.
- Adicionados: 1 (`validar-ambiente.md`, rodada 4) · Removidos: 0 · Renomeados: 0 · Modificados: 9 · Sem divergência: 0.
- Alterações estruturais: nenhuma nos arquivos existentes (mesmos nomes, caminhos e organização). Única adição: a skill `validar-ambiente.md`.
- Binários/renomeações: não há; o patch textual cobre todas as diferenças.

## Por arquivo

Linhas +/− medidas com `git diff --no-index --numstat` em 2026-10-20.

| Arquivo | Linhas +/− | Classificação |
|---|---|---|
| analise-falha.md | +1 / −1 | Alteração esperada (adaptação funcional) |
| analise-negocio.md | +112 / −7 | Alteração esperada (adaptação funcional + endurecimento de regra, rodadas 3 e 5) |
| analise-tecnica.md | +25 / −5 | Alteração esperada (adaptação funcional + validação das pendências do dev, rodadas 3 e 5) |
| atualizar-documentacao.md | +3 / −3 | Alteração esperada (adaptação funcional) |
| executar-teste.md | +25 / −38 | Alteração esperada (adaptação funcional + regras novas, rodadas 3 e 4) |
| gerar-defeito.md | +3 / −3 | Alteração esperada (adaptação funcional) |
| gerar-mapa-testes-v3.md | +59 / −20 | Alteração esperada (adaptação funcional + coluna `Pré-requisitos`, rodada 4) |
| homologar-release.md | +2 / −2 | Alteração esperada (adaptação funcional) |
| priorizar-automacao.md | +6 / −6 | Alteração esperada (adaptação funcional) |
| validar-ambiente.md | +235 / −0 | Arquivo adicionado (nova skill, rodada 4; ajustada nas rodadas 5 e 8) |

## Reconciliação com REGISTRO_ALTERACOES.md

- Registradas: 89 alterações (ALT-001…ALT-089), por rodada: 1 → 50, 2 → 13, 3 → 20, 4 → 3, 5 → 3.
- Rodadas 1 e 2 (ALT-001…ALT-063): o destino foi produzido exclusivamente pelas operações registradas (script de replay sobre a origem), sem edição manual. Resultado na época: **0 alterações não documentadas**. Limitação: o replay confirma que nada além do registrado foi aplicado, mas não prova que cada troca é semanticamente correta (revisão humana pendente).
- Rodadas 3 a 5 (ALT-064…ALT-089): edições feitas diretamente nas skills e registradas depois, sem replay. Reconciliadas em 2026-10-20 contra `diff-completo.patch`, que foi regenerado e confere com o estado atual das 10 skills (diff vazio):
  - **Rodada 3, ALT-064…ALT-083:** todas presentes no patch. ALT-064 a ALT-074 em `analise-negocio.md` (Step 3.5, item 10 do Step 3, Step 4.5, relatórios, Troubleshooting); ALT-075, ALT-076, ALT-079 e ALT-081 em `analise-tecnica.md` (Step 2.5 e seção de validação); ALT-077, ALT-078 e ALT-080 (persistência, Steps 4.5 e 5); ALT-082 e ALT-083 em `executar-teste.md` (prevalência da US sobre a KB e seção `Divergências da KB`).
  - **Rodada 4, ALT-084…ALT-086:** todas presentes. ALT-084 em `gerar-mapa-testes-v3.md` (Step 4.2b, 4.4, 4.5, 5, 7, Troubleshooting, item 11; larguras 3/11/16/20/20/7/9/7/7%; `colspan="9"`); ALT-085 em `executar-teste.md` (Step 2, 9 colunas e `colspan=9`); ALT-086 em `validar-ambiente.md` (arquivo adicionado; contém classificações ATENDIDO / NAO ATENDIDO / NAO VERIFICAVEL, EXECUTAVEL / PARCIAL / BLOQUEADO, gravação em `validacoes-ambiente` e linha em LOG-ACOES).
  - **Alterações sem ALT correspondente:** nenhuma de conteúdo nas 4 skills conferidas. Única omissão de descrição: em `executar-teste.md` (Step 2) a lista `$SCENARIOS` passou a incluir `pré-requisitos`, o que ALT-085 não cita explicitamente (faz parte da mesma mudança de colunas).
  - **Registros superados (o patch mostra só o estado final):** ALT-069 por ALT-074; ALT-073 por ALT-077 e ALT-080; ALT-075/076 por ALT-079, ALT-081 e ALT-088; ALT-077/078/080/081 por ALT-087…ALT-089 (caminhos).
  - Não conferi linha a linha as alterações das rodadas 1 e 2 nem se `analise-falha`, `atualizar-documentacao`, `gerar-defeito`, `homologar-release` e `priorizar-automacao` receberam edições além das registradas (nenhum ALT das rodadas 3 a 5 aponta para elas).
- Alterações suspeitas: nenhuma além das remoções intencionais abaixo.

### Remoções de conteúdo (revisar)

- `executar-teste.md`: seção CNAB/Cobrança Integrada removida e substituída por comentário HTML (skills `gerar-cnab240`/`gerar-cnab400`, `pix`, convênios e CNPJ deixam de existir); linha correspondente da tabela de triagem removida; frase sobre KB de Portaria removida.
- `executar-teste.md`: itens de Troubleshooting específicos de ExtJS/Cobrança removidos, com apontador para registrar peculiaridades do SmartShare; tempo de sessão de ~15 min removido.
- `executar-teste.md`: regra fixa "HMG, nunca DEV" e MCP `mysql-cobranca-hmg` removidos (decisão pendente do time SmartShare).

## Rodadas 3 a 5 (resumo)

- **Rodada 3 (2026-10-15, ALT-064…ALT-083):** endurecimento de regra em `analise-negocio` (gate de conclusão, Steps 3.5, 4.5 e 5, pontos de atenção do dev), validação das pendências do dev em `analise-tecnica` (Step 2.5) e regras novas em `executar-teste` (prevalência da US sobre a KB, seção `Divergências da KB`).
- **Rodada 4 (2026-10-20, ALT-084…ALT-086):** coluna `Pré-requisitos` em `gerar-mapa-testes-v3.md` (Step 4.2b, `colspan` 8→9), parser de 9 colunas em `executar-teste.md` e nova skill `validar-ambiente.md`.
- **Rodada 5 (2026-10-20, ALT-087…ALT-089):** diretório único de registro das execuções, `C:\skills-qualidade\ciclos-executados` (`$CICLOS_DIR`), em `analise-negocio.md`, `analise-tecnica.md` e `validar-ambiente.md`. Os caminhos deixam de ser relativos ao diretório de trabalho. O diretório `ciclos-executados` que ficava dentro de `skills-qa-smartshare` foi unificado com o da raiz (arquivos copiados e conferidos byte a byte).
- **Rodada 6 (2026-10-21, ALT-090…ALT-091):** validação opcional do código via hub em `analise-tecnica.md` (Step 2.7) e `gerar-mapa-testes-v3.md` (Step 3.7).
- **Rodada 7 (2026-10-21, ALT-092…ALT-093):** HTML interativo local do mapa (`gerar-mapa-testes-v3.md`, Step 5b) e novo `templates\mapa-teste-viewer.template.html`. **Não reconciliadas** com `diff-completo.patch` e `manifesto-arquivos.md` (não regenerados nas rodadas 6 e 7).
- A origem (`Skills-QA-Processo_2026-09-28`) **permanece imutável**: hash de `analise-negocio.md` conferido contra o manifesto de 2026-10-14 (`68bf9fc61bc0`). `diff-completo.patch` e `manifesto-arquivos.md` foram regenerados na rodada 5 e refletem o estado atual dos 10 arquivos.

## Pendências de revisão

- Regra de ambiente fixa e MCP de banco do SmartShare: decisão do time (EVD-005, EVD-006).
- Peculiaridades reais da UI do SmartShare (download, autocompletar, sessão): a registrar quando descobertas (EVD-007).
- Campos/tipos de work item herdados do processo do produto anterior (`Custom.Pontosdeimpacto`, `Custom.CasodeTeste`, tipo "Criar Mapa de Teste", "Instruções QA" etc.) **não foram alterados**: dependem do levantamento do processo Azure DevOps do SmartShare (ADAPTACAO.md §0). Ver backlog REF-007.
- IDs de US/Bug e datas históricas permanecem (mesma decisão do pacote de referência, "cosmético").
- Reconciliação das rodadas 3 e 4 com o patch: feita em 2026-10-20 (ver acima). Pendente apenas a conferência das rodadas 1 e 2 e das 5 skills sem ALT nas rodadas 3 a 5.

Comparação concluída para todos os arquivos de skill. As skills não foram executadas em ambiente real neste relatório.

## Reexecução

`git diff --no-index <origem>\<skill>.md <destino>\skills\<skill>.md` para cada skill (ou, para todas, `git diff --no-index --numstat <origem> <destino>\skills`); regenerar este relatório após novas alterações.
- **Rodada 8 (2026-10-21, ALT-094…ALT-095):** `validar-ambiente.md` cria usuários de teste ausentes e grava credenciais em `usuarios-teste.local.md` (Step 4.5); `executar-teste.md` Step 4.1 lê esse arquivo. Manifesto atualizado só para essas duas skills; patch regenerado.
