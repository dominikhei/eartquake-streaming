provider "aws" {
  region = var.aws_region 
  version = "~> 4.60"
}

provider "aws" {
  region = "us-east-1"
  alias = "finops"
  version = "~> 4.60"
}

provider "tls" {
}