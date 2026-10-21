# Painel de Mortalidade Materna - Fase 2

Este projeto tem como objetivo preparar, tratar e armazenar dados públicos de mortalidade materna para uso em análises posteriores, em um banco PostgreSQL na nuvem. A solução foi desenvolvida conforme o marco de entregáveis descrito no documento de referência da etapa, com foco em organização dos dados, modelagem, infraestrutura e documentação.

## 1. Contexto e objetivo

A base utilizada é o Observatório Obstétrico Brasileiro (OOBr), com dados de óbitos na gravidez e no puerpério. O projeto concentra-se no estudo da mortalidade materna, considerando especificamente:

- óbitos maternos oficiais;
- óbitos desconsiderados;
- organização em modelo analítico;
- armazenamento em banco relacional na nuvem;
- documentação dos processos e da infraestrutura.

A etapa não calcula razão de mortalidade materna, porque isso exigiria dados de nascidos vivos do SINASC. O foco foi preparar a camada de dados para uso nas próximas fases do painel.

## 2. Dados utilizados

### 2.1 Fonte

Os dados foram obtidos a partir dos arquivos públicos do OOBr, mantidos no diretório `data/raw/`.

### 2.2 Base e recorte

Foram utilizados cinco arquivos da base de óbitos em gravidez e puerpério, no período de 1996 a 2024:

- `maternos_oficiais`
- `desconsiderados`
- `garbage_codes`
- `analise_cruzada`
- `ufs`

Para a carga e análise funcional da etapa, o recorte adotado foi de 2014 a 2024, porque esse intervalo foi considerado o período de maior utilidade operacional e de consistência para o painel. O arquivo `manifest.csv` foi mantido junto aos dados brutos para registrar origem, versão e hash das bases.

### 2.3 Características relevantes

- os dados incluem informações de município, UF, região, ano, idade, raça/cor, causa CID-10, tipo de morte materna, período do óbito e investigação do CMM;
- há registros de óbitos oficiais e registros classificados como desconsiderados;
- parte da base contém redundâncias e arquivos auxiliares usados para validação e controle de qualidade;
- a etapa foi construida para manter dados públicos e tratá-los antes da carga em banco.

## 3. Tratamento realizado

O processo de ETL foi implementado em `src/etl.py` e produziu os CSVs processados em `data/processed/`.

### 3.1 Transformações principais

As principais decisões e transformações foram:

- remoção da coluna `X`, que era apenas um índice da exportação original;
- limpeza de textos, com remoção de espaços extras e padronização;
- conversão de ano e idade para inteiros;
- preservação do código do município com 6 dígitos, para não perder zeros à esquerda;
- criação de faixa etária a partir da idade;
- unificação de variações de estado civil/descrições equivalentes, como `Solteira` e `Solteiro`;
- preenchimento de nulos de necropsia como `Ignorado` quando necessário;
- manutenção de municípios ignorados, marcados com a coluna `municipio_ignorado`;
- preservação de registros com idade menor que 10 anos, mas agrupados na faixa `0 a 9`;
- manutenção de linhas duplicadas do arquivo de análise cruzada, porque cada linha representa um óbito e o total concentrou-se com os demais arquivos;
- encurtamento de nomes de colunas do arquivo de UFs para evitar incompatibilidades com PostgreSQL.

### 3.2 Regras de recorte

A etapa tratou os dados conforme as regras abaixo:

- recorte temporal: 2014 a 2024;
- óbitos oficiais: mantidos no conjunto principal;
- óbitos desconsiderados: filtrados pela faixa de idade, removendo registros com menos de 10 anos e 50 anos ou mais.

### 3.3 Validações executadas

O pipeline realizou verificações de integridade e consistência, incluindo:

- comparação de hashes dos arquivos com o manifest;
- validação de redundância entre arquivos;
- contagens de óbitos por tabela;
- checagem de ausência de chaves estrangeiras sem correspondência;
- conferência de totals entre arquivos oficiais, análise cruzada e UFs.

Resultados relevantes:

- total de óbitos maternos oficiais: 48.933;
- total de óbitos desconsiderados: 42.311;
- nenhum problema de integridade de chave foi detectado.

## 4. Modelagem dos dados

A estrutura foi organizada em modelo estrela, com dimensões e tabelas fato.

