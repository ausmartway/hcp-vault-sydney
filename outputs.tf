# Define your outputs here
output "hcp-vault-public_endpoint" {
    value = hcp_vault_cluster.first-cluster.vault_public_endpoint_url
}

output "hcp-vault-admin-token" {
    value = hcp_vault_cluster_admin_token.admin.token
}