# Painel de Mortalidade Materna

Trabalho de Big Data & Analytics, Fase 2.

Alunos: Diego Gabriel Pinheiro Damasceno e Flávia Rodrigues Santos Silva.
Professora: Sheila Tirony.

Base de óbitos na gravidez e no puerpério do Observatório Obstétrico Brasileiro (OOBr), tratada para o período de 2014 a 2024 e carregada num PostgreSQL no Aiven, provisionado com Terraform.

## Organização do repositório

```
.
├── README.md                  este arquivo
├── .gitignore                 bloqueia .env, state e tfvars do Terraform (ver docs/SEGURANCA.md)
└── projeto/
    ├── requirements.txt       dependências Python
    ├── .env.example           modelo do .env com a conexão do banco (sem senha)
    ├── data/
    │   ├── raw/               os 5 CSVs originais do OOBr e o manifest.csv (versão e MD5 de cada um)
    │   └── processed/         os 2 CSVs tratados, gerados pelo etl.py
    ├── src/                   código do tratamento e da carga
    │   ├── etl.py             data/raw ──► data/processed
    │   └── load.py            data/processed ──► PostgreSQL
    ├── sql/
    │   ├── schema.sql                  schema painel, tabelas e índices (rodado pelo load.py)
    │   ├── permissoes.sql              usuário só de leitura para o painel
    │   └── consultas_verificacao.sql   consultas para conferir a carga
    ├── terraform/             infraestrutura como código (serviço PostgreSQL e usuário de leitura no Aiven)
    └── docs/
        ├── DECISOES.md        tratamento dos dados: problemas encontrados, decisões e justificativas
        ├── INFRAESTRUTURA.md  serviços, recursos provisionados e como rodar o Terraform
        ├── SEGURANCA.md       como as credenciais são guardadas fora do repositório
        └── log_etl.txt        contagens e validações geradas pelo etl.py
```

| O que se procura                     | Onde está                                   |
|--------------------------------------|---------------------------------------------|
| Código do tratamento dos dados       | `projeto/src/etl.py`                        |
| Base tratada                         | `projeto/data/processed/`                   |
| Estrutura do banco                   | `projeto/sql/schema.sql`                    |
| Infraestrutura                       | `projeto/terraform/`                        |
| Documentação                         | `projeto/docs/`                             |
| Gestão de credenciais                | `projeto/docs/SEGURANCA.md`                 |

## Como reproduzir

Precisa de Python 3.10 ou mais novo e Terraform 1.6 ou mais novo. Todos os comandos rodam a partir da pasta `projeto/`.

```
cd projeto
pip install -r requirements.txt

# 1. tratamento: lê data/raw e grava data/processed e docs/log_etl.txt
python src/etl.py

# 2. infraestrutura (detalhes em docs/INFRAESTRUTURA.md)
cd terraform
cp terraform.tfvars.example terraform.tfvars
export AIVEN_TOKEN=...
terraform init && terraform apply
echo "DATABASE_URL=$(terraform output -raw database_url)" > ../../.env
cd ..

# 3. carga no banco e permissões do usuário de leitura
python src/load.py
psql "$(terraform -chdir=terraform output -raw database_url)" -f sql/permissoes.sql
```

Para conferir a carga, rode `sql/consultas_verificacao.sql` no DBeaver, no pgAdmin ou no `psql`.
