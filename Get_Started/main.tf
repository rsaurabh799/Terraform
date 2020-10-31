provider "aws" {
    access_key = var.AWS_ACCESS_KEY
    secret_key = var.AWS_SECRET_KEY
    region = var.AWS_REGION
}

resource "aws_instance" "my-server" {
  ami           = var.AWS_AMI[var.AWS_REGION]
  instance_type = "t2.micro"
}

resource "aws_vpc" "first_vpc" {
  cidr_block = "10.0.0.0/16"
}


resource "aws_subnet" "first_subnet" {
  vpc_id     = aws_vpc.first_vpc.id
  cidr_block = "10.0.1.0/24"

}

