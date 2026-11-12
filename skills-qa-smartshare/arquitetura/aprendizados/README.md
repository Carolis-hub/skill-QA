# Base de aprendizados do agente de QA

Esta pasta armazena conhecimentos reutilizáveis derivados dos ciclos de execução das skills de Arquitetura.

## Princípios

- Os relatórios em `../ciclos-execucao/` continuam sendo a evidência primária.
- Um aprendizado é uma síntese rastreável, não uma cópia de um relatório inteiro.
- Todo aprendizado precisa indicar origem, data, skill responsável, escopo e nível de confiança.
- Aprendizados `candidato` ou `hipotese` não podem ser tratados como fatos nem alterar sozinhos um resultado esperado.
- Contradições não apagam o registro anterior: criam histórico e exigem revisão explícita.
- Nunca registrar senha, token, PAT, connection string, dado pessoal desnecessário ou segredo de ambiente.

## Estrutura

```text
aprendizados/
├── README.md
├── COMO-USAR.md
├── INDICE.md
└── entradas/
    └── QA-KB-YYYYMMDD-NNN.md
```

O procedimento operacional compartilhado está em [COMO-USAR.md](COMO-USAR.md). O [INDICE.md](INDICE.md) deve permanecer compacto e conter apenas o catálogo das entradas.

## Estados

- `candidato`: observação ainda não confirmada;
- `validado`: confirmado por evidência suficiente e aplicável ao escopo informado;
- `em-revisao`: precisa ser revalidado por mudança de código, ambiente ou regra;
- `contradito`: existe evidência posterior conflitante;
- `obsoleto`: substituído por um aprendizado mais recente.

Somente `validado` pode orientar decisões sem ressalva. `em-revisao` pode ser considerado apenas como ponto de atenção, com revalidação no ciclo atual.
