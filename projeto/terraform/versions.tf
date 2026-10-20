terraform {
  required_version = ">= 1.6"

  required_providers {
    aiven = {
      source  = "aiven/aiven"
      version = "~> 4.64"
    }
  }

  # O state fica local (terraform.tfstate) e NÃO vai para o Git, porque guarda
  # as senhas dos usuários do banco. Ver docs/SEGURANCA.md.
}

# O token da API do Aiven é lido da variável de ambiente AIVEN_TOKEN.
# Ele nunca é escrito em nenhum arquivo do repositório.
provider "aiven" {}
