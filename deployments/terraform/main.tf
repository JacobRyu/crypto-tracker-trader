resource "kind_cluster" "ctt-cluster" {
  name           = var.cluster_name
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role  = "control-plane"
      extra_port_mappings {
        container_port = var.app_port
        host_port      = var.app_port
        protocol       = "TCP"
      }
    }

    node {
      role = "worker"
    }
  }
}

resource "kubernetes_namespace" "ctt" {
  metadata {
    name = var.namespace

    labels = {
      app     = "crypto-tracker-trader"
      managed = "terraform"
    }
  }

  depends_on = [kind_cluster.ctt-cluster]
}

resource "kubernetes_config_map" "redis_config" {
  metadata {
    name      = "redis-config"
    namespace = kubernetes_namespace.ctt.metadata[0].name
  }

  data = {
    REDIS_HOST = "redis"
    REDIS_PORT = "6379"
  }
}

resource "kubernetes_config_map" "kafka_config" {
  metadata {
    name      = "kafka-config"
    namespace = kubernetes_namespace.ctt.metadata[0].name
  }

  data = {
    KAFKA_BROKER         = "kafka:9092"
    KAFKA_TOPIC_PRICES   = "price-events"
    KAFKA_TOPIC_EXCHANGE = "exchange-events"
    KAFKA_TOPIC_DEFI     = "defi-events"
  }
}

resource "kubernetes_config_map" "prometheus_config" {
  metadata {
    name      = "prometheus-config"
    namespace = kubernetes_namespace.ctt.metadata[0].name
  }

  data = {
    "prometheus.yml" = file("${path.module}/../config/prometheus.yml")
  }
}

resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = "app-config"
    namespace = kubernetes_namespace.ctt.metadata[0].name
  }

  data = {
    ETHEREUM_NODE_URL      = var.ethereum_node_url
    PRICE_SYMBOLS          = "BTC,ETH,BNB,SOL"
    PRICE_SYNC_INTERVAL_S  = "60"
    EXCHANGE_SYNC_INTERVAL_S = "300"
    DEFI_SYNC_INTERVAL_S   = "900"
    REDIS_HOST             = "redis"
    REDIS_PORT             = "6379"
    KAFKA_BROKER           = "kafka:9092"
  }
}

resource "kubernetes_secret" "app_secrets" {
  metadata {
    name      = "app-secrets"
    namespace = kubernetes_namespace.ctt.metadata[0].name
  }

  data = {
    JWT_SECRET      = var.jwt_secret
    ENCRYPTION_KEY  = var.encryption_key
  }
}

resource "kubernetes_config_map" "db_config" {
  metadata {
    name      = "db-config"
    namespace = kubernetes_namespace.ctt.metadata[0].name
  }

  data = {
    POSTGRES_DB       = var.postgres_db
    POSTGRES_USER     = var.postgres_user
    POSTGRES_PASSWORD = var.postgres_password
  }
}
