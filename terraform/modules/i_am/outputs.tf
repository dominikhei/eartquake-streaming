
output "kafka_streaming_instance_profile_name" {
  value = aws_iam_instance_profile.kafka_streaming_instance_profile.name
}

output "ecs_execution_role_arn" {
  value = aws_iam_role.ecs_execution_role.arn
}

output "ecs_role_arn" {
  value = aws_iam_role.ecs_role.arn
}
