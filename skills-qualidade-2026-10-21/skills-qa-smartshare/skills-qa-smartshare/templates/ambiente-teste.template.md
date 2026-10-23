# Configuração do ambiente de teste — SmartShare

> Copie este arquivo para `C:\skills-qualidade\config\ambiente-teste.local.md` e preencha. Ele contém senhas: **nunca versionar** (fica fora do sync com o GitHub).
> Lido por `/validar-ambiente` (valida e configura o ambiente) e por `/executar-teste` (login). A skill só atua nas URLs listadas aqui como `teste`.

ambiente_padrao: HMG

## Ambientes

> A **URL base não é lida deste arquivo**: o `/validar-ambiente` pergunta a URL base a cada execução (ex.: `http://localhost:8080/smartshare/`). A tabela abaixo só identifica o ambiente e seu tipo.

| Ambiente | Tipo | Observação |
|---|---|---|
| HMG | teste | |

## Telas de configuração (caminhos relativos à URL base)

| Nome | Caminho relativo | Para que serve |
|---|---|---|
| Menu configurações | workspace/management/configuracoes | ponto de entrada das configurações |
| Usuário | workspace/management/configuracoes/usuario | criar usuário |
| Perfil | workspace/management/configuracoes/perfil | criar perfil (dependência do usuário) |
| Área | workspace/management/configuracoes/perfil | criar área (mesma tela do perfil; dependência do usuário) |
| Papel | workspace/management/configuracoes/papel | criar papel (dependência do usuário) |

## Administração (usada para configurar o ambiente)

| Ambiente | Login admin | Senha |
|---|---|---|
| HMG | <preencher> | <preencher> |

## Usuários de teste

> Preencha os que já existem. O `/validar-ambiente` acrescenta aqui os que criar (Origem = CRIADO).

| Login | Senha | Perfil/permissões | Ambiente | Origem | US | Criado em | Observação |
|---|---|---|---|---|---|---|---|
