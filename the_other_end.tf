resource "aws_iam_instance_profile" "test_profile1" {
  name = "test_profile1"
  role = aws_iam_role.role1.name
}

resource "aws_iam_role" "role1" {
  name = "yulei_role1"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}


data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "tag:application"
    values = ["vault-1.8.2-oss"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["711129375688"] # HashiCorp account
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.hvn-peer.id

  tags = {
    Name = "hcp-vault-demo-gw"

  }
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.hvn-peer.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    cidr_block                = "172.25.48.0/20"
    vpc_peering_connection_id = hcp_aws_network_peering.example.provider_peering_id
  }

  tags = {
    Name = "route-to-hcp"
  }
}

resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_subnet" "subnet" {
  vpc_id                  = aws_vpc.hvn-peer.id
  cidr_block              = "10.10.10.0/24"
  availability_zone       = "ap-southeast-2a"
  map_public_ip_on_launch = true

  depends_on = [aws_internet_gateway.gw]

  tags = {
    Name = "hcp-vault-demo-subnet"

  }
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow ssh inbound traffic"
  vpc_id      = aws_vpc.hvn-peer.id

  ingress {
    description      = "ssh from all"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

resource "aws_instance" "testserver" {
  ami                    = data.aws_ami.ubuntu.id
  iam_instance_profile   = aws_iam_instance_profile.test_profile1.name
  instance_type          = "t3.micro"
  key_name               = "yulei"
  private_ip             = "10.10.10.20"
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  subnet_id              = aws_subnet.subnet.id
  tags = {
    Name = "testserver"
  }
}
