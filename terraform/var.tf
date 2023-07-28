variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "my_ip" {
  description = "Your local IP adress"
  type = string
  default = ""
}

variable "git_username" {
  description = "Your git username on the ec2 instance"
  type = string
  default = ""
}

variable "git_mail" {
  description = "Your git mail on the ec2 instance"
  type = string
  default = ""
}

variable "account_id" {
  description = "Your AWS account ID"
  type = string
  default = ""
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table you want to grant access to"
  type = string
  default = ""
}

