# O serviço foi criado pelo console do Aiven antes do Terraform. Este bloco traz
# o serviço existente para o state no primeiro "terraform apply", em vez de
# tentar criar outro. Se o banco for criado do zero, este arquivo pode ser apagado.
import {
  to = aiven_pg.painel
  id = "${var.aiven_project}/${var.service_name}"
}
