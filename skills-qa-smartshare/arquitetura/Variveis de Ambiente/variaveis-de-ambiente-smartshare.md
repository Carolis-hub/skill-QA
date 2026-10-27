# Variáveis de ambiente e credenciais — SmartShare

> **SENSÍVEL:** este arquivo contém logins e senhas de ambientes de QA/desenvolvimento. Restrinja o acesso, não publique em repositórios ou tickets e faça a rotação das credenciais se o arquivo for compartilhado fora do time autorizado.

Gerado em **2026-10-26** a partir dos arquivos do projeto de Arquitetura Share e das configurações locais referenciadas pelos scripts.

## 1. Variáveis de execução dos testes

| Variável | Valor registrado | Observação |
|---|---|---|
| `SS_TEST_USER` | (fornecido em tempo de execução) | Login do Share usado pelos scripts de automação; não há valor persistido no projeto. |
| `SS_TEST_PASSWORD` | (fornecido em tempo de execução) | Senha do Share usada pelos scripts de automação; não há valor persistido no projeto. |
| `SS_OUTPUT_DIR` | (fornecido em tempo de execução) | Diretório de evidências. |
| `SS_BROWSER_PATH` | (opcional; usa o Chromium padrão quando ausente) | Executável do navegador. |
| `SS_ACTION` | inspect (padrão do script) | Ações do script NotifyWF: inspect, break ou restore. |
| `SS_MODE` | (fornecido em tempo de execução) | Modo de autenticação do Mailer. |
| `SS_PREFIX` | (fornecido em tempo de execução) | Prefixo dos arquivos de evidência do Mailer. |
| `SS_SMTP_USER` | (fornecido em tempo de execução) | Usuário SMTP; não há valor persistido no projeto. |
| `SS_SMTP_PASS` | (fornecido em tempo de execução) | Senha SMTP; não há valor persistido no projeto. |
| `SS_FROM` | (fornecido em tempo de execução) | Remetente usado no Mailer. |

Fontes dos nomes: scripts em `work\*.js` e `work\*.ps1` que acessam `process.env.*` ou `$env:*`.

## 2. SQL Server

### 2.0 Configurações registradas na pasta de trabalho

Os três arquivos abaixo possuem a mesma conexão SQL Server criptografada:

- work\appsettings-workers-3.87.4\BPM\appsettings.json
- work\appsettings-workers-3.87.4\Scheduler\appsettings.json
- work\executaws-bpm-runtime\appsettings.json

| Variável/configuração | Valor |
|---|---|
| `DBType` | SQLServer |
| `SQLSERVER_DATA_SOURCE` | NOTE-74VQ\SQLEXPRESS |
| `SQLSERVER_DATABASE` | ShareGuizao |
| `SQLSERVER_USER` | guilherme.borges |
| `SQLSERVER_PASSWORD` | Guizao@2 |

## 2. SQL Server

### 2.1 Worker .NET 8 — BPM e Scheduler

> **Ambiente utilizado:** banco pessoal de QA ShareGuizao, cliente GuizaoLocal. Os valores abaixo substituem os valores de desenvolvimento que vieram nos ppsettings após o pull da master.

| Variável/configuração | Valor | Origem |
|---|---|---|
| `DBType` | SQLServer | Configuração do cliente GuizaoLocal |
| `SQLSERVER_DATA_SOURCE` | NOTE-74VQ\SQLEXPRESS | 	mp-share-db-check\ConfigClientes.legacy-test.xml |
| `SQLSERVER_DATABASE` | ShareGuizao | 	mp-share-db-check\ConfigClientes.legacy-test.xml |
| `SQLSERVER_USER` | guilherme.borges | 	mp-share-db-check\ConfigClientes.legacy-test.xml |
| `SQLSERVER_PASSWORD` | Guizao@2 | Descriptografada a partir de DsSenhaBD |
| `SQLSERVER_CLIENTE` | GuizaoLocal | 	mp-share-db-check\ConfigClientes.legacy-test.xml |
| `SQLSERVER_INSTALLATION_URL` | http://localhost:58149/smartshare/ | 	mp-share-db-check\ConfigClientes.legacy-test.xml |

BPM e Scheduler devem apontar para os mesmos valores de conexão do ambiente ShareGuizao.
### 2.2 Cliente legado — GuizaoLocal

