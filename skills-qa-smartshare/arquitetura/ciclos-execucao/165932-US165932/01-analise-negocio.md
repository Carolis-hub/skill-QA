# Etapa 01 — Análise de negócio — #165932 Novo Agent | Configuração | Acesso, estrutura e status geral

- **Skill:** `/arquitetura-analise-negocio` — argumento `#165932`
- **Data:** 2026-11-12 09:41
- **Escreveu no Azure DevOps:** não (somente leitura)
- **Aprovação:** não aplicável (sem gate de escrita)
- **Fontes lidas:** work item #165932 (rev 8, `expand=all`: descrição, critérios de aceite, relações). Comentários: `System.CommentCount = 0`, não consultados. Cards filhos (166455 Análise técnica, 166789) não usados, por regra da skill. Protótipo (link `claude.ai/artifact/...` na descrição) **não aberto** — lacuna declarada.

## Aprendizados consultados

Consulta realizada — nenhum aprendizado aplicável encontrado. (QA-KB-20261111-005, tela `job-config` do analytics, é outra tela; não aproveitada.)

# Análise de Negócio — #165932 Novo Agent | Configuração | Acesso, estrutura e status geral

**Projeto:** SmartShare Arquitetura | **Tipo:** Product Backlog Item | **Status:** Committed (coluna Desenvolvimento) | **Responsável:** Luis Fernando Bertucci | **Pai:** #151954 | **Série:** 1 de 8 (origem PBI 164649)

## Objetivo da alteração
Entregar a "casca" da nova tela de configuração do SmartShare Agent: item de menu em Configurações, controle de acesso, cabeçalho com badge de status e nome do servidor, abas Instalação / Controle do serviço / Logs com bloqueio, atualização automática de status, estados de carregamento e indisponibilidade, padrão de toast e auditoria das ações. Permite ao admin saber, sem entrar no servidor, se as rotinas estão rodando. (descrição: história, Problema, Objetivo)

## Comportamentos esperados (contratos verificáveis)
- Quando admin acessa Configurações, o sistema deve exibir "SmartShare Agent" e, ao clicar, abrir a tela na aba Instalação. (CA-01)
- Quando usuário não admin acessa Configurações, o sistema não deve exibir o item. (CA-02)
- Quando não admin acessa o endereço da tela diretamente, o sistema deve levá-lo a Configurações com o aviso "Acesso negado", sem exibir informação do Agent, e a API deve recusar o acesso. (CA-03)
- Quando o Agent não está instalado e o admin abre a tela, o sistema deve mostrar badge "Não instalado" e Controle/Logs desabilitadas com cadeado e a mensagem "Controle do serviço e Logs ficam disponíveis após a instalação." (CA-04)
- Quando o Agent está instalado, o sistema deve habilitar as 3 abas e mostrar o nome do servidor no cabeçalho. (CA-05)
- Quando o Agent está instalado com 3, 0 ou 1–2 serviços em execução, o badge deve mostrar texto e cor correspondentes ("Em execução · 3 de 3 serviços" sucesso; "Instalado · 0 de 3 serviços em execução" neutro; "Parcialmente em execução · N de 3 serviços" atenção). (CA-06, regras de negócio)
- Quando alguém para um serviço direto no Windows com a tela aberta e 3 serviços rodando, o badge deve virar "Parcialmente em execução · 2 de 3 serviços" na consulta seguinte (30 s, podendo levar um pouco mais pela rede), sem recarregar. (CA-07)
- Quando a tela perde comunicação com o servidor, o sistema deve mostrar badge "Servidor indisponível", mensagem abaixo das abas, manter o admin na aba atual e bloquear só as ações que alteram o servidor. (CA-08)
- Quando a comunicação volta, o sistema deve mostrar o status real sem recarregar. (CA-09)
- Quando o admin está na aba Logs e o Agent é desinstalado por fora, o sistema deve voltar para Instalação, com abas bloqueadas e "Não instalado". (CA-10)
- Quando uma ação auditada termina (sucesso ou falha), deve existir registro com usuário, data/hora, ação, instalação e resultado, sem senha. (CA-11)
- Quando o admin acabou de abrir a tela e a primeira resposta não chegou, o sistema deve mostrar "Verificando status..." (neutro, com carregamento) e Controle/Logs desabilitadas sem cadeado. (CA-12)
- Quando outro admin inicia a desinstalação, o admin em Controle ou Logs deve voltar para Instalação, com badge "Desinstalando..." e Controle/Logs desabilitadas sem cadeado. (CA-13)
- Quando uma ação gera mensagem, o toast deve aparecer no rodapé, com tipo e botão fechar, e sumir após 5 s. (CA-14)

