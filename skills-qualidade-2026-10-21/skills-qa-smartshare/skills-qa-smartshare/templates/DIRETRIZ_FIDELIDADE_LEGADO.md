# Diretriz compartilhada — Fidelidade à versão legada

> Fonte única, lida por **todas** as skills de QA do SmartShare (cada skill só aponta para este arquivo; não replique o texto nelas). Para mudar a regra, altere só aqui e registre em `REGISTRO_ALTERACOES.md`.

O SmartShare está em migração tecnológica. A **versão legada continua vigente** e é a principal referência para descobrir as regras de negócio e os comportamentos existentes. A implementação migrada deve preservar a fidelidade funcional ao legado.

## Precedência das fontes de regra

1. Requisito explícito da US (critério de aceite, regra escrita) e mudança intencional aprovada/documentada.
2. Decisão do dev registrada no card de Análise (APR-010) e decisão da PM/PO registrada.
3. **Comportamento do legado**, para tudo que a US não define.
4. Protótipo (Figma) para aparência, conforme as regras de fidelidade ao protótipo.

O legado revela o comportamento existente, mas **não substitui** requisito explícito da US. Mudança intencional e aprovada é respeitada e passa a ser o esperado.

## Diretrizes obrigatórias

1. **Legado como referência:** descobrir a regra existente no legado antes de concluir o que é "esperado" quando a US for omissa.
2. **Comparação de comportamentos:** sempre que aplicável, executar o mesmo cenário no legado e no migrado (quando houver ambiente legado acessível) e/ou ler o código do legado via hub (somente leitura, `SMARTSHARE_HUB` ou `C:\GIT\smartshare-hub`; nunca alterar o hub).
3. **Preservação de regras:** validações, permissões, fluxos, restrições e resultados são mantidos.
4. **Não presumir melhoria:** comportamento diferente do legado não é melhoria sem requisito ou decisão documentada.
5. **Investigar divergências:** divergência legado × migrado é investigada (intencional ou regressão?) antes de virar defeito ou ser aceita.
6. **Documentar exceções:** mudança funcional prevista é registrada com justificativa; o novo comportamento vira a referência.

## Como cada skill aplica

- Análises (`analise-negocio`, `analise-tecnica`): registrar o que o legado faz quando a US é omissa e sinalizar divergência; sem validar no legado, marcar "legado não consultado".
- `gerar-mapa-testes-v3`: Resultado Esperado omisso na US vem do legado e leva a marca "conforme legado"; cenários de regressão quando o comportamento legado deve ser preservado.
- `executar-teste` e `analise-falha`: antes de abrir Bug, confirmar o comportamento no legado (fluxo de análise do `executar-teste`, Step 4.2 item 9).
- `gerar-defeito`: o Bug informa o que o legado faz (ou "legado não consultado") e se há decisão documentada em contrário.
- `validar-ambiente`: ambiente do legado só entra como pré-requisito quando o mapa pedir comparação.
- `homologar-release`, `priorizar-automacao`, `atualizar-documentacao`: manter o comportamento legado como referência de regressão, automação e documentação.

## Critérios de conclusão de uma US

Só é "integralmente validada" quando: todos os cenários aplicáveis foram executados; todas as áreas técnicas impactadas (FE/BE/API) foram contempladas; todos os bancos exigidos receberam a execução completa; as divergências em relação ao legado foram analisadas; os defeitos passaram pela análise prévia; resultados e evidências estão registrados.
