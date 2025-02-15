// Create a Vault cluster in the same region and cloud provider as the HVN
resource "hcp_vault_cluster" "vault-plus-demo" {
  cluster_id      = "vault-plus-demo"
  tier = "Plus_small"
  public_endpoint = true
  hvn_id          = hcp_hvn.vault-demo-hvn.hvn_id
}

resource "hcp_vault_cluster_admin_token" "vault-plus-demo-admin" {
  cluster_id = "vault-plus-demo"
  depends_on = [
    hcp_vault_cluster.vault-plus-demo,
  ]
}

output "vault-plus-demo-url" {
  value = hcp_vault_cluster.vault-plus-demo.public_endpoint
  description = "URL of Vault cluster"
  sensitive = false
}

output "vault-plus-demo-admin-token" {
  value = hcp_vault_cluster_admin_token.vault-plus-demo-admin.admin_token
  description = "Admin token for Vault cluster"
  sensitive = false
}

