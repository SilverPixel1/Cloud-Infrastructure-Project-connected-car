########################################
#ALB erstellen
########################################

# ALB Security Group 


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


#ALB erstellen, damit die Anfragen von außen an die ECS Tasks weitergeleitet werden können

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