| Variável/configuração | Valor |
|---|---|
| `SQLSERVER_CLIENTE` | GuizaoLocal |
| `SQLSERVER_DATA_SOURCE` | NOTE-74VQ\SQLEXPRESS |
| `SQLSERVER_DATABASE` | ShareGuizao |
| `SQLSERVER_USER` | guilherme.borges |
| `SQLSERVER_PASSWORD` | Guizao@2 |
| `SQLSERVER_INSTALLATION_URL` | http://localhost/smartshare_debug/ |

### 2.3 Script temporário de execução SQL

Valores encontrados em `tmp-share-db-check\Invoke-DbScript.ps1`:

| Variável/configuração | Valor |
|---|---|
| `SQLSERVER_DATA_SOURCE` | NOTE-74VQ\SQLEXPRESS |
| `SQLSERVER_DATABASE` | ShareGuizao |
| `SQLSERVER_USER` | guilherme.borges |
| `SQLSERVER_PASSWORD` | Guizao@2 |

## 3. Oracle

### 3.1 Worker BPM legado

| Variável/configuração | Valor | Origem |
|---|---|---|
| `DBType` | Oracle | D:\Instalação Share\Agent Workers\BPM\appsettings.json |
| `ORACLE_DATA_SOURCE` | ss-oracle-br-3.c4xqrvkzu2a0.sa-east-1.rds.amazonaws.com:1521/SSHARE | D:\Instalação Share\Agent Workers\BPM\appsettings.json |
| `ORACLE_USER` | SHAREGUIZAO | D:\Instalação Share\Agent Workers\BPM\appsettings.json |
| `ORACLE_PASSWORD` | guilherme13 | Descriptografada com a chave usada pelos scripts do projeto |

### 3.2 Cliente legado — SHAREGUIZAO

| Variável/configuração | Valor |
|---|---|
| `ORACLE_CLIENTE` | SHAREGUIZAO |
| `ORACLE_PROVIDER` | System.Data.OracleClient |
| `ORACLE_DATA_SOURCE` | ss-oracle-br-3.c4xqrvkzu2a0.sa-east-1.rds.amazonaws.com:1521/SSHARE |
| `ORACLE_SCHEMA_DATABASE` | SHAREGUIZAO |
| `ORACLE_USER` | SHAREGUIZAO |
| `ORACLE_PASSWORD` | guilherme13 |
| `ORACLE_INSTALLATION_URL` | http://localhost/smartshare_debug/ |

## 4. Usuário do Share

| Variável | Login | Senha |
|---|---|---|
| ``SS_TEST_USER`` | Não registrado; informado em tempo de execução | — |
| ``SS_TEST_PASSWORD`` | — | Não registrado; informado em tempo de execução |

Os scripts `work\smartshare_final_login.js`, `work\executasql_front_login_inspect.js`, `work\notifywf_poison_front.js` e `work\mailer_front_*.js` apenas leem essas variáveis do ambiente; nenhum login ou senha do Share foi persistido no projeto.

## 5. Observações de segurança

- As conexões em `appsettings.json` e em `ConfigClientes.xml` ficam armazenadas criptografadas; os valores acima foram obtidos localmente usando a mesma rotina/chave já referenciada pelos scripts do projeto.
- Este documento deve permanecer fora de repositórios públicos e de artefatos de evidência.
- Após o uso, recomenda-se armazenar as credenciais em um cofre de segredos e remover senhas de scripts temporários.

## 6. Fontes consultadas

- `work\appsettings-workers-3.87.4\BPM\appsettings.json`
- `work\appsettings-workers-3.87.4\Scheduler\appsettings.json`
- `work\executaws-bpm-runtime\appsettings.json`
- `tmp-share-db-check\ConfigClientes.legacy-test.xml`
- `tmp-share-db-check\Invoke-DbScript.ps1`
- `D:\smartshare-net8\src\3 - Core\Project.Agent.Worker.Bpm\appsettings.json`
- `D:\smartshare-net8\src\3 - Core\Project.Agent.WorkerScheduler\appsettings.json`
- `D:\Instalação Share\Agent Workers\BPM\appsettings.json`
- `D:\Instalação Share\Agent\configuracoes\ConfigClientes.xml`
