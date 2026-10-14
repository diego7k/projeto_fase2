-- =====================================================================
-- Painel de Mortalidade Materna (OOBR 1996-2024) - modelo estrela
-- PostgreSQL (Aiven). Rode ANTES de src/load.py
-- =====================================================================
CREATE SCHEMA IF NOT EXISTS painel;
SET search_path TO painel;

DROP VIEW  IF EXISTS vw_obito_materno CASCADE;
DROP TABLE IF EXISTS fato_obitos_uf_idade, fato_perfil_obito, fato_garbage_code,
                     fato_obito_desconsiderado, fato_obito_materno,
                     dim_causa_cid10, dim_investigacao_cmm, dim_periodo_obito,
                     dim_tipo_morte, dim_raca_cor, dim_faixa_etaria,
                     dim_localidade, dim_tempo CASCADE;

-- ------------------------------ DIMENSÕES ------------------------------
CREATE TABLE dim_tempo (
    id_tempo   INTEGER PRIMARY KEY,
    ano        INTEGER NOT NULL UNIQUE CHECK (ano BETWEEN 1996 AND 2100)
);

CREATE TABLE dim_localidade (
    id_localidade      INTEGER PRIMARY KEY,
    codigo_ibge        CHAR(6)      NOT NULL UNIQUE,
    municipio          VARCHAR(100) NOT NULL,
    uf                 CHAR(2)      NOT NULL,
    regiao             VARCHAR(20)  NOT NULL,
    municipio_ignorado BOOLEAN      NOT NULL DEFAULT FALSE
);

