variable "aiven_project" {
  description = "Nome do projeto no Aiven onde o banco fica"
  type        = string
  default     = "diego7k"
}

variable "service_name" {
  description = "Nome do serviço PostgreSQL no Aiven (não pode ser alterado depois de criado)"
  type        = string
  default     = "pg-3f45094b"
}

variable "cloud_name" {
  description = "Nuvem e região do serviço, como aparece no console do Aiven (ex.: do-nyc, aws-us-east-1)"
  type        = string
}

variable "plan" {
  description = "Plano do serviço. free-1-1gb é o plano gratuito (1 CPU, 1 GB de RAM, 1 GB de disco)"
  type        = string
  default     = "free-1-1gb"
}

variable "usuario_leitura" {
  description = "Usuário somente leitura que o painel vai usar nas próximas fases"
  type        = string
  default     = "painel_leitura"
}
