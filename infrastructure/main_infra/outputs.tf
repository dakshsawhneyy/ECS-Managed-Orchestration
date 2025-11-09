output "vpc_id" {
  value = module.vpc.vpc_id
}

output "ecr_service_a_url" {
  value = module.ecr["service_a"].repository_url
}
output "ecr_service_b_url" {
  value = module.ecr["service_b"].repository_url
}
output "ecr_ingestor_url" {
  value = module.ecr["ingestor"].repository_url
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

output "aws_alb_access_dns_name" {
  value = "http://${aws_alb.alb.dns_name}"
}

output "sqs_url" {
  value = aws_sqs_queue.my_q.url
}

output "DYNAMODB_TABLE_NAME" {
  value = aws_dynamodb_table.table.name
}