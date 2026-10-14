"""
ETL - Painel de Mortalidade Materna (fonte: OOBR / Synapse, 1996-2024)
Lê data/raw/*.csv -> trata -> grava data/processed/*.csv (dimensões e fatos).
Uso (na raiz do projeto): python src/etl.py
"""
import pandas as pd
from pathlib import Path

RAW = Path("data/raw")
OUT = Path("data/processed")
OUT.mkdir(parents=True, exist_ok=True)
P = "dados_oobr_obitos_grav_puerp_"
SUF = "_1996_2024.csv"
log = []  # registro das decisões/contagens (vai para docs/log_etl.txt)


def say(msg):
    print(msg)
    log.append(msg)


def ler(nome):
    df = pd.read_csv(RAW / f"{P}{nome}{SUF}", dtype=str)
    say(f"[{nome}] original: {df.shape[0]} linhas x {df.shape[1]} colunas")
    return df


def limpar_texto(df):
    for c in df.columns:
        if not pd.api.types.is_numeric_dtype(df[c]):
            df[c] = df[c].str.strip()
    return df


ESTADO_CIVIL = {
    "Solteira": "Solteiro(a)", "Solteiro": "Solteiro(a)",
    "Casada": "Casado(a)", "Casado": "Casado(a)",
    "Viúva": "Viúvo(a)", "Viúvo": "Viúvo(a)",
    "Separada Judic./Divorciada": "Separado(a)/Divorciado(a)",
    "Separado Judic./Divorciado": "Separado(a)/Divorciado(a)",
}


