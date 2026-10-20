-- Permissões do usuário somente leitura do painel (criado pelo Terraform, terraform/main.tf).
-- Rodar uma vez com o avnadmin, depois do primeiro src/load.py.
-- O ALTER DEFAULT PRIVILEGES faz a permissão valer também para as tabelas
-- recriadas pelo load.py nas próximas cargas.

GRANT USAGE ON SCHEMA painel TO painel_leitura;
GRANT SELECT ON ALL TABLES IN SCHEMA painel TO painel_leitura;
ALTER DEFAULT PRIVILEGES FOR ROLE avnadmin IN SCHEMA painel GRANT SELECT ON TABLES TO painel_leitura;

-- o usuário de leitura não cria nada no schema public
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
