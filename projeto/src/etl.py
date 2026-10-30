# Tratamento dos óbitos maternos oficiais e desconsiderados do OOBr (2014 a 2024).
# Rodar de dentro de projeto/: python src/etl.py
import hashlib
from pathlib import Path

import pandas as pd

RAW = Path("data/raw")
OUT = Path("data/processed")
ANO_INICIO, ANO_FIM = 2014, 2024
ANO_PRELIMINAR = 2024  # dados de 2024 ainda incompletos (versão de fev/2025)

log = []


def registrar(msg):
    print(msg)
    log.append(msg)


def arquivo(nome):
    return RAW / f"dados_oobr_obitos_grav_puerp_{nome}_1996_2024.csv"


def conferir_md5():
    manifest = pd.read_csv(RAW / "manifest.csv")
    for _, linha in manifest.iterrows():
        md5 = hashlib.md5((RAW / linha["name"]).read_bytes()).hexdigest()
        ok = "OK" if md5 == linha["dataFileMD5Hex"] else "DIFERENTE"
        registrar(f"md5 {linha['name']} (versão {linha['versionNumber']}): {ok}")


def conferir_redundancia(oficiais):
    # ufs e garbage_codes ficaram de fora porque repetem os oficiais
    ufs = pd.read_csv(arquivo("ufs"))
    registrar(f"soma de obitos_maternos no arquivo ufs: {ufs['obitos_maternos'].sum()} "
              f"(oficiais: {oficiais['obitos'].sum()})")
    garbage = pd.read_csv(arquivo("garbage_codes"), dtype=str).drop(columns="X")
    chaves = list(garbage.columns)
    junto = garbage.merge(oficiais.drop(columns="X").astype(str), on=chaves, how="left", indicator=True)
    registrar(f"linhas do garbage_codes que não estão nos oficiais: {(junto['_merge'] != 'both').sum()}")


def ler(nome):
    df = pd.read_csv(arquivo(nome), dtype=str)
    df["ano"] = df["ano"].astype(int)
    df["idade"] = df["idade"].astype(int)
    df["obitos"] = df["obitos"].astype(int)
    registrar(f"[{nome}] original: {len(df)} linhas, {df['obitos'].sum()} óbitos")
    return df


def faixa_etaria(idade):
    if pd.isna(idade):
        return "Ignorada"
    idade = int(idade)
    if idade >= 50:
        return "50 ou mais"
    inicio = idade // 5 * 5
    return f"{inicio} a {inicio + 4}"


def tratar(df, nome):
    df = df[df["ano"].between(ANO_INICIO, ANO_FIM)].copy()
    registrar(f"[{nome}] recorte {ANO_INICIO}-{ANO_FIM}: {len(df)} linhas, {df['obitos'].sum()} óbitos")

    # X é só o número da linha na exportação
    df = df.drop(columns="X")

    for col in df.columns:
        if pd.api.types.is_string_dtype(df[col]):
            df[col] = df[col].str.strip().str.replace(r"\s+", " ", regex=True)

    # "O15 Eclâmpsia" -> O15 / Eclâmpsia
    partes = df["causabas_categoria"].str.split(" ", n=1)
    df["cod_categoria"] = partes.str[0]
    df["categoria_descricao"] = partes.str[1]

    # 99 = idade ignorada no SIM
    registrar(f"[{nome}] idade 99 passou a nula: {(df['idade'] == 99).sum()}")
    df["idade"] = df["idade"].astype("Int64").mask(df["idade"] == 99)

    df["preliminar"] = df["ano"] == ANO_PRELIMINAR
    df["faixa_etaria"] = df["idade"].map(faixa_etaria)

    registrar(f"[{nome}] Sem informação na investigação do CMM: "
              f"{df.loc[df['investigacao_cmm'] == 'Sem informação', 'obitos'].sum()} óbitos")
    registrar(f"[{nome}] período do óbito não informado: "
              f"{df.loc[df['periodo_do_obito'] == 'Não informado ou ignorado', 'obitos'].sum()} óbitos")
    registrar(f"[{nome}] raça/cor ignorada: {df.loc[df['racacor'] == 'Ignorado', 'obitos'].sum()} óbitos")
    registrar(f"[{nome}] município ignorado: {df['municipio'].str.contains('ignorado', case=False).sum()} linhas")
    registrar(f"[{nome}] linhas duplicadas: {df.duplicated().sum()}")

    return df.rename(columns={
        "codigo": "cod_municipio",
        "causabas": "cod_causa",
        "tipo_de_morte_materna": "tipo_morte_materna",
        "periodo_do_obito": "periodo_obito",
        "racacor": "raca_cor",
        "obitos": "qtd_obitos",
    })


COLUNAS = [
    "cod_municipio", "municipio", "uf", "regiao", "ano", "preliminar",
    "cod_causa", "cod_categoria", "categoria_descricao", "capitulo_cid10",
    "tipo_morte_materna", "periodo_obito", "investigacao_cmm",
    "raca_cor", "idade", "faixa_etaria", "qtd_obitos",
]

conferir_md5()

oficiais_bruto = ler("maternos_oficiais")
descons_bruto = ler("desconsiderados")
conferir_redundancia(oficiais_bruto)

oficiais = tratar(oficiais_bruto, "oficiais")
# nos oficiais as idades acima de 49 ficam, porque contam no número oficial
registrar(f"[oficiais] óbitos com 50 anos ou mais (mantidos): "
          f"{oficiais.loc[oficiais['idade'] >= 50, 'qtd_obitos'].sum()}")

descons = tratar(descons_bruto, "desconsiderados")
# menores de 10 são quase sempre bebês marcados como gestação por engano
menor_10 = (descons["idade"] < 10).fillna(False)
maior_49 = (descons["idade"] > 49).fillna(False)
registrar(f"[desconsiderados] removidos com menos de 10 anos: {descons.loc[menor_10, 'qtd_obitos'].sum()} óbitos")
registrar(f"[desconsiderados] removidos com 50 anos ou mais: {descons.loc[maior_49, 'qtd_obitos'].sum()} óbitos "
          f"(idade máxima {descons['idade'].max()})")
descons = descons[~(menor_10 | maior_49)]

colunas_descons = [c for c in COLUNAS if c not in ("cod_causa", "tipo_morte_materna")]
saidas = {
    "obitos_maternos_oficiais_tratado_2014_2024.csv": oficiais[COLUNAS],
    "obitos_desconsiderados_tratado_2014_2024.csv": descons[colunas_descons],
}

OUT.mkdir(parents=True, exist_ok=True)
for nome_arquivo, df in saidas.items():
    caminho = OUT / nome_arquivo
    df.to_csv(caminho, index=False, encoding="utf-8")
    registrar(f"{nome_arquivo}: {len(df)} linhas, {df['qtd_obitos'].sum()} óbitos, "
              f"{df.shape[1]} colunas, {caminho.stat().st_size / 1e6:.1f} MB")

Path("docs").mkdir(exist_ok=True)
Path("docs/log_etl.txt").write_text("\n".join(log) + "\n", encoding="utf-8")
