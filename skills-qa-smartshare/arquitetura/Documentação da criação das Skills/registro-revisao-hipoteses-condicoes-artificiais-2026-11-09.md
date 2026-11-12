# Registro de revisão — Condições artificiais e hipóteses

**Data:** 2026-11-09
**Motivação:** evitar abertura de defeitos funcionais baseados exclusivamente em estados artificiais de banco sem origem comprovada no uso do produto.
**Aprovação:** rascunho apresentado e aplicação autorizada pelo usuário nesta conversa.

## Skills modificadas

- `arquitetura-gerar-mapa-testes.md`: classificar como `HIPOTESE:` condições criadas por escrita direta sem caminho suportado comprovado; registrar fonte para confirmação e reclassificação.
- `arquitetura-validar-ambiente.md`: registrar condição, origem/evidência e classificação no manifesto da massa; integridade ou existência do dado não confirma validade funcional.
- `arquitetura-executar-teste.md`: reavaliar preparação artificial descoberta na execução, interromper execução automática da hipótese e separar observação investigativa de falha funcional.
- `arquitetura-analise-falha.md`: emitir `NÃO — hipótese não confirmada` na ausência de origem comprovada ou exigência confirmada de tratamento, registrando fontes e pendências.
- `arquitetura-gerar-defeito.md`: bloquear proposta de Bug baseada exclusivamente nessa hipótese e preservar a confirmação nas pré-condições do rascunho.

## Critério adotado

A condição criada determina a classificação, não o uso de SQL isoladamente. Preparação equivalente a estado alcançável pela interface, API, integração, importação, job, scheduler ou migração continua válida quando houver comprovação no contexto da história. Confirmar a exigência de tratamento também permite reclassificação, com fonte registrada.

Autorizar massa ou execução investigativa não confirma regra de negócio nem substitui autorizações de escrita e gates existentes.

## Verificação

- Edição em lugar dos cinco arquivos centrais para preservar hard links.
- Conteúdo central comparado com os cinco `claude-skills/<skill>/SKILL.md` após a edição.
- Revisão textual das regras e de sua compatibilidade com o tratamento existente de `HIPOTESE:`.
- Nenhuma história, cenário ou Bug externo foi alterado; validação comportamental em uma história real permanece para o próximo uso do fluxo.
- Hard links dos cinco pares confirmados com fsutil.
- O validador quick_validate.py não pôde executar porque o Python disponível não possui o módulo yaml (PyYAML); nenhuma dependência foi instalada.
