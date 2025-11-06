output "vpc_id" {
  value = module.vpc.vpc_id
}

output "ecr_service_a_registry" {
  value = module.ecr["service_a"].repository_name
}
output "ecr_service_b_registry" {
  value = module.ecr["service_b"].repository_name
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

output "aws_cloudwatch_log_group_name" {
  value = aws_cloudwatch_log_group.ecs.name
}

output "aws_ecs_task_definition_family" {
  value = aws_ecs_task_definition.app.family
}

output "aws_ecs_service_name" {
  value = aws_ecs_service.app_services.name
}