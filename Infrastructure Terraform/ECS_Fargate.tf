#######################################################################################################################
#Build the Infrastructure for the Project: ECR, ECS, Fargate(EC2), IAM, CloudWatch, ALB
#######################################################################################################################

# ECR speichert Docker Images, wie Docker HUB, privat in AWS dadurch werden die Images sicher verwaltet und können direkt in AWS Diensten wie ECS oder Lambda verwendet werden
# ECS ist der Container Orchestrator von AWS er startet, skaliert und verwaltet Container
# Fargate ist der Compute Service von AWS, für serverless und günstiger (EC2 wäre für vollständige Kontrolle)
# ALB ist der Application Load Balancer von AWS, damit die Ingest API über den ALB erreichbar ist und der ALB die Anfragen an die ECS Tasks weiterleiten kann
# CloudWatch ist der Monitoring Service von AWS (überwacht die Infrastruktur, sammelt Logs, erstellt Alarme, etc.)
# IAM ist der Identity and Access Management Service von AWS (verwalten von Benutzern, Rollen, Berechtigungen, etc.)  


###############################
#Dieses Projekt ist Containerbasiert:
#1. Ingest API: Nimmt Daten von den Fahrzeugen entgegen, validiert sie und speichert sie in der Datenbank
#2. Processor: Verarbeitet die Daten mit Kinesis, führt Analysen durch und generiert Erkenntnisse
#3. Simulation: Simuliert Fahrzeugdaten für Test- und Entwicklungszwecke
###############################

####################################################
#ECS Cluster auf Fargate (Serverless Compute Service für Container, keine Updates/Patches verwalten, kosten nur wenn Containerlaufen)
####################################################

resource "aws_ecs_cluster" "connected_car_cluster" {
  name = "${var.project_name}-cluster"

  setting {
    name = "containerInsights" # CloudWatch Container Insights ermöglicht die Überwachung von Container-basierten Anwendungen
    value = "enabled"
  }

    tags = {
        Name        = "${var.project_name}-cluster"
        Environment = "Development"
        Project     = "var.project_name"
        ManagedBy    = "Terraform"
    } 
}


##########################################
#ECS Task Definition für Ingest API, Processor und Simulation, damit die Container in ECS gestartet werden können
##########################################

# security group ECS Service
resource "aws_security_group" "ecs_service" {
  name        = "${var.project_name}-ecs-tasks-sg"
  description = "Security group for ECS tasks"
  vpc_id      = aws_vpc.connected_car_vpc.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_security_group.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ecs-service-sg"
    Environment = "Development"
    Project = "var.project_name"
  }

}






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
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

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
          value = aws_sqs_queue.sensor_queue.id
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
    Project = "var.project_name"
  }

}

#simulation task definition
resource "aws_ecs_task_definition" "simulation_task" {
  family                   = "${var.project_name}-simulation"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "simulation-container"
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
          "awslogs-stream-prefix" = "simulation"
        }
      }
    }
  ])

  tags = {
    Environment = "Development"
    Project = "var.project_name"
  }

}

#################################
#ECS Service erstellen, damit die Container in ECS gestartet und verwaltet werden können
#################################

#ingest-api service mit ALB erstellt, damit die Ingest API über den ALB erreichbar ist und der ALB die Anfragen an die ECS Tasks weiterleiten kann
resource "aws_ecs_service" "ingest_api_service" {
  name            = "${var.project_name}-ingest-api-service"
  cluster         = aws_ecs_cluster.connected_car_cluster.id
  task_definition = aws_ecs_task_definition.ingest_api_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = aws_subnet.connected_car_public_subnet[*].id
    security_groups = [aws_security_group.ecs_service.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ingest_api_target_group.arn
    container_name   = "ingest-api-container"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.http_alb_listener]  

}

#processor service erstellt, damit die Processor Container in ECS gestartet und verwaltet werden können
resource "aws_ecs_service" "processor_service" {
  name            = "${var.project_name}-processor-service"
  cluster         = aws_ecs_cluster.connected_car_cluster.id
  task_definition = aws_ecs_task_definition.processor_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = aws_subnet.connected_car_private_subnet[*].id
    security_groups = [aws_security_group.ecs_service.id]
    assign_public_ip = false
  }
  
}

#simulation service erstellt, damit die Simulation Container in ECS gestartet und verwaltet werden können
resource "aws_ecs_service" "simulation_service" {
  name            = "${var.project_name}-simulation-service"
  cluster         = aws_ecs_cluster.connected_car_cluster.id
  task_definition = aws_ecs_task_definition.simulation_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = aws_subnet.connected_car_private_subnet[*].id
    security_groups = [aws_security_group.ecs_service.id]
    assign_public_ip = false 
  }
}




