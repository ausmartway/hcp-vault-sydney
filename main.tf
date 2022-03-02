##main.tf
provider "hcp" {
}

provider "aws" {
  region = "ap-southeast-2"
}

// Create an HVN
resource "hcp_hvn" "vault-demo-hvn" {
  hvn_id         = "vault-demo-hvn"
  cloud_provider = "aws"
  region         = "ap-southeast-2"
  cidr_block     = "172.25.48.0/20"
}

// Create a Vault cluster in the same region and cloud provider as the HVN
resource "hcp_vault_cluster" "vault-cluster" {
  cluster_id      = "vault-cluster"
  public_endpoint = true
  hvn_id          = hcp_hvn.vault-demo-hvn.hvn_id
}

resource "hcp_vault_cluster_admin_token" "admin" {
  cluster_id = "vault-cluster"
  depends_on = [
    hcp_vault_cluster.vault-cluster,
  ]
}


// If you have not already, create a VPC within your AWS account that will
// contain the workloads you want to connect to your HCP Consul cluster.
// Make sure the CIDR block of the peer VPC does not overlap with the CIDR
// of the HVN.
resource "aws_vpc" "hvn-peer" {
  cidr_block = "10.10.10.0/24"
  tags = {
    Name   = "hcp-vault-demo-vpc"
    Owner  = "yulei@hashicorp.com"
    TTL    = "48"
    Region = "APJ"
  }
}



//get the arn of hvn-peer
data "aws_arn" "hvn-peer" {
  arn = aws_vpc.hvn-peer.arn
}
// Create an HCP network peering to peer your HVN with your AWS VPC.
resource "hcp_aws_network_peering" "example" {
  peering_id      = "hcp-vault"
  hvn_id          = hcp_hvn.vault-demo-hvn.hvn_id
  peer_vpc_id     = aws_vpc.hvn-peer.id
  peer_account_id = aws_vpc.hvn-peer.owner_id
  peer_vpc_region = data.aws_arn.hvn-peer.region
}

// Create an HVN route that targets your HCP network peering and matches your AWS VPC's CIDR block
resource "hcp_hvn_route" "example" {
  hvn_link         = hcp_hvn.vault-demo-hvn.self_link
  hvn_route_id     = "demo-route"
  destination_cidr = aws_vpc.hvn-peer.cidr_block
  target_link      = hcp_aws_network_peering.example.self_link
}

// Accept the VPC peering within your AWS account.
resource "aws_vpc_peering_connection_accepter" "peer" {
  vpc_peering_connection_id = hcp_aws_network_peering.example.provider_peering_id
  auto_accept               = true
}