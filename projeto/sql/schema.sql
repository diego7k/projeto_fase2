-- Painel de Mortalidade Materna - base tratada (OOBr, 2014 a 2024)
-- PostgreSQL no Aiven. O src/load.py roda este arquivo antes de carregar os CSVs.

CREATE SCHEMA IF NOT EXISTS painel;
SET search_path TO painel;

-- apaga o modelo antigo (fase anterior), se ainda existir no banco
DROP VIEW  IF EXISTS vw_obito_materno CASCADE;
DROP TABLE IF EXISTS fato_obitos_uf_idade, fato_perfil_obito, fato_garbage_code,
                     fato_obito_desconsiderado, fato_obito_materno,
                     dim_causa_cid10, dim_investigacao_cmm, dim_periodo_obito,
                     dim_tipo_morte, dim_raca_cor, dim_faixa_etaria,
                     dim_localidade, dim_tempo CASCADE;

DROP TABLE IF EXISTS obitos_maternos_oficiais, obitos_desconsiderados CASCADE;

-- Óbitos maternos oficiais (reconhecidos pelo Ministério da Saúde)
CREATE TABLE obitos_maternos_oficiais (
    id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cod_municipio       CHAR(6)      NOT NULL,   -- código IBGE, texto para não perder zeros
    municipio           VARCHAR(100) NOT NULL,
    uf                  CHAR(2)      NOT NULL,
    regiao              VARCHAR(20)  NOT NULL,
    ano                 SMALLINT     NOT NULL CHECK (ano BETWEEN 2014 AND 2024),
    preliminar          BOOLEAN      NOT NULL,   -- TRUE em 2024 (dados incompletos)
    cod_causa           VARCHAR(4)   NOT NULL,   -- CID-10 completo, ex.: O159
    cod_categoria       CHAR(3)      NOT NULL,   -- ex.: O15
    categoria_descricao VARCHAR(250) NOT NULL,   -- ex.: Eclâmpsia
    capitulo_cid10      VARCHAR(250) NOT NULL,
    tipo_morte_materna  VARCHAR(30)  NOT NULL,
    periodo_obito       VARCHAR(60)  NOT NULL,
    investigacao_cmm    VARCHAR(30)  NOT NULL,
    raca_cor            VARCHAR(20)  NOT NULL,
    idade               SMALLINT,                -- nula quando a idade veio como 99 (ignorada)
    faixa_etaria        VARCHAR(15)  NOT NULL,
    qtd_obitos          INTEGER      NOT NULL CHECK (qtd_obitos > 0)
);

-- Óbitos de grávidas e puérperas que não entram na contagem oficial (só 10 a 49 anos)
CREATE TABLE obitos_desconsiderados (
    id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cod_municipio       CHAR(6)      NOT NULL,
    municipio           VARCHAR(100) NOT NULL,
    uf                  CHAR(2)      NOT NULL,
    regiao              VARCHAR(20)  NOT NULL,
    ano                 SMALLINT     NOT NULL CHECK (ano BETWEEN 2014 AND 2024),
    preliminar          BOOLEAN      NOT NULL,
    cod_categoria       CHAR(3)      NOT NULL,
    categoria_descricao VARCHAR(250) NOT NULL,
    capitulo_cid10      VARCHAR(250) NOT NULL,
    periodo_obito       VARCHAR(60)  NOT NULL,
    investigacao_cmm    VARCHAR(30)  NOT NULL,
    raca_cor            VARCHAR(20)  NOT NULL,
    idade               SMALLINT CHECK (idade BETWEEN 10 AND 49),
    faixa_etaria        VARCHAR(15)  NOT NULL,
    qtd_obitos          INTEGER      NOT NULL CHECK (qtd_obitos > 0)
);

CREATE INDEX idx_oficiais_ano ON obitos_maternos_oficiais (ano);
CREATE INDEX idx_oficiais_uf  ON obitos_maternos_oficiais (uf);
CREATE INDEX idx_descons_ano  ON obitos_desconsiderados (ano);
CREATE INDEX idx_descons_uf   ON obitos_desconsiderados (uf);
