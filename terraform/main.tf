provider "aws" {
  region = "us-east-1"
}

# S3 Backend for Terraform state storage
terraform {
  backend "s3" {
    bucket = "devops-superhero-bucket"
    key    = "terraform/state"
    region = "us-east-1"
  }
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "instance_type" {
  description = "The type of EC2 instance"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "The name of the key pair"
  type        = string
  default     = "hello-world-instance"
}

variable "your_ip" {
  description = "Your IP address for SSH access"
  type        = string
  default     = "125.209.112.99/32"
}

variable "ssh_private_key_path" {
  description = "The path to the SSH private key for accessing the EC2 instance"
  type        = string
  default     = "/tmp/private-key.pem"
}

# Fetch the most recent Ubuntu 20.04 LTS AMI
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

  owners = ["099720109477"] # Canonical
}

# Create VPC
resource "aws_vpc" "devops_hero_vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "DevOpsHeroVPC"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.devops_hero_vpc.id

  tags = {
    Name = "DevOpsHeroIGW"
  }
}

# Create public subnets
resource "aws_subnet" "devops_hero_public_subnet_1" {
  vpc_id                  = aws_vpc.devops_hero_vpc.id
  cidr_block              = var.public_subnets[0]
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "DevOpsHeroPublicSubnet1"
  }
}

resource "aws_subnet" "devops_hero_public_subnet_2" {
  vpc_id                  = aws_vpc.devops_hero_vpc.id
  cidr_block              = var.public_subnets[1]
  availability_zone       = var.availability_zones[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "DevOpsHeroPublicSubnet2"
  }
}

# Create private subnets
resource "aws_subnet" "devops_hero_private_subnet_1" {
  vpc_id            = aws_vpc.devops_hero_vpc.id
  cidr_block        = var.private_subnets[0]
  availability_zone = var.availability_zones[0]

  tags = {
    Name = "DevOpsHeroPrivateSubnet1"
  }
}

resource "aws_subnet" "devops_hero_private_subnet_2" {
  vpc_id            = aws_vpc.devops_hero_vpc.id
  cidr_block        = var.private_subnets[1]
  availability_zone = var.availability_zones[1]

  tags = {
    Name = "DevOpsHeroPrivateSubnet2"
  }
}

# Create route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.devops_hero_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "DevOpsHeroPublicRouteTable"
  }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.devops_hero_public_subnet_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.devops_hero_public_subnet_2.id
  route_table_id = aws_route_table.public.id
}

# Create route table for private subnets
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.devops_hero_vpc.id

  tags = {
    Name = "DevOpsHeroPrivateRouteTable"
  }
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.devops_hero_private_subnet_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.devops_hero_private_subnet_2.id
  route_table_id = aws_route_table.private.id
}

# Create security group allowing SSH access
resource "aws_security_group" "allow_ssh" {
  vpc_id = aws_vpc.devops_hero_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.your_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "AllowSSH"
  }
}

# Launch EC2 instance in public subnet
resource "aws_instance" "devops_hero_instance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.devops_hero_public_subnet_1.id
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  tags = {
    Name = "DevOpsHeroInstance"
  }

  provisioner "local-exec" {
    command = <<EOT
      ansible-playbook -i '${self.public_ip},' --private-key /tmp/private-key.pem ansible/configure-ec2.yml
    EOT
  }
}



# Output the VPC ID
output "vpc_id" {
  value = aws_vpc.devops_hero_vpc.id
}

# Output the public IP of the EC2 instance
output "ec2_public_ip" {
  value = aws_instance.devops_hero_instance.public_ip
}