def faixa_etaria(i):
    if i < 10:
        return "0 a 9"
    if i >= 50:
        return "50 ou mais"
    base = (i // 5) * 5
    return f"{base} a {base + 4}"


def base_comum(df):
    """Tipagem e padronização comuns a todos os arquivos."""
    df = df.drop(columns=["X"], errors="ignore")      # índice do R, sem valor
    df = limpar_texto(df)
    df["ano"] = df["ano"].astype(int)
    df["idade"] = df["idade"].astype(int)
    df["uf"] = df["uf"].str.upper()
    if "codigo" in df:
        df["codigo"] = df["codigo"].str.zfill(6)
    if "obitos" in df:
        df["obitos"] = df["obitos"].astype(int)
    df["faixa_etaria"] = df["idade"].map(faixa_etaria)
    return df


# ------------------------------------------------------------------ leitura
oficiais = base_comum(ler("maternos_oficiais"))
descons = base_comum(ler("desconsiderados"))
garbage = base_comum(ler("garbage_codes"))
perfil = base_comum(ler("analise_cruzada"))
ufs = limpar_texto(ler("ufs").drop(columns=["X"], errors="ignore"))

# ------------------------------------------------------------ tratamentos
# perfil (1 linha = 1 óbito): padronizar estado civil e preencher nulo
perfil["est_civil"] = perfil["est_civil"].replace(ESTADO_CIVIL)
nulos_nec = int(perfil["necropsia"].isna().sum())
perfil["necropsia"] = perfil["necropsia"].fillna("Ignorado")
say(f"[perfil] estado civil padronizado (variações de gênero): {perfil['est_civil'].nunique()} categorias; "
    f"necropsia nula -> 'Ignorado': {nulos_nec}")
dups = int(perfil.duplicated().sum())
say(f"[perfil] linhas idênticas MANTIDAS: {dups} (cada linha é um óbito; o total bate com os outros arquivos)")

# ufs: tipos
for c in ufs.columns:
    if c not in ("uf", "regiao"):
        ufs[c] = ufs[c].astype(int)
ufs["uf"] = ufs["uf"].str.upper()
# nomes originais passam de 63 caracteres (limite de identificador do PostgreSQL) -> encurtar
ufs = ufs.rename(columns={
    "obitos_descons_durante_a_gravidez_parto_ou_aborto_exceto_ext": "obitos_descons_gravidez_exceto_ext",
    "obitos_descons_durante_o_puerperio_ate_42_dias_exceto_ext": "obitos_descons_puerp_ate42d_exceto_ext",
    "obitos_descons_durante_o_puerperio_de_43_dias_a_menos_de_1_ano_exceto_ext": "obitos_descons_puerp_43d_1a_exceto_ext",
    "obitos_descons_periodo_inconsistente_exceto_ext": "obitos_descons_inconsistente_exceto_ext",
    "obitos_descons_durante_a_gravidez_parto_ou_aborto_ext": "obitos_descons_gravidez_ext",
    "obitos_descons_durante_o_puerperio_ate_42_dias_ext": "obitos_descons_puerp_ate42d_ext",
    "obitos_descons_durante_o_puerperio_de_43_dias_a_menos_de_1_ano_ext": "obitos_descons_puerp_43d_1a_ext",
    "obitos_descons_periodo_inconsistente_ext": "obitos_descons_inconsistente_ext",
})
ufs["faixa_etaria"] = ufs["idade"].map(faixa_etaria)

# ---------------------------------------------------------- dimensões
dim_tempo = pd.DataFrame({"ano": sorted(oficiais["ano"].unique())})
dim_tempo.insert(0, "id_tempo", range(1, len(dim_tempo) + 1))

loc = pd.concat([oficiais, descons, garbage, perfil])[["codigo", "municipio", "uf", "regiao"]].drop_duplicates()
loc = loc.sort_values("codigo").reset_index(drop=True)
loc["municipio_ignorado"] = loc["municipio"].str.contains("ignorado", case=False)
dim_localidade = loc.rename(columns={"codigo": "codigo_ibge"})
dim_localidade.insert(0, "id_localidade", range(1, len(dim_localidade) + 1))


def dim_simples(col, nome_id):
    vals = pd.concat([d[col] for d in (oficiais, descons, garbage, perfil) if col in d]).dropna().unique()
    d = pd.DataFrame({"descricao": sorted(vals)})
    d.insert(0, nome_id, range(1, len(d) + 1))
    return d


dim_raca_cor = dim_simples("racacor", "id_raca_cor")
dim_tipo_morte = dim_simples("tipo_de_morte_materna", "id_tipo_morte")
dim_periodo = dim_simples("periodo_do_obito", "id_periodo")
dim_investigacao = dim_simples("investigacao_cmm", "id_investigacao")

ordem_fx = sorted(oficiais["faixa_etaria"].unique(), key=lambda s: int(s.split()[0]))
dim_faixa = pd.DataFrame({"id_faixa_etaria": range(1, len(ordem_fx) + 1), "descricao": ordem_fx})

# causas: oficiais/garbage trazem o CID de 4 caracteres; desconsiderados só a categoria (3)
cols_c = ["causabas", "causabas_categoria", "capitulo_cid10"]
causas = pd.concat([oficiais[cols_c], garbage[cols_c]]).drop_duplicates("causabas")
causas_d = descons[["causabas_categoria", "capitulo_cid10"]].drop_duplicates("causabas_categoria").copy()
causas_d["causabas"] = causas_d["causabas_categoria"].str.split().str[0]
causas = pd.concat([causas, causas_d[cols_c]]).drop_duplicates("causabas").sort_values("causabas")
dim_causa = causas.reset_index(drop=True)
dim_causa.insert(0, "id_causa", range(1, len(dim_causa) + 1))
dim_causa = dim_causa.rename(columns={"causabas": "cid10", "causabas_categoria": "categoria_cid10"})

# mapas texto -> id
m_tempo = dict(zip(dim_tempo.ano, dim_tempo.id_tempo))
m_loc = dict(zip(dim_localidade.codigo_ibge, dim_localidade.id_localidade))
m_raca = dict(zip(dim_raca_cor.descricao, dim_raca_cor.id_raca_cor))
m_tipo = dict(zip(dim_tipo_morte.descricao, dim_tipo_morte.id_tipo_morte))
m_per = dict(zip(dim_periodo.descricao, dim_periodo.id_periodo))
m_inv = dict(zip(dim_investigacao.descricao, dim_investigacao.id_investigacao))
m_fx = dict(zip(dim_faixa.descricao, dim_faixa.id_faixa_etaria))
m_causa = dict(zip(dim_causa.cid10, dim_causa.id_causa))


def chaves(df):
    out = pd.DataFrame({
        "id_tempo": df["ano"].map(m_tempo),
        "id_localidade": df["codigo"].map(m_loc),
        "id_faixa_etaria": df["faixa_etaria"].map(m_fx),
        "id_raca_cor": df["racacor"].map(m_raca),
        "id_periodo": df["periodo_do_obito"].map(m_per),
        "id_investigacao": df["investigacao_cmm"].map(m_inv),
        "idade": df["idade"],
    })
    if "tipo_de_morte_materna" in df:
        out["id_tipo_morte"] = df["tipo_de_morte_materna"].map(m_tipo)
    return out


# ----------------------------------------------------------------- fatos
fato_oficial = chaves(oficiais)
fato_oficial["id_causa"] = oficiais["causabas"].map(m_causa)
fato_oficial["qtd_obitos"] = oficiais["obitos"]

fato_descons = chaves(descons)
fato_descons["id_causa"] = descons["causabas_categoria"].str.split().str[0].map(m_causa)
fato_descons["qtd_obitos"] = descons["obitos"]

fato_garbage = chaves(garbage)
fato_garbage["id_causa"] = garbage["causabas"].map(m_causa)
fato_garbage["qtd_obitos"] = garbage["obitos"]

fato_perfil = chaves(perfil)
for c in ["est_civil", "escolaridade", "local_ocorrencia_obito", "assistencia_med",
          "necropsia", "obito_em_idade_fertil", "capitulo_cid10"]:
    fato_perfil[c] = perfil[c]

cols_obitos = [c for c in ufs.columns if c.startswith("obitos")]
fato_uf = ufs.merge(dim_tempo, on="ano")
fato_uf["id_faixa_etaria"] = fato_uf["faixa_etaria"].map(m_fx)
fato_uf = fato_uf[["id_tempo", "uf", "regiao", "id_faixa_etaria", "idade"] + cols_obitos]

# -------------------------------------------------------------- validações
for nome, f in [("oficial", fato_oficial), ("descons", fato_descons),
                ("garbage", fato_garbage), ("perfil", fato_perfil)]:
    nul = f.filter(like="id_").isna().sum()
    assert nul.sum() == 0, f"chaves sem correspondência em {nome}:\n{nul[nul > 0]}"
tot_of = int(fato_oficial.qtd_obitos.sum())
assert tot_of == len(fato_perfil) == int(fato_uf.obitos_maternos.sum()), "totais de óbitos divergem"
say(f"[validação] óbitos maternos oficiais = {tot_of} (oficiais = perfil = ufs) -> OK")
tot_d = int(fato_descons.qtd_obitos.sum())
assert tot_d == int(fato_uf.filter(like="descons").sum().sum())
say(f"[validação] óbitos desconsiderados = {tot_d} (bate com a soma das colunas 'descons' do arquivo ufs) -> OK")
say(f"[qualidade] registros oficiais com idade < 10 anos: {int((oficiais['idade'] < 10).sum())} "
    f"(mantidos; ficam na faixa '0 a 9')")
say(f"[qualidade] municípios 'ignorados': {int(dim_localidade.municipio_ignorado.sum())} (um por UF, mantidos)")

# ------------------------------------------------------------------ saída
saidas = {
    "dim_tempo": dim_tempo, "dim_localidade": dim_localidade, "dim_faixa_etaria": dim_faixa,
    "dim_raca_cor": dim_raca_cor, "dim_tipo_morte": dim_tipo_morte, "dim_periodo_obito": dim_periodo,
    "dim_investigacao_cmm": dim_investigacao, "dim_causa_cid10": dim_causa,
    "fato_obito_materno": fato_oficial, "fato_obito_desconsiderado": fato_descons,
    "fato_garbage_code": fato_garbage, "fato_perfil_obito": fato_perfil, "fato_obitos_uf_idade": fato_uf,
}
for nome, df in saidas.items():
    df.to_csv(OUT / f"{nome}.csv", index=False)
    say(f"[saída] {nome}.csv: {len(df)} linhas x {df.shape[1]} colunas")

Path("docs").mkdir(exist_ok=True)
Path("docs/log_etl.txt").write_text("\n".join(log), encoding="utf-8")
