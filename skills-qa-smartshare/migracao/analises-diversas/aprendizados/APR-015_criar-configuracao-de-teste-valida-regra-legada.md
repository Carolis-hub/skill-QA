---
id: APR-015
data: 2026-11-06
skill: executar-teste
escopo: Geral
status: Ativo
---
**Situação:** um cenário precisa de uma configuração ou massa que não existe no ambiente (perfil, usuário, conexão, vínculo entre eles, índice, parâmetro etc.) e a skill vai criá-la para poder testar. Gatilho concreto: US 164849, cenário #53 (usuário com perfis sem vínculo a nenhuma conexão).
**Pergunta feita:** existe um usuário ou perfil sem vínculo a conexão, ou posso criar um perfil e um usuário novos só para o #53?
**Resposta da usuária:** "#53, sempre que for necessário criar uma configuração para um teste, deve ser validada a regra legada para essa criação".
**Como aplicar:** antes de criar qualquer configuração para um teste, ler no Clássico (hub: `SmartShare/WebApplication`, `SmartShare/SmartShare/BLL` e `DAL`) a regra de criação daquele item: campos obrigatórios, valores permitidos, efeitos colaterais (herança, cópia de vínculos) e quem a executa. Citar `arquivo:linha` no plano e no relatório. Criar pelo caminho que respeita essa regra (mesma ordem, mesmos campos). Se a tela ou API nova divergir do Clássico, registrar a divergência e não "contornar". Vale também para o `/validar-ambiente`. Não dispensa a confirmação de ação de escrita quando a criação tiver efeito sobre dados existentes (ex.: herança de usuários de um perfil pai).
