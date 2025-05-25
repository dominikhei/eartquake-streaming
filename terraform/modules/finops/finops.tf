provider "aws" {
  region = "us-east-1"
  alias = "finops"
}

resource "null_resource" "run_infracost" {
  provisioner "local-exec" {
    command = "./infracost.sh"
  }
  
  triggers = {
    script_hash = filemd5("${path.module}/infracost.sh")
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
  depends_on = [null_resource.run_infracost]
}

resource "aws_s3_bucket_public_access_block" "static_site" {
  bucket = aws_s3_bucket.infracost_static_site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_control" "static_site" {
  name                              = "static-site-oac"
  description                       = "OAC for static site S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_s3_bucket_policy" "static_site" {
  bucket = aws_s3_bucket.infracost_static_site.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.infracost_static_site.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.static_site.arn
          }
        }
      }
    ]
  })
}

resource "aws_wafv2_ip_set" "allowed_ips" {
  name  = "allowed-ips"
  scope = "CLOUDFRONT"

  ip_address_version = "IPV4"
  addresses          = [var.my_ip]
}

resource "aws_wafv2_web_acl" "ip_restriction" {
  name  = "ip-restriction-acl"
  scope = "CLOUDFRONT"
  provider = aws.finops

  default_action {
    block {}
  }

  rule {
    name     = "AllowSpecificIP"
    priority = 1

    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.allowed_ips.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                 = "AllowSpecificIPRule"
      sampled_requests_enabled    = false
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                 = "IPRestrictionACL"
    sampled_requests_enabled    = false
  }
}

resource "aws_cloudfront_distribution" "static_site" {
  origin {
    domain_name              = aws_s3_bucket.infracost_static_site.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.static_site.id
    origin_id                = "S3-${aws_s3_bucket.infracost_static_site.id}"
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.${var.site_version}.html"

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.infracost_static_site.id}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  web_acl_id = aws_wafv2_web_acl.ip_restriction.arn
}

output "cloudfront_domain_name" {
  value       = aws_cloudfront_distribution.static_site.domain_name
  description = "CloudFront distribution domain name"
}

output "cloudfront_url" {
  value       = "https://${aws_cloudfront_distribution.static_site.domain_name}"
  description = "CloudFront distribution URL"
}

output "bucket_name" {
  value       = aws_s3_bucket.infracost_static_site.id
  description = "Name of the S3 bucket"
}