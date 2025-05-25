resource "aws_dynamodb_table" "earthquakes" {
  name           = "eartquakes"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  replica {
    region_name = var.global_table_replication_region
  }

  tags = {
    Name = "earthquakes"
  }
}