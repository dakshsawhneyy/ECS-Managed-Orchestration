resource "aws_dynamodb_table" "terraform_lock" {
    name = "${var.project_name}-table"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "log_id"

    attribute {
        name = "log_id"
        type = "S"
    }

    tags = local.common_tags
}