terraform {
  required_version = ">= 1.0"

  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27.0"
    }
  }
}

provider "kind" {}

provider "kubernetes" {
  host                   = kind_cluster.ctt-cluster.endpoint
  client_certificate     = kind_cluster.ctt-cluster.client_certificate
  client_key             = kind_cluster.ctt-cluster.client_key
  cluster_ca_certificate = kind_cluster.ctt-cluster.cluster_ca_certificate
}
