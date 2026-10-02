# skill-QA

Skill de QA para o produto **SmartShare** (Claude Skills).

## Estrutura

```
smartshare-qa/
├── SKILL.md                    ← orquestrador: papel, fluxo, padrões, níveis de confiança, guardrails
├── evals/evals.json            ← cenários para testar a skill
└── references/
    ├── processo/               ← como o QA trabalha (9 etapas)
    ├── product-knowledge/      ← o que o produto faz (saída da mineração do código, 00 a 14)
    └── complementar/           ← o que o código não revela (fluxos críticos, defeitos, ambientes)
```

## Como atualizar a base de conhecimento
Copie a saída da mineração do código para `smartshare-qa/references/product-knowledge/`, mantendo os nomes dos arquivos.
Não é necessário alterar o `SKILL.md`.

## Instalação
Compacte a pasta `smartshare-qa/` (ou use o arquivo `.skill`) e faça o upload em Claude → Configurações → Skills.
