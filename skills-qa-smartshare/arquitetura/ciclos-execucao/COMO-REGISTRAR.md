# Como registrar uma etapa no ciclo de execução

Procedimento comum a todas as skills de QA (Arquitetura). Cada skill chama este procedimento no seu último step, depois de entregar o relatório ao usuário. Gravar aqui é escrita **local** (não toca o Azure DevOps), então vale também para as skills somente leitura (`/analise-negocio`, `/analise-tecnica`, `/analise-falha`).

## Caminhos

- Raiz dos ciclos: `D:\Skills QA - Share\skill-QA\skills-qa-smartshare\arquitetura\ciclos-execucao`
- Índice: `<raiz>\README.md`
- Log de ações (só escrita no Azure DevOps): `D:\Skills QA - Share\skill-QA\skills-qa-smartshare\arquitetura\log\LOG-ACOES.md`

## 1. Achar a pasta do ciclo

A pasta se chama `<id da task>-US<id da história>` (ex.: `164259-US164251`).

1. **Id da história:** o work item analisado pela skill (para `/gerar-defeito` e `/analise-falha`, a história à qual o defeito/falha pertence).
2. **Id da task:** o número entre colchetes da referência definida com `/task` nesta sessão (ex.: `[164259] - Testes do card de bugs 164251` → `164259`).
3. Procure em `<raiz>` uma pasta terminada em `-US<id da história>`:
   - **Uma pasta encontrada:** use-a.
   - **Nenhuma:** crie `<id da task>-US<id da história>`. Se a sessão não tiver referência de `/task`, **pergunte ao usuário o id da task** — não invente.
   - **Mais de uma:** pergunte ao usuário qual usar.

## 2. Gravar o arquivo da etapa

- Nome: `NN-<etapa>.md`, onde `NN` é o próximo número livre na pasta (01, 02, 03...), na ordem em que as etapas rodaram. Uma etapa repetida (ex.: reteste) ganha um número novo; nunca sobrescreva um arquivo de etapa anterior.
- `<etapa>` por skill:

  | Skill | `<etapa>` |
  |---|---|
  | `/analise-negocio` | `analise-negocio` |
  | `/analise-tecnica` | `analise-tecnica` |
  | `/gerar-mapa-testes-v3` | `mapa-testes` |
  | `/executar-teste` | `execucao-testes` (Modo B: `reteste-bug-<BUG_ID>`) |
  | `/analise-falha` | `analise-falha` |
  | `/gerar-defeito` | `defeito-<BUG_ID>` |
  | `/atualizar-documentacao` | `documentacao` |
  | `/priorizar-automacao` | `priorizacao-automacao` |
  | `/homologar-release` | `homologacao-release` |

- Conteúdo, nesta ordem:
  1. Título `# Etapa NN — <nome da etapa> — #<história> <título da história>`.
  2. Cabeçalho com: skill e argumentos, data (`Get-Date -Format "yyyy-MM-dd HH:mm"`), se escreveu no Azure DevOps (sim/não), quem aprovou (quando houve gate de aprovação), fontes lidas.
  3. O relatório final da skill, **completo**, como foi entregue ao usuário.
  4. Se houver: artefatos criados no Azure DevOps (id + link) e pendências.
- Nunca grave credencial, token, senha, connection string ou valor de `web.config` neste arquivo.

## 3. Atualizar o README do ciclo

Arquivo `<pasta do ciclo>\README.md`. Se não existir, crie com:

```markdown
# Ciclo de QA — Task <task> / US <história>

- **Task:** <referência completa do /task>
- **História:** [#<história>](https://dev.azure.com/selbettidev/<projeto>/_workitems/edit/<história>) — <título>
- **Projeto:** <projeto> | **Sprint:** <iteration> | **Tipo:** <tipo>
- **QA:** <usuário>

## Etapas

| # | Etapa | Data | Status | Escreveu no Azure DevOps? | Arquivo |
|---|---|---|---|---|---|

## Artefatos criados no Azure DevOps

| Artefato | Onde | Etapa |
|---|---|---|

## Pendências
```

Depois, via `Edit` (sem apagar linhas existentes):
- Acrescente a linha da etapa na tabela **Etapas** (status: `Concluída`, `Parcial — <motivo>` ou `Bloqueada — <motivo>`).
- Acrescente cada artefato criado no Azure DevOps na tabela **Artefatos**.
- Atualize a seção **Pendências**: remova as resolvidas por esta etapa e inclua as novas.

## 4. Atualizar o índice

Em `<raiz>\README.md`, na tabela **Ciclos**: atualize a coluna "Etapa atual" da linha do ciclo, ou acrescente uma linha se o ciclo for novo.

## 5. Falhas

Se não conseguir gravar (pasta sem permissão, disco indisponível), avise no chat e siga. O registro do ciclo nunca bloqueia nem desfaz a ação principal da skill.

## Formato da linha do log de ações

O `LOG-ACOES.md` tem 8 colunas:

```
| Data/hora | Skill | Ação | Alvo | Resultado | Aprovado por | Rodada | Observações |
```

`Rodada` só tem valor em `/executar-teste` (`1 (funcional, HOM)`) e `/homologar-release` (`2 (homologação oficial, HOM)`); nas outras skills use `—`.
