terraform {
  backend "s3" {
    bucket = "ecs-managed-orchestration-sf"
    region = "ap-south-1"
    key = "daksh/terraform.tfstate"
    dynamodb_table = "terraform-lock"
  }
}