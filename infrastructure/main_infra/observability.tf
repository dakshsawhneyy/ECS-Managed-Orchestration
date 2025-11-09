# ##################################################
# # Create Amazon Managed Prometheus (AMP) Workspace
# ##################################################
# resource "aws_prometheus_workspace" "main" {
#   alias = "${var.project_name}-workspace"
# }

# ##################################################
# # Prometheus Template file
# ##################################################
# data "template_file" "prometheus_config" {
#   template = file("${path.module}/prom.yml.tpl")
#   vars = {
#     service_a_alb_dns = aws_alb.alb.dns_name
#   }
# }

# resource "local_file" "prometheus_config" {
#   content  = data.template_file.prometheus_config.rendered
#   filename = "${path.module}/prometheus.yml"
# }


# ##################################################
# # Prometheus ECS Container
# ##################################################
# resource "aws_ecs_task_definition" "prometheus" {
#   family                   = "${var.project_name}-prometheus"
#   network_mode             = "awsvpc"
#   requires_compatibilities = ["FARGATE"]
#   cpu                      = "256"
#   memory                   = "512"
#   execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn   # permission ecs needs for execution 

#   container_definitions = jsonencode([
#     {
#       name      = "prometheus"
#       image     = "prom/prometheus:latest"
#       essential = true
#       mountPoints = [{
#         sourceVolume  = "prometheus-config"
#         containerPath = "/etc/prometheus"
#       }]      
#     }
#   ])
#   volume {
#     name = "prometheus-config"
#     host_path = null
#   }
# }

# resource "aws_ecs_service" "prometheus-svc" {
#   name            = "${var.project_name}-processor-svc"
#   cluster         = module.ecs.cluster_id
#   task_definition = aws_ecs_task_definition.prometheus.arn
#   launch_type     = "FARGATE"
#   desired_count   = 1

#   network_configuration {
#     subnets          = module.vpc.private_subnets
#     assign_public_ip = true
#     security_groups  = [aws_security_group.web_sg.id]
#   }
# }

# ##################################################
# # Grafana ECS Container
# ##################################################
# resource "aws_ecs_task_definition" "grafana" {
#   family                   = "${var.project_name}-grafana"
#   network_mode             = "awsvpc"
#   requires_compatibilities = ["FARGATE"]
#   cpu                      = "256"
#   memory                   = "512"
#   execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn   # permission ecs needs for execution 

#   container_definitions = jsonencode([
#     {
#       name      = "grafana"
#       image     = "grafana/grafana:latest"
#       essential = true
#       portMappings = [{
#         containerPort = 3000
#       }]
#       environment = [
#         {
#           name  = "GF_SECURITY_ADMIN_USER"
#           value = "admin"
#         },
#         {
#           name  = "GF_SECURITY_ADMIN_PASSWORD"
#           value = "admin123"
#         }
#       ]   
#     }
#   ])
# }

# resource "aws_ecs_service" "grafana-svc" {
#   name            = "${var.project_name}-grafana-svc"
#   cluster         = module.ecs.cluster_id
#   task_definition = aws_ecs_task_definition.grafana.arn
#   launch_type     = "FARGATE"
#   desired_count   = 1

#   network_configuration {
#     subnets          = module.vpc.private_subnets
#     assign_public_ip = true
#     security_groups  = [aws_security_group.web_sg.id]
#   }
# }