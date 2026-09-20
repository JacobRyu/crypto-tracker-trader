variable "cluster_name" {
  description = "Name of the kind cluster"
  type        = string
  default     = "ctt-cluster"
}

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "ctt-dev"
}

variable "postgres_db" {
  description = "PostgreSQL database name"
  type        = string
  default     = "crypto"
}

variable "postgres_user" {
  description = "PostgreSQL user"
  type        = string
  default     = "ctt"
}

variable "postgres_password" {
  description = "PostgreSQL password"
  type        = string
  default     = "password"
  sensitive   = true
}

variable "app_port" {
  description = "Application port"
  type        = number
  default     = 8080
}

variable "jwt_secret" {
  description = "JWT secret key"
  type        = string
  default     = "dev-jwt-secret-key-change-in-production"
  sensitive   = true
}

variable "encryption_key" {
  description = "AES-256 encryption key (64 hex chars)"
  type        = string
  default     = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
  sensitive   = true
}

variable "ethereum_node_url" {
  description = "Ethereum node URL"
  type        = string
  default     = "https://eth.llamarpc.com"
}

variable "redis_port" {
  description = "Redis port"
  type        = number
  default     = 6379
}

variable "kafka_port" {
  description = "Kafka port"
  type        = number
  default     = 9092
}

variable "prometheus_port" {
  description = "Prometheus port"
  type        = number
  default     = 9090
}

variable "grafana_port" {
  description = "Grafana port"
  type        = number
  default     = 3000
}
