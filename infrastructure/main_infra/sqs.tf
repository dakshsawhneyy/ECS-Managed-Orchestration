resource "aws_sqs_queue" "my_q" {
  name = "${var.project_name}-sqs"
  message_retention_seconds = 86400   # retain message for 1 day [default is 4 days]
  visibility_timeout_seconds = 30   # When a consumer receives a message, it becomes temporarily invisible to other consumers for this duration -- avoid clash
  receive_wait_time_seconds  = 10   # wait for message, ensure not to add empty message

  tags = local.common_tags
}