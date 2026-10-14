# Painel de Mortalidade Materna - Fase 2

Estrutura:
- `data/raw/` dados originais (OOBR/Synapse) | `data/processed/` dados tratados
- `src/etl.py` tratamento | `src/load.py` carga no PostgreSQL (Aiven)
- `sql/schema.sql` estrutura do banco | `sql/consultas_verificacao.sql` consultas para os prints
- `docs/DECISOES.md` decisões e justificativas | `docs/log_etl.txt` log gerado pelo ETL

Como rodar:
1. `pip install pandas psycopg2-binary python-dotenv`
2. `python src/etl.py`
3. Criar `.env` com `DATABASE_URL=postgres://USUARIO:SENHA@HOST:PORTA/defaultdb?sslmode=require` (do Aiven)
4. `python src/load.py`
5. Rodar `sql/consultas_verificacao.sql` no DBeaver/pgAdmin e tirar os prints
