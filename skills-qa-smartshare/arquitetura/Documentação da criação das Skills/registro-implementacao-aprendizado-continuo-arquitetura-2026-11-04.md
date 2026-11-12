# Registro da implementação de aprendizado contínuo — Arquitetura do Share

## Identificação

| Campo | Valor |
|---|---|
| Data | 2026-11-04 |
| Escopo | Base local de aprendizados reutilizáveis entre ciclos e skills |
| Execução | Direta pelas skills, sem dependência de orquestrador |
| Status | Implementado |

## Objetivo

Criar uma base persistente, incremental e rastreável para que as skills consultem conhecimentos relevantes antes das atividades e avaliem novos aprendizados ao final de cada etapa.

## Arquivos criados

- `aprendizados/README.md` — finalidade, princípios e estados de confiabilidade.
- `aprendizados/COMO-USAR.md` — inicialização, consulta, registro, deduplicação, contradição e regras de segurança.
- `aprendizados/INDICE.md` — catálogo compacto das entradas.
- `aprendizados/entradas/README.md` — convenção dos arquivos individuais de aprendizado.
- `Documentação da criação das Skills/registro-implementacao-aprendizado-continuo-arquitetura-2026-11-04.md` — este registro.

Nenhum aprendizado factual foi criado nesta implementação; a pasta começa sem entradas para evitar registrar conhecimento sem evidência de um ciclo real.

## Skills modificadas

- `arquitetura-analise-negocio.md`
  - Consulta aprendizados antes da análise.
  - Permite registrar regras ou descobertas reutilizáveis, mantendo ambiguidades como hipóteses.
- `arquitetura-analise-tecnica.md`
  - Consulta conhecimentos relacionados ao componente.
  - Restringe novos aprendizados a evidências de card, PR, código ou ciclo.
- `arquitetura-gerar-mapa-testes.md`
  - Consulta riscos, componentes e defeitos recorrentes.
  - Inclui a avaliação de aprendizados antes do registro do mapa.
- `arquitetura-executar-teste.md`
  - Consulta aprendizados por história, cenário, componente e ambiente.
  - Exige revalidação de informações de ambiente, massa e configuração.
- `arquitetura-analise-falha.md`
  - Consulta o contexto histórico da falha.
  - Não permite promover hipóteses a fatos.
- `arquitetura-gerar-defeito.md`
  - Consulta contexto histórico, mas impede usar aprendizados para preencher evidências ausentes do defeito atual.

## Documentação operacional modificada

- `README.md`
  - Documenta a base `aprendizados/`.
  - Inclui a consulta no fluxo e no checklist de instalação.
  - Atualiza a descrição do conjunto ativo de skills.
- `ciclos-execucao/COMO-REGISTRAR.md`
  - Adiciona a tabela de aprendizados consultados ou registrados ao README de cada ciclo.
  - Torna `aprendizados/COMO-USAR.md` parte do procedimento comum.

## Regras implementadas

- A estrutura é criada somente se estiver ausente.
- Arquivo ocupando o lugar de uma pasta é tratado como conflito; nada é removido ou sobrescrito.
- Entradas usam Markdown com frontmatter e ID `QA-KB-YYYYMMDD-NNN`.
- O índice é consultado antes das entradas completas.
- Somente aprendizados `validado` influenciam decisões sem ressalva.
- Hipóteses, observações e conhecimentos contraditos permanecem identificados.
- Contradições preservam o histórico e não substituem silenciosamente a entrada anterior.
- Relatórios de ciclo continuam sendo a evidência primária.
- Segredos, tokens, credenciais e dados pessoais desnecessários são proibidos.

## Validação realizada

- Confirmada a criação de `aprendizados/entradas/`.
- Confirmada a integração da diretriz nas seis skills ativas.
- Confirmada a atualização do README do projeto e do procedimento de registro de ciclos.
- Confirmado que nenhum arquivo de aprendizado factual foi inventado.
- Confirmado que a implementação não depende de um orquestrador externo.
