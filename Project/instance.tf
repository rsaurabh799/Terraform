provider "aws" {
    access_key = var.AWS_ACCESS_KEY
    secret_key = var.AWS_SECRET_KEY
    region = var.AWS_REGION
}


# Create VPC

resource "aws_vpc" "dev_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
      Name = "Dev"
  }
}

# Create Internet Gateway

resource "aws_internet_gateway" "dev_gw" {
  vpc_id = aws_vpc.dev_vpc.id
  tags = {
      Name = "DevGW"
  }
}

# Create Custom Route Table

resource "aws_route_table" "dev_route_table" {
  vpc_id = aws_vpc.dev_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev_gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.dev_gw.id
  }

  tags = {
    Name = "DevRoute"
  }
}

# Create Subnet

resource "aws_subnet" "dev_sunet" {
  vpc_id     = aws_vpc.dev_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "DevSubnet"
  }
}

# Associate subnet with route table

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.dev_sunet.id
  route_table_id = aws_route_table.dev_route_table.id
}

# Create Security group to allow port 22, 80, 443

resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow web_traffic"
  vpc_id      = aws_vpc.dev_vpc.id

  ingress {
    description = "HTTPS Traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP Traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH Traffic"
    from_port   = 22
    to_port     = 22
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
    Name = "Allow Web Traffic"
  }
}

# Create Network interface with an IP in the subnet that was created in step 4

resource "aws_network_interface" "dev_network_interface" {
  subnet_id       = aws_subnet.dev_sunet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

}

# Assign as elastic IP (Public IP) to the network interface in step 7

resource "aws_eip" "dev_elastic_ip" {
  vpc                       = true
  network_interface         = aws_network_interface.dev_network_interface.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.dev_gw]
}


output "server_public_ip" {
  value = aws_eip.dev_elastic_ip.public_ip
}


# Create ubuntu server and install/ enable apache2

resource "aws_instance" "Web_server_instance" {
    ami           = var.AWS_AMI[var.AWS_REGION]
    instance_type = "t2.micro"
    availability_zone = "us-east-2a"
    key_name = "terraform-key"


    network_interface {
        device_index = 0
        network_interface_id = aws_network_interface.dev_network_interface.id
    }

    user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                EOF
    tags = {
        Name = "web-server"
    }
}