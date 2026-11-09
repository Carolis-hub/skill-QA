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

> O `/validar-ambiente` cria na primeira execução o admin de automação `Claude-adm` e anexa aqui (Origem = CRIADO). Enquanto não existir, a skill pede um admin de bootstrap no chat (não gravado).

| Ambiente | Login admin | Senha | Origem | Criado em |
|---|---|---|---|---|
| HMG | Claude-adm | <preencher> | A CRIAR | |

## Troca de banco (tela config/webconfig.aspx)

> Lido pelo `/validar-ambiente` (Step 0.3d) ao trocar o banco do ambiente. Contém senhas: nunca copiar para relatório, chat, log ou GitHub. Base de Dados fica em branco para Oracle (campo desabilitado).

| Banco | Provider | Servidor/Instância | Base de Dados | Usuário do banco | Senha do banco | Caminho virtual | Admin SmartShare | Senha admin |
|---|---|---|---|---|---|---|---|---|
| Oracle | System.Data.OracleClient | orcl | (em branco) | <preencher> | <preencher> | /smartshare/ | <preencher> | <preencher> |
| SQL Server | System.Data.SqlClient | <preencher> | <preencher> | <preencher> | <preencher> | /smartshare/ | <preencher> | <preencher> |

Código do net8 (conferência somente leitura após a troca): `C:\projetos_selbetti\smartshare-net8\src - Core\Project.Core.Apippsettings.json`. A API do net8 precisa ser reiniciada depois da troca.

## Valores originais (backup)

> O `/executar-teste` (Step 3.6) grava aqui o valor existente de todo campo que o teste vai alterar, e o devolve no Step 4.4. Contém segredos: nunca copiar para relatório, chat, log ou GitHub.

| Ambiente | US | Item (tela/identificador) | Valor original | Sensível (s/n) | Salvo em | Restaurado em |
|---|---|---|---|---|---|---|

## Usuários de teste

> Preencha os que já existem. O `/validar-ambiente` acrescenta aqui os que criar (Origem = CRIADO).

| Login | Senha | Perfil/permissões | Ambiente | Origem | US | Criado em | Observação |
|---|---|---|---|---|---|---|---|

## Destinatário de e-mail de teste (notificações)

Só o endereço do domínio selbetti da usuária. **Sem senha.** A skill /validar-ambiente pede a confirmação dele a cada execução (Step 4.6); a leitura dos e-mails é feita pelo conector Outlook da usuária.

| Endereço | Observação |
|---|---|
| <preencher: e-mail selbetti da usuária> | Usado como e-mail do usuário destinatário das notificações de teste. |
