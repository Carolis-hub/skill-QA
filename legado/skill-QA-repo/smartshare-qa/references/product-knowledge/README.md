# Base de Conhecimento do Produto (product-knowledge)

Esta pasta recebe a saída da **mineração de conhecimento do código-fonte** do SmartShare.
Os nomes dos arquivos são idênticos aos da estrutura de mineração, para que o resultado possa ser copiado
diretamente para cá **sem alterar o SKILL.md**.

## Níveis de confiança (obrigatórios)
| Marcador | Significado | Como a skill usa |
|---|---|---|
| `[CONFIRMADO]` | Demonstrável por código, configuração, banco, teste ou documentação | Pode ser tratado como comportamento atual do sistema, citando a fonte |
| `[INFERIDO]` | Conclusão plausível por relacionamento entre componentes | Sempre apresentado como **Hipótese**, com pedido de validação |
| `[NÃO ENCONTRADO]` | Necessário, mas não comprovável | Vira pergunta de validação (ver `13-lacunas-conhecimento.md`) |

## Identificadores
- `RULE-XXX` — regras de negócio (`03-regras-negocio.md`)
- `Q-XXX` — lacunas/perguntas (`13-lacunas-conhecimento.md`)
- `RISK-XXX` — riscos de QA (`10-riscos-qa.md`)
- `FEAT-<MODULO>-XX` — funcionalidades (`02-funcionalidades.md` ou `funcionalidades/`)
- `DEP-XXX` — fichas de impacto (`09-dependencias-impactos.md`)

## Mapa de arquivos
| Arquivo | Conteúdo | Consultado principalmente em |
|---|---|---|
| 00-visao-geral.md | Resumo executivo do produto | Toda demanda (leitura inicial curta) |
| 01-arquitetura-produto.md | Aplicações, camadas, módulos, auth | Análise técnica, falha |
| 02-funcionalidades.md (+ `funcionalidades/`) | Catálogo por funcionalidade | Negócio, mapa de testes, documentação |
| 03-regras-negocio.md | Catálogo RULE-XXX | Negócio, mapa de testes, falha |
| 04-estados-workflows.md | Máquinas de estado | Mapa de testes (transição de estados) |
| 05-apis.md | Endpoints | Técnica, falha, automação (setup via API) |
| 06-banco-dados.md | Entidades, tabelas, flags, soft delete | Técnica, dados de teste |
| 07-permissoes-seguranca.md | Perfis, roles, claims, tenant | Toda análise (dimensão Permissões/Segurança) |
| 08-integracoes.md | Integrações, retry, timeout, filas | Técnica, falha, homologação |
| 09-dependencias-impactos.md | "Se este componente mudar..." | Técnica, regressão, homologação |
| 10-riscos-qa.md | Estrutura de risco do produto | Mapa de testes, homologação |
| 11-testes-existentes.md | Cobertura atual e lacunas | Mapa, regressão, automação |
| 12-glossario.md | Negócio ↔ código | Toda demanda |
| 13-lacunas-conhecimento.md | Perguntas Q-XXX | Toda análise (antes de criar hipóteses) |
| 14-indice-rastreabilidade.md | Funcionalidade → regras → componentes → APIs → banco → testes → riscos | Ponto de entrada para localizar tudo |

## Produtos grandes
Se o catálogo ficar extenso, divida em `funcionalidades/<modulo>.md` e mantenha `02-funcionalidades.md` apenas como índice.
Aplique a mesma lógica a `03-regras-negocio.md` (`regras/<modulo>.md`) se necessário.
