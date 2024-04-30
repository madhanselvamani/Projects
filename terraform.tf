terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  access_key = "Your acces key"
  secret_key = "Your secret key"
}

// Step-1: VPC vreation

resource "aws_vpc" "myvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "My-VPC"
  }
}
// step-2: public subnet

resource "aws_subnet" "pub-sub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone ="us-east-1a"

  tags = {
    Name = "My-pubsub"
  }
}
// step-3: private subnet

resource "aws_subnet" "prv-sub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone ="us-east-1b"

  tags = {
    Name = "My=prvsub"
  }
}

// step-3: Internet Gateway and connect it with VPC

resource "aws_internet_gateway" "my-gw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "MYGW"
  }
}

// step-4: Route table for public and attach it with IGW

resource "aws_route_table" "pub-rt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-gw.id
  }

  tags = {
    Name = "mypubrt"
  }
}
// step-5: connect RT with appropriate subnet(pulic subnet)

resource "aws_route_table_association" "pub-rt-assoc" {
  subnet_id      = aws_subnet.pub-sub.id
  route_table_id = aws_route_table.pub-rt.id
}
// step-6: Elastic IP for NAT

resource "aws_eip" "myeip" {
   domain   = "vpc"
}
// step-7: Nat GW to access internet from public subnet

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.myeip.id
  subnet_id     = aws_subnet.pub-sub.id

  tags = {
    Name = "gw NAT"
  }

}

// step-8: Route table for private subnet and attach it with nat gateway

resource "aws_route_table" "prv-rt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "myprvrt"
  }
}

// step-9: connect RT with appropriate private subnet

resource "aws_route_table_association" "prv-rt-assoc" {
  subnet_id      = aws_subnet.prv-sub.id
  route_table_id = aws_route_table.prv-rt.id
}

// step-10: security group for public

resource "aws_security_group" "mypubsg" {
  name        = "mypubsg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

 ingress {
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  tags = {
    Name = "my-vpc-sg"
  }
}

// step-12: create a security group for private:

resource "aws_security_group" "mypvtsg" {
  name        = "myprivatesg"
  description = "Allow SSH from public instance"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description = "SSH from public instance"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.mypubsg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "my-private-sg"
  }
}


// step-13: create inatance 1

resource "aws_instance" "my-machine1" {
    ami = "ami-07caf09b362be10b8"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.pub-sub.id
    vpc_security_group_ids = [aws_security_group.mypubsg.id]
    key_name = "terra"
    associate_public_ip_address = true
  
}
// step-14: create instance 2

resource "aws_instance" "my-machine2" {
    ami = "ami-07caf09b362be10b8"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.prv-sub.id
    vpc_security_group_ids = [aws_security_group.mypvtsg.id]
    key_name = "terra"
}

// Terraform commands

  # terraform init
  # terraform plan
  # terraform apply
  # terraform destroy