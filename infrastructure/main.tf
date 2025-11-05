module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  azs = local.azs
  public_subnets = local.public_subnets
  private_subnets = local.private_subnets
  
  enable_nat_gateway = true
  single_nat_gateway = var.enable_single_natgateway

  create_igw = true

  map_public_ip_on_launch = true

  tags = local.common_tags
}