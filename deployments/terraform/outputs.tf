output "cluster_name" {
  description = "Name of the kind cluster"
  value       = kind_cluster.ctt-cluster.name
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint"
  value       = kind_cluster.ctt-cluster.endpoint
  sensitive   = true
}

output "namespace" {
  description = "Kubernetes namespace"
  value       = kubernetes_namespace.ctt.metadata[0].name
}

output "app_url" {
  description = "Application URL"
  value       = "http://localhost:${var.app_port}"
}

output "redis_service" {
  description = "Redis service name"
  value       = "redis"
}

output "kafka_service" {
  description = "Kafka service name"
  value       = "kafka"
}

output "prometheus_url" {
  description = "Prometheus URL"
  value       = "http://localhost:${var.prometheus_port}"
}

output "grafana_url" {
  description = "Grafana URL"
  value       = "http://localhost:${var.grafana_port}"
}
