
#################
#Internet gateway
#################   

resource "aws_internet_gateway" "connected_car_igw" {
  vpc_id = aws_vpc.connected_car_vpc.id

  tags = {
    Name = "${var.project_name}-igw"
    Project = var.project_name
    Environment = "Development"
  }
}
