"""
Carga no PostgreSQL (Aiven): cria as tabelas (sql/schema.sql) e carrega data/processed/*.csv
Antes: pip install psycopg2-binary python-dotenv
Crie um arquivo .env (NÃO suba no GitHub) com:
    DATABASE_URL=postgres://USUARIO:SENHA@HOST:PORTA/defaultdb?sslmode=require
Uso (na raiz do projeto): python src/load.py
"""
import os
from pathlib import Path
import psycopg2

try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass

PROC = Path("data/processed")
# ordem importa: dimensões primeiro (chaves estrangeiras)
TABELAS = [
    "dim_tempo", "dim_localidade", "dim_faixa_etaria", "dim_raca_cor", "dim_tipo_morte",
    "dim_periodo_obito", "dim_investigacao_cmm", "dim_causa_cid10",
    "fato_obito_materno", "fato_obito_desconsiderado", "fato_garbage_code",
    "fato_perfil_obito", "fato_obitos_uf_idade",
]

conn = psycopg2.connect(os.environ["DATABASE_URL"])
cur = conn.cursor()

cur.execute(Path("sql/schema.sql").read_text(encoding="utf-8"))
print("Estrutura criada.")
cur.execute("SET search_path TO painel")

for t in TABELAS:
    arq = PROC / f"{t}.csv"
    colunas = arq.open(encoding="utf-8").readline().strip()
    with arq.open(encoding="utf-8") as f:
        cur.copy_expert(f"COPY {t} ({colunas}) FROM STDIN WITH (FORMAT csv, HEADER true)", f)
    cur.execute(f"SELECT COUNT(*) FROM {t}")
    print(f"{t}: {cur.fetchone()[0]} linhas")

conn.commit()
cur.execute("SELECT pg_size_pretty(pg_database_size(current_database()))")
print("Tamanho do banco:", cur.fetchone()[0])
cur.close()
conn.close()
