# Como consultar e registrar aprendizados

Procedimento compartilhado pelas skills de Arquitetura. Ele funciona durante a execução direta das skills, sem depender de um orquestrador externo.

## 1. Inicializar a estrutura

Antes de iniciar a atividade, confirme que existem:

```text
./aprendizados/
./aprendizados/entradas/
```

Se uma pasta estiver ausente, crie somente a pasta faltante. Se existir um arquivo com o mesmo nome, trate como conflito e informe o problema; não exclua nem substitua o arquivo.

Exemplo PowerShell seguro:

```powershell
$learningRoot = Join-Path (Get-Location) "aprendizados"
$learningEntries = Join-Path $learningRoot "entradas"

foreach ($path in @($learningRoot, $learningEntries)) {
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        throw "Conflito: existe um arquivo onde deveria existir uma pasta: $path"
    }

    if (-not (Test-Path -LiteralPath $path -PathType Container)) {
        New-Item -ItemType Directory -LiteralPath $path -ErrorAction Stop | Out-Null
    }
}
```

Se a criação falhar por permissão ou indisponibilidade do disco, informe a limitação e continue a atividade principal sem fingir que o aprendizado foi consultado ou salvo.

## 2. Consultar antes da execução

1. Identifique o contexto atual: história/Bug, produto, módulo, componente, ambiente, tipo de execução, tags e modo.
2. Leia primeiro `./aprendizados/INDICE.md`.
3. Filtre por domínio, componente, tags, skill, ambiente e validade.
4. Leia somente as entradas relacionadas na pasta `./aprendizados/entradas/`.
5. Considere diretamente apenas entradas `validado`.
6. Apresente entradas `candidato`, `em-revisao` ou de baixa confiança como ressalvas, nunca como fatos.
7. Revalide o aprendizado contra a história, PR, build, ambiente e evidências atuais.

Não carregue a base inteira e não use um aprendizado histórico para substituir uma verificação atual. Uma configuração ou massa existente em um ciclo anterior não prova que continua disponível.

Registre no relatório da etapa a seção:

```markdown
## Aprendizados consultados

| ID | Status | Relação com a atividade | Uso ou ressalva |
|---|---|---|---|
| QA-KB-... | validado | ... | ... |
```

Se nenhum aprendizado for aplicável, registre `Consulta realizada — nenhum aprendizado aplicável encontrado.`

## 3. Avaliar ao final do ciclo

Depois de concluir o relatório da etapa e antes de encerrar a skill, avalie se houve conhecimento reutilizável. Registre somente algo que:

- possa ajudar outra execução;
- tenha uma fonte real e rastreável;
- não seja apenas um detalhe descartável da sessão;
- não replique integralmente um relatório;
- não contenha segredo ou dado pessoal desnecessário.

Exemplos de tipos válidos:

```text
regra-negocio
comportamento-produto
particularidade-tecnica
problema-recorrente
estrategia-execucao
limitacao
dependencia
boa-pratica
```

Se a informação ainda não estiver confirmada, registre-a como `candidato` ou mantenha-a apenas no relatório do ciclo. Não promova uma hipótese diretamente para `validado`.

## 4. Criar ou atualizar uma entrada

Use um ID único no formato `QA-KB-YYYYMMDD-NNN`. Antes de criar, pesquise o índice e as entradas por título, componente e tags.

- **Duplicada:** não crie outra entrada; atualize a existente somente se houver evidência nova.
- **Complementar:** atualize a entrada existente e acrescente o evento no histórico.
- **Contraditória:** preserve a entrada antiga, marque-a como `contradito` ou `em-revisao` e crie uma nova entrada ligada por `relacionados`.
- **Específica de um ciclo:** mantenha no relatório do ciclo, sem promover para a base global.

Modelo mínimo:

```markdown
---
id: QA-KB-YYYYMMDD-NNN
tipo: regra-negocio
dominio: <produto ou módulo>
componente: <componente ou N/A>
status: candidato
natureza: fato | observacao | hipotese | decisao
confianca: alta | media | baixa
tags:
  - <tag>
skill_origem: arquitetura-<skill>
ciclo_origem: <task>-US<historia>
data_criacao: YYYY-MM-DD
ultima_validacao: YYYY-MM-DD
revisao_necessaria_em: YYYY-MM-DD ou N/A
relacionados: []
---

# <Título do aprendizado>

## Contexto

<onde e por que foi identificado>

## Aprendizado

<conclusão objetiva>

## Evidência e origem

- Ciclo: `ciclos-execucao/<ciclo>/...`
- Skill: `<skill>`
- Fonte adicional: <work item, PR, log, comentário ou N/A>

## Como reutilizar

<qual decisão, análise ou cenário pode ser influenciado>

## Limitações

<escopo, ambiente, versão ou condição que restringe o uso>

## Histórico

| Data | Evento | Fonte | Resumo |
|---|---|---|---|
| YYYY-MM-DD | Criação | <ciclo> | <resumo> |
```

Depois de criar ou atualizar a entrada, acrescente uma linha no `INDICE.md`. Nunca reescreva ou remova evidências do ciclo de origem.

## 5. Regras de segurança

- Aprendizados não substituem critérios de aceite, card de Análise, PR, evidência de execução ou confirmação humana.
- `arquitetura-gerar-defeito` não pode usar um aprendizado para preencher esperado, obtido ou evidência ausentes.
- Um aprendizado sobre ambiente, massa, configuração ou credencial deve ser revalidado no ambiente atual.
- Não propague automaticamente uma conclusão contradita ou expirada.
- Se a base estiver indisponível, registre a limitação e siga as regras normais da skill.
