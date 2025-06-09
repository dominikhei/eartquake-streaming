provider "aws" {
  region  = var.aws_region
  version = "~> 4.60"

  default_tags {
    tags = {
      Environment = "dev"
      Project     = "eartquake-streaming"
      Cost-Center = "analytics"
    }
  }
}

provider "tls" {
}
