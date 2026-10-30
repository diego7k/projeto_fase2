# Segurança das informações de acesso

O repositório é público, então nenhuma credencial pode estar nele. Este documento mostra quais informações são sensíveis no projeto, onde cada uma fica e como evitamos que cheguem ao GitHub.

## O que é sensível

| Informação                              | Onde fica                                         | Vai para o Git? |
|-----------------------------------------|---------------------------------------------------|-----------------|
| Token da API do Aiven                   | variável de ambiente `AIVEN_TOKEN`, só na máquina de quem roda o Terraform | Não |
| Senha do `avnadmin` (carga dos dados)   | arquivo `.env`, gerado pelo `terraform output`   | Não (`.gitignore`) |
| Senha do `painel_leitura`               | state do Terraform, lida com `terraform output`  | Não |
| State do Terraform (`terraform.tfstate`)| pasta `terraform/`, só local                      | Não (`.gitignore`) |
| `terraform.tfvars`                      | pasta `terraform/`                                | Não (`.gitignore`) |
| Host, porta, nome do banco e do projeto | `variables.tf`, documentação                      | Sim, não são segredos sem a senha |

## Estratégia

**1. Segredos fora do código.** O código nunca tem senha escrita. O `src/load.py` lê a conexão da variável `DATABASE_URL`, que vem do arquivo `.env`. O provider do Aiven lê o token da variável de ambiente `AIVEN_TOKEN`; o bloco `provider "aiven" {}` fica vazio de propósito.

**2. `.gitignore` na raiz do repositório.** Bloqueia `.env`, `*.tfstate`, `*.tfvars` e a pasta `.terraform/`. Ficam liberados só os modelos sem segredos: `.env.example` e `terraform.tfvars.example`, que mostram o formato esperado para quem for reproduzir o projeto.

**3. State do Terraform local.** O state guarda as senhas em texto puro, mesmo as saídas marcadas como `sensitive`. Por isso ele fica só na máquina de quem roda o Terraform e não é versionado. Para um trabalho em equipe maior, o próximo passo seria um backend remoto com criptografia e controle de acesso (por exemplo, HCP Terraform ou um bucket S3 criptografado).

**4. Saídas sensíveis.** As URLs de conexão no `outputs.tf` são `sensitive = true`, então não aparecem no `terraform plan` nem no `apply`. Só aparecem quando pedidas explicitamente com `terraform output -raw`, que é como o `.env` é gerado.

**5. Menor privilégio.** O `avnadmin` é usado só para criar as tabelas e carregar os dados. O painel das próximas fases vai usar o `painel_leitura`, que só consegue fazer `SELECT` no schema `painel` (`sql/permissoes.sql`). Se a senha do painel vazar, ninguém consegue alterar nem apagar dados com ela.

**6. Conexão criptografada.** Todas as conexões usam `sslmode=require`; o Aiven não aceita conexão sem SSL.

## Incidente e correção

Na primeira versão do repositório, o `.env` com a senha do `avnadmin` foi enviado ao GitHub. Isso aconteceu porque o `.gitignore` estava dentro da pasta `projeto/`, e o `.env` estava na raiz, fora do alcance dele.

O que foi feito:

- a senha do `avnadmin` foi trocada no console do Aiven (Users > avnadmin > Reset password), então a senha que aparece no histórico não funciona mais;
- o `.env` foi removido do repositório e foi criado um `.gitignore` na raiz, que vale para o repositório inteiro;
- o histórico do Git foi reescrito para tirar o `.env` de todos os commits (`git filter-branch --index-filter 'git rm --cached --ignore-unmatch .env'`), então o arquivo não aparece mais em nenhuma versão do repositório;
- o `.env` passou a ser gerado pelo `terraform output`, em vez de copiado à mão.

Limpar o histórico não basta sozinho, porque alguém pode ter clonado o repositório antes. Por isso a troca da senha é o passo principal, e a limpeza do histórico complementa.

## Como trocar uma senha

- `avnadmin`: console do Aiven > serviço > Users > Reset password. Depois, gerar o `.env` de novo com `terraform output`.
- `painel_leitura`: `terraform apply -replace=aiven_pg_user.leitura` recria o usuário com uma senha nova. Depois, rodar `sql/permissoes.sql` de novo.
- Token do Aiven: revogar em User information > Tokens e criar outro.
