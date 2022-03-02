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


resource "aws_subnet" "subnet" {
    vpc_id            = aws_vpc.hvn-peer.id
  cidr_block        = "10.220.1.0/24"
  availability_zone = "ap-southeast-2a"

  tags = {
    Name = "hcp-vault-demo-subnet"
   Owner  = "yulei@hashicorp.com"
    TTL    = "48"
    Region = "APJ"
  }
}

resource "aws_network_interface" "network" {
  subnet_id   = aws_subnet.subnet.id
  private_ips = ["10.220.1.15"]

  tags = {
    Name = "primary_network_interface"
   Owner  = "yulei@hashicorp.com"
    TTL    = "48"
    Region = "APJ"
  }
}


resource "aws_instance" "testserver1" {
  ami                  = data.aws_ami.ubuntu.id
  iam_instance_profile = aws_iam_instance_profile.test_profile1.name
  instance_type        = "t3.micro"
  key_name             = "yulei"

  network_interface {
    network_interface_id = aws_network_interface.network.id
    device_index         = 0
  }

  tags = {
    Name   = "testserver1"
    Owner  = "yulei@hashicorp.com"
    TTL    = "48"
    Region = "APJ"
  }
}

data "aws_route53_zone" "yulei" {
  name         = "yulei.aws.hashidemos.io"
  private_zone = false
}

resource "aws_route53_record" "testserver1" {
  zone_id = data.aws_route53_zone.yulei.id
  name    = "testserver1.${data.aws_route53_zone.yulei.name}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.testserver1.public_ip]
}
