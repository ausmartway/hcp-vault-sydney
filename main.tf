##main.tf
provider "hcp" {
}

// Create an HVN
resource "hcp_hvn" "yulei-hvn" {
  hvn_id         = "yulei-hvn"
  cloud_provider = "aws"
  region         = "ap-southeast-2"
  cidr_block     = "172.25.16.0/20"
}

// Create a Vault cluster in the same region and cloud provider as the HVN
resource "hcp_vault_cluster" "first-cluster" {
  cluster_id = "first-cluster"
  public_endpoint = true
  hvn_id     = hcp_hvn.yulei-hvn.hvn_id
}

resource "hcp_vault_cluster_admin_token" "admin" {
  cluster_id = "first-cluster"
  depends_on = [
      hcp_vault_cluster.first-cluster,
  ]
}
