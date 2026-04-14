#CloudWatch Logs Gruppe für ECS Tasks, damit die Container Logs in CloudWatch Logs schreiben können
resource "aws_cloudwatch_log_group" "ecs_tasks_log_group" {
  name              = "/aws/ecs/${var.project_name}-tasks"
  retention_in_days = 7 

    tags = {
        Environment = "Development"
        Project     = "var.project_name"
    }
}


