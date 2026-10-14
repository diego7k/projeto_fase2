"""
Carga no PostgreSQL (Aiven): cria as tabelas com sql/schema.sql e carrega os dois CSVs tratados.

Precisa de um .env (que não vai para o GitHub) com:
    DATABASE_URL=postgres://USUARIO:SENHA@HOST:PORTA/defaultdb?sslmode=require

Rodar a partir da pasta projeto/:  python src/load.py
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
TABELAS = {
    "obitos_maternos_oficiais": "obitos_maternos_oficiais_tratado_2014_2024.csv",
    "obitos_desconsiderados": "obitos_desconsiderados_tratado_2014_2024.csv",
}

conn = psycopg2.connect(os.environ["DATABASE_URL"])
cur = conn.cursor()

cur.execute(Path("sql/schema.sql").read_text(encoding="utf-8"))
print("Tabelas criadas.")

for tabela, nome_arquivo in TABELAS.items():
    arq = PROC / nome_arquivo
    with arq.open(encoding="utf-8") as f:
        colunas = f.readline().strip()
        f.seek(0)
        cur.copy_expert(f"COPY {tabela} ({colunas}) FROM STDIN WITH (FORMAT csv, HEADER true)", f)
    cur.execute(f"SELECT COUNT(*), SUM(qtd_obitos) FROM {tabela}")
    linhas, obitos = cur.fetchone()
    print(f"{tabela}: {linhas} linhas, {obitos} óbitos")

conn.commit()
cur.execute("SELECT pg_size_pretty(pg_database_size(current_database()))")
print("Tamanho do banco:", cur.fetchone()[0])
cur.close()
conn.close()
