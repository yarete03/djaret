output "cloudfront_domain_name" {
  value = module.cloudfront.cloudfront_distribution_domain_name
}

output "cloudfront_distribution_id" {
  value = module.cloudfront.cloudfront_distribution_id
}

output "api_invoke_url" {
  value = aws_api_gateway_stage.api_gateway_stage.invoke_url
}

output "rds_endpoint" {
  value = module.rds.db_instance_endpoint
}

output "lambda_function_arn" {
  value = module.lambda.lambda_function_arn
}

output "s3_bucket_name" {
  value = module.s3.s3_bucket_id
}