## Regras explícitas
- Acesso só para administrador; demais perfis não veem o item; API recusa o acesso. (descrição)
- Uma instalação por ambiente, sempre no servidor da aplicação SmartShare; usuário não escolhe; nome do servidor só informativo. (descrição)
- Badge, primeira regra verdadeira, nesta ordem: Verificando status... → Servidor indisponível → Desinstalando... → Instalando... → Não instalado → Instalação incompleta (erro, serviço removido por fora) → Atualizando serviços... → Em execução 3 de 3 → Instalado 0 de 3 → Parcialmente em execução N de 3. (descrição)
- Abas sem instalação: Controle e Logs com cadeado e mensagem. Em Verificando status... e Desinstalando...: desabilitadas sem cadeado. Desinstalando...: todo admin com a tela aberta volta para Instalação (o protótipo divergia: abas continuavam habilitadas). (descrição)
- Instalação deixa de existir com admin em outra aba: volta para Instalação. (descrição)
- Status consultado a cada 30 s; mudança direta no Windows aparece na consulta seguinte. (descrição)
- Servidor indisponível: serviços "Desconhecido"; mensagem "Não foi possível comunicar com o servidor. Tente novamente em instantes." abaixo das abas; recupera sozinho. (descrição)
- Toast: rodapé, por tipo (sucesso/atenção/erro), botão fechar, some em 5 s. (descrição)
- Ações auditadas: Instalar serviços, Desinstalar serviços, Iniciar serviço, Parar serviço, Alterar retenção de logs. Campos: quem, quando, ação, instalação, resultado. Alterar credenciais **não** é auditado; senha nunca registrada. (descrição)
- Fora do escopo: conteúdo das abas, lista de serviços, mais de uma instalação por ambiente, tela de consulta da auditoria, tela própria de acesso negado. (descrição)
- Cenários críticos (falha bloqueia a entrega): CV-01 (CA-02, CA-03), CV-02 (CA-06, CA-07), CV-03 (CA-08, CA-09), CV-04 (CA-04, CA-10, CA-13). (critérios de aceite)
- Performance: tela abre com status em até 3 s com o servidor já em funcionamento; primeira abertura após longo período sem uso pode levar mais. (descrição, Impactos)

## Regras implícitas
- IMPLÍCITA: a precedência do badge vale em qualquer combinação de estados. Ex.: durante a desinstalação com perda de comunicação, aparece "Servidor indisponível" (vem antes de "Desinstalando..."). Decorre da ordem "primeira regra verdadeira".
- IMPLÍCITA: instalação manual no servidor continua válida, então o QA pode obter os estados Instalado / Parcial / Em execução sem usar as telas das demais PBIs. Decorre de "o processo manual continuará permitido, a tela sempre reflete o estado real".
- IMPLÍCITA: "Instalando...", "Desinstalando..." e "Atualizando serviços..." são disparados por ações de outras PBIs da série (abas Instalação e Controle), não por esta. Decorre de o conteúdo das abas estar fora do escopo.
- IMPLÍCITA: a recusa de acesso vale por perfil, não por ocultação de menu; esconder o item sem recusar a rota/API não atende CA-03.
- IMPLÍCITA: ações que alteram o servidor (instalar, desinstalar, iniciar, parar, retenção) só existem nas outras abas; aqui o bloqueio de "Servidor indisponível" só é verificável onde essas ações já existirem (ver Dependências).
- IMPLÍCITA: a auditoria cobre também ação que falhou (CA-11: "sucesso ou falha"), e o registro não pode conter senha em nenhum campo.

## Condições e exceções
- Perfil: admin x não admin (menu, rota direta, API).
- Instalação: não instalada, instalada completa, incompleta (serviço removido por fora), em instalação, em desinstalação, em atualização.
- Contagem de serviços em execução: 3, 0, 1–2.
- Comunicação: primeira resposta pendente, indisponível, recuperada.
- Ator: mudança feita pelo mesmo admin, por outro admin na tela, ou direto no Windows.
- Aba atual do admin ao ocorrer mudança (Logs, Controle, Instalação).
- Primeira abertura após longo período sem uso do servidor (pode exceder 3 s).

## Dependências
- PBI pai #151954; origem da série PBI 164649 (série 1 de 8). (relações, descrição)
- #165935 (Resumo da instalação) e #165937 (Controle do serviço): necessários para conferir visualmente serviços "Desconhecido" (CA-08). (descrição, Observações para validação)
- Demais PBIs da série (conteúdo das abas, instalação, controle, retenção, credenciais): disparam estados "Instalando...", "Desinstalando...", "Atualizando serviços..." e as ações auditadas. Seus IDs não constam na história, exceto 165935 e 165937.
- Integração web ↔ servidor do cliente para obter status. (descrição, Impactos)
- Protótipo externo (link na descrição), com divergência já declarada em Desinstalando.
- Cards filhos #166455 (análise técnica, citada na descrição) e #166789: insumo da análise técnica, não usados aqui.

