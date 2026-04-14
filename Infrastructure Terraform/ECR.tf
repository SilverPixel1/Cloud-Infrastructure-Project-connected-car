
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

