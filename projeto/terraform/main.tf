# Banco PostgreSQL gerenciado no Aiven, onde ficam as tabelas do schema painel
# (criadas e carregadas por src/load.py a partir de sql/schema.sql).
resource "aiven_pg" "painel" {
  project      = var.aiven_project
  service_name = var.service_name
  cloud_name   = var.cloud_name
  plan         = var.plan
}

# Usuário só de leitura para o painel. O avnadmin (criado pelo Aiven junto com o
# serviço) fica restrito à carga dos dados. A senha é gerada pelo Aiven.
# As permissões de SELECT são dadas por sql/permissoes.sql.
resource "aiven_pg_user" "leitura" {
  project      = aiven_pg.painel.project
  service_name = aiven_pg.painel.service_name
  username     = var.usuario_leitura
}
