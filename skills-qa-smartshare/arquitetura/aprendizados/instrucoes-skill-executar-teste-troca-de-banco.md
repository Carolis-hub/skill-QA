# Instruções para incluir a troca de banco na skill `arquitetura-executar-teste`

Documento de trabalho. Descreve **o que alterar** na skill (`.claude/skills/arquitetura-executar-teste/SKILL.md`) para que a execução de testes saiba trocar o ambiente entre SQL Server e Oracle usando as informações do arquivo de variáveis. Nada aqui altera a skill por si só: é o roteiro para você aplicar.

Base: procedimento executado em 06/11/2026 (SQL Server para Oracle) e valores informados pelo dono do ambiente para a volta (Oracle para SQL Server, ainda não executada por QA). Registro do aprendizado: `aprendizados/entradas/QA-KB-20261106-001.md`.

## 1. Onde mexer na skill

| Local na skill | Alteração |
|---|---|
| Parâmetro de entrada (Step 1) | Aceitar o banco alvo da rodada: `banco=oracle` ou `banco=sqlserver`. Sem o parâmetro, usar o banco em que o ambiente já está e informar qual é. |
| Step 2.5.1 (matriz de pré-requisitos) | Incluir o pré-requisito `PR-BANCO`: "ambiente apontado para o banco alvo", com fonte = arquivo de variáveis e evidência = conferência da seção 4 deste documento. |
| Step 2.5.2, item "Banco e segurança da rodada" | Acrescentar: confirmar o banco ativo do Share clássico e do net8 **antes** de qualquer cenário; se diferente do alvo, executar o novo **Step 2.6**. |
| **Novo Step 2.6** | "Alternar o banco do ambiente" (texto sugerido na seção 5). Roda só se o banco ativo for diferente do alvo. |
| Step 4.1 (Login) | Depois de trocar o banco a sessão do Share cai e a primeira requisição leva 30 a 40 s: refazer o login e usar timeout de pelo menos 90 s. |
| Step 5 (relatório) | Registrar no cabeçalho: banco da rodada, se houve troca (hora de início e fim) e o resultado das conferências da seção 4. |
| Troubleshooting | Incluir as pegadinhas da seção 7. |
| Step 0, item 4 e Step 2.5.1, item 4 | A skill cita `variaveis-de-ambiente-smartshare.example.md`; o arquivo real do ambiente é `Variveis de Ambiente/variaveis-de-ambiente-smartshare.md`. Decidir qual fica como fonte oficial e usar o mesmo nome nos dois pontos. |

## 2. Variáveis lidas do arquivo (nunca copiar o valor para skill, relatório ou chat)

Já existem no arquivo de variáveis:

| Uso | Variáveis |
|---|---|
| Oracle | `ORACLE_PROVIDER`, `ORACLE_DATA_SOURCE`, `ORACLE_USER`, `ORACLE_PASSWORD`, `ORACLE_SCHEMA_DATABASE` |
| SQL Server | `SQLSERVER_DATA_SOURCE`, `SQLSERVER_DATABASE`, `SQLSERVER_USER`, `SQLSERVER_PASSWORD` |
| Administrador do Share | `SS_TEST_USER` (`root`) e `SS_TEST_PASSWORD` |

Faltam no arquivo (sugiro acrescentar, em uma seção nova "Troca de banco", só nomes e valores não secretos):

| Variável nova | Conteúdo | Valor usado hoje |
|---|---|---|
| `WEBCONFIG_URL` | URL da tela de configuração do Share clássico | `http://localhost:58149/SmartShare/config/webconfig.aspx` |
| `SQLSERVER_PROVIDER` | Provider do SQL Server na tela | `System.Data.SqlClient` |
| `SQLSERVER_CAMINHO_VIRTUAL` | Caminho virtual com o SQL Server | `/SmartShare/` |
| `ORACLE_CAMINHO_VIRTUAL` | Caminho virtual com o Oracle | `/smartshare/` |
| `NET8_APPSETTINGS_API`, `NET8_APPSETTINGS_SCHEDULER`, `NET8_APPSETTINGS_BPM` | Caminhos dos três `appsettings.json`, relativos à raiz do projeto `smartshare-net8` (resolver pelo `.claude/workspace-paths.json`, sem caminho absoluto em arquivo versionado) | `src/3 - Core/Project.Core.Api`, `.../Project.Agent.WorkerScheduler`, `.../Project.Agent.Worker.Bpm` |
| `DB_USUARIO_SQLSERVER` (opcional) | Usuário SQL Server, se não quiser repetir em `SQLSERVER_USER` | usuário já registrado em `SQLSERVER_USER` |

Se uma variável obrigatória estiver ausente ou com "fornecido em tempo de execução", **pausar e pedir ao usuário**; não inventar.

## 3. Pré-condições e autorização (guardrails)

