output "ecr_url" {
  value = module.ecr.ecr_url
}

output "cloudfront_url" {
  value = module.finops.cloudfront_url
}

output "user_pool_id" {
  value = module.finops.user_pool_id
}

output "cognito_username" {
  value = module.finops.cognito_username
}

output "client_id" {
  value = module.finops.client_id
}