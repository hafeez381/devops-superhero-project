provider "aws" {
  region = "us-east-1"
}

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
  count = length(var.public_subnets)
  vpc_id            = aws_vpc.devops_hero_vpc.id
  cidr_block        = var.public_subnets[count.index]
  availability_zone = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "PublicSubnet-${count.index + 1}"
  }
}

resource "aws_security_group" "ec2_security_group" {
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
    Name = "EC2SecurityGroup"
  }
}

resource "aws_instance" "jenkins_instance" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = element(aws_subnet.public.*.id, 0)
  security_groups        = [aws_security_group.ec2_security_group.name]
  associate_public_ip_address = true

  tags = {
    Name = "JenkinsInstance"
  }
}

output "ec2_public_ip" {
  value = aws_instance.jenkins_instance.public_ip
}
