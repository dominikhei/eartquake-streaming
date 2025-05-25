output "cloudfront_url" {
  value       = "https://${aws_cloudfront_distribution.static_site.domain_name}"
  description = "CloudFront distribution URL"
}
