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
  vpc_id                  = aws_vpc.devops_hero_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true
  tags = {
    Name = "PublicSubnet"
  }
}



resource "aws_security_group" "ec2_security_group" {
  vpc_id = aws_vpc.devops_hero_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Open for testing, restrict in production
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

  provisioner "remote-exec" {
    connection {
      host        = "${aws_instance.jenkins_instance.public_ip}"
      user        = "ubuntu"
      private_key = data.aws_secretsmanager_secret_version.ssh_private_key.secret_string
    }

    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y python3-pip",
      "pip3 install ansible"
    ]
  }

  provisioner "local-exec" {
    command = <<EOT
      sleep 80  # Add a delay to allow instance to initialize
      echo "${data.aws_secretsmanager_secret_version.ssh_private_key.secret_string}" > /tmp/private-key.pem
      chmod 400 /tmp/private-key.pem
      ansible-playbook -i ${aws_instance.jenkins_instance.public_ip}, --private-key /tmp/private-key.pem -u ubuntu ../ansible/configure-ec2.yml
    EOT
  }

  tags = {
    Name = "JenkinsInstance"
  }
}
