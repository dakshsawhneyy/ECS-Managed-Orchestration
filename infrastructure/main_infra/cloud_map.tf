# # Create a Private DNS Namespace
# # This is like the root zone (e.g., local) where ECS services will register.
# resource "aws_service_discovery_private_dns_namespace" "app" {
#   name = "local"
#   description = "Private DNS namespace for ECS services"
#   vpc = module.vpc.vpc_id
#   # this createssomething like: service-b.local
# }   

# # Create a Service Discovery Service for Service B
# resource "aws_service_discovery_service" "service_b" {
#   name = "service-b"

#   # add DNS config, so service_b registers to private dns namespace
#   dns_config {
#     namespace_id = aws_service_discovery_private_dns_namespace.app.id
#     dns_records {
#       type = "A"
#       ttl = 10
#     }
#     routing_policy = "MULTIVALUE"   # if there are 3 containers running for service-b.local, it return all 3
#   }

#   health_check_custom_config {}     # no custom config
# }

# # Attach this Service Discovery to service-b task definition