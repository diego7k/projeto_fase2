# Painel Epidemiológico de Mortalidade Materna e Violência Obstétrica

Trabalho de Big Data & Analytics, 2ª entrega (base de dados tratada).
Alunos: Diego Gabriel Pinheiro Damasceno e Flávia Rodrigues Santos Silva. Professora: Sheila Tirony.

Os dados são do Observatório Obstétrico Brasileiro (OOBr), que processa o SIM do Ministério da Saúde e publica as bases no Synapse. Usamos dois dos cinco arquivos (óbitos maternos oficiais e óbitos desconsiderados), de 2014 a 2024.

Resultado final:

- `obitos_maternos_oficiais_tratado_2014_2024.csv`: 18.457 linhas, 18.534 óbitos, 17 colunas
- `obitos_desconsiderados_tratado_2014_2024.csv`: 10.270 linhas, 10.323 óbitos, 15 colunas

## Pastas

```
data/raw/         arquivos originais do OOBr (versão 4) e o manifest.csv, sem alteração
data/processed/   os dois CSVs tratados
src/etl.py        tratamento dos dados
src/load.py       carga no PostgreSQL (Aiven)
sql/schema.sql    criação das tabelas
sql/consultas_verificacao.sql   consultas usadas para conferir a carga
docs/DECISOES.md  decisões de tratamento e o motivo de cada uma
docs/log_etl.txt  contagens geradas pelo etl.py
```

## Como rodar

Todos os comandos são rodados dentro da pasta `projeto/`.

```
pip install pandas psycopg2-binary python-dotenv
python src/etl.py
```

Para a carga, crie um arquivo `.env` com a conexão do Aiven (esse arquivo não deve ir para o GitHub):

```
DATABASE_URL=postgres://USUARIO:SENHA@HOST:PORTA/defaultdb?sslmode=require
```

Depois:

```
python src/load.py
```

O `load.py` apaga e recria as tabelas do schema `painel` antes de carregar. Para conferir, rode `sql/consultas_verificacao.sql` no DBeaver ou no pgAdmin.

## Observações

- 2024 está marcado como `preliminar = true`, porque tem só 745 óbitos oficiais e os arquivos foram atualizados em fevereiro de 2025.
- A razão de mortalidade materna ainda não dá para calcular, porque precisa dos nascidos vivos do SINASC, que vamos incluir depois.
