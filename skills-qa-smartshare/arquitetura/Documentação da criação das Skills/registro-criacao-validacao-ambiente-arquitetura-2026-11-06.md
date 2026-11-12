# Registro de criação — arquitetura-validar-ambiente

**Data:** 2026-11-06
**Skill:** `/arquitetura-validar-ambiente`
**Motivação:** criar um gate anterior à execução dos testes para confirmar ambiente, conectividade e massas em Oracle e SQL Server, evitando iniciar uma rodada com pré-condições ausentes ou não comprovadas.

## Artefatos criados

- `arquitetura-validar-ambiente.md`: definição central da skill.
- `claude-skills/arquitetura-validar-ambiente/SKILL.md`: hard link da definição central para carregamento pelo Claude Code.

## Artefatos ajustados

- `arquitetura-executar-teste.md`: gate obrigatório que exige relatório vigente com status `LIBERADO PARA EXECUÇÃO` antes de login, navegação ou execução de qualquer cenário.
- `README.md`: fluxo recomendado, catálogo de skills, ordem de uso e checklist de instalação.

## Decisões de fluxo

1. A rodada inteira fica bloqueada se faltar a massa de qualquer cenário aplicável; não há liberação parcial por cenário.
2. Leituras e metadados de banco são permitidos em ambiente não produtivo; `INSERT`/`UPDATE`/`DELETE` exigem autorização explícita, com escopo, verificação e rollback.
3. Atualização em 2026-11-09: MCP de banco deixou de ser pré-requisito absoluto. A skill tenta `MCP`, depois `ADAPTER_LOCAL` (cliente/driver/script oficial já existente) e, por fim, gera `EVIDENCIA_MANUAL` com SQL read-only. A ausência isolada de MCP não bloqueia; a falta de qualquer método verificável continua bloqueando.
4. O bootstrap de primeira execução grava somente configuração local não sensível e não altera o MCP global, instala driver ou grava credenciais.
5. O relatório `ciclos-execucao/<task>-US<story>/00-validacao-ambiente.md` guarda a matriz de massas, o manifest de dados criados, o método de acesso e a assinatura de contexto usada pelo executor.

## Referências consultadas

- `SKILL.md` da skill `skill-creator`.
- `README.md` da pasta de Arquitetura.
- `arquitetura-executar-teste.md`.
- `arquitetura-gerar-mapa-testes.md`.
- `arquitetura-analise-tecnica.md`.
- `Variveis de Ambiente/variaveis-de-ambiente-smartshare.md` — somente para entender nomes e a necessidade de não registrar credenciais na nova skill.

