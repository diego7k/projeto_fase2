Painel de Mortalidade Materna

Trabalho de Big Data & Analytics - Fase 2.

Alunos: Diego Gabriel Pinheiro Damasceno e Flávia Rodrigues Santos Silva.
Professora: Sheila Tirony.

Este projeto usa dados do Observatório Obstétrico Brasileiro (OOBr), publicados no Synapse. A base contém óbitos na gravidez e no puerpério, no período de 1996 a 2024.

Nesta fase, o foco ficou em mortalidade materna. A violência obstétrica não aparece nos arquivos usados, por isso não foi incluída na base atual.

O ETL lê os cinco arquivos originais, trata os dados e gera uma base em modelo estrela para PostgreSQL, com dimensões e tabelas fato.

Resultado principal do tratamento:

Óbitos maternos oficiais: 48.933.

Óbitos desconsiderados: 42.311.

Arquivos tratados: 8 dimensões e 5 tabelas fato em data/processed.

Pastas e arquivos principais:

data/raw: arquivos originais do OOBr e manifest.csv.

data/processed: arquivos tratados gerados pelo ETL.

src/etl.py: script de tratamento dos dados.

src/load.py: script de carga no PostgreSQL.

sql/schema.sql: criação do schema, tabelas, índices e view.

sql/consultas_verificacao.sql: consultas para conferir a carga no banco.

docs/DECISOES.md: decisões técnicas e justificativas.

docs/log_etl.txt: contagens e validações geradas pelo ETL.

Como rodar:

Entre na pasta projeto e instale as dependências:

pip install pandas psycopg2-binary python-dotenv

Depois rode o tratamento:

python src/etl.py

Para carregar no PostgreSQL, crie um arquivo .env com a conexão do Aiven:

DATABASE_URL=postgres://USUARIO:SENHA@HOST:PORTA/defaultdb?sslmode=require

Depois rode:

python src/load.py

O load.py recria as tabelas do schema painel antes de carregar os CSVs tratados.

Para conferir a carga, rode o arquivo sql/consultas_verificacao.sql no DBeaver ou no pgAdmin.

Observação:

A razão de mortalidade materna ainda não é calculada nesta base, porque precisa dos dados de nascidos vivos do SINASC.
