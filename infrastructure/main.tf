############################
# VPC
############################
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

############################
# ECS
############################
module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "6.7.0"

  cluster_name = var.project_name
  
  # CloudWatch Observability
  cluster_setting = {
    "name": "containerInsights",
    "value": "enabled" 
  }

  

  tags = local.common_tags
}

