terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region     = "us-east-1"
}

resource "aws_vpc" "VPC-A" {
  cidr_block       = "172.22.0.0/16"
  instance_tenancy = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "VPC-A"
  }
}

resource "aws_vpc" "VPC-B" {
  cidr_block       = "172.27.0.0/16"
  instance_tenancy = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "VPC-B"
  }
}

resource "aws_subnet" "VPC-A-pub1" {
  vpc_id            = aws_vpc.VPC-A.id
  cidr_block        = "172.22.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "VPC-A-pub1"
  }
}

resource "aws_subnet" "VPC-A-pub2" {
  vpc_id            = aws_vpc.VPC-A.id
  cidr_block        = "172.22.2.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "VPC-A-pub1"
  }
}

resource "aws_subnet" "VPC-A-pub3" {
  vpc_id            = aws_vpc.VPC-A.id
  cidr_block        = "172.22.3.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "VPC-A-pub1"
  }
}

resource "aws_subnet" "VPC-B-pub1" {
  vpc_id            = aws_vpc.VPC-B.id
  cidr_block        = "172.27.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "VPC-B-pub1"
  }
}

resource "aws_subnet" "VPC-B-pub2" {
  vpc_id            = aws_vpc.VPC-B.id
  cidr_block        = "172.27.2.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "VPC-B-pub1"
  }
}

resource "aws_subnet" "VPC-B-pub3" {
  vpc_id            = aws_vpc.VPC-B.id
  cidr_block        = "172.27.3.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "VPC-B-pub1"
  }
}

resource "aws_route_table" "VPC-A-rt-pub" {
  vpc_id = aws_vpc.VPC-A.id

  tags = {
    Name = "VPC-A-rt-pub"
  }
}

resource "aws_route_table" "VPC-B-rt-pub" {
  vpc_id = aws_vpc.VPC-B.id 

  tags = {
    Name = "VPC-B-rt-pub"
  }
}

resource "aws_internet_gateway" "VPC-A-igw" {
  vpc_id = aws_vpc.VPC-A.id
  tags = {
    Name = "VPC-A-igw"
  }
}

resource "aws_internet_gateway" "VPC-B-igw" {
  vpc_id = aws_vpc.VPC-B.id
  tags = {
    Name = "VPC-B-igw"
  }
}

resource "aws_security_group" "VPC-A-allow_all" {
  vpc_id = aws_vpc.VPC-A.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_all"
  }
}

resource "aws_security_group" "VPC-B-allow_all" {
  vpc_id = aws_vpc.VPC-B.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_all"
  }
} 


resource "aws_instance" "VPC-A-EC2" {
  ami           = "ami-0c02fb55956c7d316" # Amazon Linux 2 AMI (HVM), SSD Volume Type (free tier eligible)
  instance_type = "t2.micro"              # Free tier eligible instance type

  subnet_id = aws_subnet.VPC-A-pub1.id

  security_groups = [aws_security_group.VPC-A-allow_all.name]

  tags = {
    Name = "VPC-A-EC2"
  }
}

resource "aws_ec2_transit_gateway" "LAB-TGW" {
  description = "TGW for lab"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"

  tags = {
    Name = "MainTGW"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "TGW-VPC-A-attachment" {
  subnet_ids          = [aws_subnet.VPC-A-pub1.id, aws_subnet.VPC-A-pub2.id, aws_subnet.VPC-A-pub3.id]
  transit_gateway_id  = aws_ec2_transit_gateway.LAB-TGW.id
  vpc_id              = aws_vpc.VPC-A.id
  transit_gateway_default_route_table_association = true
  transit_gateway_default_route_table_propagation = true
  tags = {
    Name = "TGW-VPC-A-attachment"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "TGW-VPC-B-attachment" {
  subnet_ids          = [aws_subnet.VPC-B-pub1.id, aws_subnet.VPC-B-pub2.id, aws_subnet.VPC-B-pub3.id]
  transit_gateway_id  = aws_ec2_transit_gateway.LAB-TGW.id
  vpc_id              = aws_vpc.VPC-B.id
  transit_gateway_default_route_table_association = true
  transit_gateway_default_route_table_propagation = true
  tags = {
    Name = "TGW-VPC-B-attachment"
  }
}

resource "aws_route" "VPC-A-rt-pub-dgw" {
  route_table_id         = aws_route_table.VPC-A-rt-pub.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.VPC-A-igw.id
}

resource "aws_route" "VPC-B-rt-pub-dgw" {
  route_table_id         = aws_route_table.VPC-B-rt-pub.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.VPC-B-igw.id
}

resource "aws_route" "VPC-A-rt-pub-tgw" {
  route_table_id         = aws_route_table.VPC-A-rt-pub.id
  destination_cidr_block = "172.27.0.0/16"
  gateway_id             = aws_ec2_transit_gateway.LAB-TGW.id

  depends_on = [
    aws_ec2_transit_gateway_vpc_attachment.TGW-VPC-A-attachment
  ]
}

resource "aws_route" "VPC-B-rt-pub-tgw" {
  route_table_id         = aws_route_table.VPC-B-rt-pub.id
  destination_cidr_block = "172.22.0.0/16"
  gateway_id             = aws_ec2_transit_gateway.LAB-TGW.id

  depends_on = [
    aws_ec2_transit_gateway_vpc_attachment.TGW-VPC-B-attachment
  ]
}

resource "aws_vpc_endpoint" "VPC-B-S3-int-endpoints" {
  vpc_id            = aws_vpc.VPC-B.id
  service_name      = "com.amazonaws.us-east-1.ec2"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.VPC-B-pub1.id, aws_subnet.VPC-B-pub2.id, aws_subnet.VPC-B-pub3.id]

  security_group_ids = [
    aws_security_group.VPC-B-allow_all.id
  ]

  private_dns_enabled = true
}