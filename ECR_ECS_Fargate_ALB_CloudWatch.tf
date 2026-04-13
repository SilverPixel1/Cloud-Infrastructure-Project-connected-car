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

################
#ECR Repository
################
resource "aws_ecr_repository" "ingest_api" {
  name                 = "${var.project_name}-ingest-api"
  image_tag_mutability = "MUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
  }

    tags = {
        Name        = "${var.project_name}-ingest-api"
        Environment = "Development"
        Project     = "var.project_name"
    }

}

resource "aws_ecr_repository" "processor" {
  name                 = "${var.project_name}-processor"
  image_tag_mutability = "MUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
  }

    tags = {
        Name        = "${var.project_name}-processor"
        Environment = "Development"
        Project     = "var.project_name"
    }

}

resource "aws_ecr_repository" "simulator" {
  name                 = "${var.project_name}-simulator"
  image_tag_mutability = "MUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
  }

    tags = {
        Name        = "${var.project_name}-simulator"
        Environment = "Development"
        Project     = "var.project_name"
    }         
  
}

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


#CloudWatch Logs Gruppe für ECS Tasks, damit die Container Logs in CloudWatch Logs schreiben können
resource "aws_cloudwatch_log_group" "ecs_tasks_log_group" {
  name              = "/aws/ecs/${var.project_name}-tasks"
  retention_in_days = 7 

    tags = {
        Environment = "Development"
        Project     = "var.project_name"
    }
}

#############
#outputs
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


##########################################
#ECS Task Definition für Ingest API, Processor und Simulation, damit die Container in ECS gestartet werden können
##########################################

# ALB erstellen 

resource "aws_security_group" "alb_security_group" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.connected_car_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
    Environment = "Development"
    Project = "var.project_name"
  
  }

}


resource "aws_security_group" "ecs_service" {
  name        = "${var.project_name}-ecs-tasks-sg"
  description = "Security group for ECS tasks"
  vpc_id      = aws_vpc.connected_car_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
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

########################################
#ALB erstellen
########################################

resource "aws_lb" "application_load_balancer" {
  name               = "${var.project_name}-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_security_group.id]
  subnets            = aws_subnet.connected_car_public_subnet[*].id

  tags = {
    Name = "${var.project_name}-alb"
    Environment = "Development"
    Project = "var.project_name"
  }
}

#TargetGroup erstellen, damit der ALB die Anfragen an die ECS Tasks weiterleiten kann
resource "aws_lb_target_group" "ingest_api_target_group" {
  name     = "${var.project_name}-ingest-api-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.connected_car_vpc.id
  target_type = "ip" # Da wir Fargate verwenden, müssen wir den Target Type auf "ip" setzen, damit der ALB die IP-Adressen der ECS Tasks als Ziele verwenden kann  
  

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }


  tags = {
    Name = "${var.project_name}-ingest-api-tg"
    Environment = "Development"
    Project = "var.project_name"
  }

}


#ALB Listener erstellen, damit der ALB die Anfragen an die Target Group weiterleiten kann
  resource "aws_lb_listener" "http_alb_listener" {
    load_balancer_arn = aws_lb.application_load_balancer.arn
    port              = 80
    protocol          = "HTTP"

    default_action {
      type             = "forward"
      target_group_arn = aws_lb_target_group.ingest_api_target_group.arn
    }
  
}

#####################################
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
          value = aws_sqs_queue.sensor_queue.id
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
    Project = "var.project_name"
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
          value = "http://${aws_lb.application_load_balancer.dns_name}:80"
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
    subnets         = aws_subnet.connected_car_public_subnet[*].id
    security_groups = [aws_security_group.ecs_service.id]
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
    subnets         = aws_subnet.connected_car_public_subnet[*].id
    security_groups = [aws_security_group.ecs_service.id]
  }
}




