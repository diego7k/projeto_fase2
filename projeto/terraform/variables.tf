variable "aiven_project" {
  description = "Projeto no Aiven"
  type        = string
  default     = "diego7k"
}

variable "service_name" {
  description = "Nome do serviço PostgreSQL"
  type        = string
  default     = "pg-3f45094b"
}

variable "cloud_name" {
  description = "Nuvem e região, ex.: do-nyc"
  type        = string
}

variable "plan" {
  description = "Plano do serviço (free-1-1gb é o gratuito)"
  type        = string
  default     = "free-1-1gb"
}

variable "usuario_leitura" {
  description = "Usuário somente leitura do painel"
  type        = string
  default     = "painel_leitura"
}
