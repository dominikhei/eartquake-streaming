provider "aws" {
  region = var.aws_region #replace the region to your desired region in the var.tf file
}

provider "tls" {

}

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

resource "tls_private_key" "this_two" {
  algorithm     = "RSA"
  rsa_bits      = 4096
}

resource "aws_key_pair" "this_two" {
  key_name      = "logging-server-key"
  public_key    = tls_private_key.this_two.public_key_openssh

  provisioner "local-exec" {
    command = <<-EOT
      echo "${tls_private_key.this_two.private_key_pem}" > logging-server-key.pem
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
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "seismic-subnet"
  }
}

resource "aws_security_group" "project_security_group" {
  name_prefix = "project-security-group"

 ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
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
  ami           = "ami-04e601abe3e1a910f" // eu-central-1
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

  iam_instance_profile = aws_iam_instance_profile.streaming_instance_profile.name

  user_data = file("initiate.sh")
}

resource "aws_instance" "logging" {
    ami = "ami-04e601abe3e1a910f" // eu-central-1
    instance_type = "t2.small"
    private_ip = "10.0.1.10"
    subnet_id     = aws_subnet.seismic-subnet.id
    associate_public_ip_address = true
    key_name= "logging-server-key"
    vpc_security_group_ids = [
    aws_security_group.project_security_group.id
  ]
  tags = {
    Name = "monitoring-server"
  }
  user_data = file("initiate_logging.sh")
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

resource "aws_iam_instance_profile" "streaming_instance_profile" {
  name = "streaming-instance-profile"
  role = aws_iam_role.ec2_role.name
}

module "terraform-aws-dynamodb" {
  source  = "mineiros-io/dynamodb/aws"
  version = "~> 0.6.0"

  name         = "eartquakes"
  hash_key     = "id"
  billing_mode = "PAY_PER_REQUEST"

  attributes = {
    id = "S"
  }

  replica_region_names = [var.global_table_replication_region]
}