# migracao — skills QA centralizadas

Esta pasta é a **raiz do ambiente local** `C:\skills-qualidade`: o conteúdo daqui corresponde, subpasta a subpasta, ao que fica em `C:\skills-qualidade`. Por isso os caminhos que as skills usam (`C:\skills-qualidade\skills-qa-smartshare\skills-qa-smartshare\templates`, `...\ciclos-executados`, `...\analises-diversas`, `...\pendencias-skills`) continuam válidos, sem mudar nenhuma skill.

| Pasta aqui | Caminho local |
|---|---|
| `skills-qa-smartshare/skills-qa-smartshare/` (skills, templates, `REGISTRO_ALTERACOES.md`) | `C:\skills-qualidade\skills-qa-smartshare\skills-qa-smartshare\` |
| `ciclos-executados/` | `C:\skills-qualidade\ciclos-executados\` |
| `analises-diversas/` (aprendizados) | `C:\skills-qualidade\analises-diversas\` |
| `pendencias-skills/` | `C:\skills-qualidade\pendencias-skills\` |
| `Skills-QA-Processo_2026-09-28-cintia/` (9 skills de 28/09/2026, histórico), `corrigir-oracle-dual-client.ps1` | `C:\skills-qualidade\` (mesmos nomes) |
| `ciclos-executados/relatorios/` (relatórios consolidados) | `C:\skills-qualidade\ciclos-executados\relatorios\` |

Fora do repositório, só no local: `C:\skills-qualidade\config\ambiente-teste.local.md` e `usuarios-teste.local.md` (credenciais, ignorados pelo `.gitignore`). Esta reorganização não toca neles.

Origem: até 09/11/2026 este conteúdo ficava em `skills-qualidade-2026-10-21/` (movido sem alterar nenhum arquivo). As 9 skills antigas desta pasta (02/10/2026) estão em `legado/migracao-2026-10-02/`.

Organização de duplicidades (09/11/2026): relatórios soltos de `ciclos-executados` reunidos em `ciclos-executados/relatorios/`; `Skills-QA-Processo_2026-09-28` renomeada com o sufixo `-cintia` e sem o aninhamento duplo; o mapa da US 162365 (antes em `temp/anexo-162375`) agora está em `ciclos-executados/US-162365/mapas-teste/`. Pendente: a pasta `ciclos-executados/US - 157659/` ainda guarda 9 US aninhadas. As pastas `pendencias-dev`, `analises-negocio` e `recomendacoes-qa` dentro dos ciclos são histórico: as skills não as geram mais (hoje o arquivo único fica em `pendencias-skills/`).
