# APR-013 — "Permissão de gerenciar índices" segue a regra do Clássico

- **Data:** 2026-11-05
- **Skill:** validar-ambiente
- **Escopo:** Geral (US de BE que não define a regra de permissão no net8)
- **Status:** Ativo

## Situação
O mapa exige "usuário com permissão de gerenciar índices" e "usuário sem permissão de gerenciar índices" (CA 95/96). No net8, `TipoIndiceController` só tem `[Authorize]` (qualquer usuário autenticado); a regra de permissão não está definida.

## Pergunta
Qual regra usar para definir quem tem e quem não tem a permissão?

## Resposta (usuária, 2026-11-05)
"Como não possui uma regra no novo, mantenha a antiga do SmartShare clássico."

## Como aplicar
- Regra do Clássico (lida no código): `SmartShareWeb/Old_App_Code/BasePageTG.cs:validaSessao` exige `user.cdTipoUsuario == 1` (administrador); caso contrário lança "0059". `Gerenciamento/TipoIndice.aspx.cs:Page_Load` usa o default.
- **Com permissão de gerenciar índices** = usuário tipo **Administrador**.
- **Sem permissão** = usuário de tipo **diferente de Administrador**. Perfil não define essa permissão.
- Se o dev/PO definir regra própria para o net8, este aprendizado é substituído.