1. **Só ambiente local/não produtivo.** Confirmar pelo host (`localhost`) e pelo nome do cliente antes de alterar qualquer arquivo.
2. **Pedir confirmação explícita do usuário em cada rodada que trocar o banco**, dizendo o banco de origem e o de destino. A troca reescreve `Web.config` do clássico e três `appsettings.json` do net8 (alterações locais que aparecem no git e não podem ser commitadas).
3. **Parar antes de trocar:** Scheduler (`SmartShareAgent_SchedulerWorker`), Worker BPM (`SmartShareAgent_BpmWorker`), API local (`Engine.Api`, se estiver no ar) e o serviço `SmartShareAgent`. O serviço exige administrador: pedir ao usuário que pare (`net stop SmartShareAgent`); a skill não eleva permissão.
4. **Backup antes de editar:** copiar os 3 `appsettings.json` e o `SmartShareWeb/Web.config` para uma pasta temporária (scratchpad) e registrar o hash SHA-256 de cada um.
5. **Não registrar senha** em nenhum arquivo, relatório, comentário do Azure DevOps ou chat. O relatório mostra só "valores lidos do arquivo de variáveis".

## 4. Como saber em qual banco o ambiente está (antes e depois)

Conferir os quatro sinais e exigir que concordem:

1. `DBType` dentro de `ConnectionStrings` no `appsettings.json` da API, do Scheduler e do Worker BPM (`SQLServer` ou `Oracle`) e `Schema` (`dbo` ou o schema Oracle).
2. `ProviderName` no `SmartShareWeb/Web.config` (`System.Data.SqlClient` ou `System.Data.OracleClient`).
3. Log do Worker BPM da partida: "Iniciando worker/Bpm dbo" (SQL Server) ou "Iniciando worker/Bpm <schema Oracle>".
4. Tela de login do Share: a licença mostra "... - Oracle" quando o banco é Oracle.

Resultado da conferência vira a linha do `PR-BANCO` na matriz do Step 2.5.

## 5. Texto sugerido para o novo Step 2.6 (copiar para a skill e ajustar)

```markdown
## Step 2.6 — Alternar o banco do ambiente (somente se o banco ativo for diferente do alvo)

Pré-condição: `banco` informado e diferente do banco ativo (seção "Como saber o banco" abaixo). Peça confirmação explícita ao usuário citando origem e destino. Nunca imprima senhas.

1. **Ler as variáveis** do arquivo oficial de variáveis: para o alvo Oracle, `ORACLE_PROVIDER`, `ORACLE_DATA_SOURCE`, `ORACLE_USER`, `ORACLE_PASSWORD`, `ORACLE_CAMINHO_VIRTUAL`; para SQL Server, `SQLSERVER_PROVIDER`, `SQLSERVER_DATA_SOURCE`, `SQLSERVER_DATABASE`, `SQLSERVER_USER`, `SQLSERVER_PASSWORD`, `SQLSERVER_CAMINHO_VIRTUAL`; em ambos, `SS_TEST_USER` e `SS_TEST_PASSWORD` (administrador do Share) e `WEBCONFIG_URL`. Variável ausente: pare e pergunte.
2. **Parar os processos** (Scheduler, Worker BPM, API local) e pedir ao usuário que pare o serviço `SmartShareAgent`. Confirmar que nenhum `SmartShareAgent_*.exe` da pasta de build está vivo.
3. **Backup** dos três `appsettings.json` e do `Web.config` do clássico, com hash.
4. **Tela do Share clássico** (`WEBCONFIG_URL`, no Playwright com `browser_run_code_unsafe` ou `browser_fill_form`):
   - escolher o Provider (isto desabilita "Base de Dados" no Oracle);
   - preencher Servidor/Instância, Base de Dados (só SQL Server), Usuário e Senha do banco, Caminho Virtual, Usuário Administrador e Senha do administrador, com os valores do passo 1;
   - clicar em Salvar (botão `btnSalvarAvancada`) e exigir "Configurações Salvas com Sucesso!". Se não aparecer, pare.
   Campos da tela: `ddlProvider`, `txtServidor`, `txtBaseDados`, `txtUsuario`, `txtSenha`, `txtCaminhoVirtual`, `txtUsuarioAdministrador`, `txtSenhaAdministrador` (prefixo `ctl00_ContentPlaceHolder1_`).
5. **Conferir o efeito do Salvar:** o `Web.config` do clássico e o bloco `ConnectionStrings` do `appsettings.json` da API mudaram (hash diferente do backup; `DBType` e `Schema` do banco alvo). Se a API não mudou, pare e reporte.
6. **Copiar o bloco `ConnectionStrings` completo** do `appsettings.json` da API para o do Scheduler e para o do Worker BPM, substituindo só esse bloco e preservando o resto e as quebras de linha (script da seção 6). Validar que o JSON continua válido e que `DefaultConnection`, `DBType` e `Schema` são iguais nos três.
7. **Atualizar a pasta `bin`:** os Workers leem `bin\Debug\net8.0\appsettings.json`. Copiar o `appsettings.json` do Scheduler e do Worker BPM para a `bin` de cada um (ou recompilar). Subir primeiro o Scheduler e depois o Worker BPM.
8. **Conferir (seção "Como saber o banco")** os quatro sinais; o log do Worker não pode ter `ERROR` na partida. A primeira requisição ao Share leva de 30 a 40 s; use timeout de 90 s e refaça o login do Share.
9. **Ajustar o estado do banco alvo** conforme o cenário (ex.: `JOB_CONFIG` Id 12 `Ativo`, parâmetro 96) somente com a autorização de escrita já concedida; leia antes e registre o valor.
10. **Registrar** no relatório: banco de origem e destino, hora, hashes antes e depois (sem valores), resultado das conferências e eventuais lentidões.

Falha em qualquer passo: restaurar os quatro arquivos do backup (conferir o hash), reiniciar os processos que estavam no ar e reportar o ponto da falha.
```

