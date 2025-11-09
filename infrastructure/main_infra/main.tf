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

  repository_image_tag_mutability = "MUTABLE"

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
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "service-a"
      image     = "${module.ecr["service_a"].repository_url}:latest"
      essential = true
      portMappings = [{
        containerPort : 9000
        # hostPort : 9000
        protocol: "tcp"
      }]
      # Integrate ECS Logs with Cloudwatch logs
      logConfiguration = {
        logDriver = "awslogs" # awslogs driver is standard way to integrate ECS logs with CLoudWatch logs
        options = {
          awslogs-group         = "/ecs/${var.project_name}" # Name of cloudwatch logs group -- we created it below
          awslogs-region        = var.region                 # region where log group exists
          awslogs-stream-prefix = "ecs"                      # prefix for log streams
        }
      }
    },
    {
      name      = "service-b"
      image     = "${module.ecr["service_b"].repository_url}:latest"
      essential = true
      portMappings = [{
        containerPort : 9001
        # hostPort : 9001
        protocol: "tcp"
      }]
      # Integrate ECS Logs with Cloudwatch logs
      logConfiguration = {
        logDriver = "awslogs" # awslogs driver is standard way to integrate ECS logs with CLoudWatch logs
        options = {
          awslogs-group         = "/ecs/${var.project_name}" # Name of cloudwatch logs group -- we created it below
          awslogs-region        = var.region                 # region where log group exists
          awslogs-stream-prefix = "ecs"                      # prefix for log streams
        }
      }
    },
  ])
}

############################
# ECS - Services [The actual running containers in your cluster]
############################
resource "aws_ecs_service" "app_services" {
  name            = "${var.project_name}-service"
  cluster         = module.ecs.cluster_id
  task_definition = aws_ecs_task_definition.app.arn
  launch_type     = "FARGATE"
  desired_count   = 2

  network_configuration {
    subnets          = module.vpc.private_subnets
    assign_public_ip = true
    security_groups  = [aws_security_group.web_sg.id]
  }

  # service_registries {
  #   registry_arn = aws_service_discovery_service.service_b
  # }

  load_balancer {
    target_group_arn = aws_alb_target_group.svc-a-tg.arn
    container_name   = "service-a"
    container_port   = 9000
  }

  depends_on = [aws_lb_listener.alb-listener] # let alb listener gets created first
}


######################
# INGESTOR -- ECS
######################
resource "aws_ecs_task_definition" "ingestor" {
  family                   = "${var.project_name}-ingestor"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn   # permission ecs needs for execution 
  task_role_arn = aws_iam_role.ecs_task_execution_role.arn    # permissions your containers need for other services

  container_definitions = jsonencode([
    {
      name      = "ingestor"
      image     = "${module.ecr["ingestor"].repository_url}:latest"
      essential = true
      environment = [
        { name = "SERVICE_A_URL", value = "http://${aws_alb.alb.dns_name}" },
        { name = "SQS_URL", value = "${aws_sqs_queue.my_q.url}" },
      ]
      # Integrate ECS Logs with Cloudwatch logs
      logConfiguration = {
        logDriver = "awslogs" # awslogs driver is standard way to integrate ECS logs with CLoudWatch logs
        options = {
          awslogs-group         = "/ecs/${var.project_name}" # Name of cloudwatch logs group -- we created it below
          awslogs-region        = var.region                 # region where log group exists
          awslogs-stream-prefix = "ecs"                      # prefix for log streams
        }
      }
    }
  ])
}

resource "aws_ecs_service" "ingestor-svc" {
  name            = "${var.project_name}-ingestor-svc"
  cluster         = module.ecs.cluster_id
  task_definition = aws_ecs_task_definition.ingestor.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = module.vpc.public_subnets
    assign_public_ip = true
    security_groups  = [aws_security_group.web_sg.id]
  }
}


######################
# Processor -- ECS
######################
resource "aws_ecs_task_definition" "processor" {
  family                   = "${var.project_name}-processor"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn   # permission ecs needs for execution 
  task_role_arn = aws_iam_role.ecs_task_execution_role.arn    # permissions your containers need for other services

  container_definitions = jsonencode([
    {
      name      = "processor"
      image     = "${module.ecr["processor"].repository_url}:latest"
      essential = true
      environment = [
        { name = "DYNAMODB_TABLE", value = "${aws_dynamodb_table.table.name}" },
        { name = "SQS_URL", value = "${aws_sqs_queue.my_q.url}" },
      ]
      # Integrate ECS Logs with Cloudwatch logs
      logConfiguration = {
        logDriver = "awslogs" # awslogs driver is standard way to integrate ECS logs with CLoudWatch logs
        options = {
          awslogs-group         = "/ecs/${var.project_name}" # Name of cloudwatch logs group -- we created it below
          awslogs-region        = var.region                 # region where log group exists
          awslogs-stream-prefix = "ecs"                      # prefix for log streams
        }
      }
    }
  ])
}

resource "aws_ecs_service" "processor-svc" {
  name            = "${var.project_name}-processor-svc"
  cluster         = module.ecs.cluster_id
  task_definition = aws_ecs_task_definition.processor.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = module.vpc.public_subnets
    assign_public_ip = true
    security_groups  = [aws_security_group.web_sg.id]
  }
}