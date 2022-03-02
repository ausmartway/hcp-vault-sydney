##main.tf
provider "hcp" {
}

// Create an HVN
resource "hcp_hvn" "vault-demo" {
  hvn_id         = "vault-demo"
  cloud_provider = "aws"
  region         = "ap-southeast-2"
  cidr_block     = "172.25.64.0/20"
}

// Create a Vault cluster in the same region and cloud provider as the HVN
resource "hcp_vault_cluster" "vault-cluster" {
  cluster_id = "vault-cluster"
  public_endpoint = true
  hvn_id     = hcp_hvn.vault-demo.hvn_id
}

resource "hcp_vault_cluster_admin_token" "admin" {
  cluster_id = "vault-cluster"
  depends_on = [
      hcp_vault_cluster.vault-cluster,
  ]
}
