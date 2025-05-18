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

resource "aws_wafv2_web_acl" "dos" {
  name        = "rate-based"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "rule-1"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 100 
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "request_limit_rule"
      sampled_requests_enabled   = false
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "request_limit"
    sampled_requests_enabled   = false
  }
}

resource "aws_wafv2_web_acl_association" "acl_association" {
  web_acl_arn   = aws_wafv2_web_acl.dos.arn
  resource_arn  = var.alb_arn
}