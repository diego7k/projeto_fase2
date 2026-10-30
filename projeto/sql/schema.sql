-- Rodado pelo src/load.py antes de cada carga.

CREATE SCHEMA IF NOT EXISTS painel;
SET search_path TO painel;

-- modelo antigo da fase anterior
DROP VIEW  IF EXISTS vw_obito_materno CASCADE;
DROP TABLE IF EXISTS fato_obitos_uf_idade, fato_perfil_obito, fato_garbage_code,
                     fato_obito_desconsiderado, fato_obito_materno,
                     dim_causa_cid10, dim_investigacao_cmm, dim_periodo_obito,
                     dim_tipo_morte, dim_raca_cor, dim_faixa_etaria,
                     dim_localidade, dim_tempo CASCADE;

DROP TABLE IF EXISTS obitos_maternos_oficiais, obitos_desconsiderados CASCADE;

CREATE TABLE obitos_maternos_oficiais (
    id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cod_municipio       CHAR(6)      NOT NULL,
    municipio           VARCHAR(100) NOT NULL,
    uf                  CHAR(2)      NOT NULL,
    regiao              VARCHAR(20)  NOT NULL,
    ano                 SMALLINT     NOT NULL CHECK (ano BETWEEN 2014 AND 2024),
    preliminar          BOOLEAN      NOT NULL,   -- 2024, dados incompletos
    cod_causa           VARCHAR(4)   NOT NULL,
    cod_categoria       CHAR(3)      NOT NULL,
    categoria_descricao VARCHAR(250) NOT NULL,
    capitulo_cid10      VARCHAR(250) NOT NULL,
    tipo_morte_materna  VARCHAR(30)  NOT NULL,
    periodo_obito       VARCHAR(60)  NOT NULL,
    investigacao_cmm    VARCHAR(30)  NOT NULL,
    raca_cor            VARCHAR(20)  NOT NULL,
    idade               SMALLINT,                -- nula = ignorada
    faixa_etaria        VARCHAR(15)  NOT NULL,
    qtd_obitos          INTEGER      NOT NULL CHECK (qtd_obitos > 0)
);

-- óbitos na gravidez/puerpério fora da contagem oficial
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