## Informações ausentes
- Informação não encontrada / necessita validação: texto e desenho dos estados "Verificando status...", "Servidor indisponível" (badge e mensagem), "Instalação incompleta" e do status de serviço "Desconhecido". A própria história diz que não estão no protótipo; os textos de "Verificando status..." e "Servidor indisponível" aparecem, o desenho (cores, ícone, posição) não.
- Informação não encontrada / necessita validação: critério exato de "Instalação incompleta" — quando falta 1 ou 2 dos 3 serviços (incompleta) versus os 3 (Não instalado). A história diz só "serviço removido por fora".
- Informação não encontrada / necessita validação: com "Servidor indisponível" na primeira abertura (instalação ainda desconhecida), quais abas ficam habilitadas e com ou sem cadeado. CA-08 trata do admin já dentro de uma aba.
- Informação não encontrada / necessita validação: tolerância numérica do "um pouco mais" de 30 s em CA-07 e CA-10 (limite para reprovar).
- Informação não encontrada / necessita validação: limite aceitável de "Verificando status..." e se os 3 s de abertura são critério de aceite (aparecem só em Impactos, sem CA).
- Informação não encontrada / necessita validação: tipo (sucesso/atenção/erro) do toast "Acesso negado" de CA-03.
- Informação não encontrada / necessita validação: IDs das demais PBIs da série que habilitam as ações auditadas e os estados "Instalando..." e "Atualizando serviços...".
- Informação não encontrada / necessita validação: como o QA confere o registro de auditoria (CA-11), já que a tela de consulta está fora do escopo. É decisão de negócio de aceite, mas a forma é resolvida na análise técnica.

## Ambiguidades
- "Servidor indisponível" (CA-08): perda de comunicação pode ser falha da web com o servidor do Agent, ou o Agent não responder. A história não distingue; ambos mostram o mesmo badge.
- "Admin" (CA-01/02): "perfil de administrador" pode ser um perfil específico do Share ou o papel de administrador do ambiente. A história usa os dois termos ("administrador", "perfil de administrador").
- CA-10 x "Instalação incompleta": o texto diz "Agent desinstalado por fora" e o resultado "Não instalado"; remoção parcial por fora leva a "Instalação incompleta". A fronteira entre os dois não está escrita.
- CA-13: "outro admin inicia a desinstalação" e a regra diz "todo admin com a tela aberta volta"; inclui ou não o admin que iniciou (que já está na aba Instalação). Interpretação provável: só afeta quem estava em outra aba.
- "Parcialmente em execução · N de 3": N pode ser 1 ou 2; não está dito o que muda se um serviço estiver em transição (iniciando/parando).
- Protótipo x texto: a descrição diz que no protótipo as abas ficavam habilitadas em "Desinstalando..."; vale o texto da história, mas o protótipo não foi revisado aqui.

## Riscos identificados
- Acesso: se a recusa existir só no menu e não na rota/API, usuário comum pode parar rotinas do ambiente inteiro (CV-01, risco crítico declarado).
- Status errado: badge que não reflete o estado real (cache, contagem, precedência) leva o admin a decidir com informação falsa (CV-02).
- Bloqueio incompleto em "Servidor indisponível": ação que altera o servidor liberada sem comunicação (CV-03).
- Abas liberadas sem instalação ou durante desinstalação (CV-04); divergência do protótipo pode reintroduzir o comportamento antigo.
- Estados sem desenho/texto (Verificando, Indisponível, Incompleta, Desconhecido): cada dev/QA interpreta de um jeito; aceite subjetivo.
- Auditoria: senha ou credencial registrada por engano, ou ação auditada sem registro (falha não registrada).
- Verificação dependente de outras PBIs (165935, 165937): CA-08 completo não é testável só com esta US; risco de aceitar parcial.
- Janela de 30 s + latência de rede: dificulta reprovar CA-07 sem tolerância numérica.
- Primeira abertura lenta (> 3 s) após longo período sem uso: percepção de falha se o aceite for tratado como absoluto.

## Prontidão para as próximas etapas

| Gate | Resultado | Motivo |
|---|---|---|
| Prontidão para análise técnica | **APTA** | 14 CAs, regras e cenários críticos escritos; análise técnica (#166455) já existe como card filho. |
| Prontidão para geração do mapa | **APTA COM RESSALVAS** | Estados sem desenho/texto, critério de "Instalação incompleta", comportamento do "Servidor indisponível" na primeira abertura e tolerância de 30 s sem resposta; tratar como hipótese ou lacuna no mapa, nunca como critério de aceite. |
| Prontidão para execução | **APTA COM RESSALVAS** | CA-08 (serviços "Desconhecido") depende de 165935 e 165937; "Instalando..." e "Atualizando serviços..." dependem de outras PBIs; ambiente com Agent instalável manualmente e usuário admin e não admin a confirmar na análise técnica. |

## Pendências desta etapa
- Fechar com PO/PBI owner as informações ausentes acima antes de promover qualquer cenário baseado nelas a critério de aceite.
- Abrir o protótipo se o mapa precisar de referência visual.