CREATE TABLE dim_faixa_etaria (
    id_faixa_etaria INTEGER PRIMARY KEY,
    descricao       VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE dim_raca_cor (
    id_raca_cor INTEGER PRIMARY KEY,
    descricao   VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE dim_tipo_morte (
    id_tipo_morte INTEGER PRIMARY KEY,
    descricao     VARCHAR(30) NOT NULL UNIQUE      -- Direta / Indireta / Não especificada
);

CREATE TABLE dim_periodo_obito (
    id_periodo INTEGER PRIMARY KEY,
    descricao  VARCHAR(60) NOT NULL UNIQUE
);

CREATE TABLE dim_investigacao_cmm (
    id_investigacao INTEGER PRIMARY KEY,
    descricao       VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE dim_causa_cid10 (
    id_causa        INTEGER PRIMARY KEY,
    cid10           VARCHAR(10)  NOT NULL UNIQUE,
    categoria_cid10 VARCHAR(250) NOT NULL,
    capitulo_cid10  VARCHAR(250) NOT NULL
);

-- ------------------------------- FATOS ---------------------------------
-- Óbitos maternos oficiais (agregados por município/ano/causa/idade/raça...)
CREATE TABLE fato_obito_materno (
    id_fato         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_tempo        INTEGER  NOT NULL REFERENCES dim_tempo,
    id_localidade   INTEGER  NOT NULL REFERENCES dim_localidade,
    id_faixa_etaria INTEGER  NOT NULL REFERENCES dim_faixa_etaria,
    id_raca_cor     INTEGER  NOT NULL REFERENCES dim_raca_cor,
    id_periodo      INTEGER  NOT NULL REFERENCES dim_periodo_obito,
    id_investigacao INTEGER  NOT NULL REFERENCES dim_investigacao_cmm,
    idade           SMALLINT NOT NULL CHECK (idade BETWEEN 0 AND 120),
    id_tipo_morte   INTEGER  NOT NULL REFERENCES dim_tipo_morte,
    id_causa        INTEGER  NOT NULL REFERENCES dim_causa_cid10,
    qtd_obitos      INTEGER  NOT NULL CHECK (qtd_obitos > 0)
);

-- Óbitos de mulheres em idade fértil desconsiderados da contagem oficial
CREATE TABLE fato_obito_desconsiderado (
    id_fato         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_tempo        INTEGER  NOT NULL REFERENCES dim_tempo,
    id_localidade   INTEGER  NOT NULL REFERENCES dim_localidade,
    id_faixa_etaria INTEGER  NOT NULL REFERENCES dim_faixa_etaria,
    id_raca_cor     INTEGER  NOT NULL REFERENCES dim_raca_cor,
    id_periodo      INTEGER  NOT NULL REFERENCES dim_periodo_obito,
    id_investigacao INTEGER  NOT NULL REFERENCES dim_investigacao_cmm,
    idade           SMALLINT NOT NULL CHECK (idade BETWEEN 0 AND 120),
    id_causa        INTEGER  NOT NULL REFERENCES dim_causa_cid10,
    qtd_obitos      INTEGER  NOT NULL CHECK (qtd_obitos > 0)
);

-- Causas "garbage codes" (causas mal definidas) entre os óbitos maternos
CREATE TABLE fato_garbage_code (
    id_fato         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_tempo        INTEGER  NOT NULL REFERENCES dim_tempo,
    id_localidade   INTEGER  NOT NULL REFERENCES dim_localidade,
    id_faixa_etaria INTEGER  NOT NULL REFERENCES dim_faixa_etaria,
    id_raca_cor     INTEGER  NOT NULL REFERENCES dim_raca_cor,
    id_periodo      INTEGER  NOT NULL REFERENCES dim_periodo_obito,
    id_investigacao INTEGER  NOT NULL REFERENCES dim_investigacao_cmm,
    idade           SMALLINT NOT NULL CHECK (idade BETWEEN 0 AND 120),
    id_tipo_morte   INTEGER  NOT NULL REFERENCES dim_tipo_morte,
    id_causa        INTEGER  NOT NULL REFERENCES dim_causa_cid10,
    qtd_obitos      INTEGER  NOT NULL CHECK (qtd_obitos > 0)
);

-- Perfil sociodemográfico: 1 linha = 1 óbito materno
CREATE TABLE fato_perfil_obito (
    id_fato                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_tempo               INTEGER  NOT NULL REFERENCES dim_tempo,
    id_localidade          INTEGER  NOT NULL REFERENCES dim_localidade,
    id_faixa_etaria        INTEGER  NOT NULL REFERENCES dim_faixa_etaria,
    id_raca_cor            INTEGER  NOT NULL REFERENCES dim_raca_cor,
    id_periodo             INTEGER  NOT NULL REFERENCES dim_periodo_obito,
    id_investigacao        INTEGER  NOT NULL REFERENCES dim_investigacao_cmm,
    idade                  SMALLINT NOT NULL CHECK (idade BETWEEN 0 AND 120),
    id_tipo_morte          INTEGER  NOT NULL REFERENCES dim_tipo_morte,
    est_civil              VARCHAR(30) NOT NULL,
    escolaridade           VARCHAR(30) NOT NULL,
    local_ocorrencia_obito VARCHAR(30) NOT NULL,
    assistencia_med        VARCHAR(30) NOT NULL,
    necropsia              VARCHAR(10) NOT NULL,
    obito_em_idade_fertil  VARCHAR(5)  NOT NULL,
    capitulo_cid10         VARCHAR(250) NOT NULL
);

-- Resumo por UF/ano/idade (inclui todas as categorias de óbitos desconsiderados)
-- "ext" = por causas externas; nomes encurtados (limite de 63 caracteres do PostgreSQL)
CREATE TABLE fato_obitos_uf_idade (
    id_fato          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_tempo         INTEGER  NOT NULL REFERENCES dim_tempo,
    uf               CHAR(2)  NOT NULL,
    regiao           VARCHAR(20) NOT NULL,
    id_faixa_etaria  INTEGER  NOT NULL REFERENCES dim_faixa_etaria,
    idade            SMALLINT NOT NULL,
    obitos_maternos                          INTEGER NOT NULL,
    obitos_descons_gravidez_exceto_ext       INTEGER NOT NULL,
    obitos_descons_puerp_ate42d_exceto_ext   INTEGER NOT NULL,
    obitos_descons_puerp_43d_1a_exceto_ext   INTEGER NOT NULL,
    obitos_descons_inconsistente_exceto_ext  INTEGER NOT NULL,
    obitos_descons_gravidez_ext              INTEGER NOT NULL,
    obitos_descons_puerp_ate42d_ext          INTEGER NOT NULL,
    obitos_descons_puerp_43d_1a_ext          INTEGER NOT NULL,
    obitos_descons_inconsistente_ext         INTEGER NOT NULL,
    CONSTRAINT uq_uf_ano_idade UNIQUE (id_tempo, uf, idade)
);

-- ------------------------------ ÍNDICES --------------------------------
CREATE INDEX idx_fom_tempo  ON fato_obito_materno (id_tempo);
CREATE INDEX idx_fom_local  ON fato_obito_materno (id_localidade);
CREATE INDEX idx_fom_causa  ON fato_obito_materno (id_causa);
CREATE INDEX idx_fom_raca   ON fato_obito_materno (id_raca_cor);
CREATE INDEX idx_fod_tempo  ON fato_obito_desconsiderado (id_tempo);
CREATE INDEX idx_fod_local  ON fato_obito_desconsiderado (id_localidade);
CREATE INDEX idx_fpo_tempo  ON fato_perfil_obito (id_tempo);
CREATE INDEX idx_fpo_local  ON fato_perfil_obito (id_localidade);
CREATE INDEX idx_loc_uf     ON dim_localidade (uf);

-- ------------------------------- VIEW ----------------------------------
CREATE VIEW vw_obito_materno AS
SELECT t.ano, l.regiao, l.uf, l.municipio, f.descricao AS faixa_etaria,
       r.descricao AS raca_cor, tm.descricao AS tipo_morte,
       p.descricao AS periodo_obito, c.cid10, c.categoria_cid10,
       c.capitulo_cid10, m.idade, m.qtd_obitos
FROM fato_obito_materno m
JOIN dim_tempo t           ON t.id_tempo = m.id_tempo
JOIN dim_localidade l      ON l.id_localidade = m.id_localidade
JOIN dim_faixa_etaria f    ON f.id_faixa_etaria = m.id_faixa_etaria
JOIN dim_raca_cor r        ON r.id_raca_cor = m.id_raca_cor
JOIN dim_tipo_morte tm     ON tm.id_tipo_morte = m.id_tipo_morte
JOIN dim_periodo_obito p   ON p.id_periodo = m.id_periodo
JOIN dim_causa_cid10 c     ON c.id_causa = m.id_causa;
