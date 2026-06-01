module "s3" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-s3-bucket.git?ref=v5.14.0"

  bucket = "${var.project_name}-s3-${terraform.workspace}"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    status = "Enabled"
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
      bucket_key_enabled = true
    }
  }

  tags = var.tags
}

resource "aws_s3_bucket_policy" "s3_bucket_policy" {
  bucket = module.s3.s3_bucket_id

  policy = jsonencode({
    Version = "2008-10-17"
    Id      = "PolicyForAccesingS3"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:GetObject"
        Resource  = "${module.s3.s3_bucket_arn}/*"
        Condition = {
          ArnLike = { "AWS:SourceArn" = module.cloudfront.cloudfront_distribution_arn }
        }
      },
      {
        Sid       = "RUM_S3_Read_Permissions"
        Effect    = "Allow"
        Principal = { Service = "rum.amazonaws.com" }
        Action    = ["s3:GetObject", "s3:ListBucket"]
        Resource  = [module.s3.s3_bucket_arn, "${module.s3.s3_bucket_arn}/static/*"]
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = var.account_id
            "aws:SourceArn"     = aws_rum_app_monitor.cw_rum_app_monitor.arn
          }
        }
      },
    ]
  })
}
