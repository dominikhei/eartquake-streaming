
output "streaming_subnet_id" {
  value = aws_subnet.streaming-subnet.id
}

output "streaming_security_group" {
  value = aws_security_group.streaming_security_group.id
}

output "project_security_group_id" {
  value = aws_security_group.project_security_group.id
}

output "seismic_subnet_id" {
  value = aws_subnet.seismic-subnet.id
}

output "alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "public_subnet_1_id" {
  value = aws_subnet.public1.id
}

output "public_subnet_2_id" {
  value = aws_subnet.public2.id
}

output "vpc_id" {
  value = aws_vpc.seismic-project-vpc.id
}
