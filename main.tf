##main.tf
provider "hcp" {
}

// Create an HVN
resource "hcp_hvn" "sydney" {
  hvn_id         = "Sydney"
  cloud_provider = "aws"
  region         = "ap-southeast-2"
  cidr_block     = "172.25.16.0/20"
}

// Create a Vault cluster in the same region and cloud provider as the HVN
resource "hcp_vault_cluster" "sydney-cluster" {
  cluster_id = "sydney-cluster"
  public_endpoint = true
  hvn_id     = hcp_hvn.sydney.hvn_id
}

resource "hcp_vault_cluster_admin_token" "admin" {
  cluster_id = "sydney-cluster"
  depends_on = [
      hcp_vault_cluster.sydney-cluster,
  ]
}
