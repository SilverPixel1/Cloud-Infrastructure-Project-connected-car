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
#ECS Task Definition für Ingest API, Processor und Simulator, damit die Container in ECS gestartet werden können
##########################################

# security group ECS Service
resource "aws_security_group" "ecs_service" {
  name        = "${var.project_name}-ecs-tasks-sg"
  description = "Security group for ECS tasks"
  vpc_id      = aws_vpc.connected_car_vpc.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp" # damit die ecs tasks über den ALB erreichbar sind, müssen die Ports 8080 für die Ingest API geöffnet werden, damit der ALB die Anfragen an die ECS Tasks weiterleiten kann
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

#simulator service erstellt, damit die Simulator Container in ECS gestartet und verwaltet werden können
resource "aws_ecs_service" "simulator_service" {
  name            = "${var.project_name}-simulator-service"
  cluster         = aws_ecs_cluster.connected_car_cluster.id
  task_definition = aws_ecs_task_definition.simulator_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = aws_subnet.connected_car_private_subnet[*].id
    security_groups = [aws_security_group.ecs_service.id]
    assign_public_ip = false 
  }
}




