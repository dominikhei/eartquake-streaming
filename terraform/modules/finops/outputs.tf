output "cloudfront_url" {
  value       = "https://${aws_cloudfront_distribution.static_site.domain_name}"
  description = "CloudFront distribution URL"
}

output "user_pool_id" {
  value = aws_cognito_user_pool.main.id
}

output "cognito_username" {
  value = aws_cognito_user.sample_user.username
}

output "client_id" {
  value = aws_cognito_user_pool_client.main.id
}