### 4.1 Dimensões

As dimensões criadas foram:

- tempo;
- localidade;
- faixa etária;
- raça/cor;
- tipo de morte;
- período do óbito;
- investigação CMM;
- causa CID-10.

### 4.2 Tabelas fato

As tabelas fato previstas foram:

- óbitos maternos oficiais;
- óbitos desconsiderados;
- garbage codes;
- perfil do óbito;
- óbitos por UF e idade.

### 4.3 Estrutura no banco

O schema principal é `painel`. Os dados são carregados em tabelas como:

- `obitos_maternos_oficiais`;
- `obitos_desconsiderados`.

O SQL de criação está em `sql/schema.sql`, e o carregamento é executado por `src/load.py` usando `COPY` do PostgreSQL.

## 5. Infraestrutura

A infraestrutura foi provisionada em código usando Terraform.

### 5.1 Serviços utilizados

- PostgreSQL gerenciado no Aiven;
- Terraform para provisionamento e versionamento da infraestrutura;
- esquema do banco `painel` em PostgreSQL.

### 5.2 Recursos provisionados

A infraestrutura inclui:

- serviço PostgreSQL no Aiven;
- usuário de leitura (`painel_leitura`), com permissão somente de leitura;
- configuração de acesso segura com SSL.

### 5.3 Organização do repositório

A estrutura principal do projeto é:

```text
projeto/
├── data/
│   ├── raw/
│   └── processed/
├── docs/
│   ├── DECISOES.md
│   ├── INFRAESTRUTURA.md
│   ├── SEGURANCA.md
│   └── log_etl.txt
├── sql/
│   ├── schema.sql
│   ├── consultas_verificacao.sql
│   └── permissoes.sql
├── src/
│   ├── etl.py
│   └── load.py
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── imports.tf
│   ├── versions.tf
│   └── terraform.tfvars.example
├── .env.example
├── .gitignore
└── README.md
```

## 6. Segurança da infraestrutura

A segurança foi tratada como parte crítica do projeto, em linha com o documento de referência do marco 2.

### 6.1 O que foi protegido

- token da API do Aiven;
- senha do usuário administrativo `avnadmin`;
- senha do usuário de leitura `painel_leitura`;
- arquivos de state do Terraform;
- arquivo `.env` com a URL de conexão.

### 6.2 Estratégia adotada

- segredos armazenados fora do código-fonte;
- utilização de variáveis de ambiente;
- manutenção do arquivo `.env` fora do controle de versão;
- ajuste do `.gitignore` para bloquear credenciais e arquivos de estado;
- uso de SSL obrigatório para acesso ao banco;
- separação entre administração e leitura, com menor privilégio para usuários de consulta.

## 7. Execução do processo

### 7.1 Pré-requisitos

- Python 3;
- pandas;
- psycopg2;
- python-dotenv;
- Terraform;
- acesso ao banco no Aiven;
- token de API do Aiven configurado em variável de ambiente.

### 7.2 Sequência geral

1. provisionar a infraestrutura com Terraform;
2. gerar o arquivo `.env` com a URL do banco;
3. executar `python src/etl.py` para tratar os dados;
4. executar `python src/load.py` para criar o schema e carregar os CSVs;
5. aplicar permissões com `sql/permissoes.sql`;
6. validar a carga e a consistência dos dados.

### 7.3 Comandos principais

```bash
cd projeto
python src/etl.py
python src/load.py
```

Para provisionamento da infraestrutura:

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

## 8. Resultados esperados

Ao final da etapa, o projeto entrega:

- dados públicos selecionados e tratados;
- dados organizados em modelo de banco analítico;
- banco PostgreSQL na nuvem com os dados carregados;
- infraestrutura provisionada por Terraform;
- documentação e critérios de decisão versionados no repositório.

Esse conjunto deixa a camada de dados pronta para uso nas próximas fases do painel de mortalidade materna.

## 9. Conclusão

A solução proposta combina tratamento analítico de dados públicos, organização em modelo estrela, armazenamento em PostgreSQL na nuvem e documentação técnica adequada para reprodução e manutenção. A arquitetura foi desenhada para equilibrar praticidade, segurança e clareza, mantendo um processo reprodutível e alinhado ao que foi solicitado no marco 2 do projeto.
