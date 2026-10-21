# BACKLOG_REFATORACAO

Oportunidades identificadas e **não implementadas**. Todas exigem aprovação do time de IA. Status inicial: identificada.

| ID | Skill/arquivo | Problema | Melhoria proposta | Benefício | Riscos | Prioridade | Aprovação | Status |
|---|---|---|---|---|---|---|---|---|
| REF-001 | todas | Skills são arquivos soltos `<skill>.md`; o Claude Code espera `<skill>/SKILL.md` | Reorganizar para `<skill>/SKILL.md` | Instalação direta em `.claude/skills` | Quebra caminhos e o comparativo | Média | Sim | Identificada |
| REF-002 | `priorizar-automacao`, `homologar-release` | Caminho do projeto de automação ainda sem valor (removido o caminho pessoal em `priorizar-automacao`; resta só o nome da pasta) | Parametrizar via config, como `ambiente.projetoAutomacao` no pacote de referência | Portabilidade entre pessoas | Altera entradas da skill | Média | Sim | Identificada |
| REF-003 | `analise-tecnica` e outras | Decisões datadas embutidas no texto (atribuição pessoal já trocada por "decisão do time") | Mover decisões para registro de governança | Instruções mais estáveis | Perda de rastreabilidade histórica | Baixa | Sim | Identificada |
| REF-004 | `executar-teste` (44 KB) | Skill extensa, com risco de perda de contexto | Dividir em partes ou módulos referenciados | Manutenção | Mudança de comportamento (ver `analise-riscos-skills-extensas.md`) | Baixa | Sim | Identificada |
| REF-005 | `executar-teste`, `gerar-mapa-testes-v3` | Nomes de MCP Playwright/Azure DevOps divergem entre skills (`mcp__azure-devops__` vs `mcp__azure-devops_`) | Padronizar | Evita falha de chamada | Precisa validar o MCP instalado | Alta | Sim | Identificada |
| REF-006 | `.claude/skills/gerar-mapa-testes-v3` | Versão em uso tem conteúdo a mais que a origem (paridade com o legado, ~3,5 KB) | Decidir se incorpora ao destino | Alinhar versões | Escopo fora desta etapa | Média | Sim | Aguardando avaliação |
| REF-007 | `analise-tecnica`, `gerar-mapa-testes-v3`, `gerar-defeito`, `executar-teste` | Tipos e campos de work item do processo anterior (`Custom.Pontosdeimpacto`, `Custom.CasodeTeste`, "Criar Mapa de Teste", "Instruções QA", `ScrumBetti3.0`) embutidos no texto | Mover para config após levantar o processo Azure DevOps do SmartShare (`ADAPTACAO.md` §0 do pacote de referência) | Evita campos inexistentes | Depende de levantamento no Azure DevOps | Alta | Sim | Aguardando avaliação |
| REF-008 | todas | O pacote `AI-quality-cycle-smartshare` já usa skills configuráveis (`{ambiente.kbProduto}`, `{projetoPadrao}`) e `gerar-mapa-testes` em vez de `-v3` | Decidir se o destino converge para esse pacote | Evita duas bases divergentes | Mudança estrutural grande | Média | Sim | Aguardando avaliação |
