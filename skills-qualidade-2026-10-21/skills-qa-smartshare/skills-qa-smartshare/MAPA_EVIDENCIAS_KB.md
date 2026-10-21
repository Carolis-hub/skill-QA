# MAPA_EVIDENCIAS_KB

KB: `C:\project personal\smartshare-kb\smartshare-kb\kb\` (caminhos abaixo relativos a `smartshare-kb\smartshare-kb\`). Extração de 2026-10-08.

A KB é a documentação de produto (docs.selbetti.com.br). Ela não descreve processo de QA (ambientes de teste, MCPs, credenciais). O pacote `C:\projetos selbetti\AI-quality-cycle-smartshare` (`ADAPTACAO.md`) foi usado como referência de decisão, isto é, de como a squad SmartShare tratou cada referência a Cobrança; ele é fonte de processo, não de comportamento do produto. Esta etapa trocou referências ao produto anterior por texto neutro; as únicas afirmações novas sobre o SmartShare estão em EVD-001 e EVD-002.

| ID | Skill | Regra ou afirmação | Fonte | Localização | Evidência encontrada | Alteração | Classificação | Observações |
|---|---|---|---|---|---|---|---|---|
| EVD-001 | executar-teste | A KB do SmartShare deve ser consultada antes de navegar pela UI; começar por `_index.md` e usar `grep` por termos | `CLAUDE.md` | Seção "Como consultar" | Orienta começar por `kb/_index.md` ou pelo `_index.md` do bloco, buscar com `grep -ril "<termo>" kb/` e não ler a base inteira | ALT-038, ALT-052 | Confirmada | É instrução de uso da KB, não regra de produto |
| EVD-002 | executar-teste | Existem duas instâncias/produtos a distinguir: SmartShare clássico e SmartShare 4 | `CLAUDE.md`; `kb/_index.md` | Seção "Estrutura"; blocos `kb/smartshare/` e `kb/smartshare-4/` | Descreve `smartshare/` como clássico (ECM/BPM, DI, Embarcados, Signer) e `smartshare-4/` como nova interface | ALT-044 | Confirmada | Não define como as instâncias de teste se chamam nem onde estão as credenciais; o caminho `smartshare-ambientes.md` é apenas exemplo e está marcado "a confirmar" |
| EVD-005 | executar-teste | SGBD do SmartShare: não é MySQL; `information_schema` deve ser tratado como "ou equivalente" | `kb/smartshare/smartshare-di-server/requisitos-de-instalacao/smartshare-di-server-banco-de-dados.md`; `kb/smartshare/signer-signer/integracao-certisign/requisitos-para-realizar-integracao.md` | Lista de versões (SQL Server 2012/2014/2016); linha 18 ("SQL Server 2012 e Oracle 19c ou superior") | Os requisitos desses componentes citam SQL Server e Oracle; 0 ocorrências de "mysql" em toda a `kb/` | ALT-034, ALT-043 | Parcial | Cobre DI Server e SmartSigner, não o ECM/BPM nem o SS4. Existência e nome de um MCP de banco read-only do SmartShare: não localizados |
| EVD-006 | executar-teste | Ambiente funcional é HMG, nunca DEV | — | — | 0 ocorrências de "HMG"; 7 arquivos com "homologa*", todos sobre outros assuntos (fluxo BPM, SO homologado, formulário) | ALT-032, ALT-051 | Não localizada | Regra fixa removida da skill; passa a valer o `$ambiente` genérico (default HMG). O pacote de referência (`ADAPTACAO.md` §2) registra a mesma decisão como pendente. **Pendente de validação** com o time/PO |
| EVD-007 | executar-teste | Quedas do MCP Playwright em telas ExtJS, autocompletar ExtJS e sessão de ~15 min | — | — | 0 ocorrências de "extjs"/"ext js" na KB | ALT-047, ALT-048, ALT-049, ALT-055, ALT-056, ALT-057 | Não localizada | Itens removidos, com apontador para registrar as peculiaridades reais do SmartShare, como no pacote de referência (`ADAPTACAO.md` §2). **Pendente de validação** |
| EVD-008 | gerar-defeito | Template de Bug exibe `ReproSteps` como campo principal | — | — | A KB não cobre Azure DevOps | ALT-015 | Pendente de validação | Verificar no projeto Azure DevOps do SmartShare |
| EVD-009 | priorizar-automacao | Existência de planilha de features do SmartShare | — | — | Não localizada; a planilha de Cobrança foi descartada | ALT-027 | Pendente de validação | Pedir caminho ao usuário |

## Resumo

- Confirmadas: EVD-001, EVD-002.
- Parcial: EVD-005.
- Não localizadas: EVD-006, EVD-007.
- Pendentes de validação humana: EVD-006, EVD-007, EVD-008, EVD-009.
- Conflitos entre fontes: nenhum identificado.
- Todas as demais trocas são neutralizações sem regra nova (justificativa: remover referência ao produto anterior). Não foi lida a KB inteira (1.089 arquivos); foram consultados `CLAUDE.md`, `README.md`, `_index.md` e buscas por termo.
- Observação de qualidade da KB: `_meta/relatorio_qualidade.md` não foi consultado nesta etapa.
