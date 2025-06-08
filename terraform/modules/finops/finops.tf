provider "aws" {
  region  = "us-east-1"
  alias   = "finops"
  version = "~> 4.60"

  default_tags {
    tags = {
      Environment       = "dev"
      Project           = "eartquake-streaming"
      Cost-Center       = "analytics"
      }
  }
}

resource "aws_s3_bucket" "infracost_static_site" {
  bucket = "infracost-static-site-bucket-earthquake-streaming"
}

resource "aws_s3_object" "index_versioned" {
  bucket       = aws_s3_bucket.infracost_static_site.id
  key          = "index.${var.site_version}.html"
  content      = file("${path.module}/index.html")
  content_type = "text/html"
}

resource "aws_s3_bucket_public_access_block" "static_site" {
  bucket = aws_s3_bucket.infracost_static_site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "static_site" {
  bucket = aws_s3_bucket.infracost_static_site.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement: [
      {
        Sid: "AllowCloudFrontAccessWithOAC",
        Effect: "Allow",
        Principal: {
          Service: "cloudfront.amazonaws.com"
        },
        Action: "s3:GetObject",
        Resource: "${aws_s3_bucket.infracost_static_site.arn}/*",
        Condition: {
          StringEquals: {
            "AWS:SourceArn": "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.static_site.id}"
          }
        }
      }
    ]
  })
}

resource "aws_cloudfront_origin_access_control" "static_site" {
  name                              = "static-site-oac"
  description                       = "OAC for static site"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

data "aws_caller_identity" "current" {}

resource "aws_cognito_user_pool" "main" {

  provider = aws.finops

  name = "infracost-user-pool"
  
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  auto_verified_attributes = ["email"]

  schema {
    attribute_data_type = "String"
    name               = "email"
    required           = true
    mutable           = true
  }
}

resource "aws_cognito_user_pool_client" "main" {

  provider = aws.finops

  name         = "infracost-client"
  user_pool_id = aws_cognito_user_pool.main.id

  generate_secret = true
  
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                = ["email", "openid", "profile"]
  
  callback_urls = ["https://placeholder/callback"]  
  logout_urls   = ["https://placeholder/logout"]    

  supported_identity_providers = ["COGNITO"]

    explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_CUSTOM_AUTH",
    "ALLOW_ADMIN_USER_PASSWORD_AUTH"
  ]
  
  access_token_validity  = 1  
  id_token_validity     = 1  
  refresh_token_validity = 30 

  lifecycle {
    ignore_changes = [callback_urls, logout_urls]
  }
}

resource "aws_cognito_user_pool_domain" "main" {
  provider = aws.finops
  domain       = var.cognito_domain_prefix
  user_pool_id = aws_cognito_user_pool.main.id
}

resource "aws_cognito_user" "sample_user" {
  provider = aws.finops
  user_pool_id = aws_cognito_user_pool.main.id
  username     = var.cognito_username
  
  attributes = {
    email          = "test@example.com"
    email_verified = "true"
  }
  
  temporary_password = "xGtZuu8/81J4aCt!"
  message_action     = "SUPPRESS"
}

resource "aws_iam_role" "lambda_edge_role" {
  provider = aws.finops
  name = "lambda-edge-cognito-auth-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "lambda.amazonaws.com",
            "edgelambda.amazonaws.com"
          ]
        }
      }
    ]
  })
}

resource "aws_lambda_function" "auth_lambda" {

  provider = aws.finops
  
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "cognito-auth-lambda-edge"
  role            = aws_iam_role.lambda_edge_role.arn
  handler         = "lambda_auth.handler"
  runtime         = "nodejs18.x"
  timeout         = 5
  
  publish = true

  depends_on = [data.archive_file.lambda_zip]
}

resource "local_file" "lambda_code" {
  filename = "${path.module}/lambda_auth.js"
  content = templatefile("${path.module}/lambda_auth.js.tpl", {
    cognito_domain = var.cognito_domain_prefix
    client_id      = aws_cognito_user_pool_client.main.id
    client_secret  = aws_cognito_user_pool_client.main.client_secret
  })
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = local_file.lambda_code.filename
  output_path = "${path.module}/lambda_auth.zip"
  depends_on  = [local_file.lambda_code]
}

resource "aws_cloudfront_distribution" "static_site" {

  provider = aws.finops 

  origin {
    domain_name              = aws_s3_bucket.infracost_static_site.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.static_site.id
    origin_id                = "S3-${aws_s3_bucket.infracost_static_site.id}"
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.${var.site_version}.html"

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.infracost_static_site.id}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
      headers = ["Authorization", "CloudFront-Forwarded-Proto"]
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400

    lambda_function_association {
      event_type   = "viewer-request"
      lambda_arn   = aws_lambda_function.auth_lambda.qualified_arn
      include_body = false
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_wafv2_web_acl" "cloudfront_acl" {

  provider = aws.finops

  name        = "cloudfront-waf"
  scope       = "CLOUDFRONT"
  description = "Limit /callback to 10 requests per minute per IP"
  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "disabled"
    sampled_requests_enabled   = false
  }

  rule {
    name     = "RateLimitCallback"
    priority = 0

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 100
        aggregate_key_type = "IP"

        scope_down_statement {
          byte_match_statement {
            field_to_match {
              uri_path {}
            }
            positional_constraint = "STARTS_WITH"
            search_string         = "/callback"
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "disabled"
      sampled_requests_enabled   = false
    }
  }
}