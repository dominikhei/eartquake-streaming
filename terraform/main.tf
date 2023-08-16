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

resource "aws_subnet" "streaming-subnet" {
  vpc_id     = aws_vpc.seismic-project-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "seismic-subnet"
  }
}

resource "aws_subnet" "seismic-subnet" {
  vpc_id     = aws_vpc.seismic-project-vpc.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "seismic-subnet"
  }
}

resource "aws_security_group" "streaming_security_group" {
  name_prefix = "streaming-security-group"

 ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }
 ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self = true
  }

 egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = aws_vpc.seismic-project-vpc.id
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
  ingress {
   protocol         = "tcp"
   from_port        = 8501
   to_port          = 8501
   security_groups = [aws_security_group.alb.id]
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

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.seismic-project-vpc.id
    route {
    cidr_block = "0.0.0.0/0"
    gateway_id             = aws_internet_gateway.seismic_internet_gateway.id
  }
}

resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public-streaming" {
  subnet_id      = aws_subnet.streaming-subnet.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.seismic-project-vpc.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.seismic-subnet.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route" "nat_gateway_route" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id
}
 
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public1.id
  depends_on    = [aws_internet_gateway.seismic_internet_gateway]
}
 
resource "aws_eip" "nat" {
  vpc = true
}


resource "aws_instance" "kafka_server" {
  ami           = "ami-04e601abe3e1a910f" // eu-central-1
  instance_type = "t2.large"
  subnet_id     = aws_subnet.streaming-subnet.id
  key_name= "kafka-server-key"
  associate_public_ip_address = true

  tags = {
    Name = "kafka-server"
  }

  vpc_security_group_ids = [
    aws_security_group.streaming_security_group.id
  ]

  iam_instance_profile = aws_iam_instance_profile.kafka_streaming_instance_profile.name

  user_data = file("initiate.sh")
}

resource "aws_instance" "logging" {
    ami = "ami-04e601abe3e1a910f" // eu-central-1
    instance_type = "t2.small"
    private_ip = "10.0.1.10"
    subnet_id     = aws_subnet.streaming-subnet.id
    associate_public_ip_address = true
    key_name= "logging-server-key"
    vpc_security_group_ids = [
    aws_security_group.streaming_security_group.id
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

resource "aws_iam_instance_profile" "kafka_streaming_instance_profile" {
  name = "kafka_streaming_instance_profile"
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

resource "aws_ecr_repository" "frontend_repository" {
  name = "earthquake-frontend"
}

resource "null_resource" "docker_packaging" {
    provisioner "local-exec" {
        command = <<EOF
            aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${var.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com
            docker build -t earthquake_frontend:latest ./frontend
            docker tag earthquake_frontend:latest ${aws_ecr_repository.frontend_repository.repository_url}:latest
            docker push ${aws_ecr_repository.frontend_repository.repository_url}:latest
        EOF
    }

    depends_on = [
        aws_ecr_repository.frontend_repository,
    ]
}

resource "aws_iam_policy" "dynamodb_policy_read_only" {
  name        = "dynamo-policy-read-only"
  description = "Allows read and write access to a specific DynamoDB table"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:DescribeTable",
          "dynamodb:ListTables",
          "dynamodb:GetItem",
          "dynamodb:Scan",
          "dynamodb:Query",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:dynamodb:${var.aws_region}:${var.account_id}:table/eartquakes"
      }
    ]
  })
}

resource "aws_iam_role" "ecs_role" {
  name = "ecs_role"
  assume_role_policy = jsonencode({
    Version: "2012-10-17",
    Statement: [
    {
      Effect: "Allow",
      Principal: {
        Service: "ecs-tasks.amazonaws.com"
      },
      Action: "sts:AssumeRole"
    }
  ]
  })

}

resource "aws_iam_role_policy_attachment" "attach_db_policy" {
  policy_arn = aws_iam_policy.dynamodb_policy_read_only.arn
  role       = aws_iam_role.ecs_role.name
}

resource "aws_iam_role" "ecs_execution_role" {
  name = "MyEcsExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.ecs_execution_role.name
}

resource "aws_iam_role_policy_attachment" "ecs_cw_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
  role       = aws_iam_role.ecs_execution_role.name
}

resource "aws_iam_role_policy_attachment" "ecs_sm_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
  role       = aws_iam_role.ecs_execution_role.name
}

resource "aws_subnet" "public1" {
  vpc_id                  = aws_vpc.seismic-project-vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags = {
    Name = "frontend-subnet"
  }
}

resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.seismic-project-vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true
  tags = {
    Name = "frontend-subnet-2"
  }
}

resource "aws_security_group" "alb" {
  name   = "load-balancer-sg"
  vpc_id = aws_vpc.seismic-project-vpc.id  
 
  ingress {
   protocol         = "tcp"
   from_port        = 80
   to_port          = 80
   cidr_blocks      = ["0.0.0.0/0"]
   ipv6_cidr_blocks = ["::/0"]
  }
 
  egress {
   protocol         = "-1"
   from_port        = 0
   to_port          = 0
   cidr_blocks      = ["0.0.0.0/0"]
   ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_lb" "main" {
  name               = "frontend-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public1.id, aws_subnet.public2.id]
 
  enable_deletion_protection = false
}
 
resource "aws_alb_target_group" "main" {
  name        = "frontend-lb-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.seismic-project-vpc.id
  target_type = "ip"
 
}

resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"
 
  default_action {
    target_group_arn = aws_alb_target_group.main.arn
    type             = "forward"
  }
}

resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 2
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.seismic_cluster.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy_memory" {
  name               = "memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace
 
  target_tracking_scaling_policy_configuration {
   predefined_metric_specification {
     predefined_metric_type = "ECSServiceAverageMemoryUtilization"
   }
   target_value       = 90
  }
}

resource "aws_ecs_cluster" "seismic_cluster" {
  name = "seismic-ecs-cluster"
}

resource "aws_ecs_task_definition" "earthquake_frontend_task" {
  family                   = "frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_role.arn
  container_definitions = jsonencode([{
   name        = "frontend-container"
   image       = "${var.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/earthquake-frontend:latest"
   essential   = true
   network_mode = "awsvpc"
   portMappings = [{
     protocol      = "tcp"
     containerPort = 8501
     hostPort      = 8501
    }]
  }])
}

resource "aws_ecs_service" "main" {
 name                               = "earthquake-frontend-service"
 cluster                            = aws_ecs_cluster.seismic_cluster.id
 task_definition                    = aws_ecs_task_definition.earthquake_frontend_task.arn
 launch_type                        = "FARGATE"
 scheduling_strategy                = "REPLICA"
 
 network_configuration {
   security_groups  = [aws_security_group.project_security_group.id]
   subnets          = [aws_subnet.seismic-subnet.id]
   assign_public_ip = true
 }
 
 load_balancer {
   target_group_arn = aws_alb_target_group.main.arn
   container_name   = "frontend-container"
   container_port   = 8501
 }
 depends_on = [
    aws_alb_target_group.main
 ]
}
