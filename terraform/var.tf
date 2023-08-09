variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "my_ip" {
  description = "Your local IP adress"
  type = string
  default = "217.81.217.242/32"
}

variable "account_id" {
  description = "Your AWS account ID"
  type = string
  default = "000756383174"
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table you want to grant access to"
  type = string
  default = "eartquakes"
}

