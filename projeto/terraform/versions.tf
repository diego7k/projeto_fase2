terraform {
  required_version = ">= 1.6"

  required_providers {
    aiven = {
      source  = "aiven/aiven"
      version = "~> 4.64"
    }
  }
}

# token na variável de ambiente AIVEN_TOKEN
provider "aiven" {}
