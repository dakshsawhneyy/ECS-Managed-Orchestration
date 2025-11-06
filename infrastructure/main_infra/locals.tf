data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

locals {
  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 10)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k)]

  ecr_repositories = {
    service_a = {
      repository_name = "service-a"
      repository_type = "private"
    },
    service_b = {
      repository_name = "service-b"
      repository_type = "private"
    }
  }

  common_tags = {
    Project     = var.project_name
    ManagedBy   = "terraform"
    CreatedBy   = "DakshSawhney"
    Owner       = data.aws_caller_identity.current.user_id
    CreatedDate = formatdate("YYYY-MM-DD", timestamp())
  }
}