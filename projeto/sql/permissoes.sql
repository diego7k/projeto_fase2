-- Rodar com o avnadmin depois do primeiro load.py.

GRANT USAGE ON SCHEMA painel TO painel_leitura;
GRANT SELECT ON ALL TABLES IN SCHEMA painel TO painel_leitura;
ALTER DEFAULT PRIVILEGES FOR ROLE avnadmin IN SCHEMA painel GRANT SELECT ON TABLES TO painel_leitura;

REVOKE CREATE ON SCHEMA public FROM PUBLIC;
