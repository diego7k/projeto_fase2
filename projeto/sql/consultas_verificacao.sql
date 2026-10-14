SET search_path TO painel;

-- 1) Linhas e óbitos por tabela
-- esperado: oficiais 18457 linhas / 18534 óbitos; desconsiderados 10270 linhas / 10323 óbitos
SELECT 'obitos_maternos_oficiais' AS tabela, COUNT(*) AS linhas, SUM(qtd_obitos) AS obitos
FROM obitos_maternos_oficiais
UNION ALL
SELECT 'obitos_desconsiderados', COUNT(*), SUM(qtd_obitos)
FROM obitos_desconsiderados;

-- 2) Tamanho das tabelas e do banco (limite de 1 GB no plano gratuito do Aiven)
SELECT relname AS tabela, pg_size_pretty(pg_total_relation_size(relid)) AS tamanho
FROM pg_stat_user_tables WHERE schemaname = 'painel'
ORDER BY pg_total_relation_size(relid) DESC;

SELECT pg_size_pretty(pg_database_size(current_database())) AS tamanho_banco;

-- 3) Colunas e tipos
SELECT table_name, column_name, data_type, character_maximum_length, is_nullable
FROM information_schema.columns WHERE table_schema = 'painel'
ORDER BY table_name, ordinal_position;

-- 4) Óbitos por ano nos dois conjuntos (2024 marcado como preliminar)
SELECT COALESCE(o.ano, d.ano) AS ano, o.obitos AS oficiais, d.obitos AS desconsiderados,
       COALESCE(o.preliminar, d.preliminar) AS preliminar
FROM (SELECT ano, preliminar, SUM(qtd_obitos) AS obitos FROM obitos_maternos_oficiais GROUP BY ano, preliminar) o
FULL JOIN (SELECT ano, preliminar, SUM(qtd_obitos) AS obitos FROM obitos_desconsiderados GROUP BY ano, preliminar) d
  ON d.ano = o.ano
ORDER BY ano;

-- 5) Óbitos maternos oficiais por região e faixa etária
SELECT regiao, faixa_etaria, SUM(qtd_obitos) AS obitos
FROM obitos_maternos_oficiais
GROUP BY regiao, faixa_etaria
ORDER BY regiao, faixa_etaria;

-- 6) Quanto falta de informação (qualidade do registro)
SELECT 'investigação CMM sem informação' AS item, SUM(qtd_obitos) AS obitos
FROM obitos_maternos_oficiais WHERE investigacao_cmm = 'Sem informação'
UNION ALL
SELECT 'período do óbito não informado', SUM(qtd_obitos)
FROM obitos_maternos_oficiais WHERE periodo_obito = 'Não informado ou ignorado'
UNION ALL
SELECT 'raça/cor ignorada', SUM(qtd_obitos)
FROM obitos_maternos_oficiais WHERE raca_cor = 'Ignorado';
