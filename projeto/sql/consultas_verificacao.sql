SET search_path TO painel;

-- 1) Quantidade de linhas por tabela (print para a entrega)
SELECT 'dim_tempo' AS tabela, COUNT(*) AS linhas FROM dim_tempo
UNION ALL SELECT 'dim_localidade', COUNT(*) FROM dim_localidade
UNION ALL SELECT 'dim_faixa_etaria', COUNT(*) FROM dim_faixa_etaria
UNION ALL SELECT 'dim_raca_cor', COUNT(*) FROM dim_raca_cor
UNION ALL SELECT 'dim_tipo_morte', COUNT(*) FROM dim_tipo_morte
UNION ALL SELECT 'dim_periodo_obito', COUNT(*) FROM dim_periodo_obito
UNION ALL SELECT 'dim_investigacao_cmm', COUNT(*) FROM dim_investigacao_cmm
UNION ALL SELECT 'dim_causa_cid10', COUNT(*) FROM dim_causa_cid10
UNION ALL SELECT 'fato_obito_materno', COUNT(*) FROM fato_obito_materno
UNION ALL SELECT 'fato_obito_desconsiderado', COUNT(*) FROM fato_obito_desconsiderado
UNION ALL SELECT 'fato_garbage_code', COUNT(*) FROM fato_garbage_code
UNION ALL SELECT 'fato_perfil_obito', COUNT(*) FROM fato_perfil_obito
UNION ALL SELECT 'fato_obitos_uf_idade', COUNT(*) FROM fato_obitos_uf_idade;

-- 2) Tamanho por tabela e do banco (limite do Aiven Free: 1 GB)
SELECT relname AS tabela, pg_size_pretty(pg_total_relation_size(relid)) AS tamanho
FROM pg_stat_user_tables WHERE schemaname = 'painel'
ORDER BY pg_total_relation_size(relid) DESC;
SELECT pg_size_pretty(pg_database_size(current_database())) AS tamanho_banco;

-- 3) Colunas e tipos (documentar estrutura)
SELECT table_name, column_name, data_type, character_maximum_length
FROM information_schema.columns WHERE table_schema = 'painel'
ORDER BY table_name, ordinal_position;

-- 4) Validação: total de óbitos maternos deve ser 48933 nas três tabelas
SELECT (SELECT SUM(qtd_obitos) FROM fato_obito_materno)   AS oficiais,
       (SELECT COUNT(*)        FROM fato_perfil_obito)     AS perfil,
       (SELECT SUM(obitos_maternos) FROM fato_obitos_uf_idade) AS ufs;

-- 5) Exemplo de indicador: óbitos maternos por ano e região
SELECT ano, regiao, SUM(qtd_obitos) AS obitos
FROM vw_obito_materno GROUP BY ano, regiao ORDER BY ano, regiao;
