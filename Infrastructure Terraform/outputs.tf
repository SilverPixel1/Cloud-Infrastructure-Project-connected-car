#################
#output ECR Repository URLs
#################
output "ingest_api_ecr_url" {
  value = aws_ecr_repository.ingest_api.repository_url
}   

output "processor_ecr_url" {
  value = aws_ecr_repository.processor.repository_url
}   

output "simulator_ecr_url" {
  value = aws_ecr_repository.simulator.repository_url
}




#############
#outputs ECS Cluster, Task Execution Role ARN, and CloudWatch Log Group Name
#############
output "ecs_cluster_name" {
  value = aws_ecs_cluster.connected_car_cluster.name
}   

output "ecs_task_execution_role_arn" {
  value = aws_iam_role.ecs_task_execution_role.arn
}

output "ecs_tasks_log_group_name" {
  value = aws_cloudwatch_log_group.ecs_tasks_log_group.name
}


