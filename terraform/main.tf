terraform {
  required_version = ">= 0.12.28"
  required_providers {
    aws = ">= 2.70.0"
  }
}

provider "aws" {
  profile = "dev-user"
  region  = "ap-northeast-1"
}

variable "web_ssh_private_key" {}
variable "web_ssh_public_key" {}

############################################################
### ネットワーク 
############################################################
### VPC ####################
resource "aws_vpc" "y-oka-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "y-oka-vpc"
  }
}

### サブネット ####################
# パブリックサブネット
resource "aws_subnet" "y-oka-pub-subnet-a" {
  vpc_id                  = aws_vpc.y-oka-vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "y-oka-pub-subnet-a"
  }
}

### ネットワークルーティング ####################
# publicサブネット <- IGW -> 外部インターネット
resource "aws_internet_gateway" "y-oka-igw" {
  vpc_id = aws_vpc.y-oka-vpc.id
  tags = {
    Name = "y-oka-igw"
  }
}

resource "aws_route_table" "y-oka-pub-rtb" {
  vpc_id = aws_vpc.y-oka-vpc.id
  route {
    gateway_id = aws_internet_gateway.y-oka-igw.id
    cidr_block = "0.0.0.0/0"
  }
  tags = {
    Name = "y-oka-pub-rtb"
  }
}

resource "aws_route_table_association" "y-oka-pub-rtb-ass-a" {
  subnet_id      = aws_subnet.y-oka-pub-subnet-a.id
  route_table_id = aws_route_table.y-oka-pub-rtb.id
}


############################################################
### セキュリティグループ 
############################################################
### publicセキュリティー ####################
resource "aws_security_group" "y-oka-pub-sg" {
  name   = "y-oka-pub-sg"
  vpc_id = aws_vpc.y-oka-vpc.id

  tags = {
    Name = "y-oka-pub-sg"
  }
}

# アウトバウンド(外に出る)ルール
resource "aws_security_group_rule" "y-oka-pub-sg-out-all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.y-oka-pub-sg.id
}

# インバウンド(受け入れる)ルール
resource "aws_security_group_rule" "y-oka-pub-sg-in-http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.y-oka-pub-sg.id
}

resource "aws_security_group_rule" "y-oka-pub-sg-in-ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.y-oka-pub-sg.id
}

############################################################
### EC2 
############################################################
resource "aws_key_pair" "y-oka-web-ec2-key-pair" {
  key_name   = var.web_ssh_private_key
  public_key = file("./.ssh/${var.web_ssh_public_key}")
}

# Webサーバー
resource "aws_instance" "y-oka-web-ec2" {
  ami                    = "ami-00f045aed21a55240"
  instance_type          = "m5d.large"
  key_name               = aws_key_pair.y-oka-web-ec2-key-pair.id
  subnet_id              = aws_subnet.y-oka-pub-subnet-a.id
  vpc_security_group_ids = [aws_security_group.y-oka-pub-sg.id]
  provisioner "remote-exec" {
    connection {
      host        = self.public_ip
      user        = "ec2-user"
      private_key = file("./.ssh/${var.web_ssh_private_key}")
    }
    inline = [
      "sudo yum -y update"
    ]
  }
  tags = {
    Name = "y-oka-web-ec2"
  }
}

resource "local_file" "hosts_file" {
  content         = <<EOF
[${aws_instance.y-oka-web-ec2.id}]
${aws_instance.y-oka-web-ec2.public_ip}
EOF
  filename        = "hosts"
  file_permission = "0644"
}
