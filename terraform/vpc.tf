module "vpc" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git?ref=v6.6.1"

  name = "${var.project_name}-vpc-${terraform.workspace}"
  cidr = "10.0.0.0/18"

  azs              = ["${var.region}a", "${var.region}b", "${var.region}c"]
  public_subnets   = ["10.0.0.0/25", "10.0.0.128/26", "10.0.0.192/26"]
  database_subnets = ["10.0.1.0/25", "10.0.1.128/26", "10.0.1.192/26"]
  private_subnets  = ["10.0.2.0/23", "10.0.4.0/24", "10.0.5.0/24"]

  create_database_subnet_group           = true
  create_database_subnet_route_table     = true
  create_database_internet_gateway_route = false

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = var.tags
}