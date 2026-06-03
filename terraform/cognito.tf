resource "aws_cognito_identity_pool" "cognito_rum_identity_pool" {
  identity_pool_name               = "${var.project_name}-rum-pool-${terraform.workspace}"
  allow_unauthenticated_identities = true
  allow_classic_flow               = false

  tags = var.tags
}

resource "aws_cognito_identity_pool_roles_attachment" "rum" {
  identity_pool_id = aws_cognito_identity_pool.cognito_rum_identity_pool.id

  roles = {
    unauthenticated = module.rum_guest_role.arn
  }
}
