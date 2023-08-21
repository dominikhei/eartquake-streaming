
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