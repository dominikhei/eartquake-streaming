provider "aws" {
  region = var.aws_region #replace the region to your desired region in the var.tf file
}

provider "tls" {
}