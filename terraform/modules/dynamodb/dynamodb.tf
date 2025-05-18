module "terraform-aws-dynamodb" {
  source  = "mineiros-io/dynamodb/aws"
  version = "~> 0.6.0"

  name         = "eartquakes"
  hash_key     = "id"
  billing_mode = "PAY_PER_REQUEST"

  attributes = {
    id = "S"
  }

  replica_region_names = [var.global_table_replication_region]
}