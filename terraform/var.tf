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
  default = "__insert__here__"
}

variable "account_id" {
  description = "Your AWS account ID"
  type = string
  default = "__insert__here__"
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table you want to grant access to"
  type = string
  default = "eartquakes"
}