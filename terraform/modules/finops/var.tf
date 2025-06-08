variable "site_version" {
  description = "The version of the finops dashboard (v:n)."
  type        = string
}

variable "my_ip" {
  description = "Your local IP address. Access to the dashboard will be limited to it."
  type        = string
}

variable "cognito_domain_prefix" {
  description = "Prefix for Cognito domain"
  type        = string
}

variable "cognito_password" {
  description = "Password for Cognito authentication"
  type        = string
}

variable "cognito_username" {
  description = "Username for Cognito authentication"
  type        = string
}

variable "edge_lambda_role_arn" {
  description = "Role for the edge lambda function"
  type = string
}