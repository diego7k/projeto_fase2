# Infraestrutura

A infraestrutura do projeto é um banco PostgreSQL gerenciado no Aiven, descrito como código com Terraform na pasta `terraform/`.

## Serviços utilizados

- **Aiven for PostgreSQL**, plano gratuito (`free-1-1gb`): 1 CPU, 1 GB de RAM e 1 GB de disco. É onde fica o schema `painel`, com as tabelas `obitos_maternos_oficiais` e `obitos_desconsiderados`.
- **Terraform** com o provider oficial `aiven/aiven` (versão 4.64), para provisionar e versionar o banco.

Escolhemos o Aiven porque o plano gratuito é um PostgreSQL de verdade, acessível pela internet e com SSL obrigatório, sem precisar de cartão de crédito. O limite de 1 GB não é problema: as duas tabelas ocupam cerca de 9 MB (5,5 MB e 3,1 MB), por causa do recorte de 2014 a 2024 e de termos deixado de fora os três arquivos redundantes (ver `docs/DECISOES.md`).

## Recursos provisionados

| Recurso Terraform      | O que é                                                                                         |
|------------------------|-------------------------------------------------------------------------------------------------|
| `aiven_pg.painel`      | O serviço PostgreSQL (`pg-3f45094b`, projeto `diego7k`). Já vem com o banco `defaultdb` e o usuário administrador `avnadmin`. |
| `aiven_pg_user.leitura`| Usuário `painel_leitura`, só de leitura, para o painel das próximas fases. A senha é gerada pelo Aiven. |

As tabelas, índices e permissões não ficam no Terraform, ficam em SQL: `sql/schema.sql` (rodado pelo `src/load.py`) e `sql/permissoes.sql`. Separamos assim porque o Terraform cuida do que é infraestrutura (o servidor e os usuários), e o SQL cuida da estrutura dos dados, que muda junto com o tratamento.

## Arquivos

```
terraform/
  versions.tf               versão do Terraform e do provider do Aiven
  variables.tf              projeto, nome do serviço, nuvem, plano e nome do usuário de leitura
  main.tf                   o serviço PostgreSQL e o usuário de leitura
  imports.tf                importa o serviço que já existia no Aiven
  outputs.tf                host, porta e as URLs de conexão (marcadas como sensíveis)
  terraform.tfvars.example  modelo do terraform.tfvars
  .terraform.lock.hcl       versões exatas dos providers, para todos usarem as mesmas
```

O banco foi criado primeiro pelo console do Aiven, na fase anterior. Por isso existe o `imports.tf`: no primeiro `terraform apply` ele traz o serviço existente para o controle do Terraform, sem apagar nem recriar nada. Num ambiente novo, basta apagar esse arquivo e o Terraform cria o serviço do zero.

## Como provisionar

Precisa do Terraform 1.6 ou mais novo e de um token da API do Aiven (Aiven > User information > Tokens). O token não vai em nenhum arquivo, só na variável de ambiente (ver `docs/SEGURANCA.md`).

```
cd terraform
cp terraform.tfvars.example terraform.tfvars    # preencher cloud_name
export AIVEN_TOKEN=...                          # token pessoal do Aiven
terraform init
terraform plan
terraform apply
```

Depois do `apply`, gerar o `.env` usado pelo `load.py` a partir das saídas do Terraform, carregar os dados e dar as permissões ao usuário de leitura:

```
echo "DATABASE_URL=$(terraform output -raw database_url)" > ../../.env
cd ..
python src/etl.py
python src/load.py
psql "$(terraform -chdir=terraform output -raw database_url)" -f sql/permissoes.sql
```

## Sequência completa

```
dados do OOBr (data/raw)
   │  src/etl.py
   ▼
CSVs tratados (data/processed)
   │                         terraform apply ──► PostgreSQL no Aiven
   │  src/load.py  ─────────────────────────────►  schema painel
   ▼
sql/permissoes.sql ──► usuário painel_leitura pronto para o painel
```
