############################
# VPC
############################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  azs             = local.azs
  public_subnets  = local.public_subnets
  private_subnets = local.private_subnets

  enable_nat_gateway = true
  single_nat_gateway = var.enable_single_natgateway

  create_igw = true

  map_public_ip_on_launch = true

  tags = local.common_tags
}

############################
# ECR -- two repos for two services
############################
module "ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "~> 2.2"

  for_each = local.ecr_repositories

  repository_name = each.value.repository_name
  repository_type = each.value.repository_type

  create_lifecycle_policy = false

  # Forcefully delete, even if it contains images
  repository_force_delete = true

  tags = local.common_tags
}

############################
# ECS - cluster creation
############################
module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "6.7.0"

  cluster_name = var.project_name

  # CloudWatch Observability
  cluster_setting = [{
    "name" : "containerInsights",
    "value" : "enabled"
  }]

  tags = local.common_tags
}

############################
# CloudWatch Log Group
############################
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7
}

############################
# ECS Task Definition -- A blueprint for what gonna run inside the ecs cluster
############################
resource "aws_ecs_task_definition" "service_a_task" {
  family                   = "service-a-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name      = "service-a"
      image     = "${aws_ecr_repository.service_a.repository_url}:latest"
      essential = true
      portMappings = [{
        containerPort = 3000
        protocol      = "tcp"
      }]
      environment = [
        {
          name  = "SERVICE_B_URL"
          value = "http://${aws_service_discovery_service.service_b.name}" # or ALB DNS
        }
      ]
    }
  ])
}

resource "aws_ecs_task_definition" "service_b_task" {
  family                   = "service-b-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name      = "service-b"
      image     = "${aws_ecr_repository.service_b.repository_url}:latest"
      essential = true
      portMappings = [{
        containerPort = 9001
        protocol      = "tcp"
      }]
    }
  ])
}

############################
# ECS - Services [The actual running containers in your cluster]
############################
resource "aws_ecs_service" "service_a" {
  name            = "service-a"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.service_a_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1
  network_configuration {
    subnets         = aws_subnet.public[*].id
    assign_public_ip = true
    security_groups = [aws_security_group.ecs_sg.id]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.service_a_tg.arn
    container_name   = "service-a"
    container_port   = 3000
  }
  depends_on = [aws_lb_listener.front_end]
}

resource "aws_ecs_service" "service_b" {
  name            = "service-b"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.service_b_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1
  network_configuration {
    subnets         = aws_subnet.private[*].id
    assign_public_ip = false
    security_groups = [aws_security_group.ecs_sg.id]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.service_b_tg.arn
    container_name   = "service-b"
    container_port   = 5000
  }
  service_registries {
    registry_arn = aws_service_discovery_service.service_b.arn
  }
}