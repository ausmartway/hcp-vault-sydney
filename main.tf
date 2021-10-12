##main.tf
provider "hcp" {
}

// Create an HVN
resource "hcp_hvn" "yulei-hvn" {
  hvn_id         = "yulei-hvn"
  cloud_provider = "aws"
  region         = "us-east-1"
  cidr_block     = "172.25.16.0/20"
}

// Create a Vault cluster in the same region and cloud provider as the HVN
resource "hcp_vault_cluster" "first-cluster" {
  cluster_id = "first-cluster"
  hvn_id     = hcp_hvn.yulei-hvn.hvn_id
}

resource "hcp_vault_cluster_admin_token" "admin" {
  cluster_id = "first-cluster"
}
