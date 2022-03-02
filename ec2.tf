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
}

resource "aws_subnet" "subnet" {
  vpc_id            = aws_vpc.hvn-peer.id
  cidr_block        = "10.10.10.0/24"
  availability_zone = "ap-southeast-2a"
  map_public_ip_on_launch = true

  depends_on = [aws_internet_gateway.gw]

  tags = {
    Name   = "hcp-vault-demo-subnet"
    Owner  = "yulei@hashicorp.com"
    TTL    = "48"
    Region = "APJ"
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
    Name = "allow_tls"
  }
}
# resource "aws_network_interface" "network" {
#   subnet_id   = aws_subnet.subnet.id
#   private_ips = ["10.10.10.15"]

#   tags = {
#     Name   = "primary_network_interface"
#     Owner  = "yulei@hashicorp.com"
#     TTL    = "48"
#     Region = "APJ"
#   }
# }


resource "aws_instance" "testserver" {
  ami                         = data.aws_ami.ubuntu.id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.test_profile1.name
  instance_type               = "t3.micro"
  key_name                    = "yulei"
  private_ip                  = "10.10.10.20"
  subnet_id                   = aws_subnet.subnet.id
  #   network_interface {
  #     network_interface_id = aws_network_interface.network.id
  #     device_index         = 0
  #   }

  tags = {
    Name   = "testserver"
    Owner  = "yulei@hashicorp.com"
    TTL    = "48"
    Region = "APJ"
  }
}

resource "aws_eip" "eip" {
  vpc = true

  instance                  = aws_instance.testserver.id
  associate_with_private_ip = "10.10.10.20"
  depends_on                = [aws_internet_gateway.gw]
}

data "aws_route53_zone" "yulei" {
  name         = "yulei.aws.hashidemos.io"
  private_zone = false
}

resource "aws_route53_record" "testserver" {
  zone_id = data.aws_route53_zone.yulei.id
  name    = "testserver.${data.aws_route53_zone.yulei.name}"
  type    = "A"
  ttl     = "300"
  records = [aws_eip.eip.public_ip]
}
