provider "aws" {
  region = "us-east-1"
}

data "aws_secretsmanager_secret_version" "ssh_private_key" {
  secret_id = "hello-world-instance-pem"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"]
}

resource "aws_vpc" "devops_hero_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "DevOpsHeroVPC"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.devops_hero_vpc.id
  tags = {
    Name = "DevOpsHeroIGW"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.devops_hero_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true
  tags = {
    Name = "PublicSubnet"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.devops_hero_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "PublicRouteTable"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "ec2_security_group" {
  vpc_id = aws_vpc.devops_hero_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Open for testing, restrict in production
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "EC2SecurityGroup"
  }
}

resource "aws_instance" "jenkins_instance" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
  associate_public_ip_address = true

  # provisioner "local-exec" {
  #   command = <<EOT
  #     echo "${data.aws_secretsmanager_secret_version.ssh_private_key.secret_string}" > /tmp/private-key.pem
  #     cat /tmp/private-key.pem
  #     chmod 400 /tmp/private-key.pem
  #     export ANSIBLE_HOST_KEY_CHECKING=False
  #     ansible-playbook -i ${aws_instance.jenkins_instance.public_ip}, --private-key /tmp/private-key.pem -u ubuntu ../ansible/configure-ec2.yml
  #   EOT
  # }

  tags = {
    Name = "JenkinsInstance"
  }
}

output "ec2_public_ip" {
  value = aws_instance.jenkins_instance.public_ip
}
