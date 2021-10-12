# Define your outputs here
output "hcp-vault-public_endpoint" {
    value = hcp_vault_cluster.first-cluster.public_endpoint
}