# IAM Roles for the Connected Car Project


#######################################################################
# IAM Excecution Role für ECS Tasks, damit die Container auf AWS Ressourcen zugreifen können (z.B. S3, DynamoDB, CloudWatch Logs)
# ECS Task
resource "aws_iam_role" "ecs_task_execution_role" { 
  name = "${var.project_name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-ecs-task-execution-role"
    Environment = "Development"
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

#######################
#neue Task Role für SQS Zugriff...
resource "aws_iam_role" "ecs_task_role" { 
  name = "${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-ecs-task-role"
    Environment = "Development"
    Project     = "var.project_name"
    ManagedBy   = "Terraform"
  }
}








########
#SQS excecution Role

resource "aws_iam_role_policy" "ecs_task_sqs_policy" {
    name        = "${var.project_name}-ecs-task-sqs-policy"
    role = aws_iam_role.ecs_task_role.id
    
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
        {
            Effect = "Allow"
            Action = [
            "sqs:SendMessage",
            "sqs:ReceiveMessage",
            "sqs:GetQueueAttributes",
            "sqs:GetQueueUrl",
            "sqs:DeleteMessage"
          
            
            ]
            Resource = aws_sqs_queue.sensor_queue.arn
        }
        ]
    })
  
}


####################################################################
#Dynamo DB benötigt eine IAM Rolle, damit die Sensoren Daten in die DynamoDB Tabelle schreiben können
#Die Rolle wird mit den notwendigen Berechtigungen ausgestattet, um auf die DynamoDB Tabelle zu

#dynamodb 
resource "aws_iam_policy" "dynamodb_rw" {
    name        = "${var.project_name}-dynamodb-rw-policy"
    description = "IAM Policy for read/write access to DynamoDB table for Connected Car project"
    
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
        {
            Effect = "Allow"
            Action = [
            "dynamodb:PutItem",
            "dynamodb:GetItem",
            "dynamodb:UpdateItem",
            "dynamodb:DeleteItem",
            "dynamodb:Query",
            "dynamodb:Scan"
            ]
            Resource = aws_dynamodb_table.road_conditions.arn
        }
        ]
    })
  
}

resource "aws_iam_role_policy_attachment" "processor_dynamodb_policy" {
    role       = aws_iam_role.ecs_task_role.name
    policy_arn = aws_iam_policy.dynamodb_rw.arn
  
}


