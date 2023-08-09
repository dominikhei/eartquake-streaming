provider "aws" {
  region = var.aws_region #replace the region to your desired region in the var.tf file
}

provider "tls" {

}

# Create a .pem key to openssh into the EC2 instance

resource "tls_private_key" "this" {
  algorithm     = "RSA"
  rsa_bits      = 4096
}

resource "aws_key_pair" "this" {
  key_name      = "kafka-server-key"
  public_key    = tls_private_key.this.public_key_openssh

  provisioner "local-exec" {
    command = <<-EOT
      echo "${tls_private_key.this.private_key_pem}" > kafka-server-key.pem
    EOT
  }
}

resource "aws_vpc" "seismic-project-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "seismic-project-vpc"
  }
}

resource "aws_subnet" "seismic-subnet" {
  vpc_id     = aws_vpc.seismic-project-vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "seismic-subnet"
  }
}

resource "aws_security_group" "project_security_group" {
  name_prefix = "project-security-group"

 ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    self = true
  }
 ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }
 egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = aws_vpc.seismic-project-vpc.id
}

resource "aws_internet_gateway" "seismic_internet_gateway" {
  vpc_id = aws_vpc.seismic-project-vpc.id
}

resource "aws_route_table" "seismic_route_table" {
  vpc_id = aws_vpc.seismic-project-vpc.id  

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.seismic_internet_gateway.id
  }
}


# Attach the internet gateway to the VPC's route table
resource "aws_route" "route" {
  route_table_id         = aws_route_table.seismic_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.seismic_internet_gateway.id
}

resource "aws_route_table_association" "seismic_route_table_association" {
  subnet_id      = aws_subnet.seismic-subnet.id
  route_table_id = aws_route_table.seismic_route_table.id
}

resource "aws_instance" "kafka_server" {
  ami           = "ami-04e601abe3e1a910f" 
  instance_type = "t2.large"
  subnet_id     = aws_subnet.seismic-subnet.id
  key_name= "kafka-server-key"
  associate_public_ip_address = true

  tags = {
    Name = "kafka-server"
  }

  vpc_security_group_ids = [
    aws_security_group.project_security_group.id
  ]

  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

user_data = <<-EOL
#!/bin/bash

sudo apt-get -y update
sudo apt-get -y install docker.io docker-compose

sudo chmod 666 /var/run/docker.sock

sudo apt-get -y install git

git clone https://github.com/dominikhei/eartquake-streaming.git

docker plugin install grafana/loki-docker-driver:latest --alias loki --grant-all-permissions

sudo systemctl restart docker

cd eartquake-streaming/

docker-compose up -d 
EOL

}

resource "aws_iam_role" "ec2_role" {
  name = "ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "dynamodb_policy" {
  name        = "dynamo-policy"
  description = "Allows read and write access to a specific DynamoDB table"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:DeleteItem",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:UpdateItem",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:dynamodb:${var.aws_region}:${var.account_id}:table/eartquakes"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  policy_arn = aws_iam_policy.dynamodb_policy.arn
  role       = aws_iam_role.ec2_role.name
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}



resource "aws_dynamodb_table" "eartquakes" {
  name = "eartquakes"
  billing_mode = "PAY_PER_REQUEST"
  attribute {
    name = "id"
    type = "S"
 }
  hash_key = "id"
}

