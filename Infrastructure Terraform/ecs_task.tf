#########################################################################################
#ECS Task Definitions
#####################################

#ingest-api task definition
resource "aws_ecs_task_definition" "ingest_api_task" {                #Task Definition für die Ingest API, damit die Container in ECS gestartet werden können
  family                   = "${var.project_name}-ingest-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "ingest-api-container"
      image     = "${aws_ecr_repository.ingest_api.repository_url}:latest"
      essential = true


      environment = [
        {
          name = "AWS_REGION"
          value = var.aws_region
        },
        {
          name = "SQS_QUEUE_URL"
          value = aws_sqs_queue.sensor_queue.url
        }
      ]


      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]


      logConfiguration = {
        logDriver = "awslogs"
        options   = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_tasks_log_group.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ingest-api"
        }
      }
    }
  ])


  tags = {
    Environment = "Development"
    Project = var.project_name
  }

}


#processor task definition
resource "aws_ecs_task_definition" "processor_task" {
  family                   = "${var.project_name}-processor"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "processor-container"
      image     = "${aws_ecr_repository.processor.repository_url}:latest"
      essential = true

      environment = [
        {
          name = "AWS_REGION"
          value = var.aws_region
        },
        {
          name = "SQS_QUEUE_URL"
          value = aws_sqs_queue.sensor_queue.url
        },
        {
          name = "DYNAMODB_TABLE_NAME"
          value = aws_dynamodb_table.road_conditions.name
        }
      ]


      logConfiguration = {
        logDriver = "awslogs"
        options   = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_tasks_log_group.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "processor"
        }
      }
    }
  ])


  tags = {
    Environment = "Development"
    Project = var.project_name
  }

}


#simulator task definition
resource "aws_ecs_task_definition" "simulator_task" {
  family                   = "${var.project_name}-simulator"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "simulator-container"
      image     = "${aws_ecr_repository.simulator.repository_url}:latest"
      essential = true


      environment = [ #für die simulator die URL welcher in AWS erstellt wurde um die Docker Container zu erreichen.

        {
          name  = "INGEST_URL"
          value = "http://${aws_lb.application_load_balancer.dns_name}/ingest"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options   = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_tasks_log_group.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "simulator"
        }
      }
    }
  ])

  tags = {
    Environment = "Development"
    Project = "var.project_name"
  }

}
