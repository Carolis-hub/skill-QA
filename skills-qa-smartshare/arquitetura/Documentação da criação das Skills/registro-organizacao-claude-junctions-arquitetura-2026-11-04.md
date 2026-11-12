# Registro de organização das skills e junctions — 2026-11-04

## Objetivo

Centralizar as skills de QA arquitetural e os registros de execução em `arquitetura/`, mantendo o Claude Code no projeto SmartShare sem cópias locais divergentes.

## Fonte única

- Raiz: `D:\Skills QA - Share\skill-QA\skills-qa-smartshare\arquitetura\`
- Pacote compatível com Claude: `claude-skills/`
- Cada `claude-skills/<nome>/SKILL.md` é hard link para o arquivo `arquitetura-<nome>.md` na raiz.

## Skills mantidas

Foram mantidas somente estas seis skills, todas com o prefixo `arquitetura-`:

1. `arquitetura-analise-negocio`
2. `arquitetura-analise-tecnica`
3. `arquitetura-gerar-mapa-testes`
4. `arquitetura-executar-teste`
5. `arquitetura-analise-falha`
6. `arquitetura-gerar-defeito`

No `.claude/skills` do workspace SmartShare, as seis pastas acima foram recriadas como junctions para `arquitetura/claude-skills/`. A alteração evita que uma edição feita na fonte central precise ser replicada manualmente no projeto.

## Skills removidas do `.claude/skills`

Foram removidas as cópias físicas das skills que não fazem parte do conjunto ativo:

- `arquitetura-atualizar-documentacao`
- `arquitetura-homologar-release`
- `arquitetura-priorizar-automacao`
- todas as pastas `MELHORIA-*` existentes no diretório de skills, incluindo as variantes de análise, execução, mapa, defeito, homologação, documentação, automação e validação de ambiente.

Skills não relacionadas ao ciclo de QA arquitetural foram preservadas.

## Dados centralizados

Para manter a visualização dos artefatos pelo Claude, os diretórios de saída passaram a ser físicos no workspace `D:\SmartShare-HUB\smartshare-hub\`:

- `aprendizados`
- `ciclos-execucao`
- `log`

A pasta de arquitetura mantém junctions reversas para esses diretórios, preservando o acesso centralizado por:

- `arquitetura/aprendizados` → `D:\SmartShare-HUB\smartshare-hub\aprendizados`
- `arquitetura/ciclos-execucao` → `D:\SmartShare-HUB\smartshare-hub\ciclos-execucao`
- `arquitetura/log` → `D:\SmartShare-HUB\smartshare-hub\log`

Os arquivos foram copiados para uma área temporária, comparados por SHA-256, movidos para os diretórios físicos do workspace e novamente validados antes da criação das junctions reversas. Nenhum conteúdo foi perdido ou sobrescrito.

## Registro do Claude

O arquivo `.claude/skills/_registry.md` foi atualizado para:

- listar somente as seis skills ativas;
- remover o fluxo das três skills descontinuadas;
- documentar que as skills e os registros são disponibilizados por junctions a partir da pasta central.

## Validação realizada

- As seis junctions de skills foram criadas e apontam para `arquitetura/claude-skills/`.
- Os seis `SKILL.md` existem no pacote central.
- Os três diretórios de saída são físicos no workspace e acessíveis pela pasta `arquitetura/` por junctions reversas.
- O arquivo `ciclos-execucao/161495-US160823/04-execucao-testes.md` foi confirmado após a migração.
- As skills antigas e as pastas `MELHORIA-*` não permanecem no `.claude/skills`.
- A sequência registrada contém somente análise de negócio, análise técnica, mapa de testes, execução, análise de falha e geração de defeito.

## Operação recomendada

Executar o Claude a partir de `D:\SmartShare-HUB\smartshare-hub`, que é a raiz onde está o `.claude` principal. As skills continuam usando caminhos relativos para os registros, mas esses caminhos chegam à estrutura central por meio das junctions.

## Configuração de permissões adicionada

Após a criação das junctions, o Claude passou a solicitar confirmação para cada artefato porque os destinos reais ficam fora da raiz primária do projeto. Para resolver esse comportamento sem liberar o sistema inteiro, o arquivo `D:\SmartShare-HUB\smartshare-hub\.claude\settings.local.json` foi atualizado com:

- `permissions.defaultMode: "acceptEdits"`, para aceitar automaticamente edições e operações comuns de criação dentro dos diretórios autorizados;
- `permissions.additionalDirectories`, limitado a `claude-skills`, `aprendizados`, `ciclos-execucao` e `log` na pasta central.

A pasta `Variveis de Ambiente` não foi incluída na autorização automática para reduzir o risco de acesso ou alteração involuntária a dados sensíveis. Comandos externos, MCPs e operações fora desses diretórios continuam sujeitos às permissões normais.