## 6. Scripts de apoio (sem credenciais)

**Copiar o bloco `ConnectionStrings` da API para os outros dois `appsettings.json`** (Python, preserva o restante do arquivo):

```python
import re
def bloco(txt):
    i = txt.index('"ConnectionStrings"'); j = txt.index('{', i); d = 0
    for k in range(j, len(txt)):
        if txt[k] == '{': d += 1
        elif txt[k] == '}':
            d -= 1
            if d == 0: return i, k + 1
    raise SystemExit('chaves desbalanceadas')
api = open('<API>/appsettings.json', encoding='utf-8', newline='').read()
a0, a1 = bloco(api); novo = api[a0:a1]
for p in ('<SCHEDULER>/appsettings.json', '<BPM>/appsettings.json'):
    raw = open(p, encoding='utf-8', newline='').read()
    b0, b1 = bloco(raw)
    nl = '\r\n' if '\r\n' in raw else '\n'
    out = raw[:b0] + novo.replace('\r\n', '\n').replace('\n', nl) + raw[b1:]
    open(p, 'w', encoding='utf-8', newline='').write(out)
```

**Atualizar a `bin` e subir os Workers** (PowerShell, ajustar `$b` para a pasta `src/3 - Core` do `smartshare-net8`):

```powershell
foreach ($d in 'Project.Agent.WorkerScheduler','Project.Agent.Worker.Bpm') {
  Copy-Item "$b\$d\appsettings.json" "$b\$d\bin\Debug\net8.0\appsettings.json" -Force
}
Start-Process "$b\Project.Agent.WorkerScheduler\bin\Debug\net8.0\SmartShareAgent_SchedulerWorker.exe" -WorkingDirectory "$b\Project.Agent.WorkerScheduler\bin\Debug\net8.0" -WindowStyle Hidden
Start-Process "$b\Project.Agent.Worker.Bpm\bin\Debug\net8.0\SmartShareAgent_BpmWorker.exe" -WorkingDirectory "$b\Project.Agent.Worker.Bpm\bin\Debug\net8.0" -WindowStyle Hidden
```

**Hash para o backup e a conferência:** `Get-FileHash <arquivo> -Algorithm SHA256`.

## 7. Pegadinhas para o Troubleshooting da skill

1. Depois do Salvar, a primeira requisição ao Share leva 30 a 40 s (recompilação e primeira conexão); a sessão cai e é preciso entrar de novo.
2. O Salvar já reescreve o `appsettings.json` da API; o erro comum é copiar o bloco **antes** de conferir que a API mudou.
3. Os Workers leem a `bin`, não o arquivo de origem: sem copiar (ou recompilar), eles sobem no banco antigo.
4. No Oracle, a primeira conexão do Worker pode estourar (`ORA-50000 Connection request timed out`) e derrubar o processo: reiniciar uma vez antes de investigar.
5. Cada banco tem os seus valores de `JOB_CONFIG` Id 12 `Ativo` e do parâmetro 96; o `Ativo` só tem efeito na partida dos Workers. Ao fim dos testes de 06/11/2026: SQL Server com `Ativo=0` e parâmetro 96 = 1; Oracle com `Ativo=1` e parâmetro 96 = 0. Conferir antes de testar.
6. Parâmetro 96 = 1 exige o nginx roteando `/smartshare/api/` para a API local (porta 8081) e o Share acessado pela porta 8080; sem isso iniciar fluxo dá "Erro inesperado".
7. O Agent clássico (serviço `SmartShareAgent`) já tem os dois clientes no `ConfigClientes.xml` e não faz parte da troca; só precisa estar parado durante ela.
8. Caminho Virtual muda entre bancos (`/smartshare/` no Oracle, `/SmartShare/` no SQL Server); o salvar grava isso no `Web.config` (`CaminhoSmartShare`).

## 8. Pontos em aberto antes de aplicar

- A volta Oracle para SQL Server ainda não foi executada por QA; confirmar na primeira vez (mensagem, log, tempo) e atualizar `QA-KB-20261106-001`.
- Decidir se a troca será sempre confirmada pelo usuário ou se a skill pode trocar sozinha quando o parâmetro `banco` for informado (recomendo confirmar, por alterar arquivos do ambiente).
- Decidir onde ficam as variáveis novas da seção 2 (no próprio arquivo de variáveis, na seção "Troca de banco") e se o arquivo `.example.md` também recebe os nomes (sem valores).
- Avaliar um script único (PowerShell) para os passos 3 a 7, deixando só o passo 4 (tela) para o Playwright.
