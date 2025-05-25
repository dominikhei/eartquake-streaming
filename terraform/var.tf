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
  type        = string
}

variable "account_id" {
  description = "Your AWS account ID"
  type        = string
}

variable "site_version" {
  type        = string
  description = "Version or hash string for the index.html"
}
