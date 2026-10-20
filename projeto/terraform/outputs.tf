output "host" {
  value = aiven_pg.painel.service_host
}

output "porta" {
  value = aiven_pg.painel.service_port
}

output "banco" {
  value = "defaultdb"
}

# Conexão do avnadmin, usada pelo src/load.py. Marcada como sensível para não
# aparecer no terminal; para gerar o .env:
#   echo "DATABASE_URL=$(terraform output -raw database_url)" > ../../.env
output "database_url" {
  value     = "postgres://${aiven_pg.painel.service_username}:${aiven_pg.painel.service_password}@${aiven_pg.painel.service_host}:${aiven_pg.painel.service_port}/defaultdb?sslmode=require"
  sensitive = true
}

# Conexão do usuário somente leitura, para o painel.
output "database_url_leitura" {
  value     = "postgres://${aiven_pg_user.leitura.username}:${aiven_pg_user.leitura.password}@${aiven_pg.painel.service_host}:${aiven_pg.painel.service_port}/defaultdb?sslmode=require"
  sensitive = true
}
