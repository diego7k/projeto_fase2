resource "aiven_pg" "painel" {
  project      = var.aiven_project
  service_name = var.service_name
  cloud_name   = var.cloud_name
  plan         = var.plan
}

# permissões em sql/permissoes.sql
resource "aiven_pg_user" "leitura" {
  project      = aiven_pg.painel.project
  service_name = aiven_pg.painel.service_name
  username     = var.usuario_leitura
}
