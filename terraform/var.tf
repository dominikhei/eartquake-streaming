variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "global_table_replication_region" {
  description = "AWS region in which to replicate the table"
  type        = string
  default     = "us-east-1"
}

variable "my_ip" {
  description = "Your local IP adress"
  type = string
  default = "217.80.23.80/32"
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