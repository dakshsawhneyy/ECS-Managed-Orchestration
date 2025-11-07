############################
# ALB - to access app running inside ECS
############################
resource "aws_alb" "alb" {
  name = "${var.project_name}-alb"
  internal = false
  load_balancer_type = "application"
  
  security_groups = [aws_security_group.alb_sg.id]
  subnets = module.vpc.public_subnets

  tags = local.common_tags
}

# ALB Target Group
resource "aws_alb_target_group" "svc-a-tg" {
  name = "${var.project_name}-service-a-tg"
  target_type = "ip"    # Since we using Fargate, use ip
  port = 9000
  protocol = "HTTP"
  vpc_id = module.vpc.vpc_id

  health_check {
    path = "/healthy"
    interval = 30
    port = 9000
    protocol = "HTTP"
    timeout = 5
    healthy_threshold = 3
    unhealthy_threshold = 3
    matcher = "200"
  }
}

# ALB Listener
resource "aws_lb_listener" "alb-listener" {
  load_balancer_arn = aws_alb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_alb_target_group.svc-a-tg.arn
  }
}