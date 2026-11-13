# Template ideal — User Story (PM) para suportar a análise de negócio de QA

Este template cobre o que a PM preenche na User Story do Azure DevOps (título, descrição,
critérios de aceite, vínculos e comentários), na ordem em que a skill `/analise-negocio` lê. A skill
não inventa regra: o que não estiver escrito na história vira "Informação não encontrada /
necessita validação", e uma remissão ao legado sem comportamento descrito **bloqueia** a análise.

Regra geral de preenchimento: um QA deve conseguir escrever o resultado esperado de cada teste
**só lendo a história**, sem consultar o sistema legado, o dev ou a PM.

---

## 1. Título (`System.Title`)

> Dizer o que é entregue e marcar a camada. A marcação define o escopo da análise: em US de
> back-end, tudo que é de tela fica fora da análise e dos testes.

- Formato: `<Módulo> — <o que é entregue> (BE | FE | BE+FE)`
  - Exemplo ruim: "Ajustes na exportação."
  - Exemplo bom: "Indicadores — Exportar resultado do cálculo em CSV (BE)"

## 2. Objetivo da alteração (descrição)

> O problema que a US resolve e para quem, em 1 a 3 frases. Não descrever a solução técnica.

- **Problema/necessidade:**
- **Quem é afetado** (perfil de usuário, cliente, área):
- **Resultado esperado para o negócio:**

## 3. Escopo

> O que não estiver listado em "Dentro" é tratado como dúvida, não como fora do escopo.

- **Dentro do escopo:**
- **Fora do escopo** (inclusive o que fica para outra US, com o ID dela):
- **Camada:** [ ] Back-end/API [ ] Front-end [ ] Ambos
  - Se a US é só de BE, não escrever critérios de tela, tooltip, rótulo, layout ou protótipo aqui:
    eles pertencem à US de FE.

## 4. Regras de negócio

> Uma regra por linha, com o valor exato (limite, texto de mensagem, formato, destino). Regra que
> só existe "na cabeça" ou em reunião não é considerada.

| # | Regra | Valor/mensagem exata | Vale para (perfil, status, tipo) |
|---|---|---|---|
| RN1 | ex.: Só o responsável pela tarefa pode reabrir o processo. | Mensagem: "Você não tem permissão para reabrir este processo." | Processos com status `Concluído` |

## 5. Condições e exceções

> Situações que mudam o comportamento padrão. Preencher cada linha ou escrever "Não se aplica".

| Dimensão | Como muda o comportamento |
|---|---|
| Perfil/permissão do usuário | |
| Status/estado do item | |
| Limites (tamanho, quantidade, datas) | |
| Campo vazio, nulo ou inválido | |
| Erro ou indisponibilidade (o que o usuário vê) | |

## 6. Comportamento legado

> É o ponto que mais bloqueia a análise. "Manter o legado", "igual ao Clássico", "como hoje" e
> "comparar com o legado antes de codar" **não são definição**. Para cada remissão ao legado,
> escolher uma das duas saídas abaixo.

**Saída A — descrever o comportamento** (regra, valor, mensagem, destino, formato, passo a passo):

- Exemplo ruim: "Mesma regra e mensagem do legado."
- Exemplo bom: "Mantém o legado: grava em `TB_LOG_INDICADOR`, no formato `dd/MM/yyyy HH:mm`, com
  a mensagem 'Cálculo concluído com sucesso'."

**Saída B — atribuir a verificação ao dev, de forma expressa** (vira ponto de atenção, não bloqueia):

- Exemplo: "O dev verifica no Clássico o nome do provider Oracle e registra o resultado no PBI."

| # | Comportamento legado citado | Saída (A ou B) | Descrição (A) ou quem verifica e onde registra (B) |
|---|---|---|---|
| 1 | | | |

- **Mudanças intencionais em relação ao legado** (o que deve ficar diferente, e por quê):

## 7. Critérios de aceite (`Microsoft.VSTS.Common.AcceptanceCriteria`)

> Um comportamento por critério, numerado, no formato "Quando X, o sistema deve Y". Cada critério
> vira pelo menos um cenário de teste. Sem critérios de aceite, a análise se baseia só na descrição
> e registra a ausência como lacuna.

- **CA 1:** Quando `<condição>`, o sistema deve `<comportamento verificável>`.
- **CA 2:** Quando `<condição de exceção/erro>`, o sistema deve `<comportamento>`, exibindo `<mensagem exata>`.

Cuidados:

- Evitar termos sem medida: "rápido", "adequado", "amigável", "quando necessário". Informar o
  número, o texto ou a condição.
- Cobrir também o caminho negativo (sem permissão, dado inválido, item inexistente).
- Critério de performance precisa do tempo máximo e do volume de dados.
- Não misturar duas regras no mesmo critério.

## 8. Dependências

> Vincular no work item (Related/Predecessor), além de citar aqui.

| Tipo | Item | O que esta US precisa dele |
|---|---|---|
| Outra US | ex.: #163659 | |
| Sistema/integração externa | | |
| Dado/configuração de cliente | | |

## 9. Pendências a confirmar antes do desenvolvimento

> Toda pendência precisa de responsável. Sem responsável, a skill a trata como pendência de
> negócio. Se não houver nenhuma, escrever literalmente **"Nenhuma pendência"**: a skill entende
> que não há nada a validar. Não deixar o campo em branco.

| # | Pendência | Responsável (PM / PO / dev / QA) | CA que depende | Prazo |
|---|---|---|---|---|
| 1 | | | | |

- Pendência do dev: usar a forma "O dev verifica/valida `<o quê>` e registra o resultado no PBI".
- Pendência da PM/PO: ao ser respondida, atualizar a descrição ou o CA e registrar nos comentários
  da US.

## 10. Comentários (Discussion)

> Decisão tomada em reunião, mudança de escopo ou resposta a dúvida de QA/dev deve ficar
> registrada aqui, com data. Comentário contestado ou vago não é tratado como regra: se a decisão
> muda uma regra, atualizar também a descrição ou o critério de aceite.

---

## Checklist rápido antes de liberar a US para o time

- [ ] Título diz o que é entregue e a camada (BE, FE ou BE+FE)
- [ ] Objetivo descreve o problema, não a solução técnica
- [ ] Escopo com "dentro" e "fora" preenchidos
- [ ] Regras com valores e mensagens exatos
- [ ] Condições e exceções preenchidas (ou "Não se aplica")
- [ ] Nenhuma remissão ao legado sem descrição do comportamento ou atribuição expressa ao dev
- [ ] Critérios de aceite numerados, no formato "Quando X, o sistema deve Y", com caminho negativo
- [ ] US só de BE sem critérios de tela
- [ ] Dependências vinculadas no work item
- [ ] Pendências com responsável, ou "Nenhuma pendência" escrito no campo
- [ ] Decisões de reunião registradas nos comentários e refletidas na descrição/CA